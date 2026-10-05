import SentrySwift
import UIKit

class EmpowerPlantViewController: UIViewController {

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.register(ProductTableViewCell.self, forCellReuseIdentifier: ProductTableViewCell.reuseIdentifier)
        table.separatorStyle = .none
        table.backgroundColor = EmpowerPlantTheme.tableBackground
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    var products = [Product]()
    private var catalogSpan: Span?
    private let cartButton = CartBadgeButton()
    private static let productsEndpoint = "https://flask.empower-plant.com/products"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Empower Plants"

        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 120
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        configureNavigationItems()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshCartBadge),
            name: .shoppingCartDidChange,
            object: nil
        )
        loadCatalog()
        checkRelease()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ShopPrivacy.unmaskNavigationButtons(of: self)
        SentrySDK.configureScope { scope in
            scope.setTag(value: "product_list", key: "screen")
        }
        SentrySDK.reportFullyDisplayed()
        refreshCartBadge()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        ShopPrivacy.unmaskNavigationButtons(of: self)
    }

    private func configureNavigationItems() {
        let feedback = UIBarButtonItem(
            title: "Feedback",
            style: .plain,
            target: self,
            action: #selector(showFeedback)
        )
        feedback.accessibilityIdentifier = "Feedback"
        let more = UIBarButtonItem(
            title: "more",
            style: .plain,
            target: self,
            action: #selector(showDebugMenu)
        )
        more.accessibilityIdentifier = "more"
        navigationItem.leftBarButtonItems = [feedback, more]
        cartButton.onTap = { [weak self] in
            ShopClick.play()
            self?.goToCart()
        }
        let cartItem = UIBarButtonItem(customView: cartButton)
        if #available(iOS 26.0, *) {
            cartItem.hidesSharedBackground = true
        }
        navigationItem.rightBarButtonItem = cartItem
        refreshCartBadge()
    }

    @objc private func showFeedback() {
        ShopClick.play()
        SentrySDK.feedback.show()
    }

    @objc private func showDebugMenu() {
        ShopClick.play()
        navigationController?.pushViewController(ListAppViewController(), animated: true)
    }

    @objc private func refreshCartBadge() {
        cartButton.setCount(ShoppingCart.instance.items.count)
    }

    private func loadCatalog() {
        let span = ShopTrace.begin(operation: "catalog.load", description: "Load plant catalog", bindChildToScope: true)
        span.setData(value: "product_list", key: "screen")
        span.setData(value: Self.productsEndpoint, key: "endpoint")
        catalogSpan = span

        ShopBreadcrumb.record(
            message: "Catalog load started",
            category: "shop.catalog",
            screen: "product_list"
        )
        SentrySDK.logger.info(
            "Fetching products from server",
            attributes: [
                "screen": "product_list",
                "endpoint": Self.productsEndpoint,
            ])
        SentrySDK.metrics.count(key: "catalog.viewed", value: 1)

        readCatalogFileOnMainThread(parent: span)
        processProducts(parent: span)
        loadCachedProducts(parent: span)
        fetchProducts(catalogSpan: span)
    }

    /// Bounded main-thread file read so the catalog drops frames without an app hang.
    private func readCatalogFileOnMainThread(parent: Span) {
        let span = parent.startChild(operation: "file.read", description: "Read catalog copy")
        span.setData(value: "mobydick.txt", key: "file.name")
        guard let sourceURL = Bundle.main.url(forResource: "mobydick", withExtension: "txt") else {
            span.setData(value: "missing", key: "file.status")
            span.finish(status: .notFound)
            return
        }
        do {
            let handle = try FileHandle(forReadingFrom: sourceURL)
            let sample = try handle.read(upToCount: 256 * 1024) ?? Data()
            try handle.close()
            if let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let dest = documents.appendingPathComponent("catalog_copy.txt")
                try sample.write(to: dest)
                try FileManager.default.removeItem(at: dest)
            }
            span.setData(value: sample.count, key: "file.bytes")
            SentrySDK.logger.info(
                "Catalog file read on the main thread",
                attributes: [
                    "fileName": "mobydick.txt",
                    "bytes": sample.count,
                    "screen": "product_list",
                ])
            span.finish()
        } catch {
            span.setData(value: error.localizedDescription, key: "error")
            span.finish(status: .internalError)
            SentrySDK.logger.error(
                "Catalog file read failed",
                attributes: ["error": error.localizedDescription]
            )
        }
    }

    private func processProducts(parent: Span) {
        let span = parent.startChild(operation: "product.processing", description: "Process plant catalog")
        let iterations = 24
        let started = Date()
        let result = getIterator(iterations)
        Thread.sleep(forTimeInterval: 0.3)
        let elapsedMs = Int(Date().timeIntervalSince(started) * 1000)
        span.setData(value: iterations, key: "fibonacci.n")
        span.setData(value: result, key: "fibonacci.result")
        span.setData(value: elapsedMs, key: "duration_ms")
        SentrySDK.logger.info(
            "Plant catalog processed",
            attributes: [
                "fibonacciN": iterations,
                "durationMs": elapsedMs,
                "screen": "product_list",
            ])
        SentrySDK.metrics.distribution(
            key: "catalog.process_duration",
            value: Double(elapsedMs),
            unit: .millisecond
        )
        span.finish()
    }

    private func getIterator(_ n: Int) -> Int {
        if n <= 0 { return 0 }
        if n == 1 || n == 2 { return 1 }
        return getIterator(n - 1) + getIterator(n - 2)
    }

    private func loadCachedProducts(parent: Span) {
        let span = parent.startChild(operation: "db.query", description: "Read cached plants")
        do {
            products = try context.fetch(Product.fetchRequest())
            products = products.filter { $0.title != "Plant Mood5" }
            span.setData(value: products.count, key: "product.count")
            span.finish()
            refreshTable()
        } catch {
            span.setData(value: error.localizedDescription, key: "error")
            span.finish(status: .internalError)
            ErrorToastManager.shared.logErrorAndShowToast(
                error: error,
                message: "Failed to fetch products from database"
            )
        }
    }

    private func fetchProducts(catalogSpan: Span) {
        let startTime = Date()
        let url = URL(string: Self.productsEndpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        ShopSession.applyRequestHeaders(to: &request)
        let httpSpan = catalogSpan.startChild(operation: "http.client", description: "GET /products")
        httpSpan.setData(value: url.absoluteString, key: "url")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            let durationMs = Int(Date().timeIntervalSince(startTime) * 1000)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let decoded = data.flatMap { try? JSONDecoder().decode([CatalogProduct].self, from: $0) }
            let failureMessage = error?.localizedDescription ?? "Invalid response from server when fetching products"
            let fetchError = error

            Task { @MainActor in
                httpSpan.setData(value: statusCode, key: "http.status_code")
                httpSpan.setData(value: durationMs, key: "duration_ms")

                if let productsResponse = decoded {
                    httpSpan.finish()
                    self.finishCatalogDecode(
                        productsResponse: productsResponse,
                        durationMs: durationMs,
                        catalogSpan: catalogSpan
                    )
                } else {
                    httpSpan.finish(status: .internalError)
                    catalogSpan.finish(status: .internalError)
                    self.catalogSpan = nil
                    SentrySDK.logger.error(
                        "Failed to fetch products from server",
                        attributes: [
                            "durationMs": durationMs,
                            "statusCode": statusCode,
                            "error": failureMessage,
                        ])
                    if let fetchError {
                        ErrorToastManager.shared.logErrorAndShowToast(
                            error: fetchError,
                            message: "Failed to fetch products from server"
                        )
                    } else {
                        ErrorToastManager.shared.showErrorToast(message: failureMessage)
                    }
                }
            }
        }
        task.resume()
    }

    private func finishCatalogDecode(productsResponse: [CatalogProduct], durationMs: Int, catalogSpan: Span) {
        let decodeSpan = catalogSpan.startChild(operation: "catalog.decode", description: "Decode plant catalog")
        decodeSpan.setData(value: productsResponse.count, key: "product.count")
        decodeSpan.setData(value: durationMs, key: "http.duration_ms")
        decodeSpan.finish()

        SentrySDK.logger.info(
            "Products loaded",
            attributes: [
                "productCount": productsResponse.count,
                "durationMs": durationMs,
                "screen": "product_list",
            ])
        SentrySDK.metrics.gauge(key: "catalog.product_count", value: Double(productsResponse.count))
        SentrySDK.metrics.distribution(
            key: "catalog.load_duration",
            value: Double(durationMs),
            unit: .millisecond
        )

        guard products.isEmpty else {
            catalogSpan.setData(value: products.count, key: "product.count")
            catalogSpan.finish()
            self.catalogSpan = nil
            return
        }

        let persistSpan = catalogSpan.startChild(operation: "db.insert", description: "Save plant catalog")
        persistSpan.setData(value: productsResponse.count, key: "product.count")
        var operations = [BlockOperation]()
        let saveOp = BlockOperation {
            do {
                try self.context.save()
                self.products = try self.context.fetch(Product.fetchRequest())
                self.products = self.products.filter { $0.title != "Plant Mood5" }
                persistSpan.finish()
                catalogSpan.setData(value: self.products.count, key: "product.count")
                catalogSpan.finish()
                self.catalogSpan = nil
                self.refreshTable()
            } catch {
                persistSpan.setData(value: error.localizedDescription, key: "error")
                persistSpan.finish(status: .internalError)
                catalogSpan.finish(status: .internalError)
                self.catalogSpan = nil
                ErrorToastManager.shared.logErrorAndShowToast(
                    error: error,
                    message: "Failed to save products from server to database"
                )
            }
        }
        for product in productsResponse {
            let addOp = BlockOperation {
                self.createProduct(
                    productId: String(product.id),
                    title: product.title,
                    productDescription: product.description,
                    productDescriptionFull: product.descriptionfull,
                    img: product.img,
                    imgCropped: product.imgcropped,
                    price: String(product.price)
                )
            }
            operations.append(addOp)
            saveOp.addDependency(addOp)
        }
        if operations.isEmpty {
            persistSpan.finish()
            catalogSpan.finish()
            self.catalogSpan = nil
        } else {
            operations.append(saveOp)
            OperationQueue.main.addOperations(operations, waitUntilFinished: false)
        }
    }

    private func createProduct(
        productId: String, title: String, productDescription: String, productDescriptionFull: String, img: String,
        imgCropped: String, price: String
    ) {
        let newProduct = Product(context: context)
        newProduct.productId = productId
        newProduct.title = title
        newProduct.productDescription = productDescription
        newProduct.productDescriptionFull = productDescriptionFull
        newProduct.img = img
        newProduct.imgCropped = imgCropped
        newProduct.price = price
    }

    @objc func goToCart() {
        performSegue(withIdentifier: "goToCart", sender: self)
    }

    @objc func refreshTable() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}

