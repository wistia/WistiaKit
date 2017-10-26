//
//  Media.swift
//  Pods-WistiaKit_Example
//
//  Created by Daniel Spinosa on 10/17/17.
//

import Foundation

//MARK: - Media
public struct Media: WistiaObject {

    //MARK: Codable Attributes
    public let id: String?

    public let type: MediaType?
    public enum MediaType: String, Codable {
        case video = "video"
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
    public init(id: String? = nil, name: String? = nil, description: String? = nil, projectId: String? = nil) {
        self.id = nil
        self.type = nil
        self.attributes = Attributes(type: nil, name: name, description: description, projectId: projectId, duration: nil, position: nil, url: nil, aspectRatio: nil)
        self.relationships = nil
    }
}

//MARK: - Custom API implementations

//MARK: Show
extension Media: WistiaClientShowable {

    public static let singularPath = "medias"
}

//MARK: List
extension Media {
    public static func list(usingClient: WistiaClient? = nil, projectID: String, _ completionHander: @escaping (([Media]?, WistiaError?) -> ())) {
        let client = usingClient ?? WistiaClient.default
        let params = ["project_id": projectID]
        client.get("medias.json", parameters: params, completionHandler: completionHander)
    }
}

//MARK: Create
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
