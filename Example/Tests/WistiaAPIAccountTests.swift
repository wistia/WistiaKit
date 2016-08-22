//
//  WistiaAPIAccountTests.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 5/19/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import XCTest
import WistiaKit

class WistiaAPIAccountTests: XCTestCase {

    let wAPI = WistiaAPI(apiToken:"1511ac67c0213610d9370ef12349c6ac828a18f6405154207b44f3a7e3a29e93")

    //MARK: - Show
    func testShowAccount() {
        let expectation = self.expectation(description: "show account")

        wAPI.showAccount { (account) in
            if let a = account {
                if a.accountID == 445830 &&
                    a.name == "WistiaKitAutomatedTests" &&
                    a.accountURLString == "http://wistiakitautomatedtests.wistia.com" &&
                    a.accountURL == URL(string:"http://wistiakitautomatedtests.wistia.com") {
                    expectation.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

}
