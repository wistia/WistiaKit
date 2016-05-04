//
//  Wistia360PlayerView.swift
//  Playback
//
//  Created by Daniel Spinosa on 1/15/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

//Until we support 360 on TV, just killing this entire thing
#if os(iOS)

import UIKit
import SceneKit
import SpriteKit
import AVFoundation
import CoreMotion

/***** SELECTED LEARNINGS ****

 - SKVideoNode documentation says we can use AVPlayer to control playback.  This is a lie (probably due to a bug).  You 
   must use the nodes .play() and .pause() methods.  To check if you're currently playing, use the player's (not nodes!) .rate()

 - The Metal renderer doesn't update texture when scene isn't moving, causing video to look still while audio continues
 - FIX: Set Open GL renderer in Interface Builder
 - TODO: Investigate Metal renderer options
 - SKVideoNode mimics AVPlayerLayer w/r/t anchor (so video is centered on node's position)
 - FIX: Change the anchor to (0,0) to get video to fill entire SpriteKit scene
 - Size of video texture (ie. SKScene size) should match video itself to reduce up/down sampling
 - Aspect ratio doesn't matter too much b/c source video is captured spherically, same as it will be rendered

 Core Motion
 Assumes a default reference frame were the device is laying flat on its back where:
 ...pitch is rotation around the X-axis (goes thu device left to right), increasing as the device tilts toward you
 ...roll is rotation around the Y-axis (goes thru device bottom to top), increasing as device tilts to the right
 ...yaw is rotation around the Z-axis (goes thru back of device to top), increasing counter-clockwise

 SceneKit
 x is left to right (like normal) - pitch is rotation about x-axis
 y is bottom to top (like normal) - yaw, aka heading, is rotation about y-axis
 z is back to front (camera faces -z) - roll is rotation about z-axis


 *********************************/

internal class Wistia360PlayerView: UIView {

    //SceneKit - 3D stuff
    @IBOutlet internal var sceneView: SCNView!
    private let scene = SCNScene()
    private let camera = SCNCamera()
    private let cameraNode = SCNNode()
    private let cameraHolderNode = SCNNode()
    internal let SphereRadius = CGFloat(30.0)
    private var sphereNode = SCNNode()

    private let defaultCameraFov = 60.0 //degrees
    private let cameraFovBounds = (min:10.0, max:90.0)

    private var pinchStartScale:Double = 1.0
    private var initialCameraXFov:Double = 0.0

    //SpriteKit - 2D stuff
    private var videoScene:SKScene?
    private var videoNode:SKVideoNode?

    //Video
    internal var wPlayer:WistiaPlayer? {
        didSet(oldPlayer){
            if wPlayer != nil {
                //Optimization: in future, reuse the scene and just recreate videoNode with new player
                buildScene(
                    videoSize: CGSize(width: 1280, height: 720),
                    sphereRadius: SphereRadius)
                startDeviceMotion()
                startLookVectorTracking()
            } else {
                destroyScene()
                stopDeviceMotion()
                stopLookVectorTracking()
            }
        }
    }

    //Motion
    private let motionManager = CMMotionManager()
    private var lastMotion:CMDeviceMotion?

    private var animatingPitch = false
    private var manualEuler = SCNVector3Make(0, 0, 0)
    private let ManualPitchCapUp = Float(85.0*M_PI/180.0)
    private let ManualPitchCapDown = Float(60.0*M_PI/180.0)

    //Look Vector (aka Camera Position) Tracking
    //mostly in the extension, but can't (easily) add stored variables in extensions
    internal let LookVectorUnchangedTemporalRequirement = NSTimeInterval(0.2)
    internal let LookVectorUnchangedSpatialRequirement = HeadingPitch(heading: 10, pitch: 5)
    internal var lastLookVector = HeadingPitch(heading: 0, pitch: 0)
    internal var lookVectorStatsTimer: NSTimer?
    internal var lookVectorIsSettled = false

    //MARK:- View Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    //MARK: - API

    internal func play() {
        videoNode?.play()
        wPlayer?.logEvent(.Play)
    }

    internal func pause() {
        videoNode?.pause()
        wPlayer?.logEvent(.Pause)
    }

    //MARK:- Gesture Recognizers

    @IBAction func handleLongPress(sender: AnyObject) {
        //reset e'rything

        SCNTransaction.begin()
        SCNTransaction.setAnimationDuration(CFTimeInterval(0.25))

        //FoV to default
        camera.xFov = min(max(defaultCameraFov, cameraFovBounds.0), cameraFovBounds.1)

        //manual pitch and yaw to default
        manualEuler = SCNVector3Make(0, 0, 0)
        updateCamera()
        animatingPitch = true
        SCNTransaction.setCompletionBlock({ () -> Void in
            self.animatingPitch = false
        })

        SCNTransaction.commit()

    }

    @IBAction func handleTwoTouchSingleTap(sender: AnyObject) {
        //zoom out FoV
        scaleCameraXFovBy(1.5)
    }

    @IBAction func handleOneTouchDoubleTap(sender: AnyObject) {
        //zoom in FoV
        scaleCameraXFovBy(1/1.5)
    }

