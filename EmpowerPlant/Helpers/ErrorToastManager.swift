import Foundation
import SentrySwift
import SwiftMessages
import UIKit

class ErrorToastManager {
    static let shared = ErrorToastManager()

    private init() {}

    /// Logs an error to Sentry and shows a toast message to the user
    /// - Parameters:
    ///   - error: The error to log
    ///   - message: Optional custom message to display in toast (defaults to error description)
    ///   - scopeCallback: Optional callback to configure Sentry scope
    ///   - showFeedbackOption: Whether to show a User Feedback option in the toast
    func logErrorAndShowToast(
        error: Error,
        message: String? = nil,
        scopeCallback: ((Scope) -> Void)? = nil,
        showFeedbackOption: Bool = false
    ) {
        print("[EmpowerPlant] [Error]: \(error)")

        if let scopeCallback = scopeCallback {
            SentrySDK.capture(error: error, block: scopeCallback)  // Flagship
        } else {
            SentrySDK.capture(error: error)
        }

        // Show toast on main thread
        let displayMessage = message ?? error.localizedDescription
        Task { @MainActor in
            if showFeedbackOption {
                self.showErrorToastWithFeedback(message: displayMessage)
            } else {
                self.showErrorToast(message: displayMessage)
            }
        }
    }

    /// Shows an error toast message
    /// - Parameter message: The message to display
    @MainActor
    func showErrorToast(message: String) {
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(.error)
        view.configureContent(title: "Error", body: message)
        view.configureDropShadow()

        // Set up interactive elements
        view.button?.setTitle("Dismiss", for: .normal)
        view.buttonTapHandler = { _ in
            SwiftMessages.hide()
        }

        // Configure presentation style
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .top
        config.duration = .seconds(seconds: 5)
        config.dimMode = .gray(interactive: true)
        config.interactiveHide = true

        SwiftMessages.show(config: config, view: view)
    }

    /// Shows an error toast message with User Feedback option
    /// - Parameter message: The message to display
    @MainActor
    func showErrorToastWithFeedback(message: String) {
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(.error)
        view.configureContent(title: "Checkout Error", body: message)
        view.configureDropShadow()

        // Shop green, same as the navigation bar and buttons.
        view.backgroundColor = EmpowerPlantTheme.buttonPressed
        view.button?.backgroundColor = .white
        view.button?.setTitleColor(.black, for: .normal)
        view.button?.layer.cornerRadius = 4

        // Set up interactive elements with feedback option
        view.button?.setTitle("Provide Feedback", for: .normal)
        view.buttonTapHandler = { _ in
            SwiftMessages.hide()
            Task { @MainActor in
                ShopFeedback.presentCheckoutForm()
            }
        }
        ShopPrivacy.unmask(view)

        // Configure presentation style. No dim, so the feedback form stays usable.
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .top
        config.duration = .seconds(seconds: 8)  // Longer duration for feedback option
        config.dimMode = .none
        config.interactiveHide = true

        SwiftMessages.show(config: config, view: view)
    }

    /// Short notice after add-to-cart, matching the React Native toast.
    @MainActor
    func showAddedToCart() {
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(.success)
        view.configureContent(title: "Added to Cart", body: " ")
        view.configureDropShadow()
        view.button?.isHidden = true

        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .bottom
        config.duration = .seconds(seconds: 1)
        config.dimMode = .none
        config.interactiveHide = true

        SwiftMessages.show(config: config, view: view)
    }
}
