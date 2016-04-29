//
//  WistiaMedia.swift
//  Stargazer
//
//  Created by Daniel Spinosa on 1/25/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import Foundation

public struct WistiaMedia {

    public var mediaID: Int?
    var distilleryURLString: String?
    var accountKey: String?
    var mediaKey: String?
    var status: WistiaObjectStatus
    var duration: Float
    public var hashedID: String
    public var description: String?
    var spherical: Bool
    public var name: String?
    public var assets: [WistiaAsset]
    public var thumbnail: (url: String, width: Int, height: Int)?
    var embedOptions: WistiaMediaEmbedOptions?
    
    var distilleryURL: NSURL? {
        get {
            if let urlString = self.distilleryURLString, url = NSURL(string: urlString) {
                return url
            } else {
                return nil
            }
        }
    }
}

extension WistiaMedia: Equatable { }

public func ==(lhs: WistiaMedia, rhs: WistiaMedia) -> Bool {

    return lhs.hashedID == rhs.hashedID
}
