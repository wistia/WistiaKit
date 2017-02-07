//
//  WistiaPlayerViewController.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 4/22/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//
import Foundation

/**
 The delegate of a `WistiaPlayerViewController` must adopt the `WistiaPlayerViewControllerDelegate`
 protocol.  It will receive information about user interactions with the `WistiaPlayerViewController`
 through these methods.

 - Note: Unsupported on tvOS
 */
public protocol WistiaPlayerViewControllerDelegate : class {
//Until we support 360 on TV, just killing this entire thing

    /**
     The user has tapped the close button; you should dismiss the `WistiaPlayerViewController` at
     this point.  If no delegate object is registered, and the `WistiaPlayerViewController` has a 
     presenting view controller, it will dismiss itself.
     
     - Parameter vc: The `WistiaPlayerViewController` requesting to be closed.
     */
    func close(wistiaPlayerViewController vc: WistiaPlayerViewController)

    /**
     Called during at the same time as the `UIKit` standard `ViewController.viewWillAppear()`.
     
     - Parameter vc: The `WistiaPlayerViewController` whose view is about to appear.
    */
    func willAppear(wistiaPlayerViewController vc: WistiaPlayerViewController)

    /**
     The user has tapped the action button and the activity view will appear.  Called just before
     the `UIActivityViewController` is presented.
     
     - Parameter vc: The `WistiaPlayerViewController` that is presenting the `UIActivityViewController`
     - Parameter media: The currently loaded media that is the object of the activity
    */
    func wistiaPlayerViewController(_ vc: WistiaPlayerViewController, activityViewControllerWillAppearForMedia media:WistiaMedia)

    /**
     The user has finished with the activity view.  An action may have been taken or the view could have been dismissed
     through a cancellation.
     
     For parameters `activityType`, `completed`, and `activityError`, see the documentation for 
     `UIActivityViewController.UIActivityViewControllerCompletionWithItemsHandler` (mostly copied here for your convenience).

     - Parameter vc: The `WistiaPlayerViewController` that is presenting the `UIActivityViewController`
     - Parameter media: The currently loaded media that was the object of the activity
     - Parameter activityType: The type of the service that was selected by the user. For custom services, this is the value returned by the activityType method of a UIActivity object. For system-defined activities, it is one of the strings listed in "Built-in Activity Types” in UIActivity Class Reference.
     - Parameter completed: `True` if the service was performed or `False` if it was not. This parameter is also set to `False` when the user dismisses the view controller without selecting a service.
     - Parameter activityError: An error object if the activity failed to complete, or nil if the the activity completed normally.
     */
    func wistiaPlayerViewController(_ vc: WistiaPlayerViewController, activityViewControllerDidCompleteForMedia media:WistiaMedia, withActivityType activityType: String?, completed: Bool, activityError: Error?)

}


/**
 `WistiaPlayerViewController` acts much like an `AVPlayerViewController`.  It will display your 
 media including player controls customized in the Wistia fashion, allowing for user-initiated and/or
 programtic control of playback.

 Configure a `WistiaPlayerViewController` with a `WistiaMedia`, or the `hashedID` of one, and it will
 play the best asset for the device and current configuration.
 
 All video types supported by Wistia (currently _flat_ and _spherical_ / _360°_) are handled properly
 by this controller.

 Use the `WistiaPlayerViewControllerDelegate` as a convenient mechanism to respond to key events in the 
 controller's lifecycle.

 - Note: This class is declared `final` as it hooks into the `UIViewController` lifecycle at very specific 
 points.  Functionality is undefined if `extension`s are created that alter or prevent any of view controller 
 lifecycle methods from being called as expected.

 - Note: Unsupported on tvOS
 */
public final class WistiaPlayerViewController: UIViewController {
//Until we support 360 on TV, just killing this entire thing
#if os(iOS)

    //MARK: - Initialization

    /**
     Initialize a new `WistiaPlayerViewController` without an initial video for playback.
     
     - Important: If you are using [Domain Restrictions](https://wistia.com/doc/account-setup#domain_restrictions),
     referrer must match your whitelist or video will not load.

     - Parameter referrer: The referrer shown when viewing your video statstics on Wistia.
        \
         We recommend using a universal link to the video.
         This will allow you to click that link from the Wistia stats page
         while still recording the in-app playback location.
        \
         In the case it can't be a universal link, it should be a descriptive string identifying the location
         (and possibly state) of your app where this video isbeing played back
         eg. _ProductTourViewController_ or _SplashViewController.page1(uncoverted_email)_

     - Parameter requireHLS: Should this player use only the HLS master index manifest for playback (failing if there
         is not one available for any given `WistiaMedia` or `hashedID`)?
         \
         Apple requires HLS for video over 10m in length played over cellular connections.
         \
         Default, which we recommend, is `true`.
         \
         **NOTE:** You must have HLS enabled for your Wistia account.  Contact support@wistia.com if you're not sure.

     - Returns: An idle `WistiaPlayerViewController` not yet displayed.
     */
    public convenience init(referrer: String, requireHLS: Bool = false){
        self.init()
        self.referrer = referrer
        self.requireHLS = requireHLS

        self.modalPresentationStyle = .fullScreen
    }

