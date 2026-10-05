import SwiftUI

struct RecipeDetailView: View {
    @State private var viewModel: RecipeDetailViewModel

    init(container: AppContainer, match: RecipeMatch) {
        _viewModel = State(initialValue: RecipeDetailViewModel(container: container, match: match))
    }

    private var recipe: Recipe { viewModel.recipe }
    private var match: RecipeMatch { viewModel.match }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                RecipeArtworkView(recipe: recipe, emojiSize: 110)
                    .frame(height: 260)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    titleBlock
                    matchCard
                    ingredientsSection
                    stepsSection
                }
                .padding(20)
                .background(
                    Theme.background,
                    in: UnevenRoundedRectangle(topLeadingRadius: Theme.Radius.hero, topTrailingRadius: Theme.Radius.hero, style: .continuous)
                )
                .offset(y: -Theme.Spacing.l)
                .padding(.bottom, -Theme.Spacing.l)
            }
        }
        .background(Theme.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(item: viewModel.shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel(L10n.Recipe.share)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: viewModel.toggleFavorite) {
                Label(
                    viewModel.isFavorite ? L10n.Recipe.inFavorites : L10n.Recipe.addToFavorites,
                    systemImage: viewModel.isFavorite ? "heart.fill" : "heart"
                )
                .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.vertical, Theme.Spacing.s)
            .background(.bar)
            .accessibilityIdentifier("recipeDetail.favoriteButton")
        }
        .sensoryFeedback(.success, trigger: viewModel.isFavorite)
        .toast($viewModel.toast)
        .task { viewModel.onAppear() }
    }

    // MARK: - Blocks

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(recipe.title)
                .font(.largeTitle.weight(.bold))
                .fontDesign(.rounded)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: Theme.Spacing.xs) {
                InfoPill(icon: "clock", text: L10n.Recipe.minutes(recipe.cookingTimeMinutes))
                InfoPill(icon: "chart.bar", text: recipe.difficulty.title)
                InfoPill(icon: "person.2", text: L10n.Recipe.servings(recipe.servings))
            }
            if !recipe.description.isEmpty {
                Text(recipe.description)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var matchCard: some View {
        HStack(spacing: Theme.Spacing.m) {
            ZStack {
                Circle().stroke(Color.primary.opacity(0.08), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: match.availableRatio)
                    .stroke(match.canCookNow ? Theme.success : Theme.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(verbatim: "\(match.availableCount)/\(match.totalCount)")
                    .font(.subheadline.weight(.bold).monospacedDigit())
            }
            .frame(width: 56, height: 56)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.Recipe.available(match.availableCount, match.totalCount))
                    .font(.headline)
                Text(match.canCookNow ? L10n.Recipe.canCook : L10n.Recipe.missingCount(match.missing.count))
                    .font(.subheadline)
                    .foregroundStyle(match.canCookNow ? Theme.success : Theme.warning)
            }
            Spacer(minLength: 0)
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            SectionHeader(title: L10n.Recipe.ingredients)
            VStack(spacing: 0) {
                ForEach(Array(recipe.ingredients.enumerated()), id: \.element.id) { index, ingredient in
                    if index > 0 { Divider().padding(.leading, 44) }
                    ingredientRow(ingredient)
                }
            }
            .cardStyle(padding: Theme.Spacing.s)

            if !match.missing.isEmpty {
                shoppingButton
            }
        }
    }

    private func ingredientRow(_ ingredient: RecipeIngredient) -> some View {
        let available = match.isAvailable(ingredient)
        return HStack(spacing: Theme.Spacing.s) {
            Image(systemName: available ? "checkmark.circle.fill" : (ingredient.optional ? "circle.dashed" : "exclamationmark.triangle.fill"))
                .font(.title3)
                .foregroundStyle(available ? Theme.success : (ingredient.optional ? Color.secondary : Theme.warning))
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 1) {
                Text(ingredient.name).font(.body)
                if ingredient.optional {
                    Text(L10n.Recipe.optional).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let amount = ingredient.formattedAmount {
                Text(amount)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityValue(available ? L10n.Recipe.have : (ingredient.optional ? L10n.Recipe.optional : L10n.Recipe.missing))
    }

    private var shoppingButton: some View {
        Button(action: viewModel.addMissingToShoppingList) {
            HStack {
                Label(
                    viewModel.allMissingInList ? L10n.ShoppingList.alreadyAdded : L10n.ShoppingList.addMissing,
                    systemImage: viewModel.allMissingInList ? "checkmark" : "cart.badge.plus"
                )
                if !viewModel.canUseShoppingList { ProBadge() }
            }
        }
        .buttonStyle(.secondary)
        .disabled(viewModel.allMissingInList)
        .accessibilityIdentifier("recipeDetail.shoppingListButton")
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(title: L10n.Recipe.steps)
            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: Theme.Spacing.s) {
                    Text(verbatim: "\(index + 1)")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Theme.ctaGradient, in: Circle())
                        .accessibilityHidden(true)
                    Text(step)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(L10n.Recipe.step(index + 1) + ". " + step)
            }
        }
    }
}

private struct InfoPill: View {
    let icon: String
    let text: String

    var body: some View {
        Label(text, systemImage: icon)
            .labelStyle(CompactLabelStyle())
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Theme.surface, in: Capsule())
    }
}
