import Foundation

// Contains all static animal data for the game, now with unlock thresholds and exclusive content.
struct AnimalLibrary {

    static let allAnimals: [Animal] = [
        // Existing Animals (now with isSubscriberExclusive set to false or nil)
        Animal(id: UUID(), name: "Monkey", imageName: "monkey", rarity: .common, scoreValue: 10, mergeResult: "Penguin", ability: nil, cosmeticSkinID: nil, mass: 1.0, friction: 0.5, restitution: 0.3, isSubscriberExclusive: false),
        Animal(id: UUID(), name: "Penguin", imageName: "penguin", rarity: .common, scoreValue: 20, mergeResult: "Sloth", ability: nil, cosmeticSkinID: nil, mass: 1.2, friction: 0.4, restitution: 0.25, isSubscriberExclusive: false),
        Animal(id: UUID(), name: "Sloth", imageName: "sloth", rarity: .rare, scoreValue: 40, mergeResult: "Panda", ability: nil, cosmeticSkinID: nil, mass: 2.0, friction: 0.6, restitution: 0.2, isSubscriberExclusive: false),
        Animal(id: UUID(), name: "Panda", imageName: "panda", rarity: .rare, scoreValue: 80, mergeResult: "Giraffe", ability: nil, cosmeticSkinID: nil, mass: 3.5, friction: 0.7, restitution: 0.15, isSubscriberExclusive: false),
        Animal(id: UUID(), name: "Giraffe", imageName: "giraffe", rarity: .epic, scoreValue: 160, mergeResult: "Tiger", ability: nil, cosmeticSkinID: nil, mass: 4.5, friction: 0.8, restitution: 0.1, isSubscriberExclusive: false),
        Animal(id: UUID(), name: "Tiger", imageName: "tiger", rarity: .epic, scoreValue: 320, mergeResult: "Hippo", ability: .pounce, cosmeticSkinID: nil, mass: 6.0, friction: 0.8, restitution: 0.12, isSubscriberExclusive: false),
        Animal(id: UUID(), name: "Hippo", imageName: "hippo", rarity: .epic, scoreValue: 640, mergeResult: "Lion", ability: .heavyweight, cosmeticSkinID: nil, mass: 10.0, friction: 0.9, restitution: 0.05, isSubscriberExclusive: false),
        Animal(id: UUID(), name: "Lion", imageName: "lion", rarity: .legendary, scoreValue: 1280, mergeResult: "Elephant", ability: .roar, cosmeticSkinID: nil, mass: 8.0, friction: 0.85, restitution: 0.08, isSubscriberExclusive: false),
        Animal(id: UUID(), name: "Elephant", imageName: "elephant", rarity: .legendary, scoreValue: 2560, mergeResult: nil, ability: nil, cosmeticSkinID: nil, mass: 15.0, friction: 0.9, restitution: 0.05, isSubscriberExclusive: false),
        
        // --- MON-01 IMPLEMENTATION: EXCLUSIVE MYTHICAL ANIMALS ---
        // These animals are flagged as exclusive and have the new Mythical rarity.
        // They are not part of the normal merge chain.
        Animal(id: UUID(), name: "Celestial Lion", imageName: "lion_celestial", rarity: .mythical, scoreValue: 7500, mergeResult: nil, ability: .roar, cosmeticSkinID: "celestial_lion_skin", mass: 8.5, friction: 0.8, restitution: 0.1, isSubscriberExclusive: true),
        Animal(id: UUID(), name: "Chromatic Panda", imageName: "panda_chromatic", rarity: .mythical, scoreValue: 6000, mergeResult: nil, ability: nil, cosmeticSkinID: "chromatic_panda_skin", mass: 4.0, friction: 0.7, restitution: 0.15, isSubscriberExclusive: true)
        // NOTE: You will need to create the corresponding images: "lion_celestial.png" and "panda_chromatic.png"
        // --- END MON-01 IMPLEMENTATION ---
    ]

    static func getAnimal(byName name: String) -> Animal? {
        return allAnimals.first { $0.name == name }
    }
}
