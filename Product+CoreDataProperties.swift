//
//  Product+CoreDataProperties.swift
//  
//
//  Created by William Capozzoli on 3/14/22.
//
//

import Foundation
import CoreData


extension Product {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Product> {
        return NSFetchRequest<Product>(entityName: "Product")
    }

    @NSManaged public var title: String?
    @NSManaged public var text: String?

}
