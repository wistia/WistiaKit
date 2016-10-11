//
//  WistiaMediaEmbedOptions.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 4/13/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import Foundation

/**
 Most player customizations are communicated through the API in a hash called
 `embed_options`.  These are stored as a `WistiaMediaEmbedOptions` on the
 `WistiaMedia` to which they apply.

 Customizations may be visualized by using the `WistiaPlayerViewController` and
 accompanying xib for display.  If you are using the `WistiaPlayer`, customizations 
 will not have any effect.

 - Note: Wistia customizations not currently supported:
 - Turnstyle
 - Call To Action & Annotation Links
 - Social Bar (replaced with standard iOS action button)
 */
public struct WistiaMediaEmbedOptions {

    /// Tint for controls (default: #7b796a)
    public var playerColor: UIColor = UIColor(red: 0.482, green: 0.475, blue: 0.4157, alpha: 1)

    /// Overlay large play button on poster view before playback has started (default: true)
    public var bigPlayButton: Bool = true

    /// Show play/pause button on playbar (default: true)
    public var smallPlayButton: Bool = true

    /// Show the scrubber (default: true)
    public var playbar: Bool = true

    /// Show the fullscreen button on playbar (default: true)
    public var fullscreenButton: Bool = true

    /// Show the playbar on poster view before playback has started (default: true)
    public var controlsVisibleOnLoad: Bool = true

    /// Automatically play the video once it has loaded (default: false)
    public var autoplay: Bool = false

    /// What do do when the video ends (default: PauseOnLastFrame) as a String
    public var endVideoBehaviorString: String = "pause" {
        didSet {
            self.endVideoBehavior = WistiaEndVideoBehavior.fromString(self.endVideoBehaviorString)
        }
    }
    
    /// What do do when the video ends (default: PauseOnLastFrame) as a String
    public var endVideoBehavior: WistiaEndVideoBehavior = .pauseOnLastFrame

    /// Image to show for poster before playback (default: nil - the first frame of video is shown)
    public var stillURL: URL? = nil

    /// Show the standard iOS action button (similar to Wistia Social Bar on web) (default: false)
    public var actionButton: Bool = false

    /// The link to use when sharing
    public var actionShareURLString: String? = nil

    /// The copy to use when sharing
    public var actionShareTitle: String? = nil

    /// Are captions available and enabled for this video (default: false)
    public var captionsAvailable: Bool = false

    /// Show captions by default (default: false)
    public var captionsOnByDefault: Bool = false

    /**
     Enumeration of options of what should happen automatically when a video reaches the end.
     - `PauseOnLastFrame` : Continue to diplay the last frame, remain paused (deafult).
     - `ResetToTimeZero` : Return to the start of the video, remain paused.
     - `LoopVideo` : Return to the start of the video and resume playback there.
    */
    public enum WistiaEndVideoBehavior {
        /// Continue to diplay the last frame, remain paused (deafult).
        case pauseOnLastFrame

        /// Return to the start of the video, remain paused.
        case resetToTimeZero

        /// Return to the start of the video and resume playback there.
        case loopVideo

        static func fromString(_ behavior:String) -> WistiaEndVideoBehavior {
            switch behavior {
            case "default":
                fallthrough
            case "pause":
                return .pauseOnLastFrame
            case "reset":
                return .resetToTimeZero
            case "loop":
                return .loopVideo
            default:
                return .pauseOnLastFrame
            }
        }

        func description() -> String {
            switch self {
            case .pauseOnLastFrame:
                return "pause"
            case .loopVideo:
                return "loop"
            case .resetToTimeZero:
                return "reset"
            }
        }
    }
}

extension WistiaMediaEmbedOptions {

