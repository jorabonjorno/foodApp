import Foundation

extension Ingredient {
    /// Шаг изменения количества кнопками ±.
    var quantityStep: Double {
        switch unit {
        case "г"?, "мл"?: (quantity ?? 0) >= 500 ? 100 : 50
        default: 1
        }
    }

    mutating func incrementQuantity() {
        if let quantity {
            self.quantity = quantity + quantityStep
        } else {
            if unit == nil { unit = FoodDictionary.entry(for: normalizedName)?.defaultUnit ?? "шт" }
            switch unit {
            case "г"?: quantity = 100
            case "мл"?: quantity = 200
            default: quantity = 1
            }
        }
    }

    mutating func decrementQuantity() {
        guard let quantity else { return }
        let next = quantity - quantityStep
        self.quantity = next > 0 ? next : nil
    }

    /// Переименование пользователем: пересчитываем ключ и категорию, уверенность AI больше не важна.
    mutating func rename(to newName: String, normalizer: IngredientNormalizer = .shared) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        name = trimmed.prefix(1).uppercased() + trimmed.dropFirst()
        normalizedName = normalizer.normalize(trimmed)
        if let entry = FoodDictionary.entry(for: normalizedName) {
            category = entry.category
        }
        confidence = nil
    }

    init(entry: FoodDictionaryEntry) {
        self.init(
            name: entry.displayName,
            normalizedName: entry.key,
            category: entry.category,
            quantity: nil,
            unit: entry.defaultUnit
        )
    }
}

extension FoodDictionary {
    static func displayName(for key: String) -> String {
        entry(for: key)?.displayName ?? key.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

extension RecipeFilters {
    mutating func toggleRequired(_ key: String) {
        if let index = requiredIngredients.firstIndex(of: key) {
            requiredIngredients.remove(at: index)
        } else {
            requiredIngredients.append(key)
        }
    }

    mutating func addExcluded(_ rawName: String, normalizer: IngredientNormalizer = .shared) {
        let key = normalizer.normalize(rawName)
        guard !key.isEmpty, !excludedIngredients.contains(key) else { return }
        excludedIngredients.append(key)
    }
}
