import Foundation

enum CheckoutServiceError: Error, LocalizedError {
    case api(APIServiceError)

    var errorDescription: String? {
        switch self {
        case .api(let error):
            return error.localizedDescription
        }
    }
}
