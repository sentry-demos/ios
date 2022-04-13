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
    var cart = {}
    
    // TODO replicate what's in here
    // https://github.com/sentry-demos/application-monitoring/blob/master/react/src/reducers/index.js#L23-L32
    static func addProduct(product: Product) {
        print("addProduct", product)
    }
}
