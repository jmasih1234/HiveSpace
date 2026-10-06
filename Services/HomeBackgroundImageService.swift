import Foundation
import UIKit

enum HomeBackgroundImageService {
    private static let directoryName = "HomeBackground"
    private static let fileName = "home-hero-background.jpg"
    private static let maxImageDimension: CGFloat = 2_200

    static func loadImage() -> UIImage? {
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        return UIImage(data: data)
    }

    @discardableResult
    static func saveImageData(_ data: Data) throws -> UIImage {
        guard let image = UIImage(data: data) else {
            throw HomeBackgroundImageError.unsupportedImage
        }

        let preparedImage = image.scaledToFit(maxDimension: maxImageDimension)

        guard let jpegData = preparedImage.jpegData(compressionQuality: 0.88) else {
            throw HomeBackgroundImageError.encodingFailed
        }

        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        try jpegData.write(to: fileURL, options: [.atomic])

        return preparedImage
    }

    static func deleteImage() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    private static var directoryURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent(directoryName, isDirectory: true)
    }

    private static var fileURL: URL {
        directoryURL.appendingPathComponent(fileName)
    }
}

private enum HomeBackgroundImageError: Error {
    case unsupportedImage
    case encodingFailed
}

private extension UIImage {
    func scaledToFit(maxDimension: CGFloat) -> UIImage {
        let longestSide = max(size.width, size.height)

        guard longestSide > maxDimension else {
            return self
        }

        let scale = maxDimension / longestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
