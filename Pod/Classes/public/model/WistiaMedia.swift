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

    /// The display name of the media.
    public var name: String?

    /// Post upload processing status. There are four statuses: queued, processing, ready, and failed.
    public var status: WistiaObjectStatus

    /// An object representing the thumbnail for this media.
    public var thumbnail: Thumbnail?

    /// A struct holding the attributes of a thumbnail; URL, width, and height.
    public struct Thumbnail {
        public var url: String
        public var width: Int
        public var height: Int

        init?(from dictionary: [String: Any]) {
            let parser = Parser(dictionary: dictionary)
            do {
                url = try parser.fetch("url")
                width = try parser.fetch("width")
                height = try parser.fetch("height")
            } catch let error {
                print(error)
                return nil
            }
        }
    }

    /// Specifies the length (in seconds) for audio and video files. Specifies number of pages in the document. Omitted for other types of media.
    public var duration: Float?

    /// The date when the media was originally uploaded.
    public var created: Date?

    /// The date when the media was last changed.
    public var updated: Date?

    /// An array of the assets available for this media.
    public var assets: [WistiaAsset]

    /// A description for the media which usually appears near the top of the sidebar on the media's page.
    public var description: String?

    /// A unique alphanumeric identifier for this media.
    public var hashedID: String

    /// The visual and behavioral customizations to apply to this media
    public var embedOptions: WistiaMediaEmbedOptions?

    /// Aggregated tracking statistics for this video.
    /// - Note: Must be specifically retrieved through `WistiaAPI.statsForMedia(::)`
    public var stats: WistiaMediaStats?

    /**
     The URL serving the master index manifest for HLS streams.  This manifest includes references to all of the
     alternate HLS streams and is used by AVKit to dynamically choose the best stream for current conditions.
     
     The Wistia HLS alternate streams and master index manifest are engineered specificaly to satisfy Apple's 
     HLS requirements for the App Store.

     - Note: The Master index manifest may also be called the "manifest of manifests" in some places.
     
     - Warning: Not all `WistiaMedia` has HLS derivatives available yet.  Check that hasHlsAssets() is true; result of this URL is undefined otherwise.
     */
    public var hlsMasterIndexManifestURL: URL {
        get {
            return URL(string: "https://fast.wistia.net/embed/medias/\(self.hashedID).m3u8")!
        }
    }

    /**
     Returns true iff this media has at least one HLS asset.
     
     - Note: hlsMasterIndexManifestURL is valid for playback iff this returns true.
     **/
    public func hasHlsAssets() -> Bool {
        return assets.contains { $0.type.lowercased().contains("hls") }
    }

    // MARK: - ------------Internal------------
    var distilleryURLString: String?
    var accountKey: String?
    var mediaKey: String?
    var spherical: Bool?
    func isSpherical() -> Bool {
        return spherical ?? false
    }
    var distilleryURL: URL? {
        get {
            if let urlString = self.distilleryURLString, let url = URL(string: urlString) {
                return url
            } else {
                return nil
            }
        }
    }
    var captions: [WistiaCaptions]? = nil

    mutating func add(captions: [WistiaCaptions]) {
        self.captions = captions
    }

}

extension WistiaMedia: WistiaJSONParsable {


    /// Initialize a WistiaMedia and populate the assets hash from the provided JSON.
    ///
    /// - parameter dictionary: JSON hash representing the WistiaMedia.  May optionally include
    ///   a child hash of WistiaAssets.
    ///
    /// - returns: A newly initialized WistiaMedia if parsing is successful.
    static func create(from dictionary:[String: Any]) -> WistiaMedia? {

        if var wMedia = WistiaMedia(from: dictionary) {
            // -- Assets (are optional) --
            if let assetsDictionary = dictionary["assets"] as? [[String:Any]] {
                var wistiaAssets = [WistiaAsset]()
                for assetDictionary in assetsDictionary {
                    if let wistiaAsset = WistiaAsset(from: assetDictionary, forMedia: wMedia) {
                        wistiaAssets.append(wistiaAsset)
                    }
                }
                wMedia.assets = wistiaAssets
            }
            return wMedia
        } else {
            return nil
        }
    }

    /// Not public API.  Use WistiaMedia.create(from:).
    ///
    /// - Warning: Does not parse and attach child assets.
    fileprivate init?(from dictionary: [String: Any]) {
        let parser = Parser(dictionary: dictionary)
        do {
            if let s = parser.fetchOptional("status", transformation: { str in
                return WistiaObjectStatus(failsafeFromRawString: str)
            }) {
                status = s
            } else if let s = parser.fetchOptional("status", transformation: { integer in
                return WistiaObjectStatus(failsafeFromRaw: integer)
            }) {
                status = s
            } else {
                status = .failed
            }

            if let hid: String = try parser.fetchOptional("hashed_id") {
                hashedID = hid
            } else {
                hashedID = try parser.fetch("hashedId")
            }

            duration = try parser.fetchOptional("duration")
            name = try parser.fetchOptional("name")
            description = try parser.fetchOptional("description")
            created = parser.fetchOptional("created") { Parser.RFC3339DateFormatter.date(from: $0) }
            updated = parser.fetchOptional("updated") { Parser.RFC3339DateFormatter.date(from: $0) }
            spherical = try parser.fetchOptional("spherical")
            thumbnail = parser.fetchOptional("thumbnail") { WistiaMedia.Thumbnail(from: $0) }
            distilleryURLString = try parser.fetchOptional("distilleryUrl")
            accountKey = try parser.fetchOptional("accountKey")
            mediaKey = try parser.fetchOptional("mediaKey")
            embedOptions = parser.fetchOptional("embed_options") { WistiaMediaEmbedOptions(from: $0) }
            stats = parser.fetchOptional("stats") { WistiaMediaStats(from: $0) }
            assets = [WistiaAsset]()
            
        } catch let error {
            print(error)
            return nil
        }
    }
    
}

//MARK: - WistiaMedia Equality

extension WistiaMedia: Equatable { }

/**
 Compare two `WistiaMedia`s for equality.
 
 - Returns: `True` iff the `hashedID`s of the given `WistiaMedia`s match, statuses are the same,
    names are the same, descriptions are the same, and their embedOptions are equal.
 
 */
public func ==(lhs: WistiaMedia, rhs: WistiaMedia) -> Bool {

    return lhs.hashedID == rhs.hashedID &&
        lhs.status == rhs.status &&
        lhs.name == rhs.name &&
        lhs.description == rhs.description &&
        lhs.embedOptions == rhs.embedOptions
}
