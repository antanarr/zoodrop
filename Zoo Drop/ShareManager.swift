import UIKit
import SwiftUI
import SpriteKit
import ImageIO
import UniformTypeIdentifiers // FIX: Import for modern UTType

// VIR-01: The ShareManager is completely overhauled to support GIF creation and sharing.
// It remains an ObservableObject to align with the project's dependency injection pattern.
final class ShareManager: ObservableObject {

    init() {}

    /// Creates an animated GIF from an array of SKTextures and presents a share sheet.
    /// This is the primary method for sharing gameplay moments.
    /// - Parameters:
    ///   - frames: An array of SKTexture objects captured from the game scene.
    ///   - text: The default text to accompany the shared GIF.
    ///   - viewController: The UIViewController from which to present the share sheet.
    ///   - completion: An optional closure to call when the share sheet is dismissed.
    func shareGIF(frames: [SKTexture], text: String, from viewController: UIViewController, completion: (() -> Void)? = nil) {
        // GIF creation can be slow; perform it on a background thread to keep the UI responsive.
        DispatchQueue.global(qos: .userInitiated).async {
            // Convert SKTextures to UIImages. This is the most resource-intensive step.
            let images = self.convert(textures: frames)
            
            // Generate the GIF file at a temporary URL. The frame delay of 0.05 creates a 20 FPS GIF.
            guard let gifURL = self.createGIF(from: images, with: 0.05) else {
                print("❌ ShareManager: Failed to create GIF.")
                // Fallback to sharing just text if GIF creation fails.
                DispatchQueue.main.async {
                    self.shareText(text, from: viewController, completion: completion)
                }
                return
            }

            // Once the GIF is ready, present the share sheet on the main thread.
            DispatchQueue.main.async {
                let activityVC = UIActivityViewController(activityItems: [gifURL, text], applicationActivities: nil)
                activityVC.completionWithItemsHandler = { _, _, _, _ in completion?() }
                viewController.present(activityVC, animated: true)
            }
        }
    }

    /// Fallback method to share only a string of text.
    func shareText(_ text: String, from viewController: UIViewController, completion: (() -> Void)? = nil) {
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        activityVC.completionWithItemsHandler = { _, _, _, _ in completion?() }
        viewController.present(activityVC, animated: true)
    }

    /// Converts an array of SKTexture objects into an array of UIImages.
    /// FIX: This now correctly converts an SKTexture to a UIImage by accessing its underlying CGImage.
    private func convert(textures: [SKTexture]) -> [UIImage] {
        return textures.map { UIImage(cgImage: $0.cgImage()) }
    }

    /// Creates an animated GIF from an array of images.
    /// - Parameters:
    ///   - images: The array of UIImages to encode into the GIF.
    ///   - frameDelay: The duration each frame should be displayed.
    /// - Returns: A URL pointing to the temporary GIF file, or nil on failure.
    private func createGIF(from images: [UIImage], with frameDelay: TimeInterval) -> URL? {
        // Create a unique temporary URL for the GIF file.
        let temporaryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("zoodrop_share.gif")

        // Get a CGImageDestination for the URL, specifying GIF as the type.
        // FIX: Replaced deprecated kUTTypeGIF with the modern UTType.gif.identifier.
        guard let destination = CGImageDestinationCreateWithURL(temporaryURL as CFURL, UTType.gif.identifier as CFString, images.count, nil) else {
            return nil
        }

        // Set the GIF properties, such as loop count (0 means infinite loop).
        let fileProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]]
        CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)

        // Set the properties for each frame, primarily the delay time.
        let frameProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: frameDelay]]

        // Add each image to the GIF destination.
        for image in images {
            if let cgImage = image.cgImage {
                CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
            }
        }

        // Finalize the GIF creation. If this fails, the file is incomplete.
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return temporaryURL
    }
}
