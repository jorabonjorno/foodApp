import SwiftUI

// MARK: - Shimmer

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    GeometryReader { proxy in
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.45), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: proxy.size.width * 0.6)
                        .offset(x: phase * proxy.size.width * 1.6)
                        .blendMode(.plusLighter)
                    }
                    .mask(content)
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) { phase = 1 }
            }
    }
}

extension View {
    func shimmering() -> some View { modifier(ShimmerModifier()) }
}

/// Скелетон карточки рецепта.
struct RecipeCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                .frame(height: 170)
            RoundedRectangle(cornerRadius: 6).frame(width: 220, height: 20)
            RoundedRectangle(cornerRadius: 6).frame(width: 160, height: 14)
            RoundedRectangle(cornerRadius: 6).frame(height: 8)
        }
        .foregroundStyle(Color.primary.opacity(0.07))
        .cardStyle(padding: Theme.Spacing.s)
        .shimmering()
        .accessibilityHidden(true)
    }
}

/// Сменяющиеся статусы загрузки вместо "Loading...".
struct RotatingStatusText: View {
    let messages: [String]
    var interval: Duration = .seconds(1.6)
    @State private var index = 0

    var body: some View {
        Text(messages.isEmpty ? "" : messages[index % messages.count])
            .font(.headline)
            .foregroundStyle(.secondary)
            .contentTransition(.opacity)
            .id(index)
            .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
            .task {
                guard messages.count > 1 else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(for: interval)
                    withAnimation(.easeInOut(duration: 0.35)) { index += 1 }
                }
            }
            .accessibilityLabel(messages.first ?? "")
    }
}

// MARK: - Scanning animation

/// Ненавязчивая анимация «AI сканирует фото»: линия сканера, мерцающие искры, мягкое свечение.
struct ScanningAnimationView: View {
    private static let sparkles: [CGPoint] = [
        CGPoint(x: 0.2, y: 0.25), CGPoint(x: 0.75, y: 0.2), CGPoint(x: 0.4, y: 0.55),
        CGPoint(x: 0.85, y: 0.7), CGPoint(x: 0.15, y: 0.8), CGPoint(x: 0.6, y: 0.4),
    ]

    let image: UIImage?
    @State private var scanOffset: CGFloat = 0
    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .overlay(Color.black.opacity(0.15))
                } else {
                    Theme.artworkGradient(for: .other)
                }

                // Линия сканера
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.0), Color.white.opacity(0.75), Color.white.opacity(0.0), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 90)
                .offset(y: (scanOffset - 0.5) * proxy.size.height)
                .blendMode(.plusLighter)

                // Искры
                ForEach(0..<Self.sparkles.count, id: \.self) { i in
                    Image(systemName: "sparkle")
                        .font(.system(size: CGFloat(12 + (i % 3) * 6), weight: .bold))
                        .foregroundStyle(.white)
                        .position(
                            x: proxy.size.width * Self.sparkles[i].x,
                            y: proxy.size.height * Self.sparkles[i].y
                        )
                        .opacity(pulse ? (i.isMultiple(of: 2) ? 0.9 : 0.2) : (i.isMultiple(of: 2) ? 0.2 : 0.9))
                        .scaleEffect(pulse ? 1.1 : 0.8)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.hero, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.hero, style: .continuous)
                .strokeBorder(Theme.ctaGradient, lineWidth: 3)
                .opacity(pulse ? 1 : 0.4)
        )
        .shadow(color: Theme.accent.opacity(pulse ? 0.35 : 0.1), radius: 24)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { scanOffset = 1 }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { pulse = true }
        }
        .accessibilityHidden(true)
    }
}
