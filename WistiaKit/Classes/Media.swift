//
//  Media.swift
//  Pods-WistiaKit_Example
//
//  Created by Daniel Spinosa on 10/17/17.
//

import Foundation

//MARK: - Media
public struct Media: WistiaObject, WistiaClientShowable {

    //MARK: API Configuration
    public static let singularPath = "medias"

    //MARK: Codable Attributes
    public let id: String

    public let type: MediaType?
    public enum MediaType: String, Codable {
        case video = "video"
    }

    public let attributes: Attributes?
    public struct Attributes: Codable {
        public let type: MediaType
        public let name: String
        public let description: String
        public let projectId: String
        public let duration: Float?
        public let position: Int
        public let url: URL
        public let aspectRatio: Float

        enum CodingKeys: String, CodingKey {
            case type, name, description
            case projectId = "project_id"
            case duration, position, url
            case aspectRatio = "aspect_ratio"
        }
    }

    public let relationships: Relationships?
    public struct Relationships: Codable {
        public let storyboard: Storyboard
        public struct Storyboard: Codable {
            public let id: URL

            public init(from decoder: Decoder) throws {
                let container = try decoder.dataWrappedContainer(keyedBy: CodingKeys.self)
                id = try container.decode(URL.self, forKey: .id)
            }
        }

        public let thumbnail: Thumbnail
        public struct Thumbnail: Codable {
            public let id: URL

            public init(from decoder: Decoder) throws {
                let container = try decoder.dataWrappedContainer(keyedBy: CodingKeys.self)
                id = try container.decode(URL.self, forKey: .id)
            }
        }
    }

    //MARK: Convenience Attributes
    public var thumbnailURL: URL? {
        get {
            return relationships?.thumbnail.id
        }
    }

    //MARK: Initialization
    public init(id: String) {
        self.id = id
        self.type = nil
        self.attributes = nil
        self.relationships = nil
    }

    //MARK: Custom API implementations
    public static func list(usingClient: WistiaClient? = nil, projectID: String, _ completionHander: @escaping (([Media]?, WistiaError?) -> ())) {
        let client = usingClient ?? WistiaClient.default
        let params = ["project_id": projectID]
        client.get("medias.json", parameters: params, completionHandler: completionHander)
    }

    //using default protocol extension implementation for show(...)
}


