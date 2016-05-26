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
    public var status: WistiaObjectStatus

    /// An object representing the thumbnail for this media. The attributes are URL, width, and height.
    public var thumbnail: (url: String, width: Int, height: Int)?

    /// Specifies the length (in seconds) for audio and video files. Specifies number of pages in the document. Omitted for other types of media.
    public var duration: Float

    /// The date when the media was originally uploaded.
    public var created: NSDate?

    /// The date when the media was last changed.
    public var updated: NSDate?

    /// An array of the assets available for this media.
    public var assets: [WistiaAsset]

    /// A description for the media which usually appears near the top of the sidebar on the media's page.
    public var description: String?

    /// A unique alphanumeric identifier for this media.
    public var hashedID: String

    /// The visual and behavioral customizations to apply to this media
    public var embedOptions: WistiaMediaEmbedOptions?

    /**
     The URL serving the master index manifest for HLS streams.  This manifest includes references to all of the
     alternate HLS streams and is used by AVKit to dynamically choose the best stream for current conditions.
     
     The Wistia HLS alternate streams and master index manifest are engineered specificaly to satisfy Apple's 
     HLS requirements for the App Store.

     - Note: The Master index manifest may also be called the "manifest of manifests" in some places.
     
     - Note: Not all `WistiaMedia` has HLS derivatives available yet.
     */
    public var hlsMasterIndexManifestURL: NSURL {
        get {
            return NSURL(string: "https://fast.wistia.net/embed/medias/\(self.hashedID).m3u8")!
        }
    }

    // MARK: - ------------Internal------------
    var distilleryURLString: String?
    var accountKey: String?
    var mediaKey: String?
    var spherical: Bool
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

//MARK: - WistiaMedia Equality

extension WistiaMedia: Equatable { }

/**
 Compare two `WistiaMedia`s for equality.
 
 - Returns: `True` if the `hashedID`s of the given `WistiaMedia`s match.
 
 */
public func ==(lhs: WistiaMedia, rhs: WistiaMedia) -> Bool {

    return lhs.hashedID == rhs.hashedID
}
