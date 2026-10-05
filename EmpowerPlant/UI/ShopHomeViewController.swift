import SentrySwift
import UIKit

/// First screen after launch. The plant catalog, including the Flask
/// `GET /products` request, stays on `EmpowerPlantViewController` and runs
/// only after View products is tapped.
final class ShopHomeViewController: UIViewController {
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "HomeBackground"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isAccessibilityElement = false
        return imageView
    }()

    private let scrimView: BottomScrimView = {
        let view = BottomScrimView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Empower Plants"
        label.textColor = .white
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let viewProductsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("View products", for: .normal)
        button.setTitleColor(UIColor(white: 0.12, alpha: 1), for: .normal)
        button.setTitleColor(UIColor(white: 0.12, alpha: 1), for: .highlighted)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = .white
        button.layer.cornerRadius = 26
        button.clipsToBounds = true
        button.accessibilityIdentifier = "ViewProducts"
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = nil
        navigationItem.title = nil
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .black
        applyTransparentNavigationBar()
        layoutShopfront()
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

    private func applyTransparentNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.compactScrollEdgeAppearance = appearance
    }

    private func layoutShopfront() {
        viewProductsButton.addTarget(self, action: #selector(showProducts), for: .touchUpInside)
        ShopPrivacy.unmask(viewProductsButton)
        view.addSubview(backgroundImageView)
        view.addSubview(scrimView)
        view.addSubview(titleLabel)
        view.addSubview(viewProductsButton)

        NSLayoutConstraint.activate([
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrimView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.34),

            viewProductsButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            viewProductsButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            viewProductsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            viewProductsButton.heightAnchor.constraint(equalToConstant: 52),

            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            titleLabel.bottomAnchor.constraint(equalTo: viewProductsButton.topAnchor, constant: -20),
        ])
    }

    @objc private func showProducts() {
        ShopClick.play()
        let storyboard = self.storyboard ?? UIStoryboard(name: "Main", bundle: nil)
        let catalog = storyboard.instantiateViewController(withIdentifier: "EmpowerPlantViewController")
        navigationController?.pushViewController(catalog, animated: true)
    }
}

/// Fades from clear to dark across the lower third so the title stays readable
/// without a solid panel over the plant.
private final class BottomScrimView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        guard let gradient = layer as? CAGradientLayer else { return }
        gradient.colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(0.55).cgColor,
            UIColor.black.withAlphaComponent(0.82).cgColor,
        ]
        gradient.locations = [0, 0.45, 1]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
