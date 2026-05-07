import GoogleMobileAds
import UIKit
import UserMessagingPlatform

final class AdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    @Published private(set) var isInitialized = false
    @Published private(set) var canRequestAds = false
    @Published private(set) var privacyOptionsRequired = false

    private var interstitial: InterstitialAd?
    private var rewardedAd: RewardedAd?
    private var interstitialDidDismissFullScreenContentBlock: (() -> Void)?
    private var rewardedCompletion: ((Bool) -> Void)?
    private var lastInterstitialShowDate: Date?
    private let interstitialCooldown: TimeInterval = 75
    private var shouldServeAds = false
    private var lastKnownAdFreeEntitlement = false

    #if DEBUG
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    private let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    #else
    private let interstitialAdUnitID = "ca-app-pub-8632219809769416/9900798870"
    private let rewardedAdUnitID = "ca-app-pub-8632219809769416/1194127124"
    #endif

    func configureAdsIfAllowed(hasAdFreeEntitlement: Bool) {
        lastKnownAdFreeEntitlement = hasAdFreeEntitlement

        guard !hasAdFreeEntitlement,
              !ProcessInfo.processInfo.arguments.contains("UITEST_MODE") else {
            disableAds()
            return
        }

        shouldServeAds = true

        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = false

        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    print("AdManager: consent info update failed: \(error.localizedDescription)")
                }

                self?.privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
                ConsentForm.loadAndPresentIfRequired(from: UIViewController.findRootViewController()) { formError in
                    DispatchQueue.main.async {
                        if let formError {
                            print("AdManager: consent form failed: \(formError.localizedDescription)")
                        }

                        self?.privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
                        self?.startAdsIfAllowed()
                    }
                }
            }
        }
    }

    func loadInterstitial() {
        guard isInitialized, canRequestAds, shouldServeAds else { return }
        InterstitialAd.load(with: interstitialAdUnitID, request: adRequest()) { [weak self] ad, error in
            if let error {
                print("Failed to load interstitial ad: \(error.localizedDescription)")
                return
            }
            self?.interstitial = ad
            self?.interstitial?.fullScreenContentDelegate = self
        }
    }

    func loadRewardedAd() {
        guard isInitialized, canRequestAds, shouldServeAds else { return }
        RewardedAd.load(with: rewardedAdUnitID, request: adRequest()) { [weak self] ad, error in
            if let error {
                print("Failed to load rewarded ad: \(error.localizedDescription)")
                return
            }
            self?.rewardedAd = ad
            self?.rewardedAd?.fullScreenContentDelegate = self
        }
    }

    func showInterstitial(from rootViewController: UIViewController, completion: @escaping () -> Void) {
        guard shouldServeAds, canRequestAds else {
            completion()
            return
        }

        let now = Date()
        if let lastShow = lastInterstitialShowDate, now.timeIntervalSince(lastShow) < interstitialCooldown {
            completion()
            return
        }

        guard let ad = interstitial else {
            loadInterstitial()
            completion()
            return
        }

        interstitialDidDismissFullScreenContentBlock = completion
        lastInterstitialShowDate = now
        ad.present(from: rootViewController)
    }

    func showRewardedAd(from rootViewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard shouldServeAds, canRequestAds else {
            completion(false)
            return
        }

        rewardedCompletion = completion
        guard let ad = rewardedAd else {
            loadRewardedAd()
            completion(false)
            return
        }

        ad.present(from: rootViewController) { [weak self] in
            self?.rewardedCompletion?(true)
            self?.rewardedCompletion = nil
        }
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        if ad is InterstitialAd {
            interstitialDidDismissFullScreenContentBlock?()
            interstitialDidDismissFullScreenContentBlock = nil
            interstitial = nil
            loadInterstitial()
        } else if ad is RewardedAd {
            rewardedCompletion?(false)
            rewardedCompletion = nil
            rewardedAd = nil
            loadRewardedAd()
        }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad failed to present: \(error.localizedDescription)")
        if ad is InterstitialAd {
            interstitialDidDismissFullScreenContentBlock?()
            interstitialDidDismissFullScreenContentBlock = nil
            interstitial = nil
            loadInterstitial()
        } else if ad is RewardedAd {
            rewardedCompletion?(false)
            rewardedCompletion = nil
            rewardedAd = nil
            loadRewardedAd()
        }
    }

    func presentPrivacyOptions() {
        ConsentForm.presentPrivacyOptionsForm(from: UIViewController.findRootViewController()) { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    print("AdManager: privacy options unavailable: \(error.localizedDescription)")
                }
                self?.configureAdsIfAllowed(hasAdFreeEntitlement: self?.lastKnownAdFreeEntitlement ?? false)
            }
        }
    }

    private func startAdsIfAllowed() {
        guard shouldServeAds else { return }
        guard ConsentInformation.shared.canRequestAds else {
            canRequestAds = false
            return
        }

        canRequestAds = true

        guard !isInitialized else {
            loadInterstitial()
            loadRewardedAd()
            return
        }

        MobileAds.shared.start { [weak self] _ in
            DispatchQueue.main.async {
                self?.isInitialized = true
                self?.loadInterstitial()
                self?.loadRewardedAd()
            }
        }
    }

    private func disableAds() {
        shouldServeAds = false
        canRequestAds = false
        interstitial = nil
        rewardedAd = nil
        interstitialDidDismissFullScreenContentBlock = nil
        rewardedCompletion = nil
    }

    private func adRequest() -> Request {
        let request = Request()
        let extras = Extras()
        extras.additionalParameters = ["npa": "1"]
        request.register(extras)
        return request
    }
}
