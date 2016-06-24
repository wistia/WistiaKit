//
//  WistiaCaptions.swift
//  Pods
//
//  Created by Daniel Spinosa on 6/23/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//
//  

import Foundation

/**
 All of the information needed to display captions for a single language.
 
 Each screen of captions is defined by a WistiaCaptionSegment which includes timing
 and the actual text to be displayed.

 */
internal struct WistiaCaptions {

    /// A unique identifier for this captions object.
    let captionsID:Int

    /// Three letter code specifying the language of these captions.
    let languageCode:String

    /// English name of the language of these captions.
    let englishName:String

    /// Native name of the language of these captions.
    let nativeName:String

    /// Should this text be displayed right-to-left.
    let rightToLeft:Bool

    /// Array of individual caption segments with display timing.
    let captionSegments:[WistiaCaptionSegment]
}

/**
 A set of text to be displayed over the video.  Each segment is only used once and 
 specifies the time to begin and end showing it.
 
 */
internal struct WistiaCaptionSegment {
    /// Time in video to begin displaying this segment
    let startTime:Float

    /// Time in video to stop displaying this segment
    let endTime:Float

    /// (Ordered) Array of lines of text to show on screen together
    let text:[String]
}