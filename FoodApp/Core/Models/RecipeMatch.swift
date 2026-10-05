import Foundation

/// Результат сопоставления рецепта с продуктами пользователя.
struct RecipeMatch: Identifiable, Hashable, Sendable {
    let recipe: Recipe
    /// Ингредиенты, которые у пользователя есть (включая базовые: соль, вода, масло).
    let matched: [RecipeIngredient]
    /// Обязательные ингредиенты, которых нет.
    let missing: [RecipeIngredient]
    /// 0...1, чем больше — тем выше в выдаче.
    let score: Double

    var id: String { recipe.id }
    /// Сколько обязательных ингредиентов в рецепте.
    var totalCount: Int { recipe.ingredients.filter { !$0.optional }.count }
    var availableCount: Int { matched.filter { !$0.optional }.count }
    var canCookNow: Bool { missing.isEmpty }
    var availableRatio: Double { totalCount == 0 ? 1 : Double(availableCount) / Double(totalCount) }

    func isAvailable(_ ingredient: RecipeIngredient) -> Bool {
        matched.contains(ingredient)
    }
}
