//
//  _WistiaAPI.swift
//  WistiaKit internal
//
//  Created by Daniel Spinosa on 5/4/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import Foundation
import Alamofire

internal extension WistiaAPI {

    internal static func captions(for hash:String, completionHandler: @escaping (_ captions:[WistiaCaptions])->() ) {
        Alamofire.request("https://fast.wistia.com/embed/captions/\(hash).json", method: .get)
            .responseJSON { response in

                switch response.result {
                case .success(let value):
                    if let JSON = value as? [String: AnyObject],
                        let captionsJSONArray = JSON["captions"] as? [[String: AnyObject]]{

                        var captions = [WistiaCaptions]()
                        for captionsJSON in captionsJSONArray {
                            if let c = ModelBuilder.wistiaCaptions(from: captionsJSON) {
                                captions.append(c)
                            }
                        }
                        completionHandler(captions)
                    }

                case .failure:
                    completionHandler([WistiaCaptions]())
                }
        }
        
    }

    internal static func mediaInfo(for hash:String, completionHandler: @escaping (_ media:WistiaMedia?)->() ) {
        Alamofire.request("https://fast.wistia.net/embed/medias/\(hash).json", method: .get)
            .responseJSON { response in

                switch response.result {
                case .success(let value):
                    if let JSON = value as? [String:AnyObject],
                        let mediaHash = JSON["media"] as? [String:AnyObject] {

                        let wMedia = ModelBuilder.wistiaMedia(from: mediaHash)
                        completionHandler(wMedia)

                    } else {
                        completionHandler(nil)
                    }
                case .failure:
                    completionHandler(nil)
                }

        }
    }

    internal static func addSorting(_ sorting: (by: SortBy, direction: SortDirection)?, to params: [String: Any]) -> [String: Any] {
        var p = params
        if let sortBy = sorting?.by, let sortDirection = sorting?.direction {
            p["sort_by"] = sortBy.rawValue
            p["sort_direction"] = sortDirection.rawValue
        }
        return p
    }

}
