import Foundation

final class NetworkService {
    private let session: NetworkSession

    init(session: NetworkSession = URLSessionNetworkSession()) {
        self.session = session
    }

    func perform(
        request: URLRequest,
        completion: @escaping (Result<Data, NetworkError>) -> Void
    ) {
        let task = session.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(.transport(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(.httpStatus(httpResponse.statusCode)))
                return
            }

            completion(.success(data ?? Data()))
        }
        task.resume()
    }
}
