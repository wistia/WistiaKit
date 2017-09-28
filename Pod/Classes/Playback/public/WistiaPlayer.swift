//
//  WistiaPlayer.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 4/11/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import WistiaKitCore
import AVKit
import AVFoundation
import MediaPlayer

//MARK: - WistiaPlayerDelegate

/**
 The delegate of a `WistiaPlayer` must adopt the `WistiaPlayerDelegate `protocol.  It will receive
 state related information through the delegate methods.
 
 Information provided includes high-level state about the `WistiaPlayer` as well as state of the
 underlying `AVPlayer`, normally obtained through Key-Value Observation (KVO).
 */
public protocol WistiaPlayerDelegate : class {

    /**
     Informs the delegate that the state of the `WistiaPlayer` has changed.
     
     - Note: Upon registration of a delegate, this method will be called with the state of
     the WistiaPlayer at the time of registration.
     
     - Parameter player: The `WistiaPlayer` that has changed state.
     - Parameter newState: The new (and now-current) state of the player.
    */
    func wistiaPlayer(_ player:WistiaPlayer, didChangeStateTo newState:WistiaPlayer.State)

    /**
     Informs the delegate the playback rate of the underlying `AVPlayer` has changed.  A rate of 0.0
     means the video is paused.  Normal playback rate is 1.0.
     
     - Parameter player: The `WistiaPlayer` for which the playback rate changed.
     - Parameter newRate: The new playback rate of the current media.
     */
    func wistiaPlayer(_ player:WistiaPlayer, didChangePlaybackRateTo newRate:Float)

    /**
     Informs the delegate about the current progress of media playback.
     
     During playback, this method will be called at roughly 10Hz.  A time interval of 1/10th of a second has been
     requested from the underlying `AVPlayer`, though it is not guaranteed.
     
     This will not be called when the player's rate is 0.0 (ie. video is paused).

     
     - Note: This is normally achieved with `AVPlayer.addPeriodicTimeObserverForInterval(interval:queue:usingBlock:)`.
     
     An observer is registered with the underlying `AVPlayer` whether the `WistiaPlayer` has a delegate or not.
     
     - Parameter player: The `WistiaPlayer` for which playback progress has changed.
     - Parameter progress: The amount of video that has been played back as a percentage (ranges from 0.0 to 1.0).
     - Parameter currentTime: The current time in the video for which playback is occurring.
     - Parameter duration: The total length of the video (used, along with currentTime, to calculate progress).
    */
    func wistiaPlayer(_ player:WistiaPlayer, didChangePlaybackProgressTo progress:Float, atCurrentTime currentTime:CMTime, ofDuration duration:CMTime)

    /**
     Informs the delegate that playback has reached the end of the media.
     
     By default, the player will pause and remain on the last frame of the video.

     If you have used the Customization API (or have overridden end video behavior directly on the
     `WistiaPlayer` instance), the player may return to the beginning of the video and additionally may resume playback.
     
     - Parameter player: The `WistiaPlayer` for which playback has reached the end.

    */
    func didPlayToEndTime(of player:WistiaPlayer)

    /**
     Informs the delegate of the specific `WistiaAsset` that will be loaded for playback.
     
     Use this method to get specifics about the asset selected for playback.  If you forced an asset,
     that will always be the one used.  Otherwise, heuristics will use the current value of `requireHLS` and
     device characteristics to select the best asset.
     
     - Parameter player: The `WistiaPlayer` loading the asset.
     - Parameter media: The `WistiaMedia` from which this asset was chosen.
     - Parameter asset: The `WistiaAsset` that will be loaded for playback, if the HLS master index manifest was not used.
     - Parameter usingHLSMasterIndexManifest: `True` iff playback is using the HLS master index manifest 
        (aka Manifest of Manifests). `asset` will be `nil`.

     */
    func wistiaPlayer(_ player:WistiaPlayer, willLoadVideoForMedia media:WistiaMedia, usingAsset asset:WistiaAsset?, usingHLSMasterIndexManifest: Bool)
    
