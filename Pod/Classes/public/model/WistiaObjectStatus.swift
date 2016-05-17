//
//  WistiaObjectStatus.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 4/26/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import Foundation

/**
 The post-upload processing status of a `WistiaMedia` and its corresponding `WistiaAsset` derivatives.
 
 - `Failed`: Processing failed; this media cannot be played.
 - `Queued`: Processing has not yet started.
 - `Processing`: Processing is underway but not yet complete.
 - `Ready`: Processing has completed successfuly.
 
 */
public enum WistiaObjectStatus: Int {
    /// Processing failed; this media cannot be played.
    case Failed = -1

    /// Processing has not yet started.
    case Queued = 0

    /// Processing is underway but not yet complete.
    case Processing = 1

    /// Processing has completed successfuly.
    case Ready = 2
}

//Create initializer in extension so as to not lose default initializer
extension WistiaObjectStatus {

    /**
     Initialize a `WistiaObjectStatus` from an Int value.
     
     - Returns: The `WistiaObjectStatus` corresponding to int from -1 through 2, `.Failed` for all other values.
    */
    init(failsafeFromRaw raw: Int) {
        if let s = WistiaObjectStatus(rawValue: raw) {
            self = s
        } else {
            self = WistiaObjectStatus.Failed
        }
    }

    /**
     Initialize a `WistiaObjectStatus` from a String value.  String should be lowercase and should match
     the spelling of a case in this enum.

     - Returns: The `WistiaObjectStatus` corresponding to lowercase String that matches its symbol;
     `.Failed` for all other strings.
     */
    init(failsafeFromRawString rawString: String) {
        switch rawString {
        case "failed":
            self = Failed
        case "queued":
            self = Queued
        case "processing":
            self = Processing
        case "ready":
            self = Ready
        default:
            self = Failed
        }
    }
}
