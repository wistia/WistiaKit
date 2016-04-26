//
//  WistiaAPI.swift
//  Stargazer
//
//  Created by Daniel Spinosa on 1/25/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import Alamofire

internal class WistiaAPI {

    internal static func mediaInfoForHash(hash:String, completionHandler: (media:WistiaMedia?)->() ) {
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
                    embedOptions = media["embed_options"] as? [String:AnyObject],
                    unnamedAssets = media["assets"] as? [[String:AnyObject]] {
                    //optional attributes
                    let spherical = (media["spherical"] as? Bool) ?? false

                    // -- Embed Options--
                    let mediaEmbedOptions = embedOptionsFrom(embedOptions)

                    // -- Wistia Media --
                    var wMedia = WistiaMedia(distilleryURLString: distilleryURLString, accountKey: accountKey, mediaKey: mediaKey, duration: duration, hashedID: hashedID, spherical: spherical, name: name, unnamedAssets: [WistiaAsset](), embedOptions: mediaEmbedOptions)

                    // -- Unamed Assets --
                    let wistiaAssets = wistiaAssetsFrom(unnamedAssets, forMedia:wMedia)
                    wMedia.unnamedAssets = wistiaAssets

                    completionHandler(media: wMedia)
                } else {
                    completionHandler(media: nil)
                }
        }
        
    }

    private static func wistiaAssetsFrom(assetsHashArray:[[String:AnyObject]], forMedia media:WistiaMedia) -> [WistiaAsset] {
        var wistiaAssets = [WistiaAsset]()
        for rawAsset in assetsHashArray {
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

                let wistiaAsset = WistiaAsset(media: media, type: type, displayName: displayName, container: container, codec: codec, width: Int64(width), height: Int64(height), size: Int64(size), ext: ext, bitrate: Int64(bitrate), urlString: urlString, slug: slug)

                wistiaAssets.append(wistiaAsset)
            }
        }
        return wistiaAssets
    }

    private static func embedOptionsFrom(embedOptionsHash:[String:AnyObject]) -> WistiaMediaEmbedOptions {
        //init with defaults
        var mediaEmbedOptions = WistiaMediaEmbedOptions()

        //...override with custom attributes, if specified
        if let playerColor = embedOptionsHash["playerColor"] as? String {
            mediaEmbedOptions.playerColor = UIColor.wk_fromHexString(playerColor)
        }

        if let bigPlayButton = embedOptionsHash["playButton"] as? NSString {
            mediaEmbedOptions.bigPlayButton = bigPlayButton.boolValue
        }

        if let smallPlayButton = embedOptionsHash["smallPlayButton"] as? NSString {
            mediaEmbedOptions.smallPlayButton = smallPlayButton.boolValue
        }

        if let playbar = embedOptionsHash["playbar"] as? NSString {
            mediaEmbedOptions.playbar = playbar.boolValue
        }

        if let fullscreenButton = embedOptionsHash["fullscreenButton"] as? NSString {
            mediaEmbedOptions.fullscreenButton = fullscreenButton.boolValue
        }

        if let controlsVisibleOnLoad = embedOptionsHash["controlsVisibleOnLoad"] as? NSString {
            mediaEmbedOptions.controlsVisibleOnLoad = controlsVisibleOnLoad.boolValue
        }

        if let autoplay = embedOptionsHash["autoPlay"] as? NSString {
            mediaEmbedOptions.autoplay = autoplay.boolValue
        }

        if let endVideoBehavior = embedOptionsHash["endVideoBehavior"] as? String {
            mediaEmbedOptions.endVideoBehaviorString = endVideoBehavior
        }

        if let stillURLString = embedOptionsHash["stillUrl"] as? String, stillURL = NSURL(string: stillURLString) {
            mediaEmbedOptions.stillURL = stillURL
        }

        if let plugin = embedOptionsHash["plugin"] as? [String:AnyObject] {
            if let socialBar = plugin["socialbar-v1"] {
                mediaEmbedOptions.actionButton = true
            }
            if let captionsHash = plugin["captions-v1"] as? [String:AnyObject],
                captionsOn = captionsHash["onByDefault"] as? NSString {
                mediaEmbedOptions.captions = captionsOn.boolValue
            }
        }

        return mediaEmbedOptions
    }

}
