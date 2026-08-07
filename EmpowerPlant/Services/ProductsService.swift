import Foundation

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
        apiService.fetchProducts { result in
            switch result {
            case .success(let data):
                self.serializationService.decode([ProductDTO].self, from: data) { result in
                    completion(result.mapError(ProductsServiceError.decoding))
                }
            case .failure(let error):
                completion(.failure(.api(error)))
            }
        }
    }
}
