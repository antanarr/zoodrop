import Foundation
import SwiftUI
import Combine
import SpriteKit

@MainActor
class GameViewModel: ObservableObject, GameSceneDelegate {
    
    // Dependencies
    private let soundManager: SoundManager
    private let hapticManager: HapticManager
    private let gameCenterManager: GameCenterManager
    private let subscriptionManager: SubscriptionManager
    private let adManager: AdManager
    private let zooDexManager: ZooDexManager
    private let questManager: QuestManager
    weak var scene: GameScene?

    // Game State
    @Published var score: Int = 0
    @Published var isGameOver = false
    @Published var nextAnimalToDrop: Animal?
    @Published var recentlyUnlockedAnimal: Animal?
    @Published var lastFiveSecondsFrames: [SKTexture]? = nil
    
    @Published var droppableAnimals: [Animal] = []
    private var mergeCount = 0
    private var totalMergesThisGame = 0

    // --- Added properties for enhanced Game Over stats ---
    @Published var largestAnimalCreated: Animal?
    @Published var longestCombo: Int = 0

    // Aiming State
    @Published var isAiming = false
    @Published var dropPositionX: CGFloat = UIScreen.main.bounds.width / 2
    
    // --- UIUX-01: WIGGLE STATE ---
    // This property is bound to the ChuteView to trigger its wiggle animation.
    @Published var chuteIsWiggling = false
    
    @Published var canRevive = true

    @Published var comboActive: Bool = false

    @AppStorage("gameOverCount") private var gameOverCount = 0
    
    init(
        soundManager: SoundManager,
        hapticManager: HapticManager,
        gameCenterManager: GameCenterManager,
        subscriptionManager: SubscriptionManager,
        adManager: AdManager,
        zooDexManager: ZooDexManager,
        questManager: QuestManager
    ) {
        self.soundManager = soundManager
        self.hapticManager = hapticManager
        self.gameCenterManager = gameCenterManager
        self.subscriptionManager = subscriptionManager
        self.adManager = adManager
        self.zooDexManager = zooDexManager
        self.questManager = questManager
    }
    
    func aim(at location: CGPoint) {
        if !isAiming {
            // Play a light tap only when aiming begins.
            hapticManager.playLightTap()
        }
        isAiming = true
        let screenWidth = UIScreen.main.bounds.width
        let margin: CGFloat = 30
        dropPositionX = max(margin, min(screenWidth - margin, location.x))
    }
    
    private var dropCooldownActive = false

    func dropAnimal() {
        guard !dropCooldownActive, let animalToDrop = nextAnimalToDrop else { return }
        dropCooldownActive = true
        isAiming = false
        
        questManager.processEvent(type: .animalDropped(name: animalToDrop.name))
        
        // --- UIUX-01: TRIGGER WIGGLE AND SOUND/HAPTICS ---
        chuteIsWiggling = true // Trigger the animation.
        hapticManager.playDropImpact() // Play the drop haptic.
        
        // Play the correct drop sound based on the animal's mass.
        if animalToDrop.mass > 5.0 {
            soundManager.playHeavyDropSound()
        } else {
            soundManager.playLightDropSound()
        }
        
        scene?.addAnimal(animal: animalToDrop, atX: dropPositionX)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.prepareNextAnimal()
            self.dropCooldownActive = false
        }
    }
    
    private func prepareNextAnimal() {
        nextAnimalToDrop = droppableAnimals.randomElement()
    }

    func resetGame() {
        droppableAnimals = AnimalLibrary.startingAnimals
        prepareNextAnimal()
        score = 0
        isGameOver = false
        canRevive = true
        mergeCount = 0
        totalMergesThisGame = 0
        scene?.resetScene()
    }
    
    func reviveGame() {
        guard let rootVC = UIViewController.findRootViewController() else { return }
        adManager.showRewardedAd(from: rootVC) { [weak self] success in
            if success {
                self?.executeRevive()
            }
        }
    }

    private func executeRevive() {
        isGameOver = false
        canRevive = false
        scene?.clearTopAnimals()
    }
    
    // MARK: - GameSceneDelegate Implementation
    
    func gameScene(_ scene: GameScene, didTriggerGameOverWithFrames frames: [SKTexture]) {
        guard !isGameOver else { return }
        self.lastFiveSecondsFrames = frames
        self.soundManager.playGameOverSound()
        gameCenterManager.submitScore(score, to: .mainHighscore)
        gameCenterManager.submitScore(totalMergesThisGame, to: .totalMerges)

        self.gameOverCount += 1
        if self.gameOverCount % 3 == 0, let rootVC = UIViewController.findRootViewController() {
            adManager.showInterstitial(from: rootVC) {
                self.isGameOver = true
            }
        } else {
            self.isGameOver = true
        }
    }
    
    func gameScene(_ scene: GameScene, didMergeInitialAnimal animal: Animal, toCreate newAnimal: Animal, at position: CGPoint, combo: Int) {
        // --- UIUX-01: PLAY COMBO MERGE SOUND ---
        if combo > 2 {
            soundManager.playComboMergeSound()
        } else {
            soundManager.playStandardMergeSound()
        }

        let calculatedScore = Int(Double(newAnimal.scoreValue) * Double(combo))
        score += calculatedScore
        questManager.processEvent(type: .scoreAchieved(score))

        // --- Added tracking of largest animal created and longest combo ---
        if largestAnimalCreated == nil || newAnimal.mass > largestAnimalCreated?.mass ?? 0 {
            largestAnimalCreated = newAnimal
        }
        if combo > longestCombo {
            longestCombo = combo
        }

        comboActive = false
        DispatchQueue.main.async {
            self.comboActive = true
        }

        // Check if the newAnimal is newly unlocked and trigger popup if so
        if !zooDexManager.isUnlocked(newAnimal) {
            zooDexManager.unlock(newAnimal)
            self.recentlyUnlockedAnimal = newAnimal
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.recentlyUnlockedAnimal = nil
            }
        }

        scene.showScoreIndicator(at: position, amount: calculatedScore)
    }
    
    func gameSceneDidThump(_ scene: GameScene) {
        hapticManager.playThump()
    }

    func activateNudge() {
        if subscriptionManager.spendGoldenEgg(amount: AppMetrics.nudgeCostInGoldenEggs) {
            scene?.nudgeAnimals()
        }
    }

    func activateReroll() {
        if subscriptionManager.spendGoldenEgg(amount: AppMetrics.rerollCostInGoldenEggs) {
            prepareNextAnimal()
        }
    }
}
