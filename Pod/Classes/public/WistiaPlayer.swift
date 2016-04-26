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

public extension WistiaPlayer {

    //MARK: - Playback

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

    //MARK: - Media

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

    //MARK: lower level

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

//MARK: - WistiaPlayerDelegate
public protocol WistiaPlayerDelegate : class {
    func wistiaPlayer(player:WistiaPlayer, didChangeStateTo newState:WistiaPlayer.State)
    func wistiaPlayer(player:WistiaPlayer, didChangePlaybackRateTo newRate:Float)
    func wistiaPlayer(player:WistiaPlayer, didChangePlaybackProgressTo progress:Float, atCurrentTime currentTime:CMTime, ofDuration:CMTime)
    func wistiaPlayerDidPlayToEndTime(player:WistiaPlayer)
    func wistiaPlayer(player:WistiaPlayer, willLoadVideoForAsset asset:WistiaAsset, fromMedia media:WistiaMedia)
}