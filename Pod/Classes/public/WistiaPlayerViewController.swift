//
//  WistiaPlayerViewController.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 4/22/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

//Until we support 360 on TV, just killing this entire thing
#if os(iOS)

import Foundation

public protocol WistiaPlayerViewControllerDelegate : class {
    //For WistiaKit, will probably want to expand on this delegate to be more like what's on web
    func closeWistiaPlayerViewController(vc: WistiaPlayerViewController)
    func wistiaPlayerViewControllerViewWillAppear(vc: WistiaPlayerViewController)
    func wistiaPlayerViewController(vc: WistiaPlayerViewController, ActionSheetWillAppearForMedia media:WistiaMedia)
    func wistiaPlayerViewController(vc: WistiaPlayerViewController, actionSheetDidCompleteForMedia media:WistiaMedia, withActivityType activityType: String?, completed: Bool, returnedItems: [AnyObject]?, activityError: NSError?)
}

public final class WistiaPlayerViewController: UIViewController {

    public weak var delegate:WistiaPlayerViewControllerDelegate?

    public convenience init(referrer: String, requireHLS: Bool = false){
        self.init()
        self.referrer = referrer
        self.requireHLS = requireHLS

        self.modalPresentationStyle = .FullScreen
    }

    //Setting this will override the embed options from any video loaded unless and until
    //this is set to nil
    public var overridingEmbedOptions:WistiaMediaEmbedOptions? = nil {
        didSet {
            chooseActiveEmbedOptions()
        }
    }

    public func replaceCurrentVideoWithVideoForHashedID(hashedID:String) -> Bool {
        self.loadViewIfNeeded()
        return wPlayer.replaceCurrentVideoWithVideoForHashedID(hashedID)
    }

    //Like AVPlayer, calling this with the currently playing media is a noop (b/c that's the behavior of
    //the underlying WistiaPlayer)
    public func replaceCurrentVideoWithVideoForMedia(media: WistiaMedia, forcingAsset asset: WistiaAsset? = nil, autoplay: Bool = false) {
        autoplayVideoWhenReady = autoplay
        self.loadViewIfNeeded()
        let didReplace = wPlayer.replaceCurrentVideoWithVideoForMedia(media, forcingAsset: asset)
        if !didReplace && autoplayVideoWhenReady {
            presentForPlaybackShowingChrome(true)
            play()
        }
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

    //////////////////////////////////////////////////////////////////////////////////////////
    //MARK: - Internal

    //MARK: Player
    //Our single player that we will put into either the Flat or the 360 view
    lazy internal var wPlayer:WistiaPlayer = {
        let wp = WistiaPlayer(referrer: self.referrer ?? "set_referrer_when_initializing_\(self.dynamicType)",
                              requireHLS: self.requireHLS)
        wp.delegate = self
        return wp
    }()
    internal var referrer:String?
    internal var requireHLS = true
    //we don't care about the media, but we do care what it says about customizing the UI
    internal var activeEmbedOptions = WistiaMediaEmbedOptions() {
        didSet {
            customizeViewFor(activeEmbedOptions)
        }
    }
    internal var currentMediaEmbedOptions:WistiaMediaEmbedOptions? = nil {
        didSet {
            chooseActiveEmbedOptions()
        }
    }


    //MARK: Scrubbing
    internal var playerRateBeforeScrubbing:Float = 0.0
    internal var scrubbing:Bool = false
    internal var scrubbingSeekLastRequestedAt = NSDate()
    @IBOutlet weak internal var scrubTrackTimeLabelCenterConstraint: NSLayoutConstraint!

    internal var autoplayVideoWhenReady = false

    //MARK: - IB Outlets
    //MARK: Gesture Recognizers
    @IBOutlet weak internal var overlayTapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak internal var overlayDoubleTapGestureRecognizer: UITapGestureRecognizer!

    //MARK: Players
    @IBOutlet weak internal var playerContainer: UIView!
    @IBOutlet weak internal var playerFlatView: WistiaFlatPlayerView!
    @IBOutlet weak internal var player360View: Wistia360PlayerView!
    @IBOutlet weak internal var player360ViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak internal var player360ViewWidthConstraint: NSLayoutConstraint!
    internal var needsManualLayoutFor360View = true
    internal var playing360 = false

    //MARK: Poster
    @IBOutlet weak internal var posterStillImageContainer: UIView!
    @IBOutlet weak internal var posterStillImage: UIImageView!
    @IBOutlet weak internal var posterPlayButtonContainer: UIVisualEffectView!
    @IBOutlet weak internal var posterPlayButton: UIButton!
    @IBOutlet weak internal var posterLoadingIndicator: UIActivityIndicatorView!

    //MARK: Playback controls
    @IBOutlet weak internal var posterErrorIndicator: UIImageView!
    @IBOutlet weak internal var playbackControlsContainer: UIVisualEffectView!
    @IBOutlet weak internal var playbackControlsInnerContainer: UIVisualEffectView!
    @IBOutlet weak internal var controlsPlayPauseButton: UIButton!
    @IBOutlet weak internal var controlsActionButton: UIButton!
    @IBOutlet weak internal var controlsCloseButton: UIButton!
    @IBOutlet weak internal var scrubberTrackContainerView: UIView!
    @IBOutlet weak internal var scrubberCurrentProgressView: UIView!
    @IBOutlet weak internal var scrubberCurrentProgressViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak internal var scrubberTrackCurrentTimeLabel: UILabel!
    internal var chromeInteractionTimer:NSTimer?

    @IBOutlet weak internal var extraCloseButton: UIButton!

    //MARK: - UIViewController Normal Stuff

    //show status bar iff playback controls are showing
    internal var showStatusBar = true {
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

        overlayTapGestureRecognizer.requireGestureRecognizerToFail(overlayDoubleTapGestureRecognizer)
    }

    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        pause()
        cancelChromeInteractionTimer()
        autoplayVideoWhenReady = false
    }

}

#endif //os(iOS)