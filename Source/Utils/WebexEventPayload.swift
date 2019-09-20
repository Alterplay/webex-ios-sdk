//
//  EventPayload.swift
//  Alamofire
//
//  Created by yonshi on 2019/7/17.
//

import Foundation


public protocol WebexEventData {
}

public struct WebexEventPayload {
    /// The personId of the user who caused the event to be sent
    public var actorId:String?
    
    /// the current date on client
    public var created:Date?
    
    /// The personId of login user
    public var createdBy:String?
    
    /// Contains the data representation of the resource that triggered the event
    public var data:WebexEventData?
    
    /// The type of the event
    public var event:String?
    
    /// The organizationId of login user
    public var orgId:String?
    
    /// default is "creator"
    public var ownedBy:String?
    
    /// The resource the event data is about.
    public var resource:String?
    
    /// default is "active"
    public var status:String?
    
    init(me:Person?) {
        self.orgId = me?.orgId
        self.createdBy = me?.id
        self.created = Date()
        self.ownedBy = "creator"
        self.status = "active"
    }
    
}

public struct WebexMembershipData:WebexEventData {
    
    /// mixture id
    public var id: String?
    
    /// the date when the behaviour occured
    public var created: Date?
    
    /// default is false
    public var isRoomHidden:Bool?
    
    /// the id of the room in which the actor is
    public var roomId:String?
    
    /// group or direct
    public var roomType:String?
    
    /// for seen event, information of the user who read receipt.
    /// for add, leave, update event, information of the user who was changed
    public var personDisplayName:String?
    public var personEmail:String?
    public var personId:String?
    public var personOrgId:String?
    
    /// the id of last message read by the user
    public var lastSeenId:String?
    
    /// the user is or not the moderator
    public var isModerator:Bool?
    
    init(activity:ActivityModel) {
        self.id = activity.dataId
        self.created = activity.created
        self.isRoomHidden = false
        self.roomId = activity.targetId
        self.roomType = (activity.targetTag ?? SpaceType.group).rawValue
        
        if activity.kind == ActivityModel.Kind.acknowledge { // seen
            self.personId = activity.actorId
            self.personOrgId = activity.actorOrgId
            self.personDisplayName = activity.actorDisplayName
            self.personEmail = activity.actorEmail
            self.lastSeenId = activity.objectId
        }else { // add, leave and update
            self.personId = activity.objectId
            self.personOrgId = activity.objectOrgId
            self.personDisplayName = activity.objectDisplayName
            self.personEmail = activity.objectEmail
            self.isModerator = activity.isModerator
        }
    }
    
}
