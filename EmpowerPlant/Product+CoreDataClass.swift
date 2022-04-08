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
//    required convenience public init(from decoder: Decoder) throws {
    required convenience public init(from decoder: Decoder) throws {
// TODO deprecate all the Decodable properties
//        enum CodingKeys: String, CodingKey {
//            case title
//            case shortdescription
//            case longdescription
//            case parent
//        }
        
//        enum CodingKeys: CodingKey {
//            case title
//        }
//        guard let context = decoder.userInfo[CodingUserInfoKey.context!] as? NSManagedObjectContext else {
//            print("failed contextget");
//            throw ManagedObjectError.decodeContextError
//
//        }
//        guard let entity = NSEntityDescription.entity(forEntityName: "Product", in: context) else {
//            print("failed entity init");
//            throw ManagedObjectError.decodeEntityError
//
//        }
//
//
//        self.init(entity: entity, insertInto: context)
        self.init()
    }
}

//enum ManagedObjectError: Error {
//    case decodeContextError
//    case decodeEntityError
//}
//
//extension CodingUserInfoKey {
//    static let context = CodingUserInfoKey(rawValue: "context")
//}
//
