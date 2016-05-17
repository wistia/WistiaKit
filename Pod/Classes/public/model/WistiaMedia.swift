//
//  WistiaMedia.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 1/25/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import Foundation

/**
 A conceptual entity corresponding to a video uploaded to Wistia.  A `WistiaMedia` is
 processed into may derivatives which are represented by `WistiaAsset`s.

 - Note: Some of the attributes in this struct are obtained through an internal API different from the
 public Data API.  These attributes are undocumented and marked internal.

 See [Wistia Data API: Media](http://wistia.com/doc/data-api#medias_response)
 */
public struct WistiaMedia {

    /// A unique numeric identifier for the media within the system.
    public var mediaID: Int?

    /// The display name of the media.
    public var name: String?

    /// Post upload processing status. There are four statuses: queued, processing, ready, and failed.
    var status: WistiaObjectStatus

    /// An object representing the thumbnail for this media. The attributes are URL, width, and height.
    public var thumbnail: (url: String, width: Int, height: Int)?

    /// Specifies the length (in seconds) for audio and video files. Specifies number of pages in the document. Omitted for other types of media.
    var duration: Float

    /// An array of the assets available for this media.
    public var assets: [WistiaAsset]

    /// A description for the media which usually appears near the top of the sidebar on the media's page.
    public var description: String?

    /// A unique alphanumeric identifier for this media.
    public var hashedID: String

    // MARK: - ------------Internal------------
    var distilleryURLString: String?
    var accountKey: String?
    var mediaKey: String?
    var spherical: Bool
    var embedOptions: WistiaMediaEmbedOptions?
    var distilleryURL: NSURL? {
        get {
            if let urlString = self.distilleryURLString, url = NSURL(string: urlString) {
                return url
            } else {
                return nil
            }
        }
    }

}

extension WistiaMedia: Equatable { }

/**
 Compare two `WistiaMedia`s for equality.
 
 - Returns: `True` if the `hashedID`s of the given `WistiaMedia`s match.
 
 */
public func ==(lhs: WistiaMedia, rhs: WistiaMedia) -> Bool {

    return lhs.hashedID == rhs.hashedID
}
