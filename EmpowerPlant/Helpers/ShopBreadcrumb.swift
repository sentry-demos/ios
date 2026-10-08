import SentrySwift

enum ShopBreadcrumb {
    /// Manual shop breadcrumb. Automatic swizzle breadcrumbs are left to the SDK.
    static func record(
        message: String,
        category: String,
        level: SentryLevel = .info,
        screen: String,
        plantTitle: String? = nil,
        plantId: String? = nil,
        plantPrice: Int? = nil
    ) {
        let crumb = Breadcrumb(level: level, category: category)
        crumb.message = message
        crumb.setData(value: screen, key: "screen")
        crumb.setData(value: ShoppingCart.instance.items.count, key: "cart_size")
        crumb.setData(value: ShoppingCart.instance.total, key: "cart_total")
        if let plantTitle {
            crumb.setData(value: plantTitle, key: "plant_title")
        }
        if let plantId {
            crumb.setData(value: plantId, key: "plant_id")
        }
        if let plantPrice {
            crumb.setData(value: plantPrice, key: "plant_price")
        }
        SentrySDK.addBreadcrumb(crumb)
    }
}
