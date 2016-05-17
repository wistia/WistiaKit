//
//  WistiaProject.swift
//  Pods
//
//  Created by Daniel Spinosa on 4/28/16.
//
//

import Foundation

//Top level of your wistia stuff
/**
 Projects are the main organizational objects within Wistia. Media must be stored within Projects.

 See [Wistia Data API: Project](http://wistia.com/doc/data-api#projects_response)
 */
public struct WistiaProject {

    /// A unique numeric identifier for the project within the system.
    public let projectID: Int

    /// The project's display name.
    public var name: String?

    /// The project's description.
    public var description: String?

    /// The number of different medias that have been uploaded to the project.
    public var mediaCount: Int?

    /// The date that the project was originally created.
//    public var created: NSDate

    /// The date that the project was last updated.
//    public var updated: NSDate

    /// A private hashed id, uniquely identifying the project within the system.
    public let hashedID: String

    /// A boolean indicating whether or not anonymous uploads are enabled for the project.
//    public var anonymousCanUpload: Bool

    /// A boolean indicating whether or not anonymous downloads are enabled for this project.
//    public var anonymousCanDownload: Bool

    /// A boolean indicating whether the project is available for public (anonymous) viewing.
//    public var isPublic: Bool

    /// If the project is public, this field contains a string representing the ID used for referencing the project in public URLs.
//    public var publicID: String?

    /// An optional, not necessarily exhaustive array of `WistiaMedia` within this project.
    /// Array is `nil` if it hasn't been fetched, empty if it was fetched and returned zero elements.
    public var medias: [WistiaMedia]?

}
