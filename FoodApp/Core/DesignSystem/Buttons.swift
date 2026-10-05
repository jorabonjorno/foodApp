import SwiftUI

/// Главная CTA-кнопка: крупная, градиентная, на всю ширину.
struct PrimaryButtonStyle: ButtonStyle {
    var isLarge = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(isLarge ? .title3.weight(.bold) : .headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: isLarge ? 64 : 56)
            .padding(.horizontal, Theme.Spacing.m)
            .background(Theme.ctaGradient, in: RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
            .opacity(isEnabled ? 1 : 0.45)
            .shadow(color: Color(red: 0.85, green: 0.28, blue: 0.10).opacity(isEnabled ? 0.30 : 0), radius: 14, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Вторичная кнопка: мягкий тонированный фон.
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.accent)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, Theme.Spacing.m)
            .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Круглая кнопка-иконка (± количество и т.п.) с тап-зоной 44pt.
struct CircleIconButtonStyle: ButtonStyle {
    var tint: Color = Theme.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(tint)
            .frame(width: 34, height: 34)
            .background(tint.opacity(0.12), in: Circle())
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Для кастомных карточек-кнопок: лёгкое «нажатие» без изменения оформления.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static var primaryLarge: PrimaryButtonStyle { PrimaryButtonStyle(isLarge: true) }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

extension ButtonStyle where Self == CircleIconButtonStyle {
    static var circleIcon: CircleIconButtonStyle { CircleIconButtonStyle() }
}

/// Выбираемый «чип» для фильтров.
struct ChipView: View {
    let title: String
    var systemImage: String?
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage).font(.footnote.weight(.semibold))
                }
                Text(title).font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 38)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(
                Capsule().fill(isSelected ? AnyShapeStyle(Theme.ctaGradient) : AnyShapeStyle(Theme.surface))
            )
            .overlay(Capsule().strokeBorder(Color.primary.opacity(isSelected ? 0 : 0.08)))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .animation(.snappy(duration: 0.2), value: isSelected)
    }
}

/// Небольшая плашка-бейдж ("Можно приготовить", "Не хватает 2").
struct BadgeView: View {
    let text: String
    var systemImage: String?
    var color: Color

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage { Image(systemName: systemImage) }
            Text(text)
        }
        .font(.caption.weight(.bold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundStyle(.white)
        .background(color, in: Capsule())
    }
}
