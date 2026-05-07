import SpriteKit
import SwiftUI

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: GameViewModel
    @StateObject private var shareManager = ShareManager()
    @State private var scene = GameScene()
    @State private var isPaused = false

    init(viewModel: GameViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("gameplayscreen")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
                    .gesture(dropGesture(in: geometry.size))
                    .allowsHitTesting(!viewModel.isGameOver && !isPaused)
                    .accessibilityIdentifier("gameSurface")

                if viewModel.isAiming {
                    DashedDropLine()
                        .frame(width: 2, height: geometry.size.height)
                        .position(x: viewModel.dropPositionX, y: geometry.size.height / 2)
                        .allowsHitTesting(false)
                }

                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    bottomControls
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 22)

                ChuteView(
                    nextAnimal: viewModel.nextAnimalToDrop,
                    isAiming: viewModel.isAiming,
                    isWiggling: $viewModel.chuteIsWiggling
                )
                .position(x: viewModel.dropPositionX, y: 86)
                .animation(.spring(response: 0.24, dampingFraction: 0.82), value: viewModel.dropPositionX)

                if let animal = viewModel.recentlyUnlockedAnimal {
                    VStack {
                        UnlockToastView(animal: animal)
                            .padding(.top, 46)
                        Spacer()
                    }
                    .zIndex(20)
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
                if viewModel.nextAnimalToDrop == nil {
                    viewModel.resetGame()
                }
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
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                isPaused = true
            } label: {
                Image(systemName: "pause.fill")
                    .frame(width: 42, height: 42)
                    .background(.black.opacity(0.42), in: Circle())
            }
            .foregroundStyle(.white)
            .accessibilityLabel("Pause")

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

            Spacer()

            if viewModel.comboActive {
                Label("Combo", systemImage: "sparkles")
                    .font(.headline.weight(.heavy))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.yellow.opacity(0.88), in: Capsule())
                    .foregroundStyle(.black)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var bottomControls: some View {
        HStack(spacing: 12) {
            powerButton(
                title: "Nudge",
                systemImage: "arrow.left.and.right",
                cost: AppMetrics.nudgeCostInGoldenEggs,
                action: viewModel.activateNudge
            )

            Spacer()

            if let nextAnimal = viewModel.nextAnimalToDrop {
                HStack(spacing: 10) {
                    Image(nextAnimal.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 42, height: 42)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.7))
                        Text(nextAnimal.name)
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.black.opacity(0.38), in: RoundedRectangle(cornerRadius: 14))
                .accessibilityIdentifier("nextAnimalPanel")
            }

            Spacer()

            powerButton(
                title: "Reroll",
                systemImage: "shuffle",
                cost: AppMetrics.rerollCostInGoldenEggs,
                action: viewModel.activateReroll
            )
        }
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
            .frame(width: 74, height: 68)
            .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 14))
        }
        .foregroundStyle(.white)
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

    private func updateScenePausedState() {
        scene.isPaused = isPaused || viewModel.isGameOver
    }
}
