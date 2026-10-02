import SentrySwift

/// Demo feature flags. Values match what the shop actually does, and
/// `SentrySDK.addFeatureFlag` stores them on the scope so later error and
/// message events include them.
enum ShopFlags {
    static func register() {
        // Checkout always posts validate_inventory.
        SentrySDK.addFeatureFlag(name: "inventory-check", result: true)
        // Product detail includes Water and Repot.
        SentrySDK.addFeatureFlag(name: "plant-care", result: true)
        // Session Replay and screenshots unmask the cart, nav buttons, and total.
        SentrySDK.addFeatureFlag(name: "replay-unmask", result: true)
    }
}
