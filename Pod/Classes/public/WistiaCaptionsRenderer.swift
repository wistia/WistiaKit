//
//  WistiaCaptionsRenderer.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 6/23/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

/**
 The delegate of a `WistiaCaptionsRenderer` must adopt the `WistiaCaptionsRendererDelegate `protocol.
 */
public protocol WistiaCaptionsRendererDelegate : class {

    /**
     Captions are loaded asynchronously after a media is loaded (initial or change) by a `WistiaPlayer`.

     When captions are loaded, the list of languages available is dynamically updated based upon the
     captions data received.  When this occurs, the delegate will be notified of the update through this callback.

     - Parameter renderer: The `WistiaCaptionsRenderer` making this function call.
     - Parameter captionsLanguagesAvailable: An updated list of language codes available for the currently loaded media.
     */
    func captionsRenderer(_ renderer: WistiaCaptionsRenderer, didUpdateCaptionsLanguagesAvailable captionsLanguagesAvailable:[String])
}

/**
 During playback of a `WistiaMedia`, renders captions into a given `UITextView`.
 
 You should not instantiate directly.  Use `WistiaPlayer.getCaptionsRenderer()` to get an
 instance cofigured to work with the given player as it plays back and/or changes video.
 
 - Important: You must set the `captionsView` and set `enabled` to `true` to being rendering.
 
 - Note: If you are using `WistiaPlayerViewController`, captions handling is built in.  Get lost!  ;-]
 */
public class WistiaCaptionsRenderer {

    /**
     The object that acts as the delegate of the `WistiaCaptionsRenderer`.  It must adopt the `WistiaCaptionsRendererDelegate` protocol.

     The delegate is not retained.

     - Note: Upon setting delegate, you will immediately receive a callback with current languages available.
     */
    public weak var delegate:WistiaCaptionsRendererDelegate? {
        didSet {
            if let d = delegate {
                d.captionsRenderer(self, didUpdateCaptionsLanguagesAvailable: captionsLanguagesAvailable)
            }
        }
    }

    /**
     Thew view that will be used to render captions.  Visual appearance properties of this view will not be
     adjusted by `WistiaCaptionsRenderer`.  However, `numberOfLines` will be set to 0 and
     `userInteractionEnabled` will be set to `false`.
     
     - Important: It is recommended to layout this view with constraints such that the bottom is fixed relative
     to the video view, it is centered within the video view, and it is allowed to grow (ie. intrinsically sized)
     in width and height.
    */
    public var captionsView: UILabel? {
        didSet {
            if let v = captionsView {
                v.numberOfLines = 0
                v.isUserInteractionEnabled = false
            }
        }
    }

    /// Should captions be displayed
    public var enabled: Bool = false {
        didSet {
            if !enabled {
                removeDisplayedSegment()
            }
        }
    }

    /** 
     Which captions should be displayed (when enabled)?  See `captionsLanguagesAvailable`
     for enumeration of caption languages available for the current media.
     */
    public var captionsLanguageCode = "eng" {
        didSet(oldCode) {
            if captionsLanguageCode != oldCode {
                removeDisplayedSegment()
            }

            chooseCurrentCaptions()
        }
    }

    /**
     Enumeration of caption languages available for the current media.
     
     - Note: Captions are retrieved asynchronously, so this value may update any time after media changes.
     */
    internal(set) public var captionsLanguagesAvailable: [String] = [String]() {
        didSet {
            delegate?.captionsRenderer(self, didUpdateCaptionsLanguagesAvailable: captionsLanguagesAvailable)
        }
    }

    //MARK: - Internal

    /// - Warning: We assume `WistiaCaptionSegment`s are properly ordered.  Should be guaranteed by ModelBuilder.
    internal var media: WistiaMedia? = nil {
        didSet(lastMedia) {
            if let m = media, m != lastMedia {
                removeDisplayedSegment()
                prepareCaptions()
            }
        }
    }

    fileprivate var currentlySelectedCaptions: WistiaCaptions?
    fileprivate var currentCaptionSegment: WistiaCaptionSegment?

    fileprivate func prepareCaptions() {
        if let _ = media?.embedOptions?.captionsAvailable {
            WistiaAPI.captions(for: media!.hashedID, completionHandler: { (captions) in
                self.media?.add(captions: captions)
                self.captionsLanguagesAvailable = [String]()
                for caption in captions {
                    self.captionsLanguagesAvailable.append(caption.languageCode)
                }
                self.chooseCurrentCaptions()
            })
        }
    }

    internal func onPlayerTimeUpdate(_ time:CMTime) {
        guard enabled && captionsView != nil else { return }
        guard let caps = currentlySelectedCaptions else { return }

        if let seg = currentCaptionSegment, seg.endTime <= Float(time.seconds) {
            removeDisplayedSegment()
        }

        if currentCaptionSegment == nil {
            displaySegmentOf(caps, forTime: time)
        }
    }

    //MARK: - Display

    fileprivate func removeDisplayedSegment() {
        currentCaptionSegment = nil
        captionsView?.isHidden = true
        //no need to set text to nil
    }

    fileprivate func displaySegmentOf(_ captions: WistiaCaptions, forTime time:CMTime) {
        //Since the user may seek around the video, the current implemention is not optimized
        let t = Float(time.seconds)

        var activeSegment: WistiaCaptionSegment? = nil
        for segment in captions.captionSegments {
            //slight optimization: break if this and all subsequent segments start later than t
            if (segment.startTime > t) {
                break
            }

            //we already know segment.startTime is less than or equal to t
            if (segment.endTime > t) {
                activeSegment = segment
                break
            }
        }

        if let seg = activeSegment {
            currentCaptionSegment = activeSegment
            captionsView?.text = seg.text.joined(separator: "\n")
            captionsView?.isHidden = false
        }
    }

    //MARK: - Helpers

    fileprivate func chooseCurrentCaptions() {
        let captionsMatchingCode = media?.captions?.filter({ (cap) -> Bool in
            cap.languageCode == captionsLanguageCode
        })
        self.currentlySelectedCaptions = captionsMatchingCode?.first
    }
}

