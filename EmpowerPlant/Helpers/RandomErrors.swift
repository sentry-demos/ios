import Foundation

/// Handled failures for the Other issues screen. Each domain is its own Sentry issue.
enum DemoFailure {
    static func make() -> NSError {
        let options: [(domain: String, code: Int, message: String)] = [
            (
                "CatalogLoadError",
                1001,
                "Catalog request failed: the product service returned no prices"
            ),
            (
                "CheckoutReservationError",
                1002,
                "Checkout failed: inventory could not be reserved for this order"
            ),
            (
                "PaymentAuthorizationError",
                1003,
                "Payment failed: the card authorization was declined"
            ),
        ]
        let choice = options.randomElement()!
        return NSError(
            domain: choice.domain,
            code: choice.code,
            userInfo: [
                NSLocalizedDescriptionKey: choice.message,
                NSDebugDescriptionErrorKey: choice.message,
            ]
        )
    }
}
