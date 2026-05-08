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
    @State private var canResumeSavedRun = false
    @State private var showingUtilityMenu = false

    @AppStorage("lastRewardCheckDate") private var lastRewardCheckDate = ""
    @AppStorage("highScore") private var highScore = 0
    @AppStorage("hasConsentedToPrivacy") private var hasConsentedToPrivacy = false

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientSafariBackground()

                ScrollView {
                    VStack(spacing: 14) {
                        header
                        goalSummary
                        continueRunButton
                        modeStrip
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 104)
                }
                .scrollIndicators(.hidden)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    homeDock
                }
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
            .sheet(isPresented: $showingUtilityMenu) {
                UtilityMenuView { sheet in
                    showingUtilityMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        open(sheet)
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .onAppear {
                checkForDailyReward()
                refreshSavedRunState()
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
        VStack(spacing: 9) {
            ZStack {
                Image("fx_button_gold_glow")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 226, height: 112)
                    .opacity(0.34)

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 202)
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
    }

    private var goalSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Goal", systemImage: "flag.checkered")
                .font(.headline.weight(.black))
                .foregroundStyle(PremiumTheme.gold)
            Text("Merge matching animals into bigger ones. Keep the pile below the red danger line. Reach Elephant for the big score.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: 430, alignment: .leading)
        .premiumGlass(cornerRadius: 22, tint: PremiumTheme.mint.opacity(0.08))
    }

    @ViewBuilder
    private var continueRunButton: some View {
        Button {
            activeGameLaunch = .new(.classic)
        } label: {
            Label("Start Game", systemImage: "play.fill")
                .font(.system(size: 27, weight: .heavy, design: .rounded))
                .padding(.vertical, 2)
        }
        .buttonStyle(PremiumButtonStyle(tint: PremiumTheme.mint, prominence: .primary))
        .frame(maxWidth: 318)
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
                    Text("More Ways to Play")
                        .font(.title3.weight(.black))
                        .foregroundStyle(.white)
                    Text("Optional score variants after you know the basics.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
            }

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(GameMode.allCases.filter { $0 != .classic }) { mode in
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
        .premiumGlass(cornerRadius: 26, tint: PremiumTheme.lagoon.opacity(0.14))
        .shadow(color: .black.opacity(0.24), radius: 18, y: 10)
        .clipped()
    }

    private var homeDock: some View {
        let itemWidth = dockItemWidth

        return HStack(spacing: 8) {
            dockButton(.scores, color: .blue, icon: "rosette", itemWidth: itemWidth)
            dockButton(.daily, color: .orange, icon: "calendar", itemWidth: itemWidth)
            dockButton(.howToPlay, color: .teal, icon: "questionmark.circle.fill", itemWidth: itemWidth)
            dockButton(.shop, color: .yellow, icon: "cart.fill", itemWidth: itemWidth)

            Button {
                showingUtilityMenu = true
            } label: {
                dockButtonLabel(title: "More", icon: "ellipsis.circle.fill", color: .white, itemWidth: itemWidth)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("homeDockMoreButton")
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.74))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.white.opacity(0.18))
                .frame(height: 1)
        }
        .frame(height: 92)
    }

    private var dockItemWidth: CGFloat {
        let availableWidth = UIScreen.main.bounds.width - 20 - 32
        return min(66, max(52, floor(availableWidth / 5)))
    }

    private func dockButton(_ sheet: HomeSheet, color: Color, icon: String, itemWidth: CGFloat) -> some View {
        Button {
            open(sheet)
        } label: {
            dockButtonLabel(title: sheet.title, icon: icon, color: color, itemWidth: itemWidth)
                .overlay(alignment: .topTrailing) {
                    if sheet == .daily && shouldAnimateDailyButton {
                        Circle()
                            .fill(PremiumTheme.gold)
                            .frame(width: 9, height: 9)
                            .padding(.top, 7)
                            .padding(.trailing, 9)
                            .accessibilityHidden(true)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("homeDock-\(sheet.rawValue)")
    }

    private func dockButtonLabel(title: String, icon: String, color: Color, itemWidth: CGFloat) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.headline.weight(.black))
                .foregroundStyle(color == .yellow ? PremiumTheme.gold : color)
                .frame(height: 20)
            Text(title)
                .font(.caption2.weight(.black))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(width: itemWidth, height: 62)
        .premiumGlass(cornerRadius: 18, tint: color.opacity(0.12), interactive: true)
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
            .frame(width: 126, height: 94, alignment: .leading)
            .padding(10)
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

    private func open(_ sheet: HomeSheet) {
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

private struct UtilityMenuView: View {
    let select: (HomeSheet) -> Void
    @Environment(\.dismiss) private var dismiss

    private let items: [(sheet: HomeSheet, color: Color, icon: String)] = [
        (.scores, .blue, "rosette"),
        (.daily, .orange, "calendar"),
        (.goals, .purple, "star.fill"),
        (.zoodex, .mint, "pawprint.fill"),
        (.quests, .pink, "checkmark.seal.fill"),
        (.shop, .yellow, "cart.fill"),
        (.howToPlay, .teal, "questionmark.circle.fill"),
        (.settings, .gray, "gearshape.fill"),
        (.legal, .indigo, "doc.text.fill")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Zoo Hub")
                                .font(.title.weight(.black))
                                .foregroundStyle(.white)
                            Text("Scores, rewards, settings, legal, and collection tools.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.78))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 12)], spacing: 12) {
                            ForEach(items, id: \.sheet) { item in
                                Button {
                                    dismiss()
                                    select(item.sheet)
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: item.icon)
                                            .font(.title3.weight(.black))
                                            .foregroundStyle(item.color == .yellow ? PremiumTheme.gold : item.color)
                                        Text(item.sheet.title)
                                            .font(.caption.weight(.black))
                                            .foregroundStyle(.white)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.72)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 78)
                                    .premiumGlass(cornerRadius: 18, tint: item.color.opacity(0.12), interactive: true)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("utilityMenu-\(item.sheet.rawValue)")
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 12)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                }
            }
        }
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
        case .classic: return "Main rules"
        case .dailySafari: return "Same queue daily"
        case .timedStampede: return "90-second rush"
        case .zen: return "Practice mode"
        case .challenge: return "Target score"
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
        case .howToPlay: return "Help"
        case .settings: return "Settings"
        case .legal: return "Legal"
        }
    }
}
