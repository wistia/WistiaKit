//
//  WistiaVulcanPlayerViewController.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 4/11/17.
//  Copyright © 2017 Wistia, Inc. All rights reserved.
//
// Plan is to make this match closely with current WistiaPlayerViewController,
// but *not* to create a protocol that both conform to.  It is expected that these players
// need minimal changes to swap *only* when using a subset of their functionality.

import UIKit
import WebKit
import WistiaKitData

/**
 The delegate of a `WistiaVulcanPlayerViewController` must adopt the `WistiaVulcanPlayerViewControllerDelegate`
 protocol.  It will receive information about user interactions with the `WistiaVulcanPlayerViewController`
 through these methods.
 */
public protocol WistiaVulcanPlayerViewControllerDelegate : class {

    /**
     Informs the delegate that the state of the `WistiaVulcanPlayerViewController`'s player has changed.

     - Parameter controller: The `WistiaVulcanPlayerViewController` that has changed player state.
     - Parameter newState: The new (and now-current) state of the player.
     */
    func vulcanController(_ controller: WistiaVulcanPlayerViewController, playerDidChangeStateTo newState: WistiaVulcanPlayerViewController.VulcanPlayerState)

    /**
     Informs the delegate the playback rate has changed.  A rate of 0.0
     means the video is paused.  Normal playback rate is 1.0.

     - Parameter player: The `WistiaVulcanPlayerViewController` for which the playback rate changed.
     - Parameter newRate: The new playback rate of the current media.
     */
    func vulcanController(_ controller: WistiaVulcanPlayerViewController, didChangePlaybackRateTo newRate:Float)

    /**
     Informs the delegate about the current progress of media playback.

     During playback, this method will be called at roughly 3.3Hz.

     This will not be called when the player's rate is 0.0 (ie. video is paused).

     - Parameter player: The `WistiaVulcanPlayerViewController` for which playback progress has changed.
     - Parameter currentTime: The current time in the video for which playback is occurring.
     */
    func vulcanController(_ controller: WistiaVulcanPlayerViewController, didChangePlaybackProgressToTime currentTime: Float)

    /**
     Informs the delegate that the `WistiaVulcanPlayerViewController` is entering or exiting fullscreen prsentation.
     
     When going fullscreen, the `WistiaVulcanPlayerViewController` will remove itself from the view hierarchy and 
     present itself view screen.
     
     When exiting fullscreen, the `WistiaVulcanPlayerViewController` will reinsert itself back into the original view hierarchy.

     - Parameter player: The `WistiaVulcanPlayerViewController` changing its fullscreen state.
     - Parameter goingFullscreen: True when entering fullscreen, false when exiting fullscreen.
     */
    func vulcanController(_ controller: WistiaVulcanPlayerViewController, willEnterFullscreen goingFullscreen: Bool)

    /**
     Informs the delegate that the `WistiaVulcanPlayerViewController` has entered or exited fullscreen prsentation.

     After going fullscreen, the `WistiaVulcanPlayerViewController` has removed itself from the view hierarchy and
     presented itself view screen.

     After exiting fullscreen, the `WistiaVulcanPlayerViewController` has reinserted itself back into the original view hierarchy.

     - Parameter player: The `WistiaVulcanPlayerViewController` that changed its fullscreen state.
     - Parameter isFullscreen: True after entering fullscreen (ie. currently is fullscreen), false after exiting fullscreen (ie.
        not currently fullscreen).
     */
    func vulcanController(_ controller: WistiaVulcanPlayerViewController, didEnterFullscreen isFullscreen: Bool)

}

/**
 `WistiaVulcanPlayerViewController` acts much like an `AVPlayerViewController`.  It will display your
 media including player controls customized in the Wistia fashion, allowing for user-initiated and/or
 programtic control of playback.

 Configure a `WistiaVulcanPlayerViewController` with a `WistiaMedia`, or the `hashedID` of one, and it will
 play the best asset for the device and current configuration.

 All video types supported by Wistia (currently _flat_ and _spherical_ / _360°_) are handled properly
 by this controller.

 Use the `WistiaVulcanPlayerViewControllerDelegate` as a convenient mechanism to respond to key events in the
 controller's lifecycle.
 
 Technical Note: The underlying player (Vulcan, see https://wistia.com/blog/announcing-new-video-player-vulcan) is
 the same web-based player used to embed Wistia videos on web pages.  It is loaded in a WKWebView and has been wrapped
 in a convenient Swift API.  There is no direct access to the web view or playre therein.  But any methods and events
 available on the web can be implemented in WistiaKit.  Just submit a PR (fastest) or issue on github. =)

 - Note: This class is declared `final` as it hooks into the `UIViewController` lifecycle at very specific
 points.  Functionality is undefined if `extension`s are created that alter or prevent any of view controller
 lifecycle methods from being called as expected.
 */
