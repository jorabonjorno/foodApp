import UIKit
import XCTest
@testable import FoodApp

/// Проверки локальной базы рецептов из бандла приложения.
final class RecipeDatabaseTests: XCTestCase {
    private var recipes: [Recipe] = []

    override func setUp() async throws {
        recipes = BundledRecipeRepository.load(bundle: .main, fileName: "recipes")
    }

    func testDatabaseLoads() {
        XCTAssertGreaterThanOrEqual(recipes.count, 100, "recipes.json не найден или повреждён")
    }

    func testIdsAreUnique() {
        XCTAssertEqual(Set(recipes.map(\.id)).count, recipes.count)
    }

    func testAllIngredientKeysAreKnown() {
        for recipe in recipes {
            for ingredient in recipe.ingredients {
                XCTAssertNotNil(FoodDictionary.entry(for: ingredient.normalizedName), "\(recipe.id): \(ingredient.normalizedName)")
            }
        }
    }

    func testRecipesAreComplete() {
        for recipe in recipes {
            XCTAssertFalse(recipe.title.isEmpty, recipe.id)
            XCTAssertGreaterThanOrEqual(recipe.steps.count, 2, recipe.id)
            XCTAssertGreaterThanOrEqual(recipe.ingredients.count, 2, recipe.id)
            XCTAssertGreaterThan(recipe.cookingTimeMinutes, 0, recipe.id)
        }
    }

    func testMockScanFindsRecipesInDatabase() async throws {
        let foods = try await MockFoodRecognitionService(delay: .zero).recognizeFoods(from: UIImage())
        let matches = DefaultRecipeMatchingService().match(
            recipes: recipes,
            ingredients: foods.map { $0.toIngredient() },
            filters: .default
        )
        XCTAssertGreaterThanOrEqual(matches.count, 10)
        XCTAssertTrue(matches.contains(where: \.canCookNow), "Из mock-продуктов должно готовиться хотя бы одно блюдо")
    }

    func testWeeklyMenuHasSevenDistinctRecipes() {
        let pantry = ["chicken", "potato", "onion", "carrot", "egg", "pasta", "tomato", "cheese"].map {
            Ingredient(name: $0, normalizedName: $0, category: .other)
        }
        let menu = WeeklyMenuService().makeMenu(recipes: recipes, ingredients: pantry, filters: .default)
        XCTAssertEqual(menu.count, 7)
        XCTAssertEqual(Set(menu.map(\.recipe.id)).count, 7)
    }

    func testWeeklyMenuWorksWithoutIngredients() {
        let menu = WeeklyMenuService().makeMenu(recipes: recipes, ingredients: [], filters: .default)
        XCTAssertEqual(menu.count, 7)
    }
}
