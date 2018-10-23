//
//  MediaUnitTests.swift
//  WistiaKit_Tests
//
//  Created by Daniel Spinosa on 10/17/17.
//  Copyright © 2017 Wistia. All rights reserved.
//

import XCTest
@testable import WistiaKit

class MediaUnitTests: XCTestCase {

    func testDecodeMinimalMediaResponse() {
        let x = XCTestExpectation()

        let mediaJson = """
                        {"data":
                            {"id": "abc123"}
                        }
                        """
        let c = WistiaClient()
        c.handleDataTaskResult(data: mediaJson.data(using: .utf8), urlResponse: nil, error: nil) { (media: Media?, error) in
            XCTAssertNotNil(media, error.debugDescription)
            x.fulfill()
        }

        wait(for: [x], timeout: 1)
    }

    func testDecodeCompleteMediaResponse() {
        let x = XCTestExpectation()

        let mediaJson = "{\"data\":{\"id\":\"123456\",\"type\":\"video\",\"attributes\":{\"account_name\":\"spinosa-5\",\"project_name\":\"Uploads on 2018-10-23\",\"name\":\"Untitled\",\"display_name\":\"Untitled\",\"hashed_id\":\"jqhrpu4jca\",\"project_hashed_id\":\"y3ck12j6a7\",\"media_group_id\":5041440,\"duration\":8.365,\"position\":-4,\"progress\":0.1111111111111111,\"status\":0,\"status_in_words\":\"queued\",\"type\":\"Video\",\"thumbnail\":{\"url\":\"https://embed-ssl.wistia.com/deliveries/c922a781311f3855bb971544d2054719.jpg?image_crop_resized=200x120\\u0026video_still_time=4\",\"width\":200,\"height\":120},\"created_at\":\"2018-10-23T14:20:29+00:00\",\"updated_at\":\"2018-10-23T14:20:29+00:00\",\"description\":\"des\",\"account_host\":\"spinosa-5.wistia.com\",\"can_delete\":true,\"can_update\":true,\"can_view_stats\":true,\"comment_count\":0,\"play_count\":0,\"kind\":\"video\",\"raw_description\":\"\",\"stats\":{\"loads\":0,\"visitors\":0,\"play_rate\":\"0 %\",\"plays\":0,\"hours_watched\":0,\"engagement\":\"0 %\"},\"mp3_url\":null,\"can_create\":true,\"can_download\":true,\"show_comments\":true,\"ghost\":false,\"markdown_description\":null,\"project_id\":3886042,\"download_url\":\"/medias/jqhrpu4jca/download?asset=original\"},\"relationships\":{\"comments\":{\"data\":[]}}}}"


        let c = WistiaClient()
        c.handleDataTaskResult(data: mediaJson.data(using: .utf8), urlResponse: nil, error: nil) { (media: Media?, error) in
            XCTAssertNotNil(media, error.debugDescription)
            XCTAssertEqual(media?.id, "123456")
            XCTAssertEqual(media?.type, .video)

            XCTAssertEqual(media?.attributes?.type, .video)
            XCTAssertEqual(media?.attributes?.name, "Untitled")
            XCTAssertEqual(media?.attributes?.description, "des")
            XCTAssertEqual(media?.attributes?.projectId, 3886042)
            XCTAssertEqual((media?.attributes?.duration)!, 8.365, accuracy: 0.01)
            XCTAssertEqual(media?.attributes?.position, -4)
            XCTAssertEqual(media?.attributes?.url, nil)

            XCTAssertEqual(media?.attributes?.thumbnail?.url, URL(string: "https://embed-ssl.wistia.com/deliveries/c922a781311f3855bb971544d2054719.jpg?image_crop_resized=200x120&video_still_time=4"))

            XCTAssertEqual(media?.attributes?.stats?.loads, 0)
            XCTAssertEqual(media?.attributes?.stats?.visitors, 0)
            XCTAssertEqual(media?.attributes?.stats?.playRate, "0 %")
            XCTAssertEqual(media?.attributes?.stats?.plays, 0)
            XCTAssertEqual(media?.attributes?.stats?.hoursWatched, 0)
            XCTAssertEqual(media?.attributes?.stats?.engagement, "0 %")

            XCTAssertEqual(media?.relationships?.storyboard?.id, nil)

            x.fulfill()
        }

        wait(for: [x], timeout: 1)
    }

    func testDecodeMediaList() {
        let x = XCTestExpectation()

        let mediaJson = """
                        {"data":
                            [{"id": "abc123"},{"id": "abc456"},{"id": "abc789"},{"id": "abc10"}]
                        }
                        """
        let c = WistiaClient()
        c.handleDataTaskResult(data: mediaJson.data(using: .utf8), urlResponse: nil, error: nil) { (medias: [Media]?, error) in
            XCTAssertNotNil(medias, error.debugDescription)
            XCTAssertEqual(medias?.count, 4)
            XCTAssertEqual(medias?[0].id, "abc123")
            XCTAssertEqual(medias?[1].id, "abc456")
            XCTAssertEqual(medias?[2].id, "abc789")
            XCTAssertEqual(medias?[3].id, "abc10")
            x.fulfill()
        }

        wait(for: [x], timeout: 1)

    }
}

