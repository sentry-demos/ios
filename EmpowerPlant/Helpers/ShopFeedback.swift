import UIKit

/// Prefills the checkout feedback message after the form is on screen.
/// The managed form has no prefill API, so the text view is set after presentation.
@MainActor
enum ShopFeedback {
    private static let checkoutMessage = "It's broken again! Please fix it."
    private static let messageIdentifier = "io.sentry.feedback.form.message"

    static func prefillCheckoutMessage() {
        fillMessage(attempt: 0)
    }

    private static func fillMessage(attempt: Int) {
        guard attempt < 8 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            if let textView = messageField() {
                if textView.text != checkoutMessage {
                    textView.text = checkoutMessage
                    textView.delegate?.textViewDidChange?(textView)
                }
                return
            }
            fillMessage(attempt: attempt + 1)
        }
    }

    private static func messageField() -> UITextView? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for window in scenes.flatMap(\.windows) {
            if let match = findMessageField(in: window) {
                return match
            }
        }
        return nil
    }

    private static func findMessageField(in view: UIView) -> UITextView? {
        if let textView = view as? UITextView, textView.accessibilityIdentifier == messageIdentifier {
            return textView
        }
        for subview in view.subviews {
            if let match = findMessageField(in: subview) {
                return match
            }
        }
        return nil
    }
}
