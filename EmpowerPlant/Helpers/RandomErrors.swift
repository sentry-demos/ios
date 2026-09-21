import Foundation
import SentrySwift

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
        let random = Int.random(in: 0...2)
        SentrySDK.logger.debug(
            "RandomErrorGenerator.generate called",
            attributes: [
                "randomValue": random
            ])
        switch random {
        case 0:
            SentrySDK.logger.debug("Throwing SampleError.bestDeveloper")
            throw SampleError.bestDeveloper
        case 1:
            SentrySDK.logger.debug("Throwing SampleError.happyCustomer")
            throw SampleError.happyCustomer
        case 2:
            SentrySDK.logger.debug("Throwing SampleError.awesomeCentaur")
            throw SampleError.awesomeCentaur
        default:
            SentrySDK.logger.warn(
                "Unexpected random value, falling back to SampleError.bestDeveloper",
                attributes: [
                    "randomValue": random
                ])
            throw SampleError.bestDeveloper
        }
    }
}
