// Copyright 2016-2019 Cisco Systems Inc
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

import Foundation

/// An iOS client wrapper of the Cisco Webex [Space Memberships REST API](https://developer.webex.com/resource-memberships.html) .
///
/// - since: 1.2.0
public class MembershipClient {
    
    /// The callback handler when receiving a membership event.
    
    /// - since: 2.2.0
    public var onEvent: ((MembershipEvent) -> Void)?
    
    private let phone: Phone
    private let messages: MessageClient

    init(phone: Phone, messages: MessageClient) {
        self.phone = phone
        self.messages = messages
    }
    
    private func requestBuilder() -> ServiceRequest.Builder {
        return ServiceRequest.Builder(self.phone.authenticator).path("memberships")
    }
    
    private func conversationBuilder() -> ServiceRequest.Builder {
        return ServiceRequest.Builder(self.phone.authenticator)
            .baseUrl(ServiceRequest.conversationServerAddress)
            .path("activities")
    }

    /// Lists all space memberships where the authenticated user belongs.
    ///
    /// - parameter max: The maximum number of items in the response.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    public func list(max: Int? = nil, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<[Membership]>) -> Void) {
        list(spaceId: nil, personId: nil, personEmail: nil, max: max, queue: queue, completionHandler: completionHandler)
    }
    
    /// Lists all memberships in the given space by space Id.
    ///
    /// - parameter spaceId: The identifier of the space where the membership belongs.
    /// - parameter max: The maximum number of memberships in the response.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    public func list(spaceId: String, max: Int? = nil, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<[Membership]>) -> Void) {
        list(spaceId: spaceId, personId: nil, personEmail: nil, max: max, queue: queue, completionHandler: completionHandler)
    }
    
    /// Lists any space memberships for the given space (by space id) and person (by person id).
    ///
    /// - parameter spaceId: The identifier of the space where the memberships belong.
    /// - parameter personId: The identifier of the person who has the memberships.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    public func list(spaceId: String, personId: String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<[Membership]>) -> Void) {
        list(spaceId: spaceId, personId: personId, personEmail: nil, max: nil, queue: queue, completionHandler: completionHandler)
    }
    
    /// Lists any space memberships for the given space (by space id) and person (by email address).
    ///
    /// - parameter spaceId: The identifier of the space where the memberships belong.
    /// - parameter personEmail: The email address of the person who has the memberships.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    public func list(spaceId: String, personEmail: EmailAddress, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<[Membership]>) -> Void) {
        list(spaceId: spaceId, personId: nil, personEmail: personEmail, max: nil, queue: queue, completionHandler: completionHandler)
    }
    
    private func list(spaceId: String?, personId: String?, personEmail: EmailAddress?, max: Int?, queue: DispatchQueue?, completionHandler: @escaping (ServiceResponse<[Membership]>) -> Void) {
        let query = RequestParameter([
            "spaceId": spaceId,
            "roomId": spaceId,
            "personId": personId,
            "personEmail": personEmail?.toString(),
            "max": max])
        
        let request = requestBuilder()
            .method(.get)
            .query(query)
            .keyPath("items")
            .queue(queue)
            .build()
        
        request.responseArray(completionHandler)
    }
    
    /// Adds a person to a space by person id; optionally making the person a moderator.
    ///
    /// - parameter spaceId: The identifier of the space where the person is to be added.
    /// - parameter personId: The identifier of the person to be added.
    /// - parameter isModerator: If true, make the person a moderator of the space. The default is false.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    public func create(spaceId: String, personId: String, isModerator: Bool = false, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Membership>) -> Void) {
        let body = RequestParameter([
            "spaceId": spaceId,
            "roomId": spaceId,
            "personId": personId,
            "isModerator": isModerator])
        
        let request = requestBuilder()
            .method(.post)
            .body(body)
            .queue(queue)
            .build()
        
        request.responseObject(completionHandler)
    }
    
    /// Adds a person to a space by email address; optionally making the person a moderator.
    ///
    /// - parameter spaceId: The identifier of the space where the person is to be added.
    /// - parameter personEmail: The email address of the person to be added.
    /// - parameter isModerator: If true, make the person a moderator of the space. The default is false.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    public func create(spaceId: String, personEmail: EmailAddress, isModerator: Bool = false, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Membership>) -> Void) {
        let body = RequestParameter([
            "spaceId": spaceId,
            "roomId": spaceId,
            "personEmail": personEmail.toString(),
            "isModerator": isModerator])
        
        let request = requestBuilder()
            .method(.post)
            .queue(queue)
            .body(body)
            .build()
        
        request.responseObject(completionHandler)
    }
    
    /// Retrieves the details for a membership by membership id.
    ///
    /// - parameter membershipId: The identifier of the membership.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the get request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    public func get(membershipId: String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Membership>) -> Void) {
        let request = requestBuilder()
            .method(.get)
            .path(membershipId)
            .queue(queue)
            .build()
        
        request.responseObject(completionHandler)
    }
    
    /// Updates the properties of a membership by membership id.
    ///
    /// - parameter membershipId: The identifier of the membership.
    /// - parameter isModerator: If true, make the person a moderator of the space in this membership. The default is false.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    public func update(membershipId: String, isModerator: Bool, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Membership>) -> Void) {
        let request = requestBuilder()
            .method(.put)
            .body(RequestParameter(["isModerator": isModerator]))
            .path(membershipId)
            .queue(queue)
            .build()
        
        request.responseObject(completionHandler)
    }
    
    /// Deletes a membership by membership id. It removes the person from the space where the membership belongs.
    ///
    /// - parameter membershipId: The identifier of the membership.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the delete request has finished.
    /// - returns: Void
    /// - since: 1.2.0
    public func delete(membershipId: String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        let request = requestBuilder()
            .method(.delete)
            .path(membershipId)
            .queue(queue)
            .build()
        
        request.responseJSON(completionHandler)
    }
    
    /// Send read receipt when the login user read a message, let others know you have seen it
    ///
    /// - parameter spaceId: The identifier of the space where the message is.
    /// - parameter messageId: The identifier of the message which user read.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the delete readReceipt has finished.
    /// - returns: Void
    /// - since: 2.2.0
    public func sendReadReceipt(spaceId:String, messageId: String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        let object = ["id": messageId.locusFormat, "objectType": ObjectType.activity.rawValue]
        let target = ["id": spaceId.locusFormat, "objectType": ObjectType.conversation.rawValue]
        let body = RequestParameter(["objectType":ObjectType.activity.rawValue,
                                     "verb": ActivityModel.Verb.acknowledge.rawValue,
                                     "object": object,
                                     "target": target])
        let request = self.conversationBuilder()
            .method(.post)
            .body(body)
            .queue(queue)
            .build()
        request.responseJSON(completionHandler)
    }
    
    /// Send read receipt when the login user read all the messages in the space, let others know you have seen them
    ///
    /// - parameter messageId: The identifier of the space.
    /// - parameter queue: If not nil, the queue on which the completion handler is dispatched. Otherwise, the handler is dispatched on the application's main thread.
    /// - parameter completionHandler: A closure to be executed once the delete readReceipt has finished.
    /// - returns: Void
    /// - since: 2.2.0
    public func sendReadReceipt(spaceId:String, queue: DispatchQueue? = nil, completionHandler: @escaping (ServiceResponse<Any>) -> Void) {
        self.messages.list(spaceId: spaceId, max: 1, queue:queue) { (response) in
            switch response.result {
            case .success(let messages):
                if let message = messages.first, let lastMessageId = message.id {
                    self.sendReadReceipt(spaceId: spaceId, messageId: lastMessageId, queue: queue,  completionHandler: completionHandler)
                }
            case .failure(let error):
                completionHandler(ServiceResponse(response.response, Result.failure(error)))
            }
        }
    }
    
}

