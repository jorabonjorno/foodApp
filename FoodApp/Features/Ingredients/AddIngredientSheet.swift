import SwiftUI

/// Добавление продукта: поиск по справочнику + произвольное название.
struct AddIngredientSheet: View {
    /// Уже добавленные ключи — отмечаются галочкой.
    var existingKeys: Set<String>
    var onAdd: (Ingredient) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var addedKeys: Set<String> = []
    @State private var toast: String?

    private var suggestions: [FoodDictionaryEntry] { FoodDictionary.suggestions(matching: query) }

    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var showsCustomRow: Bool {
        !trimmedQuery.isEmpty
            && !suggestions.contains { IngredientNormalizer.clean($0.displayName) == IngredientNormalizer.clean(trimmedQuery) }
    }

    var body: some View {
        NavigationStack {
            List {
                if showsCustomRow {
                    Section {
                        Button(action: addCustom) {
                            Label(L10n.AddIngredient.addCustom(trimmedQuery), systemImage: "plus.circle.fill")
                                .font(.body.weight(.semibold))
                        }
                        .accessibilityIdentifier("addIngredient.customButton")
                    }
                }

                Section(query.isEmpty ? L10n.AddIngredient.popular : L10n.AddIngredient.suggestions) {
                    ForEach(suggestions, id: \.key) { entry in
                        let isAdded = existingKeys.contains(entry.key) || addedKeys.contains(entry.key)
                        Button {
                            add(Ingredient(entry: entry))
                        } label: {
                            HStack(spacing: Theme.Spacing.s) {
                                FoodIconView(emoji: entry.emoji, size: 38)
                                Text(entry.displayName)
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle")
                                    .font(.title3)
                                    .foregroundStyle(isAdded ? Theme.success : Theme.accent)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                        }
                        .disabled(isAdded)
                        .accessibilityLabel(entry.displayName)
                        .accessibilityAddTraits(isAdded ? .isSelected : [])
                    }
                }
            }
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: L10n.AddIngredient.placeholder
            )
            .onSubmit(of: .search) {
                if showsCustomRow { addCustom() } else if let first = suggestions.first { add(Ingredient(entry: first)) }
            }
            .navigationTitle(L10n.AddIngredient.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.done) { dismiss() }
                        .accessibilityIdentifier("addIngredient.doneButton")
                }
            }
            .toast($toast)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func addCustom() {
        guard let ingredient = Ingredient.make(fromUserInput: trimmedQuery) else { return }
        add(ingredient)
        query = ""
    }

    private func add(_ ingredient: Ingredient) {
        onAdd(ingredient)
        addedKeys.insert(ingredient.normalizedName)
        toast = L10n.AddIngredient.added(ingredient.name)
    }
}
