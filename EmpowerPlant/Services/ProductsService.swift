import Foundation
import SentrySwift

protocol ProductsServicing {
    func fetchProducts(completion: @escaping (Result<[ProductDTO], ProductsServiceError>) -> Void)
}

final class ProductsService: ProductsServicing {
    private let apiService: APIServiceProtocol
    private let serializationService: SerializationServicing

    init(apiService: APIServiceProtocol, serializationService: SerializationServicing) {
        self.apiService = apiService
        self.serializationService = serializationService
    }

    func fetchProducts(completion: @escaping (Result<[ProductDTO], ProductsServiceError>) -> Void) {
        let span = SentrySDK.span?.startChild(
            operation: "app.products.fetch",
            description: "Fetch products"
        )
        SentrySDK.logger.debug("Product fetch started")

        apiService.fetchProducts { result in
            switch result {
            case .success(let data):
                self.serializationService.decode([ProductDTO].self, from: data) { result in
                    switch result {
                    case .success(let products):
                        span?.setData(value: products.count, key: "products.count")
                        span?.finish()
                        SentrySDK.logger.info(
                            "Product fetch completed",
                            attributes: ["productCount": products.count]
                        )
                        completion(.success(products))
                    case .failure(let error):
                        let errorType = String(describing: type(of: error))
                        span?.setData(value: errorType, key: "error.type")
                        span?.finish()
                        SentrySDK.logger.error(
                            "Product decoding failed",
                            attributes: ["errorType": errorType]
                        )
                        completion(.failure(.decoding(error)))
                    }
                }
            case .failure(let error):
                let errorType = String(describing: type(of: error))
                span?.setData(value: errorType, key: "error.type")
                span?.finish()
                SentrySDK.logger.error(
                    "Product fetch failed",
                    attributes: ["errorType": errorType]
                )
                completion(.failure(.api(error)))
            }
        }
    }
}
