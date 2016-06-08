//
//  WistiaPlayerViewController_internal.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 1/15/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

//Until we support 360 on TV, just killing this entire thing
#if os(iOS)
import UIKit
import AVFoundation
import AlamofireImage
#endif //os(iOS)

//MARK: - Rotation
//NB: The 360 view assumes and requires that it's always displayed Portrait.
// The following code sets up then maintains portrait orientation for 360 player
extension WistiaPlayerViewController {
//Until we support 360 on TV, just killing this entire thing
#if os(iOS)

    /// Internal override.
    override final public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        seekToStartIfAtEnd()
        needsManualLayoutFor360View = true
        self.delegate?.wistiaPlayerViewControllerViewWillAppear(self)
    }

    /// Internal override.
    override final public func viewDidLayoutSubviews() {

        if needsManualLayoutFor360View {
            needsManualLayoutFor360View = false

            let transform:CGAffineTransform
            let invertSize:Bool

            switch UIApplication.sharedApplication().statusBarOrientation {
            case .LandscapeLeft:
                transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
                invertSize = true
            case .LandscapeRight:
                transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
                invertSize = true
            case .PortraitUpsideDown:
                transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
                invertSize = false
            default: //.Portrait
                transform = CGAffineTransformIdentity
                invertSize = false
            }

            self.player360View.transform = transform
            self.player360ViewHeightConstraint.constant = invertSize ? self.view.bounds.width :  self.view.bounds.height
            self.player360ViewWidthConstraint.constant = invertSize ? self.view.bounds.height : self.view.bounds.width
        }
    }

    /// Internal override.
    override final public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)

        //update current progress for new size
        coordinator.animateAlongsideTransition({ (context) -> Void in
            self.presentForCurrentProgress()
            }, completion: nil)

        //The 360 view assumes and requires that it's always displayed Portrait
        //Maintain portrait orientation for 360 player
        if playing360 {
            let invertSize = (self.player360View.bounds.size != size)
            var completionTransform:CGAffineTransform? = nil

            coordinator.animateAlongsideTransition({ (context) -> Void in

                let counterTransform:CGAffineTransform
                if (context.targetTransform().a == -1 && context.targetTransform().d == -1) {
                    //iOS will rotate the shortest distance to the end angle.  Rotating 180 (or -180), is always clockwise.
                    //To counter-rotate against 180, we first (1) under-counter-rotate by some small amount in the
                    //animation block then (2) finish the rotation after the animation block.  As long as we under-rotate
                    //by a small enough amount, it's imperceptible, and our views stay perfectly square afterward.
                    counterTransform = CGAffineTransformMakeRotation(-1*(CGFloat(M_PI)-0.00001))
                    completionTransform = CGAffineTransformMakeRotation(-0.00001)
                } else {
                    //just invert the 90 degree transforms
                    counterTransform = CGAffineTransformInvert(context.targetTransform())
                }

                self.player360View.transform = CGAffineTransformConcat(self.player360View.transform, counterTransform)

                //update size (stay same if 180 rotation, otherwise we're countering size change)
                self.player360ViewWidthConstraint.constant = invertSize ? size.height : size.width
                self.player360ViewHeightConstraint.constant = invertSize ? size.width : size.height
                self.player360View.setNeedsUpdateConstraints()

                }){ (context) -> Void in
                    if let t = completionTransform {
                        self.player360View.transform = CGAffineTransformConcat(self.player360View.transform, t)
                    }
            }
        }
    }

#endif //os(iOS)
}

//MARK: - IB Actions
internal extension WistiaPlayerViewController {
//Until we support 360 on TV, just killing this entire thing
#if os(iOS)

    @IBAction func posterPlayPressed(sender: AnyObject) {
        play()
        presentForPlaybackShowingChrome(true)
    }

    @IBAction func controlsPlayPausePressed(sender: AnyObject) {
        togglePlayPause()
        presentForPlaybackShowingChrome(true)
        startOrResetChromeInteractionTimer()
    }

