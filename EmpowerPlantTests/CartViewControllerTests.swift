import XCTest

@testable import EmpowerPlant

final class CartViewControllerTests: XCTestCase {

    func testPurchase() {
        let cvc = CartViewController()
        cvc.purchase()
    }
}
