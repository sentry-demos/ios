import SentrySwift
import UIKit

class EmpowerPlantViewController: UIViewController {

    private let productsService: ProductsServicing

    init(productsService: ProductsServicing = Dependencies.productsService) {
        self.productsService = productsService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        productsService = Dependencies.productsService
        super.init(coder: coder)
    }

    // CoreData database
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.register(ProductTableViewCell.self, forCellReuseIdentifier: ProductTableViewCell.reuseIdentifier)
        table.separatorStyle = .none
        table.backgroundColor = EmpowerPlantTheme.tableBackground
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    // Product Entity, gets written to CoreData
    var products = [Product]()

    override func viewDidLoad() {
        super.viewDidLoad()
        SentrySDK.logger.debug("EmpowerPlantViewController viewDidLoad")
        title = "Empower Plants"

        self.view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 120
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        // Configures the nav bar buttons
        configureNavigationItems()

        // ???: looks like this was already done?
        /* TODO: implement:
         1 get products from server (so we get http.client span)
         2 check if any products in Core Data -> If Not -> insert the products from response into Core Data
         3 get products from DB (so we get db.query span) and reload the table with this data
         */

        getAllProductsFromServer()
        getAllProductsFromDb()
        // readCurrentDirectory() Disabled to avoid scanning outside app sandbox
        performLongFileOperation()
        processProducts()
        checkRelease()

        NotificationCenter.default.addObserver(forName: modifiedDBNotificationName, object: nil, queue: nil) { _ in
            SentrySDK.logger.debug("Received modified DB notification, refreshing products from database")
            self.getAllProductsFromDb()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        SentrySDK.logger.debug("EmpowerPlantViewController viewDidAppear")
        SentrySDK.reportFullyDisplayed()
    }

    func performLongFileOperation() {
        SentrySDK.logger.debug("performLongFileOperation called")
        // Synchronous file I/O on the main thread to demonstrate Sentry's File I/O tracking
        // Use a bundled resource to avoid permissions and external paths
        if let sourceURL = Bundle.main.url(forResource: "mobydick", withExtension: "txt") {
            do {
                // Read large file synchronously (main thread)
                let data = try Data(contentsOf: sourceURL)
                SentrySDK.logger.debug(
                    "Read bundled resource for file I/O demo",
                    attributes: [
                        "bytesRead": data.count
                    ])
                // Write it to Documents and then delete, still on main thread
                if let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let dest = documents.appendingPathComponent("mobydick_copy_\(UUID().uuidString).txt")
                    try data.write(to: dest)
                    try FileManager.default.removeItem(at: dest)
                    SentrySDK.logger.debug("File I/O demo write and delete completed")
                } else {
                    SentrySDK.logger.warn("Documents directory not found for file I/O demo")
                }
            } catch {
                // Non-fatal: we only need to exercise file I/O for performance demo
                SentrySDK.logger.error(
                    "File I/O demo error",
                    attributes: [
                        "error": error.localizedDescription
                    ])
            }
        } else {
            SentrySDK.logger.warn("Bundled resource mobydick.txt not found for file I/O demo")
        }
    }

    func processProducts() {
        SentrySDK.logger.debug("processProducts called")
        let span = SentrySDK.span?.startChild(operation: "product_processing")
        _ = getIterator(42)
        sleep(50 / 1000)
        span?.finish()
        SentrySDK.logger.debug("processProducts finished")
    }

    func getIterator(_ n: Int) -> Int {
        if n <= 0 {
            return 0
        }
        if n == 1 || n == 2 {
            return 1
        }
        return getIterator(n - 1) + getIterator(n - 2)
    }

