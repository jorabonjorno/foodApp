import XCTest
@testable import FoodApp

final class RecipeMatchingServiceTests: XCTestCase {
    private let matcher = DefaultRecipeMatchingService()

    private func ingredient(_ key: String) -> Ingredient {
        Ingredient(name: FoodDictionary.displayName(for: key), normalizedName: key, category: .other)
    }

    private func recipe(
        _ id: String,
        keys: [String],
        optional: [String] = [],
        minutes: Int = 20,
        difficulty: Difficulty = .easy,
        meal: MealType = .dinner,
        servings: Int = 2
    ) -> Recipe {
        Recipe(
            id: id, title: id, description: "", cookingTimeMinutes: minutes, difficulty: difficulty,
            servings: servings, mealType: meal,
            ingredients: keys.map { RecipeIngredient(name: $0, normalizedName: $0) }
                + optional.map { RecipeIngredient(name: $0, normalizedName: $0, optional: true) },
            steps: ["a", "b"], emoji: nil
        )
    }

    /// Пример из ТЗ: chicken, tomato, onion, cheese vs рецепт chicken, tomato, onion, cream, parmesan.
    func testSpecExampleCountsAvailableAndMissing() {
        let user = ["chicken", "tomato", "onion", "cheese"].map(ingredient)
        let target = recipe("r", keys: ["chicken", "tomato", "onion", "cream", "parmesan"])
        let match = matcher.match(recipe: target, ingredients: user)

        // cheese ≈ parmesan по иерархии продуктов → недостаёт только сливок.
        XCTAssertEqual(match.totalCount, 5)
        XCTAssertEqual(match.availableCount, 4)
        XCTAssertEqual(match.missing.map(\.normalizedName), ["cream"])
    }

    func testStaplesAndOptionalIngredientsAreNeverMissing() {
        let user = [ingredient("egg")]
        let target = recipe("omelette", keys: ["egg", "salt", "vegetable_oil"], optional: ["herbs"])
        let match = matcher.match(recipe: target, ingredients: user)
        XCTAssertTrue(match.canCookNow)
        XCTAssertTrue(match.missing.isEmpty)
    }

    func testRankingPrefersRecipesWithFewerMissing() {
        let user = ["egg", "tomato"].map(ingredient)
        let full = recipe("full", keys: ["egg", "tomato"])
        let partial = recipe("partial", keys: ["egg", "tomato", "cream", "bacon"])
        let result = matcher.match(recipes: [partial, full], ingredients: user, filters: .default)
        XCTAssertEqual(result.map(\.recipe.id), ["full", "partial"])
    }

    func testRecipesWithoutUserFoodAreExcluded() {
        let user = [ingredient("egg")]
        let unrelated = recipe("beef", keys: ["beef", "onion"])
        XCTAssertTrue(matcher.match(recipes: [unrelated], ingredients: user, filters: .default).isEmpty)
    }

    func testOnlyStaplesReturnsNothing() {
        let user = [ingredient("salt")]
        XCTAssertTrue(matcher.match(recipes: [recipe("x", keys: ["salt", "egg"])], ingredients: user, filters: .default).isEmpty)
    }

    func testFiltersApply() {
        let user = ["egg", "tomato"].map(ingredient)
        let quick = recipe("quick", keys: ["egg", "tomato"], minutes: 10, meal: .breakfast)
        let slow = recipe("slow", keys: ["egg", "tomato"], minutes: 90, difficulty: .hard)
        let missing = recipe("missing", keys: ["egg", "cream"], minutes: 10)

        var filters = RecipeFilters.default
        filters.maxCookingTime = 30
        XCTAssertEqual(Set(matcher.match(recipes: [quick, slow, missing], ingredients: user, filters: filters).map(\.recipe.id)),
                       ["quick", "missing"])

        filters.allowMissingIngredients = false
        XCTAssertEqual(matcher.match(recipes: [quick, slow, missing], ingredients: user, filters: filters).map(\.recipe.id), ["quick"])

        var meal = RecipeFilters.default
        meal.mealType = .breakfast
        XCTAssertEqual(matcher.match(recipes: [quick, slow], ingredients: user, filters: meal).map(\.recipe.id), ["quick"])

        var excluded = RecipeFilters.default
        excluded.addExcluded("сливки")
        XCTAssertFalse(matcher.match(recipes: [missing], ingredients: user, filters: excluded).contains { $0.recipe.id == "missing" })
    }

    func testBasicOnlyDropsProFilters() {
        var filters = RecipeFilters.default
        filters.maxCookingTime = 15
        filters.mealType = .soup
        filters.requiredIngredients = ["egg"]
        let basic = filters.basicOnly
        XCTAssertEqual(basic.maxCookingTime, 15)
        XCTAssertNil(basic.mealType)
        XCTAssertTrue(basic.requiredIngredients.isEmpty)
    }
}
