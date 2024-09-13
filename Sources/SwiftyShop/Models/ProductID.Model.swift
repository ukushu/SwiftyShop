
import Foundation
import SwiftUI
import StoreKit
import Essentials

extension ProductID {
    func restoreFromDisk() -> R<ProductID.Info> {
        CryptoDictFileID(path: SwiftyShopConfig.shared.dictFilePath, pass: SwiftyShopConfig.shared.dictFilePass)
            .get(key: self.id)
            .flatMap {
                $0.decodeFromJson(type: ProductID.Info.self)
            }
    }
}

extension ProductID.State {
    var saveNeeded: Bool {
        switch self {
        case .fetched(_, let purchaseResult):
            guard let purchaseResult                          else { return false }
            guard case .success(let success) = purchaseResult else { return false }
            guard case .verified(_) = success                 else { return false }
            
            return true
            
        case .restored(_,_):
            return true
            
        default:
            return false
        }
    }
    
    func saveToDisk() -> R<()> {
        switch self {
        case .fetched(let prod, let purchaseResult):
            guard let purchaseResult                          else { return .wtf("purchaseResult is nil") }
            guard case .success(let success) = purchaseResult else { return .wtf("purchaseResult must be .success(). But it is .userCancelled() OR .pending()") }
            guard case .verified(let transaction) = success   else { return .wtf("purchaseResult must be .verified()") }
            
            return ProductID.Info(prod: prod, trans: transaction)
                .asJson()
                .flatMap { json in
                    CryptoDictFileID(path: SwiftyShopConfig.shared.dictFilePath, pass: SwiftyShopConfig.shared.dictFilePass)
                        .set(key: prod.id, value: json)
                }
            
        case .restored(let prod, let transaction):
            return ProductID.Info(prod: prod, trans: transaction)
                .asJson()
                .flatMap { json in
                    CryptoDictFileID(path: SwiftyShopConfig.shared.dictFilePath, pass: SwiftyShopConfig.shared.dictFilePass)
                        .set(key: prod.id, value: json)
                }
            
        default:
            return .wtf("ProductID.State must be .fetched(_,_) or .restored(_,_)")
        }
    }
}

extension ProductID {
    class Model {
        let productID: ProductID
        let pool = FSPool(queue: DispatchQueue.global(qos: .userInteractive))
        
        let state               = S<ProductID.State>(queue: .main)
        let inProgress          = S<Bool>(queue: .main)
        let errors              = S<Error>(queue: .main)
        let transactionUpdates  = S<VerificationResult<StoreKit.Transaction>>(queue: .main)
        
        let product             = F<Product>.promise(queue: .main)
        let purchaseResult      = F<Product.PurchaseResult>.promise(queue: .main)
        let transaction         = F<StoreKit.Transaction>.promise(queue: .main)
        
        init(productID: ProductID) {
            self.productID = productID
            
            let info : ProductID.Info? = productID.restoreFromDisk().maybeSuccess /* read info from disk */
            
            if let info = info  {
                self.state.update(.read(info))
            } else {
                self.state.update(.pending(productID))
                listen()
            }
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
            
            state.onUpdate {
                if $0.saveNeeded {
                    $0.saveToDisk()
                        .onFailure {
                            printDbg("failed save to disk. Reason: \($0.localizedDescription )")
                        }
                }
            }
        }
        
        func buy() -> F<Product.PurchaseResult> {
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
