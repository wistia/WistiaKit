# WistiaKit
![WistiaKit](/../assets/wistia_kit_stack_logo.png)

The best way to play Wistia video on iPhone, iPad, and Apple TV.  Written in Swift.

[![CI Status](http://img.shields.io/travis/wistia/WistiaKit.svg?style=flat)](https://travis-ci.org/wistia/WistiaKit)
[![Version](https://img.shields.io/cocoapods/v/WistiaKit.svg?style=flat)](http://cocoapods.org/pods/WistiaKit)
[![License](https://img.shields.io/cocoapods/l/WistiaKit.svg?style=flat)](http://cocoapods.org/pods/WistiaKit)
[![Platform](https://img.shields.io/cocoapods/p/WistiaKit.svg?style=flat)](http://cocoapods.org/pods/WistiaKit)

## Your Video on iOS in 5 minutes!

Disclaimer 1: You need to have [Xcode 8 GM Seed installed](https://developer.apple.com/xcode/) (which will take > 5 minutes if you don't already have it updated)
Disclaimer 2: You need to have [RubyGems installed](https://rubygems.org/pages/download) (which may also take a little while)

Ok, got that out of the way.  Now for the fun and fairly easy part!

1.  Install [Cocoapods](https://cocoapods.org) if you haven't already: ~~`gem install cocoapods`~~ Until Cocoapods 1.1.0 is released, install the prerelease with `gem install cocoapods --pre`
2.  `pod try WistiaKit` will pull this Pod down and open it in Xcode
3.  Choose the "WistiaKit-Example" project next to the play icon and press play!

This simple app lets you enter the Hashed ID of any media and play it.  Look at the code in `WistiaKit/Example for Wistia Kit/ViewCongtroller.swift` and look at the basic interface in `WistiaKit/Example for Wistia Kit/Main.storyboard`.  That's all there is to it; two interface outlets, one custom instance variable, and three lines of code to play the video.

## Your Video on tvOS (Apple TV)

Just add the `WistiaKit` pod to any tvOS project.  Yup, that's it.  

Two caveats:

1. There is not yet an example project (like above).  So it may take more than 5 minutes.
2. The `WistiaPlayerViewController` is not available on tvOS.  Instead, create a `WistiaPlayer` and an `AVPlayerViewController` and marry them with `avPlayerVC.player = wistiaPlayer.avPlayer`.  We think the `AVPlayerViewController` looks great on the TV and would be hard pressed to do better.

## You Improve WistiaKit

We're still in the early phases of developing this thing.  Please get in touch with us (Create an issue, a pull request, email or tweet at Wistia, etc.) to let us know what you'd like to see in WistiaKit.

## Requirements 

You need a [Wistia](http://wistia.com) account on the Platform plan.  You'll also need some videos in your account.  And at this point in the game, you need the Hashed ID of the video you'd like to play. 

## Installation

WistiaKit is available through [CocoaPods](http://cocoapods.org).

> CocoaPods 1.1.0+ is required to build WistiaKit 0.12+.

To install, simply add the following line to your Podfile:

```ruby
pod "WistiaKit"
```

## Usage

WistiaKit is conceptually divided into two tranches; **playback** and **data**.  Depending on your application, you may use both components -- which work seamlessly together -- or either of them independently.  Let's briefly get to know them before diving into the details.

**Playback** is akin to a web embed.  You can present a `WistiaPlayerViewController` and play any of your videos using nothing but its `hashedID`.  Customizations are applied to the player and statistics are tracked like normal; you need do nothing extra.  Run the example project in this pod to see it in action (`pod try WistiaKit` then hit ▶ in Xcode >= 8.0).

If you don't want all the chrome (ie. player controls, scrubber, time, initial poster, etc.) you can get a little lower level with `WistiaPlayer`.  You still need just a `hashedID`, but all you get is an `AVPlayerLayer` which you can present and gussy up however you wish.  All your Wistia statistics ~~are belong to us~~ are tracked like normal.  Psst: the `WistiaPlayerViewController` uses the `WistiaPlayer` under the hood.

**Data** is provided through the [Data API](http://wistia.com/doc/data-api).  We've Swift'd it up, built a bunch of structs, and added some nice syntactic sugar.  And the end result -- we hope -- is that it feels natural whether you're coming from another code-level interface to the Data API or the web view you use to manage your account.  Initialize a `WistiaAPI` object with an API Token from your account and you're off to the races.  View account details, list your projects, dig into your medias; everything you can do from the Data API, you can do from here.

Bring them both together: create a `WistiaAPI` to browse your `WistiaProject`s, choose a `WistiaMedia`, use that `WistiaMedia` object to initialize a `WistiaPlayerViewController`, and then `self.presentViewController(_:animated:completion:)`!  It's so easy, I bet you could build a pretty nice Apple TV app in a hackathon...

### Data

I guess there's not much to say here.  Mostly just refer to the [Data API](http://wistia.com/doc/data-api) docs.  And of course, you should use an instance of `WistiaAPI` to intrect with the API.  For example:

```swift
import WistiaKit

let globalAPI = WistiaAPI(apiToken:"C4NTB3L13V3TH1S1SARAND0MT0K3N")

func printMediasByProject(){
    globalAPI.listProjects { (projects) in
        for project in projects {
            print("\(project) medias:")
            globalAPI.listMedias(limitedToProject: project, completionHandler: { (medias) in
                for media in medias {
                    print("  \(media)")
                }
            })
        }
    }
}
```

Caveat: WistiaKit is not yet [Data API](http://wistia.com/doc/data-api) complete.  But it will be.  If there's some functionality that you want, but is not yet available, let us know by submitting a Pull Request ☺ or creating an issue.


>**A Note About Structs**
>
>New to iOS programming, via Swift, is the expanded availability of value semantics.  We'll discuss exatly what that means in soon.
>
>In the good old days of Objective-C you had objects.  These were your classes and what not.  When you passed objects into methods, or stored them in variables, you were always talking about the same object.  This is because your object was a _reference type_.  You were actually passing around _references_ (aka pointers) to the object.
>
>But even then you had _value types_.  A good example were your integers.  If you said `a = 4` and `b = a`, you set both `a` and `b` to the value of 4.  They weren't pointing to an object.  So `b++` didn't change the value of `a`, it would remain 4.
>
>Enter Swift and a whole lot more value types!  Now we have _struct_ s (and _enum_ s and tuples) that may remind us of reference types, but are actually value types.  In `WistiaKit`, your data objects are _struct_ s.  So if you `let a = someMedia` and `let b = a`, your variables `a` and `b` have independent copies of that `WistiaMedia`.  If you change something, like `a.name = "whatever"`, this won't affect `b.name`.
>
>We think this makes `WistiaKit` less error prone and makes it easier to reason about your code.
>
>If you want to spend some guru meditation time on this, you could do worse than starting with the [Swift Blog](https://developer.apple.com/swift/blog/?id=10) and a [WWDC 2015 talk](https://developer.apple.com/videos/play/wwdc2015/414/).

### Playback

The first thing to do is decide how you'd like your video player to look.  If you're familiar with video playback on iOS already, then all you need to know is: `WistiaPlayerViewController ~= AVPlayerViewController` and `WistiaPlayer ~= AVPlayer`.  If you're new to video on iOS, or just need a refresher, read on.

Those who like the look of our web player -- including (most) customizations -- and/or don't want to do a ton of UI buliding should use the `WistiaPlayerViewController`.  You may present it fullscreen or within a `ContainerView` inside your own `ViewController`.  It comes with standard playback controls and some nice delegate methods for you to hook into.

For those of you who want total control, you want the `WistiaPlayer`.  To see the video you will need to present the `AVPlayerLayer` vended by your instance of the `WistiaPlayer`.  And you'll need to programatically control the `WistiaPlayer` yourself; an `AVPlayerLayer` renders only video and includes no player controls or other UI.  As you can see, with great power comes great responsibility.  :-P


#### Initializing `WistiaPlayerViewController` or `WistiaPlayer`

* `referrer` - We recommend using a universal link to the video.  This will allow you to click that link from the Wistia stats page while still recording the in-app playback location.
* `requireHLS` - Apple has [specific requirements](https://developer.apple.com/app-store/review/guidelines/#media-content) for playing video within apps.  It boils down to this: if you want to play video over 10 minutes in length over the celluar network (ie. you don't force wifi), then you must use [HLS](https://developer.apple.com/streaming/).  And Wistia fully supports and has thoroughly tested our HLS implementation with Apple.   We recommend leaving this to `true` which is the default.


#### `WistiaPlayerViewController` Example

Lets say we're building an app that has an introductory section.  We can use a single `WistiaPlayerViewController` to load any number of intro videos and present them full screen, as in the following example:

```swift
import WistiaKit

class IntroductionViewController: UIViewController {

  let wistiaPlayerVC = WistiaPlayerViewController(referrer: "https://wistia.tv/intro")

  func loadVideoWithHashedID(hashedID: String) {
    wistiaPlayerVC.replaceCurrentVideoWithVideoForHashedID(hashedID)
    self.presentViewController(wistiaPlayerVC, animated: true, completion: nil)
  }
}
```

This will load the video, but it is up to the user to play and otherwise interact with the content.

#### `WistiaPlayer` Example

If we want our intro video to behave a little differently, we might use a `WistiaPlayer`.  In the following example, we play an intro video without giving the user any way to control the video.  They have to sit there and watch it! `<evil>`bwaa ha ha ha!`</evil>`  When video playback completes, we automatically progress to the next intro screen.

Below, we display the video with a `WistiaFlatPlayerView`, which is a plain UIView backed by an `AVPlayerLayer`.  This layer is configured to display video content when you set the view's `wistiaPlayer` property to an instance of `WistiaPlayer`.  While it behaves like any other `UIView`, allowing you to use common and familiar lifecycle and layout mechanisms, you may clamor for more power.

A standalone `AVPlayerLayer` is avaiable through an `WistiaPlayer`s `newPlayerLayer()` method.  Upon requesting this layer, any previously configured layers or view's will cease to render the content for that player.  A newly initialized `AVPlayerLayer` - like any `CALayer` - should have its frame set before being added as a sublayer.  You are also responsible for maintaining layout at the layer level, either manually, with `CAConstraint`s, or an other layer-based mechanism.


```swift
import WistiaKit

class IntroductionViewController: UIViewController, WistiaPlayerDelegate {

  let wistiaPlayer = WistiaPlayer(referrer: "https://wistia.tv/intro")
  
  // In Interface Builder we set the view's class to WistiaFlatPlayerView.  
  // If we had a compelling reason, we could instead use an AVPlayerLayer directly via `newPlayerLayer()`.
  // But a UIView is more familiar without sacrificing much flexibility.
  @IBOutlet weak var playerContainer: WistiaFlatPlayerView!
  
  override public func viewDidLoad() {
    wistiaPlayer.delegate = self
    playerContainer.wistiaPlayer = wistiaPlayer
    wistiaPlayer.replaceCurrentVideoWithVideoForHashedID(IntroVideoHashedID)
  }
  
  //Mark: - WistiaPlayerDelegate
  
  public func wistiaPlayer(player:WistiaPlayer, didChangeStateTo newState:WistiaPlayer.State) {
    switch newState {
    case .VideoReadyForPlayback:
      wistiaPlayer.play()
    default:
      //ignoring, but probably shouldn't
    }
  }

  public func wistiaPlayerDidPlayToEndTime(player: WistiaPlayer) {
    self.showNextIntroScreen()
  }
  
  // ... rest of delegate methods ...
  
}
```

#### Closed Captioning

If you are using the `WistiaPlayerViewController`, closed captioning if fully supported right out of the box.  You don't need to do anything more!

For those interpid slingers of the codez using `WistiaPlayer` directly, we've made it fairly simple to display captions.  Grab the `WistiaPlayer.captionsRenderer` -- an instance of `WistiaCaptionsRenderer` configured for that player -- and hook up its `captionsView` to a view in your UI that overlays the video view.  The renderer handles the under-the-hood work of retrieving the captions, timing data, updating the UI content, and mainting proper UI visibility.  Captions are kept up to date during playback and seeking across all videos loaded by the `WistiaPlayer`.  Control what captions, if any, are displayed with the `enabled` and `captionsLanguageCode` properties of the `WistiaCaptionsRenderer`.

## Player APIs

Up above are a bunch of words that explain how WistiaKit is structured, how to approach it, and some examples of how to use it.  It's good to know the lay of the land.  But as they say, _the map is not the terrain_.  You're ready young padawan, go forth and read the [appledoc](http://cocoadocs.org/docsets/WistiaKit).


## Author

d j spinosa, spinosa@gmail.com

## License

WistiaKit is available under the MIT license. See the LICENSE file for more info.
