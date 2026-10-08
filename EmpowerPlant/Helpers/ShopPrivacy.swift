import SentrySwift
import UIKit

enum ShopPrivacy {
    /// `sentryReplayUnmask` is the per-view flag used by both Session Replay
    /// and error screenshots (`attachScreenshot`).
    static func unmask(_ view: UIView) {
        view.sentryReplayUnmask()
    }

    /// Unmasks bar buttons, including the cart, Purchase, and back controls.
    /// The navigation title stays masked. On newer iOS it is a `UIControl`.
    static func unmaskNavigationButtons(of viewController: UIViewController) {
        let screenTitle = viewController.navigationItem.title ?? viewController.title
        if let navigationBar = viewController.navigationController?.navigationBar {
            unmaskControls(in: navigationBar, screenTitle: screenTitle)
        }

        let item = viewController.navigationItem
        let barItems = (item.leftBarButtonItems ?? []) + (item.rightBarButtonItems ?? [])
        for barItem in barItems {
            if let customView = barItem.customView {
                unmask(customView)
            }
        }
    }

    private static func unmaskControls(in view: UIView, screenTitle: String?) {
        if view is UIControl, !containsScreenTitle(view, screenTitle: screenTitle) {
            view.sentryReplayUnmask()
        }
        for subview in view.subviews {
            unmaskControls(in: subview, screenTitle: screenTitle)
        }
    }

    /// True for the navigation title control and any ancestor that contains it.
    private static func containsScreenTitle(_ view: UIView, screenTitle: String?) -> Bool {
        let className = NSStringFromClass(type(of: view))
        if className.contains("TitleControl") || className.contains("NavigationBarTitle") {
            return true
        }
        guard let screenTitle, !screenTitle.isEmpty else { return false }
        if let label = view as? UILabel, label.text == screenTitle {
            return true
        }
        return view.subviews.contains { containsScreenTitle($0, screenTitle: screenTitle) }
    }
}
