//
//  WistiaPlayerViewController.swift
//  Playback
//
//  Created by Daniel Spinosa on 1/15/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import UIKit
import AVFoundation

public protocol WistiaPlayerViewControllerDelegate : class {
    //For WistiaKit, will probably want to expand on this delegate to be more like what's on web
    func closeWistiaPlayerViewController(vc: WistiaPlayerViewController)
    func wistiaPlayerViewControllerViewWillAppear(vc: WistiaPlayerViewController)
    func wistiaPlayerViewController(vc: WistiaPlayerViewController, ActionSheetWillAppearForMedia media:WistiaMedia)
    func wistiaPlayerViewController(vc: WistiaPlayerViewController, actionSheetDidCompleteForMedia media:WistiaMedia, withActivityType activityType: String?, completed: Bool, returnedItems: [AnyObject]?, activityError: NSError?)
}

public final class WistiaPlayerViewController: UIViewController {

    //MARK: Player
    //Our single player that we will put into either the Flat or the 360 view
    lazy private var wPlayer:WistiaPlayer = {
        let wp = WistiaPlayer(referrer: self.referrer ?? "set_referrer_when_initializing_\(self.dynamicType)",
            requireHLS: self.requireHLS)
        wp.delegate = self
        return wp
    }()
    private var referrer:String?
    private var requireHLS = true

    //MARK: Scrubbing
    private var playerRateBeforeScrubbing:Float = 0.0
    private var scrubbing:Bool = false
    private var scrubbingSeekLastRequestedAt = NSDate()
    @IBOutlet weak private var scrubTrackTimeLabelCenterConstraint: NSLayoutConstraint!

    private var autoplayVideoWhenReady = false

    //MARK: - IB Outlets
    //MARK: Players
    @IBOutlet weak private var playerContainer: UIView!
    @IBOutlet weak private var playerFlatView: WistiaFlatPlayerView!
    @IBOutlet weak private var player360View: Wistia360PlayerView!
    @IBOutlet weak var player360ViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var player360ViewWidthConstraint: NSLayoutConstraint!
    private var needsManualLayoutFor360View = true
    private var playing360 = false

    //MARK: Poster
    @IBOutlet weak private var posterPlayButtonContainer: UIVisualEffectView!
    @IBOutlet weak private var posterLoadingIndicator: UIActivityIndicatorView!

    //MARK: Playback controls
    @IBOutlet weak private var posterErrorIndicator: UIImageView!
    @IBOutlet weak private var playbackControlsContainer: UIVisualEffectView!
    @IBOutlet weak private var playbackControlsInnerContainer: UIVisualEffectView!
    @IBOutlet weak private var controlsPlayPauseButton: UIButton!
    @IBOutlet weak private var scrubberTrackContainerView: UIView!
    @IBOutlet weak private var scrubberCurrentProgressView: UIView!
    @IBOutlet weak private var scrubberCurrentProgressViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak private var scrubberTrackCurrentTimeLabel: UILabel!
    private var chromeInteractionTimer:NSTimer?

    @IBOutlet weak var extraCloseButton: UIButton!

    //MARK: - UIViewController Normal Stuff

    //show status bar iff playback controls are showing
    private var showStatusBar = true {
        didSet {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }

    override public func prefersStatusBarHidden() -> Bool {
        return !showStatusBar
    }

    override public func loadView() {
        let nib = NSBundle(forClass: self.classForCoder).loadNibNamed("WistiaPlayerViewController", owner: self, options: nil)
        self.view = nib.first as! UIView
    }

    override public func viewDidLoad() {
        //It seems that SpriteKit always resumes a SKVideoNode when app resumes, so we need to cancel
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue: nil) { (note) -> Void in
            if !self.autoplayVideoWhenReady {
                self.pause()
            }
        }

        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidEnterBackgroundNotification, object: nil, queue: nil) { (note) -> Void in
            self.autoplayVideoWhenReady = false
        }
    }

    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        pause()
        cancelChromeInteractionTimer()
        autoplayVideoWhenReady = false
    }

    //MARK: - Public API

    weak var delegate:WistiaPlayerViewControllerDelegate?

    //TODO: implement playMediaWithHashedID()

    public convenience init(referrer: String, requireHLS: Bool = false){
        self.init()
        self.referrer = referrer
        self.requireHLS = requireHLS

        self.modalPresentationStyle = .FullScreen
    }

    //XXX: Following is useful for internal use, not sure if it's for WistiaKit
    //Like AVPlayer, calling this with the currently playing media is a noop (b/c that's the behavior of
    //the underlying WistiaPlayer)
    private func replaceCurrentVideoWithVideoForMedia(media: WistiaMedia, autoplay: Bool = false, forcingAsset asset: WistiaAsset? = nil) {
        autoplayVideoWhenReady = autoplay
        self.loadViewIfNeeded()
        let didReplace = wPlayer.replaceCurrentVideoWithVideoForMedia(media, forcingAsset: asset)
        if !didReplace && autoplayVideoWhenReady {
            presentForPlaybackShowingChrome(true)
            play()
        }
    }

    public func replaceCurrentVideoWithVideoForHashedID(hashedID:String) -> Bool {
        self.loadViewIfNeeded()
        return wPlayer.replaceCurrentVideoWithVideoForHashedID(hashedID)
    }

    public func play() {
        seekToStartIfAtEnd()

        //Due to an Apple bug, we can't control playback using the AVPlayer, need to use the SKVideoNode thru 360 view
        if playing360 {
            player360View.play()
        } else {
            wPlayer.play()
        }
    }

    public func pause() {
        //Due to an Apple bug, we can't control playback using the AVPlayer, need to use the SKVideoNode thru 360 view
        if playing360 {
            player360View.pause()
        } else {
            wPlayer.pause()
        }
    }

    public func togglePlayPause() {
        seekToStartIfAtEnd()

        //Due to an Apple bug, we can't control playback using the AVPlayer, need to use the SKVideoNode thru 360 view
        if playing360 {
            if wPlayer.rate == 0.0 {
                player360View.play()
            } else {
                player360View.pause()
            }
        } else {
            wPlayer.togglePlayPause()
        }
    }

}

