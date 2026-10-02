import SentrySwift
import UIKit

/// Plant detail. Add to cart stays on the happy path. Watering blocks the main
/// thread long enough for an app hang. Repot ends in a native crash.
final class ProductDetailViewController: UIViewController {

    private let product: Product

    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let productImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = EmpowerPlantTheme.cardBackground
        imageView.layer.cornerRadius = 8
        imageView.image = UIImage(systemName: "leaf.fill")
        imageView.tintColor = EmpowerPlantTheme.buttonBackground
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    init(product: Product) {
        self.product = product
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = product.title ?? "Plant"
        view.backgroundColor = EmpowerPlantTheme.tableBackground
        layoutStorefront()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ShopPrivacy.unmaskNavigationButtons(of: self)
        recordProductView()
        SentrySDK.reportFullyDisplayed()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        ShopPrivacy.unmaskNavigationButtons(of: self)
    }

    private func layoutStorefront() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = EmpowerPlantTheme.textHeader
        titleLabel.numberOfLines = 0
        titleLabel.text = product.title

        let priceLabel = UILabel()
        priceLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        priceLabel.textColor = EmpowerPlantTheme.textHeader
        priceLabel.text = priceText

        let descriptionLabel = UILabel()
        descriptionLabel.font = .systemFont(ofSize: 16)
        descriptionLabel.textColor = .darkGray
        descriptionLabel.numberOfLines = 0
        descriptionLabel.text = product.productDescriptionFull ?? product.productDescription

        let addButton = filledButton(title: "Add to Cart", action: #selector(addToCart))
        addButton.accessibilityIdentifier = "AddToCartDetail"

        let careHeading = UILabel()
        careHeading.font = .systemFont(ofSize: 13, weight: .semibold)
        careHeading.textColor = .secondaryLabel
        careHeading.text = "PLANT CARE"

        let waterButton = plainButton(title: "Water this plant", action: #selector(waterPlant))
        waterButton.accessibilityIdentifier = "WaterPlant"

        let repotButton = plainButton(title: "Repot", action: #selector(repotPlant))
        repotButton.accessibilityIdentifier = "RepotPlant"

        contentStack.addArrangedSubview(productImageView)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(priceLabel)
        contentStack.addArrangedSubview(descriptionLabel)
        contentStack.addArrangedSubview(addButton)
        contentStack.addArrangedSubview(careHeading)
        contentStack.addArrangedSubview(waterButton)
        contentStack.addArrangedSubview(repotButton)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),

            productImageView.heightAnchor.constraint(equalToConstant: 220),
            addButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    private func recordProductView() {
        let span = ShopTrace.begin(operation: "product.detail", description: "View plant", bindChildToScope: false)
        span.setData(value: "product_detail", key: "screen")
        span.setData(value: plantTitle, key: "plant.title")
        span.setData(value: plantId, key: "plant.id")
        span.setData(value: plantPrice, key: "plant.price")
        SentrySDK.configureScope { scope in
            scope.setTag(value: "product_detail", key: "screen")
            scope.setExtra(value: self.plantTitle, key: "plant.title")
            scope.setExtra(value: self.plantPrice, key: "plant.price")
        }
        SentrySDK.logger.info(
            "Product detail viewed",
            attributes: [
                "plantTitle": plantTitle,
                "plantId": plantId,
                "plantPrice": plantPrice,
                "screen": "product_detail",
            ])
        SentrySDK.metrics.count(
            key: "product.viewed",
            value: 1,
            attributes: ["plant_title": plantTitle, "plant_id": plantId]
        )
        renderPhotoOnMainThread(parent: span)
        span.finish()
    }

    /// Main-thread photo work. Long enough for a frozen frame, short of the 2s hang threshold.
    private func renderPhotoOnMainThread(parent: Span) {
        let span = parent.startChild(operation: "ui.render", description: "Render plant photo")
        let imageURL = product.imgCropped ?? product.img ?? ""
        span.setData(value: imageURL, key: "image.url")
        span.setData(value: plantTitle, key: "plant.title")
        loadPhoto(from: imageURL)

        let started = Date()
        var iterations = 0
        while Date().timeIntervalSince(started) < 0.8 {
            iterations &+= 1
        }
        span.setData(value: iterations, key: "render.iterations")
        span.setData(value: 800, key: "budget_ms")
        SentrySDK.logger.info(
            "Plant photo rendered on the main thread",
            attributes: [
                "plantTitle": plantTitle,
                "budgetMs": 800,
                "imageURL": imageURL,
            ])
        span.finish()
    }

    private func loadPhoto(from imageURL: String) {
        guard let url = URL(string: imageURL) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.productImageView.image = image
            }
        }.resume()
    }

