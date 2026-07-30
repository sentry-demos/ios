import CoreData
import Foundation
import SentrySwift

@objc(Product)
public class Product: NSManagedObject {
    required convenience public init(from decoder: Decoder) throws {
        SentrySDK.logger.debug("Product decoded")
        self.init()
    }
}

// TODO: Deprecate this soon
// This was all the boilerplate needed for mapping the HTTP Response directly into a Product CoreData Class,
// in addition to changes needed in XCode settings for the Product Entity
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
//            throw ManagedObjectError.decodeContextError
//
//        }
//        guard let entity = NSEntityDescription.entity(forEntityName: "Product", in: context) else {
//            throw ManagedObjectError.decodeEntityError
//
//        }
//
//
//        self.init(entity: entity, insertInto: context)

// enum ManagedObjectError: Error {
//    case decodeContextError
//    case decodeEntityError
// }
//
// extension CodingUserInfoKey {
//    static let context = CodingUserInfoKey(rawValue: "context")
// }
//
