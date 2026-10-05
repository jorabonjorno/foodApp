import Foundation

/// Меню на 7 дней из локальной базы без AI.
/// Жадный выбор: на каждом шаге берём рецепт с лучшим score с учётом штрафов за однообразие
/// (тот же тип блюда, тот же основной продукт).
struct WeeklyMenuService: Sendable {
    var matcher: DefaultRecipeMatchingService = DefaultRecipeMatchingService()
    var days = 7

    /// Типы блюд, подходящие для основного приёма пищи.
    private static let mainMeals: Set<MealType> = [.lunch, .dinner, .soup, .salad, .other]

    func makeMenu(recipes: [Recipe], ingredients: [Ingredient], filters: RecipeFilters) -> [RecipeMatch] {
        var relaxed = filters
        relaxed.allowMissingIngredients = true
        relaxed.mealType = nil

        let candidates = matcher.match(recipes: recipes, ingredients: ingredients, filters: relaxed)
            .filter { Self.mainMeals.contains($0.recipe.mealType) }
        let pool = candidates.isEmpty
            // Нет продуктов — меню из быстрых и простых блюд базы.
            ? recipes.filter { Self.mainMeals.contains($0.mealType) }
                .map { matcher.match(recipe: $0, ingredients: ingredients) }
                .sorted { $0.recipe.cookingTimeMinutes < $1.recipe.cookingTimeMinutes }
            : candidates

        var menu: [RecipeMatch] = []
        var usedMeals: [MealType: Int] = [:]
        var usedMains: Set<String> = []
        var remaining = pool

        while menu.count < days, !remaining.isEmpty {
            let best = remaining.enumerated().max { lhs, rhs in
                adjustedScore(lhs.element, usedMeals: usedMeals, usedMains: usedMains, position: lhs.offset)
                    < adjustedScore(rhs.element, usedMeals: usedMeals, usedMains: usedMains, position: rhs.offset)
            }
            guard let best else { break }
            let pick = remaining.remove(at: best.offset)
            menu.append(pick)
            usedMeals[pick.recipe.mealType, default: 0] += 1
            if let main = Self.mainIngredient(of: pick.recipe) { usedMains.insert(main) }
        }
        return menu
    }

    private func adjustedScore(_ match: RecipeMatch, usedMeals: [MealType: Int], usedMains: Set<String>, position: Int) -> Double {
        var score = match.score
        score -= Double(usedMeals[match.recipe.mealType, default: 0]) * 0.12
        if let main = Self.mainIngredient(of: match.recipe), usedMains.contains(main) { score -= 0.25 }
        return score
    }

    /// «Основной» продукт — первый значимый ингредиент рецепта (обычно мясо/рыба/крупа).
    static func mainIngredient(of recipe: Recipe) -> String? {
        recipe.ingredients.first { !$0.optional && !FoodDictionary.staples.contains($0.normalizedName) }
            .map { FoodDictionary.parent(of: $0.normalizedName) ?? $0.normalizedName }
    }
}
