#!/usr/bin/env python3
"""Единый источник строк интерфейса.

Генерирует:
  FoodApp/Utilities/L10n.swift              — типизированный доступ из кода
  FoodApp/Resources/Localizable.xcstrings   — String Catalog (ru; позже добавляется en)

Формат записи: (Группа, имя, ключ, значение, [типы аргументов])
  значение — строка или dict с формами множественного числа {one, few, many, other}.
  Аргументы: "Int" → %lld, "String" → %@.

Запуск: python tools/build_strings.py   (или --check в CI)
"""
from __future__ import annotations

import io
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SWIFT_OUT = ROOT / "FoodApp" / "Utilities" / "L10n.swift"
CATALOG_OUT = ROOT / "FoodApp" / "Resources" / "Localizable.xcstrings"


def plural(one: str, few: str, many: str) -> dict:
    return {"one": one, "few": few, "many": many, "other": many}


S = [
    # Common
    ("Common", "cancel", "common.cancel", "Отмена"),
    ("Common", "done", "common.done", "Готово"),
    ("Common", "add", "common.add", "Добавить"),
    ("Common", "delete", "common.delete", "Удалить"),
    ("Common", "retry", "common.retry", "Повторить"),
    ("Common", "reset", "common.reset", "Сбросить"),
    ("Common", "save", "common.save", "Сохранить"),
    ("Common", "any", "common.any", "Все"),
    ("Common", "close", "common.close", "Закрыть"),
    ("Common", "openSettings", "common.open_settings", "Открыть настройки"),
    # Tabs
    ("Tab", "home", "tab.home", "Главная"),
    ("Tab", "pantry", "tab.pantry", "Продукты"),
    ("Tab", "favorites", "tab.favorites", "Избранное"),
    ("Tab", "profile", "tab.profile", "Профиль"),
    # Home
    ("Home", "title", "home.title", "Что приготовить?"),
    ("Home", "subtitle", "home.subtitle", "Сфотографируйте продукты — мы подберём рецепты"),
    ("Home", "scanButton", "home.scan_button", "Сфотографировать продукты"),
    ("Home", "addManually", "home.add_manually", "Добавить продукты вручную"),
    ("Home", "cookFromPantry", "home.cook_from_pantry", "Приготовить из моих продуктов"),
    ("Home", "pantryCount", "home.pantry_count", plural("%lld продукт", "%lld продукта", "%lld продуктов"), ["Int"]),
    ("Home", "favoriteRecipes", "home.favorite_recipes", "Избранные рецепты"),
    ("Home", "privacyNote", "home.privacy_note", "Фото используется только для распознавания продуктов и нигде не хранится."),
    ("Home", "greetingMorning", "home.greeting_morning", "Доброе утро"),
    ("Home", "greetingDay", "home.greeting_day", "Добрый день"),
    ("Home", "greetingEvening", "home.greeting_evening", "Добрый вечер"),
    ("Home", "scansLeft", "home.scans_left", "Осталось сканирований: %lld из %lld", ["Int", "Int"]),
    # Camera
    ("Camera", "title", "camera.title", "Фото продуктов"),
    ("Camera", "introTitle", "camera.intro_title", "Сфотографируйте продукты"),
    ("Camera", "introSubtitle", "camera.intro_subtitle", "AI определит, что у вас есть, а вы сможете поправить список."),
    ("Camera", "tipLight", "camera.tip_light", "Хорошее освещение"),
    ("Camera", "tipVisible", "camera.tip_visible", "Продукты видны целиком"),
    ("Camera", "tipFridge", "camera.tip_fridge", "Можно снимать открытый холодильник или стол"),
    ("Camera", "takePhoto", "camera.take_photo", "Сделать фото"),
    ("Camera", "choosePhoto", "camera.choose_photo", "Выбрать из Фото"),
    ("Camera", "demoPhoto", "camera.demo_photo", "Использовать демо-фото"),
    ("Camera", "retake", "camera.retake", "Переснять"),
    ("Camera", "continueButton", "camera.continue", "Продолжить"),
    ("Camera", "privacy", "camera.privacy", "Фото используется только для распознавания продуктов."),
    ("Camera", "deniedTitle", "camera.denied_title", "Нет доступа к камере"),
    ("Camera", "deniedMessage", "camera.denied_message", "Разрешите доступ в Настройках или выберите фото из галереи."),
    ("Camera", "unavailable", "camera.unavailable", "Камера недоступна на этом устройстве."),
    ("Camera", "previewTitle", "camera.preview_title", "Проверьте фото"),
    ("Camera", "loadFailed", "camera.load_failed", "Не удалось загрузить фото."),
    # Recognition
    ("Recognition", "title", "recognition.title", "Ищем продукты…"),
    ("Recognition", "step1", "recognition.step1", "Распознаём продукты…"),
    ("Recognition", "step2", "recognition.step2", "Оцениваем количество…"),
    ("Recognition", "step3", "recognition.step3", "Почти готово…"),
    ("Recognition", "addManually", "recognition.add_manually", "Ввести продукты вручную"),
    ("Recognition", "retakePhoto", "recognition.retake_photo", "Переснять фото"),
    # Ingredients
    ("Ingredients", "found", "ingredients.found",
     plural("Мы нашли %lld продукт", "Мы нашли %lld продукта", "Мы нашли %lld продуктов"), ["Int"]),
    ("Ingredients", "manualTitle", "ingredients.manual_title", "Ваши продукты"),
    ("Ingredients", "checkHint", "ingredients.check_hint", "Проверьте список — AI может ошибаться"),
    ("Ingredients", "manualHint", "ingredients.manual_hint", "Добавьте продукты, которые есть дома"),
    ("Ingredients", "addProduct", "ingredients.add_product", "Добавить продукт"),
    ("Ingredients", "showRecipes", "ingredients.show_recipes", "Показать рецепты"),
    ("Ingredients", "emptyTitle", "ingredients.empty_title", "Добавьте продукты, чтобы начать"),
    ("Ingredients", "emptyMessage", "ingredients.empty_message", "Добавьте хотя бы один продукт — и мы подберём рецепты."),
    ("Ingredients", "lowConfidence", "ingredients.low_confidence", "Проверьте — AI не уверен"),
    ("Ingredients", "rename", "ingredients.rename", "Переименовать"),
    ("Ingredients", "renamePlaceholder", "ingredients.rename_placeholder", "Название продукта"),
    ("Ingredients", "saveToPantry", "ingredients.save_to_pantry", "Сохранить в «Мои продукты»"),
    ("Ingredients", "savedToPantry", "ingredients.saved_to_pantry", "Сохранено в «Мои продукты»"),
    ("Ingredients", "quantityUnknown", "ingredients.quantity_unknown", "не указано"),
    ("Ingredients", "increase", "ingredients.increase", "Больше"),
    ("Ingredients", "decrease", "ingredients.decrease", "Меньше"),
    ("Ingredients", "quantityA11y", "ingredients.quantity_a11y", "Количество: %@", ["String"]),
    # Add ingredient
    ("AddIngredient", "title", "add_ingredient.title", "Добавить продукт"),
    ("AddIngredient", "placeholder", "add_ingredient.placeholder", "Например, помидоры"),
    ("AddIngredient", "popular", "add_ingredient.popular", "Популярные"),
    ("AddIngredient", "suggestions", "add_ingredient.suggestions", "Подходящие"),
    ("AddIngredient", "addCustom", "add_ingredient.add_custom", "Добавить «%@»", ["String"]),
    ("AddIngredient", "added", "add_ingredient.added", "«%@» в списке", ["String"]),
    # Recipes
    ("Recipes", "title", "recipes.title", "Что можно приготовить?"),
    ("Recipes", "subtitle", "recipes.subtitle", "Из ваших продуктов"),
    ("Recipes", "filters", "recipes.filters", "Фильтры"),
    ("Recipes", "quick", "recipes.quick", "До 30 мин"),
    ("Recipes", "easy", "recipes.easy", "Легко"),
    ("Recipes", "cookNow", "recipes.cook_now", "Всё есть"),
    ("Recipes", "sectionCookNow", "recipes.section_cook_now", "Можно приготовить сейчас"),
    ("Recipes", "sectionAlmost", "recipes.section_almost", "Почти всё есть"),
    ("Recipes", "emptyTitle", "recipes.empty_title", "Не нашли подходящих рецептов"),
    ("Recipes", "emptyMessage", "recipes.empty_message", "Попробуйте изменить фильтры или добавить продукты."),
    ("Recipes", "resetFilters", "recipes.reset_filters", "Сбросить фильтры"),
    # Recipe
    ("Recipe", "minutes", "recipe.minutes", "%lld мин", ["Int"]),
    ("Recipe", "servings", "recipe.servings", plural("%lld порция", "%lld порции", "%lld порций"), ["Int"]),
    ("Recipe", "available", "recipe.available", "Есть %lld из %lld ингредиентов", ["Int", "Int"]),
    ("Recipe", "canCook", "recipe.can_cook", "Можно приготовить"),
    ("Recipe", "missingCount", "recipe.missing_count", "Не хватает: %lld", ["Int"]),
    ("Recipe", "missingList", "recipe.missing_list", "Не хватает: %@", ["String"]),
    ("Recipe", "open", "recipe.open", "Открыть рецепт"),
    ("Recipe", "ingredients", "recipe.ingredients", "Ингредиенты"),
    ("Recipe", "steps", "recipe.steps", "Приготовление"),
    ("Recipe", "addToFavorites", "recipe.add_to_favorites", "Добавить в избранное"),
    ("Recipe", "inFavorites", "recipe.in_favorites", "В избранном"),
    ("Recipe", "removeFromFavorites", "recipe.remove_from_favorites", "Убрать из избранного"),
    ("Recipe", "addedToFavorites", "recipe.added_to_favorites", "Добавлено в избранное"),
    ("Recipe", "step", "recipe.step", "Шаг %lld", ["Int"]),
    ("Recipe", "have", "recipe.have", "есть"),
    ("Recipe", "missing", "recipe.missing", "нет"),
    ("Recipe", "optional", "recipe.optional", "по желанию"),
    ("Recipe", "share", "recipe.share", "Поделиться"),
    # Filters
    ("Filters", "title", "filters.title", "Фильтры"),
    ("Filters", "time", "filters.time", "Время"),
    ("Filters", "upTo", "filters.up_to", "До %lld мин", ["Int"]),
    ("Filters", "anyTime", "filters.any_time", "Неважно"),
    ("Filters", "difficulty", "filters.difficulty", "Сложность"),
    ("Filters", "advanced", "filters.advanced", "Расширенные фильтры"),
    ("Filters", "mealType", "filters.meal_type", "Тип блюда"),
    ("Filters", "servings", "filters.servings", "Порции"),
    ("Filters", "allowMissing", "filters.allow_missing", "Показывать рецепты, для которых не хватает продуктов"),
    ("Filters", "allowMissingHint", "filters.allow_missing_hint", "Выключите, чтобы видеть только то, что можно приготовить прямо сейчас"),
    ("Filters", "mustInclude", "filters.must_include", "Обязательно использовать"),
    ("Filters", "exclude", "filters.exclude", "Исключить продукты"),
    ("Filters", "excludePlaceholder", "filters.exclude_placeholder", "Например, грибы"),
    ("Filters", "apply", "filters.apply", "Показать рецепты"),
    # Pantry
    ("Pantry", "title", "pantry.title", "Мои продукты"),
    ("Pantry", "fridge", "pantry.fridge", "Холодильник"),
    ("Pantry", "produce", "pantry.produce", "Овощи и фрукты"),
    ("Pantry", "other", "pantry.other", "Другое"),
    ("Pantry", "emptyTitle", "pantry.empty_title", "Добавьте продукты, чтобы начать"),
    ("Pantry", "emptyMessage", "pantry.empty_message", "Сохраните, что есть дома, — и подбирайте рецепты без фото."),
    ("Pantry", "whatToCook", "pantry.what_to_cook", "Что приготовить из этого?"),
    ("Pantry", "clearAll", "pantry.clear_all", "Очистить всё"),
    ("Pantry", "clearConfirm", "pantry.clear_confirm", "Удалить все продукты?"),
    # Shopping list
    ("ShoppingList", "title", "shopping.title", "Покупки"),
    ("ShoppingList", "addMissing", "shopping.add_missing", "Добавить недостающее в покупки"),
    ("ShoppingList", "alreadyAdded", "shopping.already_added", "Уже в списке покупок"),
    ("ShoppingList", "added", "shopping.added", "В список покупок: +%lld", ["Int"]),
    ("ShoppingList", "emptyTitle", "shopping.empty_title", "Список покупок пуст"),
    ("ShoppingList", "emptyMessage", "shopping.empty_message", "Добавляйте недостающие продукты прямо из рецепта."),
    ("ShoppingList", "lockedTitle", "shopping.locked_title", "Список покупок — в PRO"),
    ("ShoppingList", "lockedMessage", "shopping.locked_message", "Недостающие продукты из рецептов — в одном списке."),
    ("ShoppingList", "moveToPantry", "shopping.move_to_pantry", "Купленное — в мои продукты"),
    ("ShoppingList", "movedToPantry", "shopping.moved_to_pantry", "Перенесено в продукты: %lld", ["Int"]),
    # Favorites
    ("Favorites", "title", "favorites.title", "Избранное"),
    ("Favorites", "emptyTitle", "favorites.empty_title", "Здесь появятся избранные рецепты"),
    ("Favorites", "emptyMessage", "favorites.empty_message", "Нажмите ♡ на рецепте, чтобы сохранить его."),
    ("Favorites", "findRecipes", "favorites.find_recipes", "Найти рецепты"),
    # Weekly menu
    ("WeeklyMenu", "title", "weekly.title", "Меню на неделю"),
    ("WeeklyMenu", "subtitle", "weekly.subtitle", "7 блюд из ваших продуктов"),
    ("WeeklyMenu", "hint", "weekly.hint", "Подобрали разнообразные блюда с учётом ваших продуктов."),
    ("WeeklyMenu", "regenerate", "weekly.regenerate", "Собрать заново"),
    ("WeeklyMenu", "addMissing", "weekly.add_missing", "Всё недостающее — в покупки"),
    # History
    ("History", "title", "history.title", "История сканирований"),
    ("History", "subtitle", "history.subtitle", "Прошлые списки продуктов"),
    ("History", "emptyTitle", "history.empty_title", "Пока нет сканирований"),
    # Paywall
    ("Paywall", "title", "paywall.title", "Готовьте больше с PRO"),
    ("Paywall", "scansTitle", "paywall.scans_title",
     plural("Вы использовали %lld бесплатное сканирование", "Вы использовали %lld бесплатных сканирования",
            "Вы использовали %lld бесплатных сканирований"), ["Int"]),
    ("Paywall", "subtitle", "paywall.subtitle", "Получайте больше идей для приготовления."),
    ("Paywall", "featureScans", "paywall.feature_scans",
     plural("%lld AI-сканирование в месяц", "%lld AI-сканирования в месяц", "%lld AI-сканирований в месяц"), ["Int"]),
    ("Paywall", "featureFilters", "paywall.feature_filters", "Расширенные фильтры"),
    ("Paywall", "featureMenu", "paywall.feature_menu", "Меню на неделю"),
    ("Paywall", "featureShopping", "paywall.feature_shopping", "Список покупок"),
    ("Paywall", "featureHistory", "paywall.feature_history", "История сканирований"),
    ("Paywall", "yearly", "paywall.yearly", "Год"),
    ("Paywall", "monthly", "paywall.monthly", "Месяц"),
    ("Paywall", "perMonth", "paywall.per_month", "%@ в месяц", ["String"]),
    ("Paywall", "billedMonthly", "paywall.billed_monthly", "Оплата каждый месяц"),
    ("Paywall", "save", "paywall.save", "Выгоднее на %lld%%", ["Int"]),
    ("Paywall", "cta", "paywall.cta", "Попробовать PRO"),
    ("Paywall", "legal", "paywall.legal",
     "Подписка продлевается автоматически, если не отменить её минимум за 24 часа до конца периода. "
     "Управлять подпиской можно в настройках App Store."),
    ("Paywall", "unlock", "paywall.unlock", "Открыть в PRO"),
    ("Paywall", "proBadgeA11y", "paywall.pro_badge_a11y", "Доступно в PRO"),
    ("Paywall", "productsUnavailable", "paywall.products_unavailable", "Не удалось загрузить подписки. Попробуйте позже."),
    ("Paywall", "purchaseFailed", "paywall.purchase_failed", "Покупка не прошла. Попробуйте ещё раз."),
    ("Paywall", "nothingToRestore", "paywall.nothing_to_restore", "Активных покупок не найдено."),
    # Profile
    ("Profile", "freePlan", "profile.free_plan", "Бесплатный план"),
    ("Profile", "proActive", "profile.pro_active", "PRO активен"),
    ("Profile", "scansUsage", "profile.scans_usage", "Сканирований в этом месяце: %lld из %lld", ["Int", "Int"]),
    ("Profile", "manage", "profile.manage", "Управлять подпиской"),
    ("Profile", "restore", "profile.restore", "Восстановить покупки"),
    ("Profile", "restored", "profile.restored", "Покупки восстановлены"),
    ("Profile", "language", "profile.language", "Язык приложения"),
    ("Profile", "privacy", "profile.privacy", "Конфиденциальность"),
    ("Profile", "terms", "profile.terms", "Условия использования"),
    ("Profile", "photoNote", "profile.photo_note",
     "Фото продуктов отправляются только для распознавания и не сохраняются ни в приложении, ни на сервере."),
    ("Profile", "version", "profile.version", "Версия %@", ["String"]),
    ("Profile", "debugTitle", "profile.debug_title", "Режим разработки (mock)"),
    ("Profile", "debugPremium", "profile.debug_premium", "Включить PRO (тест)"),
    ("Profile", "debugResetScans", "profile.debug_reset_scans", "Сбросить счётчик сканов"),
    # Errors
    ("Error", "networkTitle", "error.network_title", "Проверьте подключение к интернету"),
    ("Error", "networkMessage", "error.network_message", "Не удалось связаться с сервером. Попробуйте ещё раз."),
    ("Error", "timeoutMessage", "error.timeout_message", "Сервер долго не отвечает. Попробуйте ещё раз."),
    ("Error", "recognitionTitle", "error.recognition_title", "Не удалось распознать продукты"),
    ("Error", "recognitionMessage", "error.recognition_message",
     "Попробуйте сделать фото при лучшем освещении или добавьте продукты вручную."),
    ("Error", "noFoodsMessage", "error.no_foods_message", "На фото не нашлось продуктов. Попробуйте другой ракурс."),
    ("Error", "cameraTitle", "error.camera_title", "Камера недоступна"),
    ("Error", "cameraMessage", "error.camera_message", "Выберите фото из галереи."),
    ("Error", "genericTitle", "error.generic_title", "Что-то пошло не так"),
    ("Error", "genericMessage", "error.generic_message", "Попробуйте ещё раз чуть позже."),
    # Categories
    ("Category", "vegetables", "category.vegetables", "Овощи"),
    ("Category", "fruits", "category.fruits", "Фрукты"),
    ("Category", "meat", "category.meat", "Мясо"),
    ("Category", "fish", "category.fish", "Рыба"),
    ("Category", "dairy", "category.dairy", "Молочное"),
    ("Category", "eggs", "category.eggs", "Яйца"),
    ("Category", "grains", "category.grains", "Крупы и бобовые"),
    ("Category", "bakery", "category.bakery", "Хлеб"),
    ("Category", "spices", "category.spices", "Специи"),
    ("Category", "sauces", "category.sauces", "Соусы и масла"),
    ("Category", "drinks", "category.drinks", "Напитки"),
    ("Category", "sweets", "category.sweets", "Сладкое"),
    ("Category", "nuts", "category.nuts", "Орехи"),
    ("Category", "other", "category.other", "Другое"),
    # Difficulty
    ("Difficulty", "easy", "difficulty.easy", "Легко"),
    ("Difficulty", "medium", "difficulty.medium", "Средне"),
    ("Difficulty", "hard", "difficulty.hard", "Сложно"),
    # Meal types
    ("MealType", "breakfast", "meal.breakfast", "Завтрак"),
    ("MealType", "lunch", "meal.lunch", "Обед"),
    ("MealType", "dinner", "meal.dinner", "Ужин"),
    ("MealType", "soup", "meal.soup", "Суп"),
    ("MealType", "salad", "meal.salad", "Салат"),
    ("MealType", "baking", "meal.baking", "Выпечка"),
    ("MealType", "dessert", "meal.dessert", "Десерт"),
    ("MealType", "other", "meal.other", "Другое"),
]

