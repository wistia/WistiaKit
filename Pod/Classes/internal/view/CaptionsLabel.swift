//
//  CaptionsLabel.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 6/24/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//
//  A label formatted to display captions atop a video.
//  Crafted for use with WistiaCaptionsRenderer.

import UIKit

class CaptionsLabel: UILabel {

    @IBInspectable var leftEdgeInset: CGFloat = 0 {
        didSet {
            edgeInsets = UIEdgeInsets(top: edgeInsets.top, left: leftEdgeInset, bottom: edgeInsets.bottom, right: edgeInsets.right)
        }
    }

    @IBInspectable var rightEdgeInset: CGFloat = 0 {
        didSet {
            edgeInsets = UIEdgeInsets(top: edgeInsets.top, left: edgeInsets.left, bottom: edgeInsets.bottom, right: rightEdgeInset)
        }
    }

    @IBInspectable var topEdgeInset: CGFloat = 0 {
        didSet {
            edgeInsets = UIEdgeInsets(top: topEdgeInset, left: edgeInsets.left, bottom: edgeInsets.bottom, right: edgeInsets.right)
        }
    }

    @IBInspectable var bottomEdgeInset: CGFloat = 0 {
        didSet {
            edgeInsets = UIEdgeInsets(top: edgeInsets.top, left: edgeInsets.left, bottom: bottomEdgeInset, right: edgeInsets.right)
        }
    }

    var edgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    // Return a drawing rectange that is `edgeInsets` larger than the bounds needed for the text alone.
    // We can then draw within that margin later.
    override func textRectForBounds(bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        var rect = UIEdgeInsetsInsetRect(bounds, edgeInsets)
        rect = super.textRectForBounds(rect, limitedToNumberOfLines: numberOfLines)
        let inverseEdgeInsets = UIEdgeInsetsMake(-edgeInsets.top, -edgeInsets.left, -edgeInsets.bottom, -edgeInsets.right)
        return UIEdgeInsetsInsetRect(rect, inverseEdgeInsets)
    }

    // The given `rect` is `edgeInsets` larger than needed.  Just draw `edgeInsets` within it and we have our margin!
    override func drawTextInRect(rect: CGRect) {
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, edgeInsets))
    }

}
