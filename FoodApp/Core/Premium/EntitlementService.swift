import Foundation
import Observation

/// Единая точка проверки доступа к платным функциям. Никаких `if isPremium` по проекту.
@MainActor
protocol EntitlementService: AnyObject {
    var isPremium: Bool { get }
    func canUse(feature: PremiumFeature) -> Bool
}

@MainActor
@Observable
final class Entitlements: EntitlementService {
    @ObservationIgnored let subscriptions: SubscriptionManager
    @ObservationIgnored let quota: ScanQuota

    init(subscriptions: SubscriptionManager, quota: ScanQuota) {
        self.subscriptions = subscriptions
        self.quota = quota
    }

    var isPremium: Bool { subscriptions.isPremium }

    func canUse(feature: PremiumFeature) -> Bool {
        switch feature {
        case .scan:
            return quota.remaining(isPremium: isPremium) > 0
        case .advancedFilters, .weeklyMenu, .shoppingList, .scanHistory, .aiRecommendations:
            return isPremium
        }
    }

    var scansRemaining: Int { quota.remaining(isPremium: isPremium) }
    var scansLimit: Int { quota.limit(isPremium: isPremium) }
}
