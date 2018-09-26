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

    /// Initialize using default values
    public init(){
    }

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
    public var endVideoBehavior: WistiaEndVideoBehavior = .pauseOnLastFrame {
        didSet {
            self.endVideoBehaviorString = endVideoBehavior.description()
        }
    }

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

    /// A password protected video will have `lockedByPassword = true`.
    /// You must provide the password as a query parameter (ie. password=XXX) to get asset info from the API.
    /// A value of false indicates the video is either not password protected, or the API request included the correct password.
    public var lockedByPassword: Bool = false

    /// A message to use when prompting the user for the password.
    public var passwordChallenge: String? = nil

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

// As of Swift 3.0, the default member-wise initializer for Structs is private if any properties of the struct 
// private, internal if they are all public.  There is no way to make this initilizer public.  So we must
// explicitly create one.  
// See https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/AccessControl.html#//apple_ref/doc/uid/TP40014097-CH41-ID3
public extension WistiaMediaEmbedOptions {

    /// Initializes a WistiaMediaEmbedOptions, used to customize the look and behavior of your
    /// video across all platforms (web, WistiaKit, etc).
    ///
    /// Any parameter left nil will use the default.
    ///
    /// - Parameters:
    ///   - playerColor: Tint for controls (default: #7b796a)
    ///   - bigPlayButton: Overlay large play button on poster view before playback has started (default: true)
    ///   - smallPlayButton: Show play/pause button on playbar (default: true)
    ///   - playbar: Show the scrubber (default: true)
    ///   - fullscreenButton: Show the fullscreen button on playbar (default: true)
    ///   - controlsVisibleOnLoad: Show the playbar on poster view before playback has started (default: true)
    ///   - autoplay: Automatically play the video once it has loaded (default: false)
    ///   - endVideoBehavior: What do do when the video ends (default: PauseOnLastFrame) as a String
    ///   - stillURL: Image to show for poster before playback (default: nil - the first frame of video is shown)
    ///   - actionButton: Show the standard iOS action button (similar to Wistia Social Bar on web) (default: false)
    ///   - actionShareURLString: The link to use when sharing
    ///   - actionShareTitle: The copy to use when sharing
    ///   - captionsAvailable: Are captions available and enabled for this video (default: false)
    ///   - captionsOnByDefault: Show captions by default (default: false)
    public init(playerColor: UIColor?, bigPlayButton: Bool?, smallPlayButton: Bool?, playbar: Bool?, fullscreenButton: Bool?, controlsVisibleOnLoad: Bool?, autoplay: Bool?, endVideoBehavior: WistiaMediaEmbedOptions.WistiaEndVideoBehavior?, stillURL: URL?, actionButton: Bool?, actionShareURLString: String?, actionShareTitle: String?, captionsAvailable: Bool?, captionsOnByDefault: Bool?) {

        if let pc = playerColor { self.playerColor = pc }
        if let bpb = bigPlayButton { self.bigPlayButton = bpb }
        if let spb = smallPlayButton { self.smallPlayButton = spb }
        if let pb = playbar { self.playbar = pb }
        if let fsb = fullscreenButton { self.fullscreenButton = fsb }
        if let cv = controlsVisibleOnLoad { self.controlsVisibleOnLoad = cv }
        if let ap = autoplay { self.autoplay = ap }
        if let ev = endVideoBehavior { self.endVideoBehavior = ev }
        if let su = stillURL { self.stillURL = su }
        if let ab = actionButton { self.actionButton = ab }
        if let asu = actionShareURLString { self.actionShareURLString = asu }
        if let ast = actionShareTitle { self.actionShareTitle = ast }
        if let ca = captionsAvailable { self.captionsAvailable = ca }
        if let co = captionsOnByDefault { self.captionsOnByDefault = co }
    }

}

extension WistiaMediaEmbedOptions: WistiaJSONParsable {

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

                // The `embedOptions` also have a `passwordProtectedVideo` key (ie. not within the `plugin` dictionary),
                // but `embedOptions.passwordProtectedVideo.on` does not tell us if the request was made with the correct password or not.
                // Whereas `embedOptions.plugins.passwordProtectedVideo.on` does provide this informtion.
                if let passwordParser = pluginParser.fetchOptional("passwordProtectedVideo", transformation: { (dict: [String: Any]) -> Parser? in
                    Parser(dictionary: dict)
                }) {
                    // when `on` is set to true, the Media is password protected and it was not requested with the correct password
                    // when `on` is set to false, the Media is password protected and it was requested with the correct password.
                    // when the passwordProtectedVideo dictionary does not exist, the video is not password protected
                    lockedByPassword = passwordParser.fetchOptional("on", default: false) { (s: NSString) -> Bool in s.boolValue }
                    passwordChallenge = try passwordParser.fetchOptional("challenge")
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

//MARK: - WistiaMediaEmbedOptions Equality

extension WistiaMediaEmbedOptions: Equatable { }

/**
 Compare two `WistiaMediaEmbedOptions`s for equality.

 - Returns: `True` iff each customization option is equal.

 */
public func ==(lhs: WistiaMediaEmbedOptions, rhs: WistiaMediaEmbedOptions) -> Bool {

    return lhs.playerColor == rhs.playerColor &&
        lhs.bigPlayButton == rhs.bigPlayButton &&
        lhs.smallPlayButton == rhs.smallPlayButton &&
        lhs.playbar == rhs.playbar &&
        lhs.fullscreenButton == rhs.fullscreenButton &&
        lhs.controlsVisibleOnLoad == rhs.controlsVisibleOnLoad &&
        lhs.autoplay == rhs.autoplay &&
        lhs.endVideoBehavior == rhs.endVideoBehavior &&
        lhs.stillURL == rhs.stillURL &&

        lhs.actionButton == rhs.actionButton &&
        lhs.actionShareURLString == rhs.actionShareURLString &&
        lhs.actionShareTitle == rhs.actionShareTitle &&

        lhs.captionsAvailable == rhs.captionsAvailable &&
        lhs.captionsOnByDefault == rhs.captionsOnByDefault
}
