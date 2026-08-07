import Foundation
import SentrySwift

final class NetworkService {
    private let session: NetworkSession

    init(session: NetworkSession = URLSessionNetworkSession()) {
        self.session = session
    }

    func perform(
        request: URLRequest,
        completion: @escaping (Result<Data, NetworkError>) -> Void
    ) {
        let method = request.httpMethod ?? "GET"
        let route = request.url?.path ?? "unknown"
        let span = SentrySDK.span?.startChild(
            operation: "app.network.request",
            description: "\(method) \(route)"
        )
        span?.setData(value: method, key: "http.method")
        span?.setData(value: route, key: "http.route")
        SentrySDK.logger.debug(
            "Network request started",
            attributes: ["method": method, "route": route]
        )

        let task = session.dataTask(with: request) { data, response, error in
            if let error {
                let errorType = String(describing: type(of: error))
                span?.setData(value: errorType, key: "error.type")
                span?.finish()
                SentrySDK.logger.error(
                    "Network request failed",
                    attributes: ["method": method, "route": route, "errorType": errorType]
                )
                completion(.failure(.transport(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                span?.setData(value: "invalid_response", key: "error.type")
                span?.finish()
                SentrySDK.logger.error(
                    "Network request returned an invalid response",
                    attributes: ["method": method, "route": route]
                )
                completion(.failure(.invalidResponse))
                return
            }

            let responseSize = data?.count ?? 0
            span?.setData(value: httpResponse.statusCode, key: "http.status_code")
            span?.setData(value: responseSize, key: "response.size")

            guard (200...299).contains(httpResponse.statusCode) else {
                span?.setData(value: "http_status", key: "error.type")
                span?.finish()
                SentrySDK.logger.error(
                    "Network request returned an error status",
                    attributes: [
                        "method": method,
                        "route": route,
                        "statusCode": httpResponse.statusCode,
                        "responseSize": responseSize,
                    ]
                )
                completion(.failure(.httpStatus(httpResponse.statusCode)))
                return
            }

            span?.finish()
            SentrySDK.logger.info(
                "Network request completed",
                attributes: [
                    "method": method,
                    "route": route,
                    "statusCode": httpResponse.statusCode,
                    "responseSize": responseSize,
                ]
            )
            completion(.success(data ?? Data()))
        }
        task.resume()
    }
}
