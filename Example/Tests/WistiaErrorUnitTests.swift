//
//  WistiaErrorUnitTests.swift
//  WistiaKit_Tests
//
//  Created by Daniel Spinosa on 10/18/17.
//  Copyright © 2017 Wistia. All rights reserved.
//

import XCTest
@testable import WistiaKit

class WistiaErrorUnitTests: XCTestCase {

    let x = XCTestExpectation()

    //response object *may* have both data and errors top level keys
    func testDataAndErrorResponse() {
        let doubleJson = """
                        {"data":
                            {"id": "abc123"},
                         "errors": [{
                            "code": "NotFound",
                            "message": "Z not found"
                         }]
                        }
                        """
        let c = WistiaClient()
        c.handleDataTaskResult(data: doubleJson.data(using: .utf8), urlResponse: nil, error: nil) { (media: Media?, error) in
            XCTAssertNotNil(error)
            XCTAssertNotNil(media)
            self.x.fulfill()
        }

        wait(for: [x], timeout: 1)
    }

    //reponse object must have data and/or errors top level keys
    func testUnexpectedResponse() {
        let unexpectedJson = "{\"foo\":\"bar\"}"
        let c = WistiaClient()
        c.handleDataTaskResult(data: unexpectedJson.data(using: .utf8), urlResponse: nil, error: nil) { (media: Media?, error) in
            XCTAssertNotNil(error)
            switch error! {
            case .badResponse(_):
                self.x.fulfill()
            default:
                XCTFail("Expected BadResponse Error")
            }
        }

        wait(for: [x], timeout: 1)
    }
    
    func testDecodeInvalidJSON() {
        let invalidJson = """
                        {"data":
                            "id": "abc123"}
                        }
                        """
        let c = WistiaClient()
        c.handleDataTaskResult(data: invalidJson.data(using: .utf8), urlResponse: nil, error: nil) { (media: Media?, error) in
            XCTAssertNotNil(error)
            switch error! {
            case .decodingError(_):
                self.x.fulfill()
            default:
                XCTFail("Expected Decoding Error")
            }
        }

        wait(for: [x], timeout: 1)
    }

    func testDataTaskProgrammingError(){
        let c = WistiaClient()
        c.handleDataTaskResult(data: nil, urlResponse: nil, error: nil) { (media: Media?, error) in
            XCTAssertNotNil(error)
            switch error! {
            case .unknown:
                self.x.fulfill()
            default:
                XCTFail("Expected BadResponse Error")
            }
        }

        wait(for: [x], timeout: 1)
    }
}
