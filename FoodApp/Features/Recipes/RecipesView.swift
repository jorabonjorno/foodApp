import SwiftUI

struct RecipesView: View {
    @State private var viewModel: RecipesViewModel

    init(container: AppContainer, ingredients: [Ingredient]) {
        _viewModel = State(initialValue: RecipesViewModel(container: container, ingredients: ingredients))
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.m) {
                header
                ingredientChips
                filterBar
                content
            }
            .padding(.horizontal, 20)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Theme.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.isFiltersPresented) {
            RecipeFiltersView(
                initial: viewModel.filters,
                ingredients: viewModel.ingredients,
                canUseAdvanced: viewModel.canUseAdvancedFilters,
                onApply: viewModel.apply,
                onUnlock: viewModel.showPaywallForFilters
            )
        }
        .task { await viewModel.load() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text(L10n.Recipes.title)
                .font(.largeTitle.weight(.heavy))
                .fontDesign(.rounded)
                .accessibilityAddTraits(.isHeader)
            Text(L10n.Recipes.subtitle)
                .foregroundStyle(.secondary)
        }
    }

    private var ingredientChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(viewModel.ingredients) { ingredient in
                    HStack(spacing: 4) {
                        Text(verbatim: ingredient.emoji)
                        Text(ingredient.name)
                    }
                    .font(.footnote.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.surface, in: Capsule())
                }
            }
        }
        .scrollClipDisabled()
        .accessibilityElement(children: .combine)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                ChipView(
                    title: viewModel.filters.activeCount > 0
                        ? "\(L10n.Recipes.filters) · \(viewModel.filters.activeCount)"
                        : L10n.Recipes.filters,
                    systemImage: "slider.horizontal.3",
                    isSelected: viewModel.filters.activeCount > 0
                ) { viewModel.isFiltersPresented = true }
                .accessibilityIdentifier("recipes.filtersButton")

                ChipView(title: L10n.Recipes.quick, systemImage: "bolt.fill", isSelected: viewModel.isQuickSelected, action: viewModel.toggleQuick)
                ChipView(title: L10n.Recipes.easy, isSelected: viewModel.isEasySelected, action: viewModel.toggleEasy)
                ChipView(title: L10n.Recipes.cookNow, systemImage: "checkmark.circle", isSelected: viewModel.isCookNowSelected, action: viewModel.toggleCookNow)
            }
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ForEach(0..<3, id: \.self) { _ in RecipeCardSkeleton() }
        } else if viewModel.isEmptyResult {
            emptyState
                .padding(.top, Theme.Spacing.xl)
        } else {
            if !viewModel.cookNow.isEmpty {
                SectionHeader(title: L10n.Recipes.sectionCookNow)
                    .padding(.top, Theme.Spacing.xs)
                cards(viewModel.cookNow)
            }
            if !viewModel.almost.isEmpty {
                SectionHeader(title: L10n.Recipes.sectionAlmost)
                    .padding(.top, Theme.Spacing.xs)
                cards(viewModel.almost)
            }
        }
    }

    private var emptyState: EmptyStateView {
        var resetAction: (() -> Void)?
        if !viewModel.filters.isDefault {
            resetAction = { viewModel.resetFilters() }
        }
        return EmptyStateView(
            title: L10n.Recipes.emptyTitle,
            message: L10n.Recipes.emptyMessage,
            systemImage: "fork.knife",
            primaryTitle: resetAction == nil ? nil : L10n.Recipes.resetFilters,
            primaryAction: resetAction
        )
    }

    private func cards(_ matches: [RecipeMatch]) -> some View {
        ForEach(matches) { match in
            RecipeCardView(
                match: match,
                isFavorite: viewModel.isFavorite(match.recipe),
                onToggleFavorite: { viewModel.toggleFavorite(match.recipe) }
            )
        }
    }
}