public final class WistiaVulcanPlayerViewController: UIViewController {

    //MARK: - Initialization

    /**
     Initialize a new `VulcanController` without an initial video for playback.

     - Important: If you are using [Domain Restrictions](https://wistia.com/doc/account-setup#domain_restrictions),
     referrer must match your whitelist or video will not load.

     - Parameter referrer: The referrer shown when viewing your video statstics on Wistia.
     \
     We recommend using a universal link to the video.
     This will allow you to click that link from the Wistia stats page
     while still recording the in-app playback location.
     \
     In the case it can't be a universal link, it should be a descriptive string identifying the location
     (and possibly state) of your app where this video isbeing played back
     eg. _ProductTourViewController_ or _SplashViewController.page1(uncoverted_email)_

     - Returns: An idle `WistiaVulcanPlayerViewController` not yet displayed.
     */
    public convenience init(referrer: String){
        self.init()
        self.referrer = referrer
    }

    //MARK: - Instance Properties

    /**
     The object that acts as the delegate of the `WistiaVulcanPlayerViewController`.
     It must adopt the `WistiaVulcanPlayerViewControllerDelegate` protocol.

     The delegate is not retained.
     */
    public weak var delegate: WistiaVulcanPlayerViewControllerDelegate?

    /// When true (default), the player will present a fullscreen control.  When the user taps that button,
    /// this view controller will remove itself from the view hierarchy and present itself over the entire application.  
    /// When the button is tapped to exit fullscreen, this view controller will reinsert itself back into
    /// view hierarchy as it was originally presented.
    /// Register a delegate to receive callbacks during this cycle.
    public var fullscreenEnabled = true {
        didSet {
            showFullscreenButton(shouldShow: fullscreenEnabled)
        }
    }

    /// Toggle the fullscreen mode of this view controller.
    public func toggleFullscreen() {
        _toggleFullscreen()
    }

    /// Current fullscreen state.
    public func isFullscreen() -> Bool {
        return fullscreenWindow != nil
    }

    /// The current state of the underlying video player.
    /// Register a delegate to observe changes to this property.
    fileprivate(set) var playerState: VulcanPlayerState = .unloaded {
        didSet {
            delegate?.vulcanController(self, playerDidChangeStateTo: playerState)
        }
    }

    /**
     The referrer shown when viewing your video statstics on Wistia.

     We recommend using a universal link to the video.
     This will allow you to click that link from the Wistia stats page
     while still recording the in-app playback location.

     - Important: If you are using [Domain Restrictions](https://wistia.com/doc/account-setup#domain_restrictions),
     referrer must match your whitelist or video will not load.

     - Note: Changing referrer takes effect the next time the video is replaced; it does not affect the currently
     playing video.
     
     */
    public var referrer = "https://wistia.com"

    //MARK: - Changing Media

    /**
     Use this property to initiate the asynchronous loading of a video.  Pauses the currently playing video before
     starting the loading process.  Works just as well if there is no current video.

     You may call this method immediately upon initializing a new instance.  This will cause the view to load even
     if it is an orphan of the view hierarchy.

     If you do not have a `WistiaMedia` object, you may call `replaceCurrentVideoWithVideo` with the hashedID
     instead.

     - Note: Changing this property will always force the player to reload if the given `media` is not `nil`.
     
     - Note: If a video is played usingn `replaceCurrentVideoWithVideo`, this will remain `nil`.

     */
    public var media: WistiaMedia? = nil {
        didSet {
            if let hashedID = media?.hashedID {
                self.loadViewIfNeeded()
                pause()
                loadVulcanPlaying(hashedID: hashedID)
            }
        }
    }

    /**
     Use this method to initiate the asynchronous loading of a video.  Pauses the currently playing video before
     starting the loading process.  Works just as well if there is no current video.

     You may call this method immediately upon initializing a new instance.  This will cause the view to load even
     if it is an orphan of the view hierarchy.

     If you have a `WistiaMedia` object, you may set the media property instead of calling this method.

     - Note: This method will always force the player to reload.
     
     - Note: The `media` property will be `nil` when a video is played using this method.

     - Parameter hashedID: The ID of a Wistia media from which to choose an asset to load for playback.

     */
    public func replaceCurrentVideoWithVideo(forHashedID hashedID: String) {
        self.loadViewIfNeeded()
        media = nil
        pause()
        loadVulcanPlaying(hashedID: hashedID)
    }

