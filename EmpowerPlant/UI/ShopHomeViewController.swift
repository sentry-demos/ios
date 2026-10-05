import SentrySwift
import UIKit

/// First screen after launch. The plant catalog, including the Flask
/// `GET /products` request, stays on `EmpowerPlantViewController` and runs
/// only after View products is tapped.
final class ShopHomeViewController: UIViewController {
    private let viewProductsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("View products", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.backgroundColor = EmpowerPlantTheme.buttonBackground
        button.layer.cornerRadius = 8
        button.accessibilityIdentifier = "ViewProducts"
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Empower Plants"
        view.backgroundColor = EmpowerPlantTheme.tableBackground
        configureNavigationItems()
        layoutButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ShopPrivacy.unmaskNavigationButtons(of: self)
        SentrySDK.reportFullyDisplayed()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        ShopPrivacy.unmaskNavigationButtons(of: self)
    }

    private func configureNavigationItems() {
        let more = UIBarButtonItem(
            title: "more",
            style: .plain,
            target: self,
            action: #selector(showDebugMenu)
        )
        more.accessibilityIdentifier = "more"
        navigationItem.leftBarButtonItem = more
    }

    private func layoutButton() {
        viewProductsButton.addTarget(self, action: #selector(showProducts), for: .touchUpInside)
        ShopPrivacy.unmask(viewProductsButton)
        view.addSubview(viewProductsButton)
        NSLayoutConstraint.activate([
            viewProductsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            viewProductsButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            viewProductsButton.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
            viewProductsButton.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32),
            viewProductsButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 220),
            viewProductsButton.heightAnchor.constraint(equalToConstant: 52),
        ])
    }

    @objc private func showProducts() {
        ShopClick.play()
        let storyboard = self.storyboard ?? UIStoryboard(name: "Main", bundle: nil)
        let catalog = storyboard.instantiateViewController(withIdentifier: "EmpowerPlantViewController")
        navigationController?.pushViewController(catalog, animated: true)
    }

    @objc private func showDebugMenu() {
        ShopClick.play()
        navigationController?.pushViewController(ListAppViewController(), animated: true)
    }
}
