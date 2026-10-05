import Observation
import SwiftUI

/// Меню на неделю (PRO). Без AI: алгоритм выбирает 7 разнообразных рецептов из локальной базы.
@MainActor
@Observable
final class WeeklyMenuViewModel {
    private(set) var menu: [RecipeMatch] = []
    private(set) var isLoading = false
    var toast: String?
    private let container: AppContainer
    private static let storageKey = "weekly_menu.v1"

    init(container: AppContainer) {
        self.container = container
    }

    var hasMissing: Bool { menu.contains { !$0.missing.isEmpty } }

    func dayTitle(_ index: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: index, to: .now) ?? .now
        return date.formatted(.dateTime.weekday(.wide)).capitalized
    }

    /// Загружает сохранённое меню или создаёт новое.
    func load() async {
        guard menu.isEmpty else { return }
        let recipes = await container.recipes.allRecipes()
        if let ids = UserDefaults.standard.stringArray(forKey: Self.storageKey), !ids.isEmpty {
            let byID = Dictionary(recipes.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            menu = ids.compactMap { byID[$0] }.map(container.match(for:))
        }
        if menu.isEmpty { await generate() }
    }

    func generate() async {
        isLoading = true
        defer { isLoading = false }
        let recipes = await container.recipes.allRecipes()
        menu = container.weeklyMenu.makeMenu(
            recipes: recipes,
            ingredients: container.currentIngredients,
            filters: container.filters.filters.basicOnly
        )
        UserDefaults.standard.set(menu.map(\.recipe.id), forKey: Self.storageKey)
    }

    func addAllMissingToShoppingList() {
        container.requirePremium(.shoppingList) {
            var added = 0
            for match in menu {
                added += container.shoppingList.add(match.missing, from: match.recipe)
            }
            if added > 0 {
                container.analytics.track(.shoppingListAdded(count: added))
                toast = L10n.ShoppingList.added(added)
            }
        }
    }
}

struct WeeklyMenuView: View {
    @State private var viewModel: WeeklyMenuViewModel

    init(container: AppContainer) {
        _viewModel = State(initialValue: WeeklyMenuViewModel(container: container))
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text(L10n.WeeklyMenu.title)
                    .font(.largeTitle.weight(.heavy))
                    .fontDesign(.rounded)
                    .accessibilityAddTraits(.isHeader)
                Text(L10n.WeeklyMenu.hint)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, Theme.Spacing.xs)

                if viewModel.isLoading && viewModel.menu.isEmpty {
                    ForEach(0..<3, id: \.self) { _ in RecipeCardSkeleton() }
                } else {
                    ForEach(Array(viewModel.menu.enumerated()), id: \.element.id) { index, match in
                        NavigationLink(value: AppRoute.recipeDetail(match)) {
                            WeeklyMenuRow(day: viewModel.dayTitle(index), match: match)
                        }
                        .buttonStyle(.pressable)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Theme.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.generate() }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .accessibilityLabel(L10n.WeeklyMenu.regenerate)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.hasMissing {
                Button(action: viewModel.addAllMissingToShoppingList) {
                    Label(L10n.WeeklyMenu.addMissing, systemImage: "cart.badge.plus")
                }
                .buttonStyle(.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, Theme.Spacing.s)
                .background(.bar)
            }
        }
        .toast($viewModel.toast)
        .task { await viewModel.load() }
    }
}

private struct WeeklyMenuRow: View {
    let day: String
    let match: RecipeMatch

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            RecipeArtworkView(recipe: match.recipe, emojiSize: 32)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(day)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                Text(match.recipe.title)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Text(match.canCookNow ? L10n.Recipe.canCook : L10n.Recipe.missingCount(match.missing.count))
                    .font(.caption)
                    .foregroundStyle(match.canCookNow ? Theme.success : .secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .cardStyle(padding: Theme.Spacing.s)
        .accessibilityElement(children: .combine)
    }
}
