//
//  WistiaPlayer.swift
//  Playback
//
//  Created by Daniel Spinosa on 4/11/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import AVKit
import AVFoundation

//MARK: - WistiaPlayerDelegate

/**
 The delegate of a `WistiaPlayer` must adopt the `WistiaPlayerDelegate `protocol.  It will receive
 state related information through the delegaet methods.
 
 Information provided includes high-level state about the `WistiaPlayer` as well as state of the
 underlying `AVPlayer`, normally obtained through Key-Value Observation (KVO).
 */
public protocol WistiaPlayerDelegate : class {

    /**
     Informs the delegate that the state of the `WistiaPlayer` has changed.
     
     - Note: Upon registration of a delegate, this method will be called with the state of
     the WistiaPlayer at the time of registration.
     
     - Parameters:
        - player: The `WistiaPlayer` that has changed state.
        - newState: The new (and now-current) state of the player.
    */
    func wistiaPlayer(player:WistiaPlayer, didChangeStateTo newState:WistiaPlayer.State)

    /**
     Informs the delegate the playback rate of the underlying `AVPlayer` has changed.  A rate of 0.0
     means the video is paused.  Normal playback rate is 1.0.
     
     - Parameters:
        - player: The `WistiaPlayer` for which the playback rate changed.
        - newRate: The new playback rate of the current media.
     */
    func wistiaPlayer(player:WistiaPlayer, didChangePlaybackRateTo newRate:Float)

    /**
     Informs the delegate about the current progress of media playback.
     
     During playback, this method will be called at roughly 10Hz.  A time interval of 1/10th of a second has been
     requested from the underlying `AVPlayer`, though it is not guaranteed.
     
     This will not be called when the player's rate is 0.0 (ie. video is paused).

     
     - Note: This is normally achieved with `AVPlayer.addPeriodicTimeObserverForInterval(interval:queue:usingBlock:)`.
     
     An observer is registered with the underlying `AVPlayer` whether the `WistiaPlayer` has a delegate or not.
     
     - Parameters:
        - player: The `WistiaPlayer` for which playback progress has changed.
        - progress: The amount of video that has been played back as a percentage (ranges from 0.0 to 1.0).
        - currentTime: The current time in the video for which playback is occurring.
        - duration: The total length of the video (used, along with currentTime, to calculate progress).
    */
    func wistiaPlayer(player:WistiaPlayer, didChangePlaybackProgressTo progress:Float, atCurrentTime currentTime:CMTime, ofDuration duration:CMTime)

    /**
     Informs the delegate that playback has reached the end of the media.
     
     By default, the player will pause and remain on the last frame of the video.

     If you have used the Customization API (or have overridden end video behavior directly on the
     `WistiaPlayer` instance), the player may return to the beginning of the video and additionally may resume playback.
     
     - Parameter player: The `WistiaPlayer` for which playback has reached the end.

    */
    func wistiaPlayerDidPlayToEndTime(player:WistiaPlayer)

    /**
     Informs the delegate of the specific `WistiaAsset` that will be loaded for playback.
     
     Use this method to get specifics about the asset selected for playback.  If you forced an asset,
     that will always be the one used.  Otherwise, heuristics will use the current value of `requireHLS` and
     device characteristics to select the best asset.
     
     - Parameters:
        - asset: The `WistiaAsset` that will be loaded for playback.
        - media: The `WistiaMedia` from which this asset was chosen.
     */
    func wistiaPlayer(player:WistiaPlayer, willLoadVideoForAsset asset:WistiaAsset, fromMedia media:WistiaMedia)
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
     
     - Parameters:
        - referrer: The referrer shown when viewing your video statstics on Wistia.
            
            We recommend using a universal link to the video.
            This will allow you to click that link from the Wistia stats page
            while still recording the in-app playback location.
        
            In the case it can't be a universal link, it should be a descriptive string identifying the location
            (and possibly state) of your app where this video isbeing played back
            eg. _ProductTourViewController_ or _SplashViewController.page1(uncoverted_email)_

        - requireHLS: Should this player choose only HLS assets for playback (failing if there is not one available
            for any given `WistiaMedia` or `hashedID`)?
     
