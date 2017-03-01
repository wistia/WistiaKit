//
//  WistiaAPIUploadTests.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 11/18/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest
import WistiaKitData
import WistiaKit

class WistiaAPIUploadTests: XCTestCase {

    let unlimitedAPI = WistiaAPI(apiToken:"1511ac67c0213610d9370ef12349c6ac828a18f6405154207b44f3a7e3a29e93")
    let limitedAPI = WistiaAPI(apiToken: "dcb0e1179609d1da5cf1698797fdb205ff783d428414bab13ec042102e53e159")

    let fileURL = Bundle(for: WistiaAPIUploadTests.self).url(forResource: "clipXS", withExtension: "m4v")!

    func testSuccessfulUpload() {
        let expectation = self.expectation(description: "file uploaded")

        unlimitedAPI.upload(fileURL: fileURL, intoProject: nil, name: nil, description: nil, contactID: nil, progressHandler: nil)
        { media, error in
            XCTAssert(error == nil && media != nil)
            self.unlimitedAPI.deleteMedia(forHash: media!.hashedID) { media, error in }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 20, handler: nil)
    }

    func testVideoLimitUpload() {
        let expectation = self.expectation(description: "file upload fails with VideoLimit")

        limitedAPI.upload(fileURL: fileURL, intoProject: nil, name: nil, description: nil, contactID: nil, progressHandler: nil)
        { media, error in
            XCTAssert(media == nil && error != nil)
            switch error! {
            case .VideoLimit(_):
                expectation.fulfill()
            default:
                XCTAssert(false, "Expected VideoLimit Error")
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

}
