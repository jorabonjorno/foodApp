import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: L10n.Home.greetingMorning
        case 12..<18: L10n.Home.greetingDay
        default: L10n.Home.greetingEvening
        }
    }

    var favoriteRecipes: [Recipe] { Array(container.favorites.recipes.prefix(8)) }
    var pantryCount: Int { container.pantry.items.count }
    var isPremium: Bool { container.entitlements.isPremium }
    var scansRemaining: Int { container.entitlements.scansRemaining }
    var scansLimit: Int { container.entitlements.scansLimit }
    var hasHistory: Bool { !container.history.records.isEmpty }

    var scansLabel: String { L10n.Home.scansLeft(scansRemaining, scansLimit) }

    func startScan() {
        container.requirePremium(.scan, reason: .scansExhausted) {
            container.router.push(.capture)
        }
    }

    func addManually() {
        container.router.push(.ingredients([]))
    }

    func cookFromPantry() {
        let items = container.pantry.items
        guard !items.isEmpty else { return }
        container.router.push(.recipes(items))
    }

    func openWeeklyMenu() {
        container.requirePremium(.weeklyMenu) { container.router.push(.weeklyMenu) }
    }

    func openHistory() {
        container.requirePremium(.scanHistory) { container.router.push(.scanHistory) }
    }

    func match(for recipe: Recipe) -> RecipeMatch {
        container.match(for: recipe)
    }
}
