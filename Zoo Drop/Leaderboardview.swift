import SwiftUI
import GameKit

// This is now the single source of truth for this data structure.
struct LeaderboardEntry: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let score: Int
}

struct LeaderboardView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var gameCenterManager: GameCenterManager
    @State private var scores: [LeaderboardEntry] = []
    @State private var appear = false
    @State private var errorString: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                header
                
                if let errorString = errorString {
                    Text(errorString)
                        .foregroundColor(.red)
                        .padding()
                        .multilineTextAlignment(.center)
                } else if scores.isEmpty {
                    ProgressView("Loading Scores...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                } else {
                    leaderboardList
                }
                
                Spacer()
                backButton
            }
            .scaleEffect(appear ? 1 : 0.8)
            .opacity(appear ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appear)
            .onAppear { appear = true }
            .task {
                await loadScores()
            }
        }
    }

    func loadScores() async {
        do {
            self.scores = try await gameCenterManager.fetchLeaderboardScores()
        } catch let error as GameCenterError {
            self.errorString = (error == .authenticationFailed) ? "Please sign in to Game Center to view the leaderboard." : "Could not load leaderboard."
        } catch {
            self.errorString = "An unknown error occurred. Please try again."
        }
    }

    var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "rosette").foregroundColor(.yellow)
            Text("Leaderboard").font(.largeTitle).fontWeight(.bold).foregroundColor(.white)
            Image(systemName: "star.fill").foregroundColor(.yellow)
        }
        .shadow(radius: 4).padding(.top, 60)
    }

    var leaderboardList: some View {
        List(scores) { entry in
            HStack {
                Text(entry.name)
                Spacer()
                Text("\(entry.score)")
            }
            .listRowBackground(Color.white.opacity(0.1))
            .foregroundColor(.white)
        }
        .listStyle(.plain)
        .background(Color.clear)
        .scrollContentBackground(.hidden)
    }

    var backButton: some View {
        Button("Back to Menu") { dismiss() }
            .font(.headline).foregroundColor(.white)
            .padding(.horizontal, 32).padding(.vertical, 12)
            .background(Color.blue).cornerRadius(10).shadow(radius: 4)
            .padding(.bottom, 40)
    }
}