//MARK: - Rotation
//NB: The 360 view assumes and requires that it's always displayed Portrait.
// The following code sets up then maintains portrait orientation for 360 player
extension WistiaPlayerViewController {

    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        seekToStartIfAtEnd()
        needsManualLayoutFor360View = true
        self.delegate?.wistiaPlayerViewControllerViewWillAppear(self)
    }

    override public func viewDidLayoutSubviews() {

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

    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
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

}

//MARK: - IB Actions
extension WistiaPlayerViewController {

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
            let hashedID = media.hashedID
            let videoTitle = media.name
            let shareString = "\(videoTitle) https://fast.wistia.net/360/\(hashedID)"

            let activityVC = UIActivityViewController(activityItems: [shareString], applicationActivities: nil)
            activityVC.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) -> Void in
                self.restorePlayerRate()
                self.delegate?.wistiaPlayerViewController(self, actionSheetDidCompleteForMedia: media, withActivityType: activityType, completed: completed, returnedItems: returnedItems, activityError: activityError)
            }
            self.delegate?.wistiaPlayerViewController(self, ActionSheetWillAppearForMedia: media)
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

}

//MARK: - Wistia Player Delegate
extension WistiaPlayerViewController: WistiaPlayerDelegate {

    public func wistiaPlayer(player:WistiaPlayer, didChangeStateTo newState:WistiaPlayer.State) {
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

        case .VideoError(let description):
            print("WistiaPlayer ERROR \(description)")
            presentForError()
        }
    }

    public func wistiaPlayer(player:WistiaPlayer, didChangePlaybackRateTo newRate:Float) {

        let playing = newRate > 0.0
        if playing {
            presentForPlaybackShowingChrome(true)
        }
        presentPlayPauseButtonForPlaying(playing)
    }

    public func wistiaPlayer(player: WistiaPlayer, didChangePlaybackProgressTo progress: Float, atCurrentTime currentTime: CMTime, ofDuration: CMTime) {
        //playhead tracks user's finger when scrubbing
        if !scrubbing {
            presentForProgress(progress, currentTime: currentTime)
        }
    }

    public func wistiaPlayerDidPlayToEndTime(player: WistiaPlayer) {
        //workaround SKVideoNode and/or SceneKit bug: video rapidly toggles between paused/playing upon reaching end
        self.pause()
    }

    public func wistiaPlayer(player: WistiaPlayer, willLoadVideoForAsset asset: WistiaAsset, fromMedia media:WistiaMedia) {
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
    }
}

//MARK: - View Presentation
internal extension WistiaPlayerViewController {

    func presentForPreLoading() {
        cancelChromeInteractionTimer()
        playerContainer.hidden = true
        posterLoadingIndicator.stopAnimating()
        posterErrorIndicator.hidden = true
        posterPlayButtonContainer.hidden = true
        showPlaybackControls(false, extraClose: false)
        presentForProgress(0, currentTime: nil)
    }

    func presentForLoading() {
        cancelChromeInteractionTimer()
        playerContainer.hidden = false
        posterLoadingIndicator.startAnimating()
        posterErrorIndicator.hidden = true
        posterPlayButtonContainer.hidden = true
        showPlaybackControls(false, extraClose: true)
        presentForProgress(0, currentTime: nil)
    }

    func presentForError() {
        cancelChromeInteractionTimer()
        playerContainer.hidden = true
        posterLoadingIndicator.stopAnimating()
        posterErrorIndicator.hidden = false
        posterPlayButtonContainer.hidden = true
        showPlaybackControls(false, extraClose: true)
        presentForProgress(0, currentTime: nil)
    }

    func presentForFirstPlayback() {
        cancelChromeInteractionTimer()
        playerContainer.hidden = false
        posterLoadingIndicator.stopAnimating()
        posterErrorIndicator.hidden = true
        posterPlayButtonContainer.hidden = false
        showPlaybackControls(true, extraClose: false)
        presentForProgress(0, currentTime: nil)
    }

