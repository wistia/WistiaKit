//
//  ModelBuilder.swift
//  Pods
//
//  Created by Daniel Spinosa on 5/4/16.
//
//  Converts JSON-like Hashes to Structs

import Foundation

internal class ModelBuilder {

    internal static func accountFromHash(accountHash:[String: AnyObject]) -> WistiaAccount? {

        if let
            //required
            accountID = accountHash["id"] as? Int,
            name = accountHash["name"] as? String,
            accountURLString = accountHash["url"] as? String,
            mediaCount = accountHash["mediaCount"] as? Int {

            return WistiaAccount(accountID: accountID, name: name, accountURLString: accountURLString, mediaCount: mediaCount)
        } else {
            return nil
        }

    }

    internal static func projectFromHash(projectHash:[String: AnyObject]) -> WistiaProject? {
        if let
            //required
            projectID = projectHash["id"] as? Int {
            //required and annoying
            let hashedID: String
            if let hid = projectHash["hashed_id"] as? String {
                hashedID = hid
            } else if let hid = projectHash["hashedId"] as? String {
                hashedID = hid
            } else {
                return nil
            }
            //optional
            let name = projectHash["name"] as? String
            let description = projectHash["description"] as? String
            let mediaCount = projectHash["mediaCount"] as? Int

            return WistiaProject(projectID: projectID, name: name, description: description, mediaCount: mediaCount, hashedID: hashedID, medias: nil)
        }
        
        return nil
    }

    internal static func mediaFromHash(mediaHash:[String: AnyObject]) -> WistiaMedia? {
        if let
            //required
            duration = mediaHash["duration"] as? Float,
            assets = mediaHash["assets"] as? [[String:AnyObject]] {
            let status:WistiaObjectStatus
            if let statusString = mediaHash["status"] as? String {
                status = WistiaObjectStatus(failsafeFromRawString: statusString)
            } else if let statusInt = mediaHash["status"] as? Int {
                status = WistiaObjectStatus(failsafeFromRaw: statusInt)
            } else {
                status = WistiaObjectStatus.Failed
            }
            //required and annoying
            let hashedID: String
            if let hid = mediaHash["hashedId"] as? String {
                hashedID = hid
            } else if let hid = mediaHash["hashed_id"] as? String {
                hashedID = hid
            } else {
                return nil
            }
            //optional
            let mediaID = mediaHash["id"] as? Int
            let name = mediaHash["name"] as? String
            let description = mediaHash["description"] as? String
            let spherical = (mediaHash["spherical"] as? Bool) ?? false
            let thumbnail:(String, Int, Int)?
            if let thumbnailHash = mediaHash["thumbnail"] as? [String: AnyObject],
                thumbnailURLString = thumbnailHash["url"] as? String,
                thumbnailWidth = thumbnailHash["width"] as? Int,
                thumbnailHeight = thumbnailHash["height"] as? Int {

                thumbnail = (url: thumbnailURLString, width: thumbnailWidth, height: thumbnailHeight)
            } else {
                thumbnail = nil
            }
            let distilleryURLString = mediaHash["distilleryUrl"] as? String
            let accountKey = mediaHash["accountKey"] as? String
            let mediaKey = mediaHash["mediaKey"] as? String
            let embedOptions = mediaHash["embed_options"] as? [String:AnyObject]
            let mediaEmbedOptions = ModelBuilder.embedOptionsFromHash(embedOptions)

            var wMedia = WistiaMedia(mediaID: mediaID, distilleryURLString: distilleryURLString, accountKey: accountKey, mediaKey: mediaKey, status: status, duration: duration, hashedID: hashedID, description: description, spherical: spherical, name: name, assets: [WistiaAsset](), thumbnail: thumbnail, embedOptions: mediaEmbedOptions)

            // -- Assets --
            let wistiaAssets = wistiaAssetsFromHash(assets, forMedia:wMedia)
            wMedia.assets = wistiaAssets

            return wMedia
        }
        return nil
    }

    internal static func wistiaAssetsFromHash(assetsHashArray:[[String:AnyObject]], forMedia media:WistiaMedia) -> [WistiaAsset] {
        var wistiaAssets = [WistiaAsset]()
        for rawAsset in assetsHashArray {
            if let
                //requried
                width = rawAsset["width"] as? Int,
                height = rawAsset["height"] as? Int,
                type = rawAsset["type"] as? String,
                urlString = rawAsset["url"] as? String {
                //required and annoying
                var size:Int64? = nil
                if let s = rawAsset["size"] as? Int {
                    size = Int64(s)
                } else if let s = rawAsset["filesize"] as? Int {
                    size = Int64(s)
                }
                //optional attribrutes
                let displayName = rawAsset["display_name"] as? String
                let container = rawAsset["container"] as? String
                let codec = rawAsset["codec"] as? String
                let ext = rawAsset["ext"] as? String
                var bitrate: Int64? = nil
                if let b = rawAsset["bitrate"] as? Int {
                    bitrate = Int64(b)
                }
                var status:WistiaObjectStatus? = nil
                if let assetStatus = rawAsset["status"] as? Int {
                    status = WistiaObjectStatus(failsafeFromRaw: assetStatus)
                }
                let slug = rawAsset["slug"] as? String

                let wistiaAsset = WistiaAsset(media: media, type: type, displayName: displayName, container: container, codec: codec, width: Int64(width), height: Int64(height), size: size, ext: ext, bitrate: bitrate, status: status, urlString: urlString, slug: slug)

                wistiaAssets.append(wistiaAsset)
            }
        }
        return wistiaAssets
    }

    internal static func embedOptionsFromHash(mediaEmbedOptionsHash:[String:AnyObject]?) -> WistiaMediaEmbedOptions? {
        guard let embedOptionsHash = mediaEmbedOptionsHash else { return nil }

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
            if let _ = plugin["socialbar-v1"] {
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