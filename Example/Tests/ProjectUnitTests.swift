//
//  ProjectUnitTests.swift
//  WistiaKit_Tests
//
//  Created by Daniel Spinosa on 10/31/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
@testable import WistiaKit

class ProjectUnitTests: XCTestCase {
    
    func testDecodeMinimalProjectResponse() {
        let x = XCTestExpectation()

        let projectJson = """
                        {"data":
                            {"id": "abc123"}
                        }
                        """
        let c = WistiaClient()
        c.handleDataTaskResult(data: projectJson.data(using: .utf8), urlResponse: nil, error: nil) { (project: Project?, error) in
            XCTAssertNotNil(project, error.debugDescription)
            x.fulfill()
        }

        wait(for: [x], timeout: 1)
    }

    func testDecodeFullProjectResponse() {
        let x = XCTestExpectation()

        let projectJson = "{\"data\":{\"id\":\"theid\",\"type\":\"project\",\"attributes\":{\"name\":\"the one\",\"media_count\":2,\"video_count\":2,\"type\":\"project\",\"locked\":false},\"relationships\":{\"sharing\":{\"data\":null}}}}"

        let c = WistiaClient()
        c.handleDataTaskResult(data: projectJson.data(using: .utf8), urlResponse: nil, error: nil) { (project: Project?, error) in
            XCTAssertNotNil(project, error.debugDescription)
            XCTAssertEqual(project?.id, "theid")

            XCTAssertNotNil(project?.attributes)
            XCTAssertEqual(project?.attributes?.name, "the one")
            XCTAssertEqual(project?.attributes?.mediaCount, 2)
            XCTAssertEqual(project?.attributes?.videoCount, 2)
            XCTAssertEqual(project?.attributes?.locked, false)

            x.fulfill()
        }

        wait(for: [x], timeout: 1)
    }

    func testDecodeProjectList() {
        let x = XCTestExpectation()

        let projectJson = """
                        {"data":
                            [{"id": "abc123"},{"id": "abc456"},{"id": "abc789"},{"id": "abc10"}]
                        }
                        """
        let c = WistiaClient()
        c.handleDataTaskResult(data: projectJson.data(using: .utf8), urlResponse: nil, error: nil) { (projects: [Project]?, error) in
            XCTAssertNotNil(projects, error.debugDescription)
            XCTAssertEqual(projects?.count, 4)
            XCTAssertEqual(projects?[0].id, "abc123")
            XCTAssertEqual(projects?[1].id, "abc456")
            XCTAssertEqual(projects?[2].id, "abc789")
            XCTAssertEqual(projects?[3].id, "abc10")
            x.fulfill()
        }

        wait(for: [x], timeout: 1)

    }
}
