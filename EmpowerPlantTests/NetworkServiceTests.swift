import XCTest

@testable import EmpowerPlant

final class NetworkServiceTests: XCTestCase {
    func testPerformReturnsHTTPStatusErrorForServerError() {
        let session = MockNetworkSession()
        session.response = HTTPURLResponse(
            url: URL(string: "https://example.com/checkout")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )
        let service = NetworkService(session: session)
        let expectation = expectation(description: "request completes")

        service.perform(request: URLRequest(url: URL(string: "https://example.com/checkout")!)) { result in
            guard case .failure(.httpStatus(let statusCode)) = result else {
                return XCTFail("Expected an HTTP status error")
            }
            XCTAssertEqual(statusCode, 500)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testPerformReturnsDataForSuccessfulResponse() {
        let session = MockNetworkSession()
        let expectedData = Data("[]".utf8)
        session.data = expectedData
        session.response = HTTPURLResponse(
            url: URL(string: "https://example.com/products")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        let service = NetworkService(session: session)
        let expectation = expectation(description: "request completes")

        service.perform(request: URLRequest(url: URL(string: "https://example.com/products")!)) { result in
            XCTAssertEqual(try? result.get(), expectedData)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }
}
