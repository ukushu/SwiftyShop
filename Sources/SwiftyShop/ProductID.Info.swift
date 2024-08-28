
import Foundation

public extension ProductID {
    struct Info : Codable {
        public let productID: String
        public let price: String
        
        public let expiresAt: Date?
        public let creationDate: Date
        
        public init(productID: String, price: String, expiresAt: Date?, creationDate: Date) {
            self.productID = productID
            self.price = price
            self.expiresAt = expiresAt
            self.creationDate = creationDate
        }
    }
}
