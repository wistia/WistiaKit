//
//  WistiaAsset.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 1/25/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import Foundation

/**
 Represents one of the many actual files backing a `WistiaMedia`.
 
 - Note: Some of the attributes in this struct are obtained through an internal API different from the
 public Data API.  These attributes are undocumented and marked internal.

 See [Wistia Data API: Asset](http://wistia.com/doc/data-api#asset_object_response)
 */
public struct WistiaAsset {

    /// The `WistiaMedia` this is a derivative of.
    public var media: WistiaMedia

    /// A direct-access URL to the content of the asset (as a String).
    public var urlString: String

    /// A direct-access URL to the content of the asset.
    public var url: URL {
        get {
            return URL(string: self.urlString)!
        }
    }

    /// The width of this specific asset, if applicable.
    public var width: Int64

    /// The height of this specific asset, if applicable.
    public var height: Int64

    /// The size of the asset file that's referenced by url, measured in bytes.
    public var size: Int64?

    /// The internal type of the asset, describing how the asset should be used. Values can include OriginalFile, FlashVideoFile, MdFlashVideoFile, HdFlashVideoFile, Mp4VideoFile, MdMp4VideoFile, HdMp4VideoFile, IPhoneVideoFile, StillImageFile, SwfFile, Mp3AudioFile, and LargeImageFile.
    public var type: String

    /// The status of this asset
    public var status: WistiaObjectStatus?

    // MARK: - ------------Internal------------
    internal var slug: String?
    internal var displayName: String?
    internal var container: String?
    internal var codec: String?
    internal var ext: String?
    internal var bitrate: Int64?
}

extension WistiaAsset {

    /// Initialize a WistiaAsset from the provided JSON hash.  It is unlikely you would use this
    /// method directly as assets are generally returned inside of their parent WistiaMedia.  Instead,
    /// see WistiaMedia.create(from:).
    ///
    /// - seealso: WistiaMedia.create(from:)
    ///
    /// - Note: Prints error message to console on parsing issue.
    ///
    /// - parameter dictionary: JSON hash representing the WistiaAsset.
    /// - parameter media: The owning WistiaMedia to which this asset belongs.
    ///
    /// - returns: Initialized WistiaAsset if parsing is successful.
    init?(from dictionary: [String: Any], forMedia media:WistiaMedia) {
        let parser = Parser(dictionary: dictionary)
        do {
            self.media = media

            urlString = try parser.fetch("url")
            width = try parser.fetch("width", transformation: { (w:Int) in Int64(w) })
            height = try parser.fetch("height", transformation: { (h:Int) in Int64(h) })
            type = try parser.fetch("type")

            size = try parser.fetchOptional("size", transformation: { (s:Int) in Int64(s) })
            if size == nil {
                size = try parser.fetchOptional("filesize", transformation: { (s:Int) in Int64(s) })
            }

            displayName = try parser.fetchOptional("display_name")
            container = try parser.fetchOptional("container")
            codec = try parser.fetchOptional("codec")
            ext = try parser.fetchOptional("ext")
            bitrate = try parser.fetchOptional("bitrate", transformation: { (b:Int) in Int64(b) })
            status = try parser.fetchOptional("status") { WistiaObjectStatus(failsafeFromRaw: $0) }
            slug = try parser.fetchOptional("slug")

        } catch let error {
            print(error)
            return nil
        }
    }
    
}
