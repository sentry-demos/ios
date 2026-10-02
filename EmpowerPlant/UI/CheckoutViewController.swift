import SentrySwift
import UIKit

/// Checkout reached from the cart. Contact info is prefilled the same way as the React Native shop.
/// Applying the promo fails and logs that the code expired. Place order runs the existing checkout failure.
final class CheckoutViewController: UIViewController {
    private weak var cart: CartViewController?
    private var applyingPromo = false

    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()

    private let stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let promoField = UITextField()
    private let feedbackCorner: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Feedback"
        config.cornerStyle = .capsule
        config.baseBackgroundColor = EmpowerPlantTheme.buttonBackground
        config.baseForegroundColor = .black
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 13, weight: .semibold)
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.isHidden = true
        button.accessibilityIdentifier = "CheckoutFeedback"
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private let promoError: UILabel = {
        let label = UILabel()
        label.text = "Unknown error applying promo code"
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    init(cart: CartViewController) {
        self.cart = cart
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Checkout"
        view.backgroundColor = EmpowerPlantTheme.tableBackground
        layoutForm()
        layoutFeedbackCorner()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ShopPrivacy.unmaskNavigationButtons(of: self)
        ShopPrivacy.unmask(promoError)
        ShopPrivacy.unmask(feedbackCorner)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        ShopPrivacy.unmaskNavigationButtons(of: self)
    }

    private func layoutForm() {
        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        let zipCode = String(Int.random(in: 10000...99999))
        let fields: [(String, String)] = [
            ("email", ShopSession.email),
            ("first name", "john"),
            ("last name", "doe"),
            ("address", "123 Hope St"),
            ("city", "San Francisco"),
            ("country/region", "USA"),
            ("state", "CA"),
            ("zip code", zipCode),
        ]
        for (placeholder, value) in fields {
            stack.addArrangedSubview(textField(placeholder: placeholder, text: value))
        }

        let promoHeading = UILabel()
        promoHeading.text = "Promo Code"
        promoHeading.font = .systemFont(ofSize: 17, weight: .semibold)
        promoHeading.textColor = EmpowerPlantTheme.textHeader
        stack.addArrangedSubview(promoHeading)

        promoField.placeholder = "promo code"
        promoField.text = "SAVE20"
        style(promoField)
        stack.addArrangedSubview(promoField)
        stack.addArrangedSubview(promoError)

        let apply = filledButton(title: "Apply", action: #selector(applyPromo))
        apply.accessibilityIdentifier = "ApplyPromo"
        stack.addArrangedSubview(apply)

        let place = filledButton(title: "Place your order", action: #selector(placeOrder))
        place.accessibilityIdentifier = "PlaceOrder"
        stack.addArrangedSubview(place)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),

            apply.heightAnchor.constraint(equalToConstant: 48),
            place.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    @objc private func applyPromo() {
        ShopClick.play()
        guard !applyingPromo else { return }
        applyingPromo = true
        promoError.isHidden = true
        let code = promoField.text ?? ""
        SentrySDK.logger.info(
            "Applying promo code: \(code)",
            attributes: [
                "promoCode": code,
                "action": "promo_apply",
            ])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [weak self] in
            guard let self else { return }
            self.applyingPromo = false
            let applied = self.promoField.text ?? code
            let responseBody =
                #"{"error":{"code":"expired","message":"Provided coupon code has expired."}}"#
            SentrySDK.logger.error(
                "Failed to apply promo code \(applied): HTTP 410 | Error: 'expired'",
                attributes: [
                    "promo_code": applied,
                    "http_status": 410,
                    "error_code": "expired",
                    "error_message": "Provided coupon code has expired.",
                    "response_body": responseBody,
                ])
            self.promoError.isHidden = false
        }
    }

    @objc private func placeOrder() {
        ShopClick.play()
        cart?.purchase { [weak self] in
            self?.feedbackCorner.isHidden = false
        }
    }

    @objc private func showCheckoutFeedback() {
        ShopClick.play()
        ShopFeedback.presentCheckoutForm()
    }

    private func layoutFeedbackCorner() {
        feedbackCorner.addTarget(self, action: #selector(showCheckoutFeedback), for: .touchUpInside)
        view.addSubview(feedbackCorner)
        NSLayoutConstraint.activate([
            feedbackCorner.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            feedbackCorner.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
        ShopPrivacy.unmask(feedbackCorner)
    }

    private func textField(placeholder: String, text: String) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.text = text
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        style(field)
        return field
    }

    private func style(_ field: UITextField) {
        field.borderStyle = .roundedRect
        field.backgroundColor = EmpowerPlantTheme.cardBackground
        field.font = .systemFont(ofSize: 16)
        field.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }

    private func filledButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        button.backgroundColor = EmpowerPlantTheme.buttonBackground
        button.layer.cornerRadius = 8
        button.addTarget(self, action: action, for: .touchUpInside)
        ShopPrivacy.unmask(button)
        return button
    }
}