    //MARK: - Instance Properties

    /**
     The underlying `WistiaPlayer` object.  For lower level functionality not available on this
     `WistiaPlayerViewController` object, the `WistiaPlayer` may provide it.

     - Important: API functionality available on the `WistiaPlayerViewController` should be preferred
     over the lower level `WistiaPlayer`.  For example, due to quirks of the rendering systems, `play` and `pause`
     are handled differently for flat and 360 videos; using `WistiaPlayer.play/pause` may result in
     unexpected behavior with 360 video.

     - Warning: Do not change the `delegate` of this `WistiaPlayer` object.
     */
    lazy public var wPlayer:WistiaPlayer = {
        //Our single player that we will put into either the Flat or the 360 view
        let wp = WistiaPlayer(referrer: self.referrer ?? "set_referrer_when_initializing_\(type(of: self))",
            requireHLS: self.requireHLS)
        wp.delegate = self
        wp.captionsRenderer.delegate = self
        wp.captionsRenderer.captionsView = self.captionsLabel
        return wp
    }()

    /**
     The object that acts as the delegate of the `WistiaPlayerViewController`.
     It must adopt the `WistiaPlayerViewControllerDelegate` protocol.

     The delegate is not retained.
     */
    public weak var delegate:WistiaPlayerViewControllerDelegate?


    /**
     The [_embed options_](https://wistia.com/doc/embed-options) refer to the customizations made to
     the display and playback behavior of a media.  They are loaded on per-media basis and used to
     alter the look and functionality of this instance of `WistiaPlayerViewController`.
     
     Setting this property will override the embed options returned with the `WistiaMedia` unless
     and until this is set to nil.
     */
    public var overridingEmbedOptions:WistiaMediaEmbedOptions? = nil {
        didSet {
            chooseActiveEmbedOptions()
        }
    }

    //MARK: - Changing Media

    /**
     Use this method to initiate the asynchronous loading of a video.  Pauses the currently playing video before
     starting the loading process.  Works just as well if there is no current video.
     
     You may call this method immediately upon initializing a new instance.  This will cause the view the load even
     if it is an orphan of the view hierarchy.

     - Note: This method is a no-op if the given `hashedID` matches the `hashedID` of the currently loaded `WistiaMedia`.
     Will return `False` in that case and will not change the current playback rate.

     - Parameter hashedID: The ID of a Wistia media from which to choose an asset to load for playback.

     - Returns: `False` if the current `WistiaMedia.hashedID` matches the parameter (resulting in a no-op).  `True` otherwise,
     _which does not guarantee success of the asynchronous video load_.
     */
    @discardableResult public func replaceCurrentVideoWithVideo(forHashedID hashedID:String) -> Bool {
        self.loadViewIfNeeded()
        return wPlayer.replaceCurrentVideoWithVideo(forHashedID: hashedID)
    }

    /**
     Use this method to initiate the asynchronous loading of a video.  Pauses the currently playing video before
     starting the loading process.  Works just as well if there is no current video.

     To observe the loading process and be notified when the given media is ready for playback, register an observer.

     - Note: This method is a no-op if the given `WistiaMedia` matches the currently loaded `WistiaMedia`.  Will return
     `False` in that case and will not change the current playback rate.
     
     - Important: The `WistiaMedia` should be fully fleshed out from the API and include assets.  Otherwise, use the
     _hashedID_ version of this method directly, **do not create a `WistiaMedia` and set the _hashedID_**.

     - Parameters media: The `WistiaMedia` from which to choose an asset to load for playback.
     - Parameter asset: The `WistiaAsset` of the `WistiaMedia` to load for playback.
     Leave this nil to have the `WistiaPlayer` choose an optimal asset for the current player configuration and device characteristics.
     - Parameter autoplay: If set to `True`, playback will begin immediately upon loading the video.  If the video is
        already loaded, playback will be resumed.

     - Returns: `False` if the current `WistiaMedia` matches the parameter (resulting in a no-op).  `True` otherwise,
     _which does not guarantee success of the asynchronous video load_.
     */
    public func replaceCurrentVideoWithVideo(forMedia media: WistiaMedia, forcingAsset asset: WistiaAsset? = nil, autoplay: Bool = false) {
        autoplayVideoWhenReady = autoplay
        self.loadViewIfNeeded()
        let didReplace = wPlayer.replaceCurrentVideoWithVideo(forMedia: media, forcingAsset: asset)
        if !didReplace && autoplayVideoWhenReady {
            presentForPlaybackShowingChrome(true)
            play()
        }
    }

