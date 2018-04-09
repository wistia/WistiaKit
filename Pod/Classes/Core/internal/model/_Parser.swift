//
//  _Parser.swift
//  Pods
//
//  Created by Daniel Spinosa on 9/16/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//
//  Type safe JSON parser

import Foundation

/// An empty protocol to signal that an object (class, struct, enum) may be created
/// by parsing JSON (typically a JSON reponse from the Wistia API).
/// The parsing is often wrapped in an initializer, but need not be.
public protocol WistiaJSONParsable {}

struct Parser {
    let dictionary: [String: Any]?

    init(dictionary: [String: Any]?) {
        self.dictionary = dictionary
    }

    //MARK: - fetch

    func fetch<T>(_ key: String) throws -> T {
        let fetchedOptional = dictionary?[key]
        guard let fetched = fetchedOptional else  {
            throw ParserError(message: "The key '\(key)' was not found.")
        }
        guard let typed = fetched as? T else {
            throw ParserError(message: "The key '\(key)' was not the right type. It had value '\(fetched).'")
        }
        return typed
    }

    // Special case Float
    // NSNumber bridging/casting is updated with Xcode 9.3 (Swift 4.1 and 3.3)
    // see https://github.com/apple/swift-evolution/blob/master/proposals/0170-nsnumber_bridge.md
    func fetch(_ key: String) throws -> Float {
        let fetchedOptional = dictionary?[key]
        guard let fetched = fetchedOptional else  {
            throw ParserError(message: "The key '\(key)' was not found.")
        }
        guard let typed = fetched as? NSNumber else {
            throw ParserError(message: "The key '\(key)' was not an NSNumber (to be converted to Float). It had value '\(fetched).'")
        }
        return typed.floatValue
    }

    func fetch<T, U>(_ key: String, transformation: (T) -> U?) throws -> U {
        let fetched: T = try fetch(key)
        guard let transformed = transformation(fetched) else {
            throw ParserError(message: "The value '\(fetched)' at key '\(key)' could not be transformed.")
        }
        return transformed
    }

    //MARK: - fetchOptional

    func fetchOptional<T>(_ key: String) throws -> T? {
        let fetchedOptional = dictionary?[key]
        guard let fetched = fetchedOptional else {
            return nil
        }
        guard let typed = fetched as? T else {
            if let _ = fetched as? NSNull {
                return nil
            }
            throw ParserError(message: "The key '\(key)\' was not the right type. It had value '\(fetched).'")
        }
        return typed
    }

    // Special case Float
    // NSNumber bridging/casting is updated with Xcode 9.3 (Swift 4.1 and 3.3)
    // see https://github.com/apple/swift-evolution/blob/master/proposals/0170-nsnumber_bridge.md
    func fetchOptional(_ key: String) throws -> Float? {
        let fetchedOptional = dictionary?[key]
        guard let fetched = fetchedOptional else {
            return nil
        }
        guard let typed = fetched as? NSNumber else {
            if let _ = fetched as? NSNull {
                return nil
            }
            throw ParserError(message: "The key '\(key)\' was not an NSNumber (to be coverted to Float). It had value '\(fetched).'")
        }
        return typed.floatValue
    }

    func fetchOptional<T>(_ key: String, default defaultValue: T) throws -> T {
        return try fetchOptional(key) ?? defaultValue
    }

    func fetchOptional<T, U>(_ key: String, transformation: (T) -> U?) -> U? {
        return (dictionary?[key] as? T).flatMap(transformation)
    }

    func fetchOptional<T, U>(_ key: String, default defaultValue: U, transformation: (T) -> U?) -> U {
        return fetchOptional(key, transformation: transformation) ?? defaultValue
    }

    //MARK: - fetchArray

    func fetchArray<T, U>(_ key: String, transformation: (T) -> U?) throws -> [U] {
        let fetched: [T] = try fetch(key)
        return fetched.compactMap(transformation)
    }

    func fetchArrayOptional<T, U>(_ key: String, transformation: (T) -> U?) throws -> [U]? {
        if let fetched: [T] = try fetchOptional(key) {
            return fetched.compactMap(transformation)
        } else {
            return nil
        }
    }

    static let RFC3339DateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale?
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return df
    }()
}

struct ParserError: Error {
    let message: String
}
