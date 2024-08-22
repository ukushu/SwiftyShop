import Foundation
import Essentials
import StoreKit

public class SwiftyShop {
    public static func restorePurchases () -> R<[Transaction]> {
        return Result {
            try getSyncResultFrom {
                try await AppStore.sync()
                return await transactions()
            }
        }
    }
    
    public static func currentEntitlements() -> R<[Transaction]> {
        return Result {
            getSyncResultFrom {
                return await transactions()
            }
        }
    }
    
    public static var proIsUnlocked: Bool {
        if let trans = currentEntitlements().maybeSuccess {
            return trans.count > 0
        }
        
        return false
    }
}

fileprivate extension SwiftyShop {
    static func transactions() async -> [Transaction] {
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
