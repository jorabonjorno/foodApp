import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel

    init(container: AppContainer) {
        _viewModel = State(initialValue: HomeViewModel(container: container))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                header
                scanHero
                secondaryActions
                extrasSection
                if !viewModel.favoriteRecipes.isEmpty {
                    favoritesSection
                }
                Label(L10n.Home.privacyNote, systemImage: "lock.shield")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Theme.background)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text(viewModel.greeting)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text(L10n.Home.title)
                .font(.largeTitle.weight(.heavy))
                .fontDesign(.rounded)
                .accessibilityAddTraits(.isHeader)
            Text(L10n.Home.subtitle)
                .foregroundStyle(.secondary)
        }
        .padding(.top, Theme.Spacing.m)
    }

    private var scanHero: some View {
        Button(action: viewModel.startScan) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                HStack(alignment: .top) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 40, weight: .semibold))
                        .padding(14)
                        .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    Spacer()
                    Text(verbatim: "🥚🍅🧀\n🥒🍗🧅")
                        .font(.system(size: 26))
                        .multilineTextAlignment(.trailing)
                        .accessibilityHidden(true)
                }
                Spacer(minLength: Theme.Spacing.m)
                Text(L10n.Home.scanButton)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.leading)
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text(viewModel.scansLabel)
                }
                .font(.subheadline.weight(.medium))
                .opacity(0.9)
            }
            .foregroundStyle(.white)
            .padding(Theme.Spacing.l)
            .frame(maxWidth: .infinity, minHeight: 210, alignment: .leading)
            .background(Theme.ctaGradient, in: RoundedRectangle(cornerRadius: Theme.Radius.hero, style: .continuous))
            .shadow(color: Color(red: 0.85, green: 0.28, blue: 0.10).opacity(0.35), radius: 20, y: 10)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(L10n.Home.scanButton)
        .accessibilityValue(viewModel.scansLabel)
        .accessibilityIdentifier("home.scanButton")
    }

    private var secondaryActions: some View {
        VStack(spacing: Theme.Spacing.s) {
            Button(action: viewModel.addManually) {
                Label(L10n.Home.addManually, systemImage: "plus")
            }
            .buttonStyle(.secondary)
            .accessibilityIdentifier("home.addManuallyButton")

            if viewModel.pantryCount > 0 {
                HomeRow(
                    icon: "refrigerator",
                    title: L10n.Home.cookFromPantry,
                    subtitle: L10n.Home.pantryCount(viewModel.pantryCount),
                    action: viewModel.cookFromPantry
                )
                .accessibilityIdentifier("home.cookFromPantryButton")
            }
        }
    }

    private var extrasSection: some View {
        VStack(spacing: Theme.Spacing.s) {
            HomeRow(
                icon: "calendar",
                title: L10n.WeeklyMenu.title,
                subtitle: L10n.WeeklyMenu.subtitle,
                isLocked: !viewModel.isPremium,
                action: viewModel.openWeeklyMenu
            )
            .accessibilityIdentifier("home.weeklyMenuButton")

            if viewModel.hasHistory {
                HomeRow(
                    icon: "clock.arrow.circlepath",
                    title: L10n.History.title,
                    subtitle: L10n.History.subtitle,
                    isLocked: !viewModel.isPremium,
                    action: viewModel.openHistory
                )
            }
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            SectionHeader(title: L10n.Home.favoriteRecipes)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.s) {
                    ForEach(viewModel.favoriteRecipes) { recipe in
                        NavigationLink(value: AppRoute.recipeDetail(viewModel.match(for: recipe))) {
                            FavoriteMiniCard(recipe: recipe)
                        }
                        .buttonStyle(.pressable)
                    }
                }
            }
            .scrollClipDisabled()
        }
    }
}

/// Строка-кнопка на главной (иконка, заголовок, подзаголовок, замок для PRO).
struct HomeRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var isLocked = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 44, height: 44)
                    .background(Theme.accent.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title).font(.headline)
                        if isLocked { ProBadge() }
                    }
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(Color.primary)
            .cardStyle(padding: Theme.Spacing.s)
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .combine)
    }
}

private struct FavoriteMiniCard: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            RecipeArtworkView(recipe: recipe, emojiSize: 48)
                .frame(width: 168, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
            Text(recipe.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.primary)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)
            Text(L10n.Recipe.minutes(recipe.cookingTimeMinutes))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 168)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack { HomeView(container: .preview()) }
}
