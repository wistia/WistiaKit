//
//  WistiaAPIMediaTests.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 5/19/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import XCTest
@testable import WistiaKit

class WistiaAPIMediaTests: XCTestCase {
    
    let wAPI = WistiaAPI(apiToken:"1511ac67c0213610d9370ef12349c6ac828a18f6405154207b44f3a7e3a29e93")

    //MARK: - WistiaMedia

    //MARK: List

    func testListMediasByProject() {
        let expectation = self.expectation(description: "listed medias by project")

        wAPI.listMediasGroupedByProject { (projects) in
            if projects.count > 0 {
                if let medias = projects.first?.medias, let media = medias.first {
                    if media.status == .ready &&
                        media.hashedID == "2egno8swf1" &&
                        media.name == "Hey there, welcome to Wistia!" {
                            expectation.fulfill()
                    }
                }
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testListMediasFilterByValidProject() {
        let expectation = self.expectation(description: "listed media filtered by project")

        let p = WistiaProject(projectID: 2356285, name: nil, description: nil, mediaCount: nil, created: nil, updated: nil, hashedID: "ignored", anonymousCanUpload: false, anonymousCanDownload: false, isPublic: false, publicID: nil, medias: nil)
        wAPI.listMedias(filterByProject: p) { (medias) in
            if !medias.isEmpty {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testListMediasFilterByInValidProject() {
        let expectation = self.expectation(description: "listed media filtered by project")

        let p = WistiaProject(projectID: 0, name: nil, description: nil, mediaCount: nil, created: nil, updated: nil, hashedID: "ignored", anonymousCanUpload: false, anonymousCanDownload: false, isPublic: false, publicID: nil, medias: nil)
        wAPI.listMedias(filterByProject: p) { (medias) in
            if medias.isEmpty {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testListMediasFilterByName() {
        let expectation = self.expectation(description: "listed media filtered by name")

        wAPI.listMedias(filterByName: "do_not_change_this_name") { (medias) in
            if !medias.isEmpty {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testListMediasFilterByNameEmpty() {
        let expectation = self.expectation(description: "listed media filtered by name")

        wAPI.listMedias(filterByName: "ThisIsNOTTHENAME") { (medias) in
            if medias.isEmpty {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testListMediasFilterByValidType() {
        let expectation = self.expectation(description: "listed media filtered by valid type")

        wAPI.listMedias(filterByType: "Video") { (medias) in
            if !medias.isEmpty {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testListMediasFilterByValidButEmptyType() {
        let expectation = self.expectation(description: "listed media filtered by valid type")

        wAPI.listMedias(filterByType: "MicrosoftOfficeDocument") { (medias) in
            if medias.isEmpty {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testListMediasFilterByInvalidType() {
        let expectation = self.expectation(description: "listed media filtered by valid type")

        wAPI.listMedias(filterByType: "Cromulent") { (medias) in
            if medias.isEmpty {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testListMediasFilterByValidHashedID() {
        let expectation = self.expectation(description: "listed media filtered by valid hashedID")

        wAPI.listMedias(filterByHashedID: "2egno8swf1") { (medias) in
            if let m = medias.first, m.hashedID == "2egno8swf1" {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testListMediasFilterByInvalidHashedID() {
        let expectation = self.expectation(description: "listed media filtered by invalid hashedID")

        wAPI.listMedias(filterByHashedID: "BAD33ID33") { (medias) in
            if medias.isEmpty {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)

    }

    //MARK: Show

    func testShowMedia() {
        let expectation = self.expectation(description: "showed media from hashedID")

        wAPI.showMedia(forHash: "2egno8swf1") { (media) in
            if let m = media, m.hashedID == "2egno8swf1" {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    //MARK: Update

    func testUpdateMedia() {
        let expectation = self.expectation(description: "updated media via hashedID")

        let randDesc = "MediaDescriptionUpdate@\(Date())"
        wAPI.updateMedia(forHash: "2egno8swf1", withName: nil, newStillMediaId: nil, description: randDesc) { (success, updatedMedia) in
            if let m = updatedMedia, let d = m.description, success && d.contains(randDesc) {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)

    }

    //MARK: Copy & Delete
    
    func testCopyAndDeleteMedia() {
        let copyExpectation = self.expectation(description: "copied the media")
        let deleteExpectation = self.expectation(description: "deleted the media")

        wAPI.copyMedia(forHash: "2egno8swf1", toProject: nil, withNewOwner: nil) { (success, copiedMedia) in
            if let m = copiedMedia, success && m.hashedID != "2egno8swf1" {
                copyExpectation.fulfill()

                self.wAPI.deleteMedia(forHash: m.hashedID) { (success, deletedMedia) in
                    if let del = deletedMedia, success && del.hashedID == m.hashedID {
                        deleteExpectation.fulfill()
                    }
                }

            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    //MARK: Stats

    func testStatsForMedia() {
        let expectation = self.expectation(description: "got stats for media via hashedID")

        wAPI.statsForMedia(forHash: "2egno8swf1") { (media) in
            if let m = media, m.stats != nil {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    //MARK: - WistiaAsset

    func testShowMediaIncludesAssets() {
        let expectation = self.expectation(description: "media had good looking assets")

        wAPI.showMedia(forHash: "2egno8swf1") { (media) in
            if let m = media , m.hashedID == "2egno8swf1" && m.assets.count > 0 {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }
    
}
