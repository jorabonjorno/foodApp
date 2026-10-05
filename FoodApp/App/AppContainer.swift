import Foundation
import Observation
import SwiftData

/// DI-контейнер: создаёт сервисы и хранилища и выбирает mock/production реализации.
/// Экраны получают зависимости только отсюда, поэтому замена провайдера AI не трогает UI.
@MainActor
@Observable
final class AppContainer {
    let environment: AppEnvironment
    let analytics: AnalyticsService
    let foodRecognition: FoodRecognitionService
    let recipes: RecipeRepository
    let matcher: RecipeMatchingService
    let weeklyMenu: WeeklyMenuService

    let pantry: PantryStore
    let favorites: FavoritesStore
    let history: ScanHistoryStore
    let shoppingList: ShoppingListStore
    let filters: FiltersStore

    let subscriptions: SubscriptionManager
    let quota: ScanQuota
    let entitlements: Entitlements
    let router: AppRouter

    let modelContainer: ModelContainer

    init(
        environment: AppEnvironment,
        analytics: AnalyticsService,
        foodRecognition: FoodRecognitionService,
        recipes: RecipeRepository,
        modelContainer: ModelContainer,
        quotaStorage: QuotaStorage = KeychainQuotaStorage(),
        defaults: UserDefaults = .standard
    ) {
        self.environment = environment
        self.analytics = analytics
        self.foodRecognition = foodRecognition
        self.recipes = recipes
        self.matcher = DefaultRecipeMatchingService()
        self.weeklyMenu = WeeklyMenuService()
        self.modelContainer = modelContainer

        let context = modelContainer.mainContext
        pantry = PantryStore(repository: SwiftDataPantryRepository(context: context))
        favorites = FavoritesStore(repository: SwiftDataFavoritesRepository(context: context))
        history = ScanHistoryStore(repository: SwiftDataScanHistoryRepository(context: context))
        shoppingList = ShoppingListStore(repository: SwiftDataShoppingListRepository(context: context))
        filters = FiltersStore(storage: FiltersStorage(defaults: defaults))

        subscriptions = SubscriptionManager(analytics: analytics, defaults: defaults)
        quota = ScanQuota(storage: quotaStorage)
        entitlements = Entitlements(subscriptions: subscriptions, quota: quota)
        router = AppRouter()
    }

    static func live() -> AppContainer {
        let environment = AppEnvironment.current()
        let recognition: FoodRecognitionService
        switch environment {
        case .mock:
            recognition = MockFoodRecognitionService()
        case .production(let baseURL):
            recognition = RealFoodRecognitionService(client: APIClient(baseURL: baseURL, appToken: AppEnvironment.appToken))
        }
        return AppContainer(
            environment: environment,
            analytics: LocalAnalyticsService(),
            foodRecognition: recognition,
            recipes: BundledRecipeRepository(),
            modelContainer: PersistenceSchema.makeContainer()
        )
    }

    static func preview() -> AppContainer {
        AppContainer(
            environment: .mock,
            analytics: LocalAnalyticsService(defaults: UserDefaults(suiteName: "preview") ?? .standard),
            foodRecognition: MockFoodRecognitionService(delay: .seconds(1)),
            recipes: BundledRecipeRepository(),
            modelContainer: PersistenceSchema.makeContainer(inMemory: true),
            quotaStorage: InMemoryQuotaStorage(),
            defaults: UserDefaults(suiteName: "preview") ?? .standard
        )
    }

    /// Продукты, с которыми сравниваются рецепты вне сценария сканирования:
    /// последний подтверждённый список, иначе — «Мои продукты».
    var currentIngredients: [Ingredient] {
        router.lastConfirmedIngredients.isEmpty ? pantry.items : router.lastConfirmedIngredients
    }

    func match(for recipe: Recipe) -> RecipeMatch {
        matcher.match(recipe: recipe, ingredients: currentIngredients)
    }

    /// Открыть фичу или paywall, если она платная.
    func requirePremium(_ feature: PremiumFeature, reason: PaywallReason = .feature, then action: () -> Void) {
        if entitlements.canUse(feature: feature) {
            action()
        } else {
            router.presentPaywall(reason)
        }
    }
}
