import XCTest

@testable import EmpowerPlant

final class SerializationServiceTests: XCTestCase {
    func testDecodeReturnsDecodableValue() {
        let service = SerializationService()
        let data = Data(
            "{\"id\":1,\"title\":\"Plant Mood\",\"description\":\"Short\",\"descriptionfull\":\"Long\",\"img\":\"image\",\"imgcropped\":\"cropped\",\"price\":10}"
                .utf8)
        let expectation = expectation(description: "decoding completes")

        service.decode(ProductDTO.self, from: data) { result in
            XCTAssertEqual(try? result.get().title, "Plant Mood")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testDecodeReturnsErrorForMalformedJSON() {
        let service = SerializationService()
        let expectation = expectation(description: "decoding completes")

        service.decode(ProductDTO.self, from: Data("not-json".utf8)) { result in
            guard case .failure(.decoding) = result else {
                return XCTFail("Expected a decoding error")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }
}
