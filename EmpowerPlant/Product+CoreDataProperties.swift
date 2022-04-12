//
//  Product+CoreDataProperties.swift
//  
//
//  Created by William Capozzoli on 3/28/22.
//
//

import Foundation
import CoreData


extension Product {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Product> {
        return NSFetchRequest<Product>(entityName: "Product")
    }
    
//    @NSManaged public var text: String?
    @NSManaged public var title: String?
    @NSManaged public var productDescription: String?
    @NSManaged public var productDescriptionFull: String?
    @NSManaged public var productId: String?
    @NSManaged public var img: String?
    @NSManaged public var imgCropped: String?
    @NSManaged public var price: String?
}
