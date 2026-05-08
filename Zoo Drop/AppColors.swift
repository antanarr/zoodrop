//
//  AppColors.swift
//  Zoo Drop
//
//  Created by Anthony Yarand on 7/6/25.
//

import SwiftUI

struct AppColors {
    static let accent = Color("AccentColor")
    static let background = Color("BackgroundColor")
    static let primaryText = Color("PrimaryTextColor")
    static let secondaryText = Color("SecondaryTextColor")
    static let buttonGradientStart = Color("ButtonGradientStart")
    static let buttonGradientEnd = Color("ButtonGradientEnd")
    static let lockedGray = Color("LockedGray")
    static let goldenEggYellow = Color("GoldenEggYellow")
    static let confirmGreen = Color("ConfirmGreen") // For confirmation/positive actions
    static let accentYellow = Color("AccentYellow") // Used in egg actions
    static let eggOrange = Color("EggOrange")       // Orangey hue for egg unlock
    static let zooClubPurple = Color("ZooClubPurple") // For exclusive animal glow/border
}

enum PremiumTheme {
    static let ink = Color(red: 0.06, green: 0.08, blue: 0.11)
    static let canopy = Color(red: 0.05, green: 0.28, blue: 0.22)
    static let lagoon = Color(red: 0.08, green: 0.52, blue: 0.70)
    static let mint = Color(red: 0.34, green: 0.95, blue: 0.70)
    static let coral = Color(red: 1.0, green: 0.38, blue: 0.34)
    static let gold = Color(red: 1.0, green: 0.78, blue: 0.23)
    static let violet = Color(red: 0.43, green: 0.36, blue: 0.94)

    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.02, green: 0.16, blue: 0.20),
            Color(red: 0.03, green: 0.34, blue: 0.30),
            Color(red: 0.91, green: 0.44, blue: 0.26)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [mint, lagoon, coral],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    @ViewBuilder
    func premiumGlass(cornerRadius: CGFloat = 22, tint: Color = .white.opacity(0.16), interactive: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        if #available(iOS 26.0, *) {
            self
                .background(.black.opacity(0.48), in: shape)
                .overlay {
                    shape
                        .fill(tint.opacity(0.10))
                        .blendMode(.screen)
                }
                .glassEffect(interactive ? .regular.tint(.white.opacity(0.05)).interactive() : .regular.tint(.white.opacity(0.04)), in: shape)
                .overlay {
                    shape
                        .strokeBorder(.white.opacity(0.24), lineWidth: 1)
                }
        } else {
            self
                .background(.black.opacity(0.52), in: shape)
                .overlay {
                    shape
                        .strokeBorder(.white.opacity(0.24), lineWidth: 1)
                }
        }
    }

    func premiumCard(cornerRadius: CGFloat = 24) -> some View {
        self
            .padding(16)
            .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .premiumGlass(cornerRadius: cornerRadius)
            .shadow(color: .black.opacity(0.26), radius: 20, y: 12)
    }
}

struct PremiumButtonStyle: ButtonStyle {
    var tint: Color = PremiumTheme.mint
    var prominence: Prominence = .standard

    enum Prominence {
        case standard
        case primary
        case destructive
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.heavy))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .padding(.horizontal, 16)
            .background(background(for: configuration.isPressed), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(prominence == .primary ? 0.45 : 0.26), lineWidth: 1)
            }
            .shadow(color: tint.opacity(prominence == .primary ? 0.26 : 0.14), radius: 14, y: 7)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch prominence {
        case .standard: return .white
        case .primary: return PremiumTheme.ink
        case .destructive: return .white
        }
    }

    private func background(for isPressed: Bool) -> LinearGradient {
        let opacity = isPressed ? 0.72 : 0.92
        switch prominence {
        case .standard:
            return LinearGradient(colors: [PremiumTheme.ink.opacity(0.88), tint.opacity(0.45)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .primary:
            return LinearGradient(colors: [PremiumTheme.gold.opacity(opacity), PremiumTheme.mint.opacity(opacity)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .destructive:
            return LinearGradient(colors: [PremiumTheme.coral.opacity(opacity), .red.opacity(opacity)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct AmbientSafariBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            PremiumTheme.backgroundGradient

            Image("premium_safari_sky")
                .resizable()
                .scaledToFill()
                .opacity(0.9)

            Image("premium_safari_horizon")
                .resizable()
                .scaledToFill()
                .opacity(0.82)

            Image("premium_safari_aurora")
                .resizable()
                .scaledToFill()
                .opacity(reduceMotion ? 0.18 : 0.26)

            Image("premium_safari_canopy")
                .resizable()
                .scaledToFill()
                .opacity(0.82)

            LinearGradient(
                colors: [.black.opacity(0.08), .black.opacity(0.56)],
                startPoint: .top,
                endPoint: .bottom
            )

            Image("premium_safari_vignette")
                .resizable()
                .scaledToFill()
                .opacity(0.62)
        }
        .ignoresSafeArea()
    }
}
