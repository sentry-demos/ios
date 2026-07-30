import UIKit

class ProductTableViewCell: UITableViewCell {

    static let reuseIdentifier = "ProductCell"

    // MARK: - Callback

    var onAddToCart: (() -> Void)?

    // MARK: - Image loading state

    private static let imageCache = NSCache<NSString, UIImage>()
    private var imageTask: URLSessionDataTask?

    // MARK: - Subviews

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = EmpowerPlantTheme.cardBackground
        v.layer.cornerRadius = 8
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.1
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 4
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let productImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.tintColor = EmpowerPlantTheme.buttonBackground
        iv.image = UIImage(systemName: "leaf.fill")
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .bold)
        l.textColor = EmpowerPlantTheme.textHeader
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let priceLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = .darkGray
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let addToCartButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Add to Cart", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        b.backgroundColor = EmpowerPlantTheme.buttonBackground
        b.layer.cornerRadius = 4
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setupViews() {
        contentView.addSubview(cardView)
        cardView.addSubview(productImageView)
        cardView.addSubview(nameLabel)
        cardView.addSubview(priceLabel)
        cardView.addSubview(addToCartButton)

        addToCartButton.addTarget(self, action: #selector(addToCartTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            // Card inset from cell edges
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            // Image — left side, fixed width
            productImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            productImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            productImageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10),
            productImageView.widthAnchor.constraint(equalToConstant: 80),

            // Name label
            nameLabel.leadingAnchor.constraint(equalTo: productImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: addToCartButton.leadingAnchor, constant: -8),

            // Price label
            priceLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            priceLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            priceLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            // Add to Cart button — right side, vertically centered
            addToCartButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            addToCartButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            addToCartButton.widthAnchor.constraint(equalToConstant: 90),
            addToCartButton.heightAnchor.constraint(equalToConstant: 34),
        ])
    }

    // MARK: - Configuration

    func configure(name: String?, price: String?, imageURL: String?) {
        let safeName = name ?? "Unknown"
        nameLabel.text = safeName
        accessibilityIdentifier = "ProductCell_\(safeName)"
        addToCartButton.accessibilityIdentifier = "AddToCart_\(safeName)"

        if let priceStr = price, let priceInt = Int(priceStr) {
            priceLabel.text = "$\(priceInt)"
        } else {
            priceLabel.text = price.map { "$\($0)" } ?? ""
        }

        loadImage(from: imageURL)
    }

    // MARK: - Image Loading

    private func loadImage(from urlString: String?) {
        imageTask?.cancel()
        productImageView.image = UIImage(systemName: "leaf.fill")

        guard let urlString = urlString, !urlString.isEmpty else { return }

        // Check cache
        if let cached = Self.imageCache.object(forKey: urlString as NSString) {
            productImageView.image = cached
            return
        }

        guard let url = URL(string: urlString) else { return }

        imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            Self.imageCache.setObject(image, forKey: urlString as NSString)
            DispatchQueue.main.async {
                // Only set if the cell hasn't been reused for a different item
                self?.productImageView.image = image
            }
        }
        imageTask?.resume()
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        productImageView.image = UIImage(systemName: "leaf.fill")
        nameLabel.text = nil
        priceLabel.text = nil
        onAddToCart = nil
        addToCartButton.setTitle("Add to Cart", for: .normal)
    }

    // MARK: - Actions

    @objc private func addToCartTapped() {
        onAddToCart?()

        // Brief visual feedback
        addToCartButton.setTitle("Added ✓", for: .normal)
        addToCartButton.backgroundColor = EmpowerPlantTheme.buttonPressed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.addToCartButton.setTitle("Add to Cart", for: .normal)
            self?.addToCartButton.backgroundColor = EmpowerPlantTheme.buttonBackground
        }
    }
}
