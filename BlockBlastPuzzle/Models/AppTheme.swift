import SwiftUI

// MARK: - 主题色定义（对标 Android Theme.kt 的 BlockBlastColors / BlockBlastDarkColors）

/// App 全局主题色常量
enum AppTheme {
    // 浅色主题（对标 BlockBlastColors）
    static let lightPrimary = Color(hex: 0x4A90D9)
    static let lightOnPrimary = Color.white
    static let lightPrimaryVariant = Color(hex: 0xD6E8FF)
    static let lightSecondary = Color(hex: 0x7B68EE)
    static let lightSurface = Color(hex: 0xFEFEFE)
    static let lightBackground = Color(hex: 0xF5F5F5)
    static let lightOnSurface = Color(hex: 0x1C1B1F)
    static let lightOnBackground = Color(hex: 0x1C1B1F)

    // 深色主题（对标 BlockBlastDarkColors）
    static let darkPrimary = Color(hex: 0x8CB8F0)
    static let darkOnPrimary = Color(hex: 0x003258)
    static let darkPrimaryVariant = Color(hex: 0x1A3A5C)
    static let darkSecondary = Color(hex: 0xA99AF0)
    static let darkSurface = Color(hex: 0x1E1E2E)
    static let darkBackground = Color(hex: 0x13131F)
    static let darkOnSurface = Color(hex: 0xE6E1E5)
    static let darkOnBackground = Color(hex: 0xE6E1E5)

    /// 默认浅色棋盘背景
    static let boardLight = Color.white.opacity(0.95)
    /// 深色棋盘背景
    static let boardDark = Color(hex: 0x2A2A3C)

    /// 根据 ColorScheme 获取主色
    static func primary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? darkPrimary : lightPrimary
    }

    static func background(for scheme: ColorScheme) -> Color {
        scheme == .dark ? darkBackground : lightBackground
    }

    static func surface(for scheme: ColorScheme) -> Color {
        scheme == .dark ? darkSurface : lightSurface
    }

    static func onSurface(for scheme: ColorScheme) -> Color {
        scheme == .dark ? darkOnSurface : lightOnSurface
    }
}

// MARK: - 外观模式

enum AppearanceMode: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var label: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }
}

// MARK: - 主题 ViewModifier

/// 应用全局主题的 ViewModifier：字色、背景、棋盘色
struct AppThemeModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appearance") var appearance: String = AppearanceMode.system.rawValue

    private var effectiveColorScheme: ColorScheme {
        switch AppearanceMode(rawValue: appearance) ?? .system {
        case .dark: return .dark
        case .light: return .light
        case .system: return colorScheme
        }
    }

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(effectiveColorScheme)
            .tint(AppTheme.primary(for: effectiveColorScheme))
    }
}

extension View {
    func withAppTheme() -> some View {
        modifier(AppThemeModifier())
    }
}
