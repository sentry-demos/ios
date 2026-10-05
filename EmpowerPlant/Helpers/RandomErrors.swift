import Foundation

enum SampleError: Error, LocalizedError {
    case bestDeveloper
    case happyCustomer
    case awesomeCentaur

    var errorDescription: String? {
        switch self {
        case .bestDeveloper:
            return "Best Developer error occurred"
        case .happyCustomer:
            return "Happy Customer error occurred"
        case .awesomeCentaur:
            return "Awesome Centaur error occurred"
        }
    }
}

class RandomErrorGenerator {
    static func generate() throws {
        switch Int.random(in: 0...2) {
        case 0:
            throw SampleError.bestDeveloper
        case 1:
            throw SampleError.happyCustomer
        default:
            throw SampleError.awesomeCentaur
        }
    }
}
