import UIKit

/// Small cart glyph with a compact red count on the icon's corner.
final class CartBadgeButton: UIView {
    var onTap: (() -> Void)?

    private let button: UIButton = {
        let button = UIButton(type: .system)
        let symbol = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        button.setImage(UIImage(systemName: "cart", withConfiguration: symbol), for: .normal)
        button.accessibilityIdentifier = "Cart"
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let badge: UILabel = {
        let label = UILabel()
        label.backgroundColor = .systemRed
        label.textColor = .white
        label.font = .systemFont(ofSize: 9, weight: .bold)
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.clipsToBounds = true
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
        clipsToBounds = false
        addSubview(button)
        addSubview(badge)
        button.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),

            badge.centerXAnchor.constraint(equalTo: button.centerXAnchor, constant: 8),
            badge.centerYAnchor.constraint(equalTo: button.centerYAnchor, constant: -8),
            badge.heightAnchor.constraint(equalToConstant: 12),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 12),
        ])
        ShopPrivacy.unmask(button)
        ShopPrivacy.unmask(badge)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: 32, height: 32)
    }

    func setCount(_ count: Int) {
        badge.isHidden = count <= 0
        badge.text = count > 0 ? "\(count)" : nil
    }

    @objc private func tapped() {
        onTap?()
    }
}
