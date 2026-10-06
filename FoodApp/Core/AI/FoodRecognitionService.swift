import UIKit

/// Распознавание продуктов на фото. Приложение знает только этот протокол и `RecognizedFood` —
/// провайдер AI (Anthropic, OpenAI, Google…) выбирается на стороне прокси и может меняться без релиза.
protocol FoodRecognitionService: Sendable {
    func recognizeFoods(from image: UIImage) async throws -> [RecognizedFood]
}

/// Mock: AI не вызывается, возвращается подготовленный список. Для разработки без расходов.
struct MockFoodRecognitionService: FoodRecognitionService {
    var delay: Duration = .seconds(2)
    var normalizer: IngredientNormalizer = .shared

    func recognizeFoods(from image: UIImage) async throws -> [RecognizedFood] {
        try await Task.sleep(for: delay)
        let samples: [(String, Double, Double?, String?)] = [
            ("Куриная грудка", 0.94, 400, "г"),
            ("Помидоры", 0.97, 3, "шт"),
            ("Лук", 0.91, 2, "шт"),
            ("Сыр", 0.88, 200, "г"),
            ("Яйца", 0.96, 6, "шт"),
            ("Огурцы", 0.83, 2, "шт"),
            ("Молоко", 0.79, 1000, "мл"),
            ("Болгарский перец", 0.55, 1, "шт"),
            ("Картофель", 0.9, 5, "шт"),
            ("Морковь", 0.87, 2, "шт"),
            ("Чеснок", 0.72, 1, "головка"),
            ("Сливочное масло", 0.81, 180, "г"),
            ("Сметана", 0.68, 300, "г"),
        ]
        return samples.map { name, confidence, quantity, unit in
            let key = normalizer.normalize(name)
            return RecognizedFood(
                name: name,
                normalizedName: key,
                category: FoodDictionary.entry(for: key)?.category ?? .other,
                confidence: confidence,
                quantity: quantity,
                unit: unit
            )
        }
    }
}

/// Production: фото → минимальный прокси (`POST /recognize-foods`) → Vision AI.
/// Фото уменьшается до 1024 px и сжимается в JPEG перед отправкой; на сервере не сохраняется.
struct RealFoodRecognitionService: FoodRecognitionService {
    let client: APIClient
    var normalizer: IngredientNormalizer = .shared

    private struct RequestBody: Encodable {
        let imageBase64: String
        let mediaType: String
        let locale: String
    }

    func recognizeFoods(from image: UIImage) async throws -> [RecognizedFood] {
        guard let jpeg = await ImageProcessor.prepareForUpload(image) else { throw AppError.recognitionFailed }
        let body = RequestBody(
            imageBase64: jpeg.base64EncodedString(),
            mediaType: "image/jpeg",
            locale: Locale.current.language.languageCode?.identifier ?? "ru"
        )
        let response = try await client.post("recognize-foods", body: body, as: FoodRecognitionResponseDTO.self)
        let foods = response.foods.elements.map { $0.toDomain(normalizer: normalizer) }
        return Self.deduplicated(foods)
    }

    /// Объединяет дубликаты (AI иногда возвращает «помидор» и «томаты» отдельно).
    static func deduplicated(_ foods: [RecognizedFood]) -> [RecognizedFood] {
        var result: [RecognizedFood] = []
        for food in foods {
            if let index = result.firstIndex(where: { $0.normalizedName == food.normalizedName }) {
                if food.confidence > result[index].confidence {
                    var merged = food
                    merged.id = result[index].id
                    result[index] = merged
                }
            } else {
                result.append(food)
            }
        }
        return result
    }
}
