# WistiaKit
The best way to play Wistia video on iPhone, iPad, and Apple TV.

[![CI Status](http://img.shields.io/travis/wistia/WistiaKit.svg?style=flat)](https://travis-ci.org/spinosa/WistiaKit)
[![Version](https://img.shields.io/cocoapods/v/WistiaKit.svg?style=flat)](http://cocoapods.org/pods/WistiaKit)
[![License](https://img.shields.io/cocoapods/l/WistiaKit.svg?style=flat)](http://cocoapods.org/pods/WistiaKit)
[![Platform](https://img.shields.io/cocoapods/p/WistiaKit.svg?style=flat)](http://cocoapods.org/pods/WistiaKit)

## Your Video on iOS in 5 minutes!

Disclaimer 1: You need to have [Xcode 7.3 installed](https://itunes.apple.com/us/app/xcode/id497799835?mt=12) (which will take > 5 minutes if you don't already have it updated)
Disclaimer 2: You need to have [RubyGems installed](https://rubygems.org/pages/download) (which may also take a little while)

Ok, got that out of the way.  Now for the fun and fairly easy part!

1.  Install [Cocopods](https://cocoapods.org) if you haven't already: `gem install cocoapods`
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

WistiaKit is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "WistiaKit"
```

## Usage

This section needs a lot of TLC.  Until that happens, please check out the example app and/or get in touch with us directly.

You deserve great documentation.  And you shall receive it!  But we erred on the side of early over complete to get your feedback during development of WistiaKit.  We'd love for you to be a part of this journey with us. 

## Author

spinosa, spinosa@gmail.com

## License

WistiaKit is available under the MIT license. See the LICENSE file for more info.
