
import StoreKit
import Essentials

extension Product.SubscriptionInfo {
    func isTrialAccessibleAsync() async -> Bool {
        await self.isEligibleForIntroOffer
    }
    
    func isTrialAccessible() async -> Flow.Future<Bool> {
        Flow.Future { await self.isEligibleForIntroOffer }
    }
}
