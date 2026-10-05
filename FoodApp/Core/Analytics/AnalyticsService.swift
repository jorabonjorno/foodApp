import Foundation
import OSLog

/// Продуктовые события: activation (scan), completion (recipe opened), conversion (paywall → premium).
enum AnalyticsEvent: Sendable, Equatable {
    case appOpened
    case scanStarted
    case scanCompleted(foodsCount: Int)
    case scanFailed(reason: String)
    case recipeListOpened(resultsCount: Int)
    case recipeOpened(id: String)
    case recipeFavorited(id: String)
    case shoppingListAdded(count: Int)
    case paywallShown(reason: String)
    case premiumStarted(productID: String)
    case premiumCancelled

    var name: String {
        switch self {
        case .appOpened: "app_opened"
        case .scanStarted: "scan_started"
        case .scanCompleted: "scan_completed"
        case .scanFailed: "scan_failed"
        case .recipeListOpened: "recipe_list_opened"
        case .recipeOpened: "recipe_opened"
        case .recipeFavorited: "recipe_favorited"
        case .shoppingListAdded: "shopping_list_added"
        case .paywallShown: "paywall_shown"
        case .premiumStarted: "premium_started"
        case .premiumCancelled: "premium_cancelled"
        }
    }

    var parameters: [String: String] {
        switch self {
        case .scanCompleted(let count): ["foods_count": "\(count)"]
        case .scanFailed(let reason): ["reason": reason]
        case .recipeListOpened(let count): ["results_count": "\(count)"]
        case .recipeOpened(let id), .recipeFavorited(let id): ["recipe_id": id]
        case .shoppingListAdded(let count): ["count": "\(count)"]
        case .paywallShown(let reason): ["reason": reason]
        case .premiumStarted(let productID): ["product_id": productID]
        default: [:]
        }
    }
}

protocol AnalyticsService: Sendable {
    func track(_ event: AnalyticsEvent)
}

/// MVP-реализация без внешних сервисов: пишет события в системный лог и считает их локально.
/// Счётчики видны в «Профиль → Статистика (debug)». Внешний сервис подключается новой реализацией протокола.
final class LocalAnalyticsService: AnalyticsService, @unchecked Sendable {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FoodApp", category: "analytics")
    private let defaults: UserDefaults
    private let lock = NSLock()
    private static let key = "analytics_counters.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func track(_ event: AnalyticsEvent) {
        let params = event.parameters.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: ", ")
        logger.info("📊 \(event.name, privacy: .public) \(params, privacy: .public)")

        lock.lock()
        defer { lock.unlock() }
        var counters = defaults.dictionary(forKey: Self.key) as? [String: Int] ?? [:]
        counters[event.name, default: 0] += 1
        defaults.set(counters, forKey: Self.key)
    }

    var counters: [String: Int] {
        defaults.dictionary(forKey: Self.key) as? [String: Int] ?? [:]
    }
}
