import Foundation
import Observation

/// Группы для «Моих продуктов».
enum PantrySection: CaseIterable, Identifiable {
    case fridge, produce, other

    var id: Self { self }

    var title: String {
        switch self {
        case .fridge: L10n.Pantry.fridge
        case .produce: L10n.Pantry.produce
        case .other: L10n.Pantry.other
        }
    }

    static func section(for category: FoodCategory) -> PantrySection {
        switch category {
        case .meat, .fish, .dairy, .eggs, .sauces, .drinks: .fridge
        case .vegetables, .fruits: .produce
        default: .other
        }
    }
}

@MainActor
@Observable
final class PantryViewModel {
    enum Segment: Hashable { case pantry, shopping }

    var segment: Segment = .pantry
    var isAddSheetPresented = false
    var isClearConfirmPresented = false
    var toast: String?
    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    // MARK: - Pantry

    var items: [Ingredient] { container.pantry.items }
    var isEmpty: Bool { items.isEmpty }

    struct SectionGroup: Identifiable {
        let section: PantrySection
        let items: [Ingredient]
        var id: PantrySection { section }
    }

    var sections: [SectionGroup] {
        PantrySection.allCases.compactMap { section -> SectionGroup? in
            let sectionItems = items
                .filter { PantrySection.section(for: $0.category) == section }
                .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
            return sectionItems.isEmpty ? nil : SectionGroup(section: section, items: sectionItems)
        }
    }

    var existingKeys: Set<String> { Set(items.map(\.normalizedName)) }

    func add(_ ingredient: Ingredient) { container.pantry.add([ingredient]) }
    func remove(_ id: UUID) { container.pantry.remove(id: id) }
    func removeAll() { container.pantry.removeAll() }

    func increment(_ ingredient: Ingredient) {
        var copy = ingredient
        copy.incrementQuantity()
        container.pantry.update(copy)
    }

    func decrement(_ ingredient: Ingredient) {
        var copy = ingredient
        copy.decrementQuantity()
        container.pantry.update(copy)
    }

    func cook() {
        guard !items.isEmpty else { return }
        container.router.push(.recipes(items))
    }

    func scan() {
        container.router.selectedTab = .home
        container.requirePremium(.scan, reason: .scansExhausted) {
            container.router.homePath = [.capture]
        }
    }

    // MARK: - Shopping list (PRO)

    var canUseShoppingList: Bool { container.entitlements.canUse(feature: .shoppingList) }
    var shoppingItems: [ShoppingItem] { container.shoppingList.items }
    var hasChecked: Bool { shoppingItems.contains(where: \.isChecked) }

    func toggle(_ item: ShoppingItem) { container.shoppingList.toggle(item.id) }
    func removeShopping(_ item: ShoppingItem) { container.shoppingList.remove(item.id) }

    /// Купленное → в «Мои продукты».
    func moveCheckedToPantry() {
        let bought = container.shoppingList.removeChecked()
        let ingredients = bought.map { item in
            Ingredient(
                name: item.name,
                normalizedName: item.normalizedName,
                category: FoodDictionary.entry(for: item.normalizedName)?.category ?? .other,
                unit: FoodDictionary.entry(for: item.normalizedName)?.defaultUnit
            )
        }
        container.pantry.add(ingredients)
        toast = L10n.ShoppingList.movedToPantry(ingredients.count)
    }

    func unlockShoppingList() {
        container.router.presentPaywall(.feature)
    }
}
