import XCTest

@testable import EmpowerPlant

final class ProductsServiceTests: XCTestCase {
    func testFetchProductsDecodesProductDTOs() {
        let apiService = MockAPIService()
        apiService.productsResult = .success(
            Data(
                """
                [{"id":1,"title":"Plant Mood","description":"Short","descriptionfull":"Long","img":"image","imgcropped":"cropped","price":10}]
                """.utf8
            )
        )
        let service = ProductsService(apiService: apiService, serializationService: SerializationService())
        let expectation = expectation(description: "products complete")

        service.fetchProducts { result in
            guard case .success(let products) = result else {
                return XCTFail("Expected decoded products")
            }
            XCTAssertEqual(products.count, 1)
            XCTAssertEqual(products[0].id, 1)
            XCTAssertEqual(products[0].title, "Plant Mood")
            XCTAssertEqual(products[0].price, 10)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testFetchProductsReturnsDecodingErrorForMalformedJSON() {
        let apiService = MockAPIService()
        apiService.productsResult = .success(Data("not-json".utf8))
        let service = ProductsService(apiService: apiService, serializationService: SerializationService())
        let expectation = expectation(description: "products complete")

        service.fetchProducts { result in
            guard case .failure(.decoding) = result else {
                return XCTFail("Expected a decoding error")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }
}
