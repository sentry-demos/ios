import UIKit

class CartItemCell: UITableViewCell {

    static let reuseIdentifier = "CartItemCell"

    // MARK: - Subviews

    private let productNameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = EmpowerPlantTheme.textHeader
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let quantityLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = .darkGray
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setupViews() {
        contentView.addSubview(productNameLabel)
        contentView.addSubview(quantityLabel)

        NSLayoutConstraint.activate([
            productNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            productNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            productNameLabel.trailingAnchor.constraint(equalTo: quantityLabel.leadingAnchor, constant: -12),

            quantityLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            quantityLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            quantityLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
        ])
    }

    // MARK: - Configuration

    func configure(name: String, quantity: Int) {
        productNameLabel.text = name
        quantityLabel.text = "Qty: \(quantity)"
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        productNameLabel.text = nil
        quantityLabel.text = nil
    }
}
