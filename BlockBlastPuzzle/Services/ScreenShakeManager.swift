import SwiftUI

/// 屏幕震动管理器 — 对标 Android ScreenShake
/// Combo 越高震动越强，消除行数越多震动越强
@MainActor
final class ScreenShakeManager: ObservableObject {
    static let shared = ScreenShakeManager()

    @Published var offset: CGSize = .zero

    private var intensity: CGFloat = 0
    private var startTime: TimeInterval = 0
    private var duration: TimeInterval = 0
    private var displayLink: CADisplayLink?

    private init() {}

    /// 触发震动
    /// - Parameters:
    ///   - intensity: 强度（像素），建议 3~12
    ///   - duration: 持续时间（秒），建议 0.1~0.4
    func trigger(intensity: CGFloat, duration: TimeInterval) {
        self.intensity = intensity
        self.duration = duration
        self.startTime = CACurrentMediaTime()
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }

    /// Combo 分级震动（对标 Android）
    func triggerComboShake(combo: Int) {
        switch combo {
        case 2:
            trigger(intensity: 3, duration: 0.10)
        case 3:
            trigger(intensity: 6, duration: 0.20)
        case 4:
            trigger(intensity: 8, duration: 0.25)
        default: // 5+
            trigger(intensity: 12, duration: 0.30)
        }
    }

    /// 消除行震动
    func triggerClearShake(lines: Int) {
        let intensity = min(CGFloat(lines) * 3, 12)
        trigger(intensity: intensity, duration: 0.15)
    }

    /// 炸弹震动
    func triggerBombShake() {
        trigger(intensity: 10, duration: 0.25)
    }

    @objc private func update() {
        let elapsed = CACurrentMediaTime() - startTime
        guard elapsed < duration else {
            offset = .zero
            displayLink?.invalidate()
            displayLink = nil
            return
        }
        let progress = CGFloat(elapsed / duration)
        let decay = (1 - progress) * intensity
        offset = CGSize(
            width: CGFloat.random(in: -0.5...0.5) * 2 * decay,
            height: CGFloat.random(in: -0.5...0.5) * 2 * decay
        )
    }
}

// MARK: - SwiftUI Modifier

struct ScreenShakeModifier: ViewModifier {
    @ObservedObject var shaker = ScreenShakeManager.shared

    func body(content: Content) -> some View {
        content
            .offset(x: shaker.offset.width, y: shaker.offset.height)
    }
}

extension View {
    func screenShake() -> some View {
        modifier(ScreenShakeModifier())
    }
}
