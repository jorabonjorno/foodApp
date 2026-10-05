import SwiftUI

/// Карточка рецепта: обложка, название, мета, что есть и чего не хватает.
struct RecipeCardView: View {
    let match: RecipeMatch
    var isFavorite: Bool
    var onToggleFavorite: () -> Void

    private var recipe: Recipe { match.recipe }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(value: AppRoute.recipeDetail(match)) {
                content
            }
            .buttonStyle(.pressable)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilitySummary)
            .accessibilityHint(L10n.Recipe.open)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("recipeCard.\(recipe.id)")

            FavoriteButton(isFavorite: isFavorite, action: onToggleFavorite)
                .padding(Theme.Spacing.xs)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            RecipeArtworkView(recipe: recipe)
                .frame(height: 170)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .topLeading) {
                    statusBadge.padding(Theme.Spacing.s)
                }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(recipe.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                RecipeMetaRow(recipe: recipe)

                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: match.availableRatio)
                        .tint(match.canCookNow ? Theme.success : Theme.accent)
                    Label(L10n.Recipe.available(match.availableCount, match.totalCount), systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.success)
                    if !match.missing.isEmpty {
                        Text(L10n.Recipe.missingList(missingNames))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(.top, Theme.Spacing.xxs)
            }
            .padding(Theme.Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
    }

    private var missingNames: String {
        match.missing.map { $0.name.lowercased() }.joined(separator: ", ")
    }

    @ViewBuilder
    private var statusBadge: some View {
        if match.canCookNow {
            BadgeView(text: L10n.Recipe.canCook, systemImage: "checkmark", color: Theme.success)
        } else {
            BadgeView(text: L10n.Recipe.missingCount(match.missing.count), systemImage: "cart", color: Theme.warning)
        }
    }

    private var accessibilitySummary: String {
        var parts = [recipe.title, recipe.metaLine, L10n.Recipe.available(match.availableCount, match.totalCount)]
        if !match.missing.isEmpty { parts.append(L10n.Recipe.missingList(missingNames)) }
        return parts.joined(separator: ". ")
    }
}

struct RecipeMetaRow: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            Label(L10n.Recipe.minutes(recipe.cookingTimeMinutes), systemImage: "clock")
            Label(recipe.difficulty.title, systemImage: "chart.bar")
            Label(L10n.Recipe.servings(recipe.servings), systemImage: "person.2")
        }
        .labelStyle(CompactLabelStyle())
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}

struct CompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon.imageScale(.small)
            configuration.title
        }
    }
}

struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isFavorite ? Color.red : Color.primary)
                .frame(width: 40, height: 40)
                .background(.regularMaterial, in: Circle())
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: isFavorite)
        .accessibilityLabel(isFavorite ? L10n.Recipe.removeFromFavorites : L10n.Recipe.addToFavorites)
        .accessibilityAddTraits(isFavorite ? .isSelected : [])
    }
}