    func readCurrentDirectory() {
        SentrySDK.logger.debug("readCurrentDirectory called")
        let path = FileManager.default.currentDirectoryPath
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: path)
            SentrySDK.logger.debug(
                "Read current directory contents",
                attributes: [
                    "path": path,
                    "itemCount": items.count,
                ])
            let loop = fibonacciSeries(num: items.count)
            for i in 1...loop {
                readDirectory(path: path)
            }
        } catch {
            SentrySDK.logger.error(
                "Failed to read current directory",
                attributes: [
                    "path": path,
                    "error": error.localizedDescription,
                ])
            ErrorToastManager.shared.logErrorAndShowToast(
                error: error,
                message: "Failed to read current directory"
            )
        }
    }

    func readDirectory(path: String, depth: Int = 0) {
        SentrySDK.logger.debug(
            "readDirectory called",
            attributes: [
                "path": path,
                "depth": depth,
            ])
        // Limit recursion to prevent deep system traversal
        guard depth < 3 else {
            SentrySDK.logger.debug(
                "readDirectory recursion depth limit reached",
                attributes: [
                    "path": path,
                    "depth": depth,
                ])
            return
        }
        let fm = FileManager.default

        do {
            let items = try fm.contentsOfDirectory(atPath: path)

            for item in items {
                var isDirectory: ObjCBool = false
                let fullPath = (path as NSString).appendingPathComponent(item)
                if fm.fileExists(atPath: fullPath, isDirectory: &isDirectory) {
                    if isDirectory.boolValue {
                        readDirectory(path: fullPath, depth: depth + 1)
                    }
                } else {
                    SentrySDK.logger.debug(
                        "Path no longer exists during directory traversal",
                        attributes: [
                            "path": fullPath
                        ])
                    return
                }
            }
        } catch {
            SentrySDK.logger.error(
                "Failed to read directory",
                attributes: [
                    "path": path,
                    "error": error.localizedDescription,
                ])
            ErrorToastManager.shared.logErrorAndShowToast(
                error: error,
                message: "Failed to read directory: \(path)"
            )
        }

    }

    func fibonacciSeries(num: Int) -> Int {
        SentrySDK.logger.debug(
            "fibonacciSeries called",
            attributes: [
                "num": num
            ])
        // The value of 0th and 1st number of the fibonacci series are 0 and 1
        var n1 = 0
        var n2 = 1

        // To store the result
        var nR = 0
        // Adding two previous numbers to find ith number of the series
        for _ in 0..<num {
            nR = n1
            n1 = n2
            n2 = nR + n2
        }

        if n1 < 500 {
            return fibonacciSeries(num: n1)
        }
        return n1
    }

    @objc
    func addToDb() {
        SentrySDK.logger.debug("addToDb called")
        let alert = UIAlertController(
            title: "New Product",
            message: "Enter new product title",
            preferredStyle: .alert)
        alert.addTextField(configurationHandler: nil)

        alert.addAction(
            UIAlertAction(
                title: "Submit", style: .cancel,
                handler: { [weak self] _ in
                    guard let field = alert.textFields?.first, let text = field.text, !text.isEmpty else {
                        SentrySDK.logger.debug("addToDb submission ignored, title was empty")
                        return
                    }
                    SentrySDK.logger.info(
                        "Creating product from addToDb alert",
                        attributes: [
                            "title": text
                        ])
                    self?.createProduct(
                        productId: "123", title: text, productDescription: "product.description",
                        productDescriptionFull: "product.description.full", img: "img", imgCropped: "img.cropped",
                        price: "1")
                }))

        self.present(alert, animated: true, completion: nil)

        // ALSO WORKED
        // alert.addTextField()
        // let submitButton = UIAlertAction(title:"Add", style: .default) { (action) in
        //     let textfield = alert.textFields![0]
        // }
        // alert.addAction(submitButton)
        // self.present(alert, animated: true, completion: nil)
    }

    // Don't deprecate, this function is useful for development and testing
    @objc
    func clearDb() {
        SentrySDK.logger.info(
            "clearDb called",
            attributes: [
                "productCount": self.products.count
            ])
        // self.products was already set by viewDidLoad()
        // self.products = try context.fetch(Product.fetchRequest())
        for product in self.products {
            deleteProduct(product: product)
        }
        refreshTable()
    }

    private func configureNavigationItems() {
        SentrySDK.logger.debug("EmpowerPlantViewController configuring navigation items")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "cart"),
            style: .plain,
            target: self,
            action: #selector(goToCart)  // addToDb
        )
        self.navigationItem.rightBarButtonItem?.accessibilityIdentifier = "Cart"
        // self.navigationItem.rightBarButtonItem?.badgeValue = "\(1)"

        self.navigationItem.leftBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(systemName: "ellipsis"),
                style: .plain,
                target: self,
                action: #selector(goToListApp)
            ), UIBarButtonItem(title: "DB", style: .plain, target: self, action: #selector(dbActions)),
        ]
    }

    @objc func dbActions() {
        SentrySDK.logger.debug("dbActions called")
        let actionSheet = UIAlertController(title: "Database actions", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(
            UIAlertAction(
                title: "Generate items", style: .default,
                handler: { _ in
                    SentrySDK.logger.debug("dbActions: Generate items selected")
                    self.generateDBItems()
                }))
        actionSheet.addAction(
            UIAlertAction(
                title: "Clear DB", style: .default,
                handler: { _ in
                    SentrySDK.logger.debug("dbActions: Clear DB selected")
                    wipeDB()
                    NotificationCenter.default.post(name: modifiedDBNotificationName, object: nil)
                }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .destructive))
        present(actionSheet, animated: true)
    }

    func generateDBItems() {
        SentrySDK.logger.debug("generateDBItems called")
        let defaultTotalItems = 100_000
        let alert = UIAlertController(title: "Add items", message: nil, preferredStyle: .alert)

        var numberOfItemsTextField: UITextField?
        alert.addTextField { textfield in
            textfield.placeholder = "Number of items (default: \(defaultTotalItems))"
            textfield.keyboardType = .numberPad
            numberOfItemsTextField = textfield
        }
        alert.addAction(
            UIAlertAction(title: "OK", style: .default) { _ in
                var totalItems = (numberOfItemsTextField?.text as? NSString)?.integerValue ?? defaultTotalItems
                if totalItems == 0 {
                    SentrySDK.logger.debug("generateDBItems: input was zero or invalid, using default item count")
                    totalItems = defaultTotalItems
                }
                var itemsPerBatch = 1_000
                let batches = totalItems / itemsPerBatch
                SentrySDK.logger.info(
                    "Generating DB items",
                    attributes: [
                        "totalItems": totalItems,
                        "itemsPerBatch": itemsPerBatch,
                        "batches": batches,
                    ])

                let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                DispatchQueue.global(qos: .utility).async {
                    for i in 0..<batches {
                        DispatchQueue.main.async {
                            for j in 0..<itemsPerBatch {
                                let newProduct = Product(context: context)
                                let productNum = i * itemsPerBatch + j

                                newProduct.productId = "Product \(productNum)"  // 'id' was a reserved word in swift
                                newProduct.title = "Product \(productNum)"
                                newProduct.productDescription = "Description for product \(i)"  // 'description' was a reserved word in swift
                                newProduct.productDescriptionFull = "Full description for product \(productNum)"
                                newProduct.img = "img"
                                newProduct.imgCropped = "img.cropped"
                                newProduct.price = "\(productNum)"
                            }

                            do {
                                try context.save()
                                NotificationCenter.default.post(name: modifiedDBNotificationName, object: nil)
                            } catch {
                                SentrySDK.logger.error(
                                    "Failed to save generated products to database",
                                    attributes: [
                                        "error": error.localizedDescription,
                                        "batch": i,
                                    ])
                                ErrorToastManager.shared.logErrorAndShowToast(
                                    error: error,
                                    message: "Failed to save generated products to database"
                                )
                            }
                        }
                        // add a small delay so it doesn't lock up the UI
                        usleep(100_000)  // 100 milliseconds
                    }
                }
            })
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive))
        present(alert, animated: true)
    }

    // Writes to CoreData database
    func createProduct(
        productId: String, title: String, productDescription: String, productDescriptionFull: String, img: String,
        imgCropped: String, price: String
    ) {
        SentrySDK.logger.debug(
            "createProduct called",
            attributes: [
                "productId": productId,
                "title": title,
                "price": price,
            ])
        let newProduct = Product(context: context)

        newProduct.productId = productId  // 'id' was a reserved word in swift
        newProduct.title = title
        newProduct.productDescription = productDescription  // 'description' was a reserved word in swift
        newProduct.productDescriptionFull = productDescriptionFull
        newProduct.img = img
        newProduct.imgCropped = imgCropped
        newProduct.price = price
    }

    // Don't deprecate this until major release of this demo
    func deleteProduct(product: Product) {
        SentrySDK.logger.debug(
            "deleteProduct called",
            attributes: [
                "productId": product.productId ?? "unknown",
                "title": product.title ?? "unknown",
            ])
        context.delete(product)
        do {
            try context.save()
        } catch {
            SentrySDK.logger.error(
                "Failed to delete product from database",
                attributes: [
                    "error": error.localizedDescription,
                    "productId": product.productId ?? "unknown",
                ])
            ErrorToastManager.shared.logErrorAndShowToast(
                error: error,
                message: "Failed to delete product from database"
            )
        }
    }

    func getAllProductsFromDb() {
        SentrySDK.logger.debug("getAllProductsFromDb called")
        do {
            self.products = try context.fetch(Product.fetchRequest())
            // Filter out "Plant Mood5"
            self.products = self.products.filter { $0.title != "Plant Mood5" }
            SentrySDK.logger.debug(
                "Products fetched from database",
                attributes: [
                    "productCount": self.products.count
                ])
            refreshTable()
        } catch {
            SentrySDK.logger.error(
                "Failed to fetch products from database",
                attributes: [
                    "error": error.localizedDescription
                ])
            ErrorToastManager.shared.logErrorAndShowToast(
                error: error,
                message: "Failed to fetch products from database"
            )
        }
    }

    // Also writes them into database if database is empty
    func getAllProductsFromServer() {
        SentrySDK.logger.debug("getAllProductsFromServer called")

        productsService.fetchProducts { [weak self] result in
            switch result {
            case .success(let productsResponse):
                DispatchQueue.main.async {
                    guard let self else { return }
                    guard self.products.isEmpty else {
                        SentrySDK.logger.debug(
                            "Skipping server product import, local cache already populated",
                            attributes: ["cachedProductCount": self.products.count]
                        )
                        return
                    }

                    SentrySDK.logger.debug(
                        "Local product cache empty, writing server products to database",
                        attributes: ["productCount": productsResponse.count]
                    )
                    var operations = [BlockOperation]()
                    let saveOp = BlockOperation {
                        do {
                            try self.context.save()
                            self.getAllProductsFromDb()
                        } catch {
                            ErrorToastManager.shared.logErrorAndShowToast(
                                error: error,
                                message: "Failed to save products from server to database"
                            )
                        }
                    }

                    for product in productsResponse {
                        let addOp = BlockOperation {
                            self.createProduct(
                                productId: String(product.id), title: product.title,
                                productDescription: product.description,
                                productDescriptionFull: product.descriptionfull, img: product.img,
                                imgCropped: product.imgcropped, price: String(product.price))
                        }
                        operations.append(addOp)
                        saveOp.addDependency(addOp)
                    }

                    if !operations.isEmpty {
                        SentrySDK.logger.debug(
                            "Scheduling product write operations",
                            attributes: ["operationCount": operations.count]
                        )
                        operations.append(saveOp)
                        OperationQueue.main.addOperations(operations, waitUntilFinished: false)
                    }
                }
            case .failure(let error):
                ErrorToastManager.shared.logErrorAndShowToast(
                    error: error,
                    message: "Failed to fetch products from server"
                )
            }
        }
    }

    @objc
    func goToCart() {
        SentrySDK.logger.debug("goToCart called")
        self.performSegue(withIdentifier: "goToCart", sender: self)
    }

    @objc
    func goToListApp() {
        SentrySDK.logger.debug("goToListApp called")
        self.performSegue(withIdentifier: "goToListApp", sender: self)
    }

    @objc
    func refreshTable() {
        SentrySDK.logger.debug("refreshTable called")
        // ???: why is this executing so many times on load?
        // !!!: because it is called from createProduct, which is called for each item in the response from the network request to get products from server. In general, it's better to use UITableView.insertRow(...) instead of UITableView.reloadData() when simply adding things to the table.
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}

