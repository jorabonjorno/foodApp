import SwiftUI

struct PantryView: View {
    @State private var viewModel: PantryViewModel

    init(container: AppContainer) {
        _viewModel = State(initialValue: PantryViewModel(container: container))
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $viewModel.segment) {
                Text(L10n.Pantry.title).tag(PantryViewModel.Segment.pantry)
                Text(L10n.ShoppingList.title).tag(PantryViewModel.Segment.shopping)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.vertical, Theme.Spacing.xs)

            switch viewModel.segment {
            case .pantry: pantry
            case .shopping: ShoppingListView(viewModel: viewModel)
            }
        }
        .background(Theme.background)
        .navigationTitle(L10n.Tab.pantry)
        .toolbar {
            if viewModel.segment == .pantry {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { viewModel.isAddSheetPresented = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(L10n.Ingredients.addProduct)
                    .accessibilityIdentifier("pantry.addButton")
                }
                if !viewModel.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Button(L10n.Pantry.clearAll, systemImage: "trash", role: .destructive) {
                                viewModel.isClearConfirmPresented = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.isAddSheetPresented) {
            AddIngredientSheet(existingKeys: viewModel.existingKeys) { viewModel.add($0) }
        }
        .confirmationDialog(L10n.Pantry.clearConfirm, isPresented: $viewModel.isClearConfirmPresented, titleVisibility: .visible) {
            Button(L10n.Pantry.clearAll, role: .destructive, action: viewModel.removeAll)
        }
        .toast($viewModel.toast)
    }

    @ViewBuilder
    private var pantry: some View {
        if viewModel.isEmpty {
            EmptyStateView(
                title: L10n.Pantry.emptyTitle,
                message: L10n.Pantry.emptyMessage,
                systemImage: "refrigerator",
                primaryTitle: L10n.Home.scanButton,
                primaryAction: viewModel.scan,
                secondaryTitle: L10n.Home.addManually,
                secondaryAction: { viewModel.isAddSheetPresented = true }
            )
            .frame(maxHeight: .infinity)
        } else {
            List {
                ForEach(viewModel.sections) { group in
                    Section(group.section.title) {
                        ForEach(group.items) { ingredient in
                            IngredientRow(
                                ingredient: ingredient,
                                onIncrement: { viewModel.increment(ingredient) },
                                onDecrement: { viewModel.decrement(ingredient) },
                                onDelete: { withAnimation { viewModel.remove(ingredient.id) } }
                            )
                        }
                        .onDelete { offsets in
                            for index in offsets { viewModel.remove(group.items[index].id) }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .safeAreaInset(edge: .bottom) {
                Button(action: viewModel.cook) {
                    Label(L10n.Pantry.whatToCook, systemImage: "fork.knife")
                }
                .buttonStyle(.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, Theme.Spacing.s)
                .background(.bar)
                .accessibilityIdentifier("pantry.cookButton")
            }
        }
    }
}

/// Список покупок (PRO). Купленное можно одной кнопкой перенести в «Мои продукты».
struct ShoppingListView: View {
    @Bindable var viewModel: PantryViewModel

    var body: some View {
        if !viewModel.canUseShoppingList {
            EmptyStateView(
                title: L10n.ShoppingList.lockedTitle,
                message: L10n.ShoppingList.lockedMessage,
                systemImage: "cart",
                primaryTitle: L10n.Paywall.unlock,
                primaryAction: viewModel.unlockShoppingList
            )
            .frame(maxHeight: .infinity)
        } else if viewModel.shoppingItems.isEmpty {
            EmptyStateView(
                title: L10n.ShoppingList.emptyTitle,
                message: L10n.ShoppingList.emptyMessage,
                systemImage: "cart"
            )
            .frame(maxHeight: .infinity)
        } else {
            List {
                ForEach(viewModel.shoppingItems) { item in
                    Button { viewModel.toggle(item) } label: {
                        HStack(spacing: Theme.Spacing.s) {
                            Image(systemName: item.isChecked ? "checkmark.square.fill" : "square")
                                .font(.title3)
                                .foregroundStyle(item.isChecked ? Theme.success : Color.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .strikethrough(item.isChecked)
                                    .foregroundStyle(item.isChecked ? Color.secondary : Color.primary)
                                if let title = item.recipeTitle {
                                    Text(title).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if let amount = item.amount {
                                Text(amount).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        .frame(minHeight: 44)
                    }
                    .accessibilityAddTraits(item.isChecked ? .isSelected : [])
                }
                .onDelete { offsets in
                    for index in offsets { viewModel.removeShopping(viewModel.shoppingItems[index]) }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .safeAreaInset(edge: .bottom) {
                if viewModel.hasChecked {
                    Button(action: viewModel.moveCheckedToPantry) {
                        Label(L10n.ShoppingList.moveToPantry, systemImage: "refrigerator")
                    }
                    .buttonStyle(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, Theme.Spacing.s)
                    .background(.bar)
                }
            }
        }
    }
}
