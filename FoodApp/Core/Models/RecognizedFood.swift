import Foundation

/// Продукт, распознанный AI на фотографии. UI получает только эту типизированную модель, не JSON.
struct RecognizedFood: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var name: String
    var normalizedName: String
    var category: FoodCategory
    /// 0...1
    var confidence: Double
    var quantity: Double?
    var unit: String?

    func toIngredient() -> Ingredient {
        Ingredient(
            name: name,
            normalizedName: normalizedName,
            category: category,
            quantity: quantity,
            unit: unit,
            confidence: confidence
        )
    }
}
