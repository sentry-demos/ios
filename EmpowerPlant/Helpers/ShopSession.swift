import Foundation
import SentrySwift

/// Demo shop identity, matching the React Native app at startup.
/// There is no login screen. The same values are the `/products` headers.
enum ShopSession {
    static let se = ProcessInfo.processInfo.environment["USER"] ?? "tda"

    static let customerType = ["medium-plan", "large-plan", "small-plan", "enterprise"].randomElement() ?? "enterprise"

    /// Four base-36 characters plus `@yahoo.com`, same shape as the React Native shop user.
    static let email: String = {
        let digits = String(UInt64.random(in: 0...UInt64.max), radix: 36)
        return String(digits.prefix(4)) + "@yahoo.com"
    }()

    static func apply(to scope: Scope) {
        scope.setTag(value: customerType, key: "customerType")
        let user = User()
        user.email = email
        scope.setUser(user)
    }

    static func applyRequestHeaders(to request: inout URLRequest) {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(se, forHTTPHeaderField: "se")
        request.setValue(customerType, forHTTPHeaderField: "customerType")
        request.setValue(email, forHTTPHeaderField: "email")
    }
}