            Apple requires HLS for video over 10m in length played over cellular connections.
     
            Default, which we recommend, is `true`.

     - Returns: An idle `WistiaPlayer` not yet displayed.
     */
    public init(referrer: String, requireHLS: Bool = true) {
        self.referrer = referrer
        self.requireHLS = requireHLS
        self.avPlayer = AVPlayer()
        super.init()

        addPlayerObservers(self.avPlayer)
    }

    /**
     Initialize a new `WistiaPlayer` with an initial video for playback.

     Use the state updates of the delegate or the `state` variable to determine if and when this
     `WistiaPlayer` has been initialized for playback

     - Parameters:
        - hashedID: The ID of the media you wish to load asynchronously.

        - referrer: The referrer shown when viewing your video statstics on Wistia.

         We recommend using a universal link to the video.
         This will allow you to click that link from the Wistia stats page
         while still recording the in-app playback location.

         In the case it can't be a universal link, it should be a descriptive string identifying the location
         (and possibly state) of your app where this video isbeing played back
         eg. _ProductTourViewController_ or _SplashViewController.page1(uncoverted_email)_

         - requireHLS: Should this player choose only HLS assets for playback (failing if there is not one available
         for any given `WistiaMedia` or `hashedID`)?

         Apple requires HLS for video over 10m in length played over cellular connections.

         Default, which we recommend, is `true`.

     - Returns: A `WistiaPlayer` that is initialized and asynchronously loading the media for playback.
     */
    public convenience init(hashedID: String, referrer: String, requireHLS: Bool = true) {
        self.init(referrer:referrer, requireHLS:requireHLS)
        self.replaceCurrentVideoWithVideoForHashedID(hashedID)
    }

    /**
     Initialize a new `WistiaPlayer` with an initial video for playback.

     Use the state updates of the delegate or the `state` variable to determine if and when this
     `WistiaPlayer` has been initialized for playback

     - Parameters:
     - media: The `WistiaMedia` you wish to load asynchronously.

     - referrer: The referrer shown when viewing your video statstics on Wistia.

     We recommend using a universal link to the video.
     This will allow you to click that link from the Wistia stats page
     while still recording the in-app playback location.

     In the case it can't be a universal link, it should be a descriptive string identifying the location
     (and possibly state) of your app where this video isbeing played back
     eg. _ProductTourViewController_ or _SplashViewController.page1(uncoverted_email)_

     - requireHLS: Should this player choose only HLS assets for playback (failing if there is not one available
     for any given `WistiaMedia` or `hashedID`)?

     Apple requires HLS for video over 10m in length played over cellular connections.

     Default, which we recommend, is `true`.

     - Returns: A `WistiaPlayer` that is initialized and asynchronously loading the media for playback.
     */
    public convenience init(media: WistiaMedia, referrer: String, requireHLS: Bool = true) {
        self.init(referrer:referrer, requireHLS:requireHLS)
        self.replaceCurrentVideoWithVideoForMedia(media)
    }

    //MARK: - Instance Properties

    /** 
    This player will disable the iOS idle timer during playback (ie. video rate > 0) and
    re-enable the idle timer when the video is paused.

    If you wish to have total control over the idle timer, set this to false.

    Changing the value has no immediate effect on the idle timer.
    */
    var preventIdleTimerDuringPlayback = true


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

    //MARK: - Changing Media

    /**
     Use this method to initiate the asynchronous loading of a video.  Pauses the currently playing video before
     starting the loading process.  Works just as well if there is no current video.
     
     To observe the loading process and be notified when the given media is ready for playback, register an observer.
     
     - Note: This method is a no-op if the given `WistiaMedia` matches the currently loaded `WistiaMedia`.  Will return
     `False` in that case and will not change the current playback rate.
     
     - Parameters:
        - media: The `WistiaMedia` from which to choose an asset to load for playback.
        - asset: The `WistiaAsset` of the `WistiaMedia` to load for playback.  
        Leave this nil to have the `WistiaPlayer` choose an optimal asset for the current player configuration and device characteristics.
     
     - Returns: `False` if the current `WistiaMedia` matches the parameter (resulting in a no-op).  `True` otherwise,
        _which does not guarantee success of the asynchronous video load_.
    */
    func replaceCurrentVideoWithVideoForMedia(media:WistiaMedia, forcingAsset asset:WistiaAsset? = nil) -> Bool {
        guard media != self.media else { return false }
        pause()

        let slug:String? = (asset != nil ? asset!.slug : nil)
        readyPlaybackForMedia(media, choosingAssetWithSlug: slug)
        return true
    }


