//
//  _WistiaPlayerViewController.swift
//  WistiaKit internal
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
    override final public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        seekToStartIfAtEnd()
        needsManualLayoutFor360View = true
        self.delegate?.willAppear(wistiaPlayerViewController:  self)
    }

    /// Internal override.
    override final public func viewDidLayoutSubviews() {

        if needsManualLayoutFor360View {
            needsManualLayoutFor360View = false

            let transform:CGAffineTransform
            let invertSize:Bool

            switch UIApplication.shared.statusBarOrientation {
            case .landscapeLeft:
                transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2))
                invertSize = true
            case .landscapeRight:
                transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
                invertSize = true
            case .portraitUpsideDown:
                transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
                invertSize = false
            default: //.Portrait
                transform = CGAffineTransform.identity
                invertSize = false
            }

            self.player360View.transform = transform
            self.player360ViewHeightConstraint.constant = invertSize ? self.view.bounds.width :  self.view.bounds.height
            self.player360ViewWidthConstraint.constant = invertSize ? self.view.bounds.height : self.view.bounds.width
        }
    }

    /// Internal override.
    override final public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        //update current progress for new size
        coordinator.animate(alongsideTransition: { (context) -> Void in
            self.presentForCurrentProgress()
            }, completion: nil)

        //The 360 view assumes and requires that it's always displayed Portrait
        //Maintain portrait orientation for 360 player
        if playing360 {
            let invertSize = (self.player360View.bounds.size != size)
            var completionTransform:CGAffineTransform? = nil

            coordinator.animate(alongsideTransition: { (context) -> Void in

                let counterTransform:CGAffineTransform
                if (context.targetTransform.a == -1 && context.targetTransform.d == -1) {
                    //iOS will rotate the shortest distance to the end angle.  Rotating 180 (or -180), is always clockwise.
                    //To counter-rotate against 180, we first (1) under-counter-rotate by some small amount in the
                    //animation block then (2) finish the rotation after the animation block.  As long as we under-rotate
                    //by a small enough amount, it's imperceptible, and our views stay perfectly square afterward.
                    counterTransform = CGAffineTransform(rotationAngle: -1*(CGFloat(M_PI)-0.00001))
                    completionTransform = CGAffineTransform(rotationAngle: -0.00001)
                } else {
                    //just invert the 90 degree transforms
                    counterTransform = context.targetTransform.inverted()
                }

                self.player360View.transform = self.player360View.transform.concatenating(counterTransform)

                //update size (stay same if 180 rotation, otherwise we're countering size change)
                self.player360ViewWidthConstraint.constant = invertSize ? size.height : size.width
                self.player360ViewHeightConstraint.constant = invertSize ? size.width : size.height
                self.player360View.setNeedsUpdateConstraints()

                }){ (context) -> Void in
                    if let t = completionTransform {
                        self.player360View.transform = self.player360View.transform.concatenating(t)
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

    @IBAction func posterPlayPressed(_ sender: AnyObject) {
        play()
        presentForPlaybackShowingChrome(true)
    }

    @IBAction func controlsPlayPausePressed(_ sender: AnyObject) {
        togglePlayPause()
        presentForPlaybackShowingChrome(true)
        startOrResetChromeInteractionTimer()
    }

    @IBAction func controlsCaptionsPressed(_ sender: AnyObject) {
        startOrResetChromeInteractionTimer()
        toggleCaptionsChooserVisibility()
    }

    @IBAction func controlsActionPressed(_ sender: UIButton) {
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
                self.delegate?.wistiaPlayerViewController(self, activityViewControllerDidCompleteForMedia: media, withActivityType: activityType?.rawValue, completed: completed, activityError: activityError)
            }
            self.delegate?.wistiaPlayerViewController(self, activityViewControllerWillAppearForMedia: media)
            present(activityVC, animated: true, completion: nil)
            
        } else {
            print("ERROR: could not find current media to share")
        }
    }

    @IBAction func controlsClosePressed(_ sender: AnyObject) {
        pause()

        if let d = delegate {
            d.close(wistiaPlayerViewController: self)
        } else {
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func playerContainerTapped(_ tapRecognizer: UITapGestureRecognizer) {
        if wPlayer.state == WistiaPlayer.State.videoReadyForPlayback {
            presentForPlaybackToggleChrome()
        }
    }

    @IBAction func playerContainerDoubleTapped(_ sender: UITapGestureRecognizer) {
        togglePlayPause()
    }

#endif //os(iOS)
}

//Until we support 360 on TV, just killing this entire thing
#if os(iOS)
//MARK: - Wistia Player Delegate
extension WistiaPlayerViewController: WistiaPlayerDelegate {

    /// Internal.
    public final func wistiaPlayer(_ player:WistiaPlayer, didChangeStateTo newState:WistiaPlayer.State) {
        switch newState {
        case .initialized:
            presentForPreLoading()

        case .videoPreLoading(let media):
            presentForPreLoading()
            configurePlayerViews(for: media)

        case .videoLoading:
            presentForLoading()

        case .videoReadyForPlayback:
            if autoplayVideoWhenReady {
                presentForPlaybackShowingChrome(true)
                play()
            } else if player.rate == 0.0 {
                presentForFirstPlayback()
            } else {
                //AVPlayer is already in play mode; will autoplay video now that it's ready
                presentForPlaybackShowingChrome(true)
            }

        case .videoLoadingError(_, _, _):
            if wPlayer.media?.status == .queued ||
                wPlayer.media?.status == .processing {
                presentForMediaProcessing()
            }
            else {
                fallthrough
            }

        case .mediaNotFoundError(_):
            fallthrough

        case .videoPlaybackError(_):
            //IMPROVE ME: Show more useful errors to users depending on root cause
            presentForError(newState)
        }
    }

    /// Internal.
    public final func wistiaPlayer(_ player:WistiaPlayer, didChangePlaybackRateTo newRate:Float) {

        let playing = newRate > 0.0
        if playing {
            presentForPlaybackShowingChrome(true)
        }
        presentPlayPauseButton(forPlaying: playing)
    }

    /// Internal.
    public final func wistiaPlayer(_ player: WistiaPlayer, didChangePlaybackProgressTo progress: Float, atCurrentTime currentTime: CMTime, ofDuration: CMTime) {
        //playhead tracks user's finger when scrubbing
        if !scrubbing {
            present(forProgress: progress, currentTime: currentTime)
        }
    }

    /// Internal.
    public final func didPlayToEndTime(of player: WistiaPlayer) {
        switch (activeEmbedOptions.endVideoBehavior) {
        case .loopVideo:
            self.wPlayer.seek(to: CMTime(seconds: 0, preferredTimescale: 10), completionHandler: { (didSeek) in
                self.play()
            })
        case .pauseOnLastFrame:
            //NB: SKVideoNode and/or SceneKit bug: video rapidly toggles between paused/playing upon reaching end unless explicitly paused
            self.pause()
        case .resetToTimeZero:
            self.pause()
            self.wPlayer.seek(to: CMTime(seconds: 0, preferredTimescale: 10), completionHandler: { (didSeek) in
                self.presentPlayPauseButton(forPlaying: false)
            })
        }
    }

    /// Internal.
    public final func wistiaPlayer(_ player: WistiaPlayer, willLoadVideoForMedia media: WistiaMedia, usingAsset asset: WistiaAsset?, usingHLSMasterIndexManifest: Bool) {
        configurePlayerViews(for: media)
    }

}
#endif //os(iOS)

//MARK: - Wistia Captions Renderer Delegate
extension WistiaPlayerViewController: WistiaCaptionsRendererDelegate {

    public func captionsRenderer(_ renderer: WistiaCaptionsRenderer, didUpdateCaptionsLanguagesAvailable captionsLanguagesAvailable: [String]) {
        //UIPicker not supported on TV.  Captions should be done natively, anyway.
        #if os(iOS)
        captionsLanguagePickerView.reloadAllComponents()
        #endif //os(iOS)
    }

}

//MARK: - View Presentation
internal extension WistiaPlayerViewController {
//Until we support 360 on TV, just killing this entire thing
#if os(iOS)

    internal func configurePlayerViews(for media: WistiaMedia) {
        if media.isSpherical() {
            playing360 = true
            player360View.isHidden = false
            player360View.wPlayer = wPlayer
            playerFlatView.isHidden = true
            playerFlatView.wistiaPlayer = nil
        } else {
            playing360 = false
            player360View.isHidden = true
            player360View.wPlayer = nil
            playerFlatView.isHidden = false
            playerFlatView.wistiaPlayer = wPlayer
        }

        currentMediaEmbedOptions = media.embedOptions
    }

    internal func chooseActiveEmbedOptions() {
        if let overridingOptions = overridingEmbedOptions {
            activeEmbedOptions = overridingOptions
        } else if let currentOptions = currentMediaEmbedOptions {
            activeEmbedOptions = currentOptions
        } else {
            activeEmbedOptions = WistiaMediaEmbedOptions()
        }
    }

    internal func customizeView(for embedOptions: WistiaMediaEmbedOptions) {
        //playerColor
        playbackControlsContainer.backgroundColor = embedOptions.playerColor.withAlphaComponent(0.4)
        posterPlayButton.backgroundColor = playbackControlsContainer.backgroundColor

        //smallPlayButton
        controlsPlayPauseButton.isHidden = !embedOptions.smallPlayButton

        //playbar (aka scrubber)
        scrubberTrackContainerView.alpha = (embedOptions.playbar ? 1.0 : 0.0)

        //stillURL (with a backup if it's not customized)
        if let stillURL = embedOptions.stillURL {
            posterStillImage.isHidden = false
            posterStillImage.af_setImage(withURL: stillURL)
        }
        else if let media = wPlayer.media,
            let thumbString = media.thumbnail?.url,
            let thumbnail = URL(string: thumbString) {
            posterStillImage.isHidden = false
            posterStillImage.af_setImage(withURL: thumbnail)
        }
        else {
            posterStillImage.isHidden = true
        }

        //optional controls buttons
        controlsActionButton.isHidden = !embedOptions.actionButton
        controlsCaptionsButton.isHidden = !embedOptions.captionsAvailable

        //The following are implemented dynamically:
        // * bigPlayButton (see presentForFirstPlayback())
        // * controlsVisibleOnLoad (see presentForFirstPlayback())
        // * stillURL (see presentForFirstPlayback())
    }

    internal func presentForPreLoading() {
        loadViewIfNeeded()
        cancelChromeInteractionTimer()
        playerContainer.isHidden = true
        posterLoadingIndicator.stopAnimating()
        posterErrorIndicator.isHidden = true
        posterPlayButtonContainer.isHidden = true
        posterStillImageContainer.isHidden = false
        mediaProcessingContainer.isHidden = true
        showPlaybackControls(false, extraClose: false)
        present(forProgress: 0, currentTime: nil)
    }

    internal func presentForLoading() {
        loadViewIfNeeded()
        cancelChromeInteractionTimer()
        playerContainer.isHidden = false
        posterLoadingIndicator.startAnimating()
        posterErrorIndicator.isHidden = true
        posterPlayButtonContainer.isHidden = true
        posterStillImageContainer.isHidden = false
        mediaProcessingContainer.isHidden = true
        mediaProcessingContainer.isHidden = true
        showPlaybackControls(false, extraClose: true)
        present(forProgress: 0, currentTime: nil)
    }

    internal func presentForMediaProcessing() {
        loadViewIfNeeded()
        cancelChromeInteractionTimer()
        playerContainer.isHidden = true
        posterLoadingIndicator.stopAnimating()
        posterErrorIndicator.isHidden = true
        posterPlayButtonContainer.isHidden = true
        posterStillImageContainer.isHidden = false
        mediaProcessingContainer.isHidden = false
        showPlaybackControls(false, extraClose: true)
        present(forProgress: 0, currentTime: nil)
    }

    internal func presentForError(_ errorState: WistiaPlayer.State) {
        loadViewIfNeeded()
        cancelChromeInteractionTimer()
        playerContainer.isHidden = true
        posterLoadingIndicator.stopAnimating()
        posterErrorIndicator.isHidden = false
        posterPlayButtonContainer.isHidden = true
        posterStillImageContainer.isHidden = true
        mediaProcessingContainer.isHidden = true
        showPlaybackControls(false, extraClose: true)
        present(forProgress: 0, currentTime: nil)

        switch errorState {
        case .videoPlaybackError(let desc):
            alertAbout(title: "Video Playback Problem", message: desc)
        case .videoLoadingError(let desc, _, _):
            alertAbout(title: "Video Playback Problem", message: desc)
        case .mediaNotFoundError:
            alertAbout(title: "Video Playback Problem", message: "The requested media could not be found.")
        default:
            break
        }
    }

    internal func alertAbout(title: String, message: String) {
        print("\(title) -- \(message)")
        /*
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        present(alert, animated: true)
         */
    }

    internal func presentForFirstPlayback() {
        loadViewIfNeeded()
        cancelChromeInteractionTimer()
        playerContainer.isHidden = false
        posterLoadingIndicator.stopAnimating()
        posterErrorIndicator.isHidden = true
        posterPlayButtonContainer.isHidden = !activeEmbedOptions.bigPlayButton
        posterStillImageContainer.isHidden = false
        mediaProcessingContainer.isHidden = true
        showPlaybackControls(activeEmbedOptions.controlsVisibleOnLoad, extraClose: false)
        present(forProgress: 0, currentTime: nil)
    }

    internal func presentForPlaybackShowingChrome(_ showChrome:Bool){
        loadViewIfNeeded()
        playerContainer.isHidden = false
        posterLoadingIndicator.stopAnimating()
        posterErrorIndicator.isHidden = true
        posterPlayButtonContainer.isHidden = true
        posterStillImageContainer.isHidden = true
        mediaProcessingContainer.isHidden = true

        UIView.animate(withDuration: TimeInterval(0.5), animations: { () -> Void in
            //Don't change alpha of UIVisualEffectView.  
            //It's undocumented, but you can animate removal or setting of effect to affect a similar effect as alpha
            if showChrome {
                self.playbackControlsContainer.effect = UIBlurEffect(style: .light)
                //Not using vibrancy
            } else {
                self.playbackControlsContainer.effect = nil
                self.playbackControlsInnerContainer.effect = nil
                self.hideCaptionsChooser()
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
        loadViewIfNeeded()
        if self.playbackControlsContainer.isHidden {
            presentForPlaybackShowingChrome(true)
        } else {
            presentForPlaybackShowingChrome(false)
        }
    }

    internal func presentPlayPauseButton(forPlaying playing:Bool){
        loadViewIfNeeded()
        let podBundle = Bundle(for: self.classForCoder)
        if playing {
            controlsPlayPauseButton.setImage(UIImage(named: "smallPause", in: podBundle, compatibleWith: nil), for: UIControlState())
        } else {
            controlsPlayPauseButton.setImage(UIImage(named: "smallPlay", in: podBundle, compatibleWith: nil), for: UIControlState())
        }
    }

    internal func present(forProgress progress: Float, currentTime: CMTime?){
        guard progress.isFinite else {
            assertionFailure("progress expected to be finite")
            return
        }

        scrubberCurrentProgressViewWidthConstraint.constant = scrubberTrackContainerView.bounds.width * min(max(CGFloat(progress), 0.0), 1.0)
        if !scrubbing {
            UIView.animate(withDuration: TimeInterval(0.1)) { () -> Void in
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
        if let duration = wPlayer.currentItem?.duration, duration.isNumeric {
            present(forProgress: Float(wPlayer.currentTime().seconds / duration.seconds), currentTime: wPlayer.currentTime())
        }
    }

    internal func startOrResetChromeInteractionTimer(){
        chromeInteractionTimer?.invalidate()
        chromeInteractionTimer = Timer(timeInterval: TimeInterval(5), target: self, selector: #selector(WistiaPlayerViewController.noChromeInteraction), userInfo: nil, repeats: false)
        RunLoop.main.add(chromeInteractionTimer!, forMode: RunLoopMode.defaultRunLoopMode)
    }

    internal func cancelChromeInteractionTimer(){
        chromeInteractionTimer?.invalidate()
    }

    internal func noChromeInteraction(){
        presentForPlaybackShowingChrome(false)
    }

    internal func showPlaybackControls(_ showControls: Bool, extraClose showExtraClose: Bool) {
        playbackControlsContainer.isHidden = !showControls
        if delegate == nil && presentingViewController == nil {
            extraCloseButton.isHidden = true
        } else {
            extraCloseButton.isHidden = !showExtraClose
        }
    }

#endif //os(iOS)
}

//MARK: - Scrubbing
internal extension WistiaPlayerViewController {
//Until we support 360 on TV, just killing this entire thing
#if os(iOS)

    @IBAction internal func handleScrubberTap(_ sender: UITapGestureRecognizer) {
        if let seekTo = seekTimeForScrubberTrackContainerLocation(sender.location(in: scrubberTrackContainerView)) {
            wPlayer.seek(to: seekTo, completionHandler: nil)
        }
        startOrResetChromeInteractionTimer()
    }
    
    @IBAction internal func handleScrubbing(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .possible:
            //Do Nothing
            break
        case .began:
            startScrubbing()
            userScrubbed(to: sender.location(in: scrubberTrackContainerView))
        case .changed:
            userScrubbed(to: sender.location(in: scrubberTrackContainerView))
        case .cancelled:
            endScrubbing(nil)
        case .ended:
            userScrubbed(to: sender.location(in: scrubberTrackContainerView))
            endScrubbing(sender.location(in: scrubberTrackContainerView))
        case .failed:
            endScrubbing(nil)
        }
    }

    internal func startScrubbing(){
        scrubbing = true
        moveScrubTrackTimeLabelAwayFromFinger(true)
        storePlayerRateAndPause()
        cancelChromeInteractionTimer()
    }

    internal func userScrubbed(to location:CGPoint){
        let secondsSinceLastSeek = scrubbingSeekLastRequestedAt.timeIntervalSinceNow
        if let seekTo = seekTimeForScrubberTrackContainerLocation(location) {
            //An unfinished seek request will be cancelled when another is sent
            //Still, don't fire seek requests too close together, to keep performance high
            if secondsSinceLastSeek < -0.1 {
                scrubbingSeekLastRequestedAt = Date()
                wPlayer.seek(to: seekTo, completionHandler: nil)
            }

            //Update the playhead based on this location (player reported times are ignored during scrubbing)
            if let duration = wPlayer.currentItem?.duration {
                present(forProgress: Float(seekTo.seconds / duration.seconds), currentTime: seekTo)
            }
        }
    }

    internal func endScrubbing(_ location:CGPoint?){
        if let seekTo = seekTimeForScrubberTrackContainerLocation(location) {
            wPlayer.seek(to: seekTo, completionHandler: { (finished) -> Void in
                self.restorePlayerRate()
            })
        } else {
            restorePlayerRate()
        }
        moveScrubTrackTimeLabelAwayFromFinger(false)
        scrubbing = false
        startOrResetChromeInteractionTimer()
    }

    internal func seekTimeForScrubberTrackContainerLocation(_ location:CGPoint?) -> CMTime? {
        if let x = location?.x, let duration = wPlayer.currentItem?.duration {
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

    internal func moveScrubTrackTimeLabelAwayFromFinger(_ moveAway: Bool) {
        if moveAway {
            scrubTrackTimeLabelCenterConstraint.constant = -40
        } else {
            scrubTrackTimeLabelCenterConstraint.constant = 0
        }
        UIView.animate(withDuration: TimeInterval(0.25)) { () -> Void in
            self.view.layoutIfNeeded()
        }
    }

    internal func seekToStartIfAtEnd(withTolerance tolerance: CMTime = CMTime(seconds: 0.1, preferredTimescale: 10)) {
        let currentTime = wPlayer.currentTime()
        if let duration = wPlayer.currentItem?.duration {
            if currentTime > duration || (duration - currentTime) < tolerance {
                wPlayer.seek(to: CMTime(seconds: 0, preferredTimescale: 10), completionHandler: nil)
            }
        }

    }

#endif //os(iOS)
}

//UIPicker not supported on TV.  Captions should be done natively, anyway.
#if os(iOS)
//MARK: - Captions Chooser
extension WistiaPlayerViewController : UIPickerViewDelegate, UIPickerViewDataSource {

    func showCaptionsChooser() {
        captionsLanguagePickerView.isHidden = false
        cancelChromeInteractionTimer()
    }

    func hideCaptionsChooser() {
        captionsLanguagePickerView.isHidden = true
        startOrResetChromeInteractionTimer()
    }

    func toggleCaptionsChooserVisibility() {
        if captionsLanguagePickerView.isHidden {
            showCaptionsChooser()
        } else {
            hideCaptionsChooser()
        }
    }

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == 0 {
            wPlayer.captionsRenderer.enabled = false
        } else {
            wPlayer.captionsRenderer.enabled = true
            wPlayer.captionsRenderer.captionsLanguageCode = wPlayer.captionsRenderer.captionsLanguagesAvailable[row-1]
        }
        hideCaptionsChooser()
    }

    //delegate
    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30
    }

    public func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 100
    }

    public func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let title:String
        if row == 0 {
            title = "off"
        } else {
            title = wPlayer.captionsRenderer.captionsLanguagesAvailable[row-1]
        }

        return NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName: UIColor.white])
    }

    //data source

    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return wPlayer.captionsRenderer.captionsLanguagesAvailable.count + 1
    }


}
#endif //os(iOS)
