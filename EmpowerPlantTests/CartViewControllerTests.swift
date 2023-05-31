//
//  CartViewControllerTests.swift
//  EmpowerPlantTests
//
//  Created by Kosty Maleyev on 5/25/23.
//

import XCTest
@testable import EmpowerPlant


class MockURLSessionDataTask: URLSessionDataTaskProtocol {
    func resume() {
        // Do nothing as it's a mock
    }
}

class MockURLSession: URLSessionProtocol {
    var data: Data?
    var response: URLResponse?
    var error: Error?

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        let task = MockURLSessionDataTask()
        completionHandler(data, response, error)
        return task
    }
}

final class CartViewControllerTests: XCTestCase {

    func testPurchase() {
        // Given
        let expectation = XCTestExpectation(description: "Purchase request completed")
        let mockSession = MockURLSession()
        let cvc = CartViewController(session: mockSession)

        // Prepare mock response
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://application-monitoring-flask-dot-sales-engineering-sf.appspot.com/checkout")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        mockSession.response = mockResponse

        cvc.purchase()

        expectation.fulfill()
        
        // // Then
        // DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        //     // Add assertions here to validate the behavior of the purchase function
        //     // For example, you can check if the request was successful or if an error was captured
        //
        //     // Fulfill the expectation to mark the test as completed
        //     expectation.fulfill()
        // }
        //
        // // Wait for the expectation to be fulfilled or time out after a certain duration
        // wait(for: [expectation], timeout: 5)
    }
}
