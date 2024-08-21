
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

public extension ProductID {
    func requestProduct() -> R<Product> {
        return Result {
            try getSyncResultFrom {
                try await Product.products(for: [self.id] )
            }
        }
        .flatMap {
            $0.first.asNonOptional
        }
    }
    
    func purchase() -> R<Product.PurchaseResult> {
        requestProduct()
            .flatMap { product in
                Result {
                    try getSyncResultFrom {
                        try await product.purchase()
                    }
                }
            }
    }
}

public extension Array where Element == ProductID {
    func requestProducts() -> R<[Product]> {
        return Result {
            try getSyncResultFrom {
                try await Product.products(for: self.map{ $0.id } )
            }
        }
    }
    
    func restorePurchases () -> R<[Transaction]> {
        return Result {
            try getSyncResultFrom {
                try await AppStore.sync()
                return await transactions ()
            }
        }
    }
    
    fileprivate func transactions () async -> [Transaction] {
        var results = [Transaction]()
        
        for await result in Transaction.currentEntitlements {
            guard case .verified (let transaction) = result else {
                continue
            }
                
            results.append(transaction)
        }
        
        return results
    }
}
