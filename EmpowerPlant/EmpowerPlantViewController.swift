//
//  EmpowerPlantViewController.swift
//  EmpowerPlant
//
//  Created by William Capozzoli on 3/8/22.
//

import UIKit
import Sentry
//import Product

class EmpowerPlantViewController: UIViewController {

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Empower Plant"
        // Do any additional setup after loading the view.
        configureNavigationItems()
    }
    
    func getAllProducts() {
        do {
            let products = try context.fetch(Product.fetchRequest())
//            products
        }
        catch {
            // error
        }
    }
    
    func createProduct(name: String) {
        let newProduct = Product(context: context)
        newProduct.title = "thetitle"
        newProduct.text = "thedescription"
        do {
            try context.save()
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
            action: #selector(goToCart)
        )
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "List App",
            style: .plain,
            target: self,
            action: #selector(goToListApp)
        )
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
