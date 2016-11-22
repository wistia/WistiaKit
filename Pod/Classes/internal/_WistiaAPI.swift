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

    internal static func captions(for hash:String, completionHandler: @escaping (_ captions: [WistiaCaptions], _ error: WistiaAPIError?)->() ) {
        Alamofire.request("https://fast.wistia.com/embed/captions/\(hash).json", method: .get)
            .responseJSON { response in

                if response.response?.statusCode == 200,
                    let JSON = response.result.value as? [String: Any] {
                    guard let captionsJSONArray = JSON["captions"] as? [[String: Any]] else {
                        return completionHandler([], WistiaAPIError.JSONDecodingFailure(JSON, WistiaCaptions.self))
                    }

                    var captions = [WistiaCaptions]()
                    for captionsJSON in captionsJSONArray {
                        guard let c = WistiaCaptions(from: captionsJSON) else {
                            return completionHandler([], WistiaAPIError.JSONDecodingFailure(captionsJSON, WistiaCaptions.self))
                        }
                        captions.append(c)
                    }
                    completionHandler(captions, nil)

                }
                else {
                    completionHandler([], WistiaAPIError.error(for: response))
                }
        }
        
    }

    /// Domain Restrictions enforces HTTP Referer on this route
    internal static func mediaInfo(for hash:String, referer:String? = nil, completionHandler: @escaping (_ media: WistiaMedia?, _ error: WistiaAPIError?)->() ) {
        var headers = [String: String]()
        if let ref = referer {
            headers["Referer"] = ref
        }

        Alamofire.request("https://fast.wistia.net/embed/medias/\(hash).json", method: .get, headers: headers)
            .responseJSON { response in

                if response.response?.statusCode == 200,
                    let JSON = response.result.value as? [String: Any] {

                    if let mediaHash = JSON["media"] as? [String:Any] {
                        if let wMedia = WistiaMedia.create(from: mediaHash) {
                            completionHandler(wMedia, nil)
                        }
                        else {
                            completionHandler(nil, WistiaAPIError.JSONDecodingFailure(JSON, WistiaMedia.self))
                        }
                    }
                    else {
                        completionHandler(nil, WistiaAPIError.error(for: response))
                    }

                }
                else {
                    completionHandler(nil, WistiaAPIError.error(for: response))
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

//MARK: - Errors

internal extension WistiaAPIError {

    internal static func error(for response: DataResponse<Any>) -> WistiaAPIError {
        switch(response.result) {

        case.success(let value):
            if let JSON = response.result.value as? [String: Any] {
                if let errorString = JSON["error"] as? String {
                    if errorString.contains("video limit") {
                        // Upload video limit fail
                        return WistiaAPIError.VideoLimit(errorString)
                    }
                    else {
                        // JSON had error key but we haven't yet differentiated on it
                        return WistiaAPIError.ErrorWithExplanation(errorString)
                    }
                }
                // Metadata request fail
                else if let errorBool = JSON["error"] as? Bool, errorBool,
                    let iframeBool = JSON["iframe"] as? Bool, iframeBool {
                    return WistiaAPIError.ErrorWithExplanation("Hashed ID Not Found")
                }
                // Got JSON, coldn't parse an error out of it
                else {
                    return WistiaAPIError.ErrorWithExplanation("Unexpected error JSON: \(JSON)")
                }
            }
            else {
                // JSON was not returned as expected
                return WistiaAPIError.InvalidJSON(value)
            }

        case .failure(_):
            if response.response?.statusCode == 503 {
                // Rate Limit
                var retryAfter: Int? = nil
                if let ra = response.response?.allHeaderFields["Retry-After"] as? Int {
                    retryAfter = ra
                }
                return WistiaAPIError.RateLimit(retryAfterSeconds: retryAfter)
            }
            else if response.response?.statusCode == 400 {
                print("TODO: anything interesting inside this 400? \(response)")
            }
            else if let data = response.data {
                return WistiaAPIError.UnexpectedDataResponse(data)
            }

            break
        }

        return WistiaAPIError.Unknown(response.result.error)
    }


}
