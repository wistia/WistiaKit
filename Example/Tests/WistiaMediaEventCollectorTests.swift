//
//  WistiaMediaEventCollectorTests.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 6/13/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import XCTest
@testable import WistiaKit

class WistiaMediaEventCollectorTests: XCTestCase {

    func testInitializerReturnsNilWithoutDistilleryURL() {
        let m = WistiaMedia(mediaID: nil, name: nil, status: .Ready, thumbnail: nil, duration: 33.33, created: nil, updated: nil, assets: [WistiaAsset](), description: nil, hashedID: "hash", embedOptions: nil, stats: nil, distilleryURLString: nil, accountKey: nil, mediaKey: nil, spherical: false, captions: nil)

        let collector = WistiaMediaEventCollector(media: m, referrer: "ref")
        XCTAssertNil(collector)
    }

    func testInitializesWithCorrectFormatting() {
        let m = WistiaMedia(mediaID: nil, name: nil, status: .Ready, thumbnail: nil, duration: 33.33, created: nil, updated: nil, assets: [WistiaAsset](), description: nil, hashedID: "hash", embedOptions: nil, stats: nil, distilleryURLString: "http://wistia.net", accountKey: "AK", mediaKey: "MK", spherical: false, captions: nil)

        let collector = WistiaMediaEventCollector(media: m, referrer: "ref")
        XCTAssertEqual(collector?.eventMetadata["media_duration"] as? String, "33.33")
        XCTAssertEqual(collector?.eventMetadata["account_key"] as? String, "AK")
        XCTAssertEqual(collector?.eventMetadata["media_id"] as? String, "MK")
        XCTAssertEqual(collector?.eventMetadata["referrer"] as? String, "ref")

        XCTAssertNotNil(collector?.eventMetadata["sdk_version"])
        XCTAssertNotNil(collector?.eventMetadata["event_key"])
        XCTAssertNotNil(collector?.eventMetadata["visitor_version"])
        XCTAssertNotNil(collector?.eventMetadata["session_id"])
    }
}