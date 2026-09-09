import Foundation

enum SerializationError: Error, LocalizedError {
    case decoding(Error)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .decoding(let error):
            return "Unable to decode response: \(error.localizedDescription)"
        case .invalidData:
            return "Unable to decode response data"
        }
    }
}
