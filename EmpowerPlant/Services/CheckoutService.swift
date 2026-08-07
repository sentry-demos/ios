import Foundation
import SentrySwift

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
        let cartDetails = cart["cart"] as? [String: Any]
        let itemCount = (cartDetails?["items"] as? [[String: Any]])?.count ?? 0
        let span = SentrySDK.span?.startChild(
            operation: "app.checkout.purchase",
            description: "Purchase cart"
        )
        span?.setData(value: itemCount, key: "cart.item_count")
        SentrySDK.logger.debug("Checkout started", attributes: ["itemCount": itemCount])

        apiService.checkout(cart: cart) { result in
            switch result {
            case .success:
                span?.finish()
                SentrySDK.logger.info("Checkout completed", attributes: ["itemCount": itemCount])
            case .failure(let error):
                let errorType = String(describing: type(of: error))
                span?.setData(value: errorType, key: "error.type")
                span?.finish()
                SentrySDK.logger.error(
                    "Checkout failed",
                    attributes: ["itemCount": itemCount, "errorType": errorType]
                )
            }
            completion(result.mapError(CheckoutServiceError.api))
        }
    }
}
