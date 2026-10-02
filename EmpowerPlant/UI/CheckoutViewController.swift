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
        var config = UIButton.Configuration.plain()
        config.title = "Feedback"
        config.baseForegroundColor = .white
        config.background.backgroundColor = .black
        config.background.cornerRadius = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 15, weight: .semibold)
            outgoing.foregroundColor = .white
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.backgroundColor = .black
        button.layer.backgroundColor = UIColor.black.cgColor
        button.tintColor = .white
        button.isOpaque = true
        button.alpha = 0
        button.isHidden = true
        button.accessibilityIdentifier = "CheckoutFeedback"
        button.translatesAutoresizingMaskIntoConstraints = false
        var applyingSolidColor = false
        button.configurationUpdateHandler = { button in
            guard !applyingSolidColor, var updated = button.configuration else { return }
            applyingSolidColor = true
            updated.background.backgroundColor = .black
            updated.baseForegroundColor = .white
            button.configuration = updated
            applyingSolidColor = false
        }
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
            self?.revealFeedbackCorner()
        }
    }

    @objc private func showCheckoutFeedback() {
        ShopClick.play()
        ShopFeedback.presentCheckoutForm()
    }

    private func layoutFeedbackCorner() {
        feedbackCorner.addTarget(self, action: #selector(showCheckoutFeedback), for: .touchUpInside)
        feedbackCorner.transform = CGAffineTransform(translationX: 48, y: 72)
        view.addSubview(feedbackCorner)
        NSLayoutConstraint.activate([
            feedbackCorner.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            feedbackCorner.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
        ShopPrivacy.unmask(feedbackCorner)
    }

    private func revealFeedbackCorner() {
        guard feedbackCorner.isHidden else { return }
        view.bringSubviewToFront(feedbackCorner)
        feedbackCorner.isHidden = false
        UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseOut]) {
            self.feedbackCorner.alpha = 1
            self.feedbackCorner.transform = .identity
        }
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
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(.black, for: .highlighted)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        button.backgroundColor = EmpowerPlantTheme.buttonBackground
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(pressDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(pressUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        button.addTarget(self, action: action, for: .touchUpInside)
        ShopPrivacy.unmask(button)
        return button
    }

    @objc private func pressDown(_ button: UIButton) {
        button.setTitleColor(.black, for: .normal)
        UIView.animate(withDuration: 0.12, delay: 0, options: [.allowUserInteraction, .curveEaseOut, .beginFromCurrentState]) {
            button.transform = CGAffineTransform(scaleX: 0.90, y: 0.90)
            button.backgroundColor = .white
        }
    }

    @objc private func pressUp(_ button: UIButton) {
        button.setTitleColor(.black, for: .normal)
        UIView.animate(
            withDuration: 0.45,
            delay: 0,
            usingSpringWithDamping: 0.55,
            initialSpringVelocity: 0.8,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            button.transform = .identity
            button.backgroundColor = EmpowerPlantTheme.buttonBackground
        }
    }
}
