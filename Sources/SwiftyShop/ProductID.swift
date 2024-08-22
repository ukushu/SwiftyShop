
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
                        return .failure(WTF(possiblyJailbroken + error.localizedDescription))
                    
                    case .pending:
                        // Transaction waiting on SCA (Strong Customer Authentication) or
                        // approval from Ask to Buy
                        break
                    
                    case .userCancelled:
                        return .failure(WTF("userCancelled"))
                    
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
}

////////////////////////
///HELPERS
///////////////////////

private extension ProductID {
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
}

private var possiblyJailbroken = """
Successful purchase but transaction/receipt can't be verified; Could be a jailbroken; Details:
"""