    //Pauses playback of the current video, loads the media for the given hashedID asynchronously.
    //If a slug is included, will choose the asset matching that slug, overriding everything.
    // Like AVPlayer, if the new media is the same as the currently playing media, this is a noop
    // Returns false on the event of a noop.  True otherwise.

    /**
     Use this method to initiate the asynchronous loading of a video.  Pauses the currently playing video before
     starting the loading process.  Works just as well if there is no current video.

     To observe the loading process and be notified when the given media is ready for playback, register an observer.

     - Note: This method is a no-op if the given `hashedID` matches the `hashedID` of the currently loaded `WistiaMedia`.  
     Will return `False` in that case and will not change the current playback rate.

     - Parameters:
        - hashedID: The ID of a Wistia media from which to choose an asset to load for playback.
        - slug: The slug of a Wistia asset (of the media matching the given `hashedID`) to load for playback.  
        Leave this nil to have the `WistiaPlayer` choose an optimal asset for the current player configuration and device characteristics.

     - Returns: `False` if the current `WistiaMedia.hashedID` matches the parameter (resulting in a no-op).  `True` otherwise,
     _which does not guarantee success of the asynchronous video load_.
     */
    public func replaceCurrentVideoWithVideoForHashedID(hashedID: String, assetWithSlug slug: String? = nil) -> Bool {
        guard media?.hashedID != hashedID else { return false }
        avPlayer.pause()

        WistiaAPI.mediaInfoForHash(hashedID) { (media) -> () in
            if let m = media {
                self.media = m
                self.readyPlaybackForMedia(m, choosingAssetWithSlug: slug)
            } else {
                self.state = .MediaNotFoundError(badHashedID: hashedID)
            }
        }
        return true
    }

    //MARK: - Controlling Playback

    /// Play the video.  This method is idempotent.
    func play() {
        if avPlayer.rate == 0 {
            avPlayer.play()
            logEvent(.Play)
        }
    }

    /// Pause the video.  This method is idempotent.
    func pause() {
        if avPlayer.rate > 0 {
            avPlayer.pause()
            logEvent(.Pause)
        }
    }

    /// Play the video if it's currently paused.  Pause if it's currently playing.
    func togglePlayPause() {
        if avPlayer.rate > 0 {
            avPlayer.pause()
            logEvent(.Pause)
        } else {
            avPlayer.play()
            logEvent(.Play)
        }
    }

    /**
     Seek to a given time in the current video and be notified when seeking is done.
     
     - Note: It is best practice to pause the video during interactive scrubbing.
     
     - Parameters: 
        - time: The target time to move the playhead.
        - tolerance: How close to the target time must the seek move the playhead.  Smaller tolerances may result in
        slower seeking due to additional required video decoding.
        - completionHandler: The block to invoke when seeking is complete.  This block takes one parameter, `finished`,
        which indicates if the seek operation completed.  `False` indicates another seek request interrupted this one.

    */
    func seekToTime(time:CMTime, tolerance: CMTime = CMTime(seconds: 1, preferredTimescale: 10), completionHandler: ((Bool) -> Void)?){
        self.avPlayer.seekToTime(time, toleranceBefore: tolerance, toleranceAfter: tolerance) { (finished) -> Void in
            if finished {
                self.logEvent(.Seek)
            }
            completionHandler?(finished)
        }
    }

    //MARK: - State Information

    /**
     - Returns: The current time of the currently playing video.
    */
    func currentTime() -> CMTime {
        return avPlayer.currentTime()
    }

