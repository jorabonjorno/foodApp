import Foundation
import Observation

@MainActor
@Observable
final class RecipeDetailViewModel {
    let match: RecipeMatch
    var toast: String?
    private var didTrackOpen = false
    private let container: AppContainer

    init(container: AppContainer, match: RecipeMatch) {
        self.container = container
        self.match = match
    }

    var recipe: Recipe { match.recipe }
    var isFavorite: Bool { container.favorites.isFavorite(recipe) }
    var canUseShoppingList: Bool { container.entitlements.canUse(feature: .shoppingList) }

    /// Недостающие ингредиенты, которых ещё нет в списке покупок.
    var missingNotInList: [RecipeIngredient] {
        match.missing.filter { !container.shoppingList.contains($0.normalizedName) }
    }

    var allMissingInList: Bool { !match.missing.isEmpty && missingNotInList.isEmpty }

    var shareText: String {
        var lines = [recipe.title, recipe.metaLine, ""]
        lines.append(L10n.Recipe.ingredients + ":")
        for ingredient in recipe.ingredients {
            if let amount = ingredient.formattedAmount {
                lines.append("• \(ingredient.name) — \(amount)")
            } else {
                lines.append("• \(ingredient.name)")
            }
        }
        lines.append("")
        lines.append(L10n.Recipe.steps + ":")
        for (index, step) in recipe.steps.enumerated() {
            lines.append("\(index + 1). \(step)")
        }
        return lines.joined(separator: "\n")
    }

    func onAppear() {
        guard !didTrackOpen else { return }
        didTrackOpen = true
        container.analytics.track(.recipeOpened(id: recipe.id))
    }

    func toggleFavorite() {
        if container.favorites.toggle(recipe) {
            container.analytics.track(.recipeFavorited(id: recipe.id))
            toast = L10n.Recipe.addedToFavorites
        }
    }

    func addMissingToShoppingList() {
        container.requirePremium(.shoppingList) {
            let added = container.shoppingList.add(missingNotInList, from: recipe)
            guard added > 0 else { return }
            container.analytics.track(.shoppingListAdded(count: added))
            toast = L10n.ShoppingList.added(added)
        }
    }
}
