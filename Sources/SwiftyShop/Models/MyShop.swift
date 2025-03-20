
import Foundation
import SwiftUI
import StoreKit
import Essentials

public class MyShop {
    public static var shared = MyShop()
    
    public let pool = FSPool(queue: DispatchQueue.global())
    
    public var transactions = Flow.Signal<[StoreKit.Transaction]>(queue: .main)
    
    public let products            = Flow.Future{ try await ProductID.available.asProducts() }
    public let transactionUpdates  = Flow.Signal<VerificationResult<StoreKit.Transaction>>(queue: .main)
    
    public var viewModels          = LockedVar<[ProductID:ProductID.ViewModel]>([:])
    
    private var _monitor : Flow.Future<Void>?
    
    private init() {
        self._monitor = Flow.Future { await StoreKit.Transaction.monitor(shop: self) }
            .onSuccess { _ in }
    }
    
    public func restorePurchases(alerts: Bool = true) -> Flow.Future<[StoreKit.Transaction]> {
        let future = pool.future {
            try await SwiftyShopCore.restorePurchasesAsync()
        }
        .onSuccess(context: self) { me, list in
            me.transactions.update(list)
        }
        .onFailure {
            print($0.detailedDescription )
            print("---------------------" )
            print($0.localizedDescription )
        }
        
        if alerts {
            return future
                .onFailure {
                    alertMacOs(msg: "Failed to restore purchases", text: "Details: \($0.localizedDescription)")
                }
                .onSuccess {
                    if $0.count == 0 {
                        alertMacOs(msg: "No purchases found", text: "There are no previous purchases valid for the current period.")
                    }
                }
        }
        
        return future
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
