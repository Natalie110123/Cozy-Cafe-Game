// MARK: - TUTORIAL VIEW

import SwiftUI
import UIKit

struct TutorialStep: Identifiable {
    let id: Int
    let emoji: String
    let title: String
    let body: String
}

struct TutorialView: View {
    let playerName: String
    let profileEmoji: String
    let theme: CafeTheme
    let onFinish: () -> Void

    private let steps: [TutorialStep] = [
        TutorialStep(
            id: 0,
            emoji: "👥",
            title: "Customers Arrive",
            body: "Guests line up in the queue and get seated automatically. Each one has a patience bar — if it empties before you serve them, they'll walk out angry (and you'll lose coins!)."
        ),
        TutorialStep(
            id: 1,
            emoji: "🍽️",
            title: "Read Their Order",
            body: "Each seated customer shows what they want as small chips on their card. A customer might order one item or several — check carefully before tapping!"
        ),
        TutorialStep(
            id: 2,
            emoji: "☕",
            title: "Tap to Serve",
            body: "Tap the matching item in the menu grid below. Hit the right item and you earn coins. Tap the wrong one and you lose 5🪙 plus a short speed penalty. Keep it accurate!"
        ),
        TutorialStep(
            id: 3,
            emoji: "🔥",
            title: "Build Your Streak",
            body: "Serve orders without mistakes to build a combo streak. At ×2 and ×3 you earn bonus coins on every item. One wrong tap resets your streak, so stay sharp!"
        ),
        TutorialStep(
            id: 4,
            emoji: "⭐",
            title: "Level Up",
            body: "Serve enough customers to complete each level. Finish without mistakes for a 3-star rating. New menu items and themes unlock as you level up. Spend coins in the Shop between levels!"
        ),
    ]

    @State private var currentStep: Int = 0
    @State private var cardOffset: CGFloat = 60
    @State private var cardOpacity: Double = 0
    @State private var progressScale: CGFloat = 0

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.68).ignoresSafeArea()
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea().opacity(0.45)

            // Ambient glow
            RadialGradient(
                colors: [theme.accent.opacity(0.22), Color.clear],
                center: .top, startRadius: 0, endRadius: 420
            )
            .ignoresSafeArea().allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                // Card
                VStack(spacing: 0) {

                    // ── Top bar ──────────────────────────────────────────
                    HStack(spacing: 10) {
                        Text(profileEmoji).font(.system(size: 18))
                        Text(playerName.isEmpty ? "Chef" : playerName)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.textPrimary)
                        Spacer()
                        Text("How to Play")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(1.5)
                            .foregroundStyle(theme.textSecondary)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 22)
                    .padding(.bottom, 16)

                    // ── Step indicator ────────────────────────────────────
                    HStack(spacing: 6) {
                        ForEach(steps) { s in
                            Capsule()
                                .fill(s.id <= currentStep ? theme.accent : Color.white.opacity(0.15))
                                .frame(width: s.id == currentStep ? 22 : 7, height: 5)
                                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentStep)
                        }
                    }
                    .padding(.bottom, 24)

                    // ── Step content ──────────────────────────────────────
                    VStack(spacing: 14) {
                        // Big emoji in a glowing circle
                        ZStack {
                            Circle()
                                .fill(theme.accent.opacity(0.16))
                                .frame(width: 80, height: 80)
                            Circle()
                                .stroke(theme.accent.opacity(0.35), lineWidth: 1.5)
                                .frame(width: 80, height: 80)
                            Text(steps[currentStep].emoji)
                                .font(.system(size: 38))
                        }
                        .shadow(color: theme.accent.opacity(0.30), radius: 14, x: 0, y: 4)

                        Text(steps[currentStep].title)
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(theme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(steps[currentStep].body)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 22)
                    .offset(y: cardOffset)
                    .opacity(cardOpacity)

                    Spacer().frame(height: 28)

                    // ── Buttons ───────────────────────────────────────────
                    HStack(spacing: 10) {
                        // Skip / Back
                        if currentStep == 0 {
                            Button {
                                Haptics.selection()
                                onFinish()
                            } label: {
                                Text("Skip")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(theme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.white.opacity(0.07))
                                            .overlay(RoundedRectangle(cornerRadius: 14)
                                                .stroke(theme.accent.opacity(0.22), lineWidth: 1))
                                    )
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: 90)
                        } else {
                            Button {
                                Haptics.selection()
                                advance(by: -1)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 11, weight: .bold))
                                    Text("Back")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                }
                                .foregroundStyle(theme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.07))
                                        .overlay(RoundedRectangle(cornerRadius: 14)
                                            .stroke(theme.accent.opacity(0.22), lineWidth: 1))
                                )
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: 90)
                        }

                        // Next / Let's Go
                        let isLast = currentStep == steps.count - 1
                        Button {
                            Haptics.impact(.medium)
                            if isLast { onFinish() } else { advance(by: 1) }
                        } label: {
                            HStack(spacing: 8) {
                                Text(isLast ? "Let's Go! ☕" : "Next")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                if !isLast {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .bold))
                                }
                            }
                            .foregroundStyle(theme.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(LinearGradient(
                                        colors: [theme.accent, theme.accentAlt],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .shadow(color: theme.accent.opacity(0.50), radius: 10, x: 0, y: 4)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 26)
                }
                .frame(maxWidth: 360)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(theme.cardFill.opacity(0.97))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(theme.accent.opacity(0.30), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.55), radius: 34, x: 0, y: 12)
                )
                .padding(.horizontal, 18)

                Spacer()
            }
        }
        .onAppear { animateIn() }
    }

    // ── Helpers ────────────────────────────────────────────────────────

    private func animateIn() {
        cardOffset = 50; cardOpacity = 0
        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
            cardOffset = 0; cardOpacity = 1
        }
    }

    private func advance(by delta: Int) {
        // Slide out
        withAnimation(.easeIn(duration: 0.15)) {
            cardOffset = delta > 0 ? -30 : 30
            cardOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            currentStep = max(0, min(steps.count - 1, currentStep + delta))
            cardOffset = delta > 0 ? 40 : -40
            // Slide in
            withAnimation(.spring(response: 0.38, dampingFraction: 0.70)) {
                cardOffset = 0; cardOpacity = 1
            }
        }
    }
}


