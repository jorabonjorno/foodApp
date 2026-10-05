import Foundation
import Observation

// Observable-хранилища: единый источник правды для экранов. Изменения сразу видны во всех вкладках.

@MainActor
@Observable
final class PantryStore {
    private(set) var items: [Ingredient] = []
    @ObservationIgnored private let repository: PantryRepository

    init(repository: PantryRepository) {
        self.repository = repository
        items = repository.fetchAll()
    }

    var isEmpty: Bool { items.isEmpty }

    /// Добавляет продукты; если такой продукт уже есть — обновляет количество.
    func add(_ ingredients: [Ingredient]) {
        for ingredient in ingredients {
            if let index = items.firstIndex(where: { $0.normalizedName == ingredient.normalizedName }) {
                var existing = items[index]
                if ingredient.quantity != nil {
                    existing.quantity = ingredient.quantity
                    existing.unit = ingredient.unit
                }
                items[index] = existing
                repository.upsert(existing)
            } else {
                var copy = ingredient
                copy.confidence = nil
                items.insert(copy, at: 0)
                repository.upsert(copy)
            }
        }
    }

    func update(_ ingredient: Ingredient) {
        guard let index = items.firstIndex(where: { $0.id == ingredient.id }) else { return }
        items[index] = ingredient
        repository.upsert(ingredient)
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
        repository.delete(id: id)
    }

    func removeAll() {
        items.removeAll()
        repository.deleteAll()
    }
}

@MainActor
@Observable
final class FavoritesStore {
    private(set) var recipes: [Recipe] = []
    @ObservationIgnored private let repository: FavoritesRepository

    init(repository: FavoritesRepository) {
        self.repository = repository
        recipes = repository.fetchAll()
    }

    func isFavorite(_ recipe: Recipe) -> Bool {
        recipes.contains { $0.id == recipe.id }
    }

    /// Возвращает новое состояние (true — добавлен).
    @discardableResult
    func toggle(_ recipe: Recipe) -> Bool {
        if isFavorite(recipe) {
            recipes.removeAll { $0.id == recipe.id }
            repository.delete(recipeID: recipe.id)
            return false
        } else {
            recipes.insert(recipe, at: 0)
            repository.save(recipe)
            return true
        }
    }
}

@MainActor
@Observable
final class ScanHistoryStore {
    private(set) var records: [ScanRecord] = []
    @ObservationIgnored private let repository: ScanHistoryRepository

    init(repository: ScanHistoryRepository) {
        self.repository = repository
        records = repository.fetchRecent(limit: 10)
    }

    func add(_ ingredients: [Ingredient]) {
        repository.add(ingredients)
        records = repository.fetchRecent(limit: 10)
    }

    /// Уникальные продукты из последних сканирований (для блока «Недавние продукты»).
    var recentIngredients: [Ingredient] {
        var seen = Set<String>()
        var result: [Ingredient] = []
        for record in records {
            for ingredient in record.ingredients where !seen.contains(ingredient.normalizedName) {
                seen.insert(ingredient.normalizedName)
                result.append(ingredient)
            }
        }
        return result
    }
}

@MainActor
@Observable
final class FiltersStore {
    var filters: RecipeFilters {
        didSet { storage.save(filters) }
    }

    @ObservationIgnored private let storage: FiltersStorage

    init(storage: FiltersStorage) {
        self.storage = storage
        filters = storage.load()
    }
}

@MainActor
@Observable
final class ShoppingListStore {
    private(set) var items: [ShoppingItem] = []
    @ObservationIgnored private let repository: ShoppingListRepository

    init(repository: ShoppingListRepository) {
        self.repository = repository
        items = repository.fetchAll()
    }

    var uncheckedCount: Int { items.filter { !$0.isChecked }.count }

    func contains(_ normalizedName: String) -> Bool {
        items.contains { $0.normalizedName == normalizedName && !$0.isChecked }
    }

    /// Добавляет недостающие ингредиенты рецепта (без дублей). Возвращает количество добавленных.
    @discardableResult
    func add(_ ingredients: [RecipeIngredient], from recipe: Recipe?) -> Int {
        var added = 0
        for ingredient in ingredients where !contains(ingredient.normalizedName) {
            let item = ShoppingItem(
                name: ingredient.name,
                normalizedName: ingredient.normalizedName,
                amount: ingredient.formattedAmount,
                recipeTitle: recipe?.title
            )
            items.insert(item, at: 0)
            repository.upsert(item)
            added += 1
        }
        return added
    }

    func toggle(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isChecked.toggle()
        repository.upsert(items[index])
    }

    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
        repository.delete(ids: [id])
    }

    /// Удаляет купленное и возвращает его (чтобы перенести в «Мои продукты»).
    func removeChecked() -> [ShoppingItem] {
        let checked = items.filter(\.isChecked)
        items.removeAll(where: \.isChecked)
        repository.delete(ids: checked.map(\.id))
        return checked
    }
}
