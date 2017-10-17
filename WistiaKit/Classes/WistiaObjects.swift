//
//  WistiaObjects.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 10/17/17.
//

import Foundation

public protocol WistiaObject: Codable {
    typealias object = Self
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//          Protocols common to Wistia Objects
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

//MARK: - List
public protocol WistiaClientListable {
    associatedtype object: WistiaObject

    static func list(usingClient: WistiaClient?, _ completionHander: @escaping ((_ objects: [object]?, _ error: WistiaError?) -> ()))
}
//TOOD: Extension with default implementation of list?

//MARK: - show
public protocol WistiaClientShowable {
    associatedtype object: WistiaObject

    var id: String {get}
    static var singularPath: String {get}
    func show(usingClient: WistiaClient?, _ completionHander: @escaping ((_ object: object?, _ error: WistiaError?) -> ()))
}

public extension WistiaClientShowable {
    public func show(usingClient: WistiaClient? = nil, _ completionHander: @escaping ((Media?, WistiaError?) -> ())) {
        let client = usingClient ?? WistiaClient.default
        client.get("\(type(of: self).singularPath)/\(id).json", completionHandler: completionHander)
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//          Codable Extension
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

enum DataWrapperKey: String, CodingKey {
    case data = "data"
}

extension Decoder {
    // Some JSON is wrapped in a data dictionary:  {relationships: {data: {id: "https://wistia.com", name: "Title"}}}
    // The decoding process to flatten that is 1) get container for 'data', 2) get nested container for the actual CodingKeys, 3) decode
    // This method does steps 1 and 2, returning the inner container we can then use to do a flat decoding.
    func dataWrappedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        let dataContainer = try self.container(keyedBy: DataWrapperKey.self)
        let container = try dataContainer.nestedContainer(keyedBy: type, forKey: .data)
        return container
    }
}


