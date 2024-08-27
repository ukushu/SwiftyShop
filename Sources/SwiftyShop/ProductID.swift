
import Foundation
import StoreKit
import Essentials

public struct ProductID: Hashable, Identifiable {
    public let id : String
    
    public init(id: String) {
        self.id = id
    }
}

public extension Product.PurchaseResult {
    func finish() async throws -> Product.PurchaseResult {
        switch self {
        case let .success(.verified(transaction)):
            await transaction.finish()
            
        case let .success(.unverified(_, error)):
            throw WTF(possiblyJailbroken + error.localizedDescription)
            
        case .pending:
            // Transaction waiting on SCA (Strong Customer Authentication) or
            // approval from Ask to Buy
            break
            
        case .userCancelled:
            throw WTF("userCancelled")
            
        @unknown default:
            break
        }
        
        return self
    }
}


public extension Array where Element == ProductID {
    func asProducts() async throws -> [Product]  {
        try await Product.products(for: self.map{ $0.id } )
    }
    
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
