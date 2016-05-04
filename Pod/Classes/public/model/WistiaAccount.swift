//
//  WistiaAccount.swift
//  Pods
//
//  Created by Daniel Spinosa on 5/4/16.
//
//

import Foundation

/*
 id	Numeric id of the account
 name	Account name
 url	Account's main Wistia URL (e.g. http://brendan.wistia.com)
 mediaCount	The total number of medias in this account
 */

public struct WistiaAccount {

    public let accountID:Int
    public let name:String
    public let accountURLString:String
    var accountURL: NSURL {
        get {
            return NSURL(string: accountURLString)!
        }
    }
    public let mediaCount:Int
    
}