//
//  WistiaAPI.swift
//  Stargazer
//
//  Created by Daniel Spinosa on 1/25/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import Alamofire

public class WistiaAPI {

    private static let APIBaseURL = "https://api.wistia.com/v1"

    public let apiToken:String

    public init(apiToken:String) {
        self.apiToken = apiToken
    }

    //data api docs: http://wistia.com/doc/data-api#projects_list
    public func listProjects(page page: Int = 1, perPage: Int = 10 /* TODO: SORT */, completionHandler: (projects:[WistiaProject])->() ) {
        let params: [String : AnyObject] = ["page" : page, "per_page" : perPage, "api_password" : apiToken, "sort_by" : "updated", "sort_direction" : 1]

        Alamofire.request(.GET, "\(WistiaAPI.APIBaseURL)/projects.json", parameters: params)
            .responseJSON { response in

                if let JSON = response.result.value as? [[String: AnyObject]] {
                    var projects = [WistiaProject]()
                    for projectHash in JSON {
                        if let p = WistiaAPI.projectFrom(projectHash) {
                            projects.append(p)
                        } else {
                            print("ERROR parsing project hash: \(projectHash)")
                        }
                    }
                    completionHandler(projects: projects)

                } else {
                    completionHandler(projects: [])
                }
            }
    }

    // http://wistia.com/doc/data-api#medias_list
    //Use the medias/list route but return medias organized by project
    //leave project nil to get for any/all projects
    public func listMediasByProject(page page: Int = 1, perPage: Int = 10 /* TODO: SORT */, limitedToProject project: WistiaProject? = nil, completionHandler: (projects:[WistiaProject])->() ) {
        var params: [String : AnyObject] = ["page" : page, "per_page" : perPage, "api_password" : apiToken]
        if let proj = project {
            params["project_id"] = proj.projectID
        }

        Alamofire.request(.GET, "\(WistiaAPI.APIBaseURL)/medias.json", parameters: params)
            .responseJSON { response in

                if let JSON = response.result.value as? [[String: AnyObject]] {
                    var projectsByHashedID = [String: WistiaProject]()

                    for mediaHash in JSON {
                        //1) Make Media
                        if let media = WistiaAPI.mediaFrom(mediaHash) {

                            //2) Find project it's in (or create it anew)
                            let targetProject:WistiaProject
                            if let projectHash = mediaHash["project"] as? [String: AnyObject], var project = WistiaAPI.projectFrom(projectHash) {
                                if projectsByHashedID.indexForKey(project.hashedID) == nil {
                                    project.medias = [WistiaMedia]()
                                    projectsByHashedID[project.hashedID] = project
                                }
                                //3) add media to project it's in
                                projectsByHashedID[project.hashedID]!.medias!.append(media)
                            }
                        }

                    }
                    completionHandler(projects: Array(projectsByHashedID.values))

                } else {
                    completionHandler(projects: [])
                }
        }
    }

    public static func mediaInfoForHash(hash:String, completionHandler: (media:WistiaMedia?)->() ) {
        Alamofire.request(.GET, "https://fast.wistia.net/embed/medias/\(hash).json", parameters: nil)
            .responseJSON { response in

                if let JSON = response.result.value as? [String:AnyObject],
                    media = JSON["media"] as? [String:AnyObject],
                    name = media["name"] as? String,
                    distilleryURLString = media["distilleryUrl"] as? String,
                    accountKey = media["accountKey"] as? String,
                    mediaKey = media["mediaKey"] as? String,
                    mediaStatus = media["status"] as? Int,
                    duration = media["duration"] as? Float,
                    hashedID = media["hashedId"] as? String,
                    embedOptions = media["embed_options"] as? [String:AnyObject],
                    assets = media["assets"] as? [[String:AnyObject]] {
                    //optional attributes
                    let spherical = (media["spherical"] as? Bool) ?? false

                    // -- Embed Options--
                    let mediaEmbedOptions = embedOptionsFrom(embedOptions)

                    // -- Wistia Media --
                    var wMedia = WistiaMedia(mediaID: nil, distilleryURLString: distilleryURLString, accountKey: accountKey, mediaKey: mediaKey, status: WistiaObjectStatus(failsafeFromRaw: mediaStatus), duration: duration, hashedID: hashedID, description: nil, spherical: spherical, name: name, assets: [WistiaAsset](), thumbnail: nil, embedOptions: mediaEmbedOptions)

                    // -- Assets --
                    let wistiaAssets = wistiaAssetsFrom(assets, forMedia:wMedia)
                    wMedia.assets = wistiaAssets

                    completionHandler(media: wMedia)
                } else {
                    completionHandler(media: nil)
                }
        }
        
    }

    //MARK: - Private Static Parsers

    //TODO: DRY up the stuff used above from the fast route with this
    private static func mediaFrom(mediaHash:[String: AnyObject]) -> WistiaMedia? {
        if let
            //required
            mediaID = mediaHash["id"] as? Int,
            hashedID = mediaHash["hashed_id"] as? String,
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
            //optional
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

            var wMedia = WistiaMedia(mediaID: mediaID, distilleryURLString: nil, accountKey: nil, mediaKey: nil, status: status, duration: duration, hashedID: hashedID, description: description, spherical: spherical, name: name, assets: [WistiaAsset](), thumbnail: thumbnail, embedOptions: nil)

            // -- Assets --
            let wistiaAssets = wistiaAssetsFrom(assets, forMedia:wMedia)
            wMedia.assets = wistiaAssets

            return wMedia
        }
        return nil
    }

    private static func projectFrom(projectHash:[String: AnyObject]) -> WistiaProject? {

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

    private static func wistiaAssetsFrom(assetsHashArray:[[String:AnyObject]], forMedia media:WistiaMedia) -> [WistiaAsset] {
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
