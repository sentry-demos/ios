import Foundation

enum ProductsServiceError: Error, LocalizedError {
    case api(APIServiceError)
    case decoding(SerializationError)

    var errorDescription: String? {
        switch self {
        case .api(let error):
            return error.localizedDescription
        case .decoding(let error):
            return error.localizedDescription
        }
    }
}