    @IBAction func handlePinch(sender: UIPinchGestureRecognizer) {
        let currentScale = Double(sender.scale)

        switch sender.state {
        case .Possible:
            break

        case .Began:
            pinchStartScale = currentScale
            initialCameraXFov = camera.xFov

        case .Changed:
            camera.xFov = min(max(initialCameraXFov / currentScale, cameraFovBounds.min), cameraFovBounds.max)

        case .Cancelled:
            camera.xFov = initialCameraXFov

        case .Ended:
            //was already set in changed, not doing anything with velocity
            break

        case .Failed:
            break
        }
    }

    @IBAction func handlePan(sender: UIPanGestureRecognizer) {

        switch sender.state {
        case .Possible:
            break

        case .Began:
            break

        case .Changed:
            let currentLocation = sender.locationInView(self.sceneView)
            let lastTranslation = sender.translationInView(self.sceneView)
            sender.setTranslation(CGPointZero, inView: self.sceneView)

            //roll -  Nobody wants roll when panning with a _single_ finger...
            let (pitchRadsMoved, yawRadsMoved) = pitchAndYawFor(lastTranslation, endingAt: currentLocation)
            let yawRads = manualEuler.z - yawRadsMoved
            let pitchRads = min(max(manualEuler.x + pitchRadsMoved, -ManualPitchCapDown), ManualPitchCapUp)

            manualEuler = SCNVector3Make(pitchRads, 0, yawRads)
            if lastMotion != nil {
                //camera will be updated in device motion loop
            } else {
                //need to update camera here
                updateCamera()
            }

        case .Cancelled:
            break

        case .Ended:
            //translation was applied in last .Changed branch
            //figure out where velocity should land us, get the pitch/yaw that would accomplish it, apply in animation block
            let currentLocation = sender.locationInView(self.sceneView)
            let endVelocity = sender.velocityInView(sceneView) //points per second
            let seconds:CGFloat = 1/4.0
            let s_2 = seconds * seconds
            let translationForVelocity = CGPoint(x: endVelocity.x * s_2, y: endVelocity.y * s_2)
            let destination = CGPoint(x: currentLocation.x + translationForVelocity.x, y: currentLocation.y + translationForVelocity.y)
            let (pitchVRads, yawVRads) = pitchAndYawFor(translationForVelocity, endingAt: destination)
            let yawRads = manualEuler.z - yawVRads
            let pitchRads = min(max(manualEuler.x + pitchVRads, -ManualPitchCapDown), ManualPitchCapUp)

            SCNTransaction.begin()
            SCNTransaction.setAnimationDuration(CFTimeInterval(seconds))
            manualEuler = SCNVector3Make(pitchRads, 0, yawRads)
            updateCamera()
            animatingPitch = true
            SCNTransaction.setCompletionBlock({ () -> Void in
                self.animatingPitch = false
            })
            SCNTransaction.commit()

        case .Failed:
            break
        }

    }

    //MARK:- Scene Kit / Camera

    private func scaleCameraXFovBy(scaleFactor:Double) {
        SCNTransaction.begin()
        SCNTransaction.setAnimationDuration(CFTimeInterval(0.25))
        camera.xFov = min(max(camera.xFov * scaleFactor, cameraFovBounds.0), cameraFovBounds.1)
        SCNTransaction.commit()
    }

    private func updateCamera(){
        // 0) For manual yaw: apply liberally to sphere
        sphereNode.eulerAngles.z = manualEuler.z

        let pitchVector:SCNVector3

        if let attitude = lastMotion?.attitude {
            // 1) For device motion: orient camera directly from attitude
            cameraHolderNode.orientation = SCNVector4Make(
                Float(attitude.quaternion.x),
                Float(attitude.quaternion.y),
                Float(attitude.quaternion.z),
                Float(attitude.quaternion.w))

            // 2) For manual pitch with device motion:
            // 2a) Find vector to pitch over
            let inverseCameraTransform = SCNMatrix4Invert(cameraHolderNode.transform)

            //To pitch the camera towards the poles, taking into account the camera's current orientation...
            //Rotate over a "pitch vector" that is perpendicular to both
            // The camera Z axis (where you're looking) and
            // A vector, in transformed camera space, that points to the bottom of the world (ie. at south pole of sphere)
            let cameraSpaceZAxisVector = SCNVector3Make(0, 0, 1)
            let cameraSpaceDownVector = SCNVector3FromGLKVector3(GLKMatrix4MultiplyVector3(SCNMatrix4ToGLKMatrix4(inverseCameraTransform), GLKVector3Make(0, 0, 1)))
            pitchVector = cameraSpaceZAxisVector.wk_cross(cameraSpaceDownVector).wk_normalized()
        } else {
            // 1) Without device motion: camera was oriented properly when setup

            // 2) For manual pitch without device motion
            // 2a) Vector to pitch over just the x axis that runs laterally
            pitchVector = SCNVector3Make(-1, 0, 0)
        }

        //allow animation to finish before updating pitch, or you preempt it and screwed it up
        if animatingPitch { return }

        // 2b) pitch over it
        let pitchRotation = SCNMatrix4MakeRotation(-manualEuler.x, pitchVector.x, pitchVector.y, pitchVector.z)
        cameraNode.transform = pitchRotation
    }