    /**
     Informs the delegate that the `WistiaPlayer` is attempting to determine a URL for loading a `WistiaAsset`, giving an opportunity
     for the delegate to inject a url (such as a cached local asset url). The `WistiaPlayer` will use the URL returned by this method
     for playback. Return nil to allow the `WistiaPlayer` to determine the best playback URL.
     
     Optional. The default implementation returns `nil`, retaining standard functionality.
     
     - Parameter player: The `WistiaPlayer` determining the URL for playback.
     - Parameter media: The 'WistiaMedia' from which a playback URL is needed.
     */
    func wistiaPlayer(_ player:WistiaPlayer, shouldLoadVideoForMedia media:WistiaMedia) -> URL?
}

public extension WistiaPlayerDelegate {
    
    //Default implementation retains standard functionality
    public func wistiaPlayer(_ player: WistiaPlayer, shouldLoadVideoForMedia media: WistiaMedia) -> URL? {
        return nil
    }
    
}


//MARK: - WistiaPlayer

/**
    `WistiaPlayer` presents a convenient facade in front of `AVPlayer` for working with your Wistia hosted video.

    Create a `WistiaPlayer` with a `WistiaMedia`, or the `hashedID` of one, and it will play the best
    asset for the device and current configuration.

    Use the `WistiaPlayerDelegate` as a convenient mechanism to respond to key events
    in the video playback lifecycle.

    - Important: Render the video by presenting the `AVPlayerLayer` vended by `newPlayerLayer()`.  If you
    want this handled for you, including playback controls, see `WistiaPlayerViewController` or use
    a standard `AVPlayerViewController` via `WistiaPlayer.configureWithUnderlyingPlayer(_:)`.
 
    Spherical, 360°, binocular, or any other kind of video that needs to be presented in a non-flat way is
    not specially hanlded by `WistiaPlayer`.  Use the `WistiaPlayerViewController` to properly present these media types.

    - Note: The underlying `AVPlayer` is not exposed to facilitate the proper collection and reporting
    of important Wistia statistics.  Common functionality of the `AVPLayer` is available through
    public API directly on `WistiaPlayer` and through the delegate callbacks.
 */
public final class WistiaPlayer: NSObject {

    //MARK: - Initialization

    /**
     Initialize a new `WistiaPlayer` without an initial video for playback.
     
     Use the state updates of the delegate or the `state` variable to determine if and when this 
     `WistiaPlayer` has been initialized for playback
     
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

     - Returns: An idle `WistiaPlayer` not yet displayed.
     */
    public init(referrer: String, requireHLS: Bool = true) {
        self.referrer = referrer
        self.requireHLS = requireHLS
        self.avPlayer = AVPlayer()
        super.init()

        addPlayerObservers(for: self.avPlayer)
    }

    /**
     Initialize a new `WistiaPlayer` with an initial video for playback.

     Use the state updates of the delegate or the `state` variable to determine if and when this
     `WistiaPlayer` has been initialized for playback
     
     - Important: If you are using [Domain Restrictions](https://wistia.com/doc/account-setup#domain_restrictions),
     referrer must match your whitelist or video will not load.

     - Parameter hashedID: The ID of the media you wish to load asynchronously.

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

     - Returns: A `WistiaPlayer` that is initialized and asynchronously loading the media for playback.
     */
    public convenience init(hashedID: String, referrer: String, requireHLS: Bool = true) {
        self.init(referrer:referrer, requireHLS:requireHLS)
        self.replaceCurrentVideoWithVideo(forHashedID: hashedID)
    }

    /**
     Initialize a new `WistiaPlayer` with an initial video for playback.

     Use the state updates of the delegate or the `state` variable to determine if and when this
     `WistiaPlayer` has been initialized for playback
     
     - Important: If you are using [Domain Restrictions](https://wistia.com/doc/account-setup#domain_restrictions),
     referrer must match your whitelist or video will not load.

     - Parameter media: The `WistiaMedia` you wish to load asynchronously.
     
     - Parameter project: The `WistiaProject` to which the media belongs.  Optional.

     - Parameter referrer: The referrer shown when viewing your video statstics on Wistia.

         We recommend using a universal link to the video.
         This will allow you to click that link from the Wistia stats page
         while still recording the in-app playback location.

         In the case it can't be a universal link, it should be a descriptive string identifying the location
         (and possibly state) of your app where this video isbeing played back
         eg. _ProductTourViewController_ or _SplashViewController.page1(uncoverted_email)_

     - Parameter requireHLS: Should this player choose only HLS assets for playback (failing if there is not 
        one available for any given `WistiaMedia` or `hashedID`)?

        Apple requires HLS for video over 10m in length played over cellular connections.

        Default, which we recommend, is `true`.

     - Returns: A `WistiaPlayer` that is initialized and asynchronously loading the media for playback.
     */
    public convenience init(media: WistiaMedia, project: WistiaProject? = nil, referrer: String, requireHLS: Bool = true) {
        self.init(referrer:referrer, requireHLS:requireHLS)
        self.replaceCurrentVideoWithVideo(forMedia: media, fromProject: project)
    }

