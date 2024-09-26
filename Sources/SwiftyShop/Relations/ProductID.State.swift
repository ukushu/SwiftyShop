
import Foundation
import StoreKit
import Essentials

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
        return
            switch self {
            case .pending(_): ""
            case .fetched(let product, _):
                printDbg("fetched \(product.displayPrice)")
                return product.displayPrice
            case .restored(let product, let transaction):
                printDbg("restored \(transaction.displayPrice)")
                return product.displayPrice
            case .read(let info):
                printDbg("read \(info.price)")
                return info.price
            }
    }
}