    private func destroyScene(){
        videoScene?.removeAllChildren()
        videoNode = nil
        for node in scene.rootNode.childNodes {
            node.removeFromParentNode()
        }
    }

    private func buildScene(videoSize videoSize:CGSize, sphereRadius:CGFloat) {
        guard wPlayer != nil else { return }
        // Make sure scene is empty
        // Optimization: in the future we could resuse the scene and just update videoNode when player is set
        destroyScene()
        // 1) Player is injected from an outside controller

        // 2) Have video frames rendered into GPU using SceneKit
        let videoSceneSize = videoSize
        videoScene = SKScene(size: videoSceneSize)
        videoNode = SKVideoNode(AVPlayer: wPlayer!.avPlayer)
        videoNode!.size = videoSceneSize
        videoNode!.anchorPoint = CGPoint(x: 0, y: 0)
        videoNode!.pause()
        videoScene!.addChild(videoNode!)

        // 3) Use the 2D video scene as the texture of a sphere in a 3D SceneKit
        sceneView.scene = scene
        // 3a) Camera - inside the sphere looking down negative Z axis
        camera.xFov = defaultCameraFov
        cameraNode.camera = camera
        cameraNode.position = SCNVector3Make(0, 0, 0)
        cameraHolderNode.position = cameraNode.position
        cameraHolderNode.addChildNode(cameraNode)
        // When running without device motion, camera should be setup to look ahead
        cameraHolderNode.transform = SCNMatrix4MakeRotation(-Float(M_PI_2), -1, 0, 0)
        scene.rootNode.addChildNode(cameraHolderNode)

        // 3b) Sphere
        let sphere = SCNSphere(radius:sphereRadius)
        // Set texture to the video
        let material = SCNMaterial()
        material.diffuse.contents = videoScene
        // Render that texture on front and back of sphere's polygons
        material.doubleSided = true
        // But don't render the front (ie. outside of sphere) for performance
        material.cullMode = SCNCullMode.Front
        sphere.firstMaterial = material
        // Add to the scene
        sphereNode = SCNNode(geometry: sphere)
        // Reorient sphere to account for default texture mapping (upside down, backwards)
        // and device motion (natural state is device laying on back)
        sphereNode.transform = SCNMatrix4MakeRotation(-Float(M_PI_2), 1, 0, 0)

        scene.rootNode.addChildNode(sphereNode)
    }

    //MARK:- Device Motion

    private func stopDeviceMotion() {
        motionManager.stopDeviceMotionUpdates()
    }

    private func startDeviceMotion() {
        //Putting this on main queue b/c I'm not doing heavy math in my handler
        motionManager.deviceMotionUpdateInterval = 1/90.0
        motionManager.startDeviceMotionUpdatesUsingReferenceFrame(.XArbitraryCorrectedZVertical, toQueue: NSOperationQueue.mainQueue(), withHandler: self.absoluteDeviceMotionHandler)
    }

    private func absoluteDeviceMotionHandler(deviceMotion:CMDeviceMotion?, error:NSError?) {
        if let motion = deviceMotion {
            self.lastMotion = motion
            updateCamera()
        }
    }

    //MARK:- Helpers

    private func pitchAndYawFor(translation:CGPoint, endingAt currentLocation:CGPoint) -> (Float, Float) {
        //don't need to care about device attitude by using localCoordinates
        let startLocation = CGPoint(x: currentLocation.x - translation.x, y: currentLocation.y - translation.y)

        if let startHit = sceneView.hitTest(startLocation, options: [SCNHitTestFirstFoundOnlyKey: NSNumber(bool: true), SCNHitTestBackFaceCullingKey: NSNumber(bool: true)]).first,
            endHit = sceneView.hitTest(currentLocation, options: [SCNHitTestFirstFoundOnlyKey: NSNumber(bool: true), SCNHitTestBackFaceCullingKey: NSNumber(bool: true)]).first {

                //longitude = yaw = atan2(x, z)
                //latitude = pitch = arcsin(y / r)
                let startLong = atan2(startHit.localCoordinates.x, startHit.localCoordinates.z)
                let startLat = asin(startHit.localCoordinates.y / Float(SphereRadius))
                let endLong = atan2(endHit.localCoordinates.x, endHit.localCoordinates.z)
                let endLat = asin(endHit.localCoordinates.y / Float(SphereRadius))
                var deltaLong = endLong - startLong
                //Keep delta small in correct direction when crossing from -pi to +pi (and vice versa)
                if fabs(deltaLong) > Float(M_PI) {
                    deltaLong = (Float(M_PI) - fabs(endLong)) + (Float(M_PI) - fabs(startLong))
                    if translation.x < 0 {
                        deltaLong = -deltaLong
                    }
                }
                let deltaLat = endLat - startLat

                return (deltaLat, deltaLong)
        }
        return (0, 0)
    }
    
}

#endif //os(iOS)