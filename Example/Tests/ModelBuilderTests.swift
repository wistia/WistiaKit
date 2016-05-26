//
//  ModelBuilderTests.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 5/26/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import XCTest
import WistiaKit

class ModelBuilderTests: XCTestCase {

    let wAPI = WistiaAPI(apiToken:"1511ac67c0213610d9370ef12349c6ac828a18f6405154207b44f3a7e3a29e93")

    //MARK: - Project

    func testProjectBuildsMediasWhenIncluded() {
        let expectation = expectationWithDescription("created project with media")

        wAPI.showProject("8q6efplb9n") { (project) in
            if let medias = project?.medias where medias.count > 0 {
                expectation.fulfill()
            }
        }

        waitForExpectationsWithTimeout(3, handler: nil)
    }

}
