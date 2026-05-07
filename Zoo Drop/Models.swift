import Foundation
import CoreGraphics
import SwiftUI

enum Rarity: String, Codable, CaseIterable {
    case common, rare, epic, legendary, mythical
}

enum AnimalAbility: String, Codable {
    case roar, pounce, heavyweight, windGust
}

struct Animal: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let imageName: String
    let rarity: Rarity
    let scoreValue: Int
    let mergeResult: String?
    let ability: AnimalAbility?
    var cosmeticSkinID: String?

    let mass: CGFloat
    let friction: CGFloat
    let restitution: CGFloat
    
    let isSubscriberExclusive: Bool?

    var unlockThreshold: Int {
        max(0, scoreValue)
    }
}

extension Rarity {
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .yellow
        case .mythical: return Color(red: 0.4, green: 0.9, blue: 0.8)
        }
    }
}

extension AnimalAbility {
    var description: String {
        switch self {
        case .roar: return "King's Roar - Compacts animals below."
        case .pounce: return "Pounce - Lands with extra force."
        case .heavyweight: return "Heavyweight - Becomes an immovable anchor."
        case .windGust: return "Wind Gust - Pushes nearby animals sideways."
        }
    }
}
