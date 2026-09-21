import Foundation

protocol NetworkDataTask {
    func resume()
}

extension URLSessionDataTask: NetworkDataTask {}

protocol NetworkSession {
    func dataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> NetworkDataTask
}

final class URLSessionNetworkSession: NetworkSession {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func dataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> NetworkDataTask {
        session.dataTask(with: request, completionHandler: completionHandler)
    }
}
