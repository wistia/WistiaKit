//
//  _WistiaCaptions.swift
//  WistiaKit internal
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
public struct WistiaCaptions {

    /// A unique identifier for this captions object.
    public let captionsID:Int

    /// Three letter code specifying the language of these captions.
    public let languageCode:String

    /// English name of the language of these captions.
    public let englishName:String

    /// Native name of the language of these captions.
    public let nativeName:String

    /// Should this text be displayed right-to-left.
    public let rightToLeft:Bool

    /// Array of individual caption segments with display timing.
    public let captionSegments:[WistiaCaptionSegment]
}

extension WistiaCaptions: WistiaJSONParsable {

    /// Initialize a WistiaCaptions from the provided JSON hash.
    ///
    /// - Note: Prints error message to console on parsing issue.
    ///
    /// - parameter dictionary: JSON hash representing the WistiaCaptions.
    ///
    /// - returns: Initialized WistiaCaptions if parsing is successful.
    init?(from dictionary: [String: Any]?) {
        guard dictionary != nil else { return nil }
        let parser = Parser(dictionary: dictionary)
        do {

            captionsID = try parser.fetch("id")
            languageCode = try parser.fetch("language")
            englishName = try parser.fetch("english_name")
            nativeName = try parser.fetch("native_name")
            rightToLeft = try parser.fetch("right_to_left")

            let linesDictionary:[String: Any] = try parser.fetch("hash")
            let lines:[[String:Any]] = try Parser(dictionary:linesDictionary).fetch("lines")

            var segments = [WistiaCaptionSegment]()
            for line in lines {
                if let seg = WistiaCaptionSegment(from: line) {
                    segments.append(seg)
                }
            }

            //WistiaCaptionsRenderer assumes segments are in order
            segments.sort(by: { (segA, segB) -> Bool in
                segA.startTime < segB.startTime
            })

            self.captionSegments = segments

        } catch let error {
            print(error)
            return nil
        }
    }
    
}

/**
 A set of text to be displayed over the video.  Each segment is only used once and 
 specifies the time to begin and end showing it.
 
 */
public struct WistiaCaptionSegment {
    /// Time in video to begin displaying this segment
    public let startTime:Float

    /// Time in video to stop displaying this segment
    public let endTime:Float

    /// (Ordered) Array of lines of text to show on screen together
    public let text:[String]
}

internal extension WistiaCaptionSegment {

    /// Initialize a WistiaCaptionSegment from the provided JSON hash.
    ///
    /// - Note: Prints error message to console on parsing issue.
    ///
    /// - parameter dictionary: JSON hash representing the WistiaCaptionSegment.
    ///
    /// - returns: Initialized WistiaCaptionSegment if parsing is successful.
    init?(from dictionary: [String: Any]) {
        let parser = Parser(dictionary: dictionary)
        do {
            startTime = try parser.fetch("start")
            endTime = try parser.fetch("end")
            text = try parser.fetchArray("text") { $0 }
        } catch let error {
            print(error)
            return nil
        }
    }
    
}
