//
//  _ModelBuilder.swift
//  WistiaKit internal
//
//  Created by Daniel Spinosa on 5/4/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//
//  Converts JSON-like Hashes to Structs

import Foundation

internal class ModelBuilder {

    internal static func embedOptions(from mediaEmbedOptionsHash:[String:Any]?) -> WistiaMediaEmbedOptions? {
        guard let embedOptionsHash = mediaEmbedOptionsHash else { return nil }

        //init with defaults
        var mediaEmbedOptions = WistiaMediaEmbedOptions()

        //...override with custom attributes, if specified
        if let playerColor = embedOptionsHash["playerColor"] as? String {
            mediaEmbedOptions.playerColor = UIColor.wk_from(hexString: playerColor)
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

        if let stillURLString = embedOptionsHash["stillUrl"] as? String, let stillURL = URL(string: stillURLString) {
            mediaEmbedOptions.stillURL = stillURL
        }

        if let plugin = embedOptionsHash["plugin"] as? [String: Any] {
            if let shareHash = plugin["share"] as? [String: Any] {
                // share is the new stuff, preferred over socialbar-v1
                // presence of this hash means sharing is on unless it's explcity set to off
                mediaEmbedOptions.actionButton = true
                if let socialBarOn = shareHash["on"] as? NSString {
                    mediaEmbedOptions.actionButton = socialBarOn.boolValue
                }
                if let pageURL = shareHash["pageUrl"] as? String {
                    mediaEmbedOptions.actionShareURLString = pageURL
                }
                if let pageTitle = shareHash["pageTitle"] as? String {
                    mediaEmbedOptions.actionShareTitle = pageTitle
                }

            } else if let socialBarHash = plugin["socialbar-v1"] as? [String: Any] {
                // presence of this hash means sharing is on unless it's explcity set to off
                mediaEmbedOptions.actionButton = true
                if let socialBarOn = socialBarHash["on"] as? NSString {
                    mediaEmbedOptions.actionButton = socialBarOn.boolValue
                }
                if let pageURL = socialBarHash["pageUrl"] as? String {
                    mediaEmbedOptions.actionShareURLString = pageURL
                }
                if let pageTitle = socialBarHash["pageTitle"] as? String {
                    mediaEmbedOptions.actionShareTitle = pageTitle
                }
            }
            
            if let captionsHash = plugin["captions-v1"] as? [String: Any] {
                // presence of this hash means captions are available unless stated otherwise
                mediaEmbedOptions.captionsAvailable = true
                if let captionsAvailable = captionsHash["on"] as? NSString {
                    mediaEmbedOptions.captionsAvailable = captionsAvailable.boolValue
                }
                if let captionsOnByDefault = captionsHash["onByDefault"] as? NSString {
                    mediaEmbedOptions.captionsOnByDefault = mediaEmbedOptions.captionsAvailable && captionsOnByDefault.boolValue
                }

            }
        }
        
        return mediaEmbedOptions
    }

    internal static func wistiaMediaStats(from statsHash:[String: Any]?) -> WistiaMediaStats? {
        if let sHash = statsHash,
            let pageLoads = sHash["pageLoads"] as? Int,
            let visitors = sHash["visitors"] as? Int,
            let percentOfVisitorsClickingPlay = sHash["percentOfVisitorsClickingPlay"] as? Int,
            let plays = sHash["plays"] as? Int,
            let averagePercentWatched = sHash["averagePercentWatched"] as? Int {

            return WistiaMediaStats(pageLoads: pageLoads, visitors: visitors, percentOfVisitorsClickingPlay: percentOfVisitorsClickingPlay, plays: plays, averagePercentWatched: averagePercentWatched)
        }
        return nil
    }

    internal static func wistiaCaptions(from captionsHash:[String: Any]?) -> WistiaCaptions? {
        if let cHash = captionsHash,
            let cID = cHash["id"] as? Int,
            let language = cHash["language"] as? String,
            let englishName = cHash["english_name"] as? String,
            let nativeName = cHash["native_name"] as? String,
            let rightToLeft = cHash["right_to_left"] as? Bool,
            let linesHash = cHash["hash"] as? [String: Any],
            let lines = linesHash["lines"] as? [[String:Any]] {

            var captionSegments = [WistiaCaptionSegment]()
            for line in lines {
                if let start = line["start"] as? Float,
                    let end = line["end"] as? Float,
                    let text = line["text"] as? [String] {
                    let seg = WistiaCaptionSegment(startTime: start, endTime: end, text: text)
                    captionSegments.append(seg)
                }
            }

            //WistiaCaptionsRenderer assumes segments are in order
            captionSegments.sort(by: { (segA, segB) -> Bool in
                segA.startTime < segB.startTime
            })

            return WistiaCaptions(captionsID: cID, languageCode: language, englishName: englishName, nativeName: nativeName, rightToLeft: rightToLeft, captionSegments: captionSegments)
        }

        return nil
    }

}
