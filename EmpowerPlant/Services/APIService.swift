import Foundation

protocol APIServiceProtocol {
    func fetchProducts(completion: @escaping (Result<Data, APIServiceError>) -> Void)
    func checkout(cart: [String: Any], completion: @escaping (Result<Void, APIServiceError>) -> Void)
}

final class APIService: APIServiceProtocol {
    private let networkService: NetworkService
    private let baseURL = URL(string: "https://flask.empower-plant.com")!

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func fetchProducts(completion: @escaping (Result<Data, APIServiceError>) -> Void) {
        let url = baseURL.appendingPathComponent("products-join")
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        networkService.perform(request: request) { result in
            completion(result.mapError(APIServiceError.network))
        }
    }

    func checkout(
        cart: [String: Any],
        completion: @escaping (Result<Void, APIServiceError>) -> Void
    ) {
        let url = baseURL.appendingPathComponent("checkout")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: cart)
        } catch {
            completion(.failure(.requestEncoding(error)))
            return
        }

        networkService.perform(request: request) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(.network(error)))
            }
        }
    }
}