    /**
     The current rate of playback.  A value of 0.0 means paused, while 1.0 means playing at natural rate.
     
     See `AVPlayer.rate` for further information.
     */
    var rate:Float {
        get {
            return avPlayer.rate
        }
        set(newRate) {
            avPlayer.rate = newRate
            if newRate == 1.0 {
                logEvent(.Play)
            } else if rate == 0.0 {
                logEvent(.Pause)
            }
        }
    }

    /// - Returns: `True` if the video is currently playing at any rate.
    func isPlaying() -> Bool {
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
        case Initialized

        /// About to examine a `WistiaMedia` and choose a `WistiaAsset` for playback
        case VideoPreLoading

        /// `WistiaAsset` has been chosen and underlying media file will start loading
        case VideoLoading

        /// A `WistiaMedia` could not be found for the given `hashedID`
        case MediaNotFoundError(badHashedID: String)

        /// The `WistiaMedia` or `WistiaAsset` could not be loaded.
        /// This is possibly due to unsatisfiable HLS requirement.  
        /// See description for more information.
        case VideoLoadingError(description:String, problemMedia: WistiaMedia?, problemAsset: WistiaAsset?)

        /// An error occurred during playback.  See description for more information.
        case VideoPlaybackError(description:String)

        /// The video file has completed initial loading and is ready for playback.
        /// This state is only entered once per video loaded.  Player remains in this state while the video
        /// is playing.  Use the delegate for playback state changes.
        case VideoReadyForPlayback
    }

    //MARK: - Displaying Video

    /**
     Create a new `AVPlayerLayer` configured for this instance of `WistiaPlayer`.  This will remove
     the player form any previously feteched `AVPlayerLayer`s.
     
     See `AVPlayerLayer(player:)` for further information.

     - Returns: A new `AVPlayerLayer` to which we can direct our visual output.
     */
    func newPlayerLayer() -> AVPlayerLayer? {
        return AVPlayerLayer(player: avPlayer)
    }

    /**
     Configure a standard `AVPlayerViewController` to use the `AVPlayer` underlying this `WistiaPlayer`.

     For Wistia style UI and controls, see `WistiaPlayerViewController`.

     - Warning: The performance and functionality of a `WistiaPlayer` instance is undefined if the underlying
     `AVPlayer` is manipulated directly outside of `AVPlayerViewController`.
    */
    func configureWithUnderlyingPlayer(vc:AVPlayerViewController) {
        vc.player = self.avPlayer
    }


    //MARK: - -----------Internal-----------

    deinit {
        removePlayerItemObservers(self.avPlayer.currentItem)
        removePlayerObservers(self.avPlayer)
    }

    internal(set) var state:State = .Initialized {
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

    internal var media:WistiaMedia?
    internal var statsCollector:WistiaMediaEventCollector?
    internal let referrer:String

    // The 4K mp4s were not playing well.
    // Keeping max at 1920 seems good on testing thus far.
    // XXX: This should be revisited when we have HLS assets for 360 videos
    internal let SphericalTargetAssetWidth:Int64 = 1920

    //Raw Observeration
    internal var playerItemContext = 1
    internal var playerContext = 2
    internal var periodicTimeObserver:AnyObject?
}

//MARK: - WistiaPlayer.State Equality
/**
 Compare two `WistiaPlayer.State` instances for equality, ignoring associated values.
 
 - Returns: `True` if both states are the same enum case, not matter what is contained in their 
    associated values (if ap)plicable.
 */
public func == (a: WistiaPlayer.State, b: WistiaPlayer.State) -> Bool {
    switch(a, b){
    case (.Initialized, .Initialized): return true
    case (.VideoPreLoading, .VideoPreLoading): return true
    case (.VideoLoading, .VideoLoading): return true
    case (.MediaNotFoundError(_), .MediaNotFoundError(_)): return true
    case (.VideoLoadingError(_, _, _), .VideoLoadingError(_, _, _)): return true
    case (.VideoPlaybackError(_), .VideoPlaybackError(_)): return true
    case (.VideoReadyForPlayback, .VideoReadyForPlayback): return true
    default:
        return false
    }
}