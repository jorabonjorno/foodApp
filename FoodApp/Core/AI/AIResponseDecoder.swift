import Foundation

/// Защищённое декодирование ответов AI.
/// - пустой ответ → `AppError.emptyResponse`;
/// - снимает обёртки ```json … ``` и текст до/после JSON-объекта;
/// - malformed JSON → `AppError.decoding` (приложение не падает).
enum AIResponseDecoder {
    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        guard !data.isEmpty else { throw AppError.emptyResponse }
        let decoder = JSONDecoder()

        if let value = try? decoder.decode(T.self, from: data) { return value }

        guard let text = String(data: data, encoding: .utf8) else { throw AppError.decoding }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AppError.emptyResponse }

        guard let start = trimmed.firstIndex(of: "{"), let end = trimmed.lastIndex(of: "}"), start < end,
              let json = String(trimmed[start...end]).data(using: .utf8)
        else { throw AppError.decoding }

        do {
            return try decoder.decode(T.self, from: json)
        } catch {
            throw AppError.decoding
        }
    }
}

/// Массив, который пропускает невалидные элементы вместо того, чтобы ронять декодирование целиком.
struct LossyArray<Element: Decodable>: Decodable {
    var elements: [Element]

    init(_ elements: [Element] = []) { self.elements = elements }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var result: [Element] = []
        while !container.isAtEnd {
            if let element = try? container.decode(Element.self) {
                result.append(element)
            } else {
                _ = try? container.decode(Skip.self)
            }
        }
        elements = result
    }

    private struct Skip: Decodable {
        init(from decoder: Decoder) throws {}
    }
}

extension KeyedDecodingContainer {
    /// Число, которое AI может прислать как `2`, `2.5` или `"2"`.
    func flexibleDouble(forKey key: Key) -> Double? {
        if let value = try? decodeIfPresent(Double.self, forKey: key) { return value }
        if let string = try? decodeIfPresent(String.self, forKey: key) {
            return Double(string.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces))
        }
        return nil
    }

    func flexibleInt(forKey key: Key) -> Int? {
        flexibleDouble(forKey: key).map { Int($0.rounded()) }
    }

    func nonEmptyString(forKey key: Key) -> String? {
        guard let value = try? decodeIfPresent(String.self, forKey: key) else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