    /// Initialize a WistiaMediaEmbedOptions from the provided JSON hash.
    ///
    /// - Note: Prints error message to console on parsing issue.
    ///
    /// - parameter dictionary: JSON hash representing the WistiaMediaEmbedOptions.
    ///
    /// - returns: Initialized WistiaMediaEmbedOptions if parsing is successful.
    init?(from dictionary: [String: Any]?) {
        guard dictionary != nil else { return nil }
        let parser = Parser(dictionary: dictionary)
        do {

            playerColor = parser.fetchOptional("playerColor", default: UIColor(red: 0.482, green: 0.475, blue: 0.4157, alpha: 1)) { UIColor.wk_from(hexString: $0) }
            bigPlayButton = parser.fetchOptional("playButton", default: true) { (s: NSString) -> Bool in s.boolValue }
            smallPlayButton = parser.fetchOptional("smallPlayButton", default: true) { (s: NSString) -> Bool in s.boolValue }
            playbar = parser.fetchOptional("playbar", default: true) { (s: NSString) -> Bool in s.boolValue }
            fullscreenButton = parser.fetchOptional("fullscreenButton", default: true) { (s: NSString) -> Bool in s.boolValue }
            controlsVisibleOnLoad = parser.fetchOptional("controlsVisibleOnLoad", default: true) { (s: NSString) -> Bool in s.boolValue }
            autoplay = parser.fetchOptional("autoPlay", default: false) { (s: NSString) -> Bool in s.boolValue }
            endVideoBehaviorString = try parser.fetchOptional("endVideoBehavior", default: "pause")
            stillURL = parser.fetchOptional("stillUrl") { URL(string: $0) }

            if let pluginParser = parser.fetchOptional("plugin", transformation: { (dict: [String: Any]) -> Parser? in
                Parser(dictionary: dict)
            }) {
                // share is the new stuff, preferred over socialbar-v1
                if let shareParser = pluginParser.fetchOptional("share", transformation: { (dict: [String: Any]) -> Parser? in
                    Parser(dictionary: dict)
                }) {
                    // presence of this hash means sharing is on unless it's explcity set to off
                    actionButton = shareParser.fetchOptional("on", default: true) { (s: NSString) -> Bool in s.boolValue }
                    actionShareURLString = try shareParser.fetchOptional("pageUrl")
                    actionShareTitle = try shareParser.fetchOptional("pageTitle")

                } else if let socialBarV1Parser = pluginParser.fetchOptional("share", transformation: { (dict: [String: Any]) -> Parser? in
                    Parser(dictionary: dict)
                }) {
                    // presence of this hash means sharing is on unless it's explcity set to off
                    actionButton = socialBarV1Parser.fetchOptional("on", default: true) { (s: NSString) -> Bool in s.boolValue }
                    actionShareURLString = try socialBarV1Parser.fetchOptional("pageUrl")
                    actionShareTitle = try socialBarV1Parser.fetchOptional("pageTitle")
                }

                if let captionsParser = pluginParser.fetchOptional("captions-v1", transformation: { (dict: [String: Any]) -> Parser? in
                    Parser(dictionary: dict)
                }) {
                    // presence of this hash means captions are available unless stated otherwise
                    captionsAvailable = captionsParser.fetchOptional("on", default: true) { (s: NSString) -> Bool in s.boolValue }
                    captionsOnByDefault = captionsAvailable && captionsParser.fetchOptional("onByDefault", default: false) { (s: NSString) -> Bool in s.boolValue }
                }

            }

        } catch let error {
            print(error)
            return nil
        }
    }

    internal func toJson() -> [String: Any] {
        var json = [String: Any]()

        json["playerColor"] = playerColor.wk_toHexString()
        json["playButton"] = bigPlayButton
        json["smallPlayButton"] = smallPlayButton
        json["playbar"] = playbar
        json["fullscreenButton"] = fullscreenButton
        json["controlsVisibleOnLoad"] = controlsVisibleOnLoad
        json["autoPlay"] = autoplay
        json["endVideoBehavior"] = endVideoBehavior.description()
        json["stillUrl"] = stillURL?.description

        var share = [String: Any]()
        share["on"] = actionButton
        share["pageUrl"] = actionShareURLString
        share["pageTitle"] = actionShareTitle
        json["share"] = share

        var captions = [String: Any]()
        captions["on"] = captionsAvailable
        captions["onByDefault"] = captionsOnByDefault
        json["captions-v1"] = captions

        return json
    }
    
}
