//
//  WistiaProject.swift
//  Pods
//
//  Created by Daniel Spinosa on 4/28/16.
//
//

import Foundation

/*
 
 name	The project's display name.
 description	The project's description.
 mediaCount	The number of different medias that have been uploaded to the project.
 created	The date that the project was originally created.
 updated	The date that the project was last updated.
 hashedId	A private hashed id, uniquely identifying the project within the system.
 anonymousCanUpload	A boolean indicating whether or not anonymous uploads are enabled for the project.
 anonymousCanDownload	A boolean indicating whether or not anonymous downloads are enabled for this project.
 public	A boolean indicating whether the project is available for public (anonymous) viewing.
 publicId
 
 */

//Top level of your wistia stuff
public struct WistiaProject {

    public let projectID: Int
    public var name: String?
    public var description: String?
    public var mediaCount: Int?
//    public var created: NSDate
//    public var updated: NSDate
    public let hashedID: String
//    public var anonymousCanUpload: Bool
//    public var anonymousCanDownload: Bool
//    public var isPublic: Bool
//    public var publicID: String?

    //nil if it hasn't been fetched  yet, empty if it was fetched and returned zero elements
    public var medias: [WistiaMedia]?

}