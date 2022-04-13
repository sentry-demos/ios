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
    
    // TODO for checkout, will need put these on a 'cart' property on req body, may need a Class there for that
    var items = [Product]()
    var price = 0
    var quantities = Quantities()
    
    // https://github.com/sentry-demos/application-monitoring/blob/master/react/src/reducers/index.js#L23-L32
    static func addProduct(product: Product) {
        // WORKS
        // print("isEmpty", self.instance.isEmpty)
        
        if self.instance.items.contains(product) {
            //print("has it", product.productId!)
        } else {
            //print("doesn't have it", product.productId!, product.title!)
            self.instance.items.append(product)
        }
        
        // WORKS
        // self.instance.quantities.name = self.instance.quantities.name + 1
        // print("quantities.name", self.instance.quantities.name)
        
        let productId = product.productId!
        let id = Int(productId)
        
        // Cannot dynamically set KeyId's like in javascript
        // These are the values as used in the backend database in CloudSQL
        switch id {
        case 3:
            // print("id | 3")
            self.instance.quantities.plantMood += 1
            print(">> quantities plantMood", self.instance.quantities.plantMood)
            break
        case 4:
            // print("id | 4")
            self.instance.quantities.botanaVoice += 1
            print(">> quantities botanaVoice", self.instance.quantities.botanaVoice)
            break
        case 5:
            // print("id | 5")
            self.instance.quantities.plantStroller += 1
            print(">> quantities plantStroller", self.instance.quantities.plantStroller)
            break
        case 6:
            // print("id | 6")
            self.instance.quantities.plantNodes += 1
            print(">> quantities plantNodes", self.instance.quantities.plantNodes)
            break
        default:
            print("product id not found in ShoppingCart switch statement")
        }
        
        /*
         Plant Mood 3
         Botana Voice 4
         Plant Stroller 5
         Plant Nodes 6
        */

        
        /*
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

/*
 Cannot dynamically set KeyId's like in javascript
 
 The following code fails:
 self.instance.quantities.setValue(1, forKey: "someProperty")
 self.instance.quantities.value(forKey: "someProperty"))
 
 Reference:
 https://stackoverflow.com/questions/26667380/in-swift-for-anyobject-how-do-i-setvalue-then-call-valueforkey
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
