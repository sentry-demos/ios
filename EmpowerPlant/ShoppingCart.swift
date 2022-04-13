//
//  ShoppingCart.swift
//  EmpowerPlant
//
//  Created by William Capozzoli on 4/12/22.
//

import Foundation


class ShoppingCart {
    
    //creates the instance and guarantees that it's unique
    static let instance = ShoppingCart()
    
    private init() {
    }
    
    //creates the global variable
    var isEmpty = 0
    
    // Cart.items, Cart.quantities, Cart.total
    // var cart = {
    //    items: []
    // }
    
    var items = [Product]()
    var price = 0
    // var quantities = {}
    // class quantities: NSObject {}
    // var quantities: NSObject = {}
    // struct quantities {}
    // var quantities = {
    //    "1": 0;
    //    "2": 0;
    // }
    // struct quantities {
    //    var one = 0
    //    var two = 0
    // }
    
    // var city:City!
    var quantities = Quantities()
    
    // https://github.com/sentry-demos/application-monitoring/blob/master/react/src/reducers/index.js#L23-L32
    static func addProduct(product: Product) {
        // print("addProduct", product)
        // print("isEmpty", self.instance.isEmpty)
        
        if self.instance.items.contains(product) {
            print("has it", product.productId!)
        } else {
            print("doesn't have it")
            self.instance.items.append(product)
        }
        
        self.instance.quantities.name = self.instance.quantities.name + 1
        print("quantities.name", self.instance.quantities.name)
        
        // self.instance.quantities.setValue(0, forKey: "key")
        // self.instance.quantities['prop1'] = 0
        // self.instance.quantities[product.productId] = self.instance.quantities[product.productId] || 0
        // self.instance.quantities["prop1"] = 0 // struct
        // https://stackoverflow.com/questions/31145990/dynamically-create-objects-and-set-attributes-in-swift
        // https://stackoverflow.com/questions/38121957/singleton-and-class-properties-in-swift
        
        /*
         var cart = Object.assign({}, state.cart)
         DONE
           let item = cart.items.find((x) => x.id === payload.product.id);
           if (!item) cart.items.push(payload.product);
         NEXT
           cart.quantities[payload.product.id] = cart.quantities[payload.product.id] || 0;
           cart.quantities[payload.product.id]++;
         
           cart.total = cart.items.reduce((a, item) => {
             const itemTotal = item.price * cart.quantities[item.id];
             return a + itemTotal;
           }, 0);
         */
    }
}

// TODO can setKey on this?
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
}
