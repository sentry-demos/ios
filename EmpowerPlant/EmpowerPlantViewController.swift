//
//  EmpowerPlantViewController.swift
//  EmpowerPlant
//
//  Created by William Capozzoli on 3/8/22.
//

import UIKit
import Sentry

class EmpowerPlantViewController: UIViewController {
    let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    // Product Entity, gets written to CoreData
    var products = [Product]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Empower Plants"
        
        self.view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        configureNavigationItems()
        getAllProductsFromServer()
        getAllProductsFromDb()
        readCurrentDirectory()
        performLongFileOperation()
        processProducts()
        checkRelease()
        
        NotificationCenter.default.addObserver(forName: modifiedDBNotificationName, object: nil, queue: nil) { _ in
            self.getAllProductsFromDb()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        SentrySDK.reportFullyDisplayed()
    }
    
    func performLongFileOperation() {
        let longString = String(repeating: UUID().uuidString, count: 5_000_000)
        let data = longString.data(using: .utf8)!
        let filePath = FileManager.default.temporaryDirectory.appendingPathComponent("tmp" + UUID().uuidString)
        try! data.write(to: filePath)
        try! FileManager.default.removeItem(at: filePath)
    }

    func processProducts() {
        let span = SentrySDK.span?.startChild(operation: "product_processing")
        _ = getIterator(42);
        sleep(50 / 1000)
        span?.finish()
    }

    func getIterator(_ n: Int) -> Int {
       if (n <= 0) {
           return 0;
       }
       if (n == 1 || n == 2) {
           return 1;
       }
       return getIterator(n - 1) + getIterator(n - 2);
   }

    
    func readCurrentDirectory() {
        let path = FileManager.default.currentDirectoryPath
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: path)
            let loop = fibonacciSeries(num: items.count)
            for i in 1...loop {
                readDirectory(path: path)
            }
        } catch {
            // TODO: error
        }
    }
    
    func readDirectory(path: String) {
        let fm = FileManager.default
        
        do {
            let items = try fm.contentsOfDirectory(atPath: path)
            
            for item in items {
                var isDirectory: ObjCBool = false
                if fm.fileExists(atPath: item, isDirectory: &isDirectory) {
                    readDirectory(path: item)
                } else {
                    return
                }
            }
        } catch {
            // TODO: error
        }
        
    }
    
    func fibonacciSeries(num: Int) -> Int{
        var n1 = 0
        var n2 = 1

        var nR = 0
        for _ in 0..<num{
            nR = n1
            n1 = n2
            n2 = nR + n2
        }
        
        if (n1 < 500) {
            return fibonacciSeries(num: n1)
        }
        return n1
    }
    
    @objc
    func addToDb() {
        let alert = UIAlertController(title: "New Product",
                                      message: "Enter new product title",
                                      preferredStyle: .alert)
        alert.addTextField(configurationHandler: nil)
        
        alert.addAction(UIAlertAction(title:"Submit", style: .cancel, handler: { [weak self] _ in
            guard let field = alert.textFields?.first, let text = field.text, !text.isEmpty else {
                return
            }
            CoreDataController.shared.createProduct(productId: "123", title: text, productDescription: "product.description", productDescriptionFull: "product.description.full", img:"img", imgCropped:"img.cropped", price:"1")
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func configureNavigationItems() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "cart"),
            style: .plain,
            target: self,
            action: #selector(goToCart)
        )
        self.navigationItem.rightBarButtonItem?.accessibilityIdentifier = "Cart"
        
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: self,
            action: #selector(goToListApp)
        ), UIBarButtonItem(title: "DB", style: .plain, target: self, action: #selector(dbActions))]
    }
    
    @objc func dbActions() {
        let actionSheet = UIAlertController(title: "Database actions", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Generate items", style: .default, handler: { _ in
            self.generateDBItems()
        }))
        actionSheet.addAction(UIAlertAction(title: "Clear DB", style: .default, handler: { _ in
            wipeDB()
            self.getAllProductsFromDb()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .destructive))
        present(actionSheet, animated: true)
    }
    
    func generateDBItems() {
        let defaultTotalItems = 100_000
        let alert = UIAlertController(title: "Add items", message: nil, preferredStyle: .alert)

        var numberOfItemsTextField: UITextField?
        alert.addTextField { textfield in
            textfield.placeholder = "Number of items (default: \(defaultTotalItems))"
            textfield.keyboardType = .numberPad
            numberOfItemsTextField = textfield
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            var totalItems = (numberOfItemsTextField?.text as? NSString)?.integerValue ?? defaultTotalItems
            if totalItems == 0 {
                totalItems = defaultTotalItems
            }
            CoreDataController.shared.generateDBItems(total: totalItems)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive))
        present(alert, animated: true)
    }
    
    func getAllProductsFromDb() {
        do {
            self.products = try CoreDataController.shared.getAllProducts()
            // TODO: make this a debug-level log
            // for product in self.products {
            //     print(product.productId, product.title, product.productDescriptionFull)
            // }
            refreshTable()
        }
        catch {
            // TODO: error
        }
    }
    
    /// - note Also writes them into database if we don't yet have any products
    func getAllProductsFromServer() {
        let startTime = Date()
        let urlStr = "https://application-monitoring-flask-dot-sales-engineering-sf.appspot.com/products-join"
        let url = URL(string: urlStr)!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            if let data = data {
                if let productsResponse = try? JSONDecoder().decode([ProductMap].self, from: data) {
                    if (self.products.count == 0) {
                        var operations = [BlockOperation]()
                        let saveOp = BlockOperation() {
                            do {
                                try CoreDataController.shared.context.save()
                                self.getAllProductsFromDb()
                            } catch {
                                // TODO: error
                            }
                        }
                        for product in productsResponse {
                            let addOp = BlockOperation() {
                                CoreDataController.shared.createProduct(product: product)
                            }
                            operations.append(addOp)
                            saveOp.addDependency(addOp)
                        }
                        if operations.count > 0 {
                            operations.append(saveOp)
                            OperationQueue.main.addOperations(operations, waitUntilFinished: false)
                        }
                    }
                } else {
                    print("Invalid Response")
                    // TODO: error
                }
            } else if let error = error {
                print("HTTP Request Failed \(error)")
                // TODO: error
            }
        }
        
        task.resume()
    }
    
    @objc
    func goToCart() {
        self.performSegue(withIdentifier: "goToCart", sender: self)
    }
    
    @objc
    func goToListApp() {
        self.performSegue(withIdentifier: "goToListApp", sender: self)
    }
    
    @objc
    func refreshTable() {
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
        return products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = products[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = model.title
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(products.count) items"
    }
}

// MARK: UITableViewDelegate
extension EmpowerPlantViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let product = products[indexPath.row]
        
        ShoppingCart.addProduct(product: product)
    }
}
