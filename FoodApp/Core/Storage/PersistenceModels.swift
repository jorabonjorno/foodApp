import Foundation
import SwiftData

// SwiftData-сущности. UI с ними напрямую не работает — только через Store/Repository и доменные модели.

@Model
final class PantryItemEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var normalizedName: String
    var categoryRaw: String
    var quantity: Double?
    var unit: String?
    var addedAt: Date

    init(from ingredient: Ingredient, addedAt: Date = .now) {
        id = ingredient.id
        name = ingredient.name
        normalizedName = ingredient.normalizedName
        categoryRaw = ingredient.category.rawValue
        quantity = ingredient.quantity
        unit = ingredient.unit
        self.addedAt = addedAt
    }

    func update(from ingredient: Ingredient) {
        name = ingredient.name
        normalizedName = ingredient.normalizedName
        categoryRaw = ingredient.category.rawValue
        quantity = ingredient.quantity
        unit = ingredient.unit
    }

    var ingredient: Ingredient {
        Ingredient(
            id: id,
            name: name,
            normalizedName: normalizedName,
            category: FoodCategory(rawValue: categoryRaw) ?? .other,
            quantity: quantity,
            unit: unit
        )
    }
}

@Model
final class FavoriteRecipeEntity {
    @Attribute(.unique) var recipeID: String
    /// Рецепт целиком в JSON — схема рецепта может меняться без миграций SwiftData.
    var payload: Data
    var savedAt: Date

    init(recipeID: String, payload: Data, savedAt: Date = .now) {
        self.recipeID = recipeID
        self.payload = payload
        self.savedAt = savedAt
    }
}

/// История сканирований. Фото НЕ сохраняется — только итоговый список продуктов.
@Model
final class ScanHistoryEntity {
    @Attribute(.unique) var id: UUID
    var date: Date
    var payload: Data

    init(id: UUID = UUID(), date: Date = .now, payload: Data) {
        self.id = id
        self.date = date
        self.payload = payload
    }
}

/// Пункт списка покупок (локально, без интеграции с магазинами).
@Model
final class ShoppingItemEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var normalizedName: String
    var amount: String?
    var recipeTitle: String?
    var isChecked: Bool
    var addedAt: Date

    init(item: ShoppingItem) {
        id = item.id
        name = item.name
        normalizedName = item.normalizedName
        amount = item.amount
        recipeTitle = item.recipeTitle
        isChecked = item.isChecked
        addedAt = item.addedAt
    }

    var item: ShoppingItem {
        ShoppingItem(id: id, name: name, normalizedName: normalizedName, amount: amount,
                     recipeTitle: recipeTitle, isChecked: isChecked, addedAt: addedAt)
    }
}

enum PersistenceSchema {
    static let models: [any PersistentModel.Type] = [
        PantryItemEntity.self,
        FavoriteRecipeEntity.self,
        ScanHistoryEntity.self,
        ShoppingItemEntity.self,
    ]

    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema(models)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Повреждённое хранилище не должно ронять приложение: работаем в памяти.
            let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            // swiftlint:disable:next force_try
            return try! ModelContainer(for: schema, configurations: [memory])
        }
    }
}
