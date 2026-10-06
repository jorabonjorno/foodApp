import Foundation

/// Справочник продуктов: канонический ключ, отображаемое имя, категория, эмодзи и синонимы (RU/EN).
/// Используется для нормализации, подсказок при ручном добавлении и иконок.
struct FoodDictionaryEntry: Hashable, Sendable {
    let key: String
    let displayName: String
    let emoji: String
    let category: FoodCategory
    let defaultUnit: String?
    let synonyms: [String]
    /// Более общий продукт: `chicken_breast` → `chicken`. Используется при matching.
    let parent: String?

    init(
        _ key: String,
        _ displayName: String,
        _ emoji: String,
        _ category: FoodCategory,
        unit: String? = nil,
        parent: String? = nil,
        synonyms: [String]
    ) {
        self.key = key
        self.displayName = displayName
        self.emoji = emoji
        self.category = category
        self.defaultUnit = unit
        self.parent = parent
        self.synonyms = synonyms
    }
}

enum FoodDictionary {
    /// Базовые продукты, которые почти всегда есть дома: не считаются недостающими.
    static let staples: Set<String> = ["salt", "black_pepper", "water", "vegetable_oil", "sugar"]

    static let entries: [FoodDictionaryEntry] = [
        // Овощи
        .init("tomato", "Помидоры", "🍅", .vegetables, unit: "шт", synonyms: ["помидор", "помидоры", "томат", "томаты", "tomato", "tomatoes"]),
        .init("cherry_tomato", "Помидоры черри", "🍅", .vegetables, unit: "шт", parent: "tomato", synonyms: ["черри", "помидоры черри", "томаты черри", "cherry tomato", "cherry tomatoes"]),
        .init("cucumber", "Огурцы", "🥒", .vegetables, unit: "шт", synonyms: ["огурец", "огурцы", "огурчик", "cucumber", "cucumbers"]),
        .init("onion", "Лук", "🧅", .vegetables, unit: "шт", synonyms: ["лук", "луковица", "репчатый лук", "лук репчатый", "onion", "onions", "yellow onion"]),
        .init("red_onion", "Красный лук", "🧅", .vegetables, unit: "шт", parent: "onion", synonyms: ["красный лук", "лук красный", "red onion"]),
        .init("green_onion", "Зелёный лук", "🌱", .vegetables, synonyms: ["зеленый лук", "лук зеленый", "green onion", "scallion", "spring onion"]),
        .init("garlic", "Чеснок", "🧄", .vegetables, unit: "зуб.", synonyms: ["чеснок", "зубчик чеснока", "garlic"]),
        .init("potato", "Картофель", "🥔", .vegetables, unit: "шт", synonyms: ["картофель", "картошка", "картофелина", "potato", "potatoes"]),
        .init("carrot", "Морковь", "🥕", .vegetables, unit: "шт", synonyms: ["морковь", "морковка", "carrot", "carrots"]),
        .init("bell_pepper", "Болгарский перец", "🫑", .vegetables, unit: "шт", synonyms: ["болгарский перец", "перец болгарский", "сладкий перец", "bell pepper", "sweet pepper", "paprika pepper"]),
        .init("chili_pepper", "Острый перец", "🌶️", .vegetables, unit: "шт", synonyms: ["острый перец", "перец чили", "чили", "chili", "chili pepper"]),
        .init("cabbage", "Капуста", "🥬", .vegetables, unit: "г", synonyms: ["капуста", "белокочанная капуста", "cabbage"]),
        .init("broccoli", "Брокколи", "🥦", .vegetables, unit: "г", synonyms: ["брокколи", "broccoli"]),
        .init("zucchini", "Кабачок", "🥒", .vegetables, unit: "шт", synonyms: ["кабачок", "кабачки", "цукини", "zucchini", "courgette"]),
        .init("eggplant", "Баклажан", "🍆", .vegetables, unit: "шт", synonyms: ["баклажан", "баклажаны", "eggplant", "aubergine"]),
        .init("mushroom", "Грибы", "🍄", .vegetables, unit: "г", synonyms: ["грибы", "гриб", "шампиньоны", "шампиньон", "mushroom", "mushrooms", "champignon"]),
        .init("lettuce", "Салат листовой", "🥬", .vegetables, synonyms: ["листовой салат", "салат листовой", "салат айсберг", "айсберг", "романо", "lettuce", "iceberg"]),
        .init("spinach", "Шпинат", "🥬", .vegetables, unit: "г", synonyms: ["шпинат", "spinach"]),
        .init("corn", "Кукуруза", "🌽", .vegetables, unit: "г", synonyms: ["кукуруза", "corn", "sweet corn"]),
        .init("peas", "Горошек", "🫛", .vegetables, unit: "г", synonyms: ["горошек", "зеленый горошек", "горох", "peas", "green peas"]),
        .init("beetroot", "Свёкла", "🟣", .vegetables, unit: "шт", synonyms: ["свекла", "свёкла", "beet", "beetroot"]),
        .init("dill", "Укроп", "🌿", .vegetables, synonyms: ["укроп", "dill"]),
        .init("parsley", "Петрушка", "🌿", .vegetables, synonyms: ["петрушка", "parsley"]),
        .init("herbs", "Зелень", "🌿", .vegetables, synonyms: ["зелень", "свежая зелень", "herbs", "greens", "базилик", "basil", "кинза", "cilantro"]),
        .init("avocado", "Авокадо", "🥑", .vegetables, unit: "шт", synonyms: ["авокадо", "avocado"]),

        // Фрукты
        .init("apple", "Яблоки", "🍎", .fruits, unit: "шт", synonyms: ["яблоко", "яблоки", "apple", "apples"]),
        .init("banana", "Бананы", "🍌", .fruits, unit: "шт", synonyms: ["банан", "бананы", "banana", "bananas"]),
        .init("lemon", "Лимон", "🍋", .fruits, unit: "шт", synonyms: ["лимон", "лимоны", "lemon", "lime", "лайм"]),
        .init("orange", "Апельсины", "🍊", .fruits, unit: "шт", synonyms: ["апельсин", "апельсины", "orange", "oranges"]),
        .init("berries", "Ягоды", "🫐", .fruits, unit: "г", synonyms: ["ягоды", "клубника", "малина", "черника", "berries", "strawberry", "strawberries", "raspberry", "blueberry"]),

        // Мясо
        .init("chicken", "Курица", "🍗", .meat, unit: "г", synonyms: ["курица", "куриное мясо", "цыпленок", "chicken", "куриное филе", "филе курицы", "chicken fillet"]),
        .init("chicken_breast", "Куриная грудка", "🍗", .meat, unit: "г", parent: "chicken", synonyms: ["куриная грудка", "грудка куриная", "грудка", "chicken breast"]),
        .init("chicken_thigh", "Куриные бёдра", "🍗", .meat, unit: "г", parent: "chicken", synonyms: ["куриные бедра", "бедра куриные", "бедро", "chicken thigh", "chicken thighs"]),
        .init("beef", "Говядина", "🥩", .meat, unit: "г", synonyms: ["говядина", "beef", "стейк", "steak"]),
        .init("pork", "Свинина", "🥩", .meat, unit: "г", synonyms: ["свинина", "pork"]),
        .init("minced_meat", "Фарш", "🥩", .meat, unit: "г", synonyms: ["фарш", "мясной фарш", "minced meat", "ground meat", "ground beef", "mince"]),
        .init("sausage", "Колбаса / сосиски", "🌭", .meat, unit: "г", synonyms: ["колбаса", "сосиски", "сосиска", "сардельки", "sausage", "sausages"]),
        .init("ham", "Ветчина", "🥓", .meat, unit: "г", synonyms: ["ветчина", "ham"]),
        .init("bacon", "Бекон", "🥓", .meat, unit: "г", synonyms: ["бекон", "bacon"]),

        // Рыба
        .init("fish", "Рыба", "🐟", .fish, unit: "г", synonyms: ["рыба", "рыбное филе", "fish", "white fish", "треска", "cod"]),
        .init("salmon", "Лосось", "🐟", .fish, unit: "г", parent: "fish", synonyms: ["лосось", "семга", "сёмга", "форель", "salmon", "trout"]),
        .init("tuna", "Тунец", "🐟", .fish, unit: "г", parent: "fish", synonyms: ["тунец", "консервированный тунец", "tuna"]),
        .init("shrimp", "Креветки", "🦐", .fish, unit: "г", synonyms: ["креветки", "креветка", "shrimp", "shrimps", "prawns"]),

        // Молочное и яйца
        .init("egg", "Яйца", "🥚", .eggs, unit: "шт", synonyms: ["яйцо", "яйца", "куриные яйца", "egg", "eggs"]),
        .init("milk", "Молоко", "🥛", .dairy, unit: "мл", synonyms: ["молоко", "milk"]),
        .init("cheese", "Сыр", "🧀", .dairy, unit: "г", synonyms: ["сыр", "твердый сыр", "cheese", "чеддер", "cheddar", "гауда", "gouda"]),
        .init("parmesan", "Пармезан", "🧀", .dairy, unit: "г", parent: "cheese", synonyms: ["пармезан", "сыр пармезан", "parmesan"]),
        .init("mozzarella", "Моцарелла", "🧀", .dairy, unit: "г", parent: "cheese", synonyms: ["моцарелла", "mozzarella"]),
        .init("feta", "Фета", "🧀", .dairy, unit: "г", parent: "cheese", synonyms: ["фета", "брынза", "feta"]),
        .init("butter", "Сливочное масло", "🧈", .dairy, unit: "г", synonyms: ["сливочное масло", "масло сливочное", "butter"]),
        .init("cream", "Сливки", "🥛", .dairy, unit: "мл", synonyms: ["сливки", "cream", "heavy cream"]),
        .init("sour_cream", "Сметана", "🥛", .dairy, unit: "г", synonyms: ["сметана", "sour cream"]),
        .init("yogurt", "Йогурт", "🥛", .dairy, unit: "г", synonyms: ["йогурт", "греческий йогурт", "yogurt", "yoghurt"]),
        .init("cottage_cheese", "Творог", "🥛", .dairy, unit: "г", synonyms: ["творог", "cottage cheese"]),
        .init("kefir", "Кефир", "🥛", .dairy, unit: "мл", synonyms: ["кефир", "kefir"]),

        // Крупы, мука, хлеб
        .init("rice", "Рис", "🍚", .grains, unit: "г", synonyms: ["рис", "rice"]),
        .init("pasta", "Макароны", "🍝", .grains, unit: "г", synonyms: ["макароны", "паста", "спагетти", "пенне", "лапша", "pasta", "spaghetti", "noodles", "penne"]),
        .init("buckwheat", "Гречка", "🌾", .grains, unit: "г", synonyms: ["гречка", "гречневая крупа", "buckwheat"]),
        .init("oats", "Овсяные хлопья", "🥣", .grains, unit: "г", synonyms: ["овсянка", "овсяные хлопья", "геркулес", "oats", "oatmeal"]),
        .init("flour", "Мука", "🌾", .grains, unit: "г", synonyms: ["мука", "пшеничная мука", "flour"]),
        .init("bread", "Хлеб", "🍞", .bakery, unit: "шт", synonyms: ["хлеб", "батон", "багет", "тост", "bread", "toast", "baguette"]),
        .init("tortilla", "Лаваш / тортилья", "🫓", .bakery, unit: "шт", synonyms: ["лаваш", "тортилья", "tortilla", "wrap", "pita"]),

        // Специи, соусы, базовые
        .init("salt", "Соль", "🧂", .spices, synonyms: ["соль", "salt"]),
        .init("black_pepper", "Чёрный перец", "🧂", .spices, synonyms: ["черный перец", "перец черный", "молотый перец", "black pepper", "pepper"]),
        .init("sugar", "Сахар", "🍬", .spices, unit: "г", synonyms: ["сахар", "sugar"]),
        .init("water", "Вода", "💧", .other, synonyms: ["вода", "water"]),
        .init("vegetable_oil", "Растительное масло", "🫒", .sauces, unit: "мл", synonyms: ["растительное масло", "подсолнечное масло", "оливковое масло", "масло", "olive oil", "vegetable oil", "sunflower oil", "oil"]),
        .init("mayonnaise", "Майонез", "🥫", .sauces, unit: "г", synonyms: ["майонез", "mayonnaise", "mayo"]),
        .init("ketchup", "Кетчуп", "🥫", .sauces, unit: "г", synonyms: ["кетчуп", "ketchup"]),
        .init("tomato_paste", "Томатная паста", "🥫", .sauces, unit: "г", synonyms: ["томатная паста", "tomato paste", "tomato sauce", "томатный соус"]),
        .init("soy_sauce", "Соевый соус", "🥫", .sauces, unit: "мл", synonyms: ["соевый соус", "soy sauce"]),
        .init("mustard", "Горчица", "🥫", .sauces, unit: "г", synonyms: ["горчица", "mustard"]),
        .init("honey", "Мёд", "🍯", .sweets, unit: "г", synonyms: ["мед", "мёд", "honey"]),
        .init("chocolate", "Шоколад", "🍫", .sweets, unit: "г", synonyms: ["шоколад", "темный шоколад", "chocolate"]),
        .init("baking_powder", "Разрыхлитель", "🧁", .spices, unit: "г", synonyms: ["разрыхлитель", "сода", "baking powder", "baking soda"]),
        .init("nuts", "Орехи", "🥜", .nuts, unit: "г", synonyms: ["орехи", "грецкие орехи", "миндаль", "арахис", "nuts", "walnuts", "almonds", "peanuts"]),
        .init("beans", "Фасоль", "🫘", .grains, unit: "г", synonyms: ["фасоль", "консервированная фасоль", "beans", "kidney beans"]),
        .init("chickpeas", "Нут", "🫘", .grains, unit: "г", synonyms: ["нут", "chickpeas", "chickpea"]),
        .init("lentils", "Чечевица", "🫘", .grains, unit: "г", synonyms: ["чечевица", "красная чечевица", "lentils", "lentil"]),
        .init("olives", "Оливки", "🫒", .vegetables, unit: "г", synonyms: ["оливки", "маслины", "olives"]),

        // Дополнительно для базы рецептов
        .init("cauliflower", "Цветная капуста", "🥦", .vegetables, unit: "г", synonyms: ["цветная капуста", "cauliflower"]),
        .init("pumpkin", "Тыква", "🎃", .vegetables, unit: "г", synonyms: ["тыква", "pumpkin", "butternut squash"]),
        .init("radish", "Редис", "🌱", .vegetables, unit: "шт", synonyms: ["редис", "редиска", "radish", "radishes"]),
        .init("celery", "Сельдерей", "🥬", .vegetables, unit: "г", synonyms: ["сельдерей", "celery"]),
        .init("ginger", "Имбирь", "🫚", .spices, unit: "г", synonyms: ["имбирь", "ginger"]),
        .init("frozen_vegetables", "Замороженные овощи", "🥦", .vegetables, unit: "г", synonyms: ["замороженные овощи", "овощная смесь", "frozen vegetables", "mixed vegetables"]),
        .init("pickles", "Солёные огурцы", "🥒", .vegetables, unit: "шт", synonyms: ["соленые огурцы", "маринованные огурцы", "огурцы соленые", "корнишоны", "pickles", "pickled cucumbers", "gherkins"]),
        .init("sauerkraut", "Квашеная капуста", "🥬", .vegetables, unit: "г", synonyms: ["квашеная капуста", "sauerkraut"]),
        .init("crab_sticks", "Крабовые палочки", "🦀", .fish, unit: "г", synonyms: ["крабовые палочки", "крабовое мясо", "crab sticks", "surimi"]),
        .init("canned_fish", "Рыбные консервы", "🥫", .fish, unit: "банка", parent: "fish", synonyms: ["рыбные консервы", "сайра", "шпроты", "горбуша консервированная", "canned fish", "sardines"]),
        .init("turkey", "Индейка", "🦃", .meat, unit: "г", synonyms: ["индейка", "филе индейки", "turkey", "turkey breast"]),
        .init("liver", "Печень", "🥩", .meat, unit: "г", synonyms: ["печень", "куриная печень", "говяжья печень", "liver", "chicken liver"]),
        .init("cream_cheese", "Сливочный сыр", "🧀", .dairy, unit: "г", parent: "cheese", synonyms: ["сливочный сыр", "творожный сыр", "крем чиз", "филадельфия", "cream cheese"]),
        .init("processed_cheese", "Плавленый сыр", "🧀", .dairy, unit: "г", parent: "cheese", synonyms: ["плавленый сыр", "плавленый сырок", "processed cheese"]),
        .init("condensed_milk", "Сгущёнка", "🥫", .sweets, unit: "г", synonyms: ["сгущенка", "сгущенное молоко", "condensed milk"]),
        .init("jam", "Варенье", "🍓", .sweets, unit: "г", synonyms: ["варенье", "джем", "повидло", "jam"]),
        .init("raisins", "Изюм", "🍇", .fruits, unit: "г", synonyms: ["изюм", "сухофрукты", "курага", "чернослив", "raisins", "dried fruit"]),
        .init("pear", "Груши", "🍐", .fruits, unit: "шт", synonyms: ["груша", "груши", "pear", "pears"]),
        .init("semolina", "Манка", "🌾", .grains, unit: "г", synonyms: ["манка", "манная крупа", "semolina"]),
        .init("millet", "Пшено", "🌾", .grains, unit: "г", synonyms: ["пшено", "пшенная крупа", "millet"]),
        .init("bulgur", "Булгур", "🌾", .grains, unit: "г", synonyms: ["булгур", "кускус", "bulgur", "couscous"]),
        .init("puff_pastry", "Слоёное тесто", "🥐", .bakery, unit: "г", synonyms: ["слоеное тесто", "тесто слоеное", "puff pastry"]),
        .init("yeast", "Дрожжи", "🧁", .spices, unit: "г", synonyms: ["дрожжи", "сухие дрожжи", "yeast"]),
        .init("starch", "Крахмал", "🧁", .spices, unit: "г", synonyms: ["крахмал", "кукурузный крахмал", "картофельный крахмал", "starch", "cornstarch"]),
        .init("vinegar", "Уксус", "🍶", .sauces, unit: "мл", synonyms: ["уксус", "яблочный уксус", "винный уксус", "vinegar"]),
        .init("cocoa", "Какао", "🍫", .sweets, unit: "г", synonyms: ["какао", "какао порошок", "cocoa", "cocoa powder"]),
        .init("cinnamon", "Корица", "🧂", .spices, synonyms: ["корица", "cinnamon"]),
        .init("paprika", "Паприка", "🧂", .spices, synonyms: ["паприка", "молотая паприка", "paprika powder"]),
        .init("dried_herbs", "Сушёные травы", "🌿", .spices, synonyms: ["сушеные травы", "прованские травы", "итальянские травы", "орегано", "тимьян", "oregano", "thyme", "dried herbs"]),
        .init("bay_leaf", "Лавровый лист", "🍃", .spices, synonyms: ["лавровый лист", "лавр", "bay leaf"]),
        .init("sesame", "Кунжут", "🌰", .nuts, unit: "г", synonyms: ["кунжут", "sesame", "sesame seeds"]),
        .init("pesto", "Песто", "🌿", .sauces, unit: "г", synonyms: ["песто", "соус песто", "pesto"]),
        .init("leek", "Лук-порей", "🧅", .vegetables, unit: "г", parent: "onion", synonyms: ["лук-порей", "лук порей", "порей", "leek", "leeks"]),
        .init("smoked_meat", "Копчёности", "🥓", .meat, unit: "г", synonyms: ["копчености", "копченая грудинка", "грудинка копченая", "свиная грудинка", "копченые ребрышки", "smoked meat"]),
        .init("herring", "Сельдь", "🐟", .fish, unit: "г", parent: "fish", synonyms: ["сельдь", "селедка", "сельдь слабосоленая", "филе сельди", "herring"]),
        .init("pineapple", "Ананасы", "🍍", .fruits, unit: "г", synonyms: ["ананас", "ананасы", "консервированные ананасы", "pineapple"]),
        .init("cookies", "Печенье", "🍪", .sweets, unit: "г", synonyms: ["печенье", "сахарное печенье", "песочное печенье", "cookies", "biscuits"]),
        .init("broth", "Бульон", "🍲", .other, unit: "мл", synonyms: ["бульон", "куриный бульон", "овощной бульон", "broth", "stock"]),
    ]

    private static let byKey: [String: FoodDictionaryEntry] = Dictionary(
        entries.map { ($0.key, $0) },
        uniquingKeysWith: { first, _ in first }
    )

    static func entry(for key: String) -> FoodDictionaryEntry? { byKey[key] }

    static func emoji(for key: String, category: FoodCategory) -> String {
        byKey[key]?.emoji ?? category.emoji
    }

    static func parent(of key: String) -> String? { byKey[key]?.parent }

    /// Подсказки для ручного добавления продукта.
    static func suggestions(matching query: String, limit: Int = 12) -> [FoodDictionaryEntry] {
        let q = IngredientNormalizer.clean(query)
        let visible = entries.filter { !staples.contains($0.key) }
        guard !q.isEmpty else { return Array(popular.compactMap { byKey[$0] }.prefix(limit)) }
        return Array(
            visible.filter { entry in
                IngredientNormalizer.clean(entry.displayName).contains(q)
                    || entry.synonyms.contains { IngredientNormalizer.clean($0).hasPrefix(q) }
            }
            .prefix(limit)
        )
    }

    static let popular = [
        "egg", "tomato", "chicken", "cheese", "onion", "potato", "milk", "cucumber",
        "pasta", "rice", "carrot", "garlic",
    ]
}
