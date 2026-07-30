import Foundation
import SentrySwift

class ShoppingCart {

    // creates the instance and guarantees that it's unique
    static let instance = ShoppingCart()

    private init() {
        SentrySDK.logger.debug("ShoppingCart singleton initialized")
    }

    var items = [Product]()
    var total = 0
    var quantities = Quantities()

    // This updates the items, total, and quantities
    static func addProduct(product: Product) {

        if !self.instance.items.contains(product) {
            self.instance.items.append(product)
            SentrySDK.logger.debug(
                "New product added to cart",
                attributes: [
                    "productId": product.productId ?? "unknown",
                    "productTitle": product.title ?? "unknown",
                ])
        }

        let productId = product.productId!
        let id = Int(productId)

        // These are the product Id values as used in the backend database in CloudSQL
        /*
         Plant Mood 3
         Botana Voice 4
         Plant Stroller 5
         Plant Nodes 6
        */
        // Updates the Quantities for each product as well as the sum Total of all
        switch id {
        case 3:
            self.instance.quantities.plantMood += 1
            updateTotal(product: product)
        case 4:
            self.instance.quantities.botanaVoice += 1
            updateTotal(product: product)
        case 5:
            self.instance.quantities.plantStroller += 1
            updateTotal(product: product)
        case 6:
            self.instance.quantities.plantNodes += 1
            updateTotal(product: product)
        default:
            SentrySDK.logger.warn(
                "Unknown product ID in shopping cart",
                attributes: [
                    "productId": productId,
                    "expectedIds": "3, 4, 5, 6",
                ])
        }

        SentrySDK.logger.info(
            "Product quantity updated in cart",
            attributes: [
                "productId": productId,
                "newTotal": self.instance.total,
                "cartItemCount": self.instance.items.count,
            ])
    }

    static func updateTotal(product: Product) {
        let price = Int(product.price!)
        self.instance.total = self.instance.total + price!
        SentrySDK.logger.debug(
            "Cart total updated",
            attributes: [
                "productId": product.productId ?? "unknown",
                "addedPrice": price ?? 0,
                "newTotal": self.instance.total,
            ])
    }
}

/*
 Cannot dynamically set KeyId's like in javascript, so coding the product names into the Quantities class

 The following code fails because you can't add key names on the go
    self.instance.quantities.setValue(1, forKey: "someProperty")
    self.instance.quantities.value(forKey: "someProperty"))
 */
class Quantities: NSObject {

    var _name: Int = 0
    var name: Int {
        get {
            return _name
        }
        set(newVal) {
            SentrySDK.logger.debug(
                "Quantities.name updated",
                attributes: [
                    "newValue": newVal
                ])
            _name = newVal
        }
    }

    var _plantMood: Int = 0
    var plantMood: Int {
        get {
            return _plantMood
        }
        set(newVal) {
            SentrySDK.logger.debug(
                "Quantities.plantMood updated",
                attributes: [
                    "newValue": newVal
                ])
            _plantMood = newVal
        }
    }

    var _botanaVoice: Int = 0
    var botanaVoice: Int {
        get {
            return _botanaVoice
        }
        set(newVal) {
            SentrySDK.logger.debug(
                "Quantities.botanaVoice updated",
                attributes: [
                    "newValue": newVal
                ])
            _botanaVoice = newVal
        }
    }

    var _plantStroller: Int = 0
    var plantStroller: Int {
        get {
            return _plantStroller
        }
        set(newVal) {
            SentrySDK.logger.debug(
                "Quantities.plantStroller updated",
                attributes: [
                    "newValue": newVal
                ])
            _plantStroller = newVal
        }
    }

    var _plantNodes: Int = 0
    var plantNodes: Int {
        get {
            return _plantNodes
        }
        set(newVal) {
            SentrySDK.logger.debug(
                "Quantities.plantNodes updated",
                attributes: [
                    "newValue": newVal
                ])
            _plantNodes = newVal
        }
    }
}
