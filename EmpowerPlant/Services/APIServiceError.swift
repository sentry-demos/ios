import Foundation

enum APIServiceError: Error, LocalizedError {
    case requestEncoding(Error)
    case network(NetworkError)

    var errorDescription: String? {
        switch self {
        case .requestEncoding(let error):
            return "Unable to create checkout request: \(error.localizedDescription)"
        case .network(let error):
            return error.localizedDescription
        }
    }
}
