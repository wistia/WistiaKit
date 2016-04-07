//
//  WistiaMedia.swift
//  Stargazer
//
//  Created by Daniel Spinosa on 1/25/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import Foundation

public struct WistiaMedia {

    var distilleryURLString: String
    var accountKey: String
    var mediaKey: String
    var duration: Float
    var hashedID: String
    var spherical: Bool
    var name: String
    var unnamedAssets: [WistiaAsset]
    
    var distilleryURL: NSURL {
        get {
            return NSURL(string: self.distilleryURLString)!
        }
    }
}

extension WistiaMedia: Equatable { }

public func ==(lhs: WistiaMedia, rhs: WistiaMedia) -> Bool {

    return lhs.hashedID == rhs.hashedID
}