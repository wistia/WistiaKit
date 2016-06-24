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

    internal static func _captionsForHash(hash:String, completionHandler: (captions:[WistiaCaptions])->() ) {
        Alamofire.request(.GET, "https://fast.wistia.com/embed/captions/\(hash).json", parameters: nil)
            .responseJSON { response in

                switch response.result {
                case .Success(let value):
                    if let JSON = value as? [String: AnyObject],
                        captionsJSONArray = JSON["captions"] as? [[String: AnyObject]]{

                        var captions = [WistiaCaptions]()
                        for captionsJSON in captionsJSONArray {
                            if let c = ModelBuilder.wistiaCaptionsFrom(captionsJSON) {
                                captions.append(c)
                            }
                        }
                        completionHandler(captions: captions)
                    }

                case .Failure:
                    //TODO: Incorporate error handling from public API
                    completionHandler(captions: [WistiaCaptions]())
                }
        }
        
    }

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