import Foundation
import Observation
import Security

/// Месячный счётчик AI-сканирований.
/// Хранится в Keychain: в отличие от UserDefaults, он переживает переустановку приложения,
/// поэтому бесплатный лимит нельзя «обнулить», удалив приложение. Реальный потолок расходов — лимит в консоли AI-провайдера.
@MainActor
@Observable
final class ScanQuota {
    private(set) var usedThisMonth: Int = 0
    @ObservationIgnored private let storage: QuotaStorage
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private var period: String = ""

    init(storage: QuotaStorage = KeychainQuotaStorage(), now: @escaping () -> Date = { Date() }) {
        self.storage = storage
        self.now = now
        load()
    }

    func limit(isPremium: Bool) -> Int {
        isPremium ? PlanLimits.proScansPerMonth : PlanLimits.freeScansPerMonth
    }

    /// Чистое чтение (без изменения состояния) — безопасно вызывать из `body`.
    func remaining(isPremium: Bool) -> Int {
        max(0, limit(isPremium: isPremium) - used)
    }

    /// Использовано в текущем календарном месяце (после смены месяца — 0).
    var used: Int { period == currentPeriod ? usedThisMonth : 0 }

    /// Списывается только успешное распознавание.
    func consume() {
        rollOverIfNeeded()
        usedThisMonth += 1
        save()
    }

    func reset() {
        usedThisMonth = 0
        save()
    }

    // MARK: - Persistence

    private struct Record: Codable {
        var period: String
        var used: Int
    }

    private var currentPeriod: String {
        let components = Calendar(identifier: .gregorian).dateComponents([.year, .month], from: now())
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
    }

    private func load() {
        let current = currentPeriod
        if let data = storage.read(), let record = try? JSONDecoder().decode(Record.self, from: data), record.period == current {
            usedThisMonth = record.used
        } else {
            usedThisMonth = 0
        }
        period = current
    }

    private func rollOverIfNeeded() {
        guard period != currentPeriod else { return }
        period = currentPeriod
        usedThisMonth = 0
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(Record(period: period, used: usedThisMonth)) else { return }
        storage.write(data)
    }
}

protocol QuotaStorage {
    func read() -> Data?
    func write(_ data: Data)
}

struct KeychainQuotaStorage: QuotaStorage {
    var account = "scan_quota.v1"
    private var service: String { Bundle.main.bundleIdentifier ?? "FoodApp" }

    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    func read() -> Data? {
        var request = query
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(request as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    func write(_ data: Data) {
        let attributes = [kSecValueData as String: data]
        if SecItemUpdate(query as CFDictionary, attributes as CFDictionary) == errSecItemNotFound {
            var item = query
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(item as CFDictionary, nil)
        }
    }
}

/// Для тестов и превью.
final class InMemoryQuotaStorage: QuotaStorage {
    private var data: Data?
    func read() -> Data? { data }
    func write(_ data: Data) { self.data = data }
}
