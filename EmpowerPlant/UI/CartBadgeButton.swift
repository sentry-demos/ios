import UIKit

/// Cart icon with a red count. The count is hidden when the cart is empty.
final class CartBadgeButton: UIView {
    var onTap: (() -> Void)?

    private let button: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "cart"), for: .normal)
        button.accessibilityIdentifier = "Cart"
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let badge: UILabel = {
        let label = UILabel()
        label.backgroundColor = .systemRed
        label.textColor = .white
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textAlignment = .center
        label.layer.cornerRadius = 9
        label.clipsToBounds = true
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        addSubview(button)
        addSubview(badge)
        button.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),

            badge.topAnchor.constraint(equalTo: topAnchor),
            badge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 4),
            badge.heightAnchor.constraint(equalToConstant: 18),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 18),
        ])
        ShopPrivacy.unmask(button)
        ShopPrivacy.unmask(badge)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: 44, height: 44)
    }

    func setCount(_ count: Int) {
        badge.isHidden = count <= 0
        badge.text = count > 0 ? " \(count) " : nil
    }

    @objc private func tapped() {
        onTap?()
    }
}