    //MARK: - Instance Properties

    /** 
    This player will disable the iOS idle timer during playback (ie. video rate > 0) and
    re-enable the idle timer when the video is paused.

    If you wish to have total control over the idle timer, set this to false.

    Changing the value has no immediate effect on the idle timer.
    */
    public var preventIdleTimerDuringPlayback = true


    /**
     The object that acts as the delegate of the `WistiaPlayer`.  It must adopt the `WistiaPlayerDelegate` protocol.
     
     The delegate is not retained.
     
     - Note: Upon setting delegate, you will immediately receve a state change callback with the current state
     */
    public weak var delegate:WistiaPlayerDelegate? {
        didSet {
            if let d = delegate {
                d.wistiaPlayer(self, didChangeStateTo: self.state)
            }
        }
    }

    /**
     Change this before calling `replaceCurrentVideoWithVideo...(_:)` to have an effect on the next video load.

     See initializers for complete discussion of HLS.
     */
    public var requireHLS:Bool

    /// This string is populated as "album title" in the Now Playing dictionary.
    public var nowPlayingAttribution: String? = "Wistia"

    //MARK: - Changing Media

    /**
     Use this method to initiate the asynchronous loading of a video.  Pauses the currently playing video before
     starting the loading process.  Works just as well if there is no current video.
     
     To observe the loading process and be notified when the given media is ready for playback, register an observer.
     
     - Note: This method is a no-op if the given `WistiaMedia` matches the currently loaded `WistiaMedia`.  Will return
     `False` in that case and will not change the current playback rate.
     
     - Important: The `WistiaMedia` should be fully fleshed out from the API and include assets.  Otherwise, use the 
     _hashedID_ version of this method directly, **do not create a `WistiaMedia` and set the _hashedID_**.
     
     - Parameter media: The `WistiaMedia` from which to choose an asset to load for playback.
     - Parameter asset: The `WistiaAsset` of the `WistiaMedia` to load for playback.
        Leave this nil to have the `WistiaPlayer` choose an optimal asset for the current player configuration and device characteristics.
     - Parameter project: The `WistiaProject` to which the media belongs.  Optional.
     
     - Returns: `False` if the current `WistiaMedia` matches the parameter (resulting in a no-op).  `True` otherwise,
        _which does not guarantee success of the asynchronous video load_.
    */
    @discardableResult public func replaceCurrentVideoWithVideo(forMedia media: WistiaMedia, forcingAsset asset: WistiaAsset? = nil, fromProject project: WistiaProject? = nil) -> Bool {
        guard media != self.media else { return false }
        pause()

        let slug:String? = (asset != nil ? asset!.slug : nil)
        readyPlayback(for: media, choosingAssetWithSlug: slug, fromProject: project)
        return true
    }

    /**
     Use this method to initiate the asynchronous loading of a video.  Pauses the currently playing video before
     starting the loading process.  Works just as well if there is no current video.

     To observe the loading process and be notified when the given media is ready for playback, register an observer.

     - Note: This method is a no-op if the given `hashedID` matches the `hashedID` of the currently loaded `WistiaMedia`.  
     Will return `False` in that case and will not change the current playback rate.

     - Parameter hashedID: The ID of a Wistia media from which to choose an asset to load for playback.
     - Parameter slug: The slug of a Wistia asset (of the media matching the given `hashedID`) to load for playback.
        Leave this nil to have the `WistiaPlayer` choose an optimal asset for the current player configuration and device characteristics.

     - Returns: `False` if the current `WistiaMedia.hashedID` matches the parameter (resulting in a no-op).  `True` otherwise,
     _which does not guarantee success of the asynchronous video load_.
     */
    @discardableResult public func replaceCurrentVideoWithVideo(forHashedID hashedID: String, assetWithSlug slug: String? = nil) -> Bool {
        guard media?.hashedID != hashedID else { return false }
        avPlayer.pause()

        WistiaAPI.mediaInfo(for: hashedID, referer: referrer) { media, error in
            if let m = media {
                self.media = m
                self.readyPlayback(for: m, choosingAssetWithSlug: slug)
            } else {
                self.media = nil
                self.state = .mediaNotFoundError(badHashedID: hashedID)
            }
        }
        return true
    }

