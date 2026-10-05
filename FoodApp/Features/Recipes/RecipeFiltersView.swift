import SwiftUI

/// Фильтры. Free: время, сложность, «только из того, что есть». PRO: тип блюда, порции, ингредиенты.
struct RecipeFiltersView: View {
    let ingredients: [Ingredient]
    let canUseAdvanced: Bool
    let onApply: (RecipeFilters) -> Void
    let onUnlock: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: RecipeFilters
    @State private var excludeText = ""

    init(
        initial: RecipeFilters,
        ingredients: [Ingredient],
        canUseAdvanced: Bool,
        onApply: @escaping (RecipeFilters) -> Void,
        onUnlock: @escaping () -> Void
    ) {
        self.ingredients = ingredients
        self.canUseAdvanced = canUseAdvanced
        self.onApply = onApply
        self.onUnlock = onUnlock
        _draft = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    basicSection
                    advancedSection
                }
                .padding(20)
            }
            .background(Theme.background)
            .navigationTitle(L10n.Filters.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(L10n.Common.reset) { draft = .default }
                        .disabled(draft.isDefault)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(L10n.Filters.apply) {
                    onApply(draft)
                    dismiss()
                }
                .buttonStyle(.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, Theme.Spacing.s)
                .background(.bar)
                .accessibilityIdentifier("filters.applyButton")
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Free

    private var basicSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            section(L10n.Filters.time) {
                ForEach(RecipeFilters.timeOptions, id: \.self) { option in
                    ChipView(
                        title: option.map(L10n.Filters.upTo) ?? L10n.Filters.anyTime,
                        isSelected: draft.maxCookingTime == option
                    ) { draft.maxCookingTime = option }
                }
            }

            section(L10n.Filters.difficulty) {
                ChipView(title: L10n.Common.any, isSelected: draft.difficulty == nil) { draft.difficulty = nil }
                ForEach(Difficulty.allCases) { value in
                    ChipView(title: value.title, isSelected: draft.difficulty == value) { draft.difficulty = value }
                }
            }

            Toggle(isOn: Binding(
                get: { draft.allowMissingIngredients },
                set: { draft.allowMissingIngredients = $0 }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Filters.allowMissing).font(.headline)
                    Text(L10n.Filters.allowMissingHint).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .tint(Theme.accent)
            .cardStyle()
        }
    }

    // MARK: - PRO

    @ViewBuilder
    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            HStack(spacing: 6) {
                Text(L10n.Filters.advanced).font(.title3.weight(.bold))
                if !canUseAdvanced { ProBadge() }
            }

            Group {
                section(L10n.Filters.mealType) {
                    ChipView(title: L10n.Common.any, isSelected: draft.mealType == nil) { draft.mealType = nil }
                    ForEach(MealType.allCases) { value in
                        ChipView(title: value.title, isSelected: draft.mealType == value) { draft.mealType = value }
                    }
                }

                section(L10n.Filters.servings) {
                    ChipView(title: L10n.Common.any, isSelected: draft.servings == nil) { draft.servings = nil }
                    ForEach(ServingsRange.allCases) { value in
                        ChipView(title: value.title, isSelected: draft.servings == value) { draft.servings = value }
                    }
                }

                if !ingredients.isEmpty {
                    section(L10n.Filters.mustInclude) {
                        ForEach(ingredients) { ingredient in
                            ChipView(
                                title: ingredient.name,
                                isSelected: draft.requiredIngredients.contains(ingredient.normalizedName)
                            ) { draft.toggleRequired(ingredient.normalizedName) }
                        }
                    }
                }

                excludeSection
            }
            .disabled(!canUseAdvanced)
            .opacity(canUseAdvanced ? 1 : 0.45)
            .overlay {
                if !canUseAdvanced {
                    Button {
                        dismiss()
                        onUnlock()
                    } label: {
                        Label(L10n.Paywall.unlock, systemImage: "lock.open.fill")
                    }
                    .buttonStyle(.primary)
                    .frame(maxWidth: 260)
                    .accessibilityIdentifier("filters.unlockButton")
                }
            }
        }
    }

    private var excludeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(L10n.Filters.exclude).font(.headline)
            HStack {
                TextField(L10n.Filters.excludePlaceholder, text: $excludeText)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .onSubmit(addExcluded)
                Button(L10n.Common.add, action: addExcluded)
                    .disabled(excludeText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            FlowLayout {
                ForEach(draft.excludedIngredients, id: \.self) { key in
                    ChipView(title: FoodDictionary.displayName(for: key), systemImage: "xmark", isSelected: true) {
                        draft.excludedIngredients.removeAll { $0 == key }
                    }
                }
            }
        }
    }

    private func addExcluded() {
        draft.addExcluded(excludeText)
        excludeText = ""
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(title).font(.headline)
            FlowLayout { content() }
        }
    }
}
