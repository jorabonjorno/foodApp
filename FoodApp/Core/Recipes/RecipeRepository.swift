import Foundation
import OSLog

/// Источник рецептов. Сейчас — локальная база в бандле; позже можно заменить на загрузку обновлений с CDN.
protocol RecipeRepository: Sendable {
    func allRecipes() async -> [Recipe]
}

/// Рецепты из `recipes.json` в бандле приложения. Загружаются один раз в фоне и кэшируются.
actor BundledRecipeRepository: RecipeRepository {
    private let bundle: Bundle
    private let fileName: String
    private var cache: [Recipe]?

    init(bundle: Bundle = .main, fileName: String = "recipes") {
        self.bundle = bundle
        self.fileName = fileName
    }

    func allRecipes() async -> [Recipe] {
        if let cache { return cache }
        let recipes = Self.load(bundle: bundle, fileName: fileName)
        cache = recipes
        return recipes
    }

    static func load(bundle: Bundle, fileName: String) -> [Recipe] {
        guard let url = bundle.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else {
            Logger(subsystem: "FoodApp", category: "recipes").error("recipes.json not found in bundle")
            return []
        }
        do {
            // Битый рецепт не должен ломать всю базу.
            return try JSONDecoder().decode(LossyArray<Recipe>.self, from: data).elements
        } catch {
            Logger(subsystem: "FoodApp", category: "recipes").error("recipes.json decode failed: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }
}
