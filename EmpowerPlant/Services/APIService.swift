import Foundation
import SentrySwift

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
        let span = SentrySDK.span?.startChild(
            operation: "app.api.request",
            description: "GET /products-join"
        )
        span?.setData(value: "GET", key: "http.method")
        span?.setData(value: "/products-join", key: "http.route")
        SentrySDK.logger.debug("API request started", attributes: ["method": "GET", "route": "/products-join"])

        let url = baseURL.appendingPathComponent("products-join")
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        networkService.perform(request: request) { result in
            switch result {
            case .success(let data):
                span?.finish()
                SentrySDK.logger.info(
                    "API request completed",
                    attributes: ["method": "GET", "route": "/products-join", "responseSize": data.count]
                )
                completion(.success(data))
            case .failure(let error):
                let errorType = String(describing: type(of: error))
                span?.setData(value: errorType, key: "error.type")
                span?.finish()
                SentrySDK.logger.error(
                    "API request failed",
                    attributes: ["method": "GET", "route": "/products-join", "errorType": errorType]
                )
                completion(.failure(.network(error)))
            }
        }
    }

    func checkout(
        cart: [String: Any],
        completion: @escaping (Result<Void, APIServiceError>) -> Void
    ) {
        let span = SentrySDK.span?.startChild(
            operation: "app.api.request",
            description: "POST /checkout"
        )
        span?.setData(value: "POST", key: "http.method")
        span?.setData(value: "/checkout", key: "http.route")
        SentrySDK.logger.debug("API request started", attributes: ["method": "POST", "route": "/checkout"])

        let url = baseURL.appendingPathComponent("checkout")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: cart)
        } catch {
            let errorType = String(describing: type(of: error))
            span?.setData(value: errorType, key: "error.type")
            span?.finish()
            SentrySDK.logger.error(
                "Checkout request encoding failed",
                attributes: ["errorType": errorType]
            )
            completion(.failure(.requestEncoding(error)))
            return
        }

        networkService.perform(request: request) { result in
            switch result {
            case .success:
                span?.finish()
                SentrySDK.logger.info("API request completed", attributes: ["method": "POST", "route": "/checkout"])
                completion(.success(()))
            case .failure(let error):
                let errorType = String(describing: type(of: error))
                span?.setData(value: errorType, key: "error.type")
                span?.finish()
                SentrySDK.logger.error(
                    "API request failed",
                    attributes: ["method": "POST", "route": "/checkout", "errorType": errorType]
                )
                completion(.failure(.network(error)))
            }
        }
    }
}
