
import StoreKit
import Essentials

public extension StoreKit.Transaction {
    var isHaveTrial: Bool {
        self.offerType == .introductory
    }
    
    func isTrialPassed(trialDays: Int) -> Bool {
        let trialDaysInSec = Double(trialDays) * 60 * 60 * 24
        
        if isHaveTrial {
            let purchaseDate = self.purchaseDate
            let elapsedTime = Date().timeIntervalSince(purchaseDate) // Час у секундах
            
            return elapsedTime - trialDaysInSec > 0
        }
        
        return true
    }
}
