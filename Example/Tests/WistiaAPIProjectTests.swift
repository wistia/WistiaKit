//
//  WistiaAPIProjectTests.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 5/19/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import XCTest
import WistiaKit

class WistiaAPIProjectTests: XCTestCase {
    
    let wAPI = WistiaAPI(apiToken:"1511ac67c0213610d9370ef12349c6ac828a18f6405154207b44f3a7e3a29e93")

    //MARK: - WistiaProject

    //MARK: - List

    //MARK: Basic

    func testListProjects() {
        let expectation = expectationWithDescription("listed projects")

        wAPI.listProjects { (projects) in
            if projects.count > 0 {
                expectation.fulfill()
            }
        }

        waitForExpectationsWithTimeout(3, handler: nil)
    }

    //MARK: Sorting

    func testSortByCreatedAscending() {
        let expectation = expectationWithDescription("sorted properly")

        wAPI.listProjects(page: 1, perPage: 100, sorting: (by: WistiaAPI.SortBy.Created, direction: WistiaAPI.SortDirection.Ascending)) { (projects) in
            let sortedProjects = projects.sort({ (pa, pb) -> Bool in
                return pa.created!.compare(pb.created!) == NSComparisonResult.OrderedAscending
            })

            if projects.count == sortedProjects.count {
                var allGood = true
                for (i, _) in projects.enumerate() {
                    if projects[i] != sortedProjects[i] {
                        allGood = false
                    }
                }
                if allGood {
                    expectation.fulfill()
                }
            }
        }

        waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testSortByCreatedDescending() {
        let expectation = expectationWithDescription("sorted properly")

        wAPI.listProjects(page: 1, perPage: 100, sorting: (by: WistiaAPI.SortBy.Created, direction: WistiaAPI.SortDirection.Descending)) { (projects) in
            let sortedProjects = projects.sort({ (pa, pb) -> Bool in
                return pa.created!.compare(pb.created!) == NSComparisonResult.OrderedDescending
            })

            if projects.count == sortedProjects.count {
                var allGood = true
                for (i, _) in projects.enumerate() {
                    if projects[i] != sortedProjects[i] {
                        allGood = false
                    }
                }
                if allGood {
                    expectation.fulfill()
                }
            }
        }

        waitForExpectationsWithTimeout(3, handler: nil)
    }

    //MARK: Paging

    func testPageTwo() {
        let expectation = expectationWithDescription("pulled second page")

        wAPI.listProjects(page: 1, perPage: 1, sorting: (by: WistiaAPI.SortBy.Created, direction: WistiaAPI.SortDirection.Ascending)) { (projectsP1) in
            if projectsP1.count == 1 {
                self.wAPI.listProjects(page: 2, perPage: 1, sorting: (by: WistiaAPI.SortBy.Created, direction: WistiaAPI.SortDirection.Ascending), completionHandler: { (projectsP2) in
                    if projectsP2.count == 1 && projectsP1.first?.hashedID != projectsP2.first?.hashedID {
                        expectation.fulfill()
                    }
                })
            }
        }

        waitForExpectationsWithTimeout(6, handler: nil)
    }

    //MARK: - Show

    func testShowProject() {
        let expectation = expectationWithDescription("created project with media")

        wAPI.showProject("8q6efplb9n") { (project) in
            if project != nil {
                expectation.fulfill()
            }
        }

        waitForExpectationsWithTimeout(3, handler: nil)
    }

    //MARK: - Create

    static var tempProjectHashedID: String? = nil

    func testACreateProject() {
        let expectation = expectationWithDescription("created a project")

        wAPI.createProject("TestProject@\(NSDate())", adminEmail: nil, anonymousCanUpload: false, anonymousCanDownload: false, isPublic: false) { (project) in
            if let p = project {
                WistiaAPIProjectTests.tempProjectHashedID = p.hashedID
                expectation.fulfill()
            }
        }

        waitForExpectationsWithTimeout(3, handler: nil)
    }

    //MARK: - Update

    func testBUpdateProject() {
        guard let hashedID = WistiaAPIProjectTests.tempProjectHashedID else { XCTFail("prerequisite fail: no project"); return }

        let expectation = expectationWithDescription("updated the project")
        
        wAPI.updateProject(hashedID, name: nil, anonymousCanUpload: true, anonymousCanDownload: true, isPublic: false) { (success, project) in
            if let p = project where success && p.anonymousCanDownload && !p.isPublic {
                expectation.fulfill()
            }
        }

        waitForExpectationsWithTimeout(3, handler: nil)
    }

    //MARK: - Copy

    func testCCopyProject() {
        guard let hashedID = WistiaAPIProjectTests.tempProjectHashedID else { XCTFail("prerequisite fail: no project"); return }

        let expectation = expectationWithDescription("copied the project")

        wAPI.copyProject(hashedID, adminEmail: nil) { (success, copiedProject) in
            if let p = copiedProject where success && p.hashedID != hashedID {
                expectation.fulfill()

                self.wAPI.deleteProject(p.hashedID, completionHandler: { (success, deletedProject) in
                    //ignore
                })
            }
        }

        waitForExpectationsWithTimeout(3, handler: nil)
    }

    //MARK: - Delete

    func testDDeleteProject() {
        guard let hashedID = WistiaAPIProjectTests.tempProjectHashedID else { XCTFail("prerequisite fail: no project"); return }

        let expectation = expectationWithDescription("deleted the project")

        wAPI.deleteProject(hashedID) { (success, deletedProject) in
            if let p = deletedProject where success && p.hashedID == hashedID {
                WistiaAPIProjectTests.tempProjectHashedID = nil
                expectation.fulfill()
            }
        }

        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
}
