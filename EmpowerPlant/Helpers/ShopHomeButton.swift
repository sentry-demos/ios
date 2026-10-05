import UIKit

enum ShopHomeButton {
    /// Visible nav-bar control that returns to the existing succulent home screen.
    static func install(on viewController: UIViewController) {
        let home = UIBarButtonItem(
            title: "Home",
            style: .plain,
            target: viewController,
            action: #selector(UIViewController.shopPopToHome)
        )
        home.accessibilityIdentifier = "Home"
        var items = viewController.navigationItem.leftBarButtonItems ?? []
        items.insert(home, at: 0)
        viewController.navigationItem.leftBarButtonItems = items
        viewController.navigationItem.leftItemsSupplementBackButton = true
    }
}

extension UIViewController {
    @objc func shopPopToHome() {
        ShopClick.play()
        navigationController?.popToRootViewController(animated: true)
    }
}
