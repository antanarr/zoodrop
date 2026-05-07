import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var gameCenterManager: GameCenterManager
    @EnvironmentObject private var adManager: AdManager
    @EnvironmentObject private var zooDexManager: ZooDexManager
    @EnvironmentObject private var soundManager: SoundManager
    @EnvironmentObject private var questManager: QuestManager

    @State private var activeGameLaunch: GameLaunch?
    @State private var activeSheet: HomeSheet?
    @State private var shouldAnimateDailyButton = false
    @State private var mascotBounce = false
    @State private var canResumeSavedRun = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage("lastRewardCheckDate") private var lastRewardCheckDate = ""
    @AppStorage("highScore") private var highScore = 0
    @AppStorage("hasConsentedToPrivacy") private var hasConsentedToPrivacy = false

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientSafariBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        header
                        continueRunButton
                        modeStrip
                        menuGrid
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 26)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(item: $activeGameLaunch, onDismiss: {
                refreshSavedRunState()
            }) { launch in
                GameView(
                    viewModel: GameViewModel(
                        soundManager: soundManager,
                        hapticManager: HapticManager(),
                        gameCenterManager: gameCenterManager,
                        subscriptionManager: subscriptionManager,
                        adManager: adManager,
                        zooDexManager: zooDexManager,
                        questManager: questManager
                    ),
                    launch: launch
                )
            }
            .sheet(item: $activeSheet) { sheet in
                destination(for: sheet)
            }
            .onAppear {
                checkForDailyReward()
                refreshSavedRunState()
                if !reduceMotion {
                    mascotBounce = true
                }
                if !ProcessInfo.processInfo.arguments.contains("UITEST_MODE") {
                    gameCenterManager.authenticateUser()
                    soundManager.playThemeMusic()
                    if hasConsentedToPrivacy {
                        adManager.configureAdsIfAllowed(hasAdFreeEntitlement: subscriptionManager.hasAdFreeEntitlement)
                    }
                }
            }
            .onChange(of: subscriptionManager.hasAdFreeEntitlement) { _, hasAdFreeEntitlement in
                guard !ProcessInfo.processInfo.arguments.contains("UITEST_MODE"),
                      hasConsentedToPrivacy else { return }
                adManager.configureAdsIfAllowed(hasAdFreeEntitlement: hasAdFreeEntitlement)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Image("fx_button_gold_glow")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 260, height: 160)
                    .opacity(0.62)
                    .scaleEffect(mascotBounce ? 1.08 : 0.96)

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 238)
                    .rotationEffect(.degrees(mascotBounce && !reduceMotion ? 1.4 : -1.4))
                    .shadow(color: .black.opacity(0.35), radius: 14, y: 8)
            }

            HStack(spacing: 12) {
                statPill(title: "Best", value: "\(highScore)", icon: "trophy.fill")
                statPill(title: "Eggs", value: "\(subscriptionManager.goldenEggCount)", icon: "circle.fill")
            }

            if subscriptionManager.hasAdFreeEntitlement {
                Label(subscriptionManager.isSubscribed ? "Zoo Club Active" : "Ads Removed", systemImage: subscriptionManager.isSubscribed ? "crown.fill" : "shield.checkered")
                    .font(.subheadline.weight(.heavy))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .premiumGlass(cornerRadius: 18, tint: PremiumTheme.gold.opacity(0.35))
                    .foregroundStyle(.white)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: mascotBounce)
    }

    @ViewBuilder
    private var continueRunButton: some View {
        Button {
            activeGameLaunch = .new(.classic)
        } label: {
            Label("Play Classic", systemImage: "play.fill")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .padding(.vertical, 4)
        }
        .buttonStyle(PremiumButtonStyle(tint: PremiumTheme.mint, prominence: .primary))
        .frame(maxWidth: 330)
        .accessibilityLabel("Play Zoo Drop")
        .accessibilityIdentifier("playButton")

        if canResumeSavedRun {
            Button {
                activeGameLaunch = .resume
            } label: {
                Label("Resume Saved Run", systemImage: "arrow.uturn.forward.circle.fill")
            }
            .buttonStyle(PremiumButtonStyle(tint: PremiumTheme.lagoon))
            .frame(maxWidth: 330)
            .accessibilityIdentifier("resumeRunButton")
        }
    }

    private var modeStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Safari Modes")
                        .font(.title2.weight(.black))
                        .foregroundStyle(.white)
                    Text("Daily seeds, timed runs, zen play, and challenges.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                }
                Spacer()
            }

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(GameMode.allCases) { mode in
                        modeCard(mode)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
            }
            .scrollIndicators(.hidden)
        }
        .padding(16)
        .frame(maxWidth: 430, alignment: .leading)
        .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .premiumGlass(cornerRadius: 26, tint: PremiumTheme.lagoon.opacity(0.14))
        .shadow(color: .black.opacity(0.24), radius: 18, y: 10)
        .clipped()
    }

    private var menuGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            menuButton(.scores, color: .blue, icon: "rosette")
            menuButton(.daily, color: .orange, icon: "calendar")
            menuButton(.goals, color: .purple, icon: "star.fill")
            menuButton(.zoodex, color: .mint, icon: "pawprint.fill")
            menuButton(.quests, color: .pink, icon: "checkmark.seal.fill")
            menuButton(.shop, color: .yellow, icon: "cart.fill", darkText: true)
            menuButton(.howToPlay, color: .teal, icon: "questionmark.circle.fill")
            menuButton(.settings, color: .gray, icon: "gearshape.fill")
            menuButton(.legal, color: .indigo, icon: "doc.text.fill")
        }
        .frame(maxWidth: 430)
    }

    private func modeCard(_ mode: GameMode) -> some View {
        Button {
            activeGameLaunch = .new(mode)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: mode.iconName)
                    .font(.title2.weight(.black))
                    .foregroundStyle(mode.tint)
                Text(mode.displayName)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(mode.shortDescription)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(width: 142, height: 118, alignment: .leading)
            .padding(12)
            .premiumGlass(cornerRadius: 22, tint: mode.tint.opacity(0.28), interactive: true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.displayName) mode")
        .accessibilityIdentifier("modeButton-\(mode.rawValue)")
    }

    private func statPill(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(title == "Eggs" ? .yellow : .white)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))
                Text(value)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .premiumGlass(cornerRadius: 22, tint: .white.opacity(0.14))
    }

    private func menuButton(_ sheet: HomeSheet, color: Color, icon: String, darkText: Bool = false) -> some View {
        Button {
            switch sheet {
            case .scores:
                gameCenterManager.showLeaderboards()
            case .goals:
                gameCenterManager.showAchievements()
            case .daily:
                shouldAnimateDailyButton = false
                activeSheet = sheet
            default:
                activeSheet = sheet
            }
        } label: {
            VStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.title3.weight(.heavy))
                Text(sheet.title)
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, minHeight: 70)
            .premiumGlass(cornerRadius: 18, tint: color.opacity(0.3), interactive: true)
            .foregroundStyle(.white)
            .scaleEffect(sheet == .daily && shouldAnimateDailyButton ? 1.05 : 1)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: shouldAnimateDailyButton)
        }
        .accessibilityIdentifier("menuButton-\(sheet.rawValue)")
    }

    @ViewBuilder
    private func destination(for sheet: HomeSheet) -> some View {
        switch sheet {
        case .daily:
            DailyLoginView()
                .environmentObject(subscriptionManager)
        case .zoodex:
            ZooDexView()
                .environmentObject(zooDexManager)
        case .quests:
            QuestsView()
                .environmentObject(questManager)
        case .shop:
            ZooClubView()
                .environmentObject(subscriptionManager)
                .environmentObject(soundManager)
        case .settings:
            NavigationStack {
                SettingsView()
                    .environmentObject(subscriptionManager)
                    .environmentObject(soundManager)
                    .environmentObject(adManager)
            }
        case .howToPlay:
            HowToPlayView()
        case .legal:
            NavigationStack {
                LegalNoticeView()
            }
        case .scores, .goals:
            EmptyView()
        }
    }

    private func checkForDailyReward() {
        let todayString = Date().formatted(date: .abbreviated, time: .omitted)
        guard todayString != lastRewardCheckDate else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            shouldAnimateDailyButton = true
            lastRewardCheckDate = todayString
        }
    }

    private func refreshSavedRunState() {
        guard let data = UserDefaults.standard.data(forKey: "savedRunSnapshot"),
              let snapshot = try? JSONDecoder().decode(SavedRunSnapshot.self, from: data) else {
            canResumeSavedRun = false
            return
        }
        canResumeSavedRun = snapshot.isResumable
    }
}

