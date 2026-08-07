import XCTest

@testable import EmpowerPlant

final class CheckoutServiceTests: XCTestCase {
    func testPurchaseWrapsExpectedHTTP500() {
        let session = MockNetworkSession()
        session.response = HTTPURLResponse(
            url: URL(string: "https://flask.empower-plant.com/checkout")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )
        let apiService = APIService(networkService: NetworkService(session: session))
        let service = CheckoutService(apiService: apiService)
        let expectation = expectation(description: "checkout completes")

        service.purchase(cart: ["cart": [:]]) { result in
            guard case .failure(.api(.network(.httpStatus(let statusCode)))) = result else {
                return XCTFail("Expected the HTTP 500 to be wrapped by CheckoutService")
            }
            XCTAssertEqual(statusCode, 500)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }
}
