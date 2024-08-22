import Foundation
import StoreKit
import Essentials

public extension Product {
    @discardableResult
    func buy() -> R<Product.PurchaseResult> {
        ProductID(id: self.id).buy()
    }
}
