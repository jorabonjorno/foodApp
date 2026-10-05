import XCTest
@testable import FoodApp

@MainActor
final class PremiumTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: "PremiumTests")
        defaults.removePersistentDomain(forName: "PremiumTests")
    }

    func testFreeQuotaRunsOutAfterThreeScans() {
        let quota = ScanQuota(storage: InMemoryQuotaStorage())
        XCTAssertEqual(quota.remaining(isPremium: false), 3)
        for _ in 0..<3 { quota.consume() }
        XCTAssertEqual(quota.remaining(isPremium: false), 0)
        XCTAssertEqual(quota.remaining(isPremium: true), 47)
    }

    func testQuotaResetsInNewMonth() {
        var now = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2026, month: 10, day: 30).date!
        let storage = InMemoryQuotaStorage()
        let quota = ScanQuota(storage: storage, now: { now })
        quota.consume()
        quota.consume()
        XCTAssertEqual(quota.used, 2)

        now = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2026, month: 11, day: 1).date!
        XCTAssertEqual(quota.used, 0)
        quota.consume()
        XCTAssertEqual(quota.used, 1)

        // Состояние переживает перезапуск.
        let reloaded = ScanQuota(storage: storage, now: { now })
        XCTAssertEqual(reloaded.used, 1)
    }

    func testEntitlementsGateFeatures() {
        let subscriptions = SubscriptionManager(analytics: LocalAnalyticsService(defaults: defaults), defaults: defaults)
        let quota = ScanQuota(storage: InMemoryQuotaStorage())
        let entitlements = Entitlements(subscriptions: subscriptions, quota: quota)

        XCTAssertFalse(entitlements.isPremium)
        XCTAssertTrue(entitlements.canUse(feature: .scan))
        XCTAssertFalse(entitlements.canUse(feature: .weeklyMenu))
        XCTAssertFalse(entitlements.canUse(feature: .shoppingList))
        XCTAssertFalse(entitlements.canUse(feature: .advancedFilters))

        for _ in 0..<PlanLimits.freeScansPerMonth { quota.consume() }
        XCTAssertFalse(entitlements.canUse(feature: .scan))

        subscriptions.debugOverride = true
        XCTAssertTrue(entitlements.isPremium)
        XCTAssertTrue(entitlements.canUse(feature: .scan))
        XCTAssertTrue(entitlements.canUse(feature: .weeklyMenu))
        XCTAssertEqual(entitlements.scansLimit, PlanLimits.proScansPerMonth)
    }
}
