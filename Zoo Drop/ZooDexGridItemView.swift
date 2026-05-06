import SwiftUI

struct ZooDexGridItemView: View {
    @EnvironmentObject var zooDexManager: ZooDexManager
    let animal: Animal

    var body: some View {
        VStack {
            if zooDexManager.isUnlocked(animal) {
                // --- UNLOCKED STATE ---
                unlockedView
            } else {
                // --- LOCKED STATE ---
                lockedView
            }
        }
        .frame(width: 120, height: 120)
        .background(animal.rarity.color.opacity(0.2))
        .cornerRadius(16)
        .shadow(radius: 3)
    }
    
    private var unlockedView: some View {
        VStack {
            Image(animal.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
            
            Text(animal.name)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
    
    private var lockedView: some View {
        ZStack {
            VStack {
                Image("locked_silhouette") // From AppImages.swift
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .opacity(0.3)

                if animal.unlockThreshold > 0 {
                    Text("Score: \(animal.unlockThreshold)")
                        .font(.subheadline)
                        .foregroundColor(.yellow)
                } else {
                    Text("???")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundColor(.black.opacity(0.4))
        }
    }
}


struct ZooDexGridItemView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = ZooDexManager()
        manager.unlock(AnimalLibrary.getAnimal(byName: "Monkey")!)
        return Group {
            HStack {
                ZooDexGridItemView(animal: AnimalLibrary.getAnimal(byName: "Monkey")!)
                ZooDexGridItemView(animal: AnimalLibrary.getAnimal(byName: "Lion")!)
            }
        }
        .environmentObject(manager)
    }
}