struct GameLaunch: Identifiable, Equatable {
    enum Kind: Equatable {
        case new(GameMode)
        case resume
    }

    let id = UUID()
    let kind: Kind

    static func new(_ mode: GameMode) -> GameLaunch {
        GameLaunch(kind: .new(mode))
    }

    static var resume: GameLaunch {
        GameLaunch(kind: .resume)
    }
}

extension GameMode {
    var iconName: String {
        switch self {
        case .classic: return "square.stack.3d.up.fill"
        case .dailySafari: return "calendar.badge.clock"
        case .timedStampede: return "timer"
        case .zen: return "leaf.fill"
        case .challenge: return "target"
        }
    }

    var tint: Color {
        switch self {
        case .classic: return PremiumTheme.mint
        case .dailySafari: return PremiumTheme.gold
        case .timedStampede: return PremiumTheme.coral
        case .zen: return Color(red: 0.42, green: 0.86, blue: 0.97)
        case .challenge: return PremiumTheme.violet
        }
    }

    var shortDescription: String {
        switch self {
        case .classic: return "Endless tower"
        case .dailySafari: return "Shared daily seed"
        case .timedStampede: return "Two-minute rush"
        case .zen: return "No fail line"
        case .challenge: return "Goal run"
        }
    }
}

private enum HomeSheet: String, Identifiable {
    case scores
    case daily
    case goals
    case zoodex
    case quests
    case shop
    case howToPlay
    case settings
    case legal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .scores: return "Scores"
        case .daily: return "Daily"
        case .goals: return "Goals"
        case .zoodex: return "ZooDex"
        case .quests: return "Quests"
        case .shop: return "Shop"
        case .howToPlay: return "How"
        case .settings: return "Settings"
        case .legal: return "Legal"
        }
    }
}
