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
    var quantities = {}
    var price = 0
    
    // https://github.com/sentry-demos/application-monitoring/blob/master/react/src/reducers/index.js#L23-L32
    static func addProduct(product: Product) {
        print("addProduct", product)
        /*
         var cart = Object.assign({}, state.cart)
           let item = cart.items.find((x) => x.id === payload.product.id);
           if (!item) cart.items.push(payload.product);
           cart.quantities[payload.product.id] = cart.quantities[payload.product.id] || 0;
           cart.quantities[payload.product.id]++;
           cart.total = cart.items.reduce((a, item) => {
             const itemTotal = item.price * cart.quantities[item.id];
             return a + itemTotal;
           }, 0);
         */
    }
}
