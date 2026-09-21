import SentrySwift
import UIKit

class CartViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let checkoutService: CheckoutServicing

    let tableView: UITableView = {
        let table = UITableView()
        table.register(CartItemCell.self, forCellReuseIdentifier: CartItemCell.reuseIdentifier)
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    private let totalFooter: UIView = {
        let v = UIView()
        v.backgroundColor = EmpowerPlantTheme.cardBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let totalLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = EmpowerPlantTheme.textHeader
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    init(checkoutService: CheckoutServicing = Dependencies.checkoutService) {
        self.checkoutService = checkoutService
        SentrySDK.logger.debug("CartViewController initialized with checkout service")
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        checkoutService = Dependencies.checkoutService
        SentrySDK.logger.debug("CartViewController initialized with coder")
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        SentrySDK.logger.debug("CartViewController viewDidLoad")
        title = "Cart"

        // Table view
        self.view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self

        // Total footer
        totalFooter.addSubview(totalLabel)
        self.view.addSubview(totalFooter)

        // Add a top border to the footer
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        totalFooter.addSubview(separator)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: totalFooter.topAnchor),

            totalFooter.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            totalFooter.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            totalFooter.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            totalFooter.heightAnchor.constraint(equalToConstant: 60),

            totalLabel.trailingAnchor.constraint(equalTo: totalFooter.trailingAnchor, constant: -20),
            totalLabel.centerYAnchor.constraint(equalTo: totalFooter.centerYAnchor),

            separator.topAnchor.constraint(equalTo: totalFooter.topAnchor),
            separator.leadingAnchor.constraint(equalTo: totalFooter.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: totalFooter.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
        ])

        totalLabel.text = "Total: $\(ShoppingCart.instance.total)"

        configureNavigationItems()
        checkRelease()

        SentrySDK.logger.debug(
            "CartViewController loaded with cart total",
            attributes: [
                "cartTotal": ShoppingCart.instance.total,
                "cartItemCount": ShoppingCart.instance.items.count,
            ])
        SentrySDK.reportFullyDisplayed()
    }

    private func configureNavigationItems() {
        SentrySDK.logger.debug("CartViewController configuring navigation items")
        let purchaseButton = UIButton(type: .system)
        purchaseButton.setTitle("  Purchase  ", for: .normal)
        if #unavailable(iOS 26.0) {
            purchaseButton.setTitleColor(.white, for: .normal)
            purchaseButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
            purchaseButton.backgroundColor = EmpowerPlantTheme.buttonBackground
            purchaseButton.layer.cornerRadius = 4
        }
        purchaseButton.addTarget(self, action: #selector(purchase), for: .touchUpInside)
        purchaseButton.accessibilityIdentifier = "Purchase"

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: purchaseButton)
    }

    @objc
    func purchase() {
        SentrySDK.logger.debug("purchase called")
        SentrySDK.logger.info(
            "Purchase initiated",
            attributes: [
                "cartTotal": ShoppingCart.instance.total,
                "itemCount": ShoppingCart.instance.items.count,
            ])

        // Simulate potential app hang scenario for AppHang V2 demonstration
        // This creates a brief delay that could trigger hang detection if it exceeds threshold
        DispatchQueue.main.async {
            // Simulate processing delay that might cause UI to appear unresponsive
            Thread.sleep(forTimeInterval: 0.5)  // 500ms delay - under 2s threshold but shows interaction
        }

        checkoutService.purchase(cart: setJson()) { [weak self] result in
            guard let self else { return }
            self.performCheckoutFileIO()

            switch result {
            case .success:
                SentrySDK.logger.info(
                    "Purchase completed successfully",
                    attributes: ["cartTotal": ShoppingCart.instance.total]
                )
            case .failure(let error):
                SentrySDK.logger.error(
                    "Purchase failed with server error",
                    attributes: ["error": error.localizedDescription]
                )
                ErrorToastManager.shared.logErrorAndShowToast(
                    error: error,
                    message: "Purchase failed: \(error.localizedDescription)",
                    showFeedbackOption: true
                )
            }
        }
    }

    // Perform file I/O operations during checkout for Sentry File I/O Tracking demonstration
    private func performCheckoutFileIO() {
        SentrySDK.logger.debug("performCheckoutFileIO called")
        // Create temporary file to demonstrate file I/O tracking
        let tempDir = FileManager.default.temporaryDirectory
        let checkoutLogFile = tempDir.appendingPathComponent("checkout_log_\(UUID().uuidString).txt")

        let checkoutData = """
            Checkout initiated at: \(Date())
            Cart total: \(ShoppingCart.instance.total)
            Items count: \(ShoppingCart.instance.items.count)
            User interaction: Purchase button tapped
            """.data(using: .utf8)!

        do {
            try checkoutData.write(to: checkoutLogFile)

            // Simulate reading the file back (common in checkout processes)
            let readData = try Data(contentsOf: checkoutLogFile)
            SentrySDK.logger.debug(
                "Checkout log written and read",
                attributes: [
                    "bytesRead": readData.count
                ])

            // Clean up the temporary file
            try FileManager.default.removeItem(at: checkoutLogFile)
        } catch {
            SentrySDK.logger.error(
                "File I/O error during checkout",
                attributes: [
                    "error": error.localizedDescription
                ])
        }
    }

    // total, quantities, items
    func setJson() -> [String: Any] {
        SentrySDK.logger.debug("setJson called")

        // total DONE
        // quantities DONE below
        // TODO: items

        let json: [String: Any] = [
            "form": ["email": "will@example.com"],  // TODO: email update + check if all tx's+errors have email
            "cart": [
                "total": ShoppingCart.instance.total,
                "quantities": [
                    "3": ShoppingCart.instance.quantities.plantMood,
                    "4": ShoppingCart.instance.quantities.botanaVoice,
                    "5": ShoppingCart.instance.quantities.plantStroller,
                    "6": ShoppingCart.instance.quantities.plantNodes,
                ],
                "items": [
                    ["id": "4", "title": "Plant Nodes"]
                    // ["id":"5", "title":"Plant Stroller"]
                ],
            ],
            "validate_inventory": "true",
        ]

        return json
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // TODO: could compute the length based on length of quantities.botanaVoice, plantStroller, nodeVoices, etc.
        // or continue showing all products, even if quantity is 0. the screen looks more full this way
        SentrySDK.logger.debug(
            "Cart tableView numberOfRowsInSection",
            attributes: [
                "section": section,
                "rowCount": 4,
            ])
        return 4  // products.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        SentrySDK.logger.debug(
            "Cart tableView cellForRowAt",
            attributes: [
                "row": indexPath.row,
                "section": indexPath.section,
            ])
        let cell =
            tableView.dequeueReusableCell(withIdentifier: CartItemCell.reuseIdentifier, for: indexPath) as! CartItemCell

        let quantities: [(String, Int)] = [
            ("Plant Mood", ShoppingCart.instance.quantities.plantMood),
            ("Botana Voice", ShoppingCart.instance.quantities.botanaVoice),
            ("Plant Stroller", ShoppingCart.instance.quantities.plantStroller),
            ("Plant Nodes", ShoppingCart.instance.quantities.plantNodes),
        ]

        let item = quantities[indexPath.row]
        cell.configure(name: item.0, quantity: item.1)

        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