    //MARK: - Controlling Playback

    /// Play the video.  This method is idempotent.
    public func play() {
        webView?.evaluateJavaScript("wkVideo.play();", completionHandler: nil)
    }

    /// Pause the video.  This method is idempotent.
    public func pause() {
        webView?.evaluateJavaScript("wkVideo.pause();", completionHandler: nil)
    }

    /// Play the video if it's currently paused.  Pause if it's currently playing.
    public func togglePlayPause() {
        webView?.evaluateJavaScript("if (wkVideo.state() === \"playing\") { wkVideo.pause(); } else { wkVideo.play(); }") { result, err in
            if let result = result {
                print("success: \(result)")
            } else {
                print("error is \(String(describing: err))")
            }
        }
    }

    //MARK: - -----------Internal-----------

    fileprivate var webView: WKWebView?
    fileprivate var config: WKWebViewConfiguration!

    //fullscreen stuff
    fileprivate var fullscreenWindow: UIWindow?
    fileprivate weak var originalContainer: UIViewController!
    fileprivate weak var originalSuperview: UIView!

    //The player's controls
    fileprivate var hideControls = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    //MARK: - View lifecycle

    override public final func loadView() {
        webView = createWebView()
        view = webView
    }

    override public final func viewDidLoad() {
        super.viewDidLoad()
        addScriptMessageHandlers()
    }

    override public final func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition(in: nil, animation: nil) { (context) in
            //player resizes every 500ms
            //but we want to resize as soon as container has changed size
            self.webView?.evaluateJavaScript("wkVideo._doMonitor();", completionHandler: nil)
        }
    }

}

//MARK: - Web View Setup

extension WistiaVulcanPlayerViewController {

    fileprivate func createWebView() -> WKWebView {
        config = webViewConfiguration()
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.allowsBackForwardNavigationGestures = false
        wv.scrollView.maximumZoomScale = 1.0
        wv.scrollView.minimumZoomScale = 1.0
        wv.scrollView.isScrollEnabled = false
        return wv
    }

    private func webViewConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsAirPlayForMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        if #available(iOS 10.0, *) {
            config.mediaTypesRequiringUserActionForPlayback = []
        }

        return config
    }

    fileprivate func loadVulcanPlaying(hashedID: String) {
        config.userContentController.removeAllUserScripts()
        config.userContentController.addUserScript(WKUserScript(source: "var wkVideo; window._wq = window._wq || []; _wq.push({ id: \"\(hashedID)\", onReady: function(video) { wkVideo = video; window.webkit.messageHandlers.playerStateUpdate.postMessage('ready'); }});", injectionTime: .atDocumentEnd, forMainFrameOnly: true))

        webView!.loadHTMLString(fullPagePlayerHTML(hashedID: hashedID), baseURL: URL(string: referrer))
        playerState = .loading
    }

    fileprivate func fullPagePlayerHTML(hashedID: String) -> String {
        return "<html style=\"margin: 0;\"><head><meta content=\"width=device-width, initial-scale=1\" name=\"viewport\"></head><body style=\"margin: 0; background: black;\"><script src=\"https://fast.wistia.com/embed/medias/\(hashedID).jsonp\" async></script><script src=\"https://fast.wistia.com/assets/external/E-v1.js\" async></script><div class=\"wistia_responsive_padding\" style=\"padding:56.25% 0 0 0;position:relative;\"><div class=\"wistia_responsive_wrapper\" style=\"height:100%;left:0;position:absolute;top:0;width:100%;\"><div class=\"wistia_embed wistia_async_\(hashedID) seo=false videoFoam=true _inIframe=true fullscreenOnRotateToLandscape=false\" style=\"height:100%;width:100%\">&nbsp;</div></div></div></body></html>"
    }
}

//MARK: - Vulcan Helpers

extension WistiaVulcanPlayerViewController {

    //MARK: Private

    fileprivate func showFullscreenButton(shouldShow: Bool) {
        let en = fullscreenEnabled ? "true" : "false"
        webView?.evaluateJavaScript("wkVideo.fullscreenButtonEnabled(\(en));", completionHandler: nil)
    }

    //NB: This isn't yet deployed in the wistia player
    fileprivate func setControlsScaling(_ scalingFactor: Float) {
        webView?.evaluateJavaScript("wkVideo.controlScaling(\(scalingFactor));", completionHandler: nil)
    }

