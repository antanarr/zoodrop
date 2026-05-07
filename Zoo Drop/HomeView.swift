import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var gameCenterManager: GameCenterManager
    @EnvironmentObject private var adManager: AdManager
    @EnvironmentObject private var zooDexManager: ZooDexManager
    @EnvironmentObject private var soundManager: SoundManager
    @EnvironmentObject private var questManager: QuestManager

    @State private var showGameView = false
    @State private var activeSheet: HomeSheet?
    @State private var shouldAnimateDailyButton = false

    @AppStorage("lastRewardCheckDate") private var lastRewardCheckDate = ""
    @AppStorage("highScore") private var highScore = 0
    @AppStorage("hasConsentedToPrivacy") private var hasConsentedToPrivacy = false

    var body: some View {
        NavigationStack {
            ZStack {
                Image("titlescreen")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [.black.opacity(0.12), .black.opacity(0.58)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        header
                        playButton
                        menuGrid
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 26)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showGameView) {
                GameView(viewModel: GameViewModel(
                    soundManager: soundManager,
                    hapticManager: HapticManager(),
                    gameCenterManager: gameCenterManager,
                    subscriptionManager: subscriptionManager,
                    adManager: adManager,
                    zooDexManager: zooDexManager,
                    questManager: questManager
                ))
            }
            .sheet(item: $activeSheet) { sheet in
                destination(for: sheet)
            }
            .onAppear {
                checkForDailyReward()
                if !ProcessInfo.processInfo.arguments.contains("UITEST_MODE") {
                    gameCenterManager.authenticateUser()
                    soundManager.playThemeMusic()
                    if hasConsentedToPrivacy {
                        adManager.configureAdsIfAllowed(isSubscribed: subscriptionManager.isSubscribed)
                    }
                }
            }
            .onChange(of: subscriptionManager.isSubscribed) { _, isSubscribed in
                guard !ProcessInfo.processInfo.arguments.contains("UITEST_MODE"),
                      hasConsentedToPrivacy else { return }
                adManager.configureAdsIfAllowed(isSubscribed: isSubscribed)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 230)
                .shadow(color: .black.opacity(0.35), radius: 14, y: 8)

            HStack(spacing: 12) {
                statPill(title: "Best", value: "\(highScore)", icon: "trophy.fill")
                statPill(title: "Eggs", value: "\(subscriptionManager.goldenEggCount)", icon: "circle.fill")
            }

            if subscriptionManager.isSubscribed {
                Label("Zoo Club Active", systemImage: "crown.fill")
                    .font(.subheadline.weight(.heavy))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.yellow.opacity(0.9), in: Capsule())
                    .foregroundStyle(.black)
            }
        }
    }

    private var playButton: some View {
        Button {
            showGameView = true
        } label: {
            Label("Play", systemImage: "play.fill")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .frame(maxWidth: 320)
                .padding(.vertical, 18)
                .background(.green.gradient, in: RoundedRectangle(cornerRadius: 18))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 10, y: 6)
        }
        .accessibilityLabel("Play Zoo Drop")
        .accessibilityIdentifier("playButton")
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
        .background(.black.opacity(0.42), in: Capsule())
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
            .background(color.opacity(0.92), in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(darkText ? .black : .white)
            .scaleEffect(sheet == .daily && shouldAnimateDailyButton ? 1.05 : 1)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: shouldAnimateDailyButton)
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
