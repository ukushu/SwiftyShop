
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
    private func requestProduct() -> R<Product> {
        return Result {
            try getSyncResultFrom {
                try await Product.products(for: [self.id] )
            }
        }
        .flatMap {
            $0.first.asNonOptional
        }
    }
    
    private func purchase() -> R<Product.PurchaseResult> {
        requestProduct()
            .flatMap { product in
                Result {
                    try getSyncResultFrom {
                        try await product.purchase()
                    }
                }
            }
    }
    
    func buy() -> R<()> {
        self.purchase()
            .flatMap{ result in
                switch result {
                    case let .success(.verified(transaction)):
                        // Successful purhcase
                        return Result {
                            getSyncResultFrom {
                                await transaction.finish()
                            }
                        }
                    
                    case let .success(.unverified(_, error)):
                        // Successful purchase but transaction/receipt can't be verified
                        // Could be a jailbroken phone
                        break
                    case .pending:
                        // Transaction waiting on SCA (Strong Customer Authentication) or
                        // approval from Ask to Buy
                        break
                    case .userCancelled:
                        // ^^^
                        break
                    @unknown default:
                        break
                    }
                
                return .failure(WTF("WTF"))
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
