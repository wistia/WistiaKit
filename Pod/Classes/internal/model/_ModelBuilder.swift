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

}
