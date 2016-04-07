//
//  Wistia360PlayerView+LookVectorTracking.swift
//  Playback
//
//  Created by Daniel Spinosa on 1/15/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import UIKit
import SceneKit

extension Wistia360PlayerView {
    typealias LatitudeLongitude = (latitude: Float, longitude: Float)
    typealias HeadingPitch = (heading: Float, pitch: Float)

    internal func startLookVectorTracking() {
        if lookVectorStatsTimer == nil {
            lookVectorStatsTimer = NSTimer.scheduledTimerWithTimeInterval(LookVectorUnchangedTemporalRequirement, target: self, selector: #selector(Wistia360PlayerView.optionallyLogLookVector), userInfo: nil, repeats: true)
        }
    }

    internal func stopLookVectorTracking() {
        lookVectorStatsTimer?.invalidate()
        lookVectorStatsTimer = nil
    }

    //Assumes time between calls is the required time look vector needs to remain unchanged
    internal func optionallyLogLookVector() {
        let currentLookVector = correctedHeadingPitchFrom(latitudeLongitudeOfPoint(lookVectorIntersectionWithSphereNode(), onSphereWithRadius: Float(SphereRadius)))

        let headingDelta = abs(lastLookVector.heading - currentLookVector.heading)
        let pitchDelta = abs(lastLookVector.pitch - currentLookVector.pitch)

        //Log if LookVector remained in the relatively same spot for a sufficient period of time
        if headingDelta <= LookVectorUnchangedSpatialRequirement.heading && pitchDelta <= LookVectorUnchangedSpatialRequirement.pitch {
            wPlayer?.logEvent(.LookVector, value: "\(currentLookVector.heading)),\(currentLookVector.pitch)")
        }

        lastLookVector = currentLookVector
    }

    //the Look Vector extends from the middle of the view out into 3D space.  Return where that vector intersects the sphere.
    private func lookVectorIntersectionWithSphereNode() -> SCNVector3 {
        let middle = CGPointMake(sceneView.bounds.size.width/2.0, sceneView.bounds.size.height/2.0)
        let hits = sceneView.hitTest(middle, options: [SCNHitTestFirstFoundOnlyKey: NSNumber(bool: true), SCNHitTestBackFaceCullingKey: NSNumber(bool: true)])
        return hits.first!.localCoordinates
    }

    //Convert from x,y,z coordinates of sphere to latitude and longitude
    private func latitudeLongitudeOfPoint(point:SCNVector3, onSphereWithRadius radius:Float) -> LatitudeLongitude {
        let latitude = acos(Float(point.y) / radius)
        let longitude = atan2(Float(point.x), Float(point.z))
        return (latitude, longitude)
    }

    //Convert from latitude and longitude to the heading and pitch wanted for back end analytics
    private func correctedHeadingPitchFrom(latlon: LatitudeLongitude) -> HeadingPitch {
        let heading = latlon.longitude * 90.0 / Float(M_PI_2)
        let pitch = (latlon.latitude * 180.0 / Float(M_PI_2)) - 180.0
        return (heading, pitch)
    }

}