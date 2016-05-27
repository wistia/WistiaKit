//
//  WistiaAPIMediaTests.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 5/19/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import XCTest
import WistiaKit

class WistiaAPIMediaTests: XCTestCase {
    
    let wAPI = WistiaAPI(apiToken:"1511ac67c0213610d9370ef12349c6ac828a18f6405154207b44f3a7e3a29e93")

    //MARK: - WistiaMedia

    //MARK: List

    func testListMediasByProject() {
        let expectation = expectationWithDescription("listed medias by project")

        wAPI.listMediasGroupedByProject { (projects) in
            if projects.count > 0 {
                if let medias = projects.first?.medias where medias.count > 0 {
                    //TODO: CHECK MEDIA DETAILS
                    expectation.fulfill()
                }
            }
        }

        waitForExpectationsWithTimeout(3, handler: nil)
    }

    //MARK: Show

    //MARK: Create

    //MARK: Update

    //MARK: Delete

    //MARK: Copy

    //MARK: Stats

    //MARK: - WistiaAsset
    //TODO: Dig in
    
    //MARK: - WistiaEmbedOptions
    //TODO: Dig in
    
    
    
    
}
