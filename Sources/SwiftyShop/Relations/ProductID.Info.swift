
import Foundation
import StoreKit

public extension ProductID {
    struct Info : Codable {
        public let productID: String
        public let price: String
        public let expirationDate: Date?
        public let originalPurchaseDate: Date
        public let nonConsumable: Bool
        
        public let cacheCreationDate: Date
        
        public init(trans: Transaction) {
            self.productID = trans.productID
            self.price = trans.price?.asStr() ?? ""
            self.expirationDate = trans.expirationDate
            self.nonConsumable = trans.productType == .nonConsumable
            self.originalPurchaseDate = trans.originalPurchaseDate
            
            self.cacheCreationDate = Date.now
        }
    }
}
