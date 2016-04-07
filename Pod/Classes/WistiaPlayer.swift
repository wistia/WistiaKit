//
//  WistiaPlayer.swift
//  Playback
//
//  Created by Daniel Spinosa on 1/7/16.
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

import UIKit
import AVKit
import AVFoundation

public final class WistiaPlayer: NSObject {

    //Upon setting delegate, you will immediately receve a state change callback with the current state
    weak var delegate:WistiaPlayerDelegate? {
        didSet {
            if let d = delegate {
                d.wistiaPlayer(self, didChangeStateTo: self.state)
            }
        }
    }
    private(set) var state:State = .Initialized {
        didSet {
            self.delegate?.wistiaPlayer(self, didChangeStateTo: state)
        }
    }

    internal var avPlayer:AVPlayer
    internal var media:WistiaMedia?
    private var statsCollector:WistiaMediaEventCollector?
    private let referrer:String

    //Change this before calling replaceCurrentVideoWithVideoForHashedID to have an effect
    var requireHLS:Bool

    // The 4K mp4s were not playing well.  
    // Keeping max at 1920 seems good on testing thus far.
    // XXX: This should be revisited when we have HLS assets for 360 videos
    private let SphericalTargetAssetWidth:Int64 = 1920

    // Returns a WistiaPlayer that is initialized and asynchronously loading the media for playback.
    // Use the state updates of the delegate or the `state` variable to determine if this WistiaPlayer
    // has been initialized.
    // referrer should be a universal link to the given video.  In the case it can't be, it should be 
    // a descriptive string identifying the location (and possibly state) of your app where this video
    // is being played back (ie. "ProductTourViewController" or "SplashViewController.page1(uncoverted_email)")
    // If HLS playback is required (Apple requires HLS for video > 10m in length played over cellular connections),
    // only compatible assets will be played, or player will enter an error state.  Default, and suggested, it true.
    convenience init(hashedID:String, referrer:String, requireHLS: Bool = true) {
        self.init(referrer:referrer, requireHLS:requireHLS)
        self.replaceCurrentVideoWithVideoForHashedID(hashedID)
    }

    // This player will disable the idle timer during playback (ie. video rate > 0) and
    // re-enable the idle timer when the video is paused.
    // If you wish to have total control over the idle timer, set this to false.
    // Changing the value has no immediate effect on the idle timer.
    var preventIdleTimerDuringPlayback = true

    init(referrer: String, requireHLS: Bool) {
        self.referrer = referrer
        self.requireHLS = requireHLS
        self.avPlayer = AVPlayer()
        super.init()

        addPlayerObservers(self.avPlayer)
    }

    deinit {
        removePlayerItemObservers(self.avPlayer.currentItem)
        removePlayerObservers(self.avPlayer)
    }

    //MARK: - AVPlayer API facade

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

    //Get an new AVPlayerLayer configured for the our AVPlayer.  Will remove the player from any
    //previously fetched AVPlayerLayers
    func newPlayerLayer() -> AVPlayerLayer? {
        return AVPlayerLayer(player: avPlayer)
    }

