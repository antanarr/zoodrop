import Foundation

struct AnimalLibrary {

    static let allAnimals: [Animal] = [
        Animal(id: UUID(), name: "Monkey", imageName: "monkey", rarity: .common, scoreValue: 10, mergeResult: "Penguin", ability: nil, cosmeticSkinID: nil, mass: 1.0, friction: 0.5, restitution: 0.3, isSubscriberExclusive: false),
        Animal(id: UUID(), name: "Penguin", imageName: "penguin", rarity: .common, scoreValue: 20, mergeResult: "Sloth", ability: nil, cosmeticSkinID: nil, mass: 1.2, friction: 0.4, restitution: 0.25, isSubscriberExclusive: false),
        Animal(id: UUID(), name: "Sloth", imageName: "sloth", rarity: .rare, scoreValue: 40, mergeResult: "Panda", ability: nil, cosmeticSkinID: nil, mass: 2.0, friction: 0.6, restitution: 0.2, isSubscriberExclusive: false),
        Animal(id: UUID(), name: "Panda", imageName: "panda", rarity: .rare, scoreValue: 80, mergeResult: "Giraffe", ability: nil, cosmeticSkinID: nil, mass: 3.5, friction: 0.7, restitution: 0.15, isSubscriberExclusive: false),
        Animal(id: UUID(), name: "Giraffe", imageName: "giraffe", rarity: .epic, scoreValue: 160, mergeResult: "Tiger", ability: nil, cosmeticSkinID: nil, mass: 4.5, friction: 0.8, restitution: 0.1, isSubscriberExclusive: false),
        Animal(id: UUID(), name: "Tiger", imageName: "tiger", rarity: .epic, scoreValue: 320, mergeResult: "Hippo", ability: .pounce, cosmeticSkinID: nil, mass: 6.0, friction: 0.8, restitution: 0.12, isSubscriberExclusive: false),
        Animal(id: UUID(), name: "Hippo", imageName: "hippo", rarity: .epic, scoreValue: 640, mergeResult: "Lion", ability: .heavyweight, cosmeticSkinID: nil, mass: 10.0, friction: 0.9, restitution: 0.05, isSubscriberExclusive: false),
        Animal(id: UUID(), name: "Lion", imageName: "lion", rarity: .legendary, scoreValue: 1280, mergeResult: "Elephant", ability: .roar, cosmeticSkinID: nil, mass: 8.0, friction: 0.85, restitution: 0.08, isSubscriberExclusive: false),
        Animal(id: UUID(), name: "Elephant", imageName: "elephant", rarity: .legendary, scoreValue: 2560, mergeResult: nil, ability: nil, cosmeticSkinID: nil, mass: 15.0, friction: 0.9, restitution: 0.05, isSubscriberExclusive: false),
        Animal(id: UUID(), name: "Celestial Lion", imageName: "lion_celestial", rarity: .mythical, scoreValue: 7500, mergeResult: nil, ability: .roar, cosmeticSkinID: "celestial_lion_skin", mass: 8.5, friction: 0.8, restitution: 0.1, isSubscriberExclusive: true),
        Animal(id: UUID(), name: "Chromatic Panda", imageName: "panda_chromatic", rarity: .mythical, scoreValue: 6000, mergeResult: nil, ability: nil, cosmeticSkinID: "chromatic_panda_skin", mass: 4.0, friction: 0.7, restitution: 0.15, isSubscriberExclusive: true)
    ]

    static let startingAnimals: [Animal] = ["Monkey", "Penguin", "Sloth"].compactMap { getAnimal(byName: $0) }

    static func getAnimal(byName name: String) -> Animal? {
        return allAnimals.first { $0.name == name }
    }

    static func animals(named names: [String]) -> [Animal] {
        names.compactMap { getAnimal(byName: $0) }
    }

    static func droppableAnimals(for mode: GameMode, score: Int = 0, isSubscribed: Bool = false) -> [Animal] {
        var animals = startingAnimals

        if score >= AppMetrics.GameModes.dailySafariUnlockScore || mode == .dailySafari {
            animals.append(contentsOf: ["Panda"].compactMap { getAnimal(byName: $0) })
        }

        if score >= AppMetrics.GameModes.challengeUnlockScore || mode == .challenge || mode == .timedStampede {
            animals.append(contentsOf: ["Giraffe"].compactMap { getAnimal(byName: $0) })
        }

        if isSubscribed {
            animals.append(contentsOf: allAnimals.filter { $0.isSubscriberExclusive == true })
        }

        var seen = Set<String>()
        return animals.filter { seen.insert($0.name).inserted }
    }

    static func deterministicQueue(
        mode: GameMode,
        seed: UInt64,
        count: Int = AppMetrics.GameModes.deterministicQueueLength,
        isSubscribed: Bool = false
    ) -> [Animal] {
        var generator = SeededRandomNumberGenerator(seed: seed)
        let source = droppableAnimals(for: mode, isSubscribed: isSubscribed)
        guard !source.isEmpty else { return [] }

        return (0..<count).compactMap { index in
            if mode == .dailySafari, index % 9 == 8, let safariFeature = getAnimal(byName: "Panda") {
                return safariFeature
            }
            if mode == .challenge, index % 11 == 10, let challengeFeature = getAnimal(byName: "Giraffe") {
                return challengeFeature
            }
            return source.randomElement(using: &generator)
        }
    }

    static func dailySafariSeed(for date: Date = Date(), calendar: Calendar = .current) -> UInt64 {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let seedText = "daily-\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
        return SeededRandomNumberGenerator.stableSeed(from: seedText)
    }

    static func challengeSeed(challengeID: String) -> UInt64 {
        SeededRandomNumberGenerator.stableSeed(from: "challenge-\(challengeID)")
    }

    static func tierIndex(for animal: Animal) -> Int {
        guard let index = normalMergeChain.firstIndex(where: { $0.name == animal.name }) else {
            return 0
        }
        return index + 1
    }

    static var normalMergeChain: [Animal] {
        var chain: [Animal] = []
        var nextName: String? = "Monkey"
        var visited = Set<String>()

        while let name = nextName,
              !visited.contains(name),
              let animal = getAnimal(byName: name) {
            visited.insert(name)
            chain.append(animal)
            nextName = animal.mergeResult
        }

        return chain
    }
}
