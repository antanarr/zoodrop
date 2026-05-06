import Foundation
import CoreGraphics
import SwiftUI

// 1. ADDED MYTHICAL RARITY: A new, higher tier for exclusive animals.
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
    
    
    // 2. ADDED EXCLUSIVITY FLAG: This flag identifies subscriber-only content.
    let isSubscriberExclusive: Bool?
}

extension Rarity {
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .yellow
        // 3. ADDED MYTHICAL COLOR: A distinct color for the new rarity.
        case .mythical: return Color(red: 0.4, green: 0.9, blue: 0.8) // A shimmering cyan/teal
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
