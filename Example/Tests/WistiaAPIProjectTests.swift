//
//  WistiaAPIProjectTests.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 5/19/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import XCTest
import WistiaKitCore
import WistiaKit

class WistiaAPIProjectTests: XCTestCase {
    
    let wAPI = WistiaAPI(apiToken:"1511ac67c0213610d9370ef12349c6ac828a18f6405154207b44f3a7e3a29e93")

    //MARK: - WistiaProject

    //MARK: - List

    //MARK: Basic

    func testListProjects() {
        let expectation = self.expectation(description: "listed projects")

        wAPI.listProjects { projects, error in
            if projects.count > 0 {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    //MARK: Sorting

    func testSortByCreatedAscending() {
        let expectation = self.expectation(description: "sorted properly")

        wAPI.listProjects(page: 1, perPage: 100, sorting: (by: .created, direction: .ascending)) { projects, error in

            let sortedProjects = projects.sorted(by: { (pa, pb) -> Bool in
                return pa.created!.compare(pb.created!) == ComparisonResult.orderedAscending
            })

            if projects.count == sortedProjects.count {
                var allGood = true
                for (i, _) in projects.enumerated() {
                    if projects[i] != sortedProjects[i] {
                        allGood = false
                    }
                }
                if allGood {
                    expectation.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testSortByCreatedDescending() {
        let expectation = self.expectation(description: "sorted properly")

        wAPI.listProjects(page: 1, perPage: 100, sorting: (by: .created, direction: .descending)) { projects, error in

            let sortedProjects = projects.sorted(by: { (pa, pb) -> Bool in
                return pa.created!.compare(pb.created!) == ComparisonResult.orderedDescending
            })

            if projects.count == sortedProjects.count {
                var allGood = true
                for (i, _) in projects.enumerated() {
                    if projects[i] != sortedProjects[i] {
                        allGood = false
                    }
                }
                if allGood {
                    expectation.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    //MARK: Paging

    func testPageTwo() {
        let expectation = self.expectation(description: "pulled second page")

        wAPI.listProjects(page: 1, perPage: 1, sorting: (by: .created, direction: .ascending)) { projectsP1, error in
            if projectsP1.count == 1 {
                self.wAPI.listProjects(page: 2, perPage: 1, sorting: (by: .created, direction: .ascending), completionHandler: { projectsP2, error in
                    if projectsP2.count == 1 && projectsP1.first?.hashedID != projectsP2.first?.hashedID {
                        expectation.fulfill()
                    }
                })
            }
        }

        waitForExpectations(timeout: 6, handler: nil)
    }

    //MARK: - Show

    func testShowProject() {
        let expectation = self.expectation(description: "created project with media")

        wAPI.showProject(forHash: "8q6efplb9n") { project, error in
            if project != nil {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    //MARK: - Create & Update

    func testCreateProject() {
        let createExpectation = self.expectation(description: "created a project")
        let updateExpectation = self.expectation(description: "updated the project")

        wAPI.createProject(named: "TestProject@\(Date())", adminEmail: nil, anonymousCanUpload: false, anonymousCanDownload: false, isPublic: false) { project, error in
            XCTAssertNil(error)
            if let createdProject = project {
                createExpectation.fulfill()

                self.wAPI.updateProject(forHash: createdProject.hashedID, withName: nil, anonymousCanUpload: true, anonymousCanDownload: true, isPublic: false) { project, error in
                    XCTAssertNil(error)
                    if let copiedProject = project , error == nil && copiedProject.anonymousCanDownload && !copiedProject.isPublic {
                        updateExpectation.fulfill()

                        //delete them both
                        self.wAPI.deleteProject(forHash: createdProject.hashedID, completionHandler: {_,_ in })
                        self.wAPI.deleteProject(forHash: copiedProject.hashedID, completionHandler: {_,_ in })
                    }
                }
            }
        }

        waitForExpectations(timeout: 6, handler: nil)
    }

    //MARK: - Copy & Delete

    func testCopyProject() {
        let hashToCopy = "8q6efplb9n"
        let copyExpectation = self.expectation(description: "copied the project")
        let deleteExpectation = self.expectation(description: "deleted the project")

        wAPI.copyProject(forHash: hashToCopy, withUpdatedAdminEmail: nil) { copiedProject, error in
            if let copied = copiedProject , error == nil && copied.hashedID != hashToCopy {
                copyExpectation.fulfill()

                self.wAPI.deleteProject(forHash: copied.hashedID) { deletedProject, error in
                    if let del = deletedProject , error == nil && del.hashedID == copied.hashedID {

                        deleteExpectation.fulfill()
                    }
                }

            }
        }

        waitForExpectations(timeout: 6, handler: nil)
    }


}
