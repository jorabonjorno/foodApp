import PhotosUI
import SwiftUI

struct CameraView: View {
    @State private var viewModel: CameraViewModel

    init(container: AppContainer) {
        _viewModel = State(initialValue: CameraViewModel(container: container))
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .intro: intro
            case .denied: denied
            case .preview(let image): preview(image)
            }
        }
        .background(Theme.background)
        .navigationTitle(L10n.Camera.title)
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.isLoadingPhoto {
                ProgressView()
                    .controlSize(.large)
                    .padding(Theme.Spacing.l)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
            }
        }
        .fullScreenCover(isPresented: $viewModel.isCameraPresented) {
            CameraPicker(
                onCapture: { image in Task { await viewModel.didCapture(image) } },
                onCancel: { viewModel.isCameraPresented = false }
            )
            .ignoresSafeArea()
        }
        .onChange(of: viewModel.pickerItem) { _, item in
            Task { await viewModel.handlePicked(item) }
        }
        .alert(
            L10n.Error.genericTitle,
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button(L10n.Common.done, role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task { viewModel.onAppear() }
    }

    // MARK: - Intro (onboarding + permission)

    private var intro: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.12))
                        .frame(width: 148, height: 148)
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 64, weight: .semibold))
                        .foregroundStyle(Theme.ctaGradient)
                }
                .padding(.top, Theme.Spacing.l)
                .accessibilityHidden(true)

                VStack(spacing: Theme.Spacing.xs) {
                    Text(L10n.Camera.introTitle)
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)
                    Text(L10n.Camera.introSubtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    tip("sun.max.fill", L10n.Camera.tipLight)
                    tip("eye.fill", L10n.Camera.tipVisible)
                    tip("refrigerator.fill", L10n.Camera.tipFridge)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                Label(L10n.Camera.privacy, systemImage: "lock.shield")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, Theme.Spacing.l)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Theme.Spacing.s) {
                if viewModel.isCameraAvailable {
                    Button {
                        Task { await viewModel.openCamera() }
                    } label: {
                        Label(L10n.Camera.takePhoto, systemImage: "camera.fill")
                    }
                    .buttonStyle(.primaryLarge)
                    .accessibilityIdentifier("camera.takePhotoButton")
                }

                photosPickerButton

                if viewModel.isDemoAvailable {
                    Button(L10n.Camera.demoPhoto, systemImage: "wand.and.stars", action: viewModel.useDemoPhoto)
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("camera.demoPhotoButton")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, Theme.Spacing.s)
            .padding(.bottom, Theme.Spacing.xs)
            .background(.bar)
        }
    }

    private var photosPickerButton: some View {
        PhotosPicker(selection: $viewModel.pickerItem, matching: .images) {
            Label(L10n.Camera.choosePhoto, systemImage: "photo.on.rectangle")
        }
        .buttonStyle(.secondary)
        .accessibilityIdentifier("camera.choosePhotoButton")
    }

    private func tip(_ icon: String, _ text: String) -> some View {
        HStack(spacing: Theme.Spacing.s) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 36, height: 36)
                .background(Theme.accent.opacity(0.12), in: Circle())
                .accessibilityHidden(true)
            Text(text).font(.subheadline)
        }
    }

    // MARK: - Permission denied

    private var denied: some View {
        VStack(spacing: Theme.Spacing.m) {
            Spacer()
            EmptyStateView(
                title: L10n.Camera.deniedTitle,
                message: L10n.Camera.deniedMessage,
                systemImage: "camera.badge.ellipsis",
                primaryTitle: L10n.Common.openSettings,
                primaryAction: viewModel.openSettings
            )
            photosPickerButton
                .padding(.horizontal, Theme.Spacing.xl + 20)
            if viewModel.isDemoAvailable {
                Button(L10n.Camera.demoPhoto, systemImage: "wand.and.stars", action: viewModel.useDemoPhoto)
                    .font(.subheadline.weight(.semibold))
                    .frame(minHeight: 44)
            }
            Spacer()
        }
    }

    // MARK: - Preview

    private func preview(_ image: UIImage) -> some View {
        VStack(spacing: Theme.Spacing.m) {
            Text(L10n.Camera.previewTitle)
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.top, Theme.Spacing.s)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20)
                .accessibilityLabel(L10n.Camera.previewTitle)

            HStack(spacing: Theme.Spacing.s) {
                Button(action: viewModel.retake) {
                    Label(L10n.Camera.retake, systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.secondary)
                .accessibilityIdentifier("camera.retakeButton")

                Button(action: viewModel.confirm) {
                    Label(L10n.Camera.continueButton, systemImage: "sparkles")
                }
                .buttonStyle(.primary)
                .accessibilityIdentifier("camera.continueButton")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, Theme.Spacing.s)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }
}
