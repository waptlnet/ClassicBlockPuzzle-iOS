import SwiftUI

/// 光泽样式
enum GlossStyle: String, Codable, CaseIterable {
    case none, subtle, glass, metallic
}

/// 皮肤定义 — 对标 Android Skin
struct Skin: Identifiable, Equatable {
    let id: String
    var name: String { L10n.skinName(id) }
    let emoji: String
    let blockColors: [Color]
    let bgColor: Color
    let gridBgColor: Color
    let gridLineColor: Color
    let textPrimary: Color
    let textSecondary: Color
    let buttonStroke: Color
    let buttonFill: Color
    let cornerRadius: CGFloat
    let glossStyle: GlossStyle
    let requiredAchievement: String?

    static func == (lhs: Skin, rhs: Skin) -> Bool { lhs.id == rhs.id }
}

/// 皮肤仓库
enum SkinRepo {
    static let defaultSkinId = "morandi"

    static let all: [Skin] = [
        Skin(id: "morandi", emoji: "🎨",
             blockColors: [.clear, Color(hex: 0x5B8FF9), Color(hex: 0x5AD8A6), Color(hex: 0xF6BD16),
                          Color(hex: 0xE86452), Color(hex: 0x6DC8EC), Color(hex: 0x945FB9), Color(hex: 0xFF9845)],
             bgColor: .white, gridBgColor: .white, gridLineColor: Color(hex: 0x333333),
             textPrimary: Color(hex: 0x111111), textSecondary: Color(hex: 0x444444),
             buttonStroke: Color(hex: 0x444444), buttonFill: Color(hex: 0xF5F5F5),
             cornerRadius: 6, glossStyle: .subtle, requiredAchievement: nil),

        Skin(id: "macaron", emoji: "🍬",
             blockColors: [.clear, Color(hex: 0xFFB5BA), Color(hex: 0xFFD3B6), Color(hex: 0xFFEAA7),
                          Color(hex: 0xB5EAD7), Color(hex: 0xC7CEEA), Color(hex: 0xE2C2FF), Color(hex: 0xC9F0FF)],
             bgColor: Color(hex: 0xFFFBF0), gridBgColor: .white, gridLineColor: Color(hex: 0xDDD0D8),
             textPrimary: Color(hex: 0x5C4B51), textSecondary: Color(hex: 0x8E7B82),
             buttonStroke: Color(hex: 0xE8C4D0), buttonFill: Color(hex: 0xFFF0F3),
             cornerRadius: 10, glossStyle: .glass, requiredAchievement: nil),

        Skin(id: "grayscale", emoji: "⬛",
             blockColors: [.clear, Color(hex: 0x1A1A1A), Color(hex: 0x333333), Color(hex: 0x555555),
                          Color(hex: 0x777777), Color(hex: 0x999999), Color(hex: 0xAAAAAA), Color(hex: 0xBBBBBB)],
             bgColor: Color(hex: 0xF5F5F5), gridBgColor: .white, gridLineColor: Color(hex: 0x666666),
             textPrimary: Color(hex: 0x1A1A1A), textSecondary: Color(hex: 0x555555),
             buttonStroke: Color(hex: 0x888888), buttonFill: Color(hex: 0xEEEEEE),
             cornerRadius: 4, glossStyle: .none, requiredAchievement: nil),

        Skin(id: "ocean", emoji: "🌊",
             blockColors: [.clear, Color(hex: 0x0077B6), Color(hex: 0x00B4D8), Color(hex: 0x90E0EF),
                          Color(hex: 0x48CAE4), Color(hex: 0x023E8A), Color(hex: 0x0096C7), Color(hex: 0xADE8F4)],
             bgColor: Color(hex: 0xF0F8FF), gridBgColor: .white, gridLineColor: Color(hex: 0xB0D4E8),
             textPrimary: Color(hex: 0x023E8A), textSecondary: Color(hex: 0x0077B6),
             buttonStroke: Color(hex: 0x90E0EF), buttonFill: Color(hex: 0xE8F4FD),
             cornerRadius: 8, glossStyle: .glass, requiredAchievement: "CLEAR_100_LINES"),

        Skin(id: "lava", emoji: "🌋",
             blockColors: [.clear, Color(hex: 0xFF4500), Color(hex: 0xFF6B35), Color(hex: 0xFF8C42),
                          Color(hex: 0xFFA500), Color(hex: 0xDC143C), Color(hex: 0xFF5349), Color(hex: 0xFF7043)],
             bgColor: Color(hex: 0x1A1A1A), gridBgColor: Color(hex: 0x2C2C2C), gridLineColor: Color(hex: 0xFF4500),
             textPrimary: Color(hex: 0xFF8C42), textSecondary: Color(hex: 0xFF6B35),
             buttonStroke: Color(hex: 0xFF4500), buttonFill: Color(hex: 0x333333),
             cornerRadius: 4, glossStyle: .metallic, requiredAchievement: "COMBO_5"),

        Skin(id: "forest", emoji: "🌲",
             blockColors: [.clear, Color(hex: 0x2D6A4F), Color(hex: 0x40916C), Color(hex: 0x52B788),
                          Color(hex: 0x74C69D), Color(hex: 0x1B4332), Color(hex: 0x95D5B2), Color(hex: 0xB7E4C7)],
             bgColor: Color(hex: 0xF0F7F0), gridBgColor: Color(hex: 0xFAFFFA), gridLineColor: Color(hex: 0xB7D7B7),
             textPrimary: Color(hex: 0x1B4332), textSecondary: Color(hex: 0x40916C),
             buttonStroke: Color(hex: 0x52B788), buttonFill: Color(hex: 0xE8F5E8),
             cornerRadius: 8, glossStyle: .subtle, requiredAchievement: "ALL_LEVELS"),

        Skin(id: "sunset", emoji: "🌅",
             blockColors: [.clear, Color(hex: 0xFF6B6B), Color(hex: 0xFFA07A), Color(hex: 0xFFD93D),
                          Color(hex: 0xC77DFF), Color(hex: 0xFF8C61), Color(hex: 0xE8A87C), Color(hex: 0xFFB347)],
             bgColor: Color(hex: 0xFFF5EE), gridBgColor: .white, gridLineColor: Color(hex: 0xFFCBA4),
             textPrimary: Color(hex: 0x5C3A21), textSecondary: Color(hex: 0xC77DFF),
             buttonStroke: Color(hex: 0xFFA07A), buttonFill: Color(hex: 0xFFF0E8),
             cornerRadius: 12, glossStyle: .glass, requiredAchievement: "SCORE_1000"),

        Skin(id: "midnight", emoji: "🌙",
             blockColors: [.clear, Color(hex: 0x9B59B6), Color(hex: 0x3498DB), Color(hex: 0x1ABC9C),
                          Color(hex: 0xE67E22), Color(hex: 0xE74C3C), Color(hex: 0x2ECC71), Color(hex: 0xF1C40F)],
             bgColor: Color(hex: 0x1A1A2E), gridBgColor: Color(hex: 0x16213E), gridLineColor: Color(hex: 0x0F3460),
             textPrimary: Color(hex: 0xE94560), textSecondary: Color(hex: 0x7B8FA1),
             buttonStroke: Color(hex: 0x533483), buttonFill: Color(hex: 0x16213E),
             cornerRadius: 6, glossStyle: .metallic, requiredAchievement: "PERFECT_CLEAR"),

        Skin(id: "deep_sea", emoji: "🐙",
             blockColors: [.clear, Color(hex: 0xE53935), Color(hex: 0x43A047), Color(hex: 0xFDD835),
                          Color(hex: 0x29B6F6), Color(hex: 0x1E88E5), Color(hex: 0x8E24AA), Color(hex: 0x00ACC1)],
             bgColor: Color(hex: 0x0A5F9A), gridBgColor: Color(hex: 0x0F1E3A), gridLineColor: Color(hex: 0x1A3A5C),
             textPrimary: .white, textSecondary: Color(hex: 0x90CAF9),
             buttonStroke: Color(hex: 0x4FC3F7), buttonFill: Color(hex: 0x1565C0),
             cornerRadius: 6, glossStyle: .glass, requiredAchievement: "SCORE_5000"),
    ]

    static var `default`: Skin { all.first { $0.id == defaultSkinId }! }

    static func findById(_ id: String) -> Skin? { all.first { $0.id == id } }
}

// MARK: - Color Hex

extension Color {
    init(hex: Int, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

// MARK: - SkinManager

@MainActor
final class SkinManager: ObservableObject {
    @Published var current: Skin = SkinRepo.default
    private let prefs = AppPreferences.shared

    init() {
        let id = prefs.currentSkinId
        if let skin = SkinRepo.findById(id), isUnlocked(skin) {
            current = skin
        } else {
            current = SkinRepo.default
        }
    }

    func isUnlocked(_ skin: Skin) -> Bool {
        skin.requiredAchievement == nil || prefs.isSkinUnlocked(skin.id)
    }

    func select(_ skin: Skin) {
        guard isUnlocked(skin) else { return }
        current = skin
        prefs.currentSkinId = skin.id
    }

    func unlock(_ skin: Skin) {
        prefs.setSkinUnlocked(skin.id)
    }
}
