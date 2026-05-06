import GoogleMobileAds
import UIKit

// 1. REMOVED SINGLETON: This class is now instantiated in Zoo_DropApp.
final class AdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    
    private var interstitial: InterstitialAd?
    // 2. RESTORED PRODUCTION ID: Using your provided production Ad Unit ID.
    private let interstitialAdUnitID = "ca-app-pub-8632219809769416/9900798870"

    private var interstitialDidDismissFullScreenContentBlock: (() -> Void)?
    private var lastInterstitialShowDate: Date?
    // 3. REDUCED COOLDOWN: Reduced from 120 to 60 seconds as per strategy.
    private let interstitialCooldown: TimeInterval = 60

    private var rewardedAd: RewardedAd?
    // 2. RESTORED PRODUCTION ID: Using your provided production Ad Unit ID.
    private let rewardedAdUnitID = "ca-app-pub-8632219809769416/1194127124"
    
    private var rewardedCompletion: ((Bool) -> Void)?
    
    // 4. PUBLIC INITIALIZER: The initializer is now public to allow instantiation.
    override init() {
        super.init()
    }
    
    func initializeAndLoadAds() {
        Task {
            loadInterstitial()
            loadRewardedAd()
        }
    }
    
    func loadInterstitial() {
        let request = Request()
        InterstitialAd.load(with: interstitialAdUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                return
            }
            self?.interstitial = ad
            self?.interstitial?.fullScreenContentDelegate = self
            print("✅ Interstitial ad loaded successfully")
        }
    }

    func loadRewardedAd() {
        let request = Request()
        RewardedAd.load(with: rewardedAdUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                print("Failed to load rewarded ad with error: \(error.localizedDescription)")
                return
            }
            self?.rewardedAd = ad
            self?.rewardedAd?.fullScreenContentDelegate = self
            print("✅ Rewarded ad loaded successfully")
        }
    }
    
    func showInterstitial(from rootViewController: UIViewController, completion: @escaping () -> Void) {
        let now = Date()
        if let lastShow = lastInterstitialShowDate, now.timeIntervalSince(lastShow) < interstitialCooldown {
            print("Interstitial skipped due to cooldown.")
            completion()
            return
        }

        if let ad = interstitial {
            interstitialDidDismissFullScreenContentBlock = completion
            ad.present(from: rootViewController)
            lastInterstitialShowDate = now
        } else {
            print("Ad wasn't ready")
            loadInterstitial() // Preload the next one
            completion()
        }
    }
    
    func showRewardedAd(from rootViewController: UIViewController, completion: @escaping (Bool) -> Void) {
        rewardedCompletion = completion
        if let ad = rewardedAd {
            ad.present(from: rootViewController) {
                // This block is called when the user has earned the reward.
                self.rewardedCompletion?(true)
                self.rewardedCompletion = nil
            }
        } else {
            print("Rewarded ad wasn't ready")
            loadRewardedAd() // Preload the next one
            completion(false)
        }
    }
    
    // MARK: - GADFullScreenContentDelegate
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        if ad is InterstitialAd {
            interstitialDidDismissFullScreenContentBlock?()
            interstitialDidDismissFullScreenContentBlock = nil
            loadInterstitial() // Preload the next one
        } else if ad is RewardedAd {
            // This is called when the ad is dismissed, regardless of reward.
            // The reward is handled in the completion handler of the `present` method.
            // If the user dismissed early, the completion handler might not have been called.
            // We ensure it's called with `false`.
            rewardedCompletion?(false)
            rewardedCompletion = nil
            loadRewardedAd() // Preload the next one
        }
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad failed to present with error: \(error.localizedDescription)")
        if ad is InterstitialAd {
            interstitialDidDismissFullScreenContentBlock?()
            interstitialDidDismissFullScreenContentBlock = nil
            loadInterstitial()
        } else if ad is RewardedAd {
            rewardedCompletion?(false)
            rewardedCompletion = nil
            loadRewardedAd()
        }
    }
}
