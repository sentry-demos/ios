import Foundation

/// Handled failures for the Other issues Error button.
/// One case per failure, captured as a Swift error.
enum DemoFailure: Error, LocalizedError {
    case catalogRequestFailed
    case checkoutReservationFailed
    case paymentAuthorizationFailed

    var errorDescription: String? {
        switch self {
        case .catalogRequestFailed:
            return "Catalog request failed: the product service returned no prices"
        case .checkoutReservationFailed:
            return "Checkout failed: inventory could not be reserved for this order"
        case .paymentAuthorizationFailed:
            return "Payment failed: the card authorization was declined"
        }
    }

    static func random() -> DemoFailure {
        let cases: [DemoFailure] = [
            .catalogRequestFailed,
            .checkoutReservationFailed,
            .paymentAuthorizationFailed,
        ]
        return cases.randomElement()!
    }
}
