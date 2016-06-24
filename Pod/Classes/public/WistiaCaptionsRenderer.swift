//
//  WistiaCaptionsRenderer.swift
//  Pods
//
//  Created by Daniel Spinosa on 6/23/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

/**
 During playback of a `WistiaMedia`, renders captions into a given `UITextView`.
 
 You should not instantiate directly.  Use `WistiaPlayer.getCaptionsRenderer()` to get an
 instance cofigured to work with the given player as it plays back and/or changes video.
 
 - Important: You must set the `captionsView` and set `enabled` to `true` to being rendering.
 
 - Note: If you are using `WistiaPlayerViewController`, captions handling is built in.  Get lost!  ;-]
 */
public class WistiaCaptionsRenderer {

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
                v.userInteractionEnabled = false
            }
        }
    }

    /// Should captions be displayed
    public var enabled: Bool = false

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
    internal(set) public var captionsLanguagesAvailable: [String] = [String]()

    //MARK: - Internal

    /// - Warning: We assume `WistiaCaptionSegment`s are properly ordered.  Should be guaranteed by ModelBuilder.
    internal var media: WistiaMedia? = nil {
        didSet(lastMedia) {
            if let m = media where m != lastMedia {
                removeDisplayedSegment()
                prepareCaptions()
            }
        }
    }

    private var currentlySelectedCaptions: WistiaCaptions?
    private var currentCaptionSegment: WistiaCaptionSegment?

    private func prepareCaptions() {
        if let _ = media?.embedOptions?.captionsAvailable {
            WistiaAPI._captionsForHash(media!.hashedID, completionHandler: { (captions) in
                self.media?.addCaptions(captions)
                self.captionsLanguagesAvailable = [String]()
                for caption in captions {
                    self.captionsLanguagesAvailable.append(caption.languageCode)
                }
                self.chooseCurrentCaptions()
            })
        }
    }

    internal func onPlayerTimeUpdate(time:CMTime) {
        guard enabled && captionsView != nil else { return }
        guard let caps = currentlySelectedCaptions else { return }

        if let seg = currentCaptionSegment where seg.endTime <= Float(time.seconds) {
            removeDisplayedSegment()
        }

        if currentCaptionSegment == nil {
            displaySegmentOf(caps, forTime: time)
        }
    }

    //MARK: - Display

    private func removeDisplayedSegment() {
        currentCaptionSegment = nil
        captionsView?.hidden = true
        //no need to set text to nil
    }

    private func displaySegmentOf(captions: WistiaCaptions, forTime time:CMTime) {
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
            captionsView?.text = seg.text.joinWithSeparator("\n")
            captionsView?.hidden = false
        }
    }

    //MARK: - Helpers

    private func chooseCurrentCaptions() {
        let captionsMatchingCode = media?.captions?.filter({ (cap) -> Bool in
            cap.languageCode == captionsLanguageCode
        })
        self.currentlySelectedCaptions = captionsMatchingCode?.first
    }
}

