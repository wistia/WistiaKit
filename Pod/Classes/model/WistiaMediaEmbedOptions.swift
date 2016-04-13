//
//  WistiaMediaEmbedOptions.swift
//  Pods
//
//  Created by Daniel Spinosa on 4/13/16.
//
//

import Foundation

/*
 * Most player customizations are communicated through the API in a hash called
 * embed_options.  These are stored as a WistiaMediaEmbedOptions on the
 * WistiaMedia to which they apply.
 *
 * Customizations not currently supported:
 * - Turnstyle
 * - Call To Action & Annotation Links
 * - Social Bar (replaced with standard iOS action button)
 */
public struct WistiaMediaEmbedOptions {
    //Tint for controls (default: #7b796a)
    var playerColor: UIColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    //Overlay large play button on poster view before playback has started (default: true)
    var bigPlayButton: Bool = true
    //Show play/pause button on playbar (default: true(
    var smallPlayButton: Bool = true
    //Show the scrubber (default: true)
    var playbar: Bool = true
    //Show the fullscreen button on playbar (default: true)
    var fullscreenButton: Bool = true
    //Show the playbar on poster view before playback has started (default: true)
    var controlsVisibleOnLoad: Bool = true
    //Automatically play the video once it has loaded (default: false)
    var autoplay: Bool = false
    //What do do when the video ends (default: PauseOnLastFrame)
    var endVideoBehaviorString: String = "pause" {
        didSet(oldBehavior) {
            self.endVideoBehavior = WistiaEndVideoBehavior.fromString(self.endVideoBehaviorString)
        }
    }
    var endVideoBehavior: WistiaEndVideoBehavior = .PauseOnLastFrame
    //Image to show for poster before playback (default: nil - the first frame of video is shown)
    var stillURL: NSURL? = nil
    //Show the standard iOS action button (similar to Wistia Social Bar on web) (default: false)
    var actionButton: Bool = false
    //Show captions by default (default: false)
    var captions: Bool = false

    public enum WistiaEndVideoBehavior {
        case PauseOnLastFrame, //default
        ResetToTimeZero,
        LoopVideo

        static func fromString(behavior:String) -> WistiaEndVideoBehavior {
            switch behavior {
            case "default":
                fallthrough
            case "pause":
                return .PauseOnLastFrame
            case "reset":
                return .ResetToTimeZero
            case "loop":
                return .LoopVideo
            default:
                return .PauseOnLastFrame
            }
        }
    }
}
