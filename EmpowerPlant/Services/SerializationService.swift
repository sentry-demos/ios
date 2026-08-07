import Foundation
import SentrySwift

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
        let typeName = String(describing: type)
        let span = SentrySDK.span?.startChild(
            operation: "app.serialization.decode",
            description: "Decode \(typeName)"
        )
        span?.setData(value: typeName, key: "serialization.type")
        span?.setData(value: data.count, key: "response.size")
        SentrySDK.logger.debug(
            "Response decoding started",
            attributes: ["type": typeName, "responseSize": data.count]
        )

        do {
            let value = try decoder.decode(type, from: data)
            span?.finish()
            SentrySDK.logger.info(
                "Response decoding completed",
                attributes: ["type": typeName, "responseSize": data.count]
            )
            completion(.success(value))
        } catch {
            let errorType = String(describing: Swift.type(of: error))
            span?.setData(value: errorType, key: "error.type")
            span?.finish()
            SentrySDK.logger.error(
                "Response decoding failed",
                attributes: ["type": typeName, "responseSize": data.count, "errorType": errorType]
            )
            completion(.failure(.decoding(error)))
        }
    }
}
