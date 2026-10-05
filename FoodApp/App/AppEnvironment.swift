import Foundation

/// Режим работы приложения.
/// - `.mock`: AI не вызывается, распознавание возвращает подготовленный список, сеть не нужна. Разработка без расходов.
/// - `.production`: распознавание через backend-proxy. Ключа AI в приложении нет.
enum AppEnvironment: Equatable, Sendable {
    case mock
    case production(apiBaseURL: URL)

    var isMock: Bool { self == .mock }

    /// URL прокси задаётся build setting `API_BASE_URL` (Info.plist → `APIBaseURL`).
    /// Пусто → `.mock`. Аргумент запуска `-mock` принудительно включает mock-режим.
    static func current(bundle: Bundle = .main, arguments: [String] = ProcessInfo.processInfo.arguments) -> AppEnvironment {
        if arguments.contains("-mock") { return .mock }
        let raw = (bundle.object(forInfoDictionaryKey: "APIBaseURL") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty, !raw.hasPrefix("$("),
              let url = URL(string: raw), url.scheme == "https" || url.scheme == "http"
        else { return .mock }
        return .production(apiBaseURL: url)
    }

    /// Публичный идентификатор приложения для прокси (не секрет — отсекает случайный трафик).
    static var appToken: String {
        Bundle.main.object(forInfoDictionaryKey: "APIAppToken") as? String ?? ""
    }
}
