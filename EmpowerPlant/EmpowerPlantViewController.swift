//
//  EmpowerPlantViewController.swift
//  EmpowerPlant
//
//  Created by William Capozzoli on 3/8/22.
//

import UIKit
import Sentry

class EmpowerPlantViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // CoreData database
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    let tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    // Product Entity, gets written to CoreData
    var products = [Product]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Empower Plant"
        
        self.view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        
        // Comment this out and to see the green background and no data in the rows
        tableView.frame = view.bounds
        
        // Configures the nav bar buttons
        configureNavigationItems()
        
        /* TODO
         1 get products from server (so we get http.client span)
         2 check if any products in Core Data -> If Not -> insert the products from response into Core Data
         3 get products from DB (so we get db.query span) and reload the table with this data
         */
        generateId()
        getAllProductsFromServer()
        getAllProductsFromDb()
        
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
            self?.createProduct(productId: "123", title: text, productDescription: "product.description", productDescriptionFull: "product.description.full", img:"img", imgCropped:"img.cropped", price:"1")
        }))
        
        self.present(alert, animated: true, completion: nil)
        
        // ALSO WORKED
        // alert.addTextField()
        // let submitButton = UIAlertAction(title:"Add", style: .default) { (action) in
        //     print("here")
        //     let textfield = alert.textFields![0]
        // }
        // alert.addAction(submitButton)
        // self.present(alert, animated: true, completion: nil)
    }
    
    // Don't deprecate, this function is useful for development and testing
    @objc
    func clearDb() {
        print("> clearDb")
        // self.products was already set by viewDidLoad()
        // self.products = try context.fetch(Product.fetchRequest())
        for product in self.products {
            deleteProduct(product: product)
        }
        refreshTable()
    }
    
    private func configureNavigationItems() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Cart",
            style: .plain,
            target: self,
            action: #selector(goToCart) // addToDb
        )
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "List App",
            style: .plain,
            target: self,
            action: #selector(goToListApp) // clearDb
        )
    }
    
    // Writes to CoreData database
    func createProduct(productId: String, title: String, productDescription: String, productDescriptionFull: String, img: String, imgCropped: String, price: String) {
        let newProduct = Product(context: context)
        
        newProduct.productId = productId // 'id' was a reserved word in swift
        newProduct.title = title
        newProduct.productDescription = productDescription // 'description' was a reserved word in swift
        newProduct.productDescriptionFull = productDescriptionFull
        newProduct.img = img
        newProduct.imgCropped = imgCropped
        newProduct.price = price
        
        do {
            try context.save()
            getAllProductsFromDb()
        }
        catch {
            // error
        }
    }
    
    // Don't deprecate this until major release of this demo
    func deleteProduct(product: Product) {
        context.delete(product)
        do {
            try context.save()
        }
        catch {
            
        }
    }
    
    func getAllProductsFromDb() {
        do {
            self.products = try context.fetch(Product.fetchRequest())
            // for product in self.products {
            //     print(product.productId, product.title, product.productDescriptionFull)
            // }
            refreshTable()
        }
        catch {
            // error
        }
    }
    
    @objc
    func generateId() -> Int {
        if (self.products.isEmpty) {
            getAllProductsFromServer()
            getAllProductsFromDb()
        }
        
        var existingIds = [Int]()
        for product in self.products {
            let intId = Int(product.productId ?? "")
            existingIds.append(intId ?? 0)
        }
        
        return createId(ids:existingIds)
    }
    
    @objc
    func createId(ids: [Int]) -> Int {
        for _ in 1...5 {
            let rand = Int.random(in: (3)..<(5))
            if (!ids.contains(rand)) {
                return rand
            }
            sleep(2)
            print(rand)
        }
        
        return 0
    }
    
    // Also writes them into database if database is empty
    func getAllProductsFromServer() {
        let url = URL(string: "https://application-monitoring-flask-dot-sales-engineering-sf.appspot.com/products-join")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        struct ProductMap: Decodable {
            let id: Int
            let title: String
            let description: String
            let descriptionfull: String
            let img: String
            let imgcropped: String
            let price: Int
            // reviews: [{id: 4, productid: 4, rating: 4, customerid: null, description: null, created: String},...]
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                if let productsResponse = try? JSONDecoder().decode([ProductMap].self, from: data) {
                    if (self.products.count == 0) {
                        for product in productsResponse {
                            // Writes to CoreData database
                            self.createProduct(productId: String(product.id), title: product.title, productDescription: product.description, productDescriptionFull: product.descriptionfull, img: product.img, imgCropped: product.imgcropped, price: String(product.price))
                        }
                    }
                } else {
                    print("Invalid Response")
                }
            } else if let error = error {
                print("HTTP Request Failed \(error)")
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
        // TODO why is this executing so many times on load?
        // print("> refresh table") 
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = products[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        //  'model' has all available attributes here, if needed in the future (e.g. UI development)
        cell.textLabel?.text = model.title
        return cell
    }
    
    // Code that executes on Click'ing table row, adds the product item to shopping cart
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let product = products[indexPath.row]
        
        ShoppingCart.addProduct(product: product)
    }

    
    // Don't deprecate this until major release of this demo
    func updateProduct(product: Product, newTitle:  String) {
        product.title = newTitle
        do {
            try context.save()
        }
        catch {
            
        }
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
