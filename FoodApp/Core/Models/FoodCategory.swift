import Foundation

/// Категория продукта. Неизвестные значения от AI декодируются в `.other`, а не роняют декодирование.
enum FoodCategory: String, Codable, CaseIterable, Hashable, Sendable {
    case vegetables
    case fruits
    case meat
    case fish
    case dairy
    case eggs
    case grains
    case bakery
    case spices
    case sauces
    case drinks
    case sweets
    case nuts
    case other

    init(from decoder: Decoder) throws {
        let raw = (try? decoder.singleValueContainer().decode(String.self)) ?? ""
        self = FoodCategory(rawValue: raw.lowercased()) ?? .other
    }

    var title: String {
        switch self {
        case .vegetables: L10n.Category.vegetables
        case .fruits: L10n.Category.fruits
        case .meat: L10n.Category.meat
        case .fish: L10n.Category.fish
        case .dairy: L10n.Category.dairy
        case .eggs: L10n.Category.eggs
        case .grains: L10n.Category.grains
        case .bakery: L10n.Category.bakery
        case .spices: L10n.Category.spices
        case .sauces: L10n.Category.sauces
        case .drinks: L10n.Category.drinks
        case .sweets: L10n.Category.sweets
        case .nuts: L10n.Category.nuts
        case .other: L10n.Category.other
        }
    }

    var emoji: String {
        switch self {
        case .vegetables: "🥕"
        case .fruits: "🍎"
        case .meat: "🥩"
        case .fish: "🐟"
        case .dairy: "🧀"
        case .eggs: "🥚"
        case .grains: "🌾"
        case .bakery: "🍞"
        case .spices: "🧂"
        case .sauces: "🥫"
        case .drinks: "🥛"
        case .sweets: "🍫"
        case .nuts: "🥜"
        case .other: "🛒"
        }
    }
}
