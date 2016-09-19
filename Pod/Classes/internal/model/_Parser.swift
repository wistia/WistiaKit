//
//  _Parser.swift
//  Pods
//
//  Created by Daniel Spinosa on 9/16/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//
//  Type safe JSON parser

import Foundation

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

    func fetchOptional<T>(_ key: String, default defaultValue: T) throws -> T {
        return try fetchOptional(key) ?? defaultValue
    }

    func fetchOptional<T, U>(_ key: String, transformation: (T) -> U?) -> U? {
        return (dictionary?[key] as? T).flatMap(transformation)
    }

    //MARK: - fetchArray

    func fetchArray<T, U>(_ key: String, transformation: (T) -> U?) throws -> [U] {
        let fetched: [T] = try fetch(key)
        return fetched.flatMap(transformation)
    }

    func fetchArrayOptional<T, U>(_ key: String, transformation: (T) -> U?) throws -> [U]? {
        if let fetched: [T] = try fetchOptional(key) {
            return fetched.flatMap(transformation)
        } else {
            return nil
        }
    }
}

struct ParserError: Error {
    let message: String
}

//TODO: Move inside Parser
internal let RFC3339DateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale!
    df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    return df
}()
