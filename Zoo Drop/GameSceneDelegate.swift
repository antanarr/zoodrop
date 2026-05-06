import Foundation
import SpriteKit

// This protocol defines the contract for events that the GameScene communicates back to its owner.
// This decouples the scene from any specific ViewModel, making it more reusable and testable.
@MainActor
protocol GameSceneDelegate: AnyObject {
    /// Called when the conditions for game over have been met.
    /// - Parameters:
    ///   - scene: The scene where the event occurred.
    ///   - frames: The captured video frames for GIF sharing.
    func gameScene(_ scene: GameScene, didTriggerGameOverWithFrames frames: [SKTexture])
    
    /// Called when two animals have successfully merged.
    /// - Parameters:
    ///   - scene: The scene where the event occurred.
    ///   - animal: The initial animal that was merged.
    ///   - newAnimal: The new animal created as a result of the merge.
    ///   - position: The world-space position of the merge.
    ///   - combo: The current combo count at the time of the merge.
    func gameScene(_ scene: GameScene, didMergeInitialAnimal animal: Animal, toCreate newAnimal: Animal, at position: CGPoint, combo: Int)
    
    /// Called when a collision occurs that should produce a haptic thump.
    /// - Parameter scene: The scene where the event occurred.
    func gameSceneDidThump(_ scene: GameScene)
}
