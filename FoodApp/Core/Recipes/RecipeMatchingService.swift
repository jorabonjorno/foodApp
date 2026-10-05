import Foundation

protocol RecipeMatchingService: Sendable {
    /// Отфильтрованные и отсортированные рецепты для продуктов пользователя.
    func match(recipes: [Recipe], ingredients: [Ingredient], filters: RecipeFilters) -> [RecipeMatch]
    /// Совпадение одного рецепта (без фильтров) — для экрана рецепта и избранного.
    func match(recipe: Recipe, ingredients: [Ingredient]) -> RecipeMatch
}

/// Обычный алгоритм без AI.
///
/// score = ingredientMatch * 0.55 + fewMissing * 0.25 + cookingTimeMatch * 0.1 + difficultyMatch * 0.1
/// - ingredientMatch — доля значимых ингредиентов, которые есть (базовые соль/вода/масло и optional не учитываются);
/// - fewMissing — 1 / (1 + недостающие): 1 → 0 недостающих, 0.5 → один, 0.33 → два;
/// - cookingTimeMatch / difficultyMatch — соответствие фильтрам, а без фильтров — лёгкое предпочтение быстрых и простых блюд.
struct DefaultRecipeMatchingService: RecipeMatchingService {
    var normalizer: IngredientNormalizer = .shared

    func match(recipes: [Recipe], ingredients: [Ingredient], filters: RecipeFilters) -> [RecipeMatch] {
        let userKeys = keys(for: ingredients)
        guard userKeys.contains(where: { !FoodDictionary.staples.contains($0) }) else { return [] }

        return recipes
            .filter { passesFilters($0, filters: filters) }
            .map { match($0, userKeys: userKeys, filters: filters) }
            .filter { match in
                // Рецепт должен использовать хотя бы один «настоящий» продукт пользователя.
                let usesUserFood = match.matched.contains { !FoodDictionary.staples.contains($0.normalizedName) }
                return usesUserFood && (filters.allowMissingIngredients || match.canCookNow)
            }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                if lhs.missing.count != rhs.missing.count { return lhs.missing.count < rhs.missing.count }
                return lhs.recipe.cookingTimeMinutes < rhs.recipe.cookingTimeMinutes
            }
    }

    func match(recipe: Recipe, ingredients: [Ingredient]) -> RecipeMatch {
        match(recipe, userKeys: keys(for: ingredients), filters: .default)
    }

    // MARK: - Internals

    func keys(for ingredients: [Ingredient]) -> Set<String> {
        var keys = FoodDictionary.staples
        for ingredient in ingredients {
            keys.insert(ingredient.normalizedName)
            keys.insert(normalizer.normalize(ingredient.name))
        }
        keys.remove("")
        return keys
    }

    func match(_ recipe: Recipe, userKeys: Set<String>, filters: RecipeFilters) -> RecipeMatch {
        var matched: [RecipeIngredient] = []
        var missing: [RecipeIngredient] = []
        for ingredient in recipe.ingredients {
            if has(ingredient.normalizedName, in: userKeys) {
                matched.append(ingredient)
            } else if !ingredient.optional {
                missing.append(ingredient)
            }
        }

        let significant = recipe.ingredients.filter { !$0.optional && !FoodDictionary.staples.contains($0.normalizedName) }
        let significantMatched = significant.filter { has($0.normalizedName, in: userKeys) }.count
        let ingredientMatch = significant.isEmpty ? 1 : Double(significantMatched) / Double(significant.count)
        let fewMissing = 1 / (1 + Double(missing.count))

        let score = ingredientMatch * 0.55
            + fewMissing * 0.25
            + cookingTimeMatch(recipe, filters: filters) * 0.1
            + difficultyMatch(recipe, filters: filters) * 0.1

        return RecipeMatch(recipe: recipe, matched: matched, missing: missing, score: score)
    }

    private func has(_ key: String, in userKeys: Set<String>) -> Bool {
        userKeys.contains(key) || userKeys.contains { normalizer.isSameFood($0, key) }
    }

    private func passesFilters(_ recipe: Recipe, filters: RecipeFilters) -> Bool {
        if let maxTime = filters.maxCookingTime, recipe.cookingTimeMinutes > maxTime { return false }
        if let difficulty = filters.difficulty, recipe.difficulty != difficulty { return false }
        if let mealType = filters.mealType, recipe.mealType != mealType { return false }
        if let servings = filters.servings, !servings.contains(recipe.servings) { return false }

        let recipeKeys = recipe.ingredients.map(\.normalizedName)
        for required in filters.requiredIngredients
        where !recipeKeys.contains(where: { normalizer.isSameFood($0, required) }) {
            return false
        }
        for excluded in filters.excludedIngredients
        where recipeKeys.contains(where: { normalizer.isSameFood($0, excluded) }) {
            return false
        }
        return true
    }

    private func cookingTimeMatch(_ recipe: Recipe, filters: RecipeFilters) -> Double {
        if let maxTime = filters.maxCookingTime {
            return recipe.cookingTimeMinutes <= maxTime ? 1 : 0
        }
        switch recipe.cookingTimeMinutes {
        case ...30: return 1
        case ...60: return 0.7
        default: return 0.4
        }
    }

    private func difficultyMatch(_ recipe: Recipe, filters: RecipeFilters) -> Double {
        if let difficulty = filters.difficulty {
            return recipe.difficulty == difficulty ? 1 : 0
        }
        switch recipe.difficulty {
        case .easy: return 1
        case .medium: return 0.8
        case .hard: return 0.5
        }
    }
}
