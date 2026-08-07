import Foundation

protocol CheckoutServicing {
    func purchase(
        cart: [String: Any],
        completion: @escaping (Result<Void, CheckoutServiceError>) -> Void
    )
}

final class CheckoutService: CheckoutServicing {
    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol) {
        self.apiService = apiService
    }

    func purchase(
        cart: [String: Any],
        completion: @escaping (Result<Void, CheckoutServiceError>) -> Void
    ) {
        apiService.checkout(cart: cart) { result in
            completion(result.mapError(CheckoutServiceError.api))
        }
    }
}
