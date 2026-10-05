import Foundation

struct RecipeIngredient: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    /// Канонический ключ (`tomato`, `chicken_breast`) — по нему идёт matching.
    let normalizedName: String
    let quantity: Double?
    let unit: String?
    /// Необязательный ингредиент не считается недостающим.
    let optional: Bool

    init(id: String? = nil, name: String, normalizedName: String, quantity: Double? = nil, unit: String? = nil, optional: Bool = false) {
        self.id = id ?? normalizedName
        self.name = name
        self.normalizedName = normalizedName
        self.quantity = quantity
        self.unit = unit
        self.optional = optional
    }

    enum CodingKeys: String, CodingKey {
        case id, name, normalizedName, quantity, unit, optional
    }

    /// В JSON поля `id` и `optional` можно опускать.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let normalizedName = try c.decode(String.self, forKey: .normalizedName)
        self.init(
            id: try c.decodeIfPresent(String.self, forKey: .id),
            name: try c.decode(String.self, forKey: .name),
            normalizedName: normalizedName,
            quantity: try c.decodeIfPresent(Double.self, forKey: .quantity),
            unit: try c.decodeIfPresent(String.self, forKey: .unit),
            optional: try c.decodeIfPresent(Bool.self, forKey: .optional) ?? false
        )
    }

    /// "300 г", "2 шт.", "по вкусу".
    var formattedAmount: String? {
        guard let quantity else { return unit }
        let number = quantity.formatted(.number.precision(.fractionLength(0...1)))
        guard let unit, !unit.isEmpty else { return number }
        return "\(number) \(unit)"
    }

    var emoji: String {
        FoodDictionary.emoji(for: normalizedName, category: FoodDictionary.entry(for: normalizedName)?.category ?? .other)
    }
}

struct Recipe: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let description: String
    let cookingTimeMinutes: Int
    let difficulty: Difficulty
    let servings: Int
    let mealType: MealType
    let ingredients: [RecipeIngredient]
    let steps: [String]
    /// Эмодзи для обложки (фото рецептов в MVP не используются — это бесплатно и без авторских прав).
    let emoji: String?

    var coverEmoji: String { emoji ?? mealType.defaultEmoji }

    /// "25 мин · Легко · 2 порции"
    var metaLine: String {
        [L10n.Recipe.minutes(cookingTimeMinutes), difficulty.title, L10n.Recipe.servings(servings)]
            .joined(separator: " · ")
    }
}

extension MealType {
    var defaultEmoji: String {
        switch self {
        case .breakfast: "🍳"
        case .lunch: "🍲"
        case .dinner: "🍽️"
        case .soup: "🥣"
        case .salad: "🥗"
        case .baking: "🥐"
        case .dessert: "🍰"
        case .other: "🍴"
        }
    }
}
