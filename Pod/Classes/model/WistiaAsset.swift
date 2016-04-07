//
//  WistiaAsset.swift
//  Stargazer
//
//  Created by Daniel Spinosa on 1/25/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import Foundation


public struct WistiaAsset {

    var media: WistiaMedia
    var type: String
    var displayName: String
    var container: String
    var codec: String
    var width: Int64
    var height: Int64
    var size: Int64
    var ext: String
    var bitrate: Int64
    var urlString: String
    var slug: String

    var url:NSURL {
        get {
            return NSURL(string: self.urlString)!
        }
    }
}
