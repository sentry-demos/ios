import Foundation

@testable import EmpowerPlant

final class MockNetworkDataTask: NetworkDataTask {
    var onResume: (() -> Void)?

    func resume() {
        onResume?()
    }
}

final class MockNetworkSession: NetworkSession {
    var data: Data?
    var response: URLResponse?
    var error: Error?

    func dataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> NetworkDataTask {
        let task = MockNetworkDataTask()
        task.onResume = { completionHandler(self.data, self.response, self.error) }
        return task
    }
}

final class MockAPIService: APIServiceProtocol {
    var productsResult: Result<Data, APIServiceError> = .success(Data())
    var checkoutResult: Result<Void, APIServiceError> = .success(())

    func fetchProducts(completion: @escaping (Result<Data, APIServiceError>) -> Void) {
        completion(productsResult)
    }

    func checkout(cart: [String: Any], completion: @escaping (Result<Void, APIServiceError>) -> Void) {
        completion(checkoutResult)
    }
}

final class MockCheckoutService: CheckoutServicing {
    private(set) var purchaseCallCount = 0
    var result: Result<Void, CheckoutServiceError> = .success(())

    func purchase(
        cart: [String: Any],
        completion: @escaping (Result<Void, CheckoutServiceError>) -> Void
    ) {
        purchaseCallCount += 1
        completion(result)
    }
}
