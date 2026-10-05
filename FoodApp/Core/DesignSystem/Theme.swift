import SwiftUI

enum Theme {
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    enum Radius {
        static let small: CGFloat = 12
        static let medium: CGFloat = 18
        static let card: CGFloat = 24
        static let hero: CGFloat = 32
    }

    static let accent = Color.accentColor
    static let success = Color(red: 0.16, green: 0.62, blue: 0.36)
    static let warning = Color(red: 0.90, green: 0.49, blue: 0.08)

    /// Градиент главных CTA. Фиксированные цвета: белый текст поверх них контрастен в обеих темах.
    static let ctaGradient = LinearGradient(
        colors: [Color(red: 0.93, green: 0.36, blue: 0.13), Color(red: 0.80, green: 0.22, blue: 0.10)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let background = Color(.systemGroupedBackground)
    static let surface = Color(.secondarySystemGroupedBackground)
    static let elevated = Color(.tertiarySystemGroupedBackground)

    /// Мягкие градиенты для обложек рецептов без фото.
    static func artworkGradient(for mealType: MealType) -> LinearGradient {
        let colors: [Color] = switch mealType {
        case .breakfast: [Color(red: 1.0, green: 0.85, blue: 0.55), Color(red: 1.0, green: 0.65, blue: 0.40)]
        case .lunch: [Color(red: 0.75, green: 0.90, blue: 0.60), Color(red: 0.45, green: 0.75, blue: 0.45)]
        case .dinner: [Color(red: 1.0, green: 0.70, blue: 0.55), Color(red: 0.90, green: 0.40, blue: 0.35)]
        case .soup: [Color(red: 1.0, green: 0.80, blue: 0.50), Color(red: 0.95, green: 0.55, blue: 0.30)]
        case .salad: [Color(red: 0.70, green: 0.92, blue: 0.70), Color(red: 0.35, green: 0.72, blue: 0.50)]
        case .baking: [Color(red: 0.98, green: 0.85, blue: 0.70), Color(red: 0.85, green: 0.62, blue: 0.45)]
        case .dessert: [Color(red: 1.0, green: 0.78, blue: 0.85), Color(red: 0.85, green: 0.50, blue: 0.70)]
        case .other: [Color(red: 0.80, green: 0.85, blue: 0.95), Color(red: 0.55, green: 0.62, blue: 0.85)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Card

struct CardModifier: ViewModifier {
    var padding: CGFloat = Theme.Spacing.m

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }
}

extension View {
    func cardStyle(padding: CGFloat = Theme.Spacing.m) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var trailing: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let trailing, let action {
                Button(trailing, action: action)
                    .font(.subheadline.weight(.semibold))
            }
        }
    }
}
