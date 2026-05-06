import SwiftUI

struct HomeView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var gameCenterManager: GameCenterManager
    @EnvironmentObject var adManager: AdManager
    @EnvironmentObject var zooDexManager: ZooDexManager
    @EnvironmentObject var soundManager: SoundManager

    @State private var showGameView = false
    // --- RET-01: DAILY LOGIN STATE ---
    @State private var showDailyLogin = false
    @State private var shouldAnimateDailyButton = false
    @State private var showSettings = false
    @State private var showZooDex = false
    @State private var showQuests = false
    @State private var showShop = false
    // Tracks if the daily reward has been checked for this session.
    @AppStorage("lastRewardCheckDate") private var lastRewardCheckDate: String = ""
    @AppStorage("highScore") private var highScore: Int = 0

    var body: some View {
        NavigationView {
            ZStack {
                Image("titlescreen")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer()
                    Text("Zoo Drop")
                        .font(.system(size: 80, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                    Text("High Score: \(highScore)")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Spacer()

                    // Main Play Button
                    Button(action: { showGameView = true }) {
                        Text("Play")
                            .font(.largeTitle.bold())
                            .padding()
                            .frame(maxWidth: 300)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.3), radius: 5, y: 5)
                    }
                    
                    // --- RET-01: GAME CENTER & DAILY REWARD BUTTONS ---
                    HStack(spacing: 20) {
                        // Leaderboards Button
                        Button(action: { gameCenterManager.showLeaderboards() }) {
                            Label("Scores", systemImage: "rosette")
                                .font(.headline.bold())
                                .padding()
                                .background(.blue)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }
                        
                        // Daily Reward Calendar Button
                        Button(action: {
                            showDailyLogin = true
                            shouldAnimateDailyButton = false
                        }) {
                            Label("Daily", systemImage: "calendar")
                                .font(.headline.bold())
                                .padding()
                                .background(.orange)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                                .scaleEffect(shouldAnimateDailyButton ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: shouldAnimateDailyButton)
                        }
                        
                        // Achievements Button
                        Button(action: { gameCenterManager.showAchievements() }) {
                            Label("Goals", systemImage: "star")
                                .font(.headline.bold())
                                .padding()
                                .background(.purple)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }
                    }
                    .shadow(color: .black.opacity(0.3), radius: 5, y: 5)
                    
                    HStack(spacing: 20) {
                        Button(action: { showZooDex = true }) {
                            Label("ZooDex", systemImage: "pawprint.fill")
                                .font(.headline.bold())
                                .padding()
                                .background(.mint)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }

                        Button(action: { showQuests = true }) {
                            Label("Quests", systemImage: "checkmark.seal.fill")
                                .font(.headline.bold())
                                .padding()
                                .background(.pink)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }

                        Button(action: { showShop = true }) {
                            Label("Shop", systemImage: "cart.fill")
                                .font(.headline.bold())
                                .padding()
                                .background(.yellow)
                                .foregroundColor(.black)
                                .cornerRadius(15)
                        }

                        Button(action: { showSettings = true }) {
                            Label("Settings", systemImage: "gearshape.fill")
                                .font(.headline.bold())
                                .padding()
                                .background(.gray)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showGameView) {
                GameView(viewModel: GameViewModel(
                    soundManager: soundManager, 
                    hapticManager: HapticManager(), 
                    gameCenterManager: gameCenterManager,
                    subscriptionManager: subscriptionManager,
                    adManager: adManager,
                    zooDexManager: zooDexManager,
                    questManager: QuestManager(soundManager: soundManager)
                ))
            }
            // --- RET-01: DAILY LOGIN SHEET ---
            .sheet(isPresented: $showDailyLogin) {
                // The new DailyLoginView is presented as a sheet.
                DailyLoginView()
                    .environmentObject(subscriptionManager) // Pass the dependency
            }
            .sheet(isPresented: $showZooDex) { ZooDexView() }
            .sheet(isPresented: $showQuests) { QuestListView() }
            .sheet(isPresented: $showShop) { ShopView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .onAppear {
                checkForDailyReward()
                soundManager.playThemeMusic()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // --- RET-01: CHECK FOR DAILY REWARD ---
    /// Checks if a day has passed since the last check and shows the calendar if a reward is available.
    private func checkForDailyReward() {
        let todayString = Date().formatted(date: .abbreviated, time: .omitted)
        if todayString != lastRewardCheckDate {
            // Using a small delay to ensure the main view is fully visible first.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                shouldAnimateDailyButton = true
                lastRewardCheckDate = todayString
            }
        }
    }
}
