//
//  WistiaProject.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 4/28/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
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
    public var created: Date?

    /// The date that the project was last updated.
    public var updated: Date?

    /// A private hashed id, uniquely identifying the project within the system.
    public let hashedID: String

    /// A boolean indicating whether or not anonymous uploads are enabled for the project.
    public var anonymousCanUpload: Bool

    /// A boolean indicating whether or not anonymous downloads are enabled for this project.
    public var anonymousCanDownload: Bool

    /// A boolean indicating whether the project is available for public (anonymous) viewing.
    public var isPublic: Bool

    /// If the project is public, this field contains a string representing the ID used for referencing the project in public URLs.
    public var publicID: String?

    /// An optional, not necessarily exhaustive array of `WistiaMedia` within this project.
    /// Array is `nil` if it hasn't been fetched, empty if it was fetched and returned zero elements.
    public var medias: [WistiaMedia]?

}

extension WistiaProject {

    init?(from dictionary: [String: Any]) {
        let parser = Parser(dictionary: dictionary)
        do {
            projectID = try parser.fetch("id")
            if let hid: String = try parser.fetchOptional("hashed_id") {
                hashedID = hid
            } else {
                hashedID = try parser.fetch("hashedId")
            }
            name = try parser.fetchOptional("name")
            description = try parser.fetchOptional("description")
            mediaCount = try parser.fetchOptional("mediaCount")
            created = try parser.fetchOptional("created") { Parser.RFC3339DateFormatter.date(from: $0) }
            updated = try parser.fetchOptional("updated") { Parser.RFC3339DateFormatter.date(from: $0) }
            anonymousCanUpload = try parser.fetchOptional("anonymousCanUpload", default: false)
            anonymousCanDownload = try parser.fetchOptional("anonymousCanDownload", default: false)
            isPublic = try parser.fetchOptional("public", default: false)
            publicID = try parser.fetchOptional("publicID")
            medias = try parser.fetchArrayOptional("medias") { ModelBuilder.wistiaMedia(from: $0) }

        } catch let error {
            print(error)
            return nil
        }
    }

}

//MARK: - WistiaProject Equality

extension WistiaProject: Equatable { }

/**
 Compare two `WistiaProject`s for equality.

 - Returns: `True` if the `hashedID`s of the given `WistiaProject`s match.

 */
public func ==(lhs: WistiaProject, rhs: WistiaProject) -> Bool {

    return lhs.hashedID == rhs.hashedID
}