// ═══════════════════════════════════════════════════════════════════════
// CONTENTVIEW INTEGRATION — make these 3 small edits in ContentView:
// ═══════════════════════════════════════════════════════════════════════
//
// 1. Add this state variable near the other @State properties:
//
//    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false
//    @State private var showTutorial = false
//
//
// 2. In the ZStack inside `var body`, add the tutorial overlay AFTER
//    the `if showStartScreen { startScreen }` line:
//
//    if showTutorial {
//        TutorialView(
//            playerName: playerName,
//            profileEmoji: profileEmoji,
//            theme: activeTheme
//        ) {
//            withAnimation(.easeInOut(duration: 0.3)) { showTutorial = false }
//            hasSeenTutorial = true
//            withAnimation(.easeOut(duration: 0.35)) { gameVisible = true }
//            startGame()
//            setMessage("Welcome, \(playerName.isEmpty ? "Chef" : playerName)! ☕", positive: true)
//        }
//        .transition(.opacity)
//        .zIndex(5)
//    }
//
//
// 3. In `startScreen`, replace the Button action that starts the game:
//    Find the block that calls `startGame()` inside the "Start Playing" button,
//    and replace it with:
//
//    Button {
//        Haptics.notify(.success)
//        SoundManager.shared.play(.levelUp)
//        withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
//            startCardOffset = -60
//            startCardOpacity = 0
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
//            if hasSeenTutorial {
//                // Skip tutorial for returning players
//                withAnimation(.easeOut(duration: 0.35)) { gameVisible = true }
//                startGame()
//                setMessage("Welcome back, \(playerName.isEmpty ? "Chef" : playerName)! ☕", positive: true)
//            } else {
//                showTutorial = true
//            }
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { showStartScreen = false }
//    } label: {
//        // (keep your existing label code exactly as-is)
//    }
