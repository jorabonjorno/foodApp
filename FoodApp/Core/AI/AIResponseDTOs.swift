import Foundation

// DTO — «сырой» формат ответа backend/AI (только распознавание продуктов; рецепты AI не генерирует). Все поля опциональные и терпимые к ошибкам;
// в доменные модели преобразуются только после валидации.

struct FoodRecognitionResponseDTO: Decodable {
    var foods: LossyArray<FoodDTO>

    enum CodingKeys: String, CodingKey { case foods }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        foods = (try? container.decode(LossyArray<FoodDTO>.self, forKey: .foods)) ?? LossyArray()
    }
}

struct FoodDTO: Decodable {
    var name: String
    var normalizedName: String?
    var category: FoodCategory?
    var confidence: Double?
    var quantity: Double?
    var unit: String?

    enum CodingKeys: String, CodingKey {
        case name, normalizedName, category, confidence, quantity, unit
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard let name = c.nonEmptyString(forKey: .name) else {
            throw DecodingError.dataCorruptedError(forKey: .name, in: c, debugDescription: "Empty food name")
        }
        self.name = name
        normalizedName = c.nonEmptyString(forKey: .normalizedName)
        category = try? c.decodeIfPresent(FoodCategory.self, forKey: .category)
        confidence = c.flexibleDouble(forKey: .confidence)
        quantity = c.flexibleDouble(forKey: .quantity)
        unit = c.nonEmptyString(forKey: .unit)
    }

    func toDomain(normalizer: IngredientNormalizer) -> RecognizedFood {
        let key = normalizer.normalize(name: name, suggestedKey: normalizedName)
        let entry = FoodDictionary.entry(for: key)
        let validQuantity = quantity.flatMap { $0 > 0 && $0 < 100_000 ? $0 : nil }
        return RecognizedFood(
            name: name.prefix(1).uppercased() + name.dropFirst(),
            normalizedName: key,
            category: category ?? entry?.category ?? .other,
            confidence: min(max(confidence ?? 0.5, 0), 1),
            quantity: validQuantity,
            unit: validQuantity == nil ? nil : unit
        )
    }
}
