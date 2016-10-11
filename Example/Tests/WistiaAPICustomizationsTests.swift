//
//  WistiaAPICustomizationsTests.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 10/11/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest
@testable import WistiaKit

class WistiaAPICustomizationsTests: XCTestCase {

    let wAPI = WistiaAPI(apiToken:"1511ac67c0213610d9370ef12349c6ac828a18f6405154207b44f3a7e3a29e93")

    //MARK: - Show
    func testShowCustomizations() {
        let expectation = self.expectation(description: "show customizations")

        wAPI.showCustomizations(forHash: "2egno8swf1") { embedOptions in
            if let _ = embedOptions {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    //MARK: - Create
    func testWistiaMediaEmbedOptionsToJson() {
        let e = WistiaMediaEmbedOptions(playerColor: UIColor(red: 0.18, green: 0.33, blue: 0.99, alpha: 1.0), bigPlayButton: false, smallPlayButton: true, playbar: true, fullscreenButton: false, controlsVisibleOnLoad: true, autoplay: true, endVideoBehaviorString: "pause", endVideoBehavior: .pauseOnLastFrame, stillURL: URL(string:"http://image.com"),

                                        actionButton: true, actionShareURLString: "http://sharethis.com", actionShareTitle: "sharing is caring",

                                        captionsAvailable: true, captionsOnByDefault: false)


        let json = e.toJson()

        XCTAssertEqual(json["playerColor"] as! String, "#2D54FC")
        XCTAssertEqual(json["playButton"] as! Bool, false)
        XCTAssertEqual(json["smallPlayButton"] as! Bool, true)
        XCTAssertEqual(json["playbar"] as! Bool, true)
        XCTAssertEqual(json["fullscreenButton"] as! Bool, false)
        XCTAssertEqual(json["controlsVisibleOnLoad"] as! Bool, true)
        XCTAssertEqual(json["autoPlay"] as! Bool, true)
        XCTAssertEqual(json["endVideoBehavior"] as! String, "pause")
        XCTAssertEqual(json["stillUrl"] as! String, "http://image.com")

        let share = json["share"] as! [String: Any?]
        XCTAssertEqual(share["on"] as! Bool, true)
        XCTAssertEqual(share["pageUrl"] as! String, "http://sharethis.com")
        XCTAssertEqual(share["pageTitle"] as! String, "sharing is caring")

        let captions = json["captions-v1"] as! [String: Any?]
        XCTAssertEqual(captions["on"] as! Bool, true)
        XCTAssertEqual(captions["onByDefault"] as! Bool, false)
    }

    func testCreateCustomizations() {
        let e = WistiaMediaEmbedOptions(playerColor: UIColor(red: 0.18, green: 0.33, blue: 0.99, alpha: 1.0), bigPlayButton: false, smallPlayButton: true, playbar: true, fullscreenButton: false, controlsVisibleOnLoad: true, autoplay: true, endVideoBehaviorString: "pause", endVideoBehavior: .pauseOnLastFrame, stillURL: URL(string:"http://image.com"), actionButton: true, actionShareURLString: "http://sharethis.com", actionShareTitle: "sharing is caring",captionsAvailable: true, captionsOnByDefault: false)

        let expectation = self.expectation(description: "create customizations")

        wAPI.createCustomizations(e, forHash: "2egno8swf1") { embedOptions in
            if let createdOptions = embedOptions,
                createdOptions.bigPlayButton == e.bigPlayButton,
                createdOptions.fullscreenButton == e.fullscreenButton,
                createdOptions.autoplay == e.autoplay,
                createdOptions.endVideoBehavior == e.endVideoBehavior {
                expectation.fulfill()
            } else {
                XCTFail("Embed Options should be returned")
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }


    //MARK: - Delete

    func testDeleteCustomizations() {
        let expectation = self.expectation(description: "delete customizations")

        wAPI.deleteCustomizations(forHash: "2egno8swf1") { success in
            if success {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }
    
}