SWIFT_TYPES = {"Int": "Int", "String": "String"}


def swift_source() -> str:
    out = [
        "// Сгенерировано tools/build_strings.py — не редактируйте вручную.",
        "import Foundation",
        "",
        "/// Типизированный доступ к строкам `Localizable.xcstrings`. Строки не хардкодятся во View,",
        "/// поэтому English добавляется переводом каталога без правок кода.",
        "enum L10n {",
        "    /// Язык строк = язык выбранной локализации (для правильных форм множественного числа).",
        "    private static let locale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? \"ru\")",
        "",
        "    fileprivate static func tr(_ key: String) -> String {",
        "        NSLocalizedString(key, tableName: \"Localizable\", bundle: .main, comment: \"\")",
        "    }",
        "",
        "    fileprivate static func tr(_ key: String, _ args: CVarArg...) -> String {",
        "        String(format: tr(key), locale: locale, arguments: args)",
        "    }",
    ]
    groups: dict[str, list] = {}
    for entry in S:
        groups.setdefault(entry[0], []).append(entry)
    for group, entries in groups.items():
        out.append("")
        out.append(f"    enum {group} {{")
        for entry in entries:
            _, name, key, _value, *rest = entry
            args = rest[0] if rest else []
            if not args:
                out.append(f'        static var {name}: String {{ tr("{key}") }}')
            else:
                params = ", ".join(f"_ a{i}: {SWIFT_TYPES[t]}" for i, t in enumerate(args))
                call = ", ".join(f"a{i}" for i in range(len(args)))
                out.append(f'        static func {name}({params}) -> String {{ tr("{key}", {call}) }}')
        out.append("    }")
    out.append("}")
    return "\n".join(out) + "\n"


