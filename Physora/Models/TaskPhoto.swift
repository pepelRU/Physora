import Foundation
import UIKit

/// A compressed JPEG attached to a task. The image itself is never written to
/// logs or persisted without the user exporting a solution.
struct TaskPhoto: Identifiable {
    let id: UUID
    let data: Data

    init(id: UUID = UUID(), data: Data) {
        self.id = id
        self.data = data
    }

    var image: UIImage? {
        UIImage(data: data)
    }

    var byteCount: Int { data.count }

    @MainActor
    static func compressed(
        from rawData: Data,
        maximumDimension: CGFloat = 1_600,
        quality: CGFloat = 0.82
    ) -> TaskPhoto? {
        guard let image = UIImage(data: rawData) else { return nil }
        return compressed(from: image, maximumDimension: maximumDimension, quality: quality)
    }

    @MainActor
    static func compressed(
        from image: UIImage,
        maximumDimension: CGFloat = 1_600,
        quality: CGFloat = 0.82
    ) -> TaskPhoto? {
        let longestSide = max(image.size.width, image.size.height)
        let ratio = longestSide > maximumDimension ? maximumDimension / longestSide : 1
        let targetSize = CGSize(
            width: max(1, floor(image.size.width * ratio)),
            height: max(1, floor(image.size.height * ratio))
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let normalized = renderer.image { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: targetSize))
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        guard let data = normalized.jpegData(compressionQuality: quality),
              data.count <= 5_000_000 else {
            return nil
        }
        return TaskPhoto(data: data)
    }
}