    //MARK: - Controlling Playback

    /// Play the video.  This method is idempotent.
    public func play() {
        seekToStartIfAtEnd()

        //Due to an Apple bug, we can't control playback using the AVPlayer, need to use the SKVideoNode thru 360 view
        if playing360 {
            player360View.play()
        } else {
            wPlayer.play()
        }
    }

    /// Pause the video.  This method is idempotent.
    public func pause() {
        //Due to an Apple bug, we can't control playback using the AVPlayer, need to use the SKVideoNode thru 360 view
        if playing360 {
            player360View.pause()
        } else {
            wPlayer.pause()
        }
    }

    /// Play the video if it's currently paused.  Pause if it's currently playing.
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


    //MARK: - -----------Internal-----------

    //MARK: Player

    internal var referrer:String?
    internal var requireHLS = false
    //we don't care about the media, but we do care what it says about customizing the UI
    internal var activeEmbedOptions = WistiaMediaEmbedOptions() {
        didSet {
            customizeView(for: activeEmbedOptions)
            autoplayVideoWhenReady = activeEmbedOptions.autoplay
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
    internal var scrubbingSeekLastRequestedAt = Date()
    @IBOutlet weak internal var scrubTrackTimeLabelCenterConstraint: NSLayoutConstraint!

    internal var autoplayVideoWhenReady = false

    //MARK: IB Outlets: Gesture Recognizers
    @IBOutlet weak internal var overlayTapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak internal var overlayDoubleTapGestureRecognizer: UITapGestureRecognizer!

    //MARK: IB Outlets: Players
    @IBOutlet weak internal var playerContainer: UIView!
    @IBOutlet weak internal var playerFlatView: WistiaFlatPlayerView!
    @IBOutlet weak internal var player360View: Wistia360PlayerView!
    @IBOutlet weak internal var player360ViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak internal var player360ViewWidthConstraint: NSLayoutConstraint!
    internal var needsManualLayoutFor360View = true
    internal var playing360 = false

    //MARK: IB Outlets: Poster
    @IBOutlet weak internal var posterStillImageContainer: UIView!
    @IBOutlet weak internal var posterStillImage: UIImageView!
    @IBOutlet weak internal var posterPlayButtonContainer: UIVisualEffectView!
    @IBOutlet weak internal var posterPlayButton: UIButton!
    @IBOutlet weak internal var posterLoadingIndicator: UIActivityIndicatorView!

    //MARK: IB Outlets: Playback controls
    @IBOutlet weak internal var posterErrorIndicator: UIImageView!
    @IBOutlet weak internal var playbackControlsContainer: UIVisualEffectView!
    @IBOutlet weak internal var playbackControlsInnerContainer: UIVisualEffectView!
    @IBOutlet weak internal var controlsPlayPauseButton: UIButton!
    @IBOutlet weak internal var controlsCaptionsButton: UIButton!
    @IBOutlet weak internal var controlsActionButton: UIButton!
    @IBOutlet weak internal var controlsCloseButton: UIButton!
    @IBOutlet weak internal var scrubberTrackContainerView: UIView!
    @IBOutlet weak internal var scrubberCurrentProgressView: UIView!
    @IBOutlet weak internal var scrubberCurrentProgressViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak internal var scrubberTrackCurrentTimeLabel: UILabel!
    internal var chromeInteractionTimer:Timer?

    @IBOutlet weak internal var extraCloseButton: UIButton!

    //MARK: IB Outlets: Captions
    @IBOutlet weak internal var captionsLabel: UILabel!
    @IBOutlet weak internal var captionsLanguagePickerView: UIPickerView!

    //MARK: UIViewController Overrides

    //show status bar iff playback controls are showing
    internal var showStatusBar = true {
        didSet {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }

    /// Internal override.
    public override var prefersStatusBarHidden: Bool {
        get {
            return !showStatusBar
        }
    }

    /// Internal override.
    override final public func loadView() {
        let nib = Bundle(for: self.classForCoder).loadNibNamed("_WistiaPlayerViewController", owner: self, options: nil)
        self.view = nib?.first as! UIView
    }

    /// Internal override.
    override final public func viewDidLoad() {
        //It seems that SpriteKit always resumes a SKVideoNode when app resumes, so we need to cancel
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidBecomeActive, object: nil, queue: nil) { [weak self] (_) -> Void in
            if self != nil && !self!.autoplayVideoWhenReady {
                self?.pause()
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidEnterBackground, object: nil, queue: nil) { [weak self] (note) -> Void in
            self?.autoplayVideoWhenReady = false
        }
        
        overlayTapGestureRecognizer.require(toFail: overlayDoubleTapGestureRecognizer)

    }

    /// Internal override.
    override final public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        pause()
        cancelChromeInteractionTimer()
        autoplayVideoWhenReady = false
    }

#endif //os(iOS)
}