def unit(value: str) -> dict:
    return {"stringUnit": {"state": "translated", "value": value}}


def catalog() -> str:
    strings = {}
    for entry in S:
        key, value = entry[2], entry[3]
        if isinstance(value, dict):
            loc = {"variations": {"plural": {form: unit(v) for form, v in value.items()}}}
        else:
            loc = unit(value)
        strings[key] = {"extractionState": "manual", "localizations": {"ru": loc}}
    doc = {"sourceLanguage": "ru", "strings": dict(sorted(strings.items())), "version": "1.0"}
    return json.dumps(doc, ensure_ascii=False, indent=2) + "\n"


def main() -> None:
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
    keys = [e[2] for e in S]
    dupes = {k for k in keys if keys.count(k) > 1}
    if dupes:
        sys.exit(f"Дубликаты ключей: {dupes}")
    outputs = {SWIFT_OUT: swift_source(), CATALOG_OUT: catalog()}
    if "--check" in sys.argv:
        stale = [p for p, text in outputs.items() if not p.exists() or p.read_text(encoding="utf-8") != text]
        if stale:
            sys.exit("Устарели: " + ", ".join(str(p.relative_to(ROOT)) for p in stale) + " — запустите python tools/build_strings.py")
        print(f"Строки актуальны ({len(S)})")
        return
    for path, text in outputs.items():
        path.write_text(text, encoding="utf-8", newline="\n")
    print(f"Сгенерировано {len(S)} строк → L10n.swift, Localizable.xcstrings")


if __name__ == "__main__":
    main()
