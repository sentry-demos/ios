import Foundation

protocol SerializationServicing {
    func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data,
        completion: @escaping (Result<T, SerializationError>) -> Void
    )
}

final class SerializationService: SerializationServicing {
    private let decoder: JSONDecoder

    init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data,
        completion: @escaping (Result<T, SerializationError>) -> Void
    ) {
        do {
            completion(.success(try decoder.decode(type, from: data)))
        } catch {
            completion(.failure(.decoding(error)))
        }
    }
}
