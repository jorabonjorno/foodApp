import Foundation

struct RecipeFilters: Codable, Hashable, Sendable {
    // Базовые (Free)
    var maxCookingTime: Int?
    var difficulty: Difficulty?
    /// Показывать рецепты, для которых не хватает ингредиентов.
    var allowMissingIngredients: Bool = true

    // Расширенные (PRO)
    var mealType: MealType?
    var servings: ServingsRange?
    /// Нормализованные ключи продуктов, которые обязательно должны быть в рецепте.
    var requiredIngredients: [String] = []
    /// Нормализованные ключи продуктов, которых не должно быть в рецепте.
    var excludedIngredients: [String] = []

    static let `default` = RecipeFilters()

    var hasAdvancedFilters: Bool {
        mealType != nil || servings != nil || !requiredIngredients.isEmpty || !excludedIngredients.isEmpty
    }

    /// Те же фильтры без PRO-части (если подписка закончилась).
    var basicOnly: RecipeFilters {
        RecipeFilters(maxCookingTime: maxCookingTime, difficulty: difficulty, allowMissingIngredients: allowMissingIngredients)
    }

    var activeCount: Int {
        [maxCookingTime != nil, difficulty != nil, !allowMissingIngredients, mealType != nil, servings != nil]
            .filter { $0 }.count + requiredIngredients.count + excludedIngredients.count
    }

    var isDefault: Bool { self == .default }

    /// Варианты фильтра по времени: nil = "Неважно".
    static let timeOptions: [Int?] = [15, 30, 60, nil]
}
