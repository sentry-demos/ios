//
//  EmpowerPlantViewController.swift
//  EmpowerPlant
//
//  Created by William Capozzoli on 3/8/22.
//

import UIKit
import Sentry
//import Product

class EmpowerPlantViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    let tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    var products = [Product]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Empower Plant"
        
        self.view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds // Show/hides on top of green background
        
        // Do any additional setup after loading the view.
        configureNavigationItems()

        getAllProducts()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = products[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = model.title // "Hello Title"
//        cell.textLabel?.text = "Placeholder"
        return cell
    }
    
    func getAllProducts() {
        do {
//            let products = try context.fetch(Product.fetchRequest())
            self.products = try context.fetch(Product.fetchRequest())
            DispatchQueue.main.async {
                print("getAllProducts")
                self.tableView.reloadData()
            }
        }
        catch {
            // error
        }
    }
    
    func createProduct(title: String) {
        let newProduct = Product(context: context)
        newProduct.title = title
        newProduct.text = "thedescription"
        do {
            print("createProduct")
            try context.save()
            print("then...")
            getAllProducts()
        }
        catch {
            
        }
    }

    func deleteProduct(product: Product) {
        context.delete(product)
        do {
            try context.save()
        }
        catch {
            
        }
    }

    func updateProduct(product: Product, newTitle:  String) {
        product.title = newTitle
        do {
            try context.save()
        }
        catch {
            
        }
    }
    
    private func configureNavigationItems() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Cart",
            style: .plain,
            target: self,
            action: #selector(addToDb)
        )
        // goToCart
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "List App",
            style: .plain,
            target: self,
            action: #selector(goToListApp)
        )
    }
    
    @objc
    func addToDb() {
        let alert = UIAlertController(title: "New Product",
                                      message: "Enter new product title",
                                      preferredStyle: .alert)
        alert.addTextField(configurationHandler: nil)

        // WORKED
//        alert.addTextField()
//        let submitButton = UIAlertAction(title:"Add", style: .default) { (action) in
//            print("here")
//            let textfield = alert.textFields![0]
//        }
//        alert.addAction(submitButton)
//        self.present(alert, animated: true, completion: nil)
        
        // WORKS, handler
        alert.addAction(UIAlertAction(title:"Submit", style: .cancel, handler: { [weak self] _ in
            guard let field = alert.textFields?.first, let text = field.text, !text.isEmpty else {
                print(".")
                return
            }
            print("..")
            self?.createProduct(title: text)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc
    func goToCart() {
        print("go to Cart")
        self.performSegue(withIdentifier: "goToCart", sender: self)
    }
    
    @objc
    func goToListApp() {
        print("go to List App")
        self.performSegue(withIdentifier: "goToListApp", sender: self)
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
