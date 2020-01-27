// Copyright 2016-2020 Cisco Systems Inc
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import Alamofire

@objc public protocol WebexCancellableTask {
    func cancel()
}

class DownloadFileOperation : NSObject, URLSessionDataDelegate {
    
    private let authenticator: Authenticator
    private let uuid: String
    private let source: String
    private let secureContentRef: String?
    private var target: URL
    private let fileName: String?
    private let queue: DispatchQueue
    private let progressHandler: ((Double) -> Void)?
    private let completionHandler : ((Result<URL>) -> Void)
    private var outputStream : OutputStream?
    private var downloadSeesion: URLSession?
    private var totalSize: UInt64?
    private var countSize: UInt64 = 0
    
    private let shouldDecryptOnCompletion: Bool

    init(authenticator: Authenticator, uuid: String, source: String, displayName: String?, secureContentRef: String?, thnumnail: Bool, target: URL?, fileName: String?, queue: DispatchQueue?, progressHandler: ((Double) -> Void)?, completionHandler: @escaping ((Result<URL>) -> Void)) {
        self.authenticator = authenticator
        self.source = source
        self.secureContentRef = secureContentRef
        self.uuid = uuid
        self.queue = queue ?? DispatchQueue.main
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
        if let target = target {
            self.target = target
        }
        else {
            let path = FileManager.default.temporaryDirectory.appendingPathComponent("com.ciscowebex.sdk.downloads", isDirectory: true)
            try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: false, attributes: nil)
            self.target = path
        }
         self.fileName = fileName
               var name: String
               if let fileName = fileName {
                   name = "encrypted-\(fileName)"
                   shouldDecryptOnCompletion = true
               }
               else {
                   shouldDecryptOnCompletion = false
                   name = UUID().uuidString + "-" + (displayName ?? Date().iso8601String)
                   if (thnumnail) {
                       name = "thumb-" + name
                   }
        }
        self.target = self.target.appendingPathComponent(name, isDirectory: false)
    }
    
    func run() {
        guard let url = URL(string: self.source) else {
            self.downloadError()
            return
        }
        self.authenticator.accessToken { token in
            guard let token = token else {
                self.downloadError()
                return
            }
            self.downloadSeesion = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
            var request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval: 0)
            request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
            request.setValue("ITCLIENT_\(self.uuid)_0", forHTTPHeaderField: "TrackingID")
            if FileManager.default.fileExists(atPath: self.target.path),
                let fileAttributes = try? FileManager.default.attributesOfItem(atPath: self.target.path),
                let fileSize = fileAttributes[.size] as? UInt64 {
                request.setValue("bytes=\(fileSize)-", forHTTPHeaderField: "Range")
                self.countSize = fileSize
            }
            if let dataTask = self.downloadSeesion?.dataTask(with: request){
                dataTask.resume()
            }
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Swift.Void) {
        if let resp = response as? HTTPURLResponse, let length = (resp.allHeaderFields["Content-Length"] as? String)?.components(separatedBy: "/").last, let size = UInt64(length) {
            self.totalSize = size + self.countSize
            do {
                var tempOutputStream = OutputStream(toFileAtPath: self.target.path, append: true)
                if !self.shouldDecryptOnCompletion, let ref = self.secureContentRef {
                    tempOutputStream = try SecureOutputStream(stream: tempOutputStream, scr: try SecureContentReference(json: ref))
                }
                self.outputStream = tempOutputStream
                self.outputStream?.open()
                completionHandler(URLSession.ResponseDisposition.allow);
            }
            catch {
                SDKLogger.shared.info("DownLoadSession Create Error - \(error)")
                completionHandler(URLSession.ResponseDisposition.cancel);
            }
        }
        else {
            SDKLogger.shared.info("Unknown size of the file")
            completionHandler(URLSession.ResponseDisposition.cancel);
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        _ = self.outputStream?.write(data: data)
        self.queue.async {
            self.countSize = self.countSize + UInt64(data.count)
            self.progressHandler?(Double(self.countSize)/Double(self.totalSize!))
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.outputStream?.close()
        self.cancel()
        if let error = error {
            self.downloadError(error)
        }
        else {
            if !shouldDecryptOnCompletion {
                self.queue.async {
                    self.completionHandler(Result.success(self.target))
                }
            }
            else if let decryptedFileURL = self.decrypt() {
                self.queue.async {
                    self.completionHandler(Result.success(self.decryptedFileURL))
                }
            }
            else {
                self.queue.async {
                    self.completionHandler(Result.failure(downloadError()))
                }
            }
        }
    }
    
    private func downloadError(_ error: Error? = nil) {
        SDKLogger.shared.info("File download fail...")
        self.queue.async {
            self.completionHandler(Result.failure(error ?? WebexError.serviceFailed(code: -7000, reason: "download error")))
        }
    }
}

extension OutputStream {
    func write(data: Data) -> Int {
        return data.withUnsafeBytes { self.write($0, maxLength: data.count) }
    }
}

extension DownloadFileOperation: WebexCancellableTask {
    func cancel() {
        downloadSeesion?.invalidateAndCancel()
    }
}

//MARK: - Decryption

private extension DownloadFileOperation {
    func decrypt() -> URL? {
        defer {
            try? FileManager.default.removeItem(at: self.target)
        }
        do {
            guard let inputStream = InputStream(url: self.target) else {
                return nil
            }
            
            var decryptedFileURL = self.target.deletingLastPathComponent()
            decryptedFileURL = decryptedFileURL.appendingPathComponent(self.fileName!)
            
            var outputStream = OutputStream(toFileAtPath: decryptedFileURL.path, append: false)
            if let ref = self.secureContentRef {
                outputStream = try SecureOutputStream(stream: outputStream, scr: try SecureContentReference(json: ref))
            }
            else {
                return nil
            }
            try outputStream?.write(fromInputStrem: inputStream)
            return decryptedFileURL
        }
        catch {
            print("Error while decryption occured: \(error)")
            return nil
        }
    }
}

extension OutputStream {
    func write(fromInputStrem inputStream: InputStream) throws {
        inputStream.open()
        open()
        
        defer {
            inputStream.close()
            close()
        }
        
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        while inputStream.hasBytesAvailable {
            let read = inputStream.read(buffer, maxLength: bufferSize)
            if read < 0 {
                throw inputStream.streamError!
            }
            else if read == 0 {
                break
            }
            write(buffer, maxLength: bufferSize)
            if let error = streamError {
                throw error
            }
        }
    }
}
