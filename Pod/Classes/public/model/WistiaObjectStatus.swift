//
//  WistiaObjectStatus.swift
//  Pods
//
//  Created by Daniel Spinosa on 4/26/16.
//
//

import Foundation

public enum WistiaObjectStatus: Int {
    case Failed = -1,
    Queued = 0,
    Processing = 1,
    Ready = 2
}

//Create initializer in extension so as to not lose default initializer
extension WistiaObjectStatus {

    //Returns .Failed if given an invalid raw value
    init(failsafeFromRaw raw: Int) {
        if let s = WistiaObjectStatus(rawValue: raw) {
            self = s
        } else {
            self = WistiaObjectStatus.Failed
        }
    }

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