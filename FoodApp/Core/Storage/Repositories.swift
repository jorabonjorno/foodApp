import Foundation
import SwiftData

// Протоколы репозиториев позволяют позже заменить локальное хранение на синхронизацию с аккаунтом.

@MainActor
protocol PantryRepository {
    func fetchAll() -> [Ingredient]
    func upsert(_ ingredient: Ingredient)
    func delete(id: UUID)
    func deleteAll()
}

@MainActor
protocol FavoritesRepository {
    func fetchAll() -> [Recipe]
    func save(_ recipe: Recipe)
    func delete(recipeID: String)
}

struct ScanRecord: Identifiable, Hashable, Sendable {
    let id: UUID
    let date: Date
    let ingredients: [Ingredient]
}

@MainActor
protocol ScanHistoryRepository {
    func fetchRecent(limit: Int) -> [ScanRecord]
    func add(_ ingredients: [Ingredient])
}

struct ShoppingItem: Identifiable, Hashable, Sendable {
    var id = UUID()
    var name: String
    var normalizedName: String
    var amount: String?
    var recipeTitle: String?
    var isChecked = false
    var addedAt = Date()
}

@MainActor
protocol ShoppingListRepository {
    func fetchAll() -> [ShoppingItem]
    func upsert(_ item: ShoppingItem)
    func delete(ids: [UUID])
}

// MARK: - SwiftData implementations

@MainActor
final class SwiftDataPantryRepository: PantryRepository {
    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    func fetchAll() -> [Ingredient] {
        let descriptor = FetchDescriptor<PantryItemEntity>(sortBy: [SortDescriptor(\.addedAt, order: .reverse)])
        return ((try? context.fetch(descriptor)) ?? []).map(\.ingredient)
    }

    func upsert(_ ingredient: Ingredient) {
        let id = ingredient.id
        let descriptor = FetchDescriptor<PantryItemEntity>(predicate: #Predicate { $0.id == id })
        if let existing = try? context.fetch(descriptor).first {
            existing.update(from: ingredient)
        } else {
            context.insert(PantryItemEntity(from: ingredient))
        }
        try? context.save()
    }

    func delete(id: UUID) {
        let descriptor = FetchDescriptor<PantryItemEntity>(predicate: #Predicate { $0.id == id })
        for item in (try? context.fetch(descriptor)) ?? [] { context.delete(item) }
        try? context.save()
    }

    func deleteAll() {
        try? context.delete(model: PantryItemEntity.self)
        try? context.save()
    }
}

@MainActor
final class SwiftDataFavoritesRepository: FavoritesRepository {
    private let context: ModelContext
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(context: ModelContext) { self.context = context }

    func fetchAll() -> [Recipe] {
        let descriptor = FetchDescriptor<FavoriteRecipeEntity>(sortBy: [SortDescriptor(\.savedAt, order: .reverse)])
        return ((try? context.fetch(descriptor)) ?? []).compactMap { try? decoder.decode(Recipe.self, from: $0.payload) }
    }

    func save(_ recipe: Recipe) {
        guard let payload = try? encoder.encode(recipe) else { return }
        let id = recipe.id
        let descriptor = FetchDescriptor<FavoriteRecipeEntity>(predicate: #Predicate { $0.recipeID == id })
        if let existing = try? context.fetch(descriptor).first {
            existing.payload = payload
        } else {
            context.insert(FavoriteRecipeEntity(recipeID: id, payload: payload))
        }
        try? context.save()
    }

    func delete(recipeID: String) {
        let descriptor = FetchDescriptor<FavoriteRecipeEntity>(predicate: #Predicate { $0.recipeID == recipeID })
        for item in (try? context.fetch(descriptor)) ?? [] { context.delete(item) }
        try? context.save()
    }
}

@MainActor
final class SwiftDataScanHistoryRepository: ScanHistoryRepository {
    private let context: ModelContext
    private let maxStored = 20

    init(context: ModelContext) { self.context = context }

    func fetchRecent(limit: Int) -> [ScanRecord] {
        var descriptor = FetchDescriptor<ScanHistoryEntity>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = limit
        return ((try? context.fetch(descriptor)) ?? []).compactMap { entity in
            guard let ingredients = try? JSONDecoder().decode([Ingredient].self, from: entity.payload) else { return nil }
            return ScanRecord(id: entity.id, date: entity.date, ingredients: ingredients)
        }
    }

    func add(_ ingredients: [Ingredient]) {
        guard !ingredients.isEmpty, let payload = try? JSONEncoder().encode(ingredients) else { return }
        context.insert(ScanHistoryEntity(payload: payload))

        // Храним только последние N записей.
        let descriptor = FetchDescriptor<ScanHistoryEntity>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let all = (try? context.fetch(descriptor)) ?? []
        for entity in all.dropFirst(maxStored) { context.delete(entity) }
        try? context.save()
    }
}

@MainActor
final class SwiftDataShoppingListRepository: ShoppingListRepository {
    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    func fetchAll() -> [ShoppingItem] {
        let descriptor = FetchDescriptor<ShoppingItemEntity>(sortBy: [SortDescriptor(\.addedAt, order: .reverse)])
        return ((try? context.fetch(descriptor)) ?? []).map(\.item)
    }

    func upsert(_ item: ShoppingItem) {
        let id = item.id
        let descriptor = FetchDescriptor<ShoppingItemEntity>(predicate: #Predicate { $0.id == id })
        if let existing = try? context.fetch(descriptor).first {
            existing.isChecked = item.isChecked
            existing.amount = item.amount
            existing.name = item.name
        } else {
            context.insert(ShoppingItemEntity(item: item))
        }
        try? context.save()
    }

    func delete(ids: [UUID]) {
        for id in ids {
            let descriptor = FetchDescriptor<ShoppingItemEntity>(predicate: #Predicate { $0.id == id })
            for entity in (try? context.fetch(descriptor)) ?? [] { context.delete(entity) }
        }
        try? context.save()
    }
}

// MARK: - Filters

/// Последние выбранные фильтры (UserDefaults, Codable JSON).
@MainActor
final class FiltersStorage {
    private let defaults: UserDefaults
    private let key = "recipe_filters.v1"

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func load() -> RecipeFilters {
        guard let data = defaults.data(forKey: key),
              let filters = try? JSONDecoder().decode(RecipeFilters.self, from: data)
        else { return .default }
        return filters
    }

    func save(_ filters: RecipeFilters) {
        guard let data = try? JSONEncoder().encode(filters) else { return }
        defaults.set(data, forKey: key)
    }
}
