//
//  WistiaMedia.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 5/31/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import Foundation

/**
 An object containing aggregated tracking statistics for a `WistiaMedia`.

 See [Wistia Data API: Medias: Stats](https://wistia.com/doc/data-api#medias_stats)
 */
public struct WistiaMediaStats {

    /// The total number of times that the page containing the embedded video has been loaded.
    public var pageLoads: Int

    /// The number of unique visitors to the page containing the embedded video.
    public var visitors: Int

    /// This is an integer between 0 and 100 that shows what percentage of the time someone who saw the 
    /// page containing the embedded video played the video.
    public var percentOfVisitorsClickingPlay: Int

    /// The total number of times that the video has been played.
    public var plays: Int

    /// An integer between 0 and 100. It shows the average percentage of the video that was watched over 
    /// every time the video was played.
    public var averagePercentWatched: Int

}

extension WistiaMediaStats {

    /// Initialize a WistiaMediaStats from the provided JSON hash.
    ///
    /// - Note: Prints error message to console on parsing issue.
    ///
    /// - parameter dictionary: JSON hash representing the WistiaMediaStats.
    ///
    /// - returns: Initialized WistiaMediaStats if parsing is successful.
    init?(from dictionary: [String: Any]?) {
        guard dictionary != nil else { return nil }
        let parser = Parser(dictionary: dictionary)
        do {
            pageLoads = try parser.fetch("pageLoads")
            visitors = try parser.fetch("visitors")
            percentOfVisitorsClickingPlay = try parser.fetch("percentOfVisitorsClickingPlay")
            plays = try parser.fetch("plays")
            averagePercentWatched = try parser.fetch("averagePercentWatched")
        } catch let error {
            // NB: The stats returned by the private media info route do not match this object.
            // They will trigger this error branch but are not cause for concern.
            print(error)
            return nil
        }
    }
    
}
