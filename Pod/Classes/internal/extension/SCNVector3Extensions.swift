//
//  SCNVector3Extensions.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 2/24/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import Foundation
import SceneKit

extension SCNVector3
{
    /**
     * Returns the length (magnitude) of the vector described by the SCNVector3
     */
    func wk_length() -> Float {
        return sqrtf(x*x + y*y + z*z)
    }

    /**
     * Normalizes the vector described by the SCNVector3 to length 1.0 and returns
     * the result as a new SCNVector3.
     */
    func wk_normalized() -> SCNVector3 {
        return self / wk_length()
    }

    /**
     * Normalizes the vector described by the SCNVector3 to length 1.0.
     */
    mutating func wk_normalize() -> SCNVector3 {
        self = wk_normalized()
        return self
    }

    /**
     * Calculates the cross product between two SCNVector3.
     */
    func wk_cross(_ vector: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(y * vector.z - z * vector.y, z * vector.x - x * vector.z, x * vector.y - y * vector.x)
    }
}

/**
 * Divides the x, y and z fields of a SCNVector3 by the same scalar value and
 * returns the result as a new SCNVector3.
 */
func / (vector: SCNVector3, scalar: Float) -> SCNVector3 {
    return SCNVector3Make(vector.x / scalar, vector.y / scalar, vector.z / scalar)
}
