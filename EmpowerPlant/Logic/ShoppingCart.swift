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