    var currentItem:AVPlayerItem? {
        get {
            return avPlayer.currentItem
        }
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

    func currentTime() -> CMTime {
        return avPlayer.currentTime()
    }

    // Replaces the non-CoreData playback methods, commented out below.
    // Like AVPlayer, if the new media is the same as the currently playing media, this is a noop
    // Returns false on the event of a noop.  True otherwise.
    func replaceCurrentVideoWithVideoForMedia(media:WistiaMedia, forcingAsset asset:WistiaAsset? = nil) -> Bool {
        guard media != self.media else { return false }
        pause()

        let slug:String? = (asset != nil ? asset!.slug : nil)
        self.readyPlaybackForMedia(media, choosingAssetWithSlug: slug)
        return true
    }

    //Pauses playback of the current video, loads the media for the given hashedID asynchronously.
    //If a slug is included, will choose the asset matching that slug, overriding everything.
    // Like AVPlayer, if the new media is the same as the currently playing media, this is a noop
    // Returns false on the event of a noop.  True otherwise.
    internal func replaceCurrentVideoWithVideoForHashedID(hashedID: String, assetWithSlug slug: String? = nil) -> Bool {
        guard media?.hashedID != hashedID else { return false }
        avPlayer.pause()

        WistiaAPI.mediaInfoForHash(hashedID) { (media) -> () in
            if let m = media {
                self.media = m
                self.readyPlaybackForMedia(m, choosingAssetWithSlug: slug)
            } else {
                self.state = .VideoError(description: "Could not find media with hashed ID \(hashedID)")
            }
        }
        return true
    }

    //MARK: - Private Helpers

    private func readyPlaybackForMedia(media: WistiaMedia, choosingAssetWithSlug slug: String?) {
        self.media = media
        self.state = .VideoPreLoading

        //assuming playback on local device, target asset width is the largest dimension of device
        let targetAssetWidth = media.spherical ? SphericalTargetAssetWidth : Int64(max(UIScreen.mainScreen().nativeBounds.width, UIScreen.mainScreen().nativeBounds.height))

        if let url = bestPlaybackURLForMedia(media, assetWithSlug: slug, requireHLS: self.requireHLS, targetWidth: targetAssetWidth) {
            //-- Out with the old (if applicable)
            removePlayerItemObservers(avPlayer.currentItem)

            //-- In with the new
            self.state = .VideoLoading
            statsCollector = WistiaStatsManager.sharedInstance.newEventCollectorForMedia(media, referrer: self.referrer)

            let avAsset = AVURLAsset(URL: url)
            let avPlayerItem = AVPlayerItem(asset: avAsset)
            addPlayerItemObservers(avPlayerItem)
            avPlayer.replaceCurrentItemWithPlayerItem(avPlayerItem)
        } else {
            self.state = .VideoError(description: "Media \(media.hashedID) has no assets compatible with this player's configuration")
        }
    }

    //Web makes decisions in a more complicated environment:
    //https://github.com/wistia/wistia/blob/master/app/assets/javascripts/external/E-v1/_judge_judy.coffee
    //
    //We just need HLS (if required), otherwise mp4.  If there are options, we pick the best sized.
    private func bestPlaybackURLForMedia(media:WistiaMedia, assetWithSlug assetSlug: String?, requireHLS: Bool, targetWidth: Int64) -> NSURL? {
        //If a particular asset is requested using the slug, that overrides all other configuration
        if let slug = assetSlug {
            if let assetMatchingSlug = (media.unnamedAssets.filter { $0.slug == slug }).first {
                delegate?.wistiaPlayer(self, willLoadVideoForAsset: assetMatchingSlug, fromMedia: media)
                return assetMatchingSlug.url
            } else {
                return nil
            }
        }

        //Preffered playback of HLS assets, which come in m3u8 containers
        let preferredAssets = media.unnamedAssets.filter { $0.container == "m3u8" }
        if let asset = largestAssetIn(preferredAssets, withoutGoingUnder: targetWidth) {
            delegate?.wistiaPlayer(self, willLoadVideoForAsset: asset, fromMedia: media)
            return asset.url
        } else if requireHLS {
            return nil
        }

        // We can also playback assets in the mp4 container.
        let playableAssets = media.unnamedAssets.filter { $0.container == "mp4" }
        if let asset = largestAssetIn(playableAssets, withoutGoingUnder: targetWidth) {
            delegate?.wistiaPlayer(self, willLoadVideoForAsset: asset, fromMedia: media)
            return asset.url
        } else {
            return nil
        }
    }

    //NB: May go under in size if there are no assets at least as large as the targetWidth
    private func largestAssetIn(assets:[WistiaAsset], withoutGoingUnder targetWidth:Int64) -> WistiaAsset? {
        let sortedAssets = assets.sort { $0.width > $1.width }
        var largestWithoutGoingUnder:WistiaAsset? =  sortedAssets.first

        for asset in sortedAssets {
            if asset.width >= targetWidth {
                largestWithoutGoingUnder = asset
            }
        }

        return largestWithoutGoingUnder
    }

    internal func logEvent(event:WistiaMediaEventCollector.EventType, value:String? = nil) {
        if let val = value {
            statsCollector?.logEvent(event, value: val)
        } else {
            statsCollector?.logEvent(event, value: avPlayer.currentTime().seconds.description)
        }
    }

    //MARK:- Value add observation

    private func playerItem(playerItem:AVPlayerItem, statusWas oldStatus:AVPlayerStatus?, changedTo newStatus:AVPlayerStatus){
        switch newStatus {
        case .Failed:
            self.state = .VideoError(description: "Player Item Failed")
        case .Unknown:
            break
        case .ReadyToPlay:
            //Unkown means "hasn't tried to load media"
            if oldStatus == .Unknown {
                self.state = .VideoReadyForPlayback
                logEvent(.Initialized)
            }
        }
    }

    private func player(player:AVPlayer, rateChangedTo rate:Float){
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.delegate?.wistiaPlayer(self, didChangePlaybackRateTo: rate)
        }
        if preventIdleTimerDuringPlayback {
            UIApplication.sharedApplication().idleTimerDisabled = (rate > 0.0)
        }
        logEvent(.PlaybackRateChange, value: String(format:"%f", rate))
    }

