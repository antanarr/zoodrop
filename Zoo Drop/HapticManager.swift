import UIKit

// UIUX-01: The HapticManager is expanded to provide a wider range of feedback types.
final class HapticManager: ObservableObject {

    // Generators are now more specific to provide different intensities.
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    init() {
        // Prepare all generators at once for responsiveness.
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        notificationGenerator.prepare()
    }

    // --- NEW: Light Tap ---
    /// Plays a very light tap, ideal for UI interactions like aiming.
    func playLightTap() {
        DispatchQueue.main.async {
            self.lightImpact.impactOccurred()
        }
    }
    
    // --- NEW: Medium Impact ---
    /// Plays a medium-intensity impact, suitable for the moment an animal is dropped.
    func playDropImpact() {
        DispatchQueue.main.async {
            self.mediumImpact.impactOccurred()
        }
    }

    /// Plays a heavy "thump" for significant impacts, like an animal landing hard or a big merge.
    func playThump() {
        DispatchQueue.main.async {
            self.heavyImpact.impactOccurred()
        }
    }

    /// Plays a success notification, perfect for unlocking animals or completing quests.
    func playSuccess() {
        DispatchQueue.main.async {
            self.notificationGenerator.notificationOccurred(.success)
        }
    }
    
    /// Plays an error notification for failed actions.
    func playError() {
        DispatchQueue.main.async {
            self.notificationGenerator.notificationOccurred(.error)
        }
    }
}
