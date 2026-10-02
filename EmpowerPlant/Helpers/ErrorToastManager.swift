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

        let eventId: SentryId
        if let scopeCallback = scopeCallback {
            eventId = SentrySDK.capture(error: error, block: scopeCallback)  // Flagship
        } else {
            eventId = SentrySDK.capture(error: error)
        }

        // Show toast on main thread
        let displayMessage = message ?? error.localizedDescription
        Task { @MainActor in
            if showFeedbackOption {
                self.showErrorToastWithFeedback(message: displayMessage, eventId: eventId)
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
    /// - Parameters:
    ///   - message: The message to display
    ///   - eventId: The Sentry event ID to associate with feedback
    @MainActor
    func showErrorToastWithFeedback(message: String, eventId: SentryId) {
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(.error)
        view.configureContent(title: "Checkout Error", body: message)
        view.configureDropShadow()

        // Apply purple theme to match the app's color scheme
        view.backgroundColor = EmpowerPlantTheme.buttonPressed  // deep purple #562E7D
        view.button?.backgroundColor = EmpowerPlantTheme.buttonBackground
        view.button?.setTitleColor(.white, for: .normal)
        view.button?.layer.cornerRadius = 4

        // Set up interactive elements with feedback option
        view.button?.setTitle("Provide Feedback", for: .normal)
        view.buttonTapHandler = { _ in
            SwiftMessages.hide()
            // Cocoa 9.24's managed form has no associatedEventId parameter.
            // `eventId` is the checkout error this toast was opened from.
            _ = eventId
            DispatchQueue.main.async {
                SentrySDK.feedback.show()
            }
        }

        // Configure presentation style
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .top
        config.duration = .seconds(seconds: 8)  // Longer duration for feedback option
        config.dimMode = .gray(interactive: true)
        config.interactiveHide = true

        SwiftMessages.show(config: config, view: view)
    }

    /// Shows a warning toast message
    /// - Parameter message: The message to display
    @MainActor
    func showWarningToast(message: String) {
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(.warning)
        view.configureContent(title: "Warning", body: message)
        view.configureDropShadow()

        view.button?.setTitle("Dismiss", for: .normal)
        view.buttonTapHandler = { _ in
            SwiftMessages.hide()
        }

        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .top
        config.duration = .seconds(seconds: 4)
        config.dimMode = .gray(interactive: true)
        config.interactiveHide = true

        SwiftMessages.show(config: config, view: view)
    }

    /// Shows an info toast message
    /// - Parameter message: The message to display
    @MainActor
    func showInfoToast(message: String) {
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(.info)
        view.configureContent(title: "Info", body: message)
        view.configureDropShadow()

        view.button?.setTitle("Dismiss", for: .normal)
        view.buttonTapHandler = { _ in
            SwiftMessages.hide()
        }

        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .top
        config.duration = .seconds(seconds: 3)
        config.dimMode = .gray(interactive: true)
        config.interactiveHide = true

        SwiftMessages.show(config: config, view: view)
    }
}
