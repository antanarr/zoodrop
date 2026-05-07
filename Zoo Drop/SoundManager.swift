import AVFoundation
import SwiftUI

final class SoundManager: ObservableObject {
    private var players: [String: AVAudioPlayer] = [:]
    private var themePlayer: AVAudioPlayer?

    @AppStorage("soundEnabled") private var soundEnabled = true

    func playSound(named name: String, volume: Float = 1.0, loops: Int = 0) {
        guard soundEnabled else { return }
        guard let url = soundURL(for: name) else {
            print("SoundManager: Sound \(name) not found")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.numberOfLoops = loops
            players[name] = player
            player.play()
        } catch {
            print("SoundManager: Failed to play \(name): \(error.localizedDescription)")
        }
    }

    func playLightDropSound() {
        playSound(named: "drop", volume: 0.75)
    }

    func playHeavyDropSound() {
        playSound(named: "thud", volume: 0.9)
    }

    func playStandardMergeSound() {
        playSound(named: "pop1")
    }

    func playComboMergeSound() {
        playSound(named: "merge_combo")
    }

    func playGameOverSound() {
        playSound(named: "gameover")
    }

    func playTapSound() {
        playSound(named: "tap", volume: 0.65)
    }

    func playUnlockSound() {
        playSound(named: "unlock")
    }

    func playGoldenEggClaimedSound() {
        playSound(named: "egg_open")
    }

    func playEggOpenSound() {
        playSound(named: "egg_open")
    }

    func playSubscribeSound() {
        playSound(named: "subscribe")
    }

    func playMidMergeSound() {
        playSound(named: "pop2")
    }

    func playHighMergeSound() {
        playSound(named: "pop3")
    }

    func playReviveSound() {
        playSound(named: "revive")
    }

    func playAchievementSound() {
        playSound(named: "achievement")
    }

    func playAmbientLoop() {
        playSound(named: "ambientloop", volume: 0.35, loops: -1)
    }

    func playThemeMusic() {
        guard soundEnabled else { return }
        guard themePlayer?.isPlaying != true else { return }
        guard let url = soundURL(for: "zoo_theme") else { return }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.35
            player.numberOfLoops = -1
            themePlayer = player
            player.play()
        } catch {
            print("SoundManager: Failed to play theme: \(error.localizedDescription)")
        }
    }

    func stopThemeMusic() {
        themePlayer?.stop()
        themePlayer = nil
    }

    private func soundURL(for name: String) -> URL? {
        let baseName = (name as NSString).deletingPathExtension
        let explicitExtension = (name as NSString).pathExtension

        if !explicitExtension.isEmpty {
            return Bundle.main.url(forResource: baseName, withExtension: explicitExtension)
        }

        for fileExtension in ["mp3", "wav"] {
            if let url = Bundle.main.url(forResource: baseName, withExtension: fileExtension) {
                return url
            }
        }

        return nil
    }
}
