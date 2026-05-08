import SpriteKit
import SwiftUI

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: GameViewModel
    @StateObject private var shareManager = ShareManager()
    @State private var scene = GameScene()
    @State private var isPaused = false
    @State private var hasAppliedLaunch = false
    @State private var showTutorialNudge = true
    @State private var visibleAchievement: GameplayAchievementID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let launch: GameLaunch?

    init(viewModel: GameViewModel, launch: GameLaunch? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.launch = launch
    }

    var body: some View {
        GeometryReader { geometry in
            let visibleWidth = max(0, geometry.size.width - geometry.safeAreaInsets.leading - geometry.safeAreaInsets.trailing)

            ZStack {
                Image("gameplayscreen")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [.black.opacity(0.24), .white.opacity(0.02), .black.opacity(0.32)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
                    .gesture(dropGesture(in: geometry.size))
                    .allowsHitTesting(!viewModel.isGameOver && !isPaused)
                    .accessibilityIdentifier("gameSurface")
                    .accessibilityLabel("Zoo Drop playfield")
                    .accessibilityHint("Drag left or right to aim, then release to drop the animal.")

                if viewModel.isAiming {
                    DashedDropLine()
                        .frame(width: 2, height: geometry.size.height)
                        .position(x: viewModel.dropPositionX, y: geometry.size.height / 2)
                        .allowsHitTesting(false)
                }

                VStack(spacing: 0) {
                    topBar
                    modeBanner
                    Spacer()
                    bottomControls(width: visibleWidth - 36)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 22)
                .frame(width: visibleWidth, height: geometry.size.height)
                .position(x: visibleWidth / 2, y: geometry.size.height / 2)

                ChuteView(
                    nextAnimal: viewModel.nextAnimalToDrop,
                    isAiming: viewModel.isAiming,
                    isWiggling: $viewModel.chuteIsWiggling
                )
                .position(x: viewModel.dropPositionX, y: 120)
                .animation(.spring(response: 0.24, dampingFraction: 0.82), value: viewModel.dropPositionX)

                if let animal = viewModel.recentlyUnlockedAnimal {
                    VStack {
                        UnlockToastView(animal: animal)
                            .padding(.top, 46)
                        Spacer()
                    }
                    .zIndex(20)
                }

                if let achievement = visibleAchievement {
                    achievementToast(achievement)
                        .padding(.top, 98)
                        .zIndex(22)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if showTutorialNudge && !viewModel.isTutorialStepComplete(.firstDrop) {
                    tutorialOverlay
                        .zIndex(24)
                        .transition(.opacity.combined(with: .scale))
                }

                if isPaused {
                    PauseMenu(
                        onResume: { isPaused = false },
                        onRestart: {
                            isPaused = false
                            viewModel.resetGame()
                        },
                        onQuit: { dismiss() }
                    )
                    .zIndex(30)
                }

                if viewModel.isGameOver {
                    GameOverView(
                        score: viewModel.score,
                        frames: viewModel.lastFiveSecondsFrames,
                        onRetry: { viewModel.resetGame() },
                        onRevive: { viewModel.reviveGame() },
                        onQuit: { dismiss() },
                        canRevive: viewModel.canRevive,
                        largestAnimal: viewModel.largestAnimalCreated?.name ?? "Monkey",
                        longestCombo: viewModel.longestCombo
                    )
                    .environmentObject(shareManager)
                    .zIndex(40)
                }
            }
            .onAppear {
                configureScene(size: geometry.size)
                viewModel.attach(scene: scene)
                applyLaunchIfNeeded()
            }
            .onChange(of: geometry.size) { _, newSize in
                configureScene(size: newSize)
            }
            .onChange(of: isPaused) { _, _ in
                updateScenePausedState()
            }
            .onChange(of: viewModel.isGameOver) { _, _ in
                updateScenePausedState()
            }
            .onChange(of: viewModel.lastEarnedAchievement) { _, achievement in
                guard let achievement else { return }
                showAchievement(achievement)
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                isPaused = true
            } label: {
                Image(systemName: "pause.fill")
                    .font(.headline.weight(.black))
                    .frame(width: 46, height: 46)
                    .premiumGlass(cornerRadius: 23, tint: PremiumTheme.lagoon.opacity(0.25), interactive: true)
            }
            .foregroundStyle(.white)
            .accessibilityLabel("Pause")
            .accessibilityIdentifier("pauseButton")

            VStack(alignment: .leading, spacing: 2) {
                Text("Score")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.75))
                Text("\(viewModel.score)")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .accessibilityIdentifier("gameScore")
                    .accessibilityLabel("Score \(viewModel.score)")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .premiumGlass(cornerRadius: 18, tint: PremiumTheme.mint.opacity(0.08))

            Spacer()

            if viewModel.comboActive {
                Label("Combo", systemImage: "sparkles")
                    .font(.headline.weight(.heavy))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(PremiumTheme.gold.opacity(0.9), in: Capsule())
                    .foregroundStyle(PremiumTheme.ink)
                    .shadow(color: PremiumTheme.gold.opacity(0.65), radius: 16)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var modeBanner: some View {
        HStack(spacing: 10) {
            Label(viewModel.gameMode.displayName, systemImage: viewModel.gameMode.iconName)
                .font(.caption.weight(.black))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .premiumGlass(cornerRadius: 16, tint: viewModel.gameMode.tint.opacity(0.08))

            if let remainingTime = viewModel.remainingTime {
                Label(timeString(remainingTime), systemImage: "timer")
                    .font(.caption.weight(.black))
                    .foregroundStyle(PremiumTheme.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(PremiumTheme.gold.opacity(0.92), in: Capsule())
                    .monospacedDigit()
                    .accessibilityIdentifier("remainingTime")
            }

            Spacer()

            if !viewModel.upcomingQueuePreview.isEmpty {
                HStack(spacing: -5) {
                    ForEach(viewModel.upcomingQueuePreview.prefix(4)) { animal in
                        Image(animal.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .padding(3)
                            .background(.black.opacity(0.22), in: Circle())
                            .accessibilityHidden(true)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .premiumGlass(cornerRadius: 16, tint: PremiumTheme.lagoon.opacity(0.08))
                .accessibilityLabel("Upcoming queue preview")
            }
        }
        .padding(.top, 10)
    }

    private func bottomControls(width availableWidth: CGFloat) -> some View {
        let controlsWidth = min(404, max(284, availableWidth))
        let nextPanelWidth = max(136, min(176, controlsWidth - 156))
        let controlGap = max(6, (controlsWidth - nextPanelWidth - 136) / 2)

        return HStack(spacing: controlGap) {
            powerButton(
                title: "Nudge",
                systemImage: "arrow.left.and.right",
                cost: AppMetrics.nudgeCostInGoldenEggs,
                action: viewModel.activateNudge
            )

            if let nextAnimal = viewModel.nextAnimalToDrop {
                Button {
                    viewModel.dropAnimal()
                } label: {
                    HStack(spacing: 8) {
                        Image(nextAnimal.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .scaleEffect(viewModel.isAiming ? 1.08 : 1)
                            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: viewModel.isAiming)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Next")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.72))
                            Text(nextAnimal.name)
                                .font(.subheadline.weight(.heavy))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.62)
                        }
                    }
                    .frame(width: nextPanelWidth, height: 68)
                    .premiumGlass(cornerRadius: 20, tint: nextAnimal.rarity.color.opacity(0.08), interactive: true)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Drop \(nextAnimal.name)")
                .accessibilityHint("Drops the queued animal at the current aim position.")
                .accessibilityIdentifier("nextAnimalPanel")
            }

            powerButton(
                title: "Reroll",
                systemImage: "shuffle",
                cost: AppMetrics.rerollCostInGoldenEggs,
                action: viewModel.activateReroll
            )
        }
        .frame(width: controlsWidth, height: 68)
    }

    private var tutorialOverlay: some View {
        GeometryReader { proxy in
            let visibleWidth = UIScreen.main.bounds.width
            let cardWidth = min(visibleWidth - 36, 344)

            ZStack(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Goal", systemImage: "flag.checkered")
                        .font(.title3.weight(.black))
                        .foregroundStyle(PremiumTheme.gold)
                    Text("Merge two matching animals to evolve them. Keep every animal below the red danger line. Reach Elephant for a huge score.")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Drag anywhere to aim, then release. You can also tap the Next animal panel to drop.")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.white.opacity(0.74))
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Start Dropping") {
                        withAnimation {
                            showTutorialNudge = false
                        }
                        viewModel.markTutorialStepComplete(.firstAim)
                    }
                    .buttonStyle(PremiumButtonStyle(tint: PremiumTheme.mint, prominence: .primary))
                    .accessibilityIdentifier("tutorialGotItButton")
                }
                .padding(18)
                .frame(width: cardWidth, alignment: .leading)
                .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(.white.opacity(0.26), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.34), radius: 18, y: 10)
                .padding(.leading, max(18, (visibleWidth - cardWidth) / 2))
                .padding(.bottom, 148)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottomLeading)
        }
    }

    private func achievementToast(_ achievement: GameplayAchievementID) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "medal.star.fill")
                .font(.title2.weight(.black))
                .foregroundStyle(PremiumTheme.gold)
            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white.opacity(0.7))
                Text(achievement.displayName)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .premiumGlass(cornerRadius: 22, tint: PremiumTheme.gold.opacity(0.22))
        .padding(.horizontal, 20)
    }

    private func powerButton(title: String, systemImage: String, cost: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.bold))
                Text(title)
                    .font(.caption.weight(.heavy))
                Label("\(cost)", systemImage: "circle.fill")
                    .font(.caption2.weight(.bold))
            }
            .frame(width: 68, height: 66)
            .premiumGlass(cornerRadius: 18, tint: PremiumTheme.violet.opacity(0.08), interactive: true)
        }
        .foregroundStyle(.white)
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), costs \(cost) golden eggs")
        .accessibilityIdentifier("\(title.lowercased())PowerButton")
    }

    private func dropGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                viewModel.aim(at: value.location, playfieldWidth: size.width)
            }
            .onEnded { value in
                viewModel.aim(at: value.location, playfieldWidth: size.width)
                viewModel.dropAnimal()
            }
    }

    private func configureScene(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        scene.size = size
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        updateScenePausedState()
    }

    private func applyLaunchIfNeeded() {
        guard !hasAppliedLaunch else { return }
        hasAppliedLaunch = true

        switch launch?.kind ?? .new(.classic) {
        case .new(let mode):
            viewModel.startNewRun(mode: mode)
        case .resume:
            if !viewModel.resumeSavedRun() {
                viewModel.startNewRun(mode: .classic)
            }
        }
    }

    private func updateScenePausedState() {
        scene.isPaused = isPaused || viewModel.isGameOver
    }

    private func showAchievement(_ achievement: GameplayAchievementID) {
        withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.82)) {
            visibleAchievement = achievement
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            guard visibleAchievement == achievement else { return }
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                visibleAchievement = nil
            }
        }
    }

    private func timeString(_ time: TimeInterval) -> String {
        let totalSeconds = max(0, Int(time.rounded()))
        return "\(totalSeconds / 60):\(String(format: "%02d", totalSeconds % 60))"
    }
}

extension GameplayAchievementID {
    var displayName: String {
        switch self {
        case .firstDrop: return "First Drop"
        case .firstCombo: return "Combo Spark"
        case .dailyExplorer: return "Daily Explorer"
        case .stampedeRunner: return "Stampede Runner"
        case .zenKeeper: return "Zen Keeper"
        case .challengeClear: return "Challenge Clear"
        case .chainMaster: return "Chain Master"
        case .elephantKeeper: return "Elephant Keeper"
        case .scoreClimber: return "Score Climber"
        case .scoreChampion: return "Score Champion"
        }
    }
}
