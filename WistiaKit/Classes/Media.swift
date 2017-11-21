//
//  Media.swift
//  Pods-WistiaKit_Example
//
//  Created by Daniel Spinosa on 10/17/17.
//

import AVKit

public struct Media: WistiaObject {
    public typealias object = Media

    //MARK: Codable Attributes
    public let id: String?

    public let type: MediaType?
    public enum MediaType: String, Codable {
        case video = "video"
        case pdf = "pdf_document"
        case image = "image"
    }

    public let attributes: Attributes?
    public struct Attributes: Codable {
        public let type: MediaType?
        public let name: String?
        public let description: String?
        public let projectId: String?
        public let duration: Float?
        public let position: Int?
        public let url: URL?
        public let aspectRatio: Float?

        enum CodingKeys: String, CodingKey {
            case type, name, description
            case projectId = "project_id"
            case duration, position, url
            case aspectRatio = "aspect_ratio"
        }
    }

    public let relationships: Relationships?
    public struct Relationships: Codable {
        public let storyboard: Storyboard?
        public struct Storyboard: Codable {
            public let id: URL?

            public init(from decoder: Decoder) throws {
                let container = try decoder.dataWrappedContainer(keyedBy: CodingKeys.self)
                id = try container?.decode(URL.self, forKey: .id)
            }
        }

        public let thumbnail: Thumbnail?
        public struct Thumbnail: Codable {
            public let id: URL?

            public init(from decoder: Decoder) throws {
                let container = try decoder.dataWrappedContainer(keyedBy: CodingKeys.self)
                id = try container?.decode(URL.self, forKey: .id)
            }
        }
    }

    //MARK: Convenience Attributes
    public var thumbnailURL: URL? {
        get {
            return relationships?.thumbnail?.id
        }
    }

    //MARK: Initialization

    //Used when showing a new media
    public init(id: String) {
        self.init(id: id, name: nil, description: nil, projectId: nil)
    }

    //Used when creating a new media
    public init(name: String? = nil, description: String? = nil, projectId: String? = nil) {
        self.init(id: nil, name: name, description: description, projectId: projectId)
    }

    internal init(id: String? = nil, name: String? = nil, description: String? = nil, projectId: String? = nil) {
        self.id = id
        self.type = nil
        self.attributes = Attributes(type: nil, name: name, description: description, projectId: projectId, duration: nil, position: nil, url: nil, aspectRatio: nil)
        self.relationships = nil
    }

}

//MARK: - Playback
extension Media {

    public struct AssetPlaybackOptions: OptionSet {
        public let rawValue: Int

        public init(rawValue: AssetPlaybackOptions.RawValue) {
            self.rawValue = rawValue
        }

        ///A .stream asset is not on disk nor in process of downloading (at time of return).
        ///There may be an equivalent asset available locally.  If you wish to allow playback
        ///using it (when available), pass .local in your asset playback options.
        public static let stream     = AssetPlaybackOptions(rawValue: 1 << 0)

        ///a local asset may be in the process of downloading or completely downloaded
        public static let local      = AssetPlaybackOptions(rawValue: 1 << 1)

        ///a downloaded asset is guaranteed to be on disk (such assets are a subset of .local assets)
        public static let downloaded = AssetPlaybackOptions(rawValue: 1 << 2)

        ///allow playback from streaming, local (downloading/downloaded), and fully downloaded assets
        public static let any: AssetPlaybackOptions = [.stream, .local, .downloaded]

        ///do not allow playback
        public static let none: AssetPlaybackOptions = []
    }

    public func hlsAsset(usingClient client: WistiaClient? = nil, assetPlaybackOptions: AssetPlaybackOptions = .any) -> AVAsset? {
        guard !assetPlaybackOptions.isEmpty, let id = self.id else { return nil }

        // .local (passed in any combination) will return an in process or completed downloaded
        if assetPlaybackOptions.contains(.local),
            let persistenceManager = (client ?? WistiaClient.default).persistenceManager,
            let asset = persistenceManager.asset(forMedia: self) {
            print("returning local asset")
            return asset
        }
        // .downloaded only returns a fully downloaded asset (a subset of .local)
        else if assetPlaybackOptions.contains(.downloaded),
            let persistenceManager = (client ?? WistiaClient.default).persistenceManager,
            let downloadedAsset = persistenceManager.localAsset(forMedia: self) {
            print("returning downloaded asset")
            return downloadedAsset
        }

        if assetPlaybackOptions.contains(.stream),
            let hlsURL = URL(string: "https://fast.wistia.net/embed/medias/\(id).m3u8") {
            //TODO: Confirm this Media has HLS Assets instead of assuming
            // ...once API V2 returns a media's assets or has some other way to accomplish it
            print("Returning streaming asset")
            return AVURLAsset(url: hlsURL)
        }

        return nil
    }

    public func hlsPlayerItem(usingClient client: WistiaClient? = nil, assetPlaybackOptions: AssetPlaybackOptions = .any) -> AVPlayerItem? {
        if let asset = hlsAsset(usingClient: client, assetPlaybackOptions: assetPlaybackOptions) {
            return AVPlayerItem(asset: asset)
        }
        return nil
    }
}

//MARK: - Persistence
extension Media {

    public enum DownloadState {
        case persistenceNotConfigured,
        persistenceNotAvailable,
        notDownloaded,
        downloading,
        downloaded
    }

    public func downloadState(usingClient client: WistiaClient? = nil) -> DownloadState {
        guard let persistenceManager = (client ?? WistiaClient.default).persistenceManager else { return .persistenceNotConfigured }

        return persistenceManager.downloadState(forMedia: self)
    }

    @discardableResult public func download(usingClient client: WistiaClient? = nil) -> DownloadState {
        guard let persistenceManager = (client ?? WistiaClient.default).persistenceManager else { return .persistenceNotConfigured }

        return persistenceManager.download(media: self)
    }

    @discardableResult public func cancelDownload(usingClient client: WistiaClient? = nil) -> DownloadState {
        guard let persistenceManager = (client ?? WistiaClient.default).persistenceManager else { return .persistenceNotConfigured }

        return persistenceManager.cancelDownload(media: self)
    }

    @discardableResult public func removeDownload(usingClient client: WistiaClient? = nil) -> DownloadState {
        guard let persistenceManager = (client ?? WistiaClient.default).persistenceManager else { return .persistenceNotConfigured }

        return persistenceManager.removeDownload(forMedia: self)
    }
}

//MARK: - Show
extension Media: WistiaClientShowable {
    public static let singularPath = "medias"
}

//MARK: - List
extension Media {
    public static func list(usingClient: WistiaClient? = nil, projectID: String, _ completionHander: @escaping (([Media]?, WistiaError?) -> ())) {
        let client = usingClient ?? WistiaClient.default
        let params = ["project_id": projectID]
        client.get("medias.json", parameters: params, completionHandler: completionHander)
    }
}

//MARK: - Create
extension Media: WistiaClientCreatable {
    public func create(usingClient: WistiaClient? = nil, _ completionHandler: @escaping ((Media?, WistiaError?) -> ())) {
        let client = usingClient ?? WistiaClient.default

        var params: [String: String] = [:]
        if let name = self.attributes?.name {
            params["name"] = name
        }
        if let description = self.attributes?.description {
            params["description"] = description
        }
        if let projectId = self.attributes?.projectId {
            params["project_id"] = projectId
        }
        //TODO: Add section_id when it's added to API v2

        client.post("medias", parameters: params, completionHandler: completionHandler)
    }
}