    private func onPlayerTimeUpdate(time:CMTime) {
        //time and duration must both be valid and definite
        guard (time.flags.contains(.Valid)) else { return }
        guard let duration = avPlayer.currentItem?.duration where duration.flags.contains(.Valid) else { return }
        guard (!time.flags.contains(.Indefinite) && !duration.flags.contains(.Indefinite)) else { return }

        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.delegate?.wistiaPlayer(self, didChangePlaybackProgressTo: Float(time.seconds / duration.seconds), atCurrentTime: time, ofDuration: duration)
        }

        //reduced resolution and jitter implemented in the stats collector
        logEvent(.Update)
    }

    internal func playerItemPlayedToEnd(notification:NSNotification) {
        dispatch_async(dispatch_get_main_queue()) { 
            self.delegate?.wistiaPlayerDidPlayToEndTime(self)
        }
        logEvent(.End)
    }

    internal func playerItemFailedToPlayToEnd(notification:NSNotification) {
        //ignoring for now
    }

    //MARK: - Raw Observeration

    private var playerItemContext = 1
    private var playerContext = 2
    private var periodicTimeObserver:AnyObject?

    private func addPlayerItemObservers(playerItem:AVPlayerItem) {
        playerItem.addObserver(self, forKeyPath: "status", options: [.Old, .New], context: &playerItemContext)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WistiaPlayer.playerItemPlayedToEnd(_:)), name: AVPlayerItemDidPlayToEndTimeNotification, object: playerItem)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WistiaPlayer.playerItemFailedToPlayToEnd(_:)), name: AVPlayerItemFailedToPlayToEndTimeNotification, object: playerItem)
    }

    private func removePlayerItemObservers(playerItem:AVPlayerItem?){
        playerItem?.removeObserver(self, forKeyPath: "status", context: &playerItemContext)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: playerItem)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemFailedToPlayToEndTimeNotification, object: playerItem)
    }

    private func addPlayerObservers(player:AVPlayer) {
        player.addObserver(self, forKeyPath: "rate", options: .New, context: &playerContext)
        //observe time updates every 0.1 seconds
        periodicTimeObserver = player.addPeriodicTimeObserverForInterval(CMTime(seconds: 0.1, preferredTimescale: 10), queue: nil, usingBlock: onPlayerTimeUpdate)
    }

    private func removePlayerObservers(player:AVPlayer?) {
        if let player = player {
            player.removeObserver(self, forKeyPath: "rate", context: &playerContext)
            player.removeTimeObserver(periodicTimeObserver!)
        }
    }

    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &playerItemContext {
            if let newValue = change?[NSKeyValueChangeNewKey] as? Int, newStatus = AVPlayerStatus(rawValue: newValue), playerItem = object as? AVPlayerItem where keyPath == "status" {
                let oldStatus:AVPlayerStatus?
                if let oldValue = change?[NSKeyValueChangeOldKey] as? Int {
                    oldStatus = AVPlayerStatus(rawValue: oldValue)
                } else {
                    oldStatus = nil
                }
                self.playerItem(playerItem, statusWas: oldStatus, changedTo: newStatus)
            } else {
                assertionFailure("Bad observation configuration on playerItem")
            }

        } else if context == &playerContext {
            if let newRate = change?[NSKeyValueChangeNewKey] as? Float
                where keyPath == "rate" {
                    self.player(avPlayer, rateChangedTo:newRate)
            } else {
                assertionFailure("Bad observation configuration on player")
            }

        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }

    //MARK: - WistiaPlayer State Enumeration
    public enum State {
        case Initialized,
        VideoPreLoading,
        VideoLoading,
        VideoError(description:String),
        //This state is only entered once per video loaded.  Player remains in this state while the video
        //is playing.  Use the delegate for playback state changes.
        VideoReadyForPlayback
    }
}

public func == (a: WistiaPlayer.State, b: WistiaPlayer.State) -> Bool {
    switch(a, b){
    case (.Initialized, .Initialized): return true
    case (.VideoPreLoading, .VideoPreLoading): return true
    case (.VideoLoading, .VideoLoading): return true
    case (.VideoError(_), .VideoError(_)): return true
    case (.VideoReadyForPlayback, .VideoReadyForPlayback): return true
    default:
        return false
    }
}

//MARK: - WistiaPlayerDelegate
public protocol WistiaPlayerDelegate : class {
    func wistiaPlayer(player:WistiaPlayer, didChangeStateTo newState:WistiaPlayer.State)
    func wistiaPlayer(player:WistiaPlayer, didChangePlaybackRateTo newRate:Float)
    func wistiaPlayer(player:WistiaPlayer, didChangePlaybackProgressTo progress:Float, atCurrentTime currentTime:CMTime, ofDuration:CMTime)
    func wistiaPlayerDidPlayToEndTime(player:WistiaPlayer)
    func wistiaPlayer(player:WistiaPlayer, willLoadVideoForAsset asset:WistiaAsset, fromMedia media:WistiaMedia)
}