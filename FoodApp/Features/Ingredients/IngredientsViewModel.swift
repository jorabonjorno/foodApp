import Foundation
import Observation

/// Редактирование списка продуктов перед поиском рецептов (после AI или вручную).
@MainActor
@Observable
final class IngredientsViewModel {
    enum Mode: Equatable {
        case recognized
        case manual
    }

    private(set) var mode: Mode
    private(set) var ingredients: [Ingredient]
    var isAddSheetPresented = false
    var renamingID: UUID?
    var renameText = ""
    var toast: String?

    private let container: AppContainer

    init(container: AppContainer, mode: Mode, initial: [Ingredient] = []) {
        self.container = container
        self.mode = mode
        self.ingredients = initial
    }

    var title: String {
        mode == .recognized && !ingredients.isEmpty
            ? L10n.Ingredients.found(ingredients.count)
            : L10n.Ingredients.manualTitle
    }

    var subtitle: String {
        mode == .recognized ? L10n.Ingredients.checkHint : L10n.Ingredients.manualHint
    }

    var canShowRecipes: Bool { !ingredients.isEmpty }

    var isRenaming: Bool {
        get { renamingID != nil }
        set { if !newValue { renamingID = nil } }
    }

    func setRecognized(_ foods: [RecognizedFood]) {
        mode = .recognized
        // Сначала уверенные продукты, сомнительные — в конце, чтобы пользователь их заметил.
        ingredients = foods
            .sorted { $0.confidence > $1.confidence }
            .map { $0.toIngredient() }
    }

    func switchToManual() {
        mode = .manual
    }

    // MARK: - Editing

    func increment(_ id: UUID) {
        guard let index = ingredients.firstIndex(where: { $0.id == id }) else { return }
        ingredients[index].incrementQuantity()
    }

    func decrement(_ id: UUID) {
        guard let index = ingredients.firstIndex(where: { $0.id == id }) else { return }
        ingredients[index].decrementQuantity()
    }

    func remove(_ id: UUID) {
        guard let index = ingredients.firstIndex(where: { $0.id == id }) else { return }
        ingredients.remove(at: index)
    }

    func remove(atOffsets offsets: IndexSet) {
        for index in offsets.sorted(by: >) where ingredients.indices.contains(index) {
            remove(ingredients[index].id)
        }
    }

    func add(_ ingredient: Ingredient) {
        guard !ingredients.contains(where: { $0.normalizedName == ingredient.normalizedName }) else {
            toast = L10n.AddIngredient.added(ingredient.name)
            return
        }
        ingredients.append(ingredient)
    }

    func contains(_ key: String) -> Bool {
        ingredients.contains { $0.normalizedName == key }
    }

    func beginRename(_ ingredient: Ingredient) {
        renameText = ingredient.name
        renamingID = ingredient.id
    }

    func commitRename() {
        defer { renamingID = nil }
        guard let id = renamingID, let index = ingredients.firstIndex(where: { $0.id == id }) else { return }
        ingredients[index].rename(to: renameText)
    }

    // MARK: - Actions

    func saveToPantry() {
        container.pantry.add(ingredients)
        toast = L10n.Ingredients.savedToPantry
    }

    func showRecipes() {
        guard canShowRecipes else { return }
        container.router.lastConfirmedIngredients = ingredients
        container.history.add(ingredients)
        container.router.push(.recipes(ingredients))
    }
}
