//
//  WistiaFlatPlayerView.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 11/15/15.
//  Copyright © 2015 Wistia, Inc. All rights reserved.
//
//  A slightly smarter View for AVPlayerLayers
//
//  Set the playerLayer and it will be sized exactly as the normal layer.
//  Now you can live in the View world instead of the lower level nitty gritty.
//
//  *** Important: do not set the frame, bounds, position, or anchorPoint of playerLayer
//  after it is set.  Result is undefined.

import UIKit
import AVKit
import AVFoundation

public class WistiaFlatPlayerView: UIView {

    public var playerLayer:AVPlayerLayer? {
        didSet(oldLayer) {
            oldLayer?.removeFromSuperlayer()

            if let newLayer = playerLayer {
                //New layers have default size (0, 0) and position (0, 0)
                //where position is relative to default center anchor: (0.5, 0.5).
                //We don't know what was handed to us.

                //For AVPlayerLayer to pefectly overlay its superlayer (ie. our layer),
                //and thereby match the this view's frame, we need to do a few things...

                // 1) Set anchor to top-left and position to (0, 0) to keep the AVPlayerLayer
                // unmoved relative it's superlayer (ie. this view's layer)
                newLayer.position = CGPoint(x: 0, y: 0)
                newLayer.anchorPoint = CGPoint(x: 0, y: 0)

                // 2) Change AVPlayerLayer's bounds to this view's layer's bounds
                // NB: Our layer will continue to be sized by normal layout mechanisms (see
                // layoutSubviews where we keep the bounds synchronized)
                newLayer.bounds = self.layer.bounds

                // 3) Add as a sublayer (of equal size at the same screen position)
                layer.addSublayer(newLayer)
            }
        }
    }

    override public func layoutSubviews() {
        //Run normal layout mechanisms (ie. iOS solves constraints and updates frames)
        super.layoutSubviews()

        // Keep AVPlayerLayer sized correctly (remains relatively unmoved at (0,0))
        playerLayer?.bounds = layer.bounds
    }

}
