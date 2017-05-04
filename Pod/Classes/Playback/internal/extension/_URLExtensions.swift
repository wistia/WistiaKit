//
//  _URLExtensions.swift
//  Pods
//
//  Created by Adam Jensen on 5/4/17.
//
//

extension URL {
    public func deletingQuery() -> URL? {
        if let components = NSURLComponents(url: self, resolvingAgainstBaseURL: false) {
            components.query = nil
            return components.url
        }
        return nil
    }
}
