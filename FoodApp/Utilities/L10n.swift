// Сгенерировано tools/build_strings.py — не редактируйте вручную.
import Foundation

/// Типизированный доступ к строкам `Localizable.xcstrings`. Строки не хардкодятся во View,
/// поэтому English добавляется переводом каталога без правок кода.
enum L10n {
    /// Язык строк = язык выбранной локализации (для правильных форм множественного числа).
    private static let locale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "ru")

    fileprivate static func tr(_ key: String) -> String {
        NSLocalizedString(key, tableName: "Localizable", bundle: .main, comment: "")
    }

    fileprivate static func tr(_ key: String, _ args: CVarArg...) -> String {
        String(format: tr(key), locale: locale, arguments: args)
    }

    enum Common {
        static var cancel: String { tr("common.cancel") }
        static var done: String { tr("common.done") }
        static var add: String { tr("common.add") }
        static var delete: String { tr("common.delete") }
        static var retry: String { tr("common.retry") }
        static var reset: String { tr("common.reset") }
        static var save: String { tr("common.save") }
        static var any: String { tr("common.any") }
        static var close: String { tr("common.close") }
        static var openSettings: String { tr("common.open_settings") }
    }

    enum Tab {
        static var home: String { tr("tab.home") }
        static var pantry: String { tr("tab.pantry") }
        static var favorites: String { tr("tab.favorites") }
        static var profile: String { tr("tab.profile") }
    }

    enum Home {
        static var title: String { tr("home.title") }
        static var subtitle: String { tr("home.subtitle") }
        static var scanButton: String { tr("home.scan_button") }
        static var addManually: String { tr("home.add_manually") }
        static var cookFromPantry: String { tr("home.cook_from_pantry") }
        static func pantryCount(_ a0: Int) -> String { tr("home.pantry_count", a0) }
        static var favoriteRecipes: String { tr("home.favorite_recipes") }
        static var privacyNote: String { tr("home.privacy_note") }
        static var greetingMorning: String { tr("home.greeting_morning") }
        static var greetingDay: String { tr("home.greeting_day") }
        static var greetingEvening: String { tr("home.greeting_evening") }
        static func scansLeft(_ a0: Int, _ a1: Int) -> String { tr("home.scans_left", a0, a1) }
    }

    enum Camera {
        static var title: String { tr("camera.title") }
        static var introTitle: String { tr("camera.intro_title") }
        static var introSubtitle: String { tr("camera.intro_subtitle") }
        static var tipLight: String { tr("camera.tip_light") }
        static var tipVisible: String { tr("camera.tip_visible") }
        static var tipFridge: String { tr("camera.tip_fridge") }
        static var takePhoto: String { tr("camera.take_photo") }
        static var choosePhoto: String { tr("camera.choose_photo") }
        static var demoPhoto: String { tr("camera.demo_photo") }
        static var retake: String { tr("camera.retake") }
        static var continueButton: String { tr("camera.continue") }
        static var privacy: String { tr("camera.privacy") }
        static var deniedTitle: String { tr("camera.denied_title") }
        static var deniedMessage: String { tr("camera.denied_message") }
        static var unavailable: String { tr("camera.unavailable") }
        static var previewTitle: String { tr("camera.preview_title") }
        static var loadFailed: String { tr("camera.load_failed") }
    }

    enum Recognition {
        static var title: String { tr("recognition.title") }
        static var step1: String { tr("recognition.step1") }
        static var step2: String { tr("recognition.step2") }
        static var step3: String { tr("recognition.step3") }
        static var addManually: String { tr("recognition.add_manually") }
        static var retakePhoto: String { tr("recognition.retake_photo") }
    }

    enum Ingredients {
        static func found(_ a0: Int) -> String { tr("ingredients.found", a0) }
        static var manualTitle: String { tr("ingredients.manual_title") }
        static var checkHint: String { tr("ingredients.check_hint") }
        static var manualHint: String { tr("ingredients.manual_hint") }
        static var addProduct: String { tr("ingredients.add_product") }
        static var showRecipes: String { tr("ingredients.show_recipes") }
        static var emptyTitle: String { tr("ingredients.empty_title") }
        static var emptyMessage: String { tr("ingredients.empty_message") }
        static var lowConfidence: String { tr("ingredients.low_confidence") }
        static var rename: String { tr("ingredients.rename") }
        static var renamePlaceholder: String { tr("ingredients.rename_placeholder") }
        static var saveToPantry: String { tr("ingredients.save_to_pantry") }
        static var savedToPantry: String { tr("ingredients.saved_to_pantry") }
        static var quantityUnknown: String { tr("ingredients.quantity_unknown") }
        static var increase: String { tr("ingredients.increase") }
        static var decrease: String { tr("ingredients.decrease") }
        static func quantityA11y(_ a0: String) -> String { tr("ingredients.quantity_a11y", a0) }
    }

    enum AddIngredient {
        static var title: String { tr("add_ingredient.title") }
        static var placeholder: String { tr("add_ingredient.placeholder") }
        static var popular: String { tr("add_ingredient.popular") }
        static var suggestions: String { tr("add_ingredient.suggestions") }
        static func addCustom(_ a0: String) -> String { tr("add_ingredient.add_custom", a0) }
        static func added(_ a0: String) -> String { tr("add_ingredient.added", a0) }
    }

    enum Recipes {
        static var title: String { tr("recipes.title") }
        static var subtitle: String { tr("recipes.subtitle") }
        static var filters: String { tr("recipes.filters") }
        static var quick: String { tr("recipes.quick") }
        static var easy: String { tr("recipes.easy") }
        static var cookNow: String { tr("recipes.cook_now") }
        static var sectionCookNow: String { tr("recipes.section_cook_now") }
        static var sectionAlmost: String { tr("recipes.section_almost") }
        static var emptyTitle: String { tr("recipes.empty_title") }
        static var emptyMessage: String { tr("recipes.empty_message") }
        static var resetFilters: String { tr("recipes.reset_filters") }
    }

    enum Recipe {
        static func minutes(_ a0: Int) -> String { tr("recipe.minutes", a0) }
        static func servings(_ a0: Int) -> String { tr("recipe.servings", a0) }
        static func available(_ a0: Int, _ a1: Int) -> String { tr("recipe.available", a0, a1) }
        static var canCook: String { tr("recipe.can_cook") }
        static func missingCount(_ a0: Int) -> String { tr("recipe.missing_count", a0) }
        static func missingList(_ a0: String) -> String { tr("recipe.missing_list", a0) }
        static var open: String { tr("recipe.open") }
        static var ingredients: String { tr("recipe.ingredients") }
        static var steps: String { tr("recipe.steps") }
        static var addToFavorites: String { tr("recipe.add_to_favorites") }
        static var inFavorites: String { tr("recipe.in_favorites") }
        static var removeFromFavorites: String { tr("recipe.remove_from_favorites") }
        static var addedToFavorites: String { tr("recipe.added_to_favorites") }
        static func step(_ a0: Int) -> String { tr("recipe.step", a0) }
        static var have: String { tr("recipe.have") }
        static var missing: String { tr("recipe.missing") }
        static var optional: String { tr("recipe.optional") }
        static var share: String { tr("recipe.share") }
    }

    enum Filters {
        static var title: String { tr("filters.title") }
        static var time: String { tr("filters.time") }
        static func upTo(_ a0: Int) -> String { tr("filters.up_to", a0) }
        static var anyTime: String { tr("filters.any_time") }
        static var difficulty: String { tr("filters.difficulty") }
        static var advanced: String { tr("filters.advanced") }
        static var mealType: String { tr("filters.meal_type") }
        static var servings: String { tr("filters.servings") }
        static var allowMissing: String { tr("filters.allow_missing") }
        static var allowMissingHint: String { tr("filters.allow_missing_hint") }
        static var mustInclude: String { tr("filters.must_include") }
        static var exclude: String { tr("filters.exclude") }
        static var excludePlaceholder: String { tr("filters.exclude_placeholder") }
        static var apply: String { tr("filters.apply") }
    }

    enum Pantry {
        static var title: String { tr("pantry.title") }
        static var fridge: String { tr("pantry.fridge") }
        static var produce: String { tr("pantry.produce") }
        static var other: String { tr("pantry.other") }
        static var emptyTitle: String { tr("pantry.empty_title") }
        static var emptyMessage: String { tr("pantry.empty_message") }
        static var whatToCook: String { tr("pantry.what_to_cook") }
        static var clearAll: String { tr("pantry.clear_all") }
        static var clearConfirm: String { tr("pantry.clear_confirm") }
    }

    enum ShoppingList {
        static var title: String { tr("shopping.title") }
        static var addMissing: String { tr("shopping.add_missing") }
        static var alreadyAdded: String { tr("shopping.already_added") }
        static func added(_ a0: Int) -> String { tr("shopping.added", a0) }
        static var emptyTitle: String { tr("shopping.empty_title") }
        static var emptyMessage: String { tr("shopping.empty_message") }
        static var lockedTitle: String { tr("shopping.locked_title") }
        static var lockedMessage: String { tr("shopping.locked_message") }
        static var moveToPantry: String { tr("shopping.move_to_pantry") }
        static func movedToPantry(_ a0: Int) -> String { tr("shopping.moved_to_pantry", a0) }
    }

    enum Favorites {
        static var title: String { tr("favorites.title") }
        static var emptyTitle: String { tr("favorites.empty_title") }
        static var emptyMessage: String { tr("favorites.empty_message") }
        static var findRecipes: String { tr("favorites.find_recipes") }
    }

    enum WeeklyMenu {
        static var title: String { tr("weekly.title") }
        static var subtitle: String { tr("weekly.subtitle") }
        static var hint: String { tr("weekly.hint") }
        static var regenerate: String { tr("weekly.regenerate") }
        static var addMissing: String { tr("weekly.add_missing") }
    }

    enum History {
        static var title: String { tr("history.title") }
        static var subtitle: String { tr("history.subtitle") }
        static var emptyTitle: String { tr("history.empty_title") }
    }

    enum Paywall {
        static var title: String { tr("paywall.title") }
        static func scansTitle(_ a0: Int) -> String { tr("paywall.scans_title", a0) }
        static var subtitle: String { tr("paywall.subtitle") }
        static func featureScans(_ a0: Int) -> String { tr("paywall.feature_scans", a0) }
        static var featureFilters: String { tr("paywall.feature_filters") }
        static var featureMenu: String { tr("paywall.feature_menu") }
        static var featureShopping: String { tr("paywall.feature_shopping") }
        static var featureHistory: String { tr("paywall.feature_history") }
        static var yearly: String { tr("paywall.yearly") }
        static var monthly: String { tr("paywall.monthly") }
        static func perMonth(_ a0: String) -> String { tr("paywall.per_month", a0) }
        static var billedMonthly: String { tr("paywall.billed_monthly") }
        static func save(_ a0: Int) -> String { tr("paywall.save", a0) }
        static var cta: String { tr("paywall.cta") }
        static var legal: String { tr("paywall.legal") }
        static var unlock: String { tr("paywall.unlock") }
        static var proBadgeA11y: String { tr("paywall.pro_badge_a11y") }
        static var productsUnavailable: String { tr("paywall.products_unavailable") }
        static var purchaseFailed: String { tr("paywall.purchase_failed") }
        static var nothingToRestore: String { tr("paywall.nothing_to_restore") }
    }

    enum Profile {
        static var freePlan: String { tr("profile.free_plan") }
        static var proActive: String { tr("profile.pro_active") }
        static func scansUsage(_ a0: Int, _ a1: Int) -> String { tr("profile.scans_usage", a0, a1) }
        static var manage: String { tr("profile.manage") }
        static var restore: String { tr("profile.restore") }
        static var restored: String { tr("profile.restored") }
        static var language: String { tr("profile.language") }
        static var privacy: String { tr("profile.privacy") }
        static var terms: String { tr("profile.terms") }
        static var photoNote: String { tr("profile.photo_note") }
        static func version(_ a0: String) -> String { tr("profile.version", a0) }
        static var debugTitle: String { tr("profile.debug_title") }
        static var debugPremium: String { tr("profile.debug_premium") }
        static var debugResetScans: String { tr("profile.debug_reset_scans") }
    }

    enum Error {
        static var networkTitle: String { tr("error.network_title") }
        static var networkMessage: String { tr("error.network_message") }
        static var timeoutMessage: String { tr("error.timeout_message") }
        static var recognitionTitle: String { tr("error.recognition_title") }
        static var recognitionMessage: String { tr("error.recognition_message") }
        static var noFoodsMessage: String { tr("error.no_foods_message") }
        static var cameraTitle: String { tr("error.camera_title") }
        static var cameraMessage: String { tr("error.camera_message") }
        static var genericTitle: String { tr("error.generic_title") }
        static var genericMessage: String { tr("error.generic_message") }
    }

    enum Category {
        static var vegetables: String { tr("category.vegetables") }
        static var fruits: String { tr("category.fruits") }
        static var meat: String { tr("category.meat") }
        static var fish: String { tr("category.fish") }
        static var dairy: String { tr("category.dairy") }
        static var eggs: String { tr("category.eggs") }
        static var grains: String { tr("category.grains") }
        static var bakery: String { tr("category.bakery") }
        static var spices: String { tr("category.spices") }
        static var sauces: String { tr("category.sauces") }
        static var drinks: String { tr("category.drinks") }
        static var sweets: String { tr("category.sweets") }
        static var nuts: String { tr("category.nuts") }
        static var other: String { tr("category.other") }
    }

    enum Difficulty {
        static var easy: String { tr("difficulty.easy") }
        static var medium: String { tr("difficulty.medium") }
        static var hard: String { tr("difficulty.hard") }
    }

    enum MealType {
        static var breakfast: String { tr("meal.breakfast") }
        static var lunch: String { tr("meal.lunch") }
        static var dinner: String { tr("meal.dinner") }
        static var soup: String { tr("meal.soup") }
        static var salad: String { tr("meal.salad") }
        static var baking: String { tr("meal.baking") }
        static var dessert: String { tr("meal.dessert") }
        static var other: String { tr("meal.other") }
    }
}