    //MARK: - Controlling Playback

    /// Play the video.  This method is idempotent.
    @objc public func play() {
        if avPlayer.rate == 0 {
            avPlayer.play()
            log(.play)
        }
    }

    /// Pause the video.  This method is idempotent.
    @objc public func pause() {
        if avPlayer.rate > 0 {
            avPlayer.pause()
            log(.pause)
        }
    }

    /// Play the video if it's currently paused.  Pause if it's currently playing.
    @objc public func togglePlayPause() {
        if avPlayer.rate > 0 {
            avPlayer.pause()
            log(.pause)
        } else {
            avPlayer.play()
            log(.play)
        }
    }

    /**
     Seek to a given time in the current video and be notified when seeking is done.
     
     - Note: It is best practice to pause the video during interactive scrubbing.
     
     - Parameter time: The target time to move the playhead.
     - Parameter tolerance: How close to the target time must the seek move the playhead.  Smaller tolerances may result in
        slower seeking due to additional required video decoding.
     - Parameter completionHandler: The block to invoke when seeking is complete.  This block takes one parameter, `finished`,
        which indicates if the seek operation completed.  `False` indicates another seek request interrupted this one.

    */
    public func seek(to time:CMTime, withTolerance tolerance: CMTime = CMTime(seconds: 1, preferredTimescale: 10), completionHandler: ((Bool) -> Void)?){
        self.avPlayer.seek(to: time, toleranceBefore: tolerance, toleranceAfter: tolerance) { (finished) -> Void in
            if finished {
                self.log(.seek)
            }
            self.updateNowPlayingWithCurrentTimeAndRate()
            completionHandler?(finished)
        }
    }

    //MARK: Remotely controlling playback

    // To make sure we don't register multiple times
    private var handlingRemoteControlEvents = false