    fileprivate func configureVulcanUI() {
        showFullscreenButton(shouldShow: fullscreenEnabled)
        setControlsScaling(1.0)
    }
}

//MARK: - Vulcan Event Handlers

extension WistiaVulcanPlayerViewController: WKScriptMessageHandler {

    fileprivate func addScriptMessageHandlers() {
        // Below message handlers must first be registerd, but they don't _do_ anything
        // until you evaluate some javascript on the page that calls one, ie.:
        // window.webkit.messageHandlers.<handler name>.postMessage(m);
        config.userContentController.add(self, name: "playerStateUpdate")
        config.userContentController.add(self, name: "playbackRateChangeEvent")
        config.userContentController.add(self, name: "timeChangeEvent")
        config.userContentController.add(self, name: "allPlayerEvents")
    }

    private func bindVulcanEvents() {
        // good for events that don't have additional data
        webView!.evaluateJavaScript("wkVideo.bind(\"all\", function(m){ window.webkit.messageHandlers.allPlayerEvents.postMessage(m);  });", completionHandler: nil)
        // events with additional data need individual handling to marshal the data out
        webView!.evaluateJavaScript("wkVideo.bind(\"playbackratechange\", function(r){ window.webkit.messageHandlers.playbackRateChangeEvent.postMessage(r);  });", completionHandler: nil)
        webView!.evaluateJavaScript("wkVideo.bind(\"timechange\", function(t){ window.webkit.messageHandlers.timeChangeEvent.postMessage(t);  });", completionHandler: nil)
    }

    public final func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let messageBody: String = message.body is String ? (message.body as! String) : ""

        switch message.name {
        case "playerStateUpdate":
            switch messageBody {
            case "ready":
                bindVulcanEvents()
                configureVulcanUI()
                playerState = .ready
            default:
                print("user content controller \(userContentController) received odd play state update with body \(messageBody)")
            }

        case "playbackRateChangeEvent":
            if let newRate = message.body as? NSNumber {
                delegate?.vulcanController(self, didChangePlaybackRateTo: newRate.floatValue)
            }

        case "timeChangeEvent":
            if let newTime = message.body as? NSNumber {
                delegate?.vulcanController(self, didChangePlaybackProgressToTime: newTime.floatValue)
            }

        case "allPlayerEvents":
            switch messageBody {
            case "enter-fullscreen":
                if fullscreenEnabled {
                    toggleFullscreen()
                }
            case "cancel-fullscreen":
                if fullscreenEnabled {
                    toggleFullscreen()
                }

            case "hide-controls":
                hideControls = true

            case "show-controls":
                hideControls = false

            default:
                //ignoring
                //print("message: \(messageBody)")
                break
            }

        default:
            print("user content controller \(userContentController) did receive \(message.body) with body \(messageBody)")
        }
    }

}

//MARK: - Player State

extension WistiaVulcanPlayerViewController {

    public enum VulcanPlayerState {
        case unloaded, loading, ready
    }

    public enum VulcanVideoState: String {
        case beforePlay = "beforeplay",
        playing = "playing",
        paused = "paused",
        ended = "ended"
    }

    public func playerIsReady() -> Bool {
        return playerState == .ready
    }
}

//MARK: - Fullscreen

extension WistiaVulcanPlayerViewController {

    override public var prefersStatusBarHidden: Bool {
        return hideControls
    }

    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override public var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }


    fileprivate func _toggleFullscreen() {
        if !isFullscreen() {
            delegate?.vulcanController(self, willEnterFullscreen: true)
            fullscreenWindow = UIWindow(frame: UIApplication.shared.keyWindow!.bounds)
            fullscreenWindow?.windowLevel = UIWindowLevelNormal

            originalContainer = self.parent
            originalSuperview = self.view.superview

            self.willMove(toParentViewController: nil)
            self.view.removeFromSuperview()
            self.removeFromParentViewController()

            fullscreenWindow?.rootViewController = self
            self.view.frame = fullscreenWindow!.bounds
            fullscreenWindow?.isHidden = false
            delegate?.vulcanController(self, didEnterFullscreen: true)
        }
        else {
            delegate?.vulcanController(self, willEnterFullscreen: false)
            self.willMove(toParentViewController: originalContainer)
            self.view.removeFromSuperview()
            self.removeFromParentViewController()
            
            self.view.frame = originalSuperview!.bounds
            originalSuperview.addSubview(self.view)
            
            fullscreenWindow = nil
            delegate?.vulcanController(self, didEnterFullscreen: false)
        }
    }
    
}