    func presentForPlaybackShowingChrome(showChrome:Bool){
        playerContainer.hidden = false
        posterLoadingIndicator.stopAnimating()
        posterErrorIndicator.hidden = true
        posterPlayButtonContainer.hidden = true

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

    func presentForPlaybackToggleChrome() {
        if self.playbackControlsContainer.hidden {
            presentForPlaybackShowingChrome(true)
        } else {
            presentForPlaybackShowingChrome(false)
        }
    }

    func presentPlayPauseButtonForPlaying(playing:Bool){
        let podBundle = NSBundle(forClass: self.classForCoder)
        if playing {
            controlsPlayPauseButton.setImage(UIImage(named: "smallPause", inBundle: podBundle, compatibleWithTraitCollection: nil), forState: .Normal)
        } else {
            controlsPlayPauseButton.setImage(UIImage(named: "smallPlay", inBundle: podBundle, compatibleWithTraitCollection: nil), forState: .Normal)
        }
    }

    func presentForProgress(progress:Float, currentTime:CMTime?){
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

    func presentForCurrentProgress(){
        if let duration = wPlayer.currentItem?.duration {
            presentForProgress(Float(wPlayer.currentTime().seconds / duration.seconds), currentTime: wPlayer.currentTime())
        }
    }

    func startOrResetChromeInteractionTimer(){
        chromeInteractionTimer?.invalidate()
        chromeInteractionTimer = NSTimer(timeInterval: NSTimeInterval(5), target: self, selector: #selector(WistiaPlayerViewController.noChromeInteraction), userInfo: nil, repeats: false)
        NSRunLoop.mainRunLoop().addTimer(chromeInteractionTimer!, forMode: NSDefaultRunLoopMode)
    }

    func cancelChromeInteractionTimer(){
        chromeInteractionTimer?.invalidate()
    }

    func noChromeInteraction(){
        presentForPlaybackShowingChrome(false)
    }

    func showPlaybackControls(showControls: Bool, extraClose showExtraClose: Bool) {
        playbackControlsContainer.hidden = !showControls
        extraCloseButton.hidden = !showExtraClose
    }

}

//MARK: - Scrubbing
internal extension WistiaPlayerViewController {

    @IBAction func handleScrubberTap(sender: UITapGestureRecognizer) {
        if let seekTo = seekTimeForScrubberTrackContainerLocation(sender.locationInView(scrubberTrackContainerView)) {
            wPlayer.seekToTime(seekTo, completionHandler: nil)
        }
        startOrResetChromeInteractionTimer()
    }
    
    @IBAction private func handleScrubbing(sender: UIPanGestureRecognizer) {
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

    private func startScrubbing(){
        scrubbing = true
        moveScrubTrackTimeLabelAwayFromFinger(true)
        storePlayerRateAndPause()
        cancelChromeInteractionTimer()
    }

    private func userScrubbedTo(location:CGPoint){
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

    private func endScrubbing(location:CGPoint?){
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

    private func seekTimeForScrubberTrackContainerLocation(location:CGPoint?) -> CMTime? {
        if let x = location?.x, duration = wPlayer.currentItem?.duration {
            let pct = min(max(0,x / scrubberTrackContainerView.bounds.width),1)
            return CMTimeMultiplyByFloat64(duration, Float64(pct))
        } else {
            return nil
        }
    }

    private func storePlayerRateAndPause() {
        //Oddly enough, although we need to use the SKVideoNode to control play/pause, it doesn't return paused state correctly.
        //Always use the AVPlayer to accruately get the rate (ie. play/pause state) of the AVPLayer.
        playerRateBeforeScrubbing = wPlayer.rate
        pause()
    }

    private func restorePlayerRate() {
        if playing360 {
            //Due to an Apple bug, we can't control playback using the AVPlayer, need to use the SKVideoNode thru 360 view
            if playerRateBeforeScrubbing == 1.0 {
                player360View.play()
            }
        } else {
            wPlayer.rate = playerRateBeforeScrubbing
        }
    }

    private func moveScrubTrackTimeLabelAwayFromFinger(moveAway: Bool) {
        if moveAway {
            scrubTrackTimeLabelCenterConstraint.constant = -40
        } else {
            scrubTrackTimeLabelCenterConstraint.constant = 0
        }
        UIView.animateWithDuration(NSTimeInterval(0.25)) { () -> Void in
            self.view.layoutIfNeeded()
        }
    }


    private func seekToStartIfAtEnd(tolerance: CMTime = CMTime(seconds: 0.1, preferredTimescale: 10)) {
        let currentTime = wPlayer.currentTime()
        if let duration = wPlayer.currentItem?.duration {
            if currentTime > duration || (duration - currentTime) < tolerance {
                wPlayer.seekToTime(CMTime(seconds: 0, preferredTimescale: 10), completionHandler: nil)
            }
        }

    }

}