//
//  WistiaAPI.swift
//  Stargazer
//
//  Created by Daniel Spinosa on 1/25/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import Alamofire

internal class WistiaAPI {

    static func mediaInfoForHash(hash:String, completionHandler: (media:WistiaMedia?)->() ) {
        Alamofire.request(.GET, "https://fast.wistia.net/embed/medias/\(hash).json", parameters: nil)
            .responseJSON { response in

                if let JSON = response.result.value as? [String:AnyObject],
                    media = JSON["media"] as? [String:AnyObject],
                    name = media["name"] as? String,
                    distilleryURLString = media["distilleryUrl"] as? String,
                    accountKey = media["accountKey"] as? String,
                    mediaKey = media["mediaKey"] as? String,
                    duration = media["duration"] as? Float,
                    hashedID = media["hashedId"] as? String,
                    unnamedAssets = media["unnamed_assets"] as? [[String:AnyObject]] {
                        //optional attributes
                        let spherical = (media["spherical"] as? Bool) ?? false

                        var wMedia = WistiaMedia(distilleryURLString: distilleryURLString, accountKey: accountKey, mediaKey: mediaKey, duration: duration, hashedID: hashedID, spherical: spherical, name: name, unnamedAssets: [WistiaAsset]())

                        // -- UnamedAssets --
                        var wistiaAssets = [WistiaAsset]()
                        for rawAsset in unnamedAssets {
                            if let type = rawAsset["type"] as? String,
                                displayName = rawAsset["display_name"] as? String,
                                width = rawAsset["width"] as? Int,
                                height = rawAsset["height"] as? Int,
                                size = rawAsset["size"] as? Int,
                                ext = rawAsset["ext"] as? String,
                                bitrate = rawAsset["bitrate"] as? Int,
                                urlString = rawAsset["url"] as? String,
                                slug = rawAsset["slug"] as? String {
                                    //optional attribrutes
                                    let container = rawAsset["container"] as? String ?? ""
                                    let codec = rawAsset["codec"] as? String ?? ""

                                    let wistiaAsset = WistiaAsset(media: wMedia, type: type, displayName: displayName, container: container, codec: codec, width: Int64(width), height: Int64(height), size: Int64(size), ext: ext, bitrate: Int64(bitrate), urlString: urlString, slug: slug)

                                    wistiaAssets.append(wistiaAsset)
                            }
                        }

                        wMedia.unnamedAssets = wistiaAssets

                        completionHandler(media: wMedia)
                } else {
                    completionHandler(media: nil)
                }
        }

    }
    
}
