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
    @Published private(set) var gameMode: GameMode = .classic
    @Published private(set) var progressionMetrics = PlayerProgressionMetrics()
    @Published private(set) var savedRunSnapshot: SavedRunSnapshot?
    @Published private(set) var challengeProgress: ChallengeProgress?
    @Published private(set) var remainingTime: TimeInterval?
    @Published private(set) var upcomingQueuePreview: [Animal] = []
    @Published var lastEarnedAchievement: GameplayAchievementID?

    @AppStorage("gameOverCount") private var gameOverCount = 0
    @AppStorage("highScore") private var highScore = 0

    private let progressionMetricsKey = "playerProgressionMetrics"
    private let savedRunSnapshotKey = "savedRunSnapshot"

    private var totalMergesThisGame = 0
    private var dropsThisGame = 0
    private var dropCooldownActive = false
    private var comboHideTask: Task<Void, Never>?
    private var modeTimerTask: Task<Void, Never>?
    private var deterministicQueue: [Animal] = []
    private var queueCursor = 0
    private var currentChallengeID: String?
    private var runID = UUID()
    private var pendingSceneRestore: [SavedRunAnimalState]?

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
        progressionMetrics = loadProgressionMetrics()
        savedRunSnapshot = loadSavedRunSnapshot()
        configureRun(mode: .classic, challengeID: nil, date: Date(), clearSnapshot: false)
    }

    func attach(scene: GameScene) {
        self.scene = scene
        scene.gameDelegate = self
        scene.configure(mode: gameMode)
        if let pendingSceneRestore {
            scene.restoreAnimalStates(pendingSceneRestore)
            self.pendingSceneRestore = nil
        }
    }

    func startNewRun(mode: GameMode, challengeID: String? = nil, date: Date = Date()) {
        configureRun(mode: mode, challengeID: challengeID, date: date, clearSnapshot: true)
        questManager.processEvent(type: .modePlayed(mode))
        if let tutorialStep = runStartTutorialStep(for: mode) {
            markTutorialStepComplete(tutorialStep)
        }
    }

    func resetGame() {
        configureRun(mode: gameMode, challengeID: currentChallengeID, date: Date(), clearSnapshot: true)
    }

    func aim(at location: CGPoint, playfieldWidth: CGFloat) {
        guard !isGameOver else { return }
        if !isAiming {
            hapticManager.playLightTap()
            markTutorialStepComplete(.firstAim)
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
        dropsThisGame += 1
        progressionMetrics.recordDrop()
        saveProgressionMetrics()
        markTutorialStepComplete(.firstDrop)
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
        unlockLocalAchievements()
        persistRunSnapshot()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
            self?.prepareNextAnimal()
            self?.dropCooldownActive = false
            self?.persistRunSnapshot()
        }
    }

    func reviveGame() {
        guard canRevive, gameMode.allowsGameOver else { return }

        if subscriptionManager.hasAdFreeEntitlement {
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
            markTutorialStepComplete(.firstPowerUp)
            hapticManager.playSuccess()
            persistRunSnapshot()
        } else {
            hapticManager.playError()
        }
    }

    func activateReroll() {
        guard !isGameOver else { return }
        if subscriptionManager.spendGoldenEgg(amount: AppMetrics.rerollCostInGoldenEggs) {
            prepareNextAnimal()
            markTutorialStepComplete(.firstPowerUp)
            hapticManager.playSuccess()
            persistRunSnapshot()
        } else {
            hapticManager.playError()
        }
    }

    @discardableResult
    func resumeSavedRun(_ snapshot: SavedRunSnapshot? = nil) -> Bool {
        guard let snapshot = snapshot ?? savedRunSnapshot ?? loadSavedRunSnapshot(),
              snapshot.isResumable else {
            return false
        }

        modeTimerTask?.cancel()
        runID = snapshot.id
        gameMode = snapshot.mode
        score = snapshot.score
        isGameOver = false
        nextAnimalToDrop = snapshot.nextAnimalName.flatMap { AnimalLibrary.getAnimal(byName: $0) }
        droppableAnimals = AnimalLibrary.animals(named: snapshot.droppableAnimalNames)
        deterministicQueue = AnimalLibrary.animals(named: snapshot.queuedAnimalNames)
        queueCursor = snapshot.queueCursor
        largestAnimalCreated = snapshot.largestAnimalName.flatMap { AnimalLibrary.getAnimal(byName: $0) }
        longestCombo = snapshot.longestCombo
        totalMergesThisGame = snapshot.totalMerges
        dropsThisGame = snapshot.drops
        canRevive = snapshot.canRevive
        remainingTime = snapshot.remainingTime
        challengeProgress = snapshot.challengeProgress
        currentChallengeID = snapshot.challengeProgress?.challengeID
        lastFiveSecondsFrames = nil
        recentlyUnlockedAnimal = nil
        comboActive = false
        updateQueuePreview()

        if nextAnimalToDrop == nil {
            prepareNextAnimal()
        }

        scene?.configure(mode: gameMode)
        if let scene {
            scene.restoreAnimalStates(snapshot.animalStates)
        } else {
            pendingSceneRestore = snapshot.animalStates
        }

        startModeTimerIfNeeded(resumingWith: snapshot.remainingTime)
        persistRunSnapshot()
        return true
    }

    @discardableResult
    func persistRunSnapshot() -> SavedRunSnapshot {
        let snapshot = makeRunSnapshot()
        savedRunSnapshot = snapshot

        if let encodedSnapshot = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(encodedSnapshot, forKey: savedRunSnapshotKey)
        }
        return snapshot
    }

    func clearSavedRunSnapshot() {
        savedRunSnapshot = nil
        UserDefaults.standard.removeObject(forKey: savedRunSnapshotKey)
    }

    func markTutorialStepComplete(_ step: TutorialStep) {
        guard !progressionMetrics.completedTutorialSteps.contains(step) else { return }
        progressionMetrics.markTutorialStepComplete(step)
        saveProgressionMetrics()
        questManager.processEvent(type: .tutorialStepCompleted(step))
    }

    func isTutorialStepComplete(_ step: TutorialStep) -> Bool {
        progressionMetrics.completedTutorialSteps.contains(step)
    }

    func gameScene(_ scene: GameScene, didTriggerGameOverWithFrames frames: [SKTexture]) {
        finishRunAsGameOver(frames: frames)
    }

    func gameScene(_ scene: GameScene, didMergeInitialAnimal animal: Animal, toCreate newAnimal: Animal, at position: CGPoint, combo: Int) {
        if combo > 2 {
            soundManager.playComboMergeSound()
        } else {
            soundManager.playStandardMergeSound()
        }

        totalMergesThisGame += 1
        let modeBonus = gameMode.scoreMultiplier
        let calculatedScore = max(1, Int(Double(newAnimal.scoreValue * combo) * modeBonus))
        score += calculatedScore
        progressionMetrics.recordMerge(score: calculatedScore, combo: combo, animal: newAnimal)
        saveProgressionMetrics()

        questManager.processEvent(type: .scoreAchieved(score))
        questManager.processEvent(type: .animalMerged(from: animal.name, into: newAnimal.name, combo: combo, mode: gameMode))
        questManager.processEvent(type: .rarityCreated(newAnimal.rarity))
        if combo >= 3 {
            questManager.processEvent(type: .comboReached(combo))
            markTutorialStepComplete(.firstCombo)
        }

        if largestAnimalCreated == nil || newAnimal.mass > (largestAnimalCreated?.mass ?? 0) {
            largestAnimalCreated = newAnimal
        }
        longestCombo = max(longestCombo, combo)
        let wasChallengeComplete = challengeProgress?.isComplete ?? false
        challengeProgress?.record(score: score, merges: totalMergesThisGame, combo: longestCombo)

        markTutorialStepComplete(.firstMerge)
        reportAchievements(for: newAnimal)
        unlockLocalAchievements(createdAnimal: newAnimal)
        unlockAnimalsForProgress(newAnimal)

        if gameMode == .challenge,
           !wasChallengeComplete,
           challengeProgress?.isComplete == true,
           let challengeID = challengeProgress?.challengeID {
            progressionMetrics.recordChallengeCompletion(id: challengeID)
            unlockLocalAchievement(.challengeClear)
            questManager.processEvent(type: .challengeCompleted(id: challengeID, score: score))
            saveProgressionMetrics()
        }

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
        persistRunSnapshot()
    }

    func gameSceneDidThump(_ scene: GameScene) {
        hapticManager.playThump()
    }

    private func configureRun(mode: GameMode, challengeID: String?, date: Date, clearSnapshot: Bool) {
        modeTimerTask?.cancel()
        comboHideTask?.cancel()
        runID = UUID()
        gameMode = mode
        currentChallengeID = challengeID
        droppableAnimals = AnimalLibrary.droppableAnimals(for: mode, isSubscribed: subscriptionManager.isSubscribed)
        deterministicQueue = queue(for: mode, challengeID: challengeID, date: date)
        queueCursor = 0
        score = 0
        isGameOver = false
        canRevive = mode.allowsGameOver
        totalMergesThisGame = 0
        dropsThisGame = 0
        dropCooldownActive = false
        largestAnimalCreated = nil
        longestCombo = 0
        lastFiveSecondsFrames = nil
        recentlyUnlockedAnimal = nil
        comboActive = false
        challengeProgress = mode == .challenge ? ChallengeProgress(challengeID: challengeID ?? "default") : nil
        remainingTime = mode.timeLimit
        scene?.configure(mode: mode)
        scene?.resetScene()
        pendingSceneRestore = nil
        prepareNextAnimal()
        startModeTimerIfNeeded(resumingWith: remainingTime)
        if clearSnapshot {
            clearSavedRunSnapshot()
        }
    }

    private func queue(for mode: GameMode, challengeID: String?, date: Date) -> [Animal] {
        guard mode.usesDeterministicQueue else { return [] }
        let seed: UInt64
        switch mode {
        case .dailySafari:
            seed = AnimalLibrary.dailySafariSeed(for: date)
        case .challenge:
            seed = AnimalLibrary.challengeSeed(challengeID: challengeID ?? "default")
        case .classic, .timedStampede, .zen:
            seed = 0
        }
        return AnimalLibrary.deterministicQueue(mode: mode, seed: seed, isSubscribed: subscriptionManager.isSubscribed)
    }

    private func prepareNextAnimal() {
        if deterministicQueue.isEmpty {
            nextAnimalToDrop = droppableAnimals.randomElement() ?? AnimalLibrary.getAnimal(byName: "Monkey")
        } else {
            if queueCursor >= deterministicQueue.count {
                queueCursor = 0
            }
            nextAnimalToDrop = deterministicQueue[queueCursor]
            queueCursor += 1
        }
        updateQueuePreview()
    }

    private func updateQueuePreview() {
        guard !deterministicQueue.isEmpty else {
            upcomingQueuePreview = []
            return
        }
        upcomingQueuePreview = (0..<5).map { offset in
            deterministicQueue[(queueCursor + offset) % deterministicQueue.count]
        }
    }

    private func executeRevive() {
        isGameOver = false
        canRevive = false
        markTutorialStepComplete(.firstRevive)
        scene?.clearTopAnimals()
        scene?.playReviveSound()
        soundManager.playReviveSound()
        persistRunSnapshot()
    }

    private func finishRunAsGameOver(frames: [SKTexture]) {
        guard !isGameOver else { return }

        lastFiveSecondsFrames = frames
        soundManager.playGameOverSound()
        highScore = max(highScore, score)
        progressionMetrics.recordRunFinished(mode: gameMode, score: score, combo: longestCombo)
        saveProgressionMetrics()
        questManager.processEvent(type: .runFinished(mode: gameMode, score: score, drops: dropsThisGame, merges: totalMergesThisGame))
        gameCenterManager.submitScore(score, to: .mainHighscore)
        gameCenterManager.submitScore(totalMergesThisGame, to: .totalMerges)
        if let largestAnimalCreated {
            gameCenterManager.submitScore(AnimalLibrary.tierIndex(for: largestAnimalCreated), to: .largestAnimal)
        }
        reportScoreAchievements()
        unlockLocalAchievements()
        clearSavedRunSnapshot()

        gameOverCount += 1
        isGameOver = true
        modeTimerTask?.cancel()

        if subscriptionManager.shouldShowAds,
           gameMode.allowsGameOver,
           gameOverCount % 3 == 0,
           let rootVC = UIViewController.findRootViewController() {
            adManager.showInterstitial(from: rootVC) {}
        } else {
            adManager.loadInterstitial()
        }
    }

    private func startModeTimerIfNeeded(resumingWith remaining: TimeInterval?) {
        modeTimerTask?.cancel()
        guard gameMode == .timedStampede else {
            remainingTime = nil
            return
        }

        remainingTime = remaining ?? gameMode.timeLimit
        modeTimerTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    return
                }
                guard let self, !self.isGameOver else { return }
                let nextValue = max(0, (self.remainingTime ?? 0) - 1)
                self.remainingTime = nextValue
                self.persistRunSnapshot()
                if nextValue <= 0 {
                    self.finishRunAsGameOver(frames: [])
                    return
                }
            }
        }
    }

    private func makeRunSnapshot() -> SavedRunSnapshot {
        SavedRunSnapshot(
            id: runID,
            createdAt: Date(),
            mode: gameMode,
            score: score,
            nextAnimalName: nextAnimalToDrop?.name,
            queuedAnimalNames: deterministicQueue.map(\.name),
            queueCursor: queueCursor,
            droppableAnimalNames: droppableAnimals.map(\.name),
            animalStates: scene?.snapshotAnimalStates() ?? pendingSceneRestore ?? [],
            largestAnimalName: largestAnimalCreated?.name,
            longestCombo: longestCombo,
            totalMerges: totalMergesThisGame,
            drops: dropsThisGame,
            canRevive: canRevive,
            remainingTime: remainingTime,
            challengeProgress: challengeProgress
        )
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

        reportScoreAchievements()
    }

    private func reportScoreAchievements() {
        gameCenterManager.reportAchievement(id: .score10k, percentComplete: min(100, Double(score) / 100))
        gameCenterManager.reportAchievement(id: .score50k, percentComplete: min(100, Double(score) / 500))
    }

    private func unlockLocalAchievements(createdAnimal: Animal? = nil) {
        if progressionMetrics.lifetimeDrops > 0 {
            unlockLocalAchievement(.firstDrop)
        }
        if longestCombo >= 3 {
            unlockLocalAchievement(.firstCombo)
        }
        if longestCombo >= 6 {
            unlockLocalAchievement(.chainMaster)
        }
        if score >= 10_000 {
            unlockLocalAchievement(.scoreClimber)
        }
        if score >= 50_000 {
            unlockLocalAchievement(.scoreChampion)
        }
        if createdAnimal?.name == "Elephant" || largestAnimalCreated?.name == "Elephant" {
            unlockLocalAchievement(.elephantKeeper)
        }

        switch gameMode {
        case .dailySafari:
            unlockLocalAchievement(.dailyExplorer)
        case .timedStampede where dropsThisGame >= 20:
            unlockLocalAchievement(.stampedeRunner)
        case .zen where dropsThisGame >= 30:
            unlockLocalAchievement(.zenKeeper)
        case .challenge where challengeProgress?.isComplete == true:
            unlockLocalAchievement(.challengeClear)
        case .classic, .timedStampede, .zen, .challenge:
            break
        }
    }

    private func unlockLocalAchievement(_ achievement: GameplayAchievementID) {
        guard !progressionMetrics.unlockedAchievements.contains(achievement) else { return }
        progressionMetrics.unlockedAchievements.insert(achievement)
        lastEarnedAchievement = achievement
        soundManager.playAchievementSound()
        saveProgressionMetrics()
    }

    private func runStartTutorialStep(for mode: GameMode) -> TutorialStep? {
        switch mode {
        case .classic:
            return nil
        case .dailySafari:
            return .firstDailyRun
        case .timedStampede:
            return .firstTimedRun
        case .zen:
            return .firstZenRun
        case .challenge:
            return .firstChallengeRun
        }
    }

    private func saveProgressionMetrics() {
        if let encodedMetrics = try? JSONEncoder().encode(progressionMetrics) {
            UserDefaults.standard.set(encodedMetrics, forKey: progressionMetricsKey)
        }
    }

    private func loadProgressionMetrics() -> PlayerProgressionMetrics {
        guard let data = UserDefaults.standard.data(forKey: progressionMetricsKey),
              let decodedMetrics = try? JSONDecoder().decode(PlayerProgressionMetrics.self, from: data) else {
            return PlayerProgressionMetrics()
        }
        return decodedMetrics
    }

    private func loadSavedRunSnapshot() -> SavedRunSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: savedRunSnapshotKey),
              let decodedSnapshot = try? JSONDecoder().decode(SavedRunSnapshot.self, from: data) else {
            return nil
        }
        return decodedSnapshot
    }
}
