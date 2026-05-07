import SwiftUI
import AVFoundation
import AudioToolbox
import UIKit

// MARK: - SOUND MANAGER
class SoundManager {
    static let shared = SoundManager()
    var isMuted = false
    func play(_ sound: CafeSound) {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(sound.systemSoundID)
    }
}

enum CafeSound {
    case serve, complete, wrong, leave, levelUp, powerUp, coin, tip, newCustomer
    var systemSoundID: SystemSoundID {
        switch self {
        case .serve:       return 1057
        case .complete:    return 1025
        case .wrong:       return 1053
        case .leave:       return 1006
        case .levelUp:     return 1013
        case .powerUp:     return 1054
        case .coin:        return 1103
        case .tip:         return 1016
        case .newCustomer: return 1104
        }
    }
}

// MARK: - HAPTICS
struct Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
}

// MARK: - BASE COLORS
extension Color {
    static let cafeCream     = Color(red: 0.99, green: 0.97, blue: 0.93)
    static let cafeWarm      = Color(red: 0.97, green: 0.92, blue: 0.84)
    static let cafeLatte     = Color(red: 0.80, green: 0.65, blue: 0.46)
    static let cafeMocha     = Color(red: 0.36, green: 0.20, blue: 0.08)
    static let cafeDark      = Color(red: 0.18, green: 0.10, blue: 0.04)
    static let cafeGreen     = Color(red: 0.30, green: 0.62, blue: 0.38)
    static let cafeAmber     = Color(red: 0.86, green: 0.58, blue: 0.18)
    static let cafeShadow    = Color.black.opacity(0.10)
    static let cafeParchment = Color(red: 0.98, green: 0.94, blue: 0.87)
    static let cafeGold      = Color(red: 0.91, green: 0.74, blue: 0.22)
    static let cafeBlush     = Color(red: 0.96, green: 0.87, blue: 0.76)
    static let cafeCanvas    = Color(red: 0.15, green: 0.09, blue: 0.03)
}

// MARK: - MODELS
struct MenuItem: Identifiable, Equatable {
    let id: String
    let emoji: String
    let name: String
    let price: Int
    let unlockLevel: Int
}

struct Customer: Identifiable {
    let id = UUID()
    var emoji: String
    var order: [MenuItem]
    var patience: Double = 1.0
    var mood: Mood = .happy
    var hadMistake: Bool = false
    enum Mood: String { case happy = "🙂", neutral = "😐", angry = "😠" }
}

// MARK: - THEME MODEL
struct CafeTheme: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let accent: Color
    let accentAlt: Color
    let background: Color
    let cardFill: Color
    let textPrimary: Color
    let textSecondary: Color
    let progressColor: Color
    let unlockLevel: Int
    let price: Int
}

struct Achievement: Identifiable, Equatable, Codable {
    let id: UUID
    let title: String
    let detail: String
}

struct PowerUp: Identifiable, Equatable {
    let id: String
    let emoji: String
    let name: String
    let effect: String
    let price: Int
    let duration: TimeInterval
    let cooldown: TimeInterval
}

struct Upgrade: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let price: Int
    let unlockLevel: Int
}

// MARK: - WORLD MODEL
struct GameWorld: Identifiable {
    let id: Int
    let name: String
    let emoji: String
    let subtitle: String
    let accentColor: Color
    let background: Color
    let cardFill: Color
    let textPrimary: Color
    let textSecondary: Color
    let menu: [MenuItem]
}

// MARK: - CONFETTI PARTICLE
struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var rotation: Double
    var scale: CGFloat
    var shape: ParticleShape
    var velocityX: CGFloat
    var velocityY: CGFloat
    var rotationSpeed: Double
    var opacity: Double

    enum ParticleShape: CaseIterable {
        case circle, rectangle, triangle
    }
}

// MARK: - CONFETTI VIEW
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var animating = false
    let colors: [Color] = [.cafeGold, Color(red:0.95,green:0.35,blue:0.35), Color(red:0.35,green:0.75,blue:0.45),
                           Color(red:0.40,green:0.70,blue:0.95), Color(red:0.90,green:0.55,blue:0.25),
                           Color(red:0.85,green:0.45,blue:0.85), .cafeParchment]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for particle in particles {
                    let rect = CGRect(x: particle.x - 5 * particle.scale,
                                      y: particle.y - 5 * particle.scale,
                                      width: 10 * particle.scale,
                                      height: 10 * particle.scale)
                    context.opacity = particle.opacity
                    var path: Path
                    switch particle.shape {
                    case .circle:
                        path = Path(ellipseIn: rect)
                    case .rectangle:
                        path = Path(rect.insetBy(dx: -1, dy: 2))
                    case .triangle:
                        path = Path { p in
                            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
                            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                            p.closeSubpath()
                        }
                    }
                    var transform = CGAffineTransform(translationX: rect.midX, y: rect.midY)
                    transform = transform.rotated(by: particle.rotation)
                    transform = transform.translatedBy(x: -rect.midX, y: -rect.midY)
                    context.fill(path.applying(transform), with: .color(particle.color))
                }
            }
            .onChange(of: timeline.date) { _ in updateParticles() }
        }
        .allowsHitTesting(false)
        .onAppear { spawnParticles() }
    }

    func spawnParticles() {
        particles = (0..<90).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: -80 ... -10),
                color: colors.randomElement()!,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.7...1.6),
                shape: ConfettiParticle.ParticleShape.allCases.randomElement()!,
                velocityX: CGFloat.random(in: -1.8...1.8),
                velocityY: CGFloat.random(in: 3.5...8.5),
                rotationSpeed: Double.random(in: -8...8),
                opacity: 1.0
            )
        }
    }

    func updateParticles() {
        let screenH = UIScreen.main.bounds.height
        for i in particles.indices {
            particles[i].x += particles[i].velocityX
            particles[i].y += particles[i].velocityY
            particles[i].rotation += particles[i].rotationSpeed
            particles[i].velocityY += 0.12 // gravity
            if particles[i].y > screenH * 0.75 {
                particles[i].opacity = max(0, particles[i].opacity - 0.03)
            }
        }
        particles.removeAll { $0.opacity <= 0 || $0.y > screenH + 40 }
    }
}

// MARK: - LEAVE FLOATER VIEW
struct LeaveFloaterView: View {
    @State private var offsetY: CGFloat = 0
    @State private var offsetX: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.5

    var body: some View {
        Text("😤")
            .font(.system(size: 28))
            .scaleEffect(scale)
            .offset(x: offsetX, y: offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                    scale = 1.1
                }
                withAnimation(.easeOut(duration: 1.2).delay(0.1)) {
                    offsetY = -90
                    offsetX = CGFloat.random(in: -30...30)
                    opacity = 0
                }
            }
    }
}

// MARK: - CHECKMARK BURST VIEW
struct CheckmarkBurstView: View {
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var ringScale: CGFloat = 0.4
    @State private var ringOpacity: Double = 0.8

    var body: some View {
        ZStack {
            // Ring pulse
            Circle()
                .stroke(Color.cafeGreen.opacity(ringOpacity), lineWidth: 3)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)
            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Color.cafeGreen)
                .shadow(color: Color.cafeGreen.opacity(0.6), radius: 10, x: 0, y: 0)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.52)) {
                scale = 1.1
                opacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.55).delay(0.05)) {
                ringScale = 1.6
                ringOpacity = 0
            }
            withAnimation(.easeIn(duration: 0.28).delay(0.55)) {
                scale = 0.6
                opacity = 0
            }
        }
    }
}

// MARK: - STEAM PARTICLE VIEW
struct SteamView: View {
    @State private var offsets: [CGFloat]  = [-6, 0, 6]
    @State private var opacities: [Double] = [0, 0, 0]
    @State private var scales: [CGFloat]   = [0.6, 0.6, 0.6]

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.55))
                    .frame(width: 3, height: 14).blur(radius: 2)
                    .offset(y: offsets[i]).opacity(opacities[i]).scaleEffect(x: scales[i], y: 1)
            }
        }
        .onAppear {
            for i in 0..<3 {
                let d = Double(i) * 0.35
                withAnimation(.easeOut(duration: 1.4).delay(d).repeatForever(autoreverses: false)) {
                    offsets[i] = -26; opacities[i] = 0; scales[i] = 1.5
                }
                withAnimation(.easeIn(duration: 0.3).delay(d)) { opacities[i] = 0.6 }
            }
        }
    }
}

// MARK: - FLOAT COIN VIEW
struct FloatCoinView: View {
    let value: Int
    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Text("+\(value)🪙")
            .font(.system(size: 20, weight: .black, design: .rounded))
            .foregroundStyle(Color.cafeGold)
            .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
            .offset(y: offsetY).opacity(opacity)
            .onAppear { withAnimation(.easeOut(duration: 1.1)) { offsetY = -70; opacity = 0 } }
    }
}

// MARK: - CONTENT VIEW
struct ContentView: View {

    @State private var isMuted = false

    @AppStorage("achievementsData") private var achievementsData: Data = Data()
    @State private var achievements: [Achievement] = []
    @AppStorage("highScore") private var highScore: Int = 0

    let powerUps: [PowerUp] = [
        PowerUp(id: "freeze", emoji: "🧊", name: "Freeze Time",  effect: "Slows patience drain for 10s", price: 25, duration: 10, cooldown: 20),
        PowerUp(id: "double", emoji: "✨", name: "Double Tips",  effect: "Doubles coins earned for 12s",  price: 30, duration: 12, cooldown: 25),
        PowerUp(id: "spawn",  emoji: "🚀", name: "Quick Seat",   effect: "Instantly seats next in queue", price: 15, duration: 0,  cooldown: 10)
    ]
    @State private var activePowerUp: String? = nil
    @State private var ownedPowerUps: [String: Int] = [:]
    @State private var powerUpCooldowns: [String: TimeInterval] = [:]
    @State private var cooldownTimers: [String: Timer] = [:]
    @State private var spawnTimer: Timer? = nil
    @State private var patienceTimer: Timer? = nil
    private let maxLevel = 5

