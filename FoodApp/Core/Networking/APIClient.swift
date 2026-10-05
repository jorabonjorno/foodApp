import Foundation

/// Минимальный HTTP-клиент для backend-proxy.
/// Клиент не знает ни о каких AI-ключах: авторизация к AI-провайдеру делается на сервере.
struct APIClient: Sendable {
    let baseURL: URL
    var session: URLSession = .shared
    /// Публичный токен приложения (не секрет): прокси отсекает запросы без него.
    var appToken: String = ""
    var timeout: TimeInterval = 30
    /// Один повтор: каждый запрос к AI стоит денег, агрессивные ретраи не нужны.
    var maxRetries: Int = 1

    func post<Body: Encodable, Response: Decodable>(
        _ path: String,
        body: Body,
        as type: Response.Type
    ) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Locale.current.language.languageCode?.identifier ?? "ru", forHTTPHeaderField: "Accept-Language")
        if !appToken.isEmpty { request.setValue(appToken, forHTTPHeaderField: "X-App-Token") }
        request.httpBody = try JSONEncoder().encode(body)

        let data = try await send(request)
        return try AIResponseDecoder.decode(type, from: data)
    }

    /// Выполняет запрос с повторами (экспоненциальная задержка) для сетевых ошибок, таймаутов, 429 и 5xx.
    private func send(_ request: URLRequest) async throws -> Data {
        var attempt = 0
        while true {
            do {
                try Task.checkCancellation()
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else { throw AppError.unknown }
                guard (200..<300).contains(http.statusCode) else {
                    throw AppError.server(statusCode: http.statusCode)
                }
                return data
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                let appError = AppError.from(error)
                guard appError.isRetryable, attempt < maxRetries else { throw appError }
                attempt += 1
                let delay = 0.8 * pow(2, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }
}
