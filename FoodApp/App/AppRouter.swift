import Observation
import SwiftUI
import UIKit

/// Маршруты внутри NavigationStack любой вкладки.
enum AppRoute: Hashable {
    case capture
    /// id фото в памяти роутера; делает каждый запуск распознавания уникальным экраном.
    case recognition(UUID)
    case ingredients([Ingredient])
    case recipes([Ingredient])
    case recipeDetail(RecipeMatch)
    case weeklyMenu
    case scanHistory
}

@MainActor
@Observable
final class AppRouter {
    enum Tab: Hashable {
        case home, pantry, favorites, profile
    }

    var selectedTab: Tab = .home
    var homePath: [AppRoute] = []
    var pantryPath: [AppRoute] = []
    var favoritesPath: [AppRoute] = []
    var profilePath: [AppRoute] = []

    /// Показанный paywall (nil — скрыт).
    var paywallReason: PaywallReason?

    /// Последний подтверждённый список продуктов.
    var lastConfirmedIngredients: [Ingredient] = []

    /// Фото передаётся экрану распознавания только через память и освобождается сразу после распознавания.
    @ObservationIgnored private var photos: [UUID: UIImage] = [:]

    func push(_ route: AppRoute) {
        switch selectedTab {
        case .home: homePath.append(route)
        case .pantry: pantryPath.append(route)
        case .favorites: favoritesPath.append(route)
        case .profile: profilePath.append(route)
        }
    }

    func presentPaywall(_ reason: PaywallReason) {
        paywallReason = reason
    }

    func startRecognition(with photo: UIImage) {
        let id = UUID()
        photos = [id: photo]   // одновременно храним не больше одного фото
        push(.recognition(id))
    }

    func photo(for id: UUID) -> UIImage? { photos[id] }

    func releasePhoto(_ id: UUID) { photos[id] = nil }
}

/// Общие navigationDestination для всех вкладок.
struct AppDestinationView: View {
    let route: AppRoute
    let container: AppContainer

    var body: some View {
        switch route {
        case .capture:
            CameraView(container: container)
        case .recognition(let photoID):
            FoodRecognitionView(container: container, photoID: photoID)
        case .ingredients(let initial):
            ManualIngredientsView(container: container, initial: initial)
        case .recipes(let ingredients):
            RecipesView(container: container, ingredients: ingredients)
        case .recipeDetail(let match):
            RecipeDetailView(container: container, match: match)
        case .weeklyMenu:
            WeeklyMenuView(container: container)
        case .scanHistory:
            ScanHistoryView(container: container)
        }
    }
}

extension View {
    func appDestinations(container: AppContainer) -> some View {
        navigationDestination(for: AppRoute.self) { route in
            AppDestinationView(route: route, container: container)
        }
    }
}
