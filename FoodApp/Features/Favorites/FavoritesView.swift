import Observation
import SwiftUI

@MainActor
@Observable
final class FavoritesViewModel {
    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    /// Совпадение пересчитывается с текущими продуктами пользователя.
    var matches: [RecipeMatch] { container.favorites.recipes.map(container.match(for:)) }

    func toggleFavorite(_ recipe: Recipe) { container.favorites.toggle(recipe) }

    func findRecipes() {
        container.router.selectedTab = .home
    }
}

struct FavoritesView: View {
    @State private var viewModel: FavoritesViewModel

    init(container: AppContainer) {
        _viewModel = State(initialValue: FavoritesViewModel(container: container))
    }

    var body: some View {
        Group {
            if viewModel.matches.isEmpty {
                EmptyStateView(
                    title: L10n.Favorites.emptyTitle,
                    message: L10n.Favorites.emptyMessage,
                    systemImage: "heart",
                    primaryTitle: L10n.Favorites.findRecipes,
                    primaryAction: viewModel.findRecipes
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.m) {
                        ForEach(viewModel.matches) { match in
                            RecipeCardView(
                                match: match,
                                isFavorite: true,
                                onToggleFavorite: { withAnimation { viewModel.toggleFavorite(match.recipe) } }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, Theme.Spacing.s)
                }
            }
        }
        .background(Theme.background)
        .navigationTitle(L10n.Favorites.title)
    }
}
