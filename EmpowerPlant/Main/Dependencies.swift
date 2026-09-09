enum Dependencies {
    static let networkService = NetworkService()
    static let serializationService = SerializationService()
    static let apiService = APIService(networkService: networkService)
    static let productsService = ProductsService(
        apiService: apiService,
        serializationService: serializationService
    )
    static let checkoutService = CheckoutService(apiService: apiService)
}
