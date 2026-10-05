import AVFoundation
import Observation
import PhotosUI
import SwiftUI
import UIKit

@MainActor
@Observable
final class CameraViewModel {
    enum State {
        case intro
        case denied
        case preview(UIImage)
    }

    var state: State = .intro
    var isCameraPresented = false
    var pickerItem: PhotosPickerItem?
    var isLoadingPhoto = false
    var errorMessage: String?

    private let container: AppContainer
    private var didAppear = false

    init(container: AppContainer) {
        self.container = container
    }

    var isCameraAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }
    /// Демо-фото доступно в Mock mode и на устройствах без камеры (симулятор).
    var isDemoAvailable: Bool { container.environment.isMock || !isCameraAvailable }

    var previewImage: UIImage? {
        if case .preview(let image) = state { return image }
        return nil
    }

    func onAppear() {
        guard !didAppear else { return }
        didAppear = true
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .denied || status == .restricted, case .intro = state {
            state = .denied
        }
    }

    func openCamera() async {
        guard isCameraAvailable else {
            errorMessage = L10n.Camera.unavailable
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraPresented = true
        case .notDetermined:
            if await AVCaptureDevice.requestAccess(for: .video) {
                isCameraPresented = true
            } else {
                state = .denied
            }
        default:
            state = .denied
        }
    }

    func didCapture(_ image: UIImage) async {
        isCameraPresented = false
        isLoadingPhoto = true
        let scaled = await ImageProcessor.downscaled(image)
        isLoadingPhoto = false
        withAnimation(.snappy) { state = .preview(scaled) }
    }

    func handlePicked(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isLoadingPhoto = true
        defer {
            isLoadingPhoto = false
            pickerItem = nil
        }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = await ImageProcessor.downsample(data: data)
            else {
                errorMessage = L10n.Camera.loadFailed
                return
            }
            withAnimation(.snappy) { state = .preview(image) }
        } catch {
            errorMessage = L10n.Camera.loadFailed
        }
    }

    func useDemoPhoto() {
        let renderer = ImageRenderer(content: DemoFridgeArtwork())
        renderer.scale = 2
        guard let image = renderer.uiImage else { return }
        withAnimation(.snappy) { state = .preview(image) }
    }

    func retake() {
        withAnimation(.snappy) { state = .intro }
    }

    func confirm() {
        guard let image = previewImage else { return }
        container.router.startRecognition(with: image)
        // Фото больше не нужно этому экрану.
        state = .intro
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

/// Картинка для демо-режима (симулятор без камеры): «холодильник» из эмодзи.
struct DemoFridgeArtwork: View {
    private let rows = ["🍗🍅🧅", "🧀🥚🥒", "🥛🫑🍅"]

    var body: some View {
        VStack(spacing: 18) {
            ForEach(rows, id: \.self) { row in
                Text(verbatim: row)
                    .font(.system(size: 96))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 24))
            }
        }
        .padding(40)
        .frame(width: 600, height: 760)
        .background(
            LinearGradient(
                colors: [Color(red: 0.88, green: 0.94, blue: 0.98), Color(red: 0.75, green: 0.85, blue: 0.93)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
