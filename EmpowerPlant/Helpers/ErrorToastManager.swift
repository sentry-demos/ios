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
        SentrySDK.logger.debug(
            "logErrorAndShowToast called",
            attributes: [
                "hasCustomMessage": message != nil,
                "hasScopeCallback": scopeCallback != nil,
                "showFeedbackOption": showFeedbackOption,
            ])
        SentrySDK.logger.error(
            "Error captured for toast display",
            attributes: [
                "error": String(describing: error)
            ])

        let eventId: SentryId
        if let scopeCallback = scopeCallback {
            SentrySDK.logger.debug("Capturing error with custom scope callback")
            eventId = SentrySDK.capture(error: error, block: scopeCallback)  // Flagship
        } else {
            SentrySDK.logger.debug("Capturing error with default scope")
            eventId = SentrySDK.capture(error: error)
        }

        // Show toast on main thread
        let displayMessage = message ?? error.localizedDescription
        Task { @MainActor in
            if showFeedbackOption {
                SentrySDK.logger.debug("Showing error toast with feedback option")
                self.showErrorToastWithFeedback(message: displayMessage, eventId: eventId)
            } else {
                SentrySDK.logger.debug("Showing standard error toast")
                self.showErrorToast(message: displayMessage)
            }
        }
    }

    /// Shows an error toast message
    /// - Parameter message: The message to display
    @MainActor
    func showErrorToast(message: String) {
        SentrySDK.logger.debug(
            "showErrorToast called",
            attributes: [
                "message": message
            ])
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
        SentrySDK.logger.debug(
            "showErrorToastWithFeedback called",
            attributes: [
                "message": message,
                "eventId": eventId.sentryIdString,
            ])
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
            self.showFeedbackPrompt(for: eventId)
        }

        // Configure presentation style
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .top
        config.duration = .seconds(seconds: 8)  // Longer duration for feedback option
        config.dimMode = .gray(interactive: true)
        config.interactiveHide = true

        SwiftMessages.show(config: config, view: view)
    }

    /// Shows a simple feedback prompt
    /// - Parameter eventId: The Sentry event ID to associate with feedback
    @MainActor
    private func showFeedbackPrompt(for eventId: SentryId) {
        SentrySDK.logger.debug(
            "showFeedbackPrompt called",
            attributes: [
                "eventId": eventId.sentryIdString
            ])
        let alert = UIAlertController(
            title: "Help Us Improve",
            message: "We'd love to hear about your experience. Would you like to provide feedback about this issue?",
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(title: "Yes, Provide Feedback", style: .default) { _ in
                self.collectUserFeedback(for: eventId)
            })

        alert.addAction(UIAlertAction(title: "Not Now", style: .cancel))

        // Present from the current top view controller
        if let topVC = UIApplication.shared.windows.first?.rootViewController {
            var presentingVC = topVC
            while let presented = presentingVC.presentedViewController {
                presentingVC = presented
            }
            presentingVC.present(alert, animated: true)
        } else {
            SentrySDK.logger.warn("Unable to present feedback prompt, no root view controller found")
        }
    }

    /// Collects user feedback and submits to Sentry
    /// - Parameter eventId: The Sentry event ID to associate with feedback
    @MainActor
    private func collectUserFeedback(for eventId: SentryId) {
        SentrySDK.logger.debug(
            "collectUserFeedback called",
            attributes: [
                "eventId": eventId.sentryIdString
            ])
        let alert = UIAlertController(
            title: "Provide Feedback",
            message: "Please tell us what happened and how we can improve your experience.",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "Your name (optional)"
        }

        alert.addTextField { textField in
            textField.placeholder = "Your email (optional)"
        }

        alert.addTextField { textField in
            textField.placeholder = "Describe the issue..."
            textField.autocorrectionType = .yes
        }

        alert.addAction(
            UIAlertAction(title: "Submit Feedback", style: .default) { _ in
                let name = alert.textFields?[0].text ?? ""
                let email = alert.textFields?[1].text ?? ""
                let comments = alert.textFields?[2].text ?? ""

                if !comments.isEmpty {
                    SentrySDK.logger.info(
                        "Submitting user feedback",
                        attributes: [
                            "eventId": eventId.sentryIdString,
                            "hasName": !name.isEmpty,
                            "hasEmail": !email.isEmpty,
                            "commentLength": comments.count,
                        ])
                    SentrySDK.capture(
                        feedback: SentryFeedback(
                            message: comments,
                            name: name.isEmpty ? "Anonymous User" : name,
                            email: email.isEmpty ? "anonymous@example.com" : email
                        ))

                    // Show success message
                    self.showInfoToast(message: "Thank you for your feedback! We'll use it to improve the app.")
                } else {
                    SentrySDK.logger.debug("User feedback not submitted, comments were empty")
                }
            })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // Present from the current top view controller
        if let topVC = UIApplication.shared.windows.first?.rootViewController {
            var presentingVC = topVC
            while let presented = presentingVC.presentedViewController {
                presentingVC = presented
            }
            presentingVC.present(alert, animated: true)
        } else {
            SentrySDK.logger.warn("Unable to present feedback collection alert, no root view controller found")
        }
    }

    /// Shows a warning toast message
    /// - Parameter message: The message to display
    @MainActor
    func showWarningToast(message: String) {
        SentrySDK.logger.debug(
            "showWarningToast called",
            attributes: [
                "message": message
            ])
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
        SentrySDK.logger.debug(
            "showInfoToast called",
            attributes: [
                "message": message
            ])
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
