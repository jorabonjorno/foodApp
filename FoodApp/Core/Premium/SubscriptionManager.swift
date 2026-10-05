import Foundation
import Observation
import StoreKit

/// Подписки на StoreKit 2 (без RevenueCat и без своего сервера).
/// Статус берётся из `Transaction.currentEntitlements`, проверка подписи — средствами StoreKit.
@MainActor
@Observable
final class SubscriptionManager {
    enum PurchaseOutcome {
        case success
        case cancelled
        case pending
        case failed
    }

    private(set) var products: [Product] = []
    private(set) var isPremium: Bool
    private(set) var activeProductID: String?
    private(set) var isLoadingProducts = false

    /// Ручное включение PRO для проверки интерфейса в mock-режиме (только для разработки).
    var debugOverride = false {
        didSet { applyPremium(hasActiveSubscription || debugOverride) }
    }

    @ObservationIgnored private var hasActiveSubscription = false
    @ObservationIgnored private var updatesTask: Task<Void, Never>?
    @ObservationIgnored private let analytics: AnalyticsService
    @ObservationIgnored private let defaults: UserDefaults
    private static let cacheKey = "premium_cache.v1"

    init(analytics: AnalyticsService, defaults: UserDefaults = .standard) {
        self.analytics = analytics
        self.defaults = defaults
        // Кэш статуса: интерфейс сразу показывает правильное состояние, пока StoreKit отвечает.
        isPremium = defaults.bool(forKey: Self.cacheKey)
        hasActiveSubscription = isPremium
    }

    /// Запускается один раз при старте приложения.
    func start() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
                await self?.refreshEntitlements()
            }
        }
        Task {
            await refreshEntitlements()
            await loadProducts()
        }
    }

    var monthly: Product? { products.first { $0.id == SubscriptionProducts.monthly } }
    var yearly: Product? { products.first { $0.id == SubscriptionProducts.yearly } }

    func loadProducts() async {
        guard products.isEmpty, !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            products = try await Product.products(for: SubscriptionProducts.all).sorted { $0.price < $1.price }
        } catch {
            products = []
        }
    }

    func purchase(_ product: Product) async -> PurchaseOutcome {
        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { return .failed }
                await transaction.finish()
                await refreshEntitlements()
                analytics.track(.premiumStarted(productID: product.id))
                return .success
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed
            }
        } catch {
            return .failed
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var active: String?
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  SubscriptionProducts.all.contains(transaction.productID),
                  transaction.revocationDate == nil
            else { continue }
            if let expiration = transaction.expirationDate, expiration < .now { continue }
            active = transaction.productID
        }

        let wasActive = hasActiveSubscription
        hasActiveSubscription = active != nil
        activeProductID = active
        if wasActive, !hasActiveSubscription {
            analytics.track(.premiumCancelled)
        }
        applyPremium(hasActiveSubscription || debugOverride)
    }

    private func applyPremium(_ value: Bool) {
        isPremium = value
        defaults.set(hasActiveSubscription, forKey: Self.cacheKey)
    }

    /// Экономия годового плана относительно 12 месяцев помесячно, в процентах.
    var yearlySavingsPercent: Int {
        guard let monthly, let yearly else { return 33 }
        let monthlyYear = NSDecimalNumber(decimal: monthly.price * 12).doubleValue
        let yearlyPrice = NSDecimalNumber(decimal: yearly.price).doubleValue
        guard monthlyYear > 0 else { return 0 }
        return Int(((1 - yearlyPrice / monthlyYear) * 100).rounded())
    }
}
