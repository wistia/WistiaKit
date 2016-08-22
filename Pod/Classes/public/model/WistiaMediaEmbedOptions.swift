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
    public var playerColor: UIColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)

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
    }
}
