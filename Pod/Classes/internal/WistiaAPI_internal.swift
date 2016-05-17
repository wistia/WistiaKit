//
//  WistiaAPI_internal.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 5/4/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import Foundation
import Alamofire

internal extension WistiaAPI {

    internal static func mediaInfoForHash(hash:String, completionHandler: (media:WistiaMedia?)->() ) {
        Alamofire.request(.GET, "https://fast.wistia.net/embed/medias/\(hash).json", parameters: nil)
            .responseJSON { response in

                if let JSON = response.result.value as? [String:AnyObject],
                    mediaHash = JSON["media"] as? [String:AnyObject] {

                    let wMedia = ModelBuilder.mediaFromHash(mediaHash)
                    completionHandler(media: wMedia)

                } else {
                    completionHandler(media: nil)
                }
        }
    }

    internal static func addSorting(sorting: (by: SortBy, direction: SortDirection)?, to params: [String: AnyObject]) -> [String: AnyObject] {
        var p = params
        if let sortBy = sorting?.by, sortDirection = sorting?.direction {
            p["sort_by"] = sortBy.rawValue
            p["sort_direction"] = sortDirection.rawValue
        }
        return p
    }

}