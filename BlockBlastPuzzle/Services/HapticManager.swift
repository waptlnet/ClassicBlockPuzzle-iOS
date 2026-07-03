import UIKit

/// 触觉反馈管理器 — 对标 Android Vibrator + VibrationEffect
/// 使用 UIImpactFeedbackGenerator / UINotificationFeedbackGenerator
final class HapticManager {
    static let shared = HapticManager()

    private let lightImpact     = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact    = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact     = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidImpact     = UIImpactFeedbackGenerator(style: .rigid)
    private let softImpact      = UIImpactFeedbackGenerator(style: .soft)
    private let notification    = UINotificationFeedbackGenerator()

    private init() {
        // 预热生成器，减少首次延迟
        lightImpact.prepare()
        mediumImpact.prepare()
    }

    // MARK: - 游戏事件反馈

    /// 方块放置成功
    func place() {
        lightImpact.impactOccurred()
    }

    /// 方块旋转
    func rotate() {
        softImpact.impactOccurred()
    }

    /// 行/列消除 — 消除行数越多反馈越强
    func clear(lines: Int) {
        switch lines {
        case 1:
            mediumImpact.impactOccurred()
        case 2:
            heavyImpact.impactOccurred()
        default: // 3+
            heavyImpact.impactOccurred(intensity: 1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.heavyImpact.impactOccurred(intensity: 0.6)
            }
        }
    }

    /// 连击反馈 — Combo 越高越强
    func combo(level: Int) {
        switch level {
        case 2:
            mediumImpact.impactOccurred()
        case 3:
            heavyImpact.impactOccurred(intensity: 0.8)
        default: // 4+
            rigidImpact.impactOccurred(intensity: 1.0)
        }
    }

    /// 完美清空
    func perfectClear() {
        notification.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.heavyImpact.impactOccurred(intensity: 1.0)
        }
    }

    /// 道具使用
    func powerUp() {
        mediumImpact.impactOccurred()
    }

    /// 炸弹爆炸
    func bomb() {
        heavyImpact.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.rigidImpact.impactOccurred(intensity: 0.7)
        }
    }

    /// 游戏结束
    func gameOver() {
        notification.notificationOccurred(.error)
    }

    /// 按钮点击
    func buttonTap() {
        lightImpact.impactOccurred()
    }
}
