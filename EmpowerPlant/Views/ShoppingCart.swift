//
//  ShoppingCart.swift
//  EmpowerPlant
//
//  Created by William Capozzoli on 4/12/22.
//

import Foundation
import Sentry


class ShoppingCart {
    
    //creates the instance and guarantees that it's unique
    static let instance = ShoppingCart()
    
    private init() {
    }
    
    var items = [Product]()
    var total = 0
    var quantities = Quantities()
    
    // This updates the items, total, and quantities
    static func addProduct(product: Product) {
        
        if !self.instance.items.contains(product) {
            self.instance.items.append(product)
        }
        
        let productId = product.productId!
        let id = Int(productId)
        
        // These are the product Id values as used in the backend database in CloudSQL
        /*
         Plant Mood 3
         Botana Voice 4
         Plant Stroller 5
         Plant Nodes 6
        */
        // Updates the Quantities for each product as well as the sum Total of all
        switch id {
        case 3:
            self.instance.quantities.plantMood += 1
            updateTotal(product:product)
            break
        case 4:
            self.instance.quantities.botanaVoice += 1
            updateTotal(product: product)
            break
        case 5:
            self.instance.quantities.plantStroller += 1
            updateTotal(product: product)
            break
        case 6:
            self.instance.quantities.plantNodes += 1
            updateTotal(product: product)
            break
        default:
            print("product id not found in ShoppingCart switch statement")
        }
        
        // Add user interaction breadcrumb for Sentry User Interaction Tracing
        let crumb = Breadcrumb(level: .info, category: "user_action")
        crumb.message = "Product added to cart"
        crumb.data = [
            "product_id": product.productId ?? "unknown",
            "product_title": product.title ?? "unknown",
            "cart_total_after": instance.total
        ]
        SentrySDK.addBreadcrumb(crumb)
        
        print("> TOTAL", self.instance.total)
    }
    
    static func updateTotal(product: Product) {
        let price = Int(product.price!)
        self.instance.total = self.instance.total + price!
    }
}

/*
 Cannot dynamically set KeyId's like in javascript, so coding the product names into the Quantities class
 
 The following code fails because you can't add key names on the go
    self.instance.quantities.setValue(1, forKey: "someProperty")
    self.instance.quantities.value(forKey: "someProperty"))
 */
class Quantities: NSObject {

    var _name:Int = 0
    var name:Int {
        get {
            return _name
        }
        set (newVal) {
            _name = newVal
        }
    }
    
    var _plantMood:Int = 0
    var plantMood:Int {
        get {
            return _plantMood
        }
        set (newVal) {
            _plantMood = newVal
        }
    }
    
    var _botanaVoice:Int = 0
    var botanaVoice:Int {
        get {
            return _botanaVoice
        }
        set (newVal) {
            _botanaVoice = newVal
        }
    }
    
    var _plantStroller:Int = 0
    var plantStroller:Int {
        get {
            return _plantStroller
        }
        set (newVal) {
            _plantStroller = newVal
        }
    }
    
    var _plantNodes:Int = 0
    var plantNodes:Int {
        get {
            return _plantNodes
        }
        set (newVal) {
            _plantNodes = newVal
        }
    }
}