// MARK: handle conversation membership event
extension MembershipClient {
    
    func handle(activity: ActivityModel) {
        guard let verb = activity.verb else {
            return
        }
        var membership = Membership()
        membership.id = activity.dataId
        membership.created = activity.created
        membership.spaceId = activity.targetId
        
        if verb == ActivityModel.Verb.acknowledge {
            if let seenId = activity.objectId {
                membership.personId = activity.actorId
                membership.personOrgId = activity.actorOrgId
                membership.personDisplayName = activity.actorDisplayName
                membership.personEmail = EmailAddress.fromString(activity.actorEmail)
                var event = MembershipEvent.seen(membership, lastSeenId: seenId)
                event.payload = EventPayload(actorId: activity.actorId, person: self.phone.me, resource: EventResource.memberships, event: EventType.seen)
                self.onEvent?(event)
            }
        }
        else {
            membership.personId = activity.objectId
            membership.personOrgId = activity.objectOrgId
            membership.personDisplayName = activity.objectDisplayName
            membership.personEmail = EmailAddress.fromString(activity.objectEmail)
            membership.isModerator = activity.isModerator
            switch verb {
            case .add:
                var event = MembershipEvent.created(membership)
                event.payload = EventPayload(actorId: activity.actorId, person: self.phone.me, resource: EventResource.memberships, event: EventType.created)
                self.onEvent?(event)
            case .leave:
                var event = MembershipEvent.deleted(membership)
                event.payload = EventPayload(actorId: activity.actorId, person: self.phone.me, resource: EventResource.memberships, event: EventType.deleted)
                self.onEvent?(event)
            case .update:
                var event = MembershipEvent.update(membership)
                event.payload = EventPayload(actorId: activity.actorId, person: self.phone.me, resource: EventResource.memberships, event: EventType.updated)
                self.onEvent?(event)
            default:
                break
            }
        }
    }
}
