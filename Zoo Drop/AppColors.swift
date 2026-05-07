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
            if interactive {
                self.glassEffect(.regular.tint(tint).interactive(), in: shape)
            } else {
                self.glassEffect(.regular.tint(tint), in: shape)
            }
        } else {
            self
                .background(.ultraThinMaterial, in: shape)
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
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(background(for: configuration.isPressed), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .premiumGlass(cornerRadius: 18, tint: tint.opacity(0.28), interactive: true)
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
            return LinearGradient(colors: [tint.opacity(opacity), tint.opacity(0.34)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .primary:
            return LinearGradient(colors: [PremiumTheme.gold.opacity(opacity), PremiumTheme.mint.opacity(opacity)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .destructive:
            return LinearGradient(colors: [PremiumTheme.coral.opacity(opacity), .red.opacity(opacity)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct AmbientSafariBackground: View {
    @State private var drift = false
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
                .offset(y: drift && !reduceMotion ? 8 : -4)
                .opacity(0.82)

            Image("premium_safari_aurora")
                .resizable()
                .scaledToFill()
                .offset(x: drift && !reduceMotion ? 12 : -12)
                .opacity(0.38)

            Image("premium_safari_canopy")
                .resizable()
                .scaledToFill()
                .offset(y: drift && !reduceMotion ? -6 : 8)
                .opacity(0.9)

            ForEach(0..<9, id: \.self) { index in
                Circle()
                    .fill(index.isMultiple(of: 2) ? PremiumTheme.gold.opacity(0.18) : PremiumTheme.mint.opacity(0.16))
                    .frame(width: CGFloat(42 + index * 18), height: CGFloat(42 + index * 18))
                    .blur(radius: 14)
                    .offset(
                        x: drift ? CGFloat(index * 19 - 96) : CGFloat(index * -17 + 72),
                        y: drift ? CGFloat(index * -24 + 160) : CGFloat(index * 21 - 160)
                    )
                    .animation(reduceMotion ? nil : .easeInOut(duration: Double(8 + index)).repeatForever(autoreverses: true), value: drift)
            }

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
        .onAppear { drift = true }
    }
}
