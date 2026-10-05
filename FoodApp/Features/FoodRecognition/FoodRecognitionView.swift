import SwiftUI

struct FoodRecognitionView: View {
    @State private var viewModel: FoodRecognitionViewModel
    @Environment(\.dismiss) private var dismiss

    init(container: AppContainer, photoID: UUID) {
        _viewModel = State(initialValue: FoodRecognitionViewModel(container: container, photoID: photoID))
    }

    var body: some View {
        Group {
            switch viewModel.phase {
            case .recognizing:
                recognizing
                    .transition(.opacity)
            case .failed(let error):
                failed(error)
                    .transition(.opacity)
            case .done:
                IngredientsView(viewModel: viewModel.ingredients, thumbnail: viewModel.thumbnail)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: viewModel.phase)
        .background(Theme.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.startIfNeeded() }
    }

    private var recognizing: some View {
        VStack(spacing: Theme.Spacing.l) {
            Spacer(minLength: Theme.Spacing.s)
            ScanningAnimationView(image: viewModel.thumbnail)
                .aspectRatio(3 / 4, contentMode: .fit)
                .frame(maxHeight: 420)
                .padding(.horizontal, Theme.Spacing.xl)

            VStack(spacing: Theme.Spacing.xs) {
                Text(L10n.Recognition.title)
                    .font(.title2.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                RotatingStatusText(messages: [
                    L10n.Recognition.step1,
                    L10n.Recognition.step2,
                    L10n.Recognition.step3,
                ])
                .frame(height: 24)
            }
            Spacer()
            Label(L10n.Camera.privacy, systemImage: "lock.shield")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, Theme.Spacing.m)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("recognition.loading")
    }

    private func failed(_ error: AppError) -> some View {
        VStack(spacing: Theme.Spacing.s) {
            Spacer()
            EmptyStateView(
                title: error.title,
                message: error.message,
                systemImage: error.systemImage,
                primaryTitle: L10n.Common.retry,
                primaryAction: { Task { await viewModel.retry() } },
                secondaryTitle: L10n.Recognition.addManually,
                secondaryAction: viewModel.continueManually
            )
            Button(L10n.Recognition.retakePhoto, systemImage: "camera") { dismiss() }
                .font(.subheadline.weight(.semibold))
                .frame(minHeight: 44)
            Spacer()
        }
        .accessibilityIdentifier("recognition.error")
    }
}
