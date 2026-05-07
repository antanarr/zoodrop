//
//  Zoo_DropTests.swift
//  Zoo DropTests
//
//  Created by Anthony Yarand on 7/3/25.
//

import Foundation
import XCTest
@testable import Zoo_Drop

final class ZooDropModelTests: XCTestCase {
    func testAnimalLibraryNormalMergeChainResolvesInOrder() {
        let expectedChain = [
            "Monkey",
            "Penguin",
            "Sloth",
            "Panda",
            "Giraffe",
            "Tiger",
            "Hippo",
            "Lion",
            "Elephant"
        ]

        let resolvedChain = followMergeChain(startingAt: "Monkey")

        XCTAssertEqual(resolvedChain.map(\.name), expectedChain)
        XCTAssertNil(resolvedChain.last?.mergeResult)
        XCTAssertEqual(resolvedChain.map(\.scoreValue), [10, 20, 40, 80, 160, 320, 640, 1280, 2560])
    }

    func testAnimalLibraryMergeResultsReferenceExistingAnimals() {
        let animalNames = Set(AnimalLibrary.allAnimals.map(\.name))

        for animal in AnimalLibrary.allAnimals {
            guard let mergeResult = animal.mergeResult else { continue }
            XCTAssertTrue(
                animalNames.contains(mergeResult),
                "\(animal.name) merges into missing animal \(mergeResult)"
            )
        }
    }

    func testAnimalLibrarySubscriberExclusivesAreOutsideNormalMergeChain() {
        let chainNames = Set(followMergeChain(startingAt: "Monkey").map(\.name))
        let exclusiveAnimals = AnimalLibrary.allAnimals.filter { $0.isSubscriberExclusive == true }

        XCTAssertEqual(exclusiveAnimals.map(\.rarity), [.mythical, .mythical])
        XCTAssertEqual(Set(exclusiveAnimals.map(\.name)), ["Celestial Lion", "Chromatic Panda"])
        XCTAssertTrue(exclusiveAnimals.allSatisfy { $0.mergeResult == nil })
        XCTAssertTrue(exclusiveAnimals.allSatisfy { !chainNames.contains($0.name) })
    }

    func testAnimalLibraryLookupIsExactAndStable() {
        XCTAssertEqual(AnimalLibrary.getAnimal(byName: "Tiger")?.ability, .pounce)
        XCTAssertEqual(AnimalLibrary.getAnimal(byName: "Lion")?.mergeResult, "Elephant")
        XCTAssertNil(AnimalLibrary.getAnimal(byName: "lion"))
        XCTAssertNil(AnimalLibrary.getAnimal(byName: "Missing Animal"))
    }

    func testQuestGoalReachedUsesProgressForEveryQuestType() {
        XCTAssertFalse(makeQuest(type: .reachScore(1_000), progress: 999).goalReached)
        XCTAssertTrue(makeQuest(type: .reachScore(1_000), progress: 1_000).goalReached)
        XCTAssertTrue(makeQuest(type: .reachScore(1_000), progress: 1_500).goalReached)

        XCTAssertFalse(makeQuest(type: .dropSpecificAnimal(name: "Panda", count: 5), progress: 4).goalReached)
        XCTAssertTrue(makeQuest(type: .dropSpecificAnimal(name: "Panda", count: 5), progress: 5).goalReached)

        XCTAssertFalse(makeQuest(type: .surviveDrops(10), progress: 9).goalReached)
        XCTAssertTrue(makeQuest(type: .surviveDrops(10), progress: 10).goalReached)
    }

    func testQuestCompletionFlagIsIndependentFromGoalReached() {
        let incompleteQuestAtGoal = makeQuest(type: .surviveDrops(3), progress: 3, isComplete: false)
        let completedQuestBelowGoal = makeQuest(type: .reachScore(500), progress: 100, isComplete: true)

        XCTAssertTrue(incompleteQuestAtGoal.goalReached)
        XCTAssertFalse(incompleteQuestAtGoal.isComplete)
        XCTAssertFalse(completedQuestBelowGoal.goalReached)
        XCTAssertTrue(completedQuestBelowGoal.isComplete)
    }

    func testQuestCodableRoundTripPreservesTypedGoalsAndProgress() throws {
        let quests = [
            makeQuest(type: .reachScore(2_000), progress: 750, isComplete: false),
            makeQuest(type: .dropSpecificAnimal(name: "Tiger", count: 2), progress: 2, isComplete: true),
            makeQuest(type: .surviveDrops(12), progress: 6, isComplete: false)
        ]

        let data = try JSONEncoder().encode(quests)
        let decodedQuests = try JSONDecoder().decode([Quest].self, from: data)

        XCTAssertEqual(decodedQuests.map(\.id), quests.map(\.id))
        XCTAssertEqual(decodedQuests.map(\.progress), quests.map(\.progress))
        XCTAssertEqual(decodedQuests.map(\.isComplete), quests.map(\.isComplete))
        XCTAssertTrue(decodedQuests[1].goalReached)

        guard case .dropSpecificAnimal(let animalName, let count) = decodedQuests[1].type else {
            return XCTFail("Expected dropSpecificAnimal quest after decoding")
        }

        XCTAssertEqual(animalName, "Tiger")
        XCTAssertEqual(count, 2)
    }

