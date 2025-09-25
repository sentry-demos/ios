//
//  RandomErrors.swift
//  EmpowerPlant
//
//  Created by Karan Pujji on 2/20/23.
//
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
        let random = Int.random(in: 0...2)
        switch random {
        case 0:
            throw SampleError.bestDeveloper
        case 1:
            throw SampleError.happyCustomer
        case 2:
            throw SampleError.awesomeCentaur
        default:
            throw SampleError.bestDeveloper
        }
    }
}
