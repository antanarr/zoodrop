import Foundation
import SwiftUI
import AVFoundation
import UIKit

// UIUX-01: The SoundManager is updated with more specific sound-playing methods.
final class SoundManager: ObservableObject {
    
    private var players: [String: AVAudioPlayer] = [:]
    
    @AppStorage("soundEnabled") private var soundEnabled = true
    
    init() {}
    
    func playSound(named name: String, volume: Float = 1.0) {
        guard soundEnabled else { return }
        
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            print("🔊 SoundManager: Sound \(name).mp3 not found")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            players[name] = player // Keep a reference to prevent it from being deallocated mid-play
            player.play()
        } catch {
            print("🔊 SoundManager: Failed to play \(name) – \(error.localizedDescription)")
        }
    }
    
    // --- NEW: Differentiated Drop Sounds ---
    /// Plays a lighter sound for smaller animals.
    func playLightDropSound() {
        playSound(named: "sfx_drop_light", volume: 0.8)
    }
    
    /// Plays a heavier sound for larger animals.
    func playHeavyDropSound() {
        playSound(named: "sfx_drop_heavy", volume: 1.0)
    }
    
    // --- NEW: Differentiated Merge Sounds ---
    /// Plays the standard merge sound.
    func playStandardMergeSound() {
        playSound(named: "pop1")
    }
    
    /// Plays a more exciting sound for high combos.
    func playComboMergeSound() {
        playSound(named: "sfx_merge_combo")
    }
    
    func playGameOverSound() { playSound(named: "gameover") }
    func playTapSound() { playSound(named: "sfx_button_tap") }
    func playUnlockSound() { playSound(named: "unlock") }
    func playGoldenEggClaimedSound() { playSound(named: "egg_open") }

    // --- NEW: Merge Variations ---
    func playMidMergeSound() {
        playSound(named: "pop2")
    }

    func playHighMergeSound() {
        playSound(named: "pop3")
    }

    // --- NEW: Game Event Sounds ---
    func playReviveSound() {
        playSound(named: "revive")
    }

    func playAchievementSound() {
        playSound(named: "achievement")
    }

    // --- NEW: Background Audio ---
    func playAmbientLoop() {
        playSound(named: "ambientloop")
    }

    func playThemeMusic() {
        playSound(named: "zoo_theme")
    }
}