    @objc private func addToCart() {
        let span = ShopTrace.begin(operation: "cart.add", description: "Add plant to cart", bindChildToScope: false)
        span.setData(value: plantTitle, key: "plant.title")
        span.setData(value: plantId, key: "plant.id")
        span.setData(value: plantPrice, key: "plant.price")
        ShoppingCart.addProduct(product: product)
        let cartSize = ShoppingCart.instance.items.count
        span.setData(value: cartSize, key: "cart.item_count")
        span.setData(value: ShoppingCart.instance.total, key: "cart.total")
        SentrySDK.logger.info(
            "Product added to cart",
            attributes: [
                "plantTitle": plantTitle,
                "plantId": plantId,
                "plantPrice": plantPrice,
                "cartSize": cartSize,
                "cartTotal": ShoppingCart.instance.total,
            ])
        SentrySDK.metrics.count(key: "cart.item_added", value: 1, attributes: ["plant_title": plantTitle])
        SentrySDK.metrics.gauge(key: "cart.size", value: Double(cartSize))
        span.finish()
    }

    /// Blocks the main thread past `appHangTimeoutInterval` (2s).
    @objc private func waterPlant() {
        let span = ShopTrace.begin(operation: "watering.schedule", description: "Calculate watering schedule", bindChildToScope: true)
        span.setData(value: plantTitle, key: "plant.title")
        span.setData(value: plantId, key: "plant.id")
        span.setData(value: 3000, key: "duration_ms")
        span.setData(value: "product_detail", key: "screen")
        SentrySDK.logger.warn(
            "Watering schedule blocked the main thread",
            attributes: [
                "plantTitle": plantTitle,
                "plantId": plantId,
                "durationMs": 3000,
                "screen": "product_detail",
            ])
        SentrySDK.metrics.count(key: "plant.watering", value: 1, attributes: ["plant_title": plantTitle])
        Thread.sleep(forTimeInterval: 3)
        span.finish()
    }

    /// Native crash from a plant-care action. `SentrySDK.crash()` does not return.
    @objc private func repotPlant() {
        let span = ShopTrace.begin(operation: "nursery.repot", description: "Repot plant", bindChildToScope: true)
        span.setData(value: plantTitle, key: "plant.title")
        span.setData(value: plantId, key: "plant.id")
        span.setData(value: plantPrice, key: "plant.price")
        SentrySDK.configureScope { scope in
            scope.setTag(value: "repot", key: "shop.action")
            scope.setTag(value: self.plantTitle, key: "plant.title")
            scope.setContext(
                value: [
                    "plant_title": self.plantTitle,
                    "plant_id": self.plantId,
                    "plant_price": self.plantPrice,
                    "screen": "product_detail",
                ],
                key: "plant"
            )
        }
        SentrySDK.logger.fatal(
            "Repotting crashed in the nursery",
            attributes: [
                "plantTitle": plantTitle,
                "plantId": plantId,
                "plantPrice": plantPrice,
                "screen": "product_detail",
            ])
        SentrySDK.metrics.count(key: "plant.repot", value: 1, attributes: ["plant_title": plantTitle])
        SentrySDK.crash()
    }

    private var plantTitle: String { product.title ?? "unknown" }
    private var plantId: String { product.productId ?? "unknown" }
    private var plantPrice: Int { Int(product.price ?? "") ?? 0 }
    private var priceText: String { "$\(product.price ?? "0")" }

    private func filledButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        button.backgroundColor = EmpowerPlantTheme.buttonBackground
        button.layer.cornerRadius = 8
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func plainButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(EmpowerPlantTheme.primary, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
}
