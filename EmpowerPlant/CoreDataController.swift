//
//  CoreDataController.swift
//  EmpowerPlant
//
//  Created by Andrew McKnight on 7/17/25.
//

import Foundation
import CoreData

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

class CoreDataController {
    static let shared = CoreDataController()

    lazy var context = persistentContainer.viewContext

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: CRUD Operations

    func createProduct(productId: String, title: String, productDescription: String, productDescriptionFull: String, img: String, imgCropped: String, price: String) {
        let newProduct = Product(context: context)

        newProduct.productId = productId
        newProduct.title = title
        newProduct.productDescription = productDescription
        newProduct.productDescriptionFull = productDescriptionFull
        newProduct.img = img
        newProduct.imgCropped = imgCropped
        newProduct.price = price
    }

    func createProduct(product: ProductMap) {
        createProduct(productId: String(product.id), title: product.title, productDescription: product.description, productDescriptionFull: product.descriptionfull, img: product.img, imgCropped: product.imgcropped, price: String(product.price))
    }

    func getAllProducts() throws -> [Product] {
        let request: NSFetchRequest<Product> = Product.fetchRequest()
        return try context.fetch(request)
    }

    func deleteProduct(product: Product) {
        context.delete(product)
        do {
            try context.save()
        }
        catch {
            // TODO: error
        }
    }

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // TODO: error
            }
        }
    }

    func generateDBItems(total: Int) {
        let itemsPerBatch = 1_000
        let batches = total / itemsPerBatch
        DispatchQueue.global(qos: .utility).async {
            for i in 0..<batches {
                DispatchQueue.main.async {
                    for j in 0..<itemsPerBatch {
                        let newProduct = Product(context: self.context)
                        let productNum = i * itemsPerBatch + j

                        newProduct.productId = "Product \(productNum)" // 'id' was a reserved word in swift
                        newProduct.title = "Product \(productNum)"
                        newProduct.productDescription = "Description for product \(i)" // 'description' was a reserved word in swift
                        newProduct.productDescriptionFull = "Full description for product \(productNum)"
                        newProduct.img = "img"
                        newProduct.imgCropped = "img.cropped"
                        newProduct.price = "\(productNum)"
                    }

                    do {
                        try self.context.save()
                        NotificationCenter.default.post(name: modifiedDBNotificationName, object: nil)
                    } catch {
                        // TODO: error
                    }
                }
                // add a small delay so it doesn't lock up the UI
                usleep(100_000) // 100 milliseconds
            }
        }
    }
}
