import Observation
import UIKit

@MainActor
@Observable
final class FoodRecognitionViewModel {
    enum Phase: Equatable {
        case recognizing
        case failed(AppError)
        case done
    }

    private(set) var phase: Phase = .recognizing
    /// Небольшое превью для UI. Только в памяти, на диск не сохраняется.
    private(set) var thumbnail: UIImage?
    let ingredients: IngredientsViewModel

    /// Полноразмерное фото держим только до успешного распознавания.
    private var photo: UIImage?
    private let photoID: UUID
    private var hasStarted = false
    private let container: AppContainer

    init(container: AppContainer, photoID: UUID) {
        self.container = container
        self.photoID = photoID
        self.photo = container.router.photo(for: photoID)
        self.ingredients = IngredientsViewModel(container: container, mode: .recognized)
    }

    func startIfNeeded() async {
        guard !hasStarted else { return }
        hasStarted = true
        if thumbnail == nil, let photo {
            thumbnail = await ImageProcessor.downscaled(photo, maxDimension: 600)
        }
        await recognize()
    }

    func retry() async {
        await recognize()
    }

    private func recognize() async {
        guard let photo else {
            phase = .failed(.recognitionFailed)
            return
        }
        // Лимит мог закончиться, пока пользователь фотографировал (или при повторе).
        guard container.entitlements.canUse(feature: .scan) else {
            container.router.presentPaywall(.scansExhausted)
            phase = .failed(.recognitionFailed)
            return
        }
        phase = .recognizing
        container.analytics.track(.scanStarted)
        do {
            let foods = try await container.foodRecognition.recognizeFoods(from: photo)
            guard !foods.isEmpty else {
                container.analytics.track(.scanFailed(reason: "no_foods"))
                phase = .failed(.noFoodsFound)
                return
            }
            // Списываем только успешный скан.
            container.quota.consume()
            container.analytics.track(.scanCompleted(foodsCount: foods.count))
            ingredients.setRecognized(foods)
            releasePhoto()
            phase = .done
        } catch is CancellationError {
            // Пользователь ушёл с экрана — следующий заход начнёт заново.
            hasStarted = false
        } catch {
            let appError = AppError.from(error)
            container.analytics.track(.scanFailed(reason: "\(appError)"))
            phase = .failed(appError)
        }
    }

    /// Если AI не справился — пользователь может ввести продукты вручную.
    func continueManually() {
        releasePhoto()
        ingredients.switchToManual()
        phase = .done
        ingredients.isAddSheetPresented = true
    }

    private func releasePhoto() {
        photo = nil
        container.router.releasePhoto(photoID)
    }
}
