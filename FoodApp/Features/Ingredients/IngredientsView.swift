import SwiftUI

/// Экран подтверждения продуктов. AI может ошибаться — поэтому список всегда редактируемый.
struct IngredientsView: View {
    @Bindable var viewModel: IngredientsViewModel
    var thumbnail: UIImage?

    var body: some View {
        List {
            Section {
                header
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
            }

            if viewModel.ingredients.isEmpty {
                Section {
                    EmptyStateView(
                        title: L10n.Ingredients.emptyTitle,
                        message: L10n.Ingredients.emptyMessage,
                        systemImage: "basket",
                        primaryTitle: L10n.Ingredients.addProduct,
                        primaryAction: { viewModel.isAddSheetPresented = true }
                    )
                    .listRowBackground(Color.clear)
                }
            } else {
                Section {
                    ForEach(viewModel.ingredients) { ingredient in
                        IngredientRow(
                            ingredient: ingredient,
                            onIncrement: { viewModel.increment(ingredient.id) },
                            onDecrement: { viewModel.decrement(ingredient.id) },
                            onDelete: { withAnimation { viewModel.remove(ingredient.id) } },
                            onRename: { viewModel.beginRename(ingredient) }
                        )
                        .accessibilityIdentifier("ingredients.row.\(ingredient.normalizedName)")
                    }
                    .onDelete { offsets in viewModel.remove(atOffsets: offsets) }

                    Button {
                        viewModel.isAddSheetPresented = true
                    } label: {
                        Label(L10n.Ingredients.addProduct, systemImage: "plus.circle.fill")
                            .font(.body.weight(.semibold))
                            .frame(minHeight: 44)
                    }
                    .accessibilityIdentifier("ingredients.addButton")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .animation(.snappy, value: viewModel.ingredients)
        .safeAreaInset(edge: .bottom) {
            Button(action: viewModel.showRecipes) {
                Label(L10n.Ingredients.showRecipes, systemImage: "fork.knife")
            }
            .buttonStyle(.primaryLarge)
            .disabled(!viewModel.canShowRecipes)
            .padding(.horizontal, 20)
            .padding(.vertical, Theme.Spacing.s)
            .background(.bar)
            .accessibilityIdentifier("ingredients.showRecipesButton")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(L10n.Ingredients.saveToPantry, systemImage: "refrigerator", action: viewModel.saveToPantry)
                        .disabled(viewModel.ingredients.isEmpty)
                    Button(L10n.Ingredients.addProduct, systemImage: "plus") { viewModel.isAddSheetPresented = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel(L10n.Ingredients.saveToPantry)
                }
            }
        }
        .sheet(isPresented: $viewModel.isAddSheetPresented) {
            AddIngredientSheet(existingKeys: Set(viewModel.ingredients.map(\.normalizedName))) { ingredient in
                viewModel.add(ingredient)
            }
        }
        .alert(L10n.Ingredients.rename, isPresented: $viewModel.isRenaming) {
            TextField(L10n.Ingredients.renamePlaceholder, text: $viewModel.renameText)
            Button(L10n.Common.save, action: viewModel.commitRename)
            Button(L10n.Common.cancel, role: .cancel) {}
        }
        .toast($viewModel.toast)
        .sensoryFeedback(.selection, trigger: viewModel.ingredients.count)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.m) {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(viewModel.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.primary)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("ingredients.title")
                HStack(alignment: .top, spacing: 6) {
                    if viewModel.mode == .recognized {
                        Image(systemName: "sparkles").foregroundStyle(Theme.accent)
                    }
                    Text(viewModel.subtitle)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .textCase(nil)
        .padding(.top, Theme.Spacing.xs)
    }
}

/// Экран ручного ввода продуктов (маршрут `.ingredients`).
struct ManualIngredientsView: View {
    @State private var viewModel: IngredientsViewModel

    init(container: AppContainer, initial: [Ingredient]) {
        _viewModel = State(initialValue: IngredientsViewModel(container: container, mode: .manual, initial: initial))
    }

    var body: some View {
        IngredientsView(viewModel: viewModel)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // Пустой ручной список — сразу открываем добавление.
                if viewModel.ingredients.isEmpty { viewModel.isAddSheetPresented = true }
            }
    }
}
