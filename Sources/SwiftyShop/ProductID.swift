
import Foundation
import StoreKit
import Essentials

public struct ProductID: Hashable, Identifiable {
    public let id : String
    
    public init(id: String) {
        self.id = id
    }
}

public extension ProductID {
    var skproduct : SKProduct? { return nil }
}

public extension Array where Element == ProductID {
    func requestProducts() -> R<[Product]> {
        return Result {
            try getSyncResultFrom {
                try await Product.products(for: self.map{ $0.id } )
            }
        }
    }
    
    func restorePurchases() -> R<()> {
        return Result {
            try getSyncResultFrom{
                try await AppStore.sync()
            }
        }
    }
}