    @IBAction func controlsActionPressed(sender: UIButton) {
        self.storePlayerRateAndPause()
        if let media = wPlayer.media {
            let videoTitle: String
            if let customTitle = media.embedOptions?.actionShareTitle {
                videoTitle = customTitle
            } else if let mediaName = media.name {
                videoTitle = mediaName
            } else {
                videoTitle = ""
            }
            let videoUrl = media.embedOptions?.actionShareURLString ?? "https://fast.wistia.com/embed/medias/\(media.hashedID)"
            let shareString = "\(videoTitle) \(videoUrl)"

            let activityVC = UIActivityViewController(activityItems: [shareString], applicationActivities: nil)
            activityVC.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) -> Void in
                self.restorePlayerRate()
                self.delegate?.wistiaPlayerViewController(self, activityViewControllerDidCompleteForMedia: media, withActivityType: activityType, completed: completed, activityError: activityError)
            }
            self.delegate?.wistiaPlayerViewController(self, activityViewControllerWillAppearForMedia: media)
            presentViewController(activityVC, animated: true, completion: nil)
            
        } else {
            print("ERROR: could not find current media to share")
        }
    }

    @IBAction func controlsClosePressed(sender: AnyObject) {
        pause()

        if let d = delegate {
            d.closeWistiaPlayerViewController(self)
        } else {
            self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func playerContainerTapped(tapRecognizer: UITapGestureRecognizer) {
        if wPlayer.state == WistiaPlayer.State.VideoReadyForPlayback {
            presentForPlaybackToggleChrome()
        }
    }

    @IBAction func playerContainerDoubleTapped(sender: UITapGestureRecognizer) {
        togglePlayPause()
    }

#endif //os(iOS)
}

//MARK: - Wistia Player Delegate
extension WistiaPlayerViewController: WistiaPlayerDelegate {
//Until we support 360 on TV, just killing this entire thing
#if os(iOS)

    /// Internal.
    public final func wistiaPlayer(player:WistiaPlayer, didChangeStateTo newState:WistiaPlayer.State) {
        switch newState {
        case .Initialized: fallthrough
        case .VideoPreLoading:
            presentForPreLoading()

        case .VideoLoading:
            presentForLoading()

        case .VideoReadyForPlayback:
            if autoplayVideoWhenReady {
                presentForPlaybackShowingChrome(true)
                play()
            } else {
                presentForFirstPlayback()
            }

        case .MediaNotFoundError(_):
            fallthrough
        case .VideoLoadingError(_, _, _):
            fallthrough
        case .VideoPlaybackError(_):
            //IMPROVE ME: Show more useful errors to users depending on root cause
            presentForError()
        }
    }

    /// Internal.
    public final func wistiaPlayer(player:WistiaPlayer, didChangePlaybackRateTo newRate:Float) {

        let playing = newRate > 0.0
        if playing {
            presentForPlaybackShowingChrome(true)
        }
        presentPlayPauseButtonForPlaying(playing)
    }

    /// Internal.
    public final func wistiaPlayer(player: WistiaPlayer, didChangePlaybackProgressTo progress: Float, atCurrentTime currentTime: CMTime, ofDuration: CMTime) {
        //playhead tracks user's finger when scrubbing
        if !scrubbing {
            presentForProgress(progress, currentTime: currentTime)
        }
    }

    /// Internal.
    public final func wistiaPlayerDidPlayToEndTime(player: WistiaPlayer) {
        switch (activeEmbedOptions.endVideoBehavior) {
        case .LoopVideo:
            self.wPlayer.seekToTime(CMTime(seconds: 0, preferredTimescale: 10), completionHandler: { (didSeek) in
                self.play()
            })
        case .PauseOnLastFrame:
            //NB: SKVideoNode and/or SceneKit bug: video rapidly toggles between paused/playing upon reaching end unless explicitly paused
            self.pause()
        case .ResetToTimeZero:
            self.pause()
            self.wPlayer.seekToTime(CMTime(seconds: 0, preferredTimescale: 10), completionHandler: { (didSeek) in
                self.presentPlayPauseButtonForPlaying(false)
            })
        }
    }

    /// Internal.
    public final func wistiaPlayer(player: WistiaPlayer, willLoadVideoForMedia media: WistiaMedia, usingAsset asset: WistiaAsset?, usingHLSMasterIndexManifest: Bool) {
        if media.spherical {
            playing360 = true
            player360View.hidden = false
            player360View.wPlayer = wPlayer
            playerFlatView.hidden = true
            playerFlatView.playerLayer = nil
        } else {
            playing360 = false
            player360View.hidden = true
            player360View.wPlayer = nil
            playerFlatView.hidden = false
            playerFlatView.playerLayer = wPlayer.newPlayerLayer()
        }

        currentMediaEmbedOptions = media.embedOptions
    }

#endif //os(iOS)
}

//MARK: - View Presentation
internal extension WistiaPlayerViewController {
//Until we support 360 on TV, just killing this entire thing
#if os(iOS)

    internal func chooseActiveEmbedOptions() {
        if let overridingOptions = overridingEmbedOptions {
            activeEmbedOptions = overridingOptions
        } else if let currentOptions = currentMediaEmbedOptions {
            activeEmbedOptions = currentOptions
        } else {
            activeEmbedOptions = WistiaMediaEmbedOptions()
        }
    }

    internal func customizeViewFor(embedOptions:WistiaMediaEmbedOptions) {
        //playerColor
        controlsPlayPauseButton.backgroundColor = embedOptions.playerColor
        scrubberTrackContainerView.backgroundColor = embedOptions.playerColor
        controlsActionButton.backgroundColor = embedOptions.playerColor
        controlsCloseButton.backgroundColor = embedOptions.playerColor
        posterPlayButton.backgroundColor = embedOptions.playerColor

        //smallPlayButton
        controlsPlayPauseButton.hidden = !embedOptions.smallPlayButton

        //playbar (aka scrubber)
        scrubberTrackContainerView.alpha = (embedOptions.playbar ? 1.0 : 0.0)

        //stillURL
        if let stillURL = embedOptions.stillURL {
            posterStillImage.hidden = false
            posterStillImage.af_setImageWithURL(stillURL)
        } else {
            posterStillImage.hidden = true
        }

        //actionButton
        controlsActionButton.hidden = !embedOptions.actionButton

        //The following are implemented dynamically:
        // * bigPlayButton (see presentForFirstPlayback())
        // * controlsVisibleOnLoad (see presentForFirstPlayback())
        // * stillURL (see presetnForFirstPlayback())
    }

    internal func presentForPreLoading() {
        cancelChromeInteractionTimer()
        playerContainer.hidden = true
        posterLoadingIndicator.stopAnimating()
        posterErrorIndicator.hidden = true
        posterPlayButtonContainer.hidden = true
        posterStillImageContainer.hidden = true
        showPlaybackControls(false, extraClose: false)
        presentForProgress(0, currentTime: nil)
    }

    internal func presentForLoading() {
        cancelChromeInteractionTimer()
        playerContainer.hidden = false
        posterLoadingIndicator.startAnimating()
        posterErrorIndicator.hidden = true
        posterPlayButtonContainer.hidden = true
        posterStillImageContainer.hidden = true
        showPlaybackControls(false, extraClose: true)
        presentForProgress(0, currentTime: nil)
    }

    internal func presentForError() {
        cancelChromeInteractionTimer()
        playerContainer.hidden = true
        posterLoadingIndicator.stopAnimating()
        posterErrorIndicator.hidden = false
        posterPlayButtonContainer.hidden = true
        posterStillImageContainer.hidden = true
        showPlaybackControls(false, extraClose: true)
        presentForProgress(0, currentTime: nil)
    }

    internal func presentForFirstPlayback() {
        cancelChromeInteractionTimer()
        playerContainer.hidden = false
        posterLoadingIndicator.stopAnimating()
        posterErrorIndicator.hidden = true
        posterPlayButtonContainer.hidden = !activeEmbedOptions.bigPlayButton
        posterStillImageContainer.hidden = false
        showPlaybackControls(activeEmbedOptions.controlsVisibleOnLoad, extraClose: false)
        presentForProgress(0, currentTime: nil)
    }

    internal func presentForPlaybackShowingChrome(showChrome:Bool){
        playerContainer.hidden = false
        posterLoadingIndicator.stopAnimating()
        posterErrorIndicator.hidden = true
        posterPlayButtonContainer.hidden = true
        posterStillImageContainer.hidden = true

        UIView.animateWithDuration(NSTimeInterval(0.5), animations: { () -> Void in
            //Don't change alpha of UIVisualEffectView.  
            //It's undocumented, but you can animate removal or setting of effect to affect a similar effect as alpha
            if showChrome {
                self.playbackControlsContainer.effect = UIBlurEffect(style: .Light)
                //You are *supposed* to use a vibrancy effect matching the underlying blur effect
                //But vibrancy for dark blur turns template icons white, which is what we want (and it looks good!)
                self.playbackControlsInnerContainer.effect = UIVibrancyEffect(forBlurEffect: UIBlurEffect(style: .Dark))
            } else {
                self.playbackControlsContainer.effect = nil
                self.playbackControlsInnerContainer.effect = nil
            }
            }) { (finished) -> Void in
                self.showStatusBar = showChrome
                self.showPlaybackControls(showChrome, extraClose: false)
                if showChrome {
                    self.startOrResetChromeInteractionTimer()
                }
        }

    }

    internal func presentForPlaybackToggleChrome() {
        if self.playbackControlsContainer.hidden {
            presentForPlaybackShowingChrome(true)
        } else {
            presentForPlaybackShowingChrome(false)
        }
    }

    internal func presentPlayPauseButtonForPlaying(playing:Bool){
        let podBundle = NSBundle(forClass: self.classForCoder)
        if playing {
            controlsPlayPauseButton.setImage(UIImage(named: "smallPause", inBundle: podBundle, compatibleWithTraitCollection: nil), forState: .Normal)
        } else {
            controlsPlayPauseButton.setImage(UIImage(named: "smallPlay", inBundle: podBundle, compatibleWithTraitCollection: nil), forState: .Normal)
        }
    }

    internal func presentForProgress(progress:Float, currentTime:CMTime?){
        scrubberCurrentProgressViewWidthConstraint.constant = scrubberTrackContainerView.bounds.width * min(max(CGFloat(progress), 0.0), 1.0)
        if !scrubbing {
            UIView.animateWithDuration(NSTimeInterval(0.1)) { () -> Void in
                self.view.layoutIfNeeded()
            }
        }

        if let totalSecondsD = (currentTime?.seconds) {
            let totalSeconds = Int(totalSecondsD)
            let seconds = totalSeconds % 60
            let minutes = (totalSeconds / 60) % 60
            let hours = totalSeconds / 3600

            if hours > 0 {
                scrubberTrackCurrentTimeLabel.text = String(format: "%01d:%02d:%02d", hours, minutes, seconds)
            } else {
                scrubberTrackCurrentTimeLabel.text = String(format: "%01d:%02d", minutes, seconds)
            }
        } else {
            scrubberTrackCurrentTimeLabel.text = nil
        }
    }

    internal func presentForCurrentProgress(){
        if let duration = wPlayer.currentItem?.duration {
            presentForProgress(Float(wPlayer.currentTime().seconds / duration.seconds), currentTime: wPlayer.currentTime())
        }
    }

    internal func startOrResetChromeInteractionTimer(){
        chromeInteractionTimer?.invalidate()
        chromeInteractionTimer = NSTimer(timeInterval: NSTimeInterval(5), target: self, selector: #selector(WistiaPlayerViewController.noChromeInteraction), userInfo: nil, repeats: false)
        NSRunLoop.mainRunLoop().addTimer(chromeInteractionTimer!, forMode: NSDefaultRunLoopMode)
    }

    internal func cancelChromeInteractionTimer(){
        chromeInteractionTimer?.invalidate()
    }

    internal func noChromeInteraction(){
        presentForPlaybackShowingChrome(false)
    }

    internal func showPlaybackControls(showControls: Bool, extraClose showExtraClose: Bool) {
        playbackControlsContainer.hidden = !showControls
        extraCloseButton.hidden = !showExtraClose
    }

#endif //os(iOS)
}

//MARK: - Scrubbing
internal extension WistiaPlayerViewController {
//Until we support 360 on TV, just killing this entire thing
#if os(iOS)

    @IBAction internal func handleScrubberTap(sender: UITapGestureRecognizer) {
        if let seekTo = seekTimeForScrubberTrackContainerLocation(sender.locationInView(scrubberTrackContainerView)) {
            wPlayer.seekToTime(seekTo, completionHandler: nil)
        }
        startOrResetChromeInteractionTimer()
    }
    
    @IBAction internal func handleScrubbing(sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .Possible:
            //Do Nothing
            break
        case .Began:
            startScrubbing()
            userScrubbedTo(sender.locationInView(scrubberTrackContainerView))
        case .Changed:
            userScrubbedTo(sender.locationInView(scrubberTrackContainerView))
        case .Cancelled:
            endScrubbing(nil)
        case .Ended:
            userScrubbedTo(sender.locationInView(scrubberTrackContainerView))
            endScrubbing(sender.locationInView(scrubberTrackContainerView))
        case .Failed:
            endScrubbing(nil)
        }
    }

    internal func startScrubbing(){
        scrubbing = true
        moveScrubTrackTimeLabelAwayFromFinger(true)
        storePlayerRateAndPause()
        cancelChromeInteractionTimer()
    }

    internal func userScrubbedTo(location:CGPoint){
        let secondsSinceLastSeek = scrubbingSeekLastRequestedAt.timeIntervalSinceNow
        if let seekTo = seekTimeForScrubberTrackContainerLocation(location) {
            //An unfinished seek request will be cancelled when another is sent
            //Still, don't fire seek requests too close together, to keep performance high
            if secondsSinceLastSeek < -0.1 {
                scrubbingSeekLastRequestedAt = NSDate()
                wPlayer.seekToTime(seekTo, completionHandler: nil)
            }

            //Update the playhead based on this location (player reported times are ignored during scrubbing)
            if let duration = wPlayer.currentItem?.duration {
                presentForProgress(Float(seekTo.seconds / duration.seconds), currentTime: seekTo)
            }
        }
    }

    internal func endScrubbing(location:CGPoint?){
        if let seekTo = seekTimeForScrubberTrackContainerLocation(location) {
            wPlayer.seekToTime(seekTo, completionHandler: { (finished) -> Void in
                self.restorePlayerRate()
            })
        } else {
            restorePlayerRate()
        }
        moveScrubTrackTimeLabelAwayFromFinger(false)
        scrubbing = false
        startOrResetChromeInteractionTimer()
    }

    internal func seekTimeForScrubberTrackContainerLocation(location:CGPoint?) -> CMTime? {
        if let x = location?.x, duration = wPlayer.currentItem?.duration {
            let pct = min(max(0,x / scrubberTrackContainerView.bounds.width),1)
            return CMTimeMultiplyByFloat64(duration, Float64(pct))
        } else {
            return nil
        }
    }

    internal func storePlayerRateAndPause() {
        //Oddly enough, although we need to use the SKVideoNode to control play/pause, it doesn't return paused state correctly.
        //Always use the AVPlayer to accruately get the rate (ie. play/pause state) of the AVPLayer.
        playerRateBeforeScrubbing = wPlayer.rate
        pause()
    }

    internal func restorePlayerRate() {
        if playing360 {
            //Due to an Apple bug, we can't control playback using the AVPlayer, need to use the SKVideoNode thru 360 view
            if playerRateBeforeScrubbing == 1.0 {
                player360View.play()
            }
        } else {
            wPlayer.rate = playerRateBeforeScrubbing
        }
    }

    internal func moveScrubTrackTimeLabelAwayFromFinger(moveAway: Bool) {
        if moveAway {
            scrubTrackTimeLabelCenterConstraint.constant = -40
        } else {
            scrubTrackTimeLabelCenterConstraint.constant = 0
        }
        UIView.animateWithDuration(NSTimeInterval(0.25)) { () -> Void in
            self.view.layoutIfNeeded()
        }
    }


    internal func seekToStartIfAtEnd(tolerance: CMTime = CMTime(seconds: 0.1, preferredTimescale: 10)) {
        let currentTime = wPlayer.currentTime()
        if let duration = wPlayer.currentItem?.duration {
            if currentTime > duration || (duration - currentTime) < tolerance {
                wPlayer.seekToTime(CMTime(seconds: 0, preferredTimescale: 10), completionHandler: nil)
            }
        }

    }

#endif //os(iOS)
}