    /**
     Registers this `WistiaPlayer` as the handler for remote control events (ie. headphone controls, control center's
     "Now Playing" panel, etc.).  As a side effect, the Now Playing panel of control center will begin showing information
     for the media currently loaded by this player.  An additional side effect of that; the user can choose an AirPlay
     destination for the current media.
     
     This player is automatically deregistered as a remote control event handler on deinitialization.
     
     - Important: Only one `WistiaPlayer` should be handling remote control events. Do not call this on a second 
        `WistiaPlayer` unless and until you have called `endHandlingRemoteControlEvents` on this one (or this one
        was deinitialized, acheiving the same).

     - Note: Now playing information is automatically populated but it will not show up until an app begins
        handling remote control events.  The old way to do this was calling 
        `UIApplication.shared.beginReceivingRemoteControlEvents()`.  It is now done by registering a target-action
        handler for one or more of the commands available from `MPRemoteCommandCenter.shared()`.

     */
    public func beginHandlingRemoteControlEvents() {
        guard !handlingRemoteControlEvents else { return }
        handlingRemoteControlEvents = true

        let r = MPRemoteCommandCenter.shared()
        r.pauseCommand.addTarget(self, action: #selector(WistiaPlayer.pause))
        r.stopCommand.addTarget(self, action: #selector(WistiaPlayer.pause))
        r.playCommand.addTarget(self, action: #selector(WistiaPlayer.play))
        r.togglePlayPauseCommand.addTarget(self, action: #selector(WistiaPlayer.togglePlayPause))

        r.nextTrackCommand.isEnabled = false
        r.previousTrackCommand.isEnabled = false

        r.changePlaybackRateCommand.isEnabled = false
        r.seekForwardCommand.isEnabled = false
        r.seekBackwardCommand.isEnabled = false
        r.skipForwardCommand.isEnabled = false
        r.skipBackwardCommand.isEnabled = false

        r.ratingCommand.isEnabled = false
        r.likeCommand.isEnabled = false
        r.dislikeCommand.isEnabled = false

        r.bookmarkCommand.isEnabled = false

        if #available(iOS 9.1, *) {
            r.changePlaybackPositionCommand.addTarget(self, action: #selector(WistiaPlayer.seekFromRemoteCommand))
        }
    }

    /**
     Unregisters this `WistiaPlayer` as the handler for remote control events.
     
     This will happen automatically upon `deinit()`.
     
     - Important: Only one `WistiaPlayer` should be handling remote control events. You must call this on the current
        handler (or allow it to `deinit()`) before registering a different `WistiaPlayer`.

     */
    public func endHandlingRemoteControlEvents() {
        guard handlingRemoteControlEvents else { return }
        handlingRemoteControlEvents = false

        let r = MPRemoteCommandCenter.shared()
        r.pauseCommand.removeTarget(self)
        r.stopCommand.removeTarget(self)
        r.playCommand.removeTarget(self)
        r.togglePlayPauseCommand.removeTarget(self)

        if #available(iOS 9.1, *) {
            r.changePlaybackPositionCommand.removeTarget(self)
        }
    }

    @objc internal func seekFromRemoteCommand(_ event: MPChangePlaybackPositionCommandEvent) {
        seek(to: CMTime(seconds: event.positionTime, preferredTimescale: 100), completionHandler: nil)
    }

    //MARK: - State Information

    /**
     - Returns: The current time of the currently playing video.
    */
    public func currentTime() -> CMTime {
        return avPlayer.currentTime()
    }

    /**
     The current rate of playback.  A value of 0.0 means paused, while 1.0 means playing at natural rate.
     
     See `AVPlayer.rate` for further information.
     */
    public var rate:Float {
        get {
            return avPlayer.rate
        }
        set(newRate) {
            avPlayer.rate = newRate
            if newRate == 1.0 {
                log(.play)
            } else if rate == 0.0 {
                log(.pause)
            }
        }
    }

    /// - Returns: `True` if the video is currently playing at any rate.
    public func isPlaying() -> Bool {
        return rate > 0.0
    }

    /**
     Enumeration of the possible states a `WistiaPlayer` instance may be in at any time.
     Register an object as the delegate to get this state information.
     
     - `Initialized` : `WistiaPlayer` instance created but has not yet started loading a video
     - `VideoPreLoading` : About to examine a `WistiaMedia` and choose a `WistiaAsset` for playback
     - `VideoLoading` : `WistiaAsset` has been chosen and underlying media file will start loading
     - `MediaNotFoundError(badHashedID:)` : A `WistiaMedia` could not be found for the given `hashedID`
     - `VideoLoadingError(description:problemMedia:problemAsset:)` : The `WistiaMedia` or `WistiaAsset` could not be loaded.
     - `VideoPlaybackError(description:)` : An error occurred during playback.
     - `VideoReadyForPlayback` : The video file has completed initial loading and is ready for playback.
     */
    public enum State {
        /// `WistiaPlayer` instance created but has not yet started loading a video
        case initialized

        /// About to examine the given `WistiaMedia` and choose a `WistiaAsset` for playback
        case videoPreLoading(media: WistiaMedia)

        /// `WistiaAsset` has been chosen and underlying media file will start loading
        case videoLoading

        /// A `WistiaMedia` could not be found for the given `hashedID`
        case mediaNotFoundError(badHashedID: String)

        /// The `WistiaMedia` or `WistiaAsset` could not be loaded.
        /// This is possibly due to unsatisfiable HLS requirement.  
        /// See description for more information.
        case videoLoadingError(description:String, problemMedia: WistiaMedia?, problemAsset: WistiaAsset?)

        /// An error occurred during playback.  See description for more information.
        case videoPlaybackError(description:String)

        /// The video file has completed initial loading and is ready for playback.
        /// This state is only entered once per video loaded.  Player remains in this state while the video
        /// is playing.  Use the delegate for playback state changes.
        case videoReadyForPlayback
    }

    //MARK: -

    //MARK: Displaying Video

    /**
     Create a new `AVPlayerLayer` configured for this instance of `WistiaPlayer`.  This will remove
     the player form any previously fetched `AVPlayerLayer`s
     
     - Note: Unless you need a standalone layer, we recommend using a `WistiaFlatPlayerView` and setting
     it's `wistiaPlayer` property to this instance.  It is a regular `UIView` and often more familiar
     than using layers without sacrificing much flexibility.
     
     - Important: `AVPlayerLayer`s are created with size `CGSizeZero`.  You will want to change that
     if you wish to see the video.  See `AVPlayerLayer(player:)` for further information.

     - Returns: A new `AVPlayerLayer` to which we direct our visual output.
     */
    public func newPlayerLayer() -> AVPlayerLayer? {
        return AVPlayerLayer(player: avPlayer)
    }

    /**
     Configure a standard `AVPlayerViewController` to use the `AVPlayer` underlying this `WistiaPlayer`.

     For Wistia style UI and controls, see `WistiaPlayerViewController`.

     - Warning: The performance and functionality of a `WistiaPlayer` instance is undefined if the underlying
     `AVPlayer` is manipulated directly outside of `AVPlayerViewController`.
    */
    public func configure(with vc:AVPlayerViewController) {
        vc.player = self.avPlayer
    }

    //MARK: Displaying Captions

    /**
     The `WistiaCaptionsRenderer` configured for this instance of `WistiaPlayer`.  Connect that
     object's `captionsView` and set `enabled` to `true` to begin displaying captions.
     
     A `WistiaCaptionsRenderer` will continue to work for the `WistiaPlayer` that vended it, even when the
     video being played is changed.
     
     - Important: `WistiaPlayerViewController` handles captions (using a renderer vended by this function) by default.
     No additional work is needed on your part, but the video must have captions and they must be enabled in the
     video's customizations.
    */
    public let captionsRenderer = WistiaCaptionsRenderer()

    //MARK: - Internal

    deinit {
        removePlayerItemObservers(for: self.avPlayer.currentItem)
        removePlayerObservers(for: self.avPlayer)
        endHandlingRemoteControlEvents()
        WistiaStatsManager.sharedInstance.removeEventCollector(statsCollector)
    }

    internal(set) var state:State = .initialized {
        didSet {
            self.delegate?.wistiaPlayer(self, didChangeStateTo: state)
        }
    }

    internal var currentItem:AVPlayerItem? {
        get {
            return avPlayer.currentItem
        }
    }
    internal var avPlayer:AVPlayer

    internal var media:WistiaMedia? {
        didSet {
            captionsRenderer.media = media
        }
    }

    internal var project: WistiaProject?

    internal var statsCollector: WistiaMediaEventCollector?
    internal var referrer: String

    // The 4K mp4s were not playing well.
    // Keeping max at 1920 seems good on testing thus far.
    // XXX: This should be revisited when we have HLS assets for 360 videos
    internal let SphericalTargetAssetWidth:Int64 = 1920

    //Raw Observation
    internal var playerItemContext = 1
    internal var playerContext = 2
    internal var periodicTimeObserver: Any?

    /// Calls super if the posted KVO isn't handled.  Declared `final` becuase overriding would cause incorrect behavior.
    final public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        _wkObserveValue(forKeyPath: keyPath, ofObject: object as AnyObject?, change: change, context: context!)
    }
}

//MARK: - WistiaPlayer.State Equality
/**
 Compare two `WistiaPlayer.State` instances for equality, ignoring associated values.
 
 - Returns: `True` if both states are the same enum case, not matter what is contained in their 
    associated values (if ap)plicable.
 */
public func == (a: WistiaPlayer.State, b: WistiaPlayer.State) -> Bool {
    switch(a, b){
    case (.initialized, .initialized): return true
    case (.videoPreLoading, .videoPreLoading): return true
    case (.videoLoading, .videoLoading): return true
    case (.mediaNotFoundError(_), .mediaNotFoundError(_)): return true
    case (.videoLoadingError(_, _, _), .videoLoadingError(_, _, _)): return true
    case (.videoPlaybackError(_), .videoPlaybackError(_)): return true
    case (.videoReadyForPlayback, .videoReadyForPlayback): return true
    default:
        return false
    }
}
