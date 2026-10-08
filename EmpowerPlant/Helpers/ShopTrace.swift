import SentrySwift

enum ShopTrace {
    /// Child of the active span when one exists, otherwise a root transaction.
    static func begin(operation: String, description: String, bindChildToScope: Bool) -> Span {
        if let parent = SentrySDK.span {
            let child = parent.startChild(operation: operation, description: description)
            if bindChildToScope {
                SentrySDK.configureScope { scope in
                    scope.span = child
                }
            }
            return child
        }
        return SentrySDK.startTransaction(name: description, operation: operation, bindToScope: true)
    }
}
