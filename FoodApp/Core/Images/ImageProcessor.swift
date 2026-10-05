import ImageIO
import UIKit

/// Работа с фото вне main thread: даунсэмплинг при загрузке и подготовка к отправке в AI.
enum ImageProcessor {
    /// Максимальная сторона изображения, отправляемого в AI. Больше не нужно для распознавания продуктов.
    static let uploadMaxDimension: CGFloat = 1024
    static let uploadQuality: CGFloat = 0.7

    /// Декодирует данные из Photos сразу в уменьшенном размере (не держим 48MP-фото в памяти).
    static func downsample(data: Data, maxDimension: CGFloat = 2048) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            let options = [kCGImageSourceShouldCache: false] as CFDictionary
            guard let source = CGImageSourceCreateWithData(data as CFData, options) else { return nil }
            let thumbnailOptions = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxDimension,
            ] as CFDictionary
            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else { return nil }
            return UIImage(cgImage: cgImage)
        }.value
    }

    /// Уменьшает и сжимает фото до JPEG для отправки на backend.
    static func prepareForUpload(_ image: UIImage) async -> Data? {
        await Task.detached(priority: .userInitiated) {
            resized(image, maxDimension: uploadMaxDimension).jpegData(compressionQuality: uploadQuality)
        }.value
    }

    /// Уменьшает снимок камеры в фоне (исходник 12–48 MP держать в памяти не нужно).
    static func downscaled(_ image: UIImage, maxDimension: CGFloat = 2048) async -> UIImage {
        await Task.detached(priority: .userInitiated) {
            resized(image, maxDimension: maxDimension)
        }.value
    }

    static func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension, longest > 0 else { return image }
        let scale = maxDimension / longest
        let target = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
