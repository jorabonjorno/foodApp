import Foundation

/// Продукт пользователя (подтверждённый, из Pantry или добавленный вручную).
struct Ingredient: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    /// Канонический ключ продукта (`tomato`, `chicken_breast`), используется для matching.
    var normalizedName: String
    var category: FoodCategory
    var quantity: Double?
    var unit: String?
    /// Уверенность AI (nil — продукт добавлен пользователем).
    var confidence: Double?

    init(
        id: UUID = UUID(),
        name: String,
        normalizedName: String,
        category: FoodCategory,
        quantity: Double? = nil,
        unit: String? = nil,
        confidence: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.normalizedName = normalizedName
        self.category = category
        self.quantity = quantity
        self.unit = unit
        self.confidence = confidence
    }

    var isLowConfidence: Bool { (confidence ?? 1) < 0.6 }

    var emoji: String { FoodDictionary.emoji(for: normalizedName, category: category) }

    /// "2 шт.", "300 г" или nil.
    var formattedQuantity: String? {
        guard let quantity else { return nil }
        let number = quantity.formatted(.number.precision(.fractionLength(0...1)))
        if let unit, !unit.isEmpty { return "\(number) \(unit)" }
        return number
    }
}

extension Ingredient {
    /// Создаёт ингредиент из произвольного названия, введённого пользователем.
    static func make(fromUserInput rawName: String, normalizer: IngredientNormalizer = .shared) -> Ingredient? {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let key = normalizer.normalize(name)
        let entry = FoodDictionary.entry(for: key)
        return Ingredient(
            name: name.prefix(1).uppercased() + name.dropFirst(),
            normalizedName: key,
            category: entry?.category ?? .other,
            quantity: nil,
            unit: entry?.defaultUnit
        )
    }
}
