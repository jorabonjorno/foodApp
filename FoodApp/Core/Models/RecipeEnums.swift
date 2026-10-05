import Foundation

enum Difficulty: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let raw = (try? decoder.singleValueContainer().decode(String.self))?.lowercased() ?? ""
        self = Difficulty(rawValue: raw) ?? .medium
    }

    var title: String {
        switch self {
        case .easy: L10n.Difficulty.easy
        case .medium: L10n.Difficulty.medium
        case .hard: L10n.Difficulty.hard
        }
    }

    var rank: Int {
        switch self {
        case .easy: 0
        case .medium: 1
        case .hard: 2
        }
    }
}

enum MealType: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case soup
    case salad
    case baking
    case dessert
    case other

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let raw = (try? decoder.singleValueContainer().decode(String.self))?.lowercased() ?? ""
        self = MealType(rawValue: raw) ?? .other
    }

    var title: String {
        switch self {
        case .breakfast: L10n.MealType.breakfast
        case .lunch: L10n.MealType.lunch
        case .dinner: L10n.MealType.dinner
        case .soup: L10n.MealType.soup
        case .salad: L10n.MealType.salad
        case .baking: L10n.MealType.baking
        case .dessert: L10n.MealType.dessert
        case .other: L10n.MealType.other
        }
    }
}

/// Количество порций для фильтра: 1, 2, 3–4, 5+.
enum ServingsRange: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case one
    case two
    case threeToFour
    case fivePlus

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let raw = (try? decoder.singleValueContainer().decode(String.self)) ?? ""
        self = ServingsRange(rawValue: raw) ?? .two
    }

    func contains(_ servings: Int) -> Bool {
        switch self {
        case .one: servings == 1
        case .two: servings == 2
        case .threeToFour: (3...4).contains(servings)
        case .fivePlus: servings >= 5
        }
    }

    var title: String {
        switch self {
        case .one: "1"
        case .two: "2"
        case .threeToFour: "3–4"
        case .fivePlus: "5+"
        }
    }
}
