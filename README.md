# Что приготовить — iOS MVP

«Сфотографируй продукты — узнай, что можно приготовить прямо сейчас».
SwiftUI · iOS 17+ · SwiftData · StoreKit 2. Без Mac: сборка и тесты через GitHub Actions.

## Архитектура

```text
iPhone (почти всё локально)                    Cloudflare Worker (free)        Claude Haiku 4.5
 SwiftUI → ViewModels → Stores/Services  ──HTTPS──▶  POST /recognize-foods  ──────▶  vision
 ├─ recipes.json (локальная база, 150+ рецептов)        ключ AI только здесь
 ├─ DefaultRecipeMatchingService (без AI)              фото не сохраняется
 ├─ SwiftData: pantry, favorites, history, shopping
 └─ StoreKit 2: PRO + ScanQuota (3 / 50 сканов в месяц, Keychain)
```

AI используется **только для распознавания продуктов**. Подбор рецептов, фильтры и меню на неделю — локальные алгоритмы.

| Папка | Что внутри |
|---|---|
| `FoodApp/App` | точка входа, `AppEnvironment` (.mock / .production), DI-контейнер, роутер, табы |
| `FoodApp/Core/Recipes` | словарь продуктов, нормализация, matching, база рецептов, меню на неделю |
| `FoodApp/Core/AI` | `FoodRecognitionService` (+ Mock, Real), защищённый декодер ответов |
| `FoodApp/Core/Premium` | `PremiumFeature`, `EntitlementService`, `SubscriptionManager`, `ScanQuota` |
| `FoodApp/Features/*` | экраны: Home, Camera, Recognition, Ingredients, Recipes, RecipeDetail, Pantry (+покупки), Favorites, WeeklyMenu, Paywall, Profile |
| `tools/` | генераторы `recipes.json` и строк (`L10n.swift` + `Localizable.xcstrings`) |
| `backend/` | прокси на Cloudflare Workers |
| `docs/` | privacy / terms для GitHub Pages |

## Режимы

- **Mock** (по умолчанию, `API_BASE_URL` пуст): AI не вызывается, распознавание возвращает подготовленный список. В профиле есть тестовый переключатель PRO и сброс счётчика сканов. Ноль расходов.
- **Production**: укажите в Build Settings `API_BASE_URL` (URL воркера) и `API_APP_TOKEN`.

## Как изменить контент

```bash
python tools/build_recipes.py   # после правки tools/recipes/*.txt
python tools/build_strings.py   # после правки строк в tools/build_strings.py
```

CI проверяет, что сгенерированные файлы актуальны, а все ингредиенты рецептов есть в словаре нормализации.

## Запуск прокси

```bash
cd backend && npm install
npx wrangler login
npx wrangler secret put ANTHROPIC_API_KEY
npx wrangler secret put APP_TOKEN
npx wrangler deploy
```

**Обязательно** задайте месячный лимит расходов в консоли Anthropic (Settings → Limits): это настоящий потолок бюджета.

## Перед публикацией (чек-лист)

1. Bundle ID `com.example.foodapp` → ваш; Team в Signing.
2. App Store Connect: группа подписок, продукты `…pro.monthly` ($4.99) и `…pro.yearly` ($39.99) — ID должны совпадать с `SubscriptionProducts`.
3. GitHub Pages для `docs/` → обновить `AppLinks` в `PremiumFeature.swift`, указать email поддержки.
4. Иконка 1024×1024 в `Assets.xcassets/AppIcon`.
5. TestFlight: следующий этап — workflow с `xcodebuild archive` + App Store Connect API key в GitHub Secrets.

## Стоимость (оценка)

| Сервис | Цена |
|---|---|
| GitHub Actions (публичный репозиторий) | $0 |
| Cloudflare Workers | $0 (100k запросов/день) |
| Claude Haiku 4.5 | ≈ $0.003 за скан |
| StoreKit 2 | $0 (комиссия Apple 15%) |
| Apple Developer Program | $99/год (вне бюджета) |
