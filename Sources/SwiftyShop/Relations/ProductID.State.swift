
import Foundation
import StoreKit

public extension ProductID {
    enum State {
        case pending(ProductID)
        case fetched(StoreKit.Product, StoreKit.Product.PurchaseResult?)
        case restored(StoreKit.Product, StoreKit.Transaction)
        case read(ProductID.Info)
    }
}

public extension ProductID.State {
    var price : String {
        switch self {
        case .pending(_): ""
        case .fetched(let product, _): product.displayPrice
        case .restored(let product, _): product.displayPrice
        case .read(let info): info.price
        }
    }
}
