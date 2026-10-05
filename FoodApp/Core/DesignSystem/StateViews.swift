import SwiftUI

/// Универсальный empty/error state на базе `ContentUnavailableView`.
struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    var primaryTitle: String?
    var primaryAction: (() -> Void)?
    var secondaryTitle: String?
    var secondaryAction: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .symbolRenderingMode(.hierarchical)
            }
        } description: {
            Text(message)
        } actions: {
            VStack(spacing: Theme.Spacing.s) {
                if let primaryTitle, let primaryAction {
                    Button(primaryTitle, action: primaryAction)
                        .buttonStyle(.primary)
                }
                if let secondaryTitle, let secondaryAction {
                    Button(secondaryTitle, action: secondaryAction)
                        .buttonStyle(.secondary)
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
    }
}

extension EmptyStateView {
    init(error: AppError, retryTitle: String = L10n.Common.retry, retry: (() -> Void)?) {
        self.init(
            title: error.title,
            message: error.message,
            systemImage: error.systemImage,
            primaryTitle: retry == nil ? nil : retryTitle,
            primaryAction: retry
        )
    }
}

/// Обложка рецепта: мягкий градиент по типу блюда + крупный эмодзи.
/// Без фотографий: бесплатно, без авторских прав и без сетевых запросов.
struct RecipeArtworkView: View {
    let recipe: Recipe
    var emojiSize: CGFloat = 72

    var body: some View {
        ZStack {
            Theme.artworkGradient(for: recipe.mealType)
            Text(verbatim: recipe.coverEmoji)
                .font(.system(size: emojiSize))
                .shadow(color: .black.opacity(0.15), radius: 10, y: 6)
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

/// Маленький бейдж «PRO» рядом с платной функцией.
struct ProBadge: View {
    var body: some View {
        Text(verbatim: "PRO")
            .font(.caption2.weight(.heavy))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .foregroundStyle(.white)
            .background(Theme.ctaGradient, in: Capsule())
            .accessibilityLabel(L10n.Paywall.proBadgeA11y)
    }
}

/// Круглая иконка продукта.
struct FoodIconView: View {
    let emoji: String
    var size: CGFloat = 44

    var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.55))
            .frame(width: size, height: size)
            .background(Theme.elevated, in: Circle())
            .accessibilityHidden(true)
    }
}

/// Тост-подтверждение внизу экрана.
struct ToastView: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, Theme.Spacing.s)
            .background(.regularMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}

extension View {
    /// Показывает тост сверху, пока `text` не nil; автоматически скрывается.
    func toast(_ text: Binding<String?>) -> some View {
        overlay(alignment: .top) {
            if let value = text.wrappedValue {
                ToastView(text: value)
                    .padding(.top, Theme.Spacing.xs)
                    .task(id: value) {
                        try? await Task.sleep(for: .seconds(1.8))
                        withAnimation { text.wrappedValue = nil }
                    }
                    .accessibilityAddTraits(.isStaticText)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: text.wrappedValue)
    }
}
