import Foundation

/// Всё, что может быть ограничено подпиской. Проверка доступа — только через `EntitlementService.canUse(feature:)`.
enum PremiumFeature: String, CaseIterable, Sendable {
    /// AI-сканирование (лимит в месяц: Free 3, PRO 50).
    case scan
    case advancedFilters
    case weeklyMenu
    case shoppingList
    case scanHistory
    /// Зарезервировано: в MVP не реализовано, чтобы не тратить AI-бюджет.
    case aiRecommendations
}

enum PlanLimits {
    static let freeScansPerMonth = 3
    static let proScansPerMonth = 50
}

/// Почему показан paywall — от этого зависит заголовок.
enum PaywallReason: String, Identifiable, Sendable {
    case scansExhausted
    case feature
    case profile

    var id: String { rawValue }
}

/// Идентификаторы подписок в App Store Connect. Должны совпадать с продуктами, созданными в ASC.
enum SubscriptionProducts {
    static let monthly = "com.example.foodapp.pro.monthly"
    static let yearly = "com.example.foodapp.pro.yearly"
    static let all = [monthly, yearly]
}

/// Публичные ссылки (GitHub Pages — бесплатно). Замените на свои после публикации docs/.
enum AppLinks {
    static let privacy = URL(string: "https://example.github.io/foodapp/privacy.html")!
    static let terms = URL(string: "https://example.github.io/foodapp/terms.html")!
    /// Стандартное лицензионное соглашение Apple (подходит для подписок).
    static let appleEULA = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
}
