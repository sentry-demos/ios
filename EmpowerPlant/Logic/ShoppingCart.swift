import Foundation
import SentrySwift

class ShoppingCart {

    // creates the instance and guarantees that it's unique
    static let instance = ShoppingCart()

    private init() {
    }

    var items = [Product]()
    var total = 0
    var quantities = Quantities()

    // Each read returns a new stream so the plant list and the cart screen can listen together.
    private static let updateLock = NSLock()
    private static var updateContinuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    static var updates: AsyncStream<Void> {
        AsyncStream { continuation in
            let id = UUID()
            updateLock.lock()
            updateContinuations[id] = continuation
            updateLock.unlock()
            continuation.onTermination = { _ in
                updateLock.lock()
                updateContinuations.removeValue(forKey: id)
                updateLock.unlock()
            }
        }
    }

    // This updates the items, total, and quantities
    static func addProduct(product: Product) {
        let logger = SentrySDK.logger

        if !self.instance.items.contains(product) {
            self.instance.items.append(product)
            logger.debug(
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
            logger.warn(
                "Unknown product ID in shopping cart",
                attributes: [
                    "productId": productId,
                    "expectedIds": "3, 4, 5, 6",
                ])
        }

        logger.info(
            "Product quantity updated in cart",
            attributes: [
                "productId": productId,
                "newTotal": self.instance.total,
                "cartItemCount": self.instance.items.count,
            ])
        Self.publishUpdate()
    }

    private static func publishUpdate() {
        updateLock.lock()
        let continuations = Array(updateContinuations.values)
        updateLock.unlock()
        for continuation in continuations {
            continuation.yield(())
        }
    }

    static func updateTotal(product: Product) {
        let price = Int(product.price!)
        self.instance.total = self.instance.total + price!
    }
}

class Quantities: NSObject {
    var _plantMood: Int = 0
    var plantMood: Int {
        get {
            return _plantMood
        }
        set(newVal) {
            _plantMood = newVal
        }
    }

    var _botanaVoice: Int = 0
    var botanaVoice: Int {
        get {
            return _botanaVoice
        }
        set(newVal) {
            _botanaVoice = newVal
        }
    }

    var _plantStroller: Int = 0
    var plantStroller: Int {
        get {
            return _plantStroller
        }
        set(newVal) {
            _plantStroller = newVal
        }
    }

    var _plantNodes: Int = 0
    var plantNodes: Int {
        get {
            return _plantNodes
        }
        set(newVal) {
            _plantNodes = newVal
        }
    }
}
