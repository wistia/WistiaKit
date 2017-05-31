//
//  _URLExtensions.swift
//  Pods
//
//  Created by Daniel Spinosa on 3/22/17.
//
//

import Foundation

extension URL {

    internal func wk_changingQueryParemeter(_ name: String, to newValue: String) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        for (index, item) in (components?.queryItems?.enumerated())! {
            if item.name == name {
                components?.queryItems?[index] = URLQueryItem(name: name, value: newValue)
            }
        }
        return components?.url
    }

}