    // MARK: - Animation state
    @State private var completedSeatIndex: Int? = nil
    @State private var leaveFloaters: [UUID] = []
    @State private var showConfetti = false
    @State private var leavingSeatOffsets: [Int: CGFloat] = [:]
    @State private var leavingSeatOpacities: [Int: Double] = [:]

    let menu: [MenuItem] = [
        .init(id: "coffee",    emoji: "☕", name: "Coffee",    price: 10, unlockLevel: 1),
        .init(id: "toast",     emoji: "🍞", name: "Toast",     price: 9,  unlockLevel: 1),
        .init(id: "tea",       emoji: "🍵", name: "Matcha",    price: 10, unlockLevel: 2),
        .init(id: "croissant", emoji: "🥐", name: "Croissant", price: 11, unlockLevel: 2),
        .init(id: "cookie",    emoji: "🍪", name: "Cookie",    price: 12, unlockLevel: 3),
        .init(id: "muffin",    emoji: "🧁", name: "Muffin",    price: 13, unlockLevel: 3),
        .init(id: "donut",     emoji: "🍩", name: "Donut",     price: 12, unlockLevel: 3),
        .init(id: "sandwich",  emoji: "🥪", name: "Sandwich",  price: 16, unlockLevel: 4),
        .init(id: "burger",    emoji: "🍔", name: "Burger",    price: 22, unlockLevel: 4),
        .init(id: "pizza",     emoji: "🍕", name: "Pizza",     price: 24, unlockLevel: 4),
        .init(id: "sushi",     emoji: "🍣", name: "Sushi",     price: 30, unlockLevel: 5),
        .init(id: "ramen",     emoji: "🍜", name: "Ramen",     price: 32, unlockLevel: 5)
    ]

    @State private var dailySpecialID: String = "coffee"
    var dailySpecial: MenuItem? { menu.first { $0.id == dailySpecialID } }

    // MARK: - THEME DEFINITIONS
    let themes: [CafeTheme] = [
        CafeTheme(
            name: "Cozy", emoji: "🪵",
            accent:        Color(red: 0.80, green: 0.55, blue: 0.28),
            accentAlt:     Color(red: 0.55, green: 0.30, blue: 0.10),
            background:    Color(red: 0.15, green: 0.09, blue: 0.03),
            cardFill:      Color(red: 0.22, green: 0.13, blue: 0.05),
            textPrimary:   Color(red: 0.98, green: 0.94, blue: 0.87),
            textSecondary: Color(red: 0.80, green: 0.65, blue: 0.46),
            progressColor: Color(red: 0.30, green: 0.62, blue: 0.38),
            unlockLevel: 1, price: 0
        ),
        CafeTheme(
            name: "Tidal", emoji: "🩵",
            accent:        Color(red: 0.15, green: 0.80, blue: 0.85),
            accentAlt:     Color(red: 0.05, green: 0.55, blue: 0.65),
            background:    Color(red: 0.03, green: 0.10, blue: 0.13),
            cardFill:      Color(red: 0.05, green: 0.16, blue: 0.20),
            textPrimary:   Color(red: 0.88, green: 0.98, blue: 1.00),
            textSecondary: Color(red: 0.40, green: 0.78, blue: 0.85),
            progressColor: Color(red: 0.15, green: 0.80, blue: 0.85),
            unlockLevel: 2, price: 40
        ),
        CafeTheme(
            name: "Crimson", emoji: "🔴",
            accent:        Color(red: 0.90, green: 0.20, blue: 0.20),
            accentAlt:     Color(red: 0.65, green: 0.08, blue: 0.08),
            background:    Color(red: 0.10, green: 0.04, blue: 0.04),
            cardFill:      Color(red: 0.17, green: 0.06, blue: 0.06),
            textPrimary:   Color(red: 1.00, green: 0.92, blue: 0.92),
            textSecondary: Color(red: 0.85, green: 0.50, blue: 0.50),
            progressColor: Color(red: 0.90, green: 0.20, blue: 0.20),
            unlockLevel: 3, price: 60
        ),
        CafeTheme(
            name: "Modern", emoji: "🔷",
            accent:        Color(red: 0.35, green: 0.60, blue: 0.95),
            accentAlt:     Color(red: 0.20, green: 0.40, blue: 0.80),
            background:    Color(red: 0.06, green: 0.08, blue: 0.14),
            cardFill:      Color(red: 0.10, green: 0.13, blue: 0.22),
            textPrimary:   Color(red: 0.92, green: 0.95, blue: 1.00),
            textSecondary: Color(red: 0.55, green: 0.70, blue: 0.90),
            progressColor: Color(red: 0.35, green: 0.60, blue: 0.95),
            unlockLevel: 4, price: 80
        ),
        CafeTheme(
            name: "Forest", emoji: "🌿",
            accent:        Color(red: 0.25, green: 0.72, blue: 0.42),
            accentAlt:     Color(red: 0.15, green: 0.50, blue: 0.28),
            background:    Color(red: 0.05, green: 0.12, blue: 0.07),
            cardFill:      Color(red: 0.08, green: 0.18, blue: 0.11),
            textPrimary:   Color(red: 0.88, green: 0.98, blue: 0.90),
            textSecondary: Color(red: 0.45, green: 0.75, blue: 0.52),
            progressColor: Color(red: 0.25, green: 0.72, blue: 0.42),
            unlockLevel: 5, price: 100
        ),
        CafeTheme(
            name: "Luxury", emoji: "💜",
            accent:        Color(red: 0.75, green: 0.45, blue: 0.95),
            accentAlt:     Color(red: 0.50, green: 0.20, blue: 0.75),
            background:    Color(red: 0.08, green: 0.04, blue: 0.14),
            cardFill:      Color(red: 0.13, green: 0.07, blue: 0.22),
            textPrimary:   Color(red: 0.96, green: 0.90, blue: 1.00),
            textSecondary: Color(red: 0.70, green: 0.50, blue: 0.88),
            progressColor: Color(red: 0.75, green: 0.45, blue: 0.95),
            unlockLevel: 5, price: 100
        )
    ]
    
    

    var ownedThemes: [CafeTheme] { themes.filter { ownedThemeNames.contains($0.name) } }
    @State private var activeThemeName: String = "Cozy"
    var activeTheme: CafeTheme { themes.first { $0.name == activeThemeName } ?? themes[0] }

    let emojis = ["🧍","👩","👨","🧓","🧒","🚶"]

    @State private var coins = 0
    @State private var level = 1
    @State private var currentWorldIndex: Int = 0
    @State private var showWorldComplete = false
    @State private var showWorldUnlock = false
    @State private var message = "Welcome to your café! ☕"
    @State private var messageIsPositive = true
    @State private var customersServed = 0
    @State private var customersLost = 0
    @State private var totalEarned = 0
    @State private var levelMistakes = 0
    @State private var streakCount = 0
    @State private var comboMultiplier = 1
    @State private var showStreakBurst = false
    @State private var queue: [Customer] = []
    @State private var seated: [Customer?] = Array(repeating: nil, count: 3)
    @State private var ownedThemeNames: Set<String> = ["Cozy"]

    private let shopItems: [Upgrade] = [
        .init(id: "patienceBoost",  name: "Cozy Atmosphere",   description: "+10% customer patience",            price: 30,  unlockLevel: 1),
        .init(id: "coinInterest",   name: "Coin Interest",      description: "+1🪙 per customer arrival",         price: 45,  unlockLevel: 1),
        .init(id: "fasterService",  name: "Espresso Rush",      description: "Customers arrive faster — more tips", price: 40, unlockLevel: 2),
        .init(id: "tipMagnet",      name: "Tip Magnet",         description: "Happy customers tip 2× more",       price: 50,  unlockLevel: 2),
        .init(id: "lossShield",     name: "Patience Shield",    description: "First walk-out per level forgiven", price: 55,  unlockLevel: 3),
        .init(id: "perfectService", name: "Perfect Service",    description: "+5🪙 bonus for flawless orders",    price: 60,  unlockLevel: 3),
        .init(id: "loyaltyBonus",   name: "Loyalty Card",       description: "Every 5th customer tips auto",      price: 65,  unlockLevel: 4),
        .init(id: "comboStarter",   name: "Combo Kickstart",    description: "Start every level at ×2 streak",   price: 70,  unlockLevel: 4),
        .init(id: "goldRush",       name: "Gold Rush",          description: "Daily special pays 3× instead of 2×", price: 90, unlockLevel: 5),
    ]
    @State private var purchasedUpgrades: Set<String> = []

    @State private var gameVisible = false
    @State private var startCardOffset: CGFloat = 0
    @State private var startCardOpacity: Double = 1
    @State private var floatCoinValue: Int? = nil
    @State private var floatCoinID: UUID = UUID()

    @State private var showStartScreen   = true
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false
    @State private var showTutorial = false
    @State private var showProfile       = false
    @State private var showShop          = false
    @State private var showLevelComplete = false
    @State private var showGameCompleted = false
    @State private var showTryAgain      = false
    @State private var showGameOver      = false
    @State private var levelStars        = 3

    @State private var playerName: String = ""
    @State private var profileEmoji: String = "👩‍🍳"
    private let profileOptions = ["👩‍🍳","🧑‍🍳","🧍","👩","👨","🧓","🧒","🚶","🧑‍🎓","🧑‍🏫"]
    @State private var penaltyActiveUntil: Date? = nil

    var isGamePaused: Bool {
        showShop || showLevelComplete || showTryAgain || showGameOver || showGameCompleted
    }

    var spawnInterval: Double {
        let base      = max(0.8, 2.2 - Double(level) * 0.25)
        let upgraded  = purchasedUpgrades.contains("fasterService") ? max(0.6, base * 0.85) : base
        let penalised = (penaltyActiveUntil ?? .distantPast) > Date() ? max(0.5, upgraded * 0.75) : upgraded
        return penalised
    }

