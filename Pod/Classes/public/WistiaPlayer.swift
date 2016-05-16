//
//  WistiaPlayer.swift
//  Playback
//
//  Created by Daniel Spinosa on 4/11/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//
//  WistiaPlayer presents a convenient facade in front of AVPlayer.
//
//  Create a WistiaPlayer with the hashed_id of a media, and it will play the best
//  asset for the device.
//
//  Use the WistiaPlayerDelegate as a convenient mechanism to respond to key events
//  in the video playback lifecycle.
//
//  The underlying AVPlayer is not exposed to facilitate the proper collection and reporting
//  of important Wistia statistics.  Common functionality of the AVPLayer is available through
//  public API directly on WistiaPlayer and through the delegate.
//
//  Render the video by presenting the AVPlayerLayer vended by newPlayerLayer()

import AVKit
import AVFoundation

//MARK: WistiaPlayerDelegate

/**
 The delegate of a WistiaPlayer must adopt the WistiaPlayerDelegate protocol.  It will receive
 state related information through the delegaet methods.
 
 Information provided includes high-level state about the WistiaPlayer as well as state of the
 underlying AVPlayer, normally obtained through Key-Value Observation (KVO).
 */
public protocol WistiaPlayerDelegate : class {

    /**
     Informs the delegate that the state of the WistiaPlayer has changed.
     
     - Note: Upon registration of a delegate, this method will be called with the state of
     the WistiaPlayer at the time of registration.
     
     - Parameters:
        - player: The WistiaPlayer that has changed state.
        - newState: The new (and now-current) state of the player.
    */
    func wistiaPlayer(player:WistiaPlayer, didChangeStateTo newState:WistiaPlayer.State)

    /**
     
     */
    func wistiaPlayer(player:WistiaPlayer, didChangePlaybackRateTo newRate:Float)
    func wistiaPlayer(player:WistiaPlayer, didChangePlaybackProgressTo progress:Float, atCurrentTime currentTime:CMTime, ofDuration:CMTime)
    func wistiaPlayerDidPlayToEndTime(player:WistiaPlayer)
    func wistiaPlayer(player:WistiaPlayer, willLoadVideoForAsset asset:WistiaAsset, fromMedia media:WistiaMedia)
}

//MARK: - WistiaPlayer
public final class WistiaPlayer: NSObject {

    //MARK: Initializers

    public init(referrer: String, requireHLS: Bool) {
        self.referrer = referrer
        self.requireHLS = requireHLS
        self.avPlayer = AVPlayer()
        super.init()

        addPlayerObservers(self.avPlayer)
    }


    // Returns a WistiaPlayer that is initialized and asynchronously loading the media for playback.
    // Use the state updates of the delegate or the `state` variable to determine if this WistiaPlayer
    // has been initialized.
    // referrer should be a universal link to the given video.  In the case it can't be, it should be
    // a descriptive string identifying the location (and possibly state) of your app where this video
    // is being played back (ie. "ProductTourViewController" or "SplashViewController.page1(uncoverted_email)")
    // If HLS playback is required (Apple requires HLS for video > 10m in length played over cellular connections),
    // only compatible assets will be played, or player will enter an error state.  Default, and suggested, it true.
    public convenience init(hashedID:String, referrer:String, requireHLS: Bool = true) {
        self.init(referrer:referrer, requireHLS:requireHLS)
        self.replaceCurrentVideoWithVideoForHashedID(hashedID)
    }

    //MARK: Instance Properties

    // This player will disable the iOS idle timer during playback (ie. video rate > 0) and
    // re-enable the idle timer when the video is paused.
    // If you wish to have total control over the idle timer, set this to false.
    // Changing the value has no immediate effect on the idle timer.
    var preventIdleTimerDuringPlayback = true


    //Upon setting delegate, you will immediately receve a state change callback with the current state
    public weak var delegate:WistiaPlayerDelegate? {
        didSet {
            if let d = delegate {
                d.wistiaPlayer(self, didChangeStateTo: self.state)
            }
        }
    }


    public var avPlayer:AVPlayer

    var currentItem:AVPlayerItem? {
        get {
            return avPlayer.currentItem
        }
    }


    //Change this before calling replaceCurrentVideoWithVideoForHashedID to have an effect
    public var requireHLS:Bool

    //MARK: Setting Media

    // Replaces the non-CoreData playback methods, commented out below.
    // Like AVPlayer, if the new media is the same as the currently playing media, this is a noop
    // Returns false on the event of a noop.  True otherwise.
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

    //MARK: Controlling Playback

    //idempotent
    func play() {
        if avPlayer.rate == 0 {
            avPlayer.play()
            logEvent(.Play)
        }
    }

    //idempotent
    func pause() {
        if avPlayer.rate > 0 {
            avPlayer.pause()
            logEvent(.Pause)
        }
    }

    func togglePlayPause() {
        if avPlayer.rate > 0 {
            avPlayer.pause()
            logEvent(.Pause)
        } else {
            avPlayer.play()
            logEvent(.Play)
        }
    }

    func seekToTime(time:CMTime, completionHandler: ((Bool) -> Void)?){
        let tolerance = CMTime(seconds: 1, preferredTimescale: 10)
        self.avPlayer.seekToTime(time, toleranceBefore: tolerance, toleranceAfter: tolerance) { (finished) -> Void in
            if finished {
                self.logEvent(.Seek)
            }
            completionHandler?(finished)
        }
    }

    //MARK: State Information

    func currentTime() -> CMTime {
        return avPlayer.currentTime()
    }

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

    func isPlaying() -> Bool {
        return rate > 0.0
    }

    //WistiaPlayer State Enumeration
    //Register a delegate to get state callback information
    public enum State {
        case Initialized,
        VideoPreLoading,
        VideoLoading,

        MediaNotFoundError(badHashedID: String),
        VideoLoadingError(description:String, problemMedia: WistiaMedia?, problemAsset: WistiaAsset?),
        VideoPlaybackError(description:String),

        //This state is only entered once per video loaded.  Player remains in this state while the video
        //is playing.  Use the delegate for playback state changes.
        VideoReadyForPlayback
    }

    //MARK: Displaying Video

    //Get an new AVPlayerLayer configured for the our AVPlayer.  Will remove the player from any
    //previously fetched AVPlayerLayers
    func newPlayerLayer() -> AVPlayerLayer? {
        return AVPlayerLayer(player: avPlayer)
    }


    //MARK: -----------Internal-----------

    deinit {
        removePlayerItemObservers(self.avPlayer.currentItem)
        removePlayerObservers(self.avPlayer)
    }

    internal(set) var state:State = .Initialized {
        didSet {
            self.delegate?.wistiaPlayer(self, didChangeStateTo: state)
        }
    }

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