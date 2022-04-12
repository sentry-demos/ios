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
    var isEmpty = false
}
