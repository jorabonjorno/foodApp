import Foundation
import Observation

/// Поиск рецептов полностью локальный: база в бандле + алгоритм matching. Ни одного AI-запроса.
@MainActor
@Observable
final class RecipesViewModel {
    private(set) var isLoading = true
    private(set) var ingredients: [Ingredient]
    private(set) var matches: [RecipeMatch] = []
    var isFiltersPresented = false

    private var allRecipes: [Recipe] = []
    private var didTrackOpen = false
    private let container: AppContainer

    init(container: AppContainer, ingredients: [Ingredient]) {
        self.container = container
        self.ingredients = ingredients
    }

    /// Активные фильтры. PRO-часть применяется только при активной подписке.
    var filters: RecipeFilters {
        let stored = container.filters.filters
        return container.entitlements.canUse(feature: .advancedFilters) ? stored : stored.basicOnly
    }

    var canUseAdvancedFilters: Bool { container.entitlements.canUse(feature: .advancedFilters) }
    var cookNow: [RecipeMatch] { matches.filter(\.canCookNow) }
    var almost: [RecipeMatch] { matches.filter { !$0.canCookNow } }
    var isEmptyResult: Bool { !isLoading && matches.isEmpty }

    func load() async {
        if allRecipes.isEmpty {
            allRecipes = await container.recipes.allRecipes()
        }
        rerank()
        isLoading = false
        if !didTrackOpen {
            didTrackOpen = true
            container.analytics.track(.recipeListOpened(resultsCount: matches.count))
        }
    }

    private func rerank() {
        matches = container.matcher.match(recipes: allRecipes, ingredients: ingredients, filters: filters)
    }

    // MARK: - Filters

    func apply(_ newFilters: RecipeFilters) {
        container.filters.filters = newFilters
        rerank()
    }

    func resetFilters() {
        apply(.default)
    }

    var isQuickSelected: Bool { (filters.maxCookingTime ?? .max) <= 30 }
    var isEasySelected: Bool { filters.difficulty == .easy }
    var isCookNowSelected: Bool { !filters.allowMissingIngredients }

    func toggleQuick() {
        var updated = container.filters.filters
        updated.maxCookingTime = isQuickSelected ? nil : 30
        apply(updated)
    }

    func toggleEasy() {
        var updated = container.filters.filters
        updated.difficulty = isEasySelected ? nil : .easy
        apply(updated)
    }

    func toggleCookNow() {
        var updated = container.filters.filters
        updated.allowMissingIngredients.toggle()
        apply(updated)
    }

    func showPaywallForFilters() {
        container.router.presentPaywall(.feature)
    }

    // MARK: - Favorites

    func isFavorite(_ recipe: Recipe) -> Bool { container.favorites.isFavorite(recipe) }

    func toggleFavorite(_ recipe: Recipe) {
        if container.favorites.toggle(recipe) {
            container.analytics.track(.recipeFavorited(id: recipe.id))
        }
    }
}
