
import Foundation
import SwiftUI
import StoreKit
import Essentials

extension ProductID {
    class Model {
        let productID: ProductID
        let pool = FSPool(queue: DispatchQueue.global(qos: .userInteractive))
        
        let state               = Flow.Signal<ProductID.State>(queue: .main)
        let inProgress          = Flow.Signal<Bool>(queue: .main)
        let errors              = Flow.Signal<Error>(queue: .main)
        let transactionUpdates  = Flow.Signal<VerificationResult<StoreKit.Transaction>>(queue: .main)
        
        let product             = Flow.Future<Product>.promise(queue: .main)
        let purchaseResult      = Flow.Future<Product.PurchaseResult>.promise(queue: .main)
        let transaction         = Flow.Future<StoreKit.Transaction>.promise(queue: .main)
        
        init(productID: ProductID) {
            self.productID = productID
            
            self.state.update(.pending(productID))
            listen()
        }
        
        func listen() {
            let productID = self.productID
            printDbg("\(productID) listening")
            
            MyShop.shared.products
                .flatMap(queue: DispatchQueue.main) { $0.first(where: { $0.id == productID.id }).asNonOptional("product not found") }
                .completing(future: product)
                .updatingError(signal: errors)
            
            MyShop.shared.transactionUpdates
                .filter { $0.transaction.productID == productID.id }
                .updating(signal: transactionUpdates, queue: .main)
            
            self.product
                .map { ProductID.State.fetched($0, nil) }
                .updating(signal: self.state, queue: .main)
            
            // purchaseResult will complete by buy() call
            pool.combine(product, purchaseResult)
                .map { ProductID.State.fetched($0, $1) }
                .updating(signal: self.state, queue: DispatchQueue.main)
                .onSuccess { _ in
                    printDbg("purchase did finish")
                }
            
            pool.combine(product, transaction)
                .map { ProductID.State.restored($0, $1) }
                .updating(signal: self.state, queue: DispatchQueue.main)
                .onSuccess { _ in printDbg("purchase did restore") }
            
            MyShop.shared.transactions
                .onUpdate(context: self, queue: DispatchQueue.main) { me, all in
                    printDbg("transactions did restore")
                    
                    if let ours = all.filter({ $0.productID == me.productID.id }).first {
                        me.transaction.complete(.success(ours))
                    }
                }
        }
        
        func buy() -> Flow.Future<Product.PurchaseResult> {
            guard purchaseResult.maybeSuccess == nil else { return .failed(WTF("purchaseResult == nil")) }
            guard inProgress.currentValue != true else { return .failed(WTF("inProgress.currentValue == true")) }
            
            printDbg("\(productID) going to buy")
            
            inProgress.update(true)
            
            return product.flatMap { try await $0.purchase() }
                    .flatMap { try await $0.finish() }
//                    .completing(future: purchaseResult, queue: .main)
                    .updatingError(signal: errors)
                    .onComplete(context: self, queue: DispatchQueue.main) { me, purchaseResult in
                        me.inProgress.update(false)
                        
                        printDbg("in progress false \(me.productID)")
                        
                        me.purchaseResult.complete(purchaseResult)
                    }
        }
    }
}
