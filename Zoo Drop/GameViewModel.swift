import Foundation
import SwiftUI
import SpriteKit

@MainActor
final class GameViewModel: ObservableObject, GameSceneDelegate {
    private let soundManager: SoundManager
    private let hapticManager: HapticManager
    private let gameCenterManager: GameCenterManager
    private let subscriptionManager: SubscriptionManager
    private let adManager: AdManager
    private let zooDexManager: ZooDexManager
    private let questManager: QuestManager

    weak var scene: GameScene?

    @Published var score = 0
    @Published var isGameOver = false
    @Published var nextAnimalToDrop: Animal?
    @Published var recentlyUnlockedAnimal: Animal?
    @Published var lastFiveSecondsFrames: [SKTexture]?
    @Published var largestAnimalCreated: Animal?
    @Published var longestCombo = 0
    @Published var isAiming = false
    @Published var dropPositionX: CGFloat = UIScreen.main.bounds.width / 2
    @Published var chuteIsWiggling = false
    @Published var canRevive = true
    @Published var comboActive = false
    @Published var droppableAnimals: [Animal] = AnimalLibrary.startingAnimals

    @AppStorage("gameOverCount") private var gameOverCount = 0
    @AppStorage("highScore") private var highScore = 0

    private var totalMergesThisGame = 0
    private var dropCooldownActive = false
    private var comboHideTask: Task<Void, Never>?

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
        prepareNextAnimal()
    }

    func attach(scene: GameScene) {
        self.scene = scene
        scene.gameDelegate = self
    }

    func aim(at location: CGPoint, playfieldWidth: CGFloat) {
        guard !isGameOver else { return }
        if !isAiming {
            hapticManager.playLightTap()
        }
        isAiming = true
        let margin: CGFloat = 34
        dropPositionX = max(margin, min(playfieldWidth - margin, location.x))
    }

    func cancelAim() {
        isAiming = false
    }

    func dropAnimal() {
        guard !dropCooldownActive, !isGameOver, let animalToDrop = nextAnimalToDrop else { return }

        dropCooldownActive = true
        isAiming = false
        questManager.processEvent(type: .animalDropped(name: animalToDrop.name))
        questManager.processEvent(type: .dropSurvived)
        chuteIsWiggling = true
        hapticManager.playDropImpact()

        if animalToDrop.mass > 5.0 {
            soundManager.playHeavyDropSound()
        } else {
            soundManager.playLightDropSound()
        }

        scene?.addAnimal(animal: animalToDrop, atX: dropPositionX)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
            self?.prepareNextAnimal()
            self?.dropCooldownActive = false
        }
    }

    func resetGame() {
        droppableAnimals = AnimalLibrary.startingAnimals
        score = 0
        isGameOver = false
        canRevive = true
        totalMergesThisGame = 0
        dropCooldownActive = false
        largestAnimalCreated = nil
        longestCombo = 0
        lastFiveSecondsFrames = nil
        recentlyUnlockedAnimal = nil
        comboHideTask?.cancel()
        comboActive = false
        prepareNextAnimal()
        scene?.resetScene()
    }

    func reviveGame() {
        guard canRevive else { return }

        if subscriptionManager.isSubscribed {
            executeRevive()
            return
        }

        guard let rootVC = UIViewController.findRootViewController() else {
            hapticManager.playError()
            return
        }
        adManager.showRewardedAd(from: rootVC) { [weak self] success in
            guard success else {
                self?.hapticManager.playError()
                return
            }
            self?.executeRevive()
        }
    }

    func activateNudge() {
        guard !isGameOver else { return }
        if subscriptionManager.spendGoldenEgg(amount: AppMetrics.nudgeCostInGoldenEggs) {
            scene?.nudgeAnimals()
            hapticManager.playSuccess()
        } else {
            hapticManager.playError()
        }
    }

    func activateReroll() {
        guard !isGameOver else { return }
        if subscriptionManager.spendGoldenEgg(amount: AppMetrics.rerollCostInGoldenEggs) {
            prepareNextAnimal()
            hapticManager.playSuccess()
        } else {
            hapticManager.playError()
        }
    }

    func gameScene(_ scene: GameScene, didTriggerGameOverWithFrames frames: [SKTexture]) {
        guard !isGameOver else { return }

        lastFiveSecondsFrames = frames
        soundManager.playGameOverSound()
        highScore = max(highScore, score)
        gameCenterManager.submitScore(score, to: .mainHighscore)
        gameCenterManager.submitScore(totalMergesThisGame, to: .totalMerges)
        if let largestAnimalCreated {
            gameCenterManager.submitScore(AnimalLibrary.tierIndex(for: largestAnimalCreated), to: .largestAnimal)
        }
        if score >= 10_000 {
            gameCenterManager.reportAchievement(id: .score10k, percentComplete: 100)
        }
        if score >= 50_000 {
            gameCenterManager.reportAchievement(id: .score50k, percentComplete: 100)
        }

        gameOverCount += 1
        isGameOver = true

        if !subscriptionManager.isSubscribed,
           gameOverCount % 3 == 0,
           let rootVC = UIViewController.findRootViewController() {
            adManager.showInterstitial(from: rootVC) {}
        } else {
            adManager.loadInterstitial()
        }
    }

    func gameScene(_ scene: GameScene, didMergeInitialAnimal animal: Animal, toCreate newAnimal: Animal, at position: CGPoint, combo: Int) {
        if combo > 2 {
            soundManager.playComboMergeSound()
        } else {
            soundManager.playStandardMergeSound()
        }

        totalMergesThisGame += 1
        let subscriptionBonus = subscriptionManager.isSubscribed ? 1.1 : 1.0
        let calculatedScore = max(1, Int(Double(newAnimal.scoreValue * combo) * subscriptionBonus))
        score += calculatedScore
        questManager.processEvent(type: .scoreAchieved(score))

        if largestAnimalCreated == nil || newAnimal.mass > (largestAnimalCreated?.mass ?? 0) {
            largestAnimalCreated = newAnimal
        }
        longestCombo = max(longestCombo, combo)

        reportAchievements(for: newAnimal)
        unlockAnimalsForProgress(newAnimal)

        comboHideTask?.cancel()
        comboActive = true
        comboHideTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 1_600_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            self?.comboActive = false
        }

        scene.showScoreIndicator(at: position, amount: calculatedScore)
    }

    func gameSceneDidThump(_ scene: GameScene) {
        hapticManager.playThump()
    }

    private func prepareNextAnimal() {
        nextAnimalToDrop = droppableAnimals.randomElement() ?? AnimalLibrary.getAnimal(byName: "Monkey")
    }

    private func executeRevive() {
        isGameOver = false
        canRevive = false
        scene?.clearTopAnimals()
        scene?.playReviveSound()
        soundManager.playReviveSound()
    }

    private func unlockAnimalsForProgress(_ mergedAnimal: Animal) {
        let unlockCandidates = AnimalLibrary.allAnimals.filter { animal in
            if animal.isSubscriberExclusive == true {
                return subscriptionManager.isSubscribed
            }
            return animal.scoreValue <= max(score, mergedAnimal.scoreValue)
        }

        for animal in unlockCandidates where !zooDexManager.isUnlocked(animal) {
            zooDexManager.unlock(animal)
            recentlyUnlockedAnimal = animal
            soundManager.playUnlockSound()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) { [weak self] in
                if self?.recentlyUnlockedAnimal?.id == animal.id {
                    self?.recentlyUnlockedAnimal = nil
                }
            }
        }
    }

    private func reportAchievements(for animal: Animal) {
        gameCenterManager.reportAchievement(id: .firstMerge, percentComplete: 100)

        switch animal.name {
        case "Panda":
            gameCenterManager.reportAchievement(id: .createdPanda, percentComplete: 100)
        case "Lion":
            gameCenterManager.reportAchievement(id: .createdLion, percentComplete: 100)
        default:
            break
        }
    }
}
