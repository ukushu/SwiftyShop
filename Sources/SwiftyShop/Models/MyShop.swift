
import Foundation
import SwiftUI
import StoreKit
import Essentials

public class MyShop {
    public static var shared = MyShop()
    
    public let pool = FSPool(queue: DispatchQueue.global())
    
    public var transactions = S<[StoreKit.Transaction]>(queue: .main)
    
    public let products            = F { try await ProductID.available.asProducts() }
    public let transactionUpdates  = S<VerificationResult<StoreKit.Transaction>>(queue: .main)
    
    public var viewModels          = LockedVar<[ProductID:ProductID.ViewModel]>([:])
    
    private var _monitor : F<Void>?
    
    private init() {
        self._monitor = F { await StoreKit.Transaction.monitor(shop: self) }
            .onSuccess { _ in }
    }
    
    public func restorePurchases() {
        pool.future {
            await SwiftyShopCore.transactions()
        }
        .onSuccess(context: self) { me, list in
            me.transactions.update(list)
        }
    }
    
    public var isPro: Bool {
        SwiftyShopConfig.shared
            .products
            .map { ProductID(id: $0).viewModel.isPurchased }
            .atLeastOneSatisfy{ $0 == true }
    }
    
    static var subscriptionExpired: Bool {
        SwiftyShopConfig.shared
            .products
            .compactMap{ ProductID(id: $0).viewModel.expirationDate }
            .allSatisfy{ $0 < Date.now }
    }
}

public extension ProductID {
    var viewModel : ViewModel {
        if let vm = MyShop.shared.viewModels[self] {
            return vm
        }
        let vm = ViewModel(productID: self)
        MyShop.shared.viewModels[self] = vm
        return vm
    }
}

public extension StoreKit.Transaction {
    static func monitor(shop: MyShop) async {
        printDbg("monitor start")
        
        for await update in Transaction.updates {
            shop.transactionUpdates.update(update)
            
            switch update {
            case let .unverified(_, error):
                print(error.localizedDescription)
            case let .verified(transaction):
                await transaction.finish()
            }
        }
        
        printDbg("monitor finish")
    }
}

public extension VerificationResult where SignedType == StoreKit.Transaction {
    var transaction : StoreKit.Transaction {
        switch self {
        case .verified(let ta): return ta
        case .unverified(let ta, _): return ta
        }
    }
}