private struct CatalogProduct: Decodable {
    let id: Int
    let title: String
    let description: String
    let descriptionfull: String
    let img: String
    let imgcropped: String
    let price: Int
}

extension EmpowerPlantViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        products.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = products[indexPath.row]
        let cell =
            tableView.dequeueReusableCell(withIdentifier: ProductTableViewCell.reuseIdentifier, for: indexPath)
            as! ProductTableViewCell
        cell.configure(name: model.title, price: model.price, imageURL: model.imgCropped ?? model.img)
        cell.onAddToCart = { [weak self] in
            self?.addPlantToCart(model)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "\(products.count) plants"
    }

    private func addPlantToCart(_ product: Product) {
        ShopClick.play()
        let title = product.title ?? "unknown"
        let plantId = product.productId ?? "unknown"
        let price = Int(product.price ?? "") ?? 0
        let span = ShopTrace.begin(operation: "cart.add", description: "Add plant to cart", bindChildToScope: false)
        span.setData(value: title, key: "plant.title")
        span.setData(value: plantId, key: "plant.id")
        span.setData(value: price, key: "plant.price")
        ShoppingCart.addProduct(product: product)
        let cartSize = ShoppingCart.instance.items.count
        span.setData(value: cartSize, key: "cart.item_count")
        span.setData(value: ShoppingCart.instance.total, key: "cart.total")
        ShopBreadcrumb.record(
            message: "Added plant to cart",
            category: "shop.cart",
            screen: "product_list",
            plantTitle: title,
            plantId: plantId,
            plantPrice: price
        )
        SentrySDK.logger.info(
            "Product added to cart",
            attributes: [
                "plantTitle": title,
                "plantId": plantId,
                "plantPrice": price,
                "cartSize": cartSize,
                "cartTotal": ShoppingCart.instance.total,
                "screen": "product_list",
            ])
        SentrySDK.metrics.count(key: "cart.item_added", value: 1, attributes: ["plant_title": title])
        SentrySDK.metrics.gauge(key: "cart.size", value: Double(cartSize))
        span.finish()
        ErrorToastManager.shared.showAddedToCart()
    }
}

extension EmpowerPlantViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let detail = ProductDetailViewController(product: products[indexPath.row])
        navigationController?.pushViewController(detail, animated: true)
    }
}
