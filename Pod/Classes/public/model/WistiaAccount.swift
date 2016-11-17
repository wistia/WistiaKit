//
//  WistiaAccount.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 5/4/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import Foundation

/**
 Basic information about your account.

 See [Wistia Data API: Account](http://wistia.com/doc/data-api#account)
 */
public struct WistiaAccount {

    /// Numeric id of the account
    public let accountID:Int

    /// Account name
    public let name:String

    /// Account's main Wistia URL (e.g. http://brendan.wistia.com) as a String
    public let accountURLString:String

    /// Account's main Wistia URL (e.g. http://brendan.wistia.com)
    public var accountURL: URL {
        get {
            return URL(string: accountURLString)!
        }
    }

    /// The total number of medias in this account
    public let mediaCount:Int

}

extension WistiaAccount: WistiaJSONParsable {

    /// Initialize a WistiaAccount from the provided JSON hash.
    ///
    /// - Note: Prints error message to console on parsing issue.
    ///
    /// - parameter dictionary: JSON hash representing the WistiaAccount.
    ///
    /// - returns: Initialized WistiaAccount if parsing is successful.
    init?(from dictionary: [String: Any]) {
        let parser = Parser(dictionary: dictionary)
        do {
            accountID = try parser.fetch("id")
            name = try parser.fetch("name")
            accountURLString = try parser.fetch("url")
            mediaCount = try parser.fetch("mediaCount")
        } catch let error {
            print(error)
            return nil
        }
    }

}
