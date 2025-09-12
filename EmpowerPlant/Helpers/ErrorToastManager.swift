import Foundation
import UIKit
import SwiftMessages
import Sentry

class ErrorToastManager {
    static let shared = ErrorToastManager()
    
    private init() {}
    
    /// Logs an error to Sentry and shows a toast message to the user
    /// - Parameters:
    ///   - error: The error to log
    ///   - message: Optional custom message to display in toast (defaults to error description)
    ///   - scopeCallback: Optional callback to configure Sentry scope
    func logErrorAndShowToast(
        error: Error,
        message: String? = nil,
        scopeCallback: ((Scope) -> Void)? = nil
    ) {
        print("[EmpowerPlant] [Error]: \(error)")

        if let scopeCallback = scopeCallback {
            SentrySDK.capture(error: error, block: scopeCallback)
        } else {
            SentrySDK.capture(error: error)
        }
        
        // Show toast on main thread
        let displayMessage = message ?? error.localizedDescription
        Task { @MainActor in
            self.showErrorToast(message: displayMessage)
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
