//
//  WistiaPlayer_internal.swift
//  WistiaKit
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

internal extension WistiaPlayer {

    //MARK: - Private Helpers

    internal func readyPlaybackForMedia(media: WistiaMedia, choosingAssetWithSlug slug: String?) {
        self.media = media
        self.state = .VideoPreLoading

        guard media.status != .Failed else {
            self.state = .VideoLoadingError(description: "Media \(media.hashedID) failed processing", problemMedia: media, problemAsset: nil)
            return
        }

        guard media.status != .Queued else {
            self.state = .VideoLoadingError(description: "Media \(media.hashedID) has not started processing", problemMedia: media, problemAsset: nil)
            return
        }

        //assuming playback on local device, target asset width is the largest dimension of device
        let targetAssetWidth = media.spherical ? SphericalTargetAssetWidth : Int64(max(UIScreen.mainScreen().nativeBounds.width, UIScreen.mainScreen().nativeBounds.height))

        do {
            let url = try bestPlaybackURLForMedia(media, assetWithSlug: slug, requireHLS: self.requireHLS, targetWidth: targetAssetWidth)
            //-- Out with the old (if applicable)
            removePlayerItemObservers(avPlayer.currentItem)

            //-- In with the new
            self.state = .VideoLoading
            statsCollector = WistiaStatsManager.sharedInstance.newEventCollectorForMedia(media, referrer: self.referrer)

            let avAsset = AVURLAsset(URL: url)
            let avPlayerItem = AVPlayerItem(asset: avAsset)
            addPlayerItemObservers(avPlayerItem)
            avPlayer.replaceCurrentItemWithPlayerItem(avPlayerItem)
        } catch URLDeterminationError.NoAsset {
            self.state = .VideoLoadingError(description: "Media \(media.hashedID) has no assets compatible with this player's configuration.", problemMedia: media, problemAsset: nil)
        } catch URLDeterminationError.NoHLSAsset {
            self.state = .VideoLoadingError(description: "Media \(media.hashedID) has no HLS assets compatible with this WistiaPlayer, configured to require HLS for playback.", problemMedia: media, problemAsset: nil)
        } catch URLDeterminationError.AssetNotReady(let asset) {
            self.state = .VideoLoadingError(description: "Asset with slug \(asset.slug), for media \(media.hashedID), is not ready.", problemMedia: media, problemAsset: asset)
        } catch {
            self.state = .VideoLoadingError(description: "Something unexpected happened looking for an asset to play for media \(media.hashedID).", problemMedia: media, problemAsset: nil)
        }
    }

    //Web makes decisions in a more complicated environment:
    //https://github.com/wistia/wistia/blob/master/app/assets/javascripts/external/E-v1/_judge_judy.coffee
    //
    //We just need HLS (if required), otherwise mp4.  If there are options, we pick the best sized.
    internal func bestPlaybackURLForMedia(media:WistiaMedia, assetWithSlug assetSlug: String?, requireHLS: Bool, targetWidth: Int64) throws -> NSURL {
        //If a particular asset is requested using the slug, that overrides all other configuration
        if let slug = assetSlug {
            if let assetMatchingSlug = (media.assets.filter { $0.slug == slug }).first {
                guard assetMatchingSlug.status == .Ready else { throw URLDeterminationError.AssetNotReady(asset: assetMatchingSlug) }
                delegate?.wistiaPlayer(self, willLoadVideoForAsset: assetMatchingSlug, fromMedia: media)
                return assetMatchingSlug.url
            } else {
                throw URLDeterminationError.NoAsset
            }
        }

        //Preffered playback of HLS assets, which come in m3u8 containers
        let preferredAssets = media.assets.filter { $0.container == "m3u8" }
        if let asset = largestAssetIn(preferredAssets, withoutGoingUnder: targetWidth) {
            guard asset.status == .Ready else { throw URLDeterminationError.AssetNotReady(asset: asset) }
            delegate?.wistiaPlayer(self, willLoadVideoForAsset: asset, fromMedia: media)
            return asset.url
        } else if requireHLS {
            throw URLDeterminationError.NoHLSAsset
        }

        // We can also playback assets in the mp4 container.
        let playableAssets = media.assets.filter { $0.container == "mp4" }
        if let asset = largestAssetIn(playableAssets, withoutGoingUnder: targetWidth) {
            guard asset.status == .Ready else { throw URLDeterminationError.AssetNotReady(asset: asset) }
            delegate?.wistiaPlayer(self, willLoadVideoForAsset: asset, fromMedia: media)
            return asset.url
        } else {
            throw URLDeterminationError.NoAsset
        }
    }

    internal enum URLDeterminationError : ErrorType {
        case NoAsset
        case NoHLSAsset
        case AssetNotReady(asset:WistiaAsset)
    }

    //NB: May go under in size if there are no assets at least as large as the targetWidth
    internal func largestAssetIn(assets:[WistiaAsset], withoutGoingUnder targetWidth:Int64) -> WistiaAsset? {
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

    internal func playerItem(playerItem:AVPlayerItem, statusWas oldStatus:AVPlayerStatus?, changedTo newStatus:AVPlayerStatus){
        switch newStatus {
        case .Failed:
            self.state = .VideoPlaybackError(description: "Player Item Failed")
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

    internal func player(player:AVPlayer, rateChangedTo rate:Float){
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.delegate?.wistiaPlayer(self, didChangePlaybackRateTo: rate)
        }
        if preventIdleTimerDuringPlayback {
            UIApplication.sharedApplication().idleTimerDisabled = (rate > 0.0)
        }
        logEvent(.PlaybackRateChange, value: String(format:"%f", rate))
    }

    internal func onPlayerTimeUpdate(time:CMTime) {
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

    internal func addPlayerItemObservers(playerItem:AVPlayerItem) {
        playerItem.addObserver(self, forKeyPath: "status", options: [.Old, .New], context: &playerItemContext)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WistiaPlayer.playerItemPlayedToEnd(_:)), name: AVPlayerItemDidPlayToEndTimeNotification, object: playerItem)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WistiaPlayer.playerItemFailedToPlayToEnd(_:)), name: AVPlayerItemFailedToPlayToEndTimeNotification, object: playerItem)
    }

    internal func removePlayerItemObservers(playerItem:AVPlayerItem?){
        playerItem?.removeObserver(self, forKeyPath: "status", context: &playerItemContext)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: playerItem)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemFailedToPlayToEndTimeNotification, object: playerItem)
    }

    internal func addPlayerObservers(player:AVPlayer) {
        player.addObserver(self, forKeyPath: "rate", options: .New, context: &playerContext)
        //observe time updates every 0.1 seconds
        periodicTimeObserver = player.addPeriodicTimeObserverForInterval(CMTime(seconds: 0.1, preferredTimescale: 10), queue: nil, usingBlock: onPlayerTimeUpdate)
    }

    internal func removePlayerObservers(player:AVPlayer?) {
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

}

