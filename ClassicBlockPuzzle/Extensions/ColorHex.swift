import SwiftUI

// MARK: - Color(hex:) initializer

extension Color {
    /// 从 UInt 创建 Color（格式：0xRRGGBB）
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }

    /// 从十六进制字符串创建 Color（格式："#RRGGBB" 或 "RRGGBB"）
    init?(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6, let value = UInt(hex, radix: 16) else { return nil }
        self.init(hex: value)
    }

    /// 将 Color 转为十六进制 UInt（近似值）
    var hexValue: UInt {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = UInt(r * 255), gi = UInt(g * 255), bi = UInt(b * 255)
        return (ri << 16) | (gi << 8) | bi
    }
}
