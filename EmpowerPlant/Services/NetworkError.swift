import Foundation

enum NetworkError: Error, LocalizedError {
    case transport(Error)
    case invalidResponse
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .transport(let error):
            return "Network request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Network request returned an invalid response"
        case .httpStatus(let statusCode):
            return "Network request failed with HTTP status \(statusCode)"
        }
    }
}
