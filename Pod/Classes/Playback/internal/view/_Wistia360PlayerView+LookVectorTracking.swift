//
//  _Wistia360PlayerView+LookVectorTracking.swift
//  WistiaKit internal
//
//  Created by Daniel Spinosa on 1/15/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

//Until we support 360 on TV, just killing this entire thing
#if os(iOS)

import UIKit
import SceneKit

/*
 * The following algo is slightly different from web.  Because we have DeviceMotion, our heading/pitch change
 * too frequently to run an algo on every change.  So we're using a timer.  But the important part is that the
 * data record the enter and exit events for the ~5°x~5° grid.
 *
 * ALGO:
 *  1) Start a 200ms repeating timer
 *  2) Check the heading/pitch each time the timer fires
 *  2a)   If heading/pitch stayed within 5x5, log the (enter) event and set “look_settled = true”
 *        NB: Not logging each 200ms, just the first time the looks settles
 *  2b)   Else (heading/pitch left the 5x5) if “look_settled == true”, log the (exit) event and set “look_settled = false"
 */
internal extension Wistia360PlayerView {
    internal typealias LatitudeLongitude = (latitude: Float, longitude: Float)
    internal typealias HeadingPitch = (heading: Float, pitch: Float)

    internal func startLookVectorTracking() {
        if lookVectorStatsTimer == nil {
            lookVectorStatsTimer = Timer.scheduledTimer(timeInterval: LookVectorUnchangedTemporalRequirement, target: self, selector: #selector(Wistia360PlayerView.checkLookVector), userInfo: nil, repeats: true)
        }
    }

    internal func stopLookVectorTracking() {
        lookVectorStatsTimer?.invalidate()
        lookVectorStatsTimer = nil
    }

    //Assumes time between calls is the required time look vector needs to remain unchanged
    @objc internal func checkLookVector() {
        guard let currentTime = wPlayer?.currentTime().seconds else { return }
        let currentLookVector = correctedHeadingPitchFrom(latitudeLongitudeOfPoint(lookVectorIntersectionWithSphereNode(), onSphereWithRadius: Float(SphereRadius)))
        let timeHeadingPitchString = String(format: "%f,%.0f,%.0f", currentTime, currentLookVector.heading, currentLookVector.pitch)

        //use smallest distance between two angles that are < 180 degrees apart
        let headingDelta = min(360 - abs(lastLookVector.heading - currentLookVector.heading), abs(lastLookVector.heading - currentLookVector.heading))
        let pitchDelta = min(306 - abs(lastLookVector.pitch - currentLookVector.pitch), abs(lastLookVector.pitch - currentLookVector.pitch))

        let lookStayedWithinGrid = (headingDelta <= LookVectorUnchangedSpatialRequirement.heading && pitchDelta <= LookVectorUnchangedSpatialRequirement.pitch)

        if lookStayedWithinGrid {
            if !lookVectorIsSettled && wPlayer != nil && /*isPlaying*/ wPlayer!.rate > 0.0 {
                //The look has settled (ie. entered a grid square) for a sufficient period of time
                wPlayer?.log(.lookVector, withValue: timeHeadingPitchString)
                lookVectorIsSettled = true
            } else {
                //we're only logging the enter/exit, not if look stayed within grid after it initially settled
            }
        } else if lookVectorIsSettled {
            //The look has exited a grid square it was previously settled in
            wPlayer?.log(.lookVector, withValue: timeHeadingPitchString)
            lookVectorIsSettled = false
        }

        lastLookVector = currentLookVector
    }

    //the Look Vector extends from the middle of the view out into 3D space.  Return where that vector intersects the sphere.
    fileprivate func lookVectorIntersectionWithSphereNode() -> SCNVector3 {
        let middle = CGPoint(x: sceneView.bounds.size.width/2.0, y: sceneView.bounds.size.height/2.0)
        let hits = sceneView.hitTest(middle, options: [SCNHitTestOption.firstFoundOnly: NSNumber(value: true), SCNHitTestOption.backFaceCulling: NSNumber(value: true)])
        return hits.first!.localCoordinates
    }

    //Convert from x,y,z coordinates of sphere to latitude and longitude
    fileprivate func latitudeLongitudeOfPoint(_ point:SCNVector3, onSphereWithRadius radius:Float) -> LatitudeLongitude {
        let latitude = acos(Float(point.y) / radius)
        let longitude = atan2(Float(point.x), Float(point.z))
        return (latitude, longitude)
    }

    //Convert from latitude and longitude to the heading and pitch wanted for back end analytics
    fileprivate func correctedHeadingPitchFrom(_ latlon: LatitudeLongitude) -> HeadingPitch {
        let heading = latlon.longitude * 90.0 / Float.pi/2
        let pitch = latlon.latitude * 180.0 / Float.pi/2 - 180.0
        return (heading, pitch)
    }
    
}

#endif //os(iOS)
