import Darwin
import SentrySwift
import UIKit

enum PurchaseError: Error, LocalizedError {
    case insufficientInventory

    var errorDescription: String? {
        "Insufficient inventory available"
    }
}

protocol URLSessionProtocol {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)
        -> URLSessionDataTaskProtocol
}

protocol URLSessionDataTaskProtocol {
    func resume()
}

class CartViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // private let session: URLSessionProtocol

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

    // Used for mocking in unit test
    init(session: URLSessionProtocol = URLSession.shared as! URLSessionProtocol) {
        // self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        // fatalError("init(coder:) has not been implemented")
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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

        print("CartViewController | TOTAL", ShoppingCart.instance.total)
        SentrySDK.reportFullyDisplayed()
    }

    private func configureNavigationItems() {
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
        let checkoutSpan = beginCheckoutSpan()
        let logger = SentrySDK.logger
        logger.info(
            "Purchase initiated",
            attributes: [
                "cartTotal": ShoppingCart.instance.total,
                "itemCount": ShoppingCart.instance.items.count,
            ])
        recordCheckoutMetrics()
        processCart(on: checkoutSpan)

        // use localhost for development against dev-backend
        // let url = URL(string: "http://127.0.0.1:8080/checkout")!
        let url = URL(string: "https://flask.empower-plant.com/checkout")!

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"

        let bodyData = try? JSONSerialization.data(
            withJSONObject: setJson(),
            options: []
        )
        request.httpBody = bodyData

        let task = URLSession.shared.dataTask(with: request) { _, response, _ in
            SentrySDK.configureScope { scope in
                scope.span = checkoutSpan
            }
            var outcome: SentrySpanStatus = .ok
            defer {
                checkoutSpan.finish(status: outcome)
                SentrySDK.configureScope { scope in
                    if scope.span?.spanId.sentrySpanIdString == checkoutSpan.spanId.sentrySpanIdString {
                        scope.span = nil
                    }
                }
            }

            let logger = SentrySDK.logger
            // Add file I/O operation during checkout for Sentry File I/O Tracking demonstration
            self.performCheckoutFileIO()

            // This handler is responsible for Flagship Error
            if let httpResponse = response as? HTTPURLResponse {
                if (httpResponse.statusCode) == 500 {
                    outcome = .internalError
                    let delivery = checkoutSpan.startChild(operation: "delivery.workflow", description: "Start delivery")
                    delivery.setData(value: 500, key: "http.status_code")
                    delivery.setData(value: ShoppingCart.instance.total, key: "cart.total")
                    delivery.setData(value: ShoppingCart.instance.items.count, key: "cart.item_count")
                    delivery.setData(value: "insufficient_inventory", key: "failure")
                    delivery.finish(status: .internalError)
                    logger.error(
                        "Purchase failed with server error",
                        attributes: [
                            "statusCode": 500,
                            "errorType": "insufficient_inventory",
                            "cartTotal": ShoppingCart.instance.total,
                            "itemCount": ShoppingCart.instance.items.count,
                            "endpoint": "https://flask.empower-plant.com/checkout",
                        ])
                    ErrorToastManager.shared.logErrorAndShowToast(
                        error: PurchaseError.insufficientInventory,
                        message: "Purchase failed: Insufficient inventory available (HTTP 500)",
                        scopeCallback: { scope in
                            scope.setTag(value: "checkout", key: "shop.action")
                            scope.setContext(
                                value: [
                                    "cart_total": ShoppingCart.instance.total,
                                    "item_count": ShoppingCart.instance.items.count,
                                    "status_code": 500,
                                    "endpoint": "https://flask.empower-plant.com/checkout",
                                    "failure": "insufficient_inventory",
                                ],
                                key: "checkout"
                            )
                        },
                        showFeedbackOption: true
                    )
                } else if (httpResponse.statusCode) == 200 {
                    logger.info(
                        "Purchase completed successfully",
                        attributes: [
                            "statusCode": 200,
                            "cartTotal": ShoppingCart.instance.total,
                        ])
                } else {
                    outcome = .internalError
                    logger.warn(
                        "Purchase completed with unexpected status",
                        attributes: [
                            "statusCode": httpResponse.statusCode
                        ])
                }
            }

            // not getting met
            // if let error = error {
            //    print("> HTTP Request Failed \(error)")
            //    SentrySDK.capture(error: error)
            // }

            // getting met whether it's a 200 or 500 - there's always a 'data' object here
            // if let data = data {
            //     print("> no error, do nothing", data)
            // }
        }

        task.resume()
    }

    /// Slow cart work on the checkout trace. Stays under the 2s hang threshold.
    private func processCart(on checkoutSpan: Span) {
        let span = checkoutSpan.startChild(operation: "cart.process", description: "Process cart")
        let itemCount = ShoppingCart.instance.items.count
        let total = ShoppingCart.instance.total
        span.setData(value: itemCount, key: "cart.item_count")
        span.setData(value: total, key: "cart.total")
        span.setData(value: 500, key: "duration_ms")
        Thread.sleep(forTimeInterval: 0.5)
        SentrySDK.logger.info(
            "Cart processed for checkout",
            attributes: [
                "itemCount": itemCount,
                "cartTotal": total,
                "durationMs": 500,
            ])
        span.finish()
    }

    /// Keeps purchase logs, checkout metrics, and the Flask request on one trace.
    private func beginCheckoutSpan() -> Span {
        let itemCount = ShoppingCart.instance.items.count
        let total = ShoppingCart.instance.total
        let span = ShopTrace.begin(operation: "checkout", description: "checkout", bindChildToScope: true)
        span.setData(value: "checkout", key: "shop.action")
        span.setData(value: itemCount, key: "cart.item_count")
        span.setData(value: total, key: "cart.total")
        span.setData(value: "https://flask.empower-plant.com/checkout", key: "endpoint")
        span.setTag(value: "checkout", key: "shop.action")
        return span
    }

    /// Application metrics. CPU, heap, frames, and energy stay on the profiler payload.
    private func recordCheckoutMetrics() {
        let itemCount = ShoppingCart.instance.items.count
        SentrySDK.metrics.count(
            key: "checkout.attempted",
            value: 1,
            attributes: ["item_count": itemCount]
        )
        SentrySDK.metrics.gauge(
            key: "checkout.cart_size",
            value: Double(itemCount)
        )
        if let footprint = Self.memoryFootprintBytes() {
            SentrySDK.metrics.gauge(
                key: "memory.usage",
                value: footprint,
                unit: .byte
            )
        }
    }

    /// phys_footprint from task_info(TASK_VM_INFO), the same reading the profiler stores as heap.
    private static func memoryFootprintBytes() -> Double? {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &info) { pointer -> kern_return_t in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), rebound, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        return Double(info.phys_footprint)
    }

    // Perform file I/O operations during checkout for Sentry File I/O Tracking demonstration
    private func performCheckoutFileIO() {
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
            print("Checkout log written and read: \(readData.count) bytes")

            // Clean up the temporary file
            try FileManager.default.removeItem(at: checkoutLogFile)
        } catch {
            print("File I/O error during checkout: \(error)")
        }
    }

    // total, quantities, items
    func setJson() -> [String: Any] {

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
        return 4  // products.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
