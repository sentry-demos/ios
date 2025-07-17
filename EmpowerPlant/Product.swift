//
//  Product+CoreDataClass.swift
//  
//
//  Created by William Capozzoli on 3/14/22.
//
//

import Foundation
import CoreData

@objc(Product)
public class Product: NSManagedObject {
    @NSManaged public var title: String?
    @NSManaged public var productDescription: String?
    @NSManaged public var productDescriptionFull: String?
    @NSManaged public var productId: String?
    @NSManaged public var img: String?
    @NSManaged public var imgCropped: String?
    @NSManaged public var price: String?
    
    required convenience public init(from decoder: Decoder) throws {
        self.init()
    }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Product> {
        let fr = NSFetchRequest<Product>(entityName: "Product")
        fr.sortDescriptors = [.init(key: "title", ascending: true)]
        return fr
    }
}
