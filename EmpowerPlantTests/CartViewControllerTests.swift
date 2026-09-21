import XCTest

@testable import EmpowerPlant

final class CartViewControllerTests: XCTestCase {
    func testPurchaseUsesInjectedCheckoutService() {
        let checkoutService = MockCheckoutService()
        let controller = CartViewController(checkoutService: checkoutService)

        controller.purchase()

        XCTAssertEqual(checkoutService.purchaseCallCount, 1)
    }
}
