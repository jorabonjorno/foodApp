import Foundation

/// Приводит произвольное название продукта ("Томаты", "помидор", "Tomatoes") к каноническому ключу ("tomato").
///
/// Алгоритм:
/// 1. очистка: нижний регистр, ё→е, удаление пунктуации, лишних пробелов;
/// 2. точное совпадение с синонимом из `FoodDictionary`;
/// 3. совпадение по «основе» (грубый стемминг русских окончаний и английского множественного числа);
/// 4. совпадение по отдельным словам фразы ("свежие помидоры" → tomato);
/// 5. иначе — стабильный ключ из очищенной строки.
struct IngredientNormalizer: Sendable {
    static let shared = IngredientNormalizer()

    private let exact: [String: String]
    private let stemmed: [String: String]

    init(entries: [FoodDictionaryEntry] = FoodDictionary.entries) {
        var exact: [String: String] = [:]
        var stemmed: [String: String] = [:]
        for entry in entries {
            let variants = entry.synonyms + [entry.displayName, entry.key.replacingOccurrences(of: "_", with: " ")]
            for variant in variants {
                let clean = Self.clean(variant)
                if exact[clean] == nil { exact[clean] = entry.key }
                let stem = Self.stemPhrase(clean)
                if stemmed[stem] == nil { stemmed[stem] = entry.key }
            }
        }
        self.exact = exact
        self.stemmed = stemmed
    }

    func normalize(_ name: String) -> String {
        let clean = Self.clean(name)
        guard !clean.isEmpty else { return "" }

        if let key = exact[clean] { return key }

        let stem = Self.stemPhrase(clean)
        if let key = stemmed[stem] { return key }

        // По словам: берём самое длинное узнанное слово (обычно оно самое информативное).
        let words = clean.split(separator: " ").map(String.init).sorted { $0.count > $1.count }
        for word in words {
            if let key = exact[word] ?? stemmed[Self.stem(word)] { return key }
        }

        return stem.replacingOccurrences(of: " ", with: "_")
    }

    /// Если AI прислал `normalizedName`, доверяем ему, только если это известный ключ.
    func normalize(name: String, suggestedKey: String?) -> String {
        if let suggestedKey {
            let key = suggestedKey.lowercased().trimmingCharacters(in: .whitespaces)
            if FoodDictionary.entry(for: key) != nil { return key }
            let fromKey = normalize(key.replacingOccurrences(of: "_", with: " "))
            if FoodDictionary.entry(for: fromKey) != nil { return fromKey }
        }
        return normalize(name)
    }

    /// Совпадают ли два канонических ключа с учётом иерархии (`chicken_breast` ≈ `chicken`).
    func isSameFood(_ lhs: String, _ rhs: String) -> Bool {
        if lhs == rhs { return true }
        let lp = FoodDictionary.parent(of: lhs)
        let rp = FoodDictionary.parent(of: rhs)
        return lp == rhs || rp == lhs || (lp != nil && lp == rp)
    }

    // MARK: - Text helpers

    static func clean(_ text: String) -> String {
        let lowered = text.lowercased().replacingOccurrences(of: "ё", with: "е")
        let allowed = lowered.unicodeScalars.map { scalar -> Character in
            CharacterSet.letters.contains(scalar) || CharacterSet.decimalDigits.contains(scalar) ? Character(scalar) : " "
        }
        return String(allowed)
            .split(separator: " ")
            .joined(separator: " ")
    }

    static func stemPhrase(_ clean: String) -> String {
        clean.split(separator: " ").map { stem(String($0)) }.joined(separator: " ")
    }

    private static let russianEndings = [
        "ями", "ами", "ого", "его", "ому", "ему", "ыми", "ими",
        "ов", "ев", "ей", "ий", "ый", "ой", "ая", "яя", "ое", "ее", "ые", "ие", "ую", "юю", "ом", "ем", "ам", "ям", "ах", "ях",
        "ы", "и", "а", "я", "у", "ю", "е", "о", "ь", "й",
    ]

    static func stem(_ word: String) -> String {
        guard word.count > 3 else { return word }
        let isCyrillic = word.unicodeScalars.contains { (0x0400...0x04FF).contains($0.value) }
        if isCyrillic {
            for ending in russianEndings where word.hasSuffix(ending) && word.count - ending.count >= 3 {
                return String(word.dropLast(ending.count))
            }
            return word
        }
        if word.hasSuffix("oes") { return String(word.dropLast(2)) }
        if word.hasSuffix("ies") { return String(word.dropLast(3)) + "y" }
        if word.hasSuffix("s") && !word.hasSuffix("ss") { return String(word.dropLast()) }
        return word
    }
}
