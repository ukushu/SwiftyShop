
import Foundation
import SwiftUI
import StoreKit
import Essentials

public extension ProductID {
    func buy() {
        viewModel.model.buy()
    }
}

public extension ProductID {
    class ViewModel: ObservableObject {
        let model : ProductID.Model
        let pool = FPool(queue: .global(qos: .userInteractive))
        
        let productID: ProductID
        
        @Published public var state                : ProductID.State
        @Published public var inProgress = false
        @Published public var isPurchased = false
        
        @Published public var transactionUpdates   : [VerificationResult<StoreKit.Transaction>] = []
        
        public var price  : String { state.price }
        
        init(productID: ProductID) {
            self.state = .pending(productID)
            self.model = ProductID.Model(productID: productID)
            self.productID = productID
            
            model.state
                .assign(on: self, to: \.state)
            
            model.inProgress
                .assign(on: self, to: \.inProgress)
            
            model.transactionUpdates
                .append(on: self, to: \.transactionUpdates)
            
            model.purchaseResult
                .onSuccess(context: self) { me, result in
                    if case .success(.verified(_)) = result {
                        me.isPurchased = true
                    }
                }
            
            model.transaction
                .onSuccess(context: self) { me, _ in
                    me.isPurchased = true
                }
            
            model.errors
                .onUpdate { error in
                    printDbg("Error [\(Thread.current.dbgName)]: " + error.localizedDescription)
                }
        }
        
        func buy() {
            model.buy()
        }
    }
}
