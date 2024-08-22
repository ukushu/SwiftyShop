import Foundation
import StoreKit
import Essentials

public extension Product {
    @discardableResult
    func buy() -> R<()> {
        ProductID(id: self.id).buy()
    }
}
