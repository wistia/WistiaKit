//
//  WistiaUser.swift
//  Pods
//
//  Created by Daniel Spinosa on 1/26/17.
//
//

import Foundation

/**
 Basic information about the currently logged in user.
 
 Not part of the public Wistia Data API.
 
 - Warning: Use this unofficial API at your own risk

 */
public struct WistiaUser {

    /// Numeric id of the user
    public let userID:Int

    /// Creation time of this user
    public let created: Date?

    /// Full name
    public let name: String?

    /// First name
    public let firstName: String?

    /// Last name
    public let lastName: String?

    /// Email address
    public let email: String?

    /// Title
    public let title: String?

}

extension WistiaUser: WistiaJSONParsable {

    /// Initialize a WistiaUser from the provided JSON hash.
    ///
    /// - Note: Prints error message to console on parsing issue.
    ///
    /// - parameter dictionary: JSON hash representing the WistiaUser.
    ///
    /// - returns: Initialized WistiaUser if parsing is successful.
    init?(from dictionary: [String: Any]) {
        let parser = Parser(dictionary: dictionary)
        do {
            userID = try parser.fetch("id")
            created = parser.fetchOptional("created") { Parser.RFC3339DateFormatter.date(from: $0) }
            name = try parser.fetchOptional("name")
            firstName = try parser.fetchOptional("first")
            lastName = try parser.fetchOptional("last")
            email = try parser.fetchOptional("email")
            title = try parser.fetchOptional("title")
        } catch let error {
            print(error)
            return nil
        }
    }
    
}