// MARK: UITableViewDataSource
extension EmpowerPlantViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        SentrySDK.logger.debug(
            "Products tableView numberOfRowsInSection",
            attributes: [
                "section": section,
                "rowCount": products.count,
            ])
        return products.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        SentrySDK.logger.debug(
            "Products tableView cellForRowAt",
            attributes: [
                "row": indexPath.row,
                "section": indexPath.section,
            ])
        let model = products[indexPath.row]
        let cell =
            tableView.dequeueReusableCell(withIdentifier: ProductTableViewCell.reuseIdentifier, for: indexPath)
            as! ProductTableViewCell
        cell.configure(name: model.title, price: model.price, imageURL: model.imgCropped ?? model.img)
        cell.onAddToCart = { [weak self] in
            guard let self = self else { return }
            SentrySDK.logger.info(
                "Product selected and added to cart",
                attributes: [
                    "productId": model.productId ?? "unknown",
                    "productTitle": model.title ?? "unknown",
                    "selectedIndex": indexPath.row,
                ])
            ShoppingCart.addProduct(product: model)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        SentrySDK.logger.debug(
            "Products tableView titleForHeaderInSection",
            attributes: [
                "section": section,
                "productCount": products.count,
            ])
        return "\(products.count) items"
    }
}

// MARK: UITableViewDelegate
extension EmpowerPlantViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        SentrySDK.logger.debug(
            "Products tableView didSelectRowAt",
            attributes: [
                "row": indexPath.row,
                "section": indexPath.section,
            ])
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
