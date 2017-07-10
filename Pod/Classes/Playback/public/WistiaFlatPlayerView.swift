//
//  WistiaFlatPlayerView.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 11/15/15.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//
//  A View backed by an AVPlayerLayer.
//
//  Set the wistiaPlayer and this view will pass it's AVPlayer through to the backing AVPlayerLayer.
//

import UIKit
import AVKit
import AVFoundation

public class WistiaFlatPlayerView: UIView {
    private var detachedAVPlayer: AVPlayer?

    override public class var layerClass: AnyClass {
        get {
            return AVPlayerLayer.self
        }
    }

    public var wistiaPlayer:WistiaPlayer? {
        didSet {
            (self.layer as! AVPlayerLayer).player = wistiaPlayer?.avPlayer
        }
    }
    
    public func prepareForBackgroundPlayback() {
        let playerLayer = layer as! AVPlayerLayer
        detachedAVPlayer = playerLayer.player
        playerLayer.player = nil
    }
    
    public func returnToForegroundPlayback() {
        (layer as! AVPlayerLayer).player = detachedAVPlayer
        detachedAVPlayer = nil
    }

}
