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
    public var accountURL: NSURL {
        get {
            return NSURL(string: accountURLString)!
        }
    }

    /// The total number of medias in this account
    public let mediaCount:Int
}
