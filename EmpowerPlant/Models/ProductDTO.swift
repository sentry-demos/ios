struct ProductDTO: Decodable {
    let id: Int
    let title: String
    let description: String
    let descriptionfull: String
    let img: String
    let imgcropped: String
    let price: Int
}
