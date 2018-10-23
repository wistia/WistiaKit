//
//  Project.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 10/31/17.
//

import Foundation

public struct Project: WistiaObject {
    public typealias object = Project

    //MARK: Codable Attributes
    public let id: String?

    public let attributes: Attributes?
    public struct Attributes: Codable {
        public let name: String
        public let mediaCount: Int
        public let videoCount: Int
        public let locked: Bool
    }
}

//MARK: List
extension Project: WistiaClientListable {
    public static let pluralPath = "projects.json"
}