    var patienceDrain: Double {
        let base      = 0.0018 + Double(level) * 0.0007
        let upgraded  = purchasedUpgrades.contains("patienceBoost") ? max(0.0005, base * 0.9) : base
        let penalised = (penaltyActiveUntil ?? .distantPast) > Date() ? upgraded * 1.2 : upgraded
        if activePowerUp == "freeze" { return upgraded * 0.1 }
        return penalised
    }

    var maxCombo: Int  { min(3, 1 + level / 2) }
    var levelGoal: Int { level * 5 }
    var levelProgress: Double { guard levelGoal > 0 else { return 0 }; return Double(customersServed) / Double(levelGoal) }
    var messageBackgroundColor: Color { messageIsPositive ? Color.cafeGreen.opacity(0.12) : Color.red.opacity(0.10) }
    var messageBorderColor: Color     { messageIsPositive ? Color.cafeGreen.opacity(0.35) : Color.red.opacity(0.30) }
    var messageIcon: String           { messageIsPositive ? "✅" : "⚠️" }

    // MARK: - BODY
    var body: some View {
        GeometryReader { geo in
            ZStack {
                activeTheme.background.ignoresSafeArea()
                woodGrainBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        cafeHeader.padding(.horizontal, 14).padding(.top, 6).padding(.bottom, 4)
                        hudBar.padding(.horizontal, 14).padding(.bottom, 6)
                        progressBar.padding(.horizontal, 14).padding(.bottom, 8)
                        cafeScene.padding(.horizontal, 14).padding(.bottom, 8)
                        menuGrid.padding(.horizontal, 14).padding(.bottom, 14)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .opacity(gameVisible ? 1 : 0).scaleEffect(gameVisible ? 1 : 0.96)
                .animation(.easeOut(duration: 0.5).delay(0.15), value: gameVisible)

                if let val = floatCoinValue {
                    FloatCoinView(value: val).id(floatCoinID).allowsHitTesting(false)
                        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) { floatCoinValue = nil } }
                }

                // MARK: Leave floaters layer
                ForEach(leaveFloaters, id: \.self) { floaterID in
                    LeaveFloaterView()
                        .position(x: CGFloat.random(in: geo.size.width * 0.2...geo.size.width * 0.8),
                                  y: geo.size.height * 0.45)
                        .allowsHitTesting(false)
                }

                if showStreakBurst   { streakBurstView }
                if showProfile       { profileSheet }
                if showStartScreen   { startScreen }
                if showTutorial      {
                    TutorialView(
                        playerName: playerName,
                        profileEmoji: profileEmoji,
                        theme: activeTheme
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) { showTutorial = false }
                        hasSeenTutorial = true
                        withAnimation(.easeOut(duration: 0.35)) { gameVisible = true }
                        startGame()
                        setMessage("Welcome, \(playerName.isEmpty ? "Chef" : playerName)! ☕", positive: true)
                    }
                    .transition(.opacity)
                    .zIndex(5)
                }
                if showLevelComplete { levelCompleteOverlay }
                if showTryAgain      { tryAgainOverlay }
                if showGameOver      { gameOverOverlay }
                if showGameCompleted { gameCompletedOverlay }
                if showShop          { shopOverlay }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear { loadAchievements(); pickDailySpecial() }
    }

    // MARK: - Wood Grain Background
    var woodGrainBackground: some View {
        ZStack {
            RadialGradient(colors: [activeTheme.accent.opacity(0.28), Color.clear], center: .topLeading, startRadius: 0, endRadius: 400)
            RadialGradient(colors: [Color.black.opacity(0.55), Color.clear], center: .bottomTrailing, startRadius: 0, endRadius: 500)
            Canvas { context, size in
                var y: CGFloat = -size.width
                while y < size.height + size.width {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y + size.width))
                    context.stroke(path, with: .color(.white.opacity(0.018)), lineWidth: 1)
                    y += 22
                }
            }
        }
    }

    // MARK: - Header
    var cafeHeader: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                ZStack(alignment: .top) {
                    Text("☕").font(.system(size: 20))
                    SteamView().frame(width: 24, height: 18).offset(y: -16)
                }
                .frame(height: 26)
                Text("COZY CAFÉ")
                    .font(.system(size: 13, weight: .black, design: .rounded)).tracking(3.5)
                    .foregroundStyle(LinearGradient(colors: [activeTheme.textPrimary, activeTheme.accent, activeTheme.textPrimary.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
            }
            Spacer()
            Button {
                withAnimation(.spring(response: 0.35)) { showProfile.toggle() }
                Haptics.selection()
            } label: {
                HStack(spacing: 5) {
                    Text(profileEmoji).font(.system(size: 14))
                    Text(playerName.isEmpty ? "Guest" : playerName)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(activeTheme.textPrimary).lineLimit(1)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.08)).overlay(Capsule().stroke(activeTheme.accent.opacity(0.40), lineWidth: 1)))
            }
            .buttonStyle(.plain)
            Button {
                isMuted.toggle(); SoundManager.shared.isMuted = isMuted; Haptics.selection()
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 12)).foregroundStyle(activeTheme.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.white.opacity(0.08)).overlay(Circle().stroke(activeTheme.accent.opacity(0.30), lineWidth: 1)))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - HUD Bar
    var hudBar: some View {
        HStack(spacing: 6) {
            statChip("🪙", "\(coins)", highlight: true)
            statChip("⭐", "Lv \(level)")
            if streakCount >= 3 {
                statChip("🔥", "×\(comboMultiplier)", highlight: true)
                    .scaleEffect(showStreakBurst ? 1.12 : 1.0)
                    .animation(.spring(response: 0.2), value: showStreakBurst)
            }
            Spacer()
            Button {
                withAnimation(.spring(response: 0.35)) { showShop = true }
                Haptics.impact(.light)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "bag.fill").font(.system(size: 11, weight: .bold))
                    Text("Shop").font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(LinearGradient(colors: [activeTheme.accent, activeTheme.accentAlt], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(Capsule().stroke(activeTheme.accent.opacity(0.50), lineWidth: 1))
                        .shadow(color: activeTheme.accent.opacity(0.45), radius: 8, x: 0, y: 4)
                )
                .foregroundStyle(activeTheme.textPrimary)
            }
            .buttonStyle(.plain)
        }
    }

    func statChip(_ icon: String, _ value: String, highlight: Bool = false) -> some View {
        HStack(spacing: 4) {
            Text(icon).font(.system(size: 11))
            Text(value).font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(highlight ? activeTheme.accent : activeTheme.textPrimary)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.white.opacity(highlight ? 0.12 : 0.07))
                .overlay(Capsule().stroke(highlight ? activeTheme.accent.opacity(0.50) : activeTheme.accent.opacity(0.25), lineWidth: 1))
        )
    }

    // MARK: - Progress Bar
    var progressBar: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Level \(level) Progress").font(.system(size: 10, weight: .semibold, design: .rounded)).foregroundStyle(activeTheme.textSecondary)
                Spacer()
                Text("\(customersServed)/\(levelGoal) served").font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(activeTheme.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.08)).frame(height: 7)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(colors: [activeTheme.progressColor.opacity(0.8), activeTheme.progressColor], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * min(levelProgress, 1.0), height: 7)
                        .shadow(color: activeTheme.progressColor.opacity(0.55), radius: 4)
                        .animation(.easeInOut(duration: 0.4), value: levelProgress)
                }
            }
            .frame(height: 7)
        }
    }

    // MARK: - Café Scene
    var cafeScene: some View {
        VStack(spacing: 12) {
            HStack {
                Text("🪑  TABLES").font(.system(size: 10, weight: .heavy, design: .rounded)).tracking(2).foregroundStyle(activeTheme.textSecondary)
                Spacer()
                Text("👥 Queue: \(queue.count)").font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(queue.count > 4 ? Color.red.opacity(0.85) : activeTheme.textSecondary)
            }
            .padding(.horizontal, 2)

            HStack(spacing: 10) {
                ForEach(seated.indices, id: \.self) { i in seatCard(index: i) }
            }

            Divider().overlay(activeTheme.accent.opacity(0.18))

            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    if queue.isEmpty {
                        Label("No queue", systemImage: "person.slash").font(.system(size: 11, design: .rounded)).foregroundStyle(activeTheme.textSecondary.opacity(0.55))
                    } else {
                        ForEach(queue.prefix(5)) { c in
                            Text(c.emoji).font(.body).frame(width: 32, height: 32)
                                .background(Circle().fill(Color.white.opacity(0.08)).overlay(Circle().stroke(activeTheme.accent.opacity(0.25), lineWidth: 1)).shadow(color: Color.black.opacity(0.18), radius: 2))
                                .animation(.spring(), value: queue.count)
                        }
                        if queue.count > 5 { Text("+\(queue.count - 5)").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(activeTheme.textSecondary) }
                    }
                }
                Spacer()
                let activePUs = powerUps.filter { (ownedPowerUps[$0.id] ?? 0) > 0 }
                if !activePUs.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(activePUs) { p in
                                let remaining = Int(powerUpCooldowns[p.id] ?? 0)
                                let count = ownedPowerUps[p.id] ?? 0
                                Button { activate(powerUp: p) } label: {
                                    HStack(spacing: 3) {
                                        Text(p.emoji).font(.caption)
                                        Text(remaining > 0 ? "\(remaining)s" : "×\(count)").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(activeTheme.textPrimary)
                                    }
                                    .padding(.horizontal, 9).padding(.vertical, 5)
                                    .background(Capsule().fill(activePowerUp == p.id ? activeTheme.accent.opacity(0.25) : Color.white.opacity(0.10)).overlay(Capsule().stroke(activePowerUp == p.id ? activeTheme.accent.opacity(0.65) : activeTheme.accent.opacity(0.22), lineWidth: 1)))
                                    .foregroundStyle(activePowerUp == p.id ? activeTheme.accent : activeTheme.textPrimary)
                                }
                                .buttonStyle(.plain).disabled(remaining > 0).opacity(remaining > 0 ? 0.4 : 1.0)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 2)

            if !message.isEmpty {
                HStack(spacing: 6) {
                    Text(messageIcon).font(.caption)
                    Text(message).font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(messageIsPositive ? Color.cafeGreen : Color.red.opacity(0.9))
                    Spacer()
                }
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(messageBackgroundColor).overlay(RoundedRectangle(cornerRadius: 10).stroke(messageBorderColor, lineWidth: 1)))
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.25), value: message)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(activeTheme.cardFill.opacity(0.85))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(activeTheme.accent.opacity(0.28), lineWidth: 1.5))
                .shadow(color: Color.black.opacity(0.30), radius: 14, x: 0, y: 6)
        )
    }

    // MARK: - Seat Card
    @ViewBuilder
    func seatCard(index i: Int) -> some View {
        let customer = seated[i]
        let leaveOffset = leavingSeatOffsets[i] ?? 0
        let leaveOpacity = leavingSeatOpacities[i] ?? 1.0

        ZStack {
            VStack(spacing: 7) {
                if let c = customer { seatCardOccupied(c) } else { seatCardEmpty() }
            }
            .padding(10).frame(maxWidth: .infinity, minHeight: 100)
            .background(seatCardBackground(customer: customer))

            // MARK: Checkmark overlay
            if completedSeatIndex == i {
                CheckmarkBurstView()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .offset(x: leaveOffset)
        .opacity(leaveOpacity)
    }

    @ViewBuilder
    private func seatCardOccupied(_ c: Customer) -> some View {
        let urgent = c.patience < 0.2
        HStack(alignment: .top) {
            Text(c.emoji).font(.system(size: 26))
                .scaleEffect(urgent ? 1.08 : 1.0)
                .animation(urgent ? .easeInOut(duration: 0.45).repeatForever(autoreverses: true) : .default, value: urgent)
            Spacer()
            Text(c.mood.rawValue).font(.caption)
        }
        orderChips(for: c)
        patienceBar(patience: c.patience)
    }

    @ViewBuilder
    private func orderChips(for c: Customer) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(groupedOrder(c.order), id: \.item.id) { g in orderChip(g: g) }
            }
        }
    }

    @ViewBuilder
    private func orderChip(g: (item: MenuItem, count: Int)) -> some View {
        let isSpec = g.item.id == dailySpecialID
        HStack(spacing: 2) {
            Text(g.item.emoji).font(.caption)
            if isSpec { Text("★").font(.system(size: 8)).foregroundStyle(Color.cafeGold) }
            if g.count > 1 { Text("×\(g.count)").font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(activeTheme.textPrimary.opacity(0.7)) }
        }
        .padding(.horizontal, 5).padding(.vertical, 3)
        .background(Capsule().fill(isSpec ? Color.cafeGold.opacity(0.20) : Color.white.opacity(0.12)).overlay(Capsule().stroke(isSpec ? Color.cafeGold.opacity(0.45) : activeTheme.accent.opacity(0.30), lineWidth: 0.5)))
    }

    private func patienceBarColor(_ patience: Double) -> LinearGradient {
        if patience < 0.3 { return LinearGradient(colors: [Color.red.opacity(0.9), Color.red], startPoint: .leading, endPoint: .trailing) }
        if patience < 0.6 { return LinearGradient(colors: [Color.orange.opacity(0.9), Color.orange], startPoint: .leading, endPoint: .trailing) }
        return LinearGradient(colors: [activeTheme.progressColor.opacity(0.9), activeTheme.progressColor], startPoint: .leading, endPoint: .trailing)
    }

    @ViewBuilder
    private func patienceBar(patience: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.10)).frame(height: 5)
                RoundedRectangle(cornerRadius: 4)
                    .fill(patienceBarColor(patience))
                    .frame(width: geo.size.width * max(0, patience), height: 5)
                    .shadow(color: (patience < 0.3 ? Color.red : activeTheme.progressColor).opacity(0.6), radius: 3)
                    .animation(.linear(duration: 0.05), value: patience)
            }
        }
        .frame(height: 5)
    }

    @ViewBuilder
    private func seatCardEmpty() -> some View {
        Spacer()
        VStack(spacing: 4) {
            Text("🪑").font(.system(size: 24)).opacity(0.18)
            Text("Empty").font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(activeTheme.textSecondary.opacity(0.45))
        }
        Spacer()
    }

    private func seatCardBackground(customer: Customer?) -> some View {
        let isUrgent = customer != nil && customer!.patience < 0.2
        let strokeColor: Color = isUrgent ? Color.red.opacity(0.50) : customer != nil ? activeTheme.accent.opacity(0.35) : activeTheme.accent.opacity(0.12)
        let strokeWidth: CGFloat = isUrgent ? 1.5 : 1.0
        let fillOpacity: Double = customer != nil ? 0.07 : 0.03
        return RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(fillOpacity))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: strokeWidth))
            .shadow(color: Color.black.opacity(0.20), radius: 5, x: 0, y: 3)
    }

    // MARK: - Menu Grid
    var menuGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MENU").font(.system(size: 10, weight: .heavy, design: .rounded)).tracking(3).foregroundStyle(activeTheme.textSecondary)
                Spacer()
                if streakCount >= 3 {
                    HStack(spacing: 4) {
                        Text("🔥")
                        Text("×\(comboMultiplier) streak active!").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(Color.orange)
                    }
                } else if let sp = dailySpecial {
                    HStack(spacing: 3) {
                        Text("★").font(.system(size: 10, weight: .black)).foregroundStyle(Color.cafeGold)
                        Text("Daily: \(sp.emoji) \(sp.name) ×2").font(.system(size: 10, design: .rounded)).foregroundStyle(Color.cafeGold.opacity(0.85))
                    }
                } else {
                    Text("Tap to serve").font(.system(size: 10, design: .rounded)).foregroundStyle(activeTheme.textSecondary.opacity(0.55))
                }
            }
            .padding(.horizontal, 2)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 8) {
                ForEach(menu.filter { $0.unlockLevel <= level }) { item in menuButton(item) }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(activeTheme.cardFill.opacity(0.85))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(activeTheme.accent.opacity(0.28), lineWidth: 1.5))
                .shadow(color: Color.black.opacity(0.30), radius: 14, x: 0, y: 6)
        )
    }

    @ViewBuilder
    func menuButton(_ item: MenuItem) -> some View {
        let isSpecial = item.id == dailySpecialID
        Button { serve(item) } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 6) {
                    Text(item.emoji).font(.system(size: 28)).shadow(color: Color.black.opacity(0.20), radius: 3, x: 0, y: 2)
                    Text(item.name).font(.system(size: 11, weight: .semibold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.8)
                        .foregroundStyle(isSpecial ? Color.cafeGold : activeTheme.textPrimary)
                    Text(isSpecial ? "+\(item.price * 2)🪙 ★" : "+\(item.price)🪙").font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(isSpecial ? Color.cafeGold.opacity(0.9) : activeTheme.textSecondary)
                }
                .padding(.vertical, 10).padding(.horizontal, 6).frame(maxWidth: .infinity)
                if isSpecial { Text("★").font(.system(size: 10, weight: .heavy)).foregroundStyle(Color.cafeGold).padding(5) }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSpecial
                          ? LinearGradient(colors: [Color.cafeGold.opacity(0.18), Color.cafeGold.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                          : LinearGradient(colors: [activeTheme.accent.opacity(0.12), activeTheme.accent.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSpecial ? Color.cafeGold.opacity(0.50) : activeTheme.accent.opacity(0.28), lineWidth: isSpecial ? 1.5 : 1.0))
                    .shadow(color: isSpecial ? Color.cafeGold.opacity(0.22) : Color.black.opacity(0.15), radius: isSpecial ? 8 : 4, x: 0, y: 2)
            )
        }
        .buttonStyle(MenuButtonStyle())
    }

    // MARK: - Streak Burst
    var streakBurstView: some View {
        VStack {
            Spacer()
            Text(streakCount >= 10 ? "🔥 LEGENDARY! ×\(comboMultiplier)" : streakCount >= 5 ? "🔥 ON FIRE! ×\(comboMultiplier)" : "🔥 COMBO ×\(comboMultiplier)")
                .font(.system(size: 20, weight: .black, design: .rounded)).foregroundStyle(.white)
                .padding(.horizontal, 22).padding(.vertical, 11)
                .background(Capsule().fill(LinearGradient(colors: [Color.orange, Color(red:0.9,green:0.4,blue:0.1)], startPoint: .leading, endPoint: .trailing)).shadow(color: Color.orange.opacity(0.55), radius: 14, x: 0, y: 4))
                .scaleEffect(showStreakBurst ? 1.0 : 0.4).opacity(showStreakBurst ? 1.0 : 0.0)
                .animation(.spring(response: 0.32, dampingFraction: 0.58), value: showStreakBurst)
            Spacer()
        }
        .allowsHitTesting(false)
    }

    // MARK: - Profile Panel
    var profileSheet: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.40).ignoresSafeArea().onTapGesture { withAnimation(.spring(response: 0.35)) { showProfile = false } }
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("🏅 Achievements").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Color.cafeParchment)
                        Text("\(achievements.count) earned · Best: \(highScore)🪙").font(.system(size: 10, design: .rounded)).foregroundStyle(Color.cafeLatte.opacity(0.7))
                    }
                    Spacer()
                    Button { withAnimation(.spring(response: 0.35)) { showProfile = false } } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Color.cafeLatte).font(.title3)
                    }.buttonStyle(.plain)
                }
                Divider().overlay(Color.cafeLatte.opacity(0.20))
                if achievements.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("🫙").font(.title)
                            Text("No achievements yet.\nStart serving customers!").font(.system(size: 12, design: .rounded)).foregroundStyle(Color.cafeLatte.opacity(0.6)).multilineTextAlignment(.center)
                        }.padding(.vertical, 10)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(achievements) { a in
                                HStack(spacing: 10) {
                                    Text("🏅").font(.title3).frame(width: 34, height: 34).background(Circle().fill(Color.cafeAmber.opacity(0.20)).overlay(Circle().stroke(Color.cafeAmber.opacity(0.35), lineWidth: 1)))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(a.title).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Color.cafeParchment)
                                        Text(a.detail).font(.system(size: 10, design: .rounded)).foregroundStyle(Color.cafeLatte.opacity(0.7))
                                    }
                                    Spacer()
                                }
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cafeLatte.opacity(0.18), lineWidth: 1)))
                            }
                        }
                    }
                    .frame(maxHeight: 220)
                }
            }
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.cafeCanvas.opacity(0.96)).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.cafeLatte.opacity(0.25), lineWidth: 1.5)).shadow(color: Color.black.opacity(0.45), radius: 20, x: 0, y: 8))
            .padding(.horizontal, 14).padding(.top, 8).transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - START SCREEN
    var startScreen: some View {
        ZStack {
            Color.black.opacity(0.65 * startCardOpacity).ignoresSafeArea().animation(.easeInOut(duration: 0.45), value: startCardOpacity)
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea().opacity(startCardOpacity).animation(.easeInOut(duration: 0.45), value: startCardOpacity)
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    ZStack(alignment: .top) {
                        Text("☕").font(.system(size: 60)).shadow(color: Color.cafeMocha.opacity(0.5), radius: 12, x: 0, y: 6)
                        SteamView().frame(width: 40, height: 24).offset(y: -22)
                    }.frame(height: 70)
                    Text("Cozy Café").font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [Color.cafeMocha, Color(red: 0.52, green: 0.28, blue: 0.10)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text("Run your dream coffee shop").font(.system(size: 12, design: .rounded)).foregroundStyle(Color.cafeLatte)
                    if highScore > 0 {
                        Text("Best: \(highScore)🪙").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(Color.cafeAmber)
                            .padding(.horizontal, 14).padding(.vertical, 4)
                            .background(Capsule().fill(Color.cafeAmber.opacity(0.12)).overlay(Capsule().stroke(Color.cafeAmber.opacity(0.45), lineWidth: 1)))
                    }
                }
                HStack(spacing: 8) {
                    Rectangle().fill(LinearGradient(colors: [.clear, Color.cafeLatte.opacity(0.4)], startPoint: .leading, endPoint: .trailing)).frame(height: 1)
                    Text("✦").font(.system(size: 10)).foregroundStyle(Color.cafeLatte.opacity(0.6))
                    Rectangle().fill(LinearGradient(colors: [Color.cafeLatte.opacity(0.4), .clear], startPoint: .leading, endPoint: .trailing)).frame(height: 1)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Label("Your name", systemImage: "person").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(Color.cafeMocha)
                    TextField("Enter your name", text: $playerName).font(.system(size: 14, design: .rounded))
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.cafeCream).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cafeLatte.opacity(0.45), lineWidth: 1)).shadow(color: Color.cafeMocha.opacity(0.08), radius: 4, x: 0, y: 2))
                        .foregroundStyle(Color.cafeMocha)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Label("Pick your avatar", systemImage: "face.smiling").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(Color.cafeMocha)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                        ForEach(profileOptions, id: \.self) { emoji in
                            Button { profileEmoji = emoji; Haptics.selection() } label: {
                                Text(emoji).font(.title2).frame(width: 44, height: 44)
                                    .background(RoundedRectangle(cornerRadius: 12)
                                        .fill(profileEmoji == emoji
                                              ? LinearGradient(colors: [Color.cafeLatte.opacity(0.35), Color.cafeMocha.opacity(0.18)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                              : LinearGradient(colors: [Color.cafeCream, Color.cafeWarm], startPoint: .top, endPoint: .bottom))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(profileEmoji == emoji ? Color.cafeMocha.opacity(0.60) : Color.cafeLatte.opacity(0.25), lineWidth: profileEmoji == emoji ? 1.5 : 1))
                                        .shadow(color: profileEmoji == emoji ? Color.cafeMocha.opacity(0.18) : Color.cafeShadow, radius: profileEmoji == emoji ? 5 : 2, x: 0, y: 1))
                            }.buttonStyle(.plain)
                        }
                    }
                }
                Button {
                    Haptics.notify(.success); SoundManager.shared.play(.levelUp)
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) { startCardOffset = -60; startCardOpacity = 0 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showTutorial = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { showStartScreen = false }

                } label: {
                    HStack(spacing: 10) {
                        Text(profileEmoji)
                        Text(playerName.isEmpty ? "Start Playing" : "Start as \(playerName)").font(.system(size: 15, weight: .black, design: .rounded))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(RoundedRectangle(cornerRadius: 16).fill(LinearGradient(colors: [Color.cafeMocha, Color.cafeDark], startPoint: .topLeading, endPoint: .bottomTrailing)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cafeLatte.opacity(0.30), lineWidth: 1)).shadow(color: Color.cafeMocha.opacity(0.55), radius: 12, x: 0, y: 6))
                    .foregroundStyle(Color.cafeParchment)
                }.buttonStyle(.plain)
            }
            .padding(24).frame(maxWidth: 360)
            .background(ZStack {
                RoundedRectangle(cornerRadius: 28).fill(LinearGradient(colors: [Color.cafeCream, Color.cafeWarm], startPoint: .top, endPoint: .bottom))
                RoundedRectangle(cornerRadius: 28).fill(LinearGradient(colors: [Color.white.opacity(0.55), Color.clear], startPoint: .top, endPoint: .center))
                RoundedRectangle(cornerRadius: 28).stroke(Color.cafeLatte.opacity(0.30), lineWidth: 1)
            }.shadow(color: Color.black.opacity(0.45), radius: 32, x: 0, y: 14))
            .padding(.horizontal, 20).offset(y: startCardOffset).opacity(startCardOpacity)
            .animation(.spring(response: 0.55, dampingFraction: 0.78), value: startCardOffset)
        }
    }

    // MARK: - SHOP OVERLAY
    var shopOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea().background(.ultraThinMaterial)
            shopPanel.padding(.horizontal, 16)
        }
    }

    private var shopPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            shopHeader
            Divider().overlay(Color.cafeLatte.opacity(0.20)).padding(.bottom, 12)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    shopUpgradesSection
                    shopThemesSection
                    shopPowerUpsSection
                }
            }
        }
        .padding(18).frame(maxWidth: 380, maxHeight: 580)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.cafeCanvas).overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.cafeLatte.opacity(0.25), lineWidth: 1.5)).shadow(color: Color.black.opacity(0.5), radius: 24, x: 0, y: 10))
    }

    private var shopHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("☕ Shop").font(.system(size: 17, weight: .black, design: .rounded)).foregroundStyle(Color.cafeParchment)
                Text("Game paused — browse freely").font(.system(size: 10, design: .rounded)).foregroundStyle(Color.cafeGold.opacity(0.80))
            }
            Spacer()
            statChip("🪙", "\(coins)", highlight: true)
            Spacer().frame(width: 10)
            Button {
                withAnimation(.spring(response: 0.35)) { showShop = false }
                Haptics.impact(.light)
            } label: {
                Image(systemName: "xmark.circle.fill").font(.title2).foregroundStyle(Color.cafeLatte)
            }.buttonStyle(.plain)
        }
        .padding(.bottom, 12)
    }

    private var shopUpgradesSection: some View {
        shopSection("⚙️ Upgrades") {
            ForEach(shopItems) { item in upgradeRow(item) }
        }
    }

    @ViewBuilder
    private func upgradeRow(_ item: Upgrade) -> some View {
        let locked = level < item.unlockLevel
        let owned  = purchasedUpgrades.contains(item.id)
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.name).font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(locked ? Color.cafeLatte.opacity(0.40) : Color.cafeParchment)
                    if item.unlockLevel > 1 {
                        HStack(spacing: 3) {
                            Image(systemName: locked ? "lock.fill" : "checkmark.circle.fill").font(.system(size: 8, weight: .bold))
                            Text("Lv \(item.unlockLevel)").font(.system(size: 9, weight: .black, design: .rounded))
                        }
                        .foregroundStyle(locked ? Color.orange.opacity(0.80) : Color.cafeGreen)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(locked ? Color.orange.opacity(0.12) : Color.cafeGreen.opacity(0.12)).overlay(Capsule().stroke(locked ? Color.orange.opacity(0.35) : Color.cafeGreen.opacity(0.35), lineWidth: 1)))
                    }
                }
                Text(locked ? "Unlocks at level \(item.unlockLevel)" : item.description)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(locked ? Color.cafeLatte.opacity(0.30) : Color.cafeLatte.opacity(0.65))
            }
            Spacer()
            if owned {
                Label("Owned", systemImage: "checkmark.circle.fill").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(Color.cafeGreen)
            } else if locked {
                Text("Locked").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(Color.cafeLatte.opacity(0.30))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.04)).overlay(Capsule().stroke(Color.cafeLatte.opacity(0.12), lineWidth: 1)))
            } else {
                Button("Buy \(item.price)🪙") {
                    if coins >= item.price { coins -= item.price; purchasedUpgrades.insert(item.id); Haptics.notify(.success); SoundManager.shared.play(.complete) }
                }
                .font(.system(size: 11, weight: .bold, design: .rounded)).buttonStyle(.borderedProminent).tint(Color.cafeMocha).disabled(coins < item.price)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(locked ? Color.white.opacity(0.02) : Color.white.opacity(0.06)).overlay(RoundedRectangle(cornerRadius: 12).stroke(locked ? Color.cafeLatte.opacity(0.10) : Color.cafeLatte.opacity(0.20), lineWidth: 1)))
        .opacity(locked ? 0.65 : 1.0)
    }

    private var shopThemesSection: some View {
        shopSection("🎨 Themes") {
            ForEach(themes) { t in themeRow(t) }
        }
    }

    @ViewBuilder
    private func themeRow(_ t: CafeTheme) -> some View {
        let locked   = level < t.unlockLevel
        let owned    = ownedThemeNames.contains(t.name)
        let isActive = activeThemeName == t.name
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(t.background).frame(width: 44, height: 36)
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [t.accent, t.accentAlt], startPoint: .leading, endPoint: .trailing))
                        .frame(height: 10)
                    Spacer()
                }
                .frame(width: 44, height: 36).clipShape(RoundedRectangle(cornerRadius: 10))
                Text(t.emoji).font(.system(size: 14)).offset(y: 4)
            }
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isActive ? t.accent : Color.cafeLatte.opacity(0.25), lineWidth: isActive ? 2 : 1))
            .saturation(locked ? 0.25 : 1.0)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(t.name).font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(locked ? Color.cafeLatte.opacity(0.40) : Color.cafeParchment)
                    if t.unlockLevel > 1 {
                        HStack(spacing: 3) {
                            Image(systemName: locked ? "lock.fill" : "checkmark.circle.fill").font(.system(size: 8, weight: .bold))
                            Text("Lv \(t.unlockLevel)").font(.system(size: 9, weight: .black, design: .rounded))
                        }
                        .foregroundStyle(locked ? Color.orange.opacity(0.80) : Color.cafeGreen)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(locked ? Color.orange.opacity(0.12) : Color.cafeGreen.opacity(0.12)).overlay(Capsule().stroke(locked ? Color.orange.opacity(0.35) : Color.cafeGreen.opacity(0.35), lineWidth: 1)))
                    }
                }
                HStack(spacing: 5) {
                    ForEach([t.accent, t.progressColor, t.cardFill, t.textSecondary], id: \.self) { c in
                        Circle().fill(c).frame(width: 8, height: 8)
                    }
                    Text(locked ? "Unlocks at level \(t.unlockLevel)" : (t.price == 0 ? "Free" : "\(t.price)🪙"))
                        .font(.system(size: 9, design: .rounded)).foregroundStyle(Color.cafeLatte.opacity(0.55))
                }
            }
            Spacer()
            themeRowAction(t, locked: locked, owned: owned, isActive: isActive)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(isActive ? t.accent.opacity(0.10) : Color.white.opacity(locked ? 0.02 : 0.06)).overlay(RoundedRectangle(cornerRadius: 12).stroke(isActive ? t.accent.opacity(0.45) : Color.cafeLatte.opacity(locked ? 0.10 : 0.20), lineWidth: isActive ? 1.5 : 1)))
        .opacity(locked ? 0.65 : 1.0)
    }

    @ViewBuilder
    private func themeRowAction(_ t: CafeTheme, locked: Bool, owned: Bool, isActive: Bool) -> some View {
        if locked {
            Text("Locked").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(Color.cafeLatte.opacity(0.30))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.04)).overlay(Capsule().stroke(Color.cafeLatte.opacity(0.12), lineWidth: 1)))
        } else if owned {
            if isActive {
                Label("Active", systemImage: "checkmark.circle.fill").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(Color.cafeGreen)
            } else {
                Button("Equip") {
                    withAnimation(.easeInOut(duration: 0.35)) { activeThemeName = t.name }
                    Haptics.selection()
                }
                .font(.system(size: 11, weight: .bold, design: .rounded)).buttonStyle(.bordered).tint(t.accent)
            }
        } else {
            Button(t.price == 0 ? "Free" : "Buy \(t.price)🪙") {
                if t.price == 0 || coins >= t.price {
                    if t.price > 0 { coins -= t.price }
                    ownedThemeNames.insert(t.name)
                    withAnimation(.easeInOut(duration: 0.35)) { activeThemeName = t.name }
                    Haptics.notify(.success)
                }
            }
            .font(.system(size: 11, weight: .bold, design: .rounded)).buttonStyle(.borderedProminent).tint(Color.cafeMocha)
            .disabled(t.price > 0 && coins < t.price)
        }
    }

    private var shopPowerUpsSection: some View {
        shopSection("⚡️ Power-Ups") { ForEach(powerUps) { p in powerUpRow(p) } }
    }

    @ViewBuilder
    private func powerUpRow(_ p: PowerUp) -> some View {
        let count = ownedPowerUps[p.id] ?? 0
        HStack(spacing: 10) {
            Text(p.emoji).font(.title3).frame(width: 36, height: 36).background(Circle().fill(Color.white.opacity(0.10)).overlay(Circle().stroke(Color.cafeLatte.opacity(0.25), lineWidth: 1)))
            VStack(alignment: .leading, spacing: 1) {
                Text(p.name).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Color.cafeParchment)
                Text(p.effect).font(.system(size: 10, design: .rounded)).foregroundStyle(Color.cafeLatte.opacity(0.65))
            }
            Spacer()
            if count > 0 { Text("×\(count)").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(Color.cafeGold).padding(.trailing, 2) }
            Button("Buy \(p.price)🪙") {
                if coins >= p.price { coins -= p.price; ownedPowerUps[p.id] = (ownedPowerUps[p.id] ?? 0) + 1; Haptics.impact(.medium) }
            }
            .font(.system(size: 11, weight: .bold, design: .rounded)).buttonStyle(.borderedProminent).tint(Color.cafeMocha).disabled(coins < p.price)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cafeLatte.opacity(0.20), lineWidth: 1)))
    }

    @ViewBuilder
    func shopSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 13, weight: .black, design: .rounded)).foregroundStyle(Color.cafeLatte)
            content()
        }
    }

    // MARK: - LEVEL COMPLETE OVERLAY
    var levelCompleteOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea().background(.ultraThinMaterial)
            VStack(spacing: 18) {
                Text("🎉").font(.system(size: 56))
                VStack(spacing: 5) {
                    Text("Level Complete!").font(.system(size: 22, weight: .black, design: .rounded)).foregroundStyle(Color.cafeMocha)
                    Text("Welcome to Level \(level)").font(.system(size: 13, design: .rounded)).foregroundStyle(Color.cafeLatte)
                }
                HStack(spacing: 10) {
                    ForEach(0..<3) { i in
                        Image(systemName: i < levelStars ? "star.fill" : "star").font(.system(size: 26))
                            .foregroundStyle(i < levelStars ? Color.cafeGold : Color.cafeLatte.opacity(0.30))
                            .shadow(color: i < levelStars ? Color.cafeGold.opacity(0.55) : Color.clear, radius: 6)
                            .scaleEffect(i < levelStars ? 1.0 : 0.85)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(i) * 0.12), value: showLevelComplete)
                    }
                }
                Text(levelStars == 3 ? "Perfect service! ✨" : levelStars == 2 ? "Well done!" : "Room to improve!").font(.system(size: 11, design: .rounded)).foregroundStyle(Color.cafeLatte)
                let newItems = menu.filter { $0.unlockLevel == level }
                if !newItems.isEmpty {
                    VStack(spacing: 8) {
                        Text("NEW ITEMS UNLOCKED").font(.system(size: 9, weight: .black, design: .rounded)).tracking(2).foregroundStyle(Color.cafeMocha.opacity(0.55))
                        HStack(spacing: 8) {
                            ForEach(newItems) { item in
                                VStack(spacing: 3) {
                                    Text(item.emoji).font(.title2)
                                    Text(item.name).font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(Color.cafeMocha)
                                }
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.cafeLatte.opacity(0.18)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cafeLatte.opacity(0.35), lineWidth: 1)))
                            }
                        }
                    }
                    .padding(12).background(RoundedRectangle(cornerRadius: 14).fill(Color.cafeMocha.opacity(0.06)))
                }
                Button {
                    withAnimation(.spring(response: 0.35)) { showShop = true }
                    Haptics.impact(.light); SoundManager.shared.play(.coin)
                } label: {
                    ZStack(alignment: .topTrailing) {
                        HStack(spacing: 8) {
                            Text("Visit Shop").font(.system(size: 14, weight: .black, design: .rounded))
                            Image(systemName: "bag.fill").font(.system(size: 12, weight: .bold))
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [Color.cafeAmber.opacity(0.85), Color.cafeLatte.opacity(0.70)], startPoint: .topLeading, endPoint: .bottomTrailing)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cafeGold.opacity(0.55), lineWidth: 1.5)).shadow(color: Color.cafeAmber.opacity(0.40), radius: 8, x: 0, y: 4))
                        .foregroundStyle(Color.cafeDark)
                        Text("✨ Shop").font(.system(size: 9, weight: .black, design: .rounded)).foregroundStyle(Color.cafeDark)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Capsule().fill(Color.cafeGold).shadow(color: Color.cafeGold.opacity(0.6), radius: 4))
                            .offset(x: -8, y: -8)
                    }
                }.buttonStyle(.plain)
                Button {
                    levelMistakes = 0; showLevelComplete = false
                    withAnimation { showConfetti = false }
                    pickDailySpecial()
                } label: {
                    Text("Next Level  ▶").font(.system(size: 14, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [Color.cafeMocha, Color.cafeDark], startPoint: .topLeading, endPoint: .bottomTrailing)).shadow(color: Color.cafeMocha.opacity(0.45), radius: 10, x: 0, y: 5))
                        .foregroundStyle(Color.cafeParchment)
                }.buttonStyle(.plain)
            }
            .padding(26).frame(maxWidth: 310)
            .background(RoundedRectangle(cornerRadius: 26).fill(Color.cafeCream).overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.cafeLatte.opacity(0.25), lineWidth: 1.5)).shadow(color: Color.black.opacity(0.4), radius: 28, x: 0, y: 10))

            if showConfetti {
                ConfettiView().ignoresSafeArea().allowsHitTesting(false)
            }
        }
    }

    // MARK: - TRY AGAIN OVERLAY
    var tryAgainOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea().background(.ultraThinMaterial)
            VStack(spacing: 16) {
                Text("⚠️").font(.system(size: 50))
                VStack(spacing: 5) {
                    Text("Too Many Walk-Outs!").font(.system(size: 19, weight: .black, design: .rounded)).foregroundStyle(Color.cafeMocha)
                    Text("5 customers left unhappy.\nDon't worry, you've got this!").font(.system(size: 12, design: .rounded)).foregroundStyle(Color.cafeLatte).multilineTextAlignment(.center)
                }
                HStack(spacing: 10) {
                    Button {
                        retryLevel(); showTryAgain = false; SoundManager.shared.play(.serve); Haptics.impact(.medium)
                    } label: {
                        Text("Try Again").font(.system(size: 13, weight: .black, design: .rounded)).frame(maxWidth: .infinity).padding(.vertical, 13)
                            .background(RoundedRectangle(cornerRadius: 12).fill(LinearGradient(colors: [Color.cafeMocha, Color.cafeDark], startPoint: .topLeading, endPoint: .bottomTrailing)).shadow(color: Color.cafeMocha.opacity(0.35), radius: 6))
                            .foregroundStyle(Color.cafeParchment)
                    }.buttonStyle(.plain)
                    Button {
                        showTryAgain = false; showGameOver = true
                        Haptics.notify(.error)
                    } label: {
                        Text("Give Up").font(.system(size: 13, weight: .semibold, design: .rounded)).frame(maxWidth: .infinity).padding(.vertical, 13)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.cafeLatte.opacity(0.25)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cafeLatte.opacity(0.45), lineWidth: 1)))
                            .foregroundStyle(Color.cafeMocha)
                    }.buttonStyle(.plain)
                }
            }
            .padding(26).frame(maxWidth: 310)
            .background(RoundedRectangle(cornerRadius: 26).fill(Color.cafeCream).overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.cafeLatte.opacity(0.25), lineWidth: 1.5)).shadow(color: Color.black.opacity(0.4), radius: 28))
        }
    }

    // MARK: - GAME OVER
    var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.60).ignoresSafeArea().background(.ultraThinMaterial)
            VStack(spacing: 16) {
                Text("😞").font(.system(size: 58))
                VStack(spacing: 5) {
                    Text("Game Over").font(.system(size: 22, weight: .black, design: .rounded)).foregroundStyle(Color.cafeMocha)
                    Text("Better luck next time,\n\(playerName.isEmpty ? "Chef" : playerName)!").font(.system(size: 12, design: .rounded)).foregroundStyle(Color.cafeLatte).multilineTextAlignment(.center)
                }
                Text("Coins earned: \(coins)🪙").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Color.cafeAmber)
                    .padding(.horizontal, 18).padding(.vertical, 8)
                    .background(Capsule().fill(Color.cafeAmber.opacity(0.15)).overlay(Capsule().stroke(Color.cafeAmber.opacity(0.35), lineWidth: 1)))
                Button {
                    resetGame(fullReset: true); showGameOver = false; showStartScreen = true
                } label: {
                    Text("Start Over").font(.system(size: 14, weight: .black, design: .rounded)).frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [Color.cafeMocha, Color.cafeDark], startPoint: .topLeading, endPoint: .bottomTrailing)).shadow(color: Color.cafeMocha.opacity(0.45), radius: 10, x: 0, y: 5))
                        .foregroundStyle(Color.cafeParchment)
                }.buttonStyle(.plain)
            }
            .padding(26).frame(maxWidth: 300)
            .background(RoundedRectangle(cornerRadius: 26).fill(Color.cafeCream).overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.cafeLatte.opacity(0.25), lineWidth: 1.5)).shadow(color: Color.black.opacity(0.4), radius: 28))
        }
    }

    // MARK: - GAME COMPLETED
    var gameCompletedOverlay: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea().opacity(0.6)
            RadialGradient(colors: [Color.cafeGold.opacity(0.28), Color.cafeAmber.opacity(0.12), Color.clear], center: .center, startRadius: 10, endRadius: 340).ignoresSafeArea().allowsHitTesting(false)
            VStack(spacing: 16) {
                Image("congrats")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(spacing: 6) {
                    Text("You Did It!").font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [Color.cafeGold, Color.cafeAmber, Color.cafeParchment], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: Color.cafeGold.opacity(0.40), radius: 8, x: 0, y: 3)
                    Text("\(playerName.isEmpty ? "Chef" : playerName), you're officially\nthe #1 Coffee Shop Owner in town!").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Color.cafeParchment.opacity(0.90)).multilineTextAlignment(.center).lineSpacing(2)
                }

                HStack(spacing: 10) {
                    completionStat(emoji: "⭐", label: "All Levels", value: "5 / 5")
                    completionStat(emoji: "👥", label: "Customers", value: "Countless")
                    completionStat(emoji: "☕", label: "Coffee\nMastery", value: "100%")
                }

                VStack(spacing: 5) {
                    Text("FINAL SCORE").font(.system(size: 10, weight: .black, design: .rounded)).tracking(3).foregroundStyle(Color.cafeAmber.opacity(0.70))
                    Text("\(coins) 🪙").font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [Color.cafeGold, Color.cafeAmber], startPoint: .top, endPoint: .bottom))
                        .shadow(color: Color.cafeGold.opacity(0.45), radius: 10, x: 0, y: 3)
                    if coins >= highScore {
                        HStack(spacing: 5) {
                            Text("🎉")
                            Text("NEW PERSONAL BEST!").font(.system(size: 11, weight: .black, design: .rounded)).tracking(1).foregroundStyle(Color.cafeGold)
                            Text("🎉")
                        }
                    } else {
                        Text("Best: \(highScore)🪙").font(.system(size: 11, design: .rounded)).foregroundStyle(Color.cafeLatte.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity).padding(.vertical, 14).padding(.horizontal, 16)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.28)).overlay(RoundedRectangle(cornerRadius: 16).stroke(LinearGradient(colors: [Color.cafeGold.opacity(0.65), Color.cafeAmber.opacity(0.30)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)))

                Button {
                    resetGame(fullReset: true); showGameCompleted = false; showStartScreen = true
                    withAnimation { showConfetti = false }
                } label: {
                    HStack(spacing: 10) {
                        Text("☕").font(.system(size: 16))
                        Text("Open a New Café").font(.system(size: 14, weight: .black, design: .rounded))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [Color.cafeGold, Color.cafeAmber, Color.cafeMocha], startPoint: .topLeading, endPoint: .bottomTrailing)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cafeGold.opacity(0.60), lineWidth: 1.5)).shadow(color: Color.cafeGold.opacity(0.50), radius: 12, x: 0, y: 5))
                    .foregroundStyle(Color.cafeDark)
                }.buttonStyle(.plain)
            }
            .padding(22)
            .frame(maxWidth: 340)
            .fixedSize(horizontal: false, vertical: true)
            .background(RoundedRectangle(cornerRadius: 28).fill(LinearGradient(colors: [Color(red: 0.12, green: 0.07, blue: 0.02), Color(red: 0.20, green: 0.11, blue: 0.03)], startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.cafeGold.opacity(0.35), lineWidth: 1.5)).shadow(color: Color.black.opacity(0.65), radius: 36, x: 0, y: 14))
            .padding(.horizontal, 18)

            if showConfetti {
                ConfettiView().ignoresSafeArea().allowsHitTesting(false)
            }
        }
    }

    private func completionStat(emoji: String, label: String, value: String) -> some View {
        VStack(spacing: 5) {
            Text(emoji).font(.system(size: 22))
            Text(value).font(.system(size: 13, weight: .black, design: .rounded)).foregroundStyle(Color.cafeGold)
            Text(label).font(.system(size: 9, weight: .semibold, design: .rounded)).foregroundStyle(Color.cafeLatte.opacity(0.65)).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cafeGold.opacity(0.22), lineWidth: 1)))
    }

    // MARK: - GAME LOOP
    func startGame() {
        spawnTimer?.invalidate(); patienceTimer?.invalidate()
        spawnTimer = Timer.scheduledTimer(withTimeInterval: spawnInterval, repeats: true) { _ in
            guard !self.isGamePaused else { return }
            self.spawnCustomer(); self.seatFromQueue()
        }
        patienceTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard !self.isGamePaused else { return }
            for i in self.seated.indices {
                guard var c = self.seated[i] else { continue }
                c.patience -= self.patienceDrain
                c.mood = c.patience < 0.3 ? .angry : c.patience < 0.6 ? .neutral : .happy
                if c.patience <= 0 {
                    self.seated[i] = nil
                    self.triggerLeaveAnimation(for: i)
                } else {
                    self.seated[i] = c
                }
            }
        }
    }

    func triggerLeaveAnimation(for seatIndex: Int) {
        let floaterID = UUID()
        leaveFloaters.append(floaterID)

        leavingSeatOffsets[seatIndex] = 0
        leavingSeatOpacities[seatIndex] = 1.0

        withAnimation(.easeIn(duration: 0.35)) {
            leavingSeatOffsets[seatIndex] = 120
            leavingSeatOpacities[seatIndex] = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            self.leavingSeatOffsets.removeValue(forKey: seatIndex)
            self.leavingSeatOpacities.removeValue(forKey: seatIndex)
            self.coins = max(0, self.coins - 5)
            self.customersLost += 1
            self.streakCount = 0
            self.comboMultiplier = 1
            self.setMessage("A customer left! -5🪙", positive: false)
            SoundManager.shared.play(.leave)
            Haptics.notify(.error)
            if self.customersLost >= 5 && !self.showTryAgain && !self.showGameOver {
                self.showTryAgain = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            self.leaveFloaters.removeAll { $0 == floaterID }
        }
    }

    func spawnCustomer() {
        let available = menu.filter { $0.unlockLevel <= level }
        guard !available.isEmpty else { return }
        let comboSize = Int.random(in: 1...maxCombo)
        var order: [MenuItem] = []
        for _ in 0..<comboSize { if let item = available.randomElement() { order.append(item) } }
        queue.append(Customer(emoji: emojis.randomElement()!, order: order))
        SoundManager.shared.play(.newCustomer)
    }

    func seatFromQueue() {
        for i in seated.indices { if seated[i] == nil, !queue.isEmpty { seated[i] = queue.removeFirst() } }
    }

    func serve(_ item: MenuItem) {
        // Find the first seated customer who has this item in their order.
        // We write the mutated customer back to seated[i] immediately (before
        // any async work) so rapid back-to-back taps always see fresh state.
        for i in seated.indices {
            guard var c = seated[i] else { continue }
            guard let index = c.order.firstIndex(where: { $0.id == item.id }) else { continue }

            c.order.remove(at: index)

            let isSpecial   = item.id == dailySpecialID
            let multiplier  = purchasedUpgrades.contains("goldRush") && isSpecial ? 3 : isSpecial ? 2 : 1
            let basePrice   = item.price * multiplier
            let multiplied  = activePowerUp == "double" ? basePrice * 2 : basePrice
            let streakBonus = multiplied * (comboMultiplier - 1)
            let earned      = multiplied + streakBonus

            SoundManager.shared.play(.serve); Haptics.impact(.light)

            if c.order.isEmpty {
                // Write a sentinel so this seat is blocked from further taps
                // while the checkmark plays; nil it after the animation.
                seated[i] = c   // empty order — seat will clear shortly

                var tip = 0
                if c.patience > 0.7 { tip = purchasedUpgrades.contains("tipMagnet") ? 6 : 3; SoundManager.shared.play(.tip) }
                let perfectBonus  = purchasedUpgrades.contains("perfectService") && !c.hadMistake ? 5 : 0
                let interestBonus = purchasedUpgrades.contains("coinInterest") ? 1 : 0
                let total = earned + tip + perfectBonus + interestBonus
                coins += total; totalEarned += total

                triggerCheckmark(for: i)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    self.seated[i] = nil
                }

                customersServed += 1
                var msg = "+\(total)🪙 Done!"
                if tip > 0 { msg += " ✔" }
                if perfectBonus > 0 { msg += " ✨" }
                if comboMultiplier > 1 { msg += " 🔥×\(comboMultiplier)" }
                setMessage(msg, positive: true); showFloat(total)
                SoundManager.shared.play(.complete); Haptics.notify(.success)
                streakCount += 1; updateCombo(); unlockAchievementIfNeeded()
            } else {
                // Still has items — write updated order back immediately
                seated[i] = c
                coins += earned; totalEarned += earned
                setMessage("+\(earned)🪙 Keep going!", positive: true); showFloat(earned)
                SoundManager.shared.play(.coin); streakCount += 1; updateCombo()
            }

            checkLevelUp(); return
        }

        // No seated customer wanted this item
        coins = max(0, coins - 5); levelMistakes += 1
        setMessage("Wrong item! -5🪙 ⚠️", positive: false)
        SoundManager.shared.play(.wrong); Haptics.notify(.error)
        penaltyActiveUntil = Date().addingTimeInterval(10)
        streakCount = 0; comboMultiplier = 1
        for i in seated.indices { if var c = seated[i] { c.hadMistake = true; seated[i] = c } }
    }

    func triggerCheckmark(for seatIndex: Int) {
        withAnimation { completedSeatIndex = seatIndex }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            withAnimation { self.completedSeatIndex = nil }
        }
    }

    func updateCombo() {
        let nm = streakCount >= 10 ? 3 : streakCount >= 5 ? 2 : 1
        if nm > comboMultiplier {
            comboMultiplier = nm
            triggerStreakBurst()
            SoundManager.shared.play(.powerUp)
            Haptics.impact(.heavy)
        }
    }

    func triggerStreakBurst() {
        withAnimation { showStreakBurst = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { withAnimation { showStreakBurst = false } }
    }

    func activate(powerUp: PowerUp) {
        if let remaining = powerUpCooldowns[powerUp.id], remaining > 0 { return }
        let currentCount = ownedPowerUps[powerUp.id] ?? 0
        guard currentCount > 0 else { return }
        ownedPowerUps[powerUp.id] = max(0, currentCount - 1)
        activePowerUp = powerUp.id; SoundManager.shared.play(.powerUp); Haptics.impact(.medium)
        switch powerUp.id {
        case "freeze": setMessage("🧊 Time frozen!", positive: true)
        case "double": setMessage("✨ Double coins active!", positive: true)
        case "spawn":  seatFromQueue(); setMessage("🚀 Quick seat!", positive: true)
        default: break
        }
        if powerUp.duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + powerUp.duration) {
                if self.activePowerUp == powerUp.id { self.activePowerUp = nil }
            }
        } else {
            DispatchQueue.main.async { activePowerUp = nil }
        }
        powerUpCooldowns[powerUp.id] = powerUp.cooldown
        cooldownTimers[powerUp.id]?.invalidate()
        cooldownTimers[powerUp.id] = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            let r = (self.powerUpCooldowns[powerUp.id] ?? 0) - 1
            if r <= 0 {
                self.powerUpCooldowns[powerUp.id] = 0
                timer.invalidate()
                self.cooldownTimers[powerUp.id] = nil
            } else {
                self.powerUpCooldowns[powerUp.id] = r
            }
        }
    }

    func checkLevelUp() {
        if customersServed >= levelGoal {
            levelStars = levelMistakes == 0 ? 3 : levelMistakes <= 2 ? 2 : 1
            if level >= maxLevel {
                if coins > highScore { highScore = coins }
                withAnimation { showConfetti = true }
                showGameCompleted = true
                SoundManager.shared.play(.levelUp); Haptics.notify(.success)
            } else {
                level += 1; customersServed = 0
                withAnimation { showConfetti = true }
                showLevelComplete = true
                SoundManager.shared.play(.levelUp); Haptics.notify(.success)
                setMessage("🎉 Level \(level) unlocked!", positive: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation { self.showConfetti = false }
                }
            }
        }
    }

    func pickDailySpecial() {
        let available = menu.filter { $0.unlockLevel <= level }
        dailySpecialID = available.randomElement()?.id ?? "coffee"
    }

    func retryLevel() {
        customersServed = 0; customersLost = 0; levelMistakes = 0
        streakCount = 0; comboMultiplier = 1
        queue.removeAll(); seated = Array(repeating: nil, count: 3)
        leavingSeatOffsets.removeAll(); leavingSeatOpacities.removeAll()
        leaveFloaters.removeAll(); completedSeatIndex = nil
        penaltyActiveUntil = nil
        setMessage("Retrying level \(level)… You got this! ☕", positive: true)
    }

    func resetGame(fullReset: Bool) {
        spawnTimer?.invalidate(); patienceTimer?.invalidate(); spawnTimer = nil; patienceTimer = nil
        if coins > highScore { highScore = coins }
        coins = 0; level = 1; customersServed = 0; customersLost = 0
        levelMistakes = 0; totalEarned = 0; streakCount = 0; comboMultiplier = 1
        queue.removeAll(); seated = Array(repeating: nil, count: 3)
        leavingSeatOffsets.removeAll(); leavingSeatOpacities.removeAll()
        leaveFloaters.removeAll(); completedSeatIndex = nil; showConfetti = false
        showLevelComplete = false; showShop = false; showTryAgain = false
        penaltyActiveUntil = nil; startCardOffset = 0; startCardOpacity = 1; gameVisible = false
        setMessage("Welcome! ☕", positive: true)
        hasSeenTutorial = false
        if fullReset {
            purchasedUpgrades.removeAll()
            ownedThemeNames = ["Cozy"]; activeThemeName = "Cozy"
            ownedPowerUps.removeAll()
        }
    }

    func groupedOrder(_ order: [MenuItem]) -> [(item: MenuItem, count: Int)] {
        var result: [(item: MenuItem, count: Int)] = []
        var counted: Set<String> = []
        for item in order {
            if counted.contains(item.id) { continue }
            result.append((item: item, count: order.filter { $0.id == item.id }.count))
            counted.insert(item.id)
        }
        return result
    }

    func setMessage(_ text: String, positive: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) { message = text; messageIsPositive = positive }
    }

    func showFloat(_ value: Int) { floatCoinValue = value; floatCoinID = UUID() }

    func loadAchievements() {
        if let decoded = try? JSONDecoder().decode([Achievement].self, from: achievementsData), !decoded.isEmpty {
            achievements = decoded
        }
        if !showStartScreen { startGame() }
    }

    func unlockAchievementIfNeeded() {
        func add(_ title: String, _ detail: String) {
            guard !achievements.contains(where: { $0.title == title }) else { return }
            achievements.append(Achievement(id: UUID(), title: title, detail: detail))
            saveAchievements(); SoundManager.shared.play(.tip)
        }
        if customersServed == 1  { add("First Serve! ☕",   "Completed your very first order!") }
        if customersServed >= 10 { add("Speed Barista ⚡",  "Served 10 customers in a level!") }
        if customersServed >= 25 { add("Café Regular 🏡",   "Served 25 happy customers!") }
        if level >= 3            { add("Head Chef 👨‍🍳",      "Reached level 3!") }
        if level >= 5            { add("Café Master 🏆",    "Reached the maximum level!") }
        if coins >= 200          { add("High Roller 💰",    "Accumulated 200🪙!") }
        if streakCount >= 5      { add("Hot Streak 🔥",     "5 in a row without mistakes!") }
        if streakCount >= 10     { add("Legendary Brew ✨", "10 in a row — legendary!") }
        if comboMultiplier >= 3  { add("Combo King 👑",     "Reached ×3 combo!") }
    }

    func saveAchievements() {
        if let data = try? JSONEncoder().encode(achievements) { achievementsData = data }
    }
}

// MARK: - MENU BUTTON STYLE
struct MenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.91 : 1.0)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(.spring(response: 0.18, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

// MARK: - PREVIEW
#Preview { ContentView() }
