import UIKit
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

        let mediaJson = """
                        {"data":{"id":"abc123","type":"video","attributes":{"type":"video","name":"No","description":"UpdateTwoKolkkaMhmm","project_id":"projJJ33","duration":4.399,"position":-3,"url":"https://test.wistia.com/medias/abc123","aspect_ratio":1.8181818181818181},"relationships":{"media_group":{"data":{"id":"3688934","type":"media_group"}},"storyboard":{"data":{"id":"https://embed-ssl.wistia.com/deliveries/storyboarduuid.bin","type":"storyboard"}},"thumbnail":{"data":{"id":"https://embed-ssl.wistia.com/deliveries/thumbnailuuid.jpg?image_crop_resized=200x120image_quality=100ssl=true","type":"thumbnail"}}}}}
                        """
        let c = WistiaClient()
        c.handleDataTaskResult(data: mediaJson.data(using: .utf8), urlResponse: nil, error: nil) { (media: Media?, error) in
            XCTAssertNotNil(media, error.debugDescription)
            XCTAssertEqual(media?.id, "abc123")
            XCTAssertEqual(media?.type, .video)

            XCTAssertEqual(media?.attributes?.type, .video)
            XCTAssertEqual(media?.attributes?.name, "No")
            XCTAssertEqual(media?.attributes?.description, "UpdateTwoKolkkaMhmm")
            XCTAssertEqual(media?.attributes?.projectId, "projJJ33")
            XCTAssertEqual((media?.attributes?.duration)!, 4.399, accuracy: 0.01)
            XCTAssertEqual(media?.attributes?.position, -3)
            XCTAssertEqual(media?.attributes?.url, URL(string: "https://test.wistia.com/medias/abc123"))
            XCTAssertEqual((media?.attributes?.aspectRatio)!, 1.81, accuracy: 0.01)

            XCTAssertEqual(media?.relationships?.storyboard.id, URL(string: "https://embed-ssl.wistia.com/deliveries/storyboarduuid.bin"))

            XCTAssertEqual(media?.relationships?.thumbnail.id, URL(string: "https://embed-ssl.wistia.com/deliveries/thumbnailuuid.jpg?image_crop_resized=200x120image_quality=100ssl=true"))
            XCTAssertEqual(media?.thumbnailURL, URL(string: "https://embed-ssl.wistia.com/deliveries/thumbnailuuid.jpg?image_crop_resized=200x120image_quality=100ssl=true"))

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

