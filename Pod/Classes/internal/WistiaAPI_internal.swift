//
//  WistiaAPI_internal.swift
//  Pods
//
//  Created by Daniel Spinosa on 5/4/16.
//
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
    
}