    func testModelCodableRoundTripPreservesAnimalMetadata() throws {
        let originalAnimal = try XCTUnwrap(AnimalLibrary.getAnimal(byName: "Celestial Lion"))

        let data = try JSONEncoder().encode(originalAnimal)
        let decodedAnimal = try JSONDecoder().decode(Animal.self, from: data)

        XCTAssertEqual(decodedAnimal.name, "Celestial Lion")
        XCTAssertEqual(decodedAnimal.rarity, .mythical)
        XCTAssertEqual(decodedAnimal.ability, .roar)
        XCTAssertEqual(decodedAnimal.cosmeticSkinID, "celestial_lion_skin")
        XCTAssertEqual(decodedAnimal.isSubscriberExclusive, true)
    }

    func testGameModeConfigurationExposesProgressionRules() {
        XCTAssertEqual(GameMode.allCases.map(\.displayName), ["Classic", "Daily Safari", "Timed Stampede", "Zen", "Challenge"])
        XCTAssertTrue(GameMode.dailySafari.usesDeterministicQueue)
        XCTAssertTrue(GameMode.challenge.usesDeterministicQueue)
        XCTAssertFalse(GameMode.zen.allowsGameOver)
        XCTAssertEqual(GameMode.timedStampede.timeLimit, AppMetrics.GameModes.timedStampedeDuration)
        XCTAssertGreaterThan(GameMode.timedStampede.scoreMultiplier, GameMode.classic.scoreMultiplier)
    }

    func testDailySafariQueueIsDeterministicForDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = Date(timeIntervalSince1970: 1_725_235_200)
        let seed = AnimalLibrary.dailySafariSeed(for: date, calendar: calendar)

        let firstQueue = AnimalLibrary.deterministicQueue(mode: .dailySafari, seed: seed, count: 18).map(\.name)
        let secondQueue = AnimalLibrary.deterministicQueue(mode: .dailySafari, seed: seed, count: 18).map(\.name)
        let nextDaySeed = AnimalLibrary.dailySafariSeed(for: date.addingTimeInterval(86_400), calendar: calendar)
        let nextDayQueue = AnimalLibrary.deterministicQueue(mode: .dailySafari, seed: nextDaySeed, count: 18).map(\.name)

        XCTAssertEqual(firstQueue, secondQueue)
        XCTAssertNotEqual(firstQueue, nextDayQueue)
        XCTAssertEqual(firstQueue[8], "Panda")
        XCTAssertEqual(firstQueue[17], "Panda")
    }

    func testProgressionMetricsTracksRunsTutorialAndChallenges() throws {
        let elephant = try XCTUnwrap(AnimalLibrary.getAnimal(byName: "Elephant"))
        var metrics = PlayerProgressionMetrics()

        metrics.recordDrop()
        metrics.recordMerge(score: 320, combo: 4, animal: elephant)
        metrics.recordRunFinished(mode: .challenge, score: 4_200, combo: 4)
        metrics.markTutorialStepComplete(.firstChallengeRun)
        metrics.recordChallengeCompletion(id: "test-challenge")

        XCTAssertEqual(metrics.lifetimeDrops, 1)
        XCTAssertEqual(metrics.lifetimeMerges, 1)
        XCTAssertEqual(metrics.lifetimeScore, 320)
        XCTAssertEqual(metrics.modeHighScores[.challenge], 4_200)
        XCTAssertTrue(metrics.completedTutorialSteps.contains(.firstChallengeRun))
        XCTAssertEqual(metrics.challengeCompletions["test-challenge"], 1)
        XCTAssertEqual(metrics.largestAnimalTier, AnimalLibrary.tierIndex(for: elephant))
    }

    func testSavedRunSnapshotCodableRoundTripPreservesResumeState() throws {
        let snapshot = SavedRunSnapshot(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!,
            createdAt: Date(timeIntervalSince1970: 100),
            mode: .dailySafari,
            score: 1_234,
            nextAnimalName: "Panda",
            queuedAnimalNames: ["Monkey", "Penguin", "Panda"],
            queueCursor: 2,
            droppableAnimalNames: ["Monkey", "Penguin", "Sloth", "Panda"],
            animalStates: [
                SavedRunAnimalState(animalName: "Monkey", x: 12, y: 34, rotation: 0.5, velocityDX: 1, velocityDY: -2, angularVelocity: 0.25)
            ],
            largestAnimalName: "Panda",
            longestCombo: 3,
            totalMerges: 4,
            drops: 5,
            canRevive: true,
            remainingTime: nil,
            challengeProgress: nil
        )

        let data = try JSONEncoder().encode(snapshot)
        let decodedSnapshot = try JSONDecoder().decode(SavedRunSnapshot.self, from: data)

        XCTAssertEqual(decodedSnapshot, snapshot)
        XCTAssertTrue(decodedSnapshot.isResumable)
        XCTAssertEqual(decodedSnapshot.animalStates.first?.animalName, "Monkey")
    }

    private func followMergeChain(startingAt name: String) -> [Animal] {
        var chain: [Animal] = []
        var nextName: String? = name

        while let currentName = nextName, let animal = AnimalLibrary.getAnimal(byName: currentName) {
            XCTAssertFalse(chain.contains { $0.name == animal.name }, "Merge chain loops at \(animal.name)")
            chain.append(animal)
            nextName = animal.mergeResult
        }

        return chain
    }

    private func makeQuest(
        type: QuestType,
        progress: Int,
        isComplete: Bool = false
    ) -> Quest {
        Quest(
            id: UUID().uuidString,
            title: "Test Quest",
            description: "A persistence-free quest fixture.",
            type: type,
            progress: progress,
            isComplete: isComplete,
            reward: 10
        )
    }
}
