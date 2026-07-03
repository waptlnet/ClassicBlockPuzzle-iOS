import SwiftUI

// MARK: - 动画管理器（对标 Android AnimationManager）
// 统一管理 7 种动画的进度状态，由 View 层消费

@MainActor
final class AnimationManager: ObservableObject {

    // ═══ 消除闪烁 (clear flash) ═══
    @Published var clearFlashActive = false
    @Published var clearFlashPosition: Position? = nil

    // ═══ 分数弹跳 (score pop) ═══
    @Published var scorePopActive = false
    @Published var scorePopPosition: CGPoint = .zero

    // ═══ 连击特效 (combo effect) ═══
    @Published var comboEffectActive = false
    @Published var comboEffectLevel: Int = 2
    @Published var comboEffectProgress: CGFloat = 0

    // ═══ 危险脉冲 (danger pulse) ═══
    @Published var dangerPulseActive = false
    @Published var dangerPulseSpeed: DangerPulseSpeed = .none
    @Published var dangerPulseProgress: CGFloat = 0

    enum DangerPulseSpeed {
        case none, slow, fast
    }

    // ═══ 完美清空 (perfect clear) ═══
    @Published var perfectClearActive = false
    @Published var perfectClearProgress: CGFloat = 0

    // ═══ 炸弹闪光 (bomb flash) ═══
    @Published var bombFlashActive = false
    @Published var bombFlashPosition: Position? = nil

    // ═══ 提示高亮 (hint highlight) ═══
    @Published var hintActive = false
    @Published var hintPosition: Position? = nil

    // MARK: - 动画触发

    func triggerClearFlash(row: Int, col: Int) {
        clearFlashPosition = Position(row, col)
        clearFlashActive = true
        withAnimation(.easeOut(duration: 0.28)) {
            clearFlashActive = false
        }
    }

    func triggerScorePop(at point: CGPoint) {
        scorePopPosition = point
        scorePopActive = true
        withAnimation(.easeOut(duration: 0.7)) {
            scorePopActive = false
        }
    }

    func triggerComboEffect(level: Int) {
        comboEffectLevel = level
        comboEffectProgress = 0
        comboEffectActive = true
        withAnimation(.easeOut(duration: 0.8)) {
            comboEffectProgress = 1
        }
    }

    func triggerDangerPulse(fillRate: Float) {
        let newSpeed: DangerPulseSpeed
        if fillRate > 0.85 {
            newSpeed = .fast
        } else if fillRate > 0.70 {
            newSpeed = .slow
        } else {
            newSpeed = .none
        }

        guard newSpeed != .none else {
            stopDangerPulse()
            return
        }

        dangerPulseActive = true
        dangerPulseSpeed = newSpeed

        // 使用重复动画模拟脉冲
        let duration: TimeInterval = newSpeed == .fast ? 0.3 : 0.6
        dangerPulseProgress = 0
        withAnimation(
            .easeInOut(duration: duration)
            .repeatForever(autoreverses: true)
        ) {
            dangerPulseProgress = 1
        }
    }

    func triggerPerfectClear() {
        perfectClearActive = true
        perfectClearProgress = 0
        withAnimation(.easeOut(duration: 1.0)) {
            perfectClearProgress = 1
        }
    }

    func triggerBombFlash(row: Int, col: Int) {
        bombFlashPosition = Position(row, col)
        bombFlashActive = true
        withAnimation(.easeOut(duration: 0.5)) {
            bombFlashActive = false
        }
    }

    func triggerHint(at row: Int, col: Int) {
        hintPosition = Position(row, col)
        hintActive = true
        withAnimation(.easeOut(duration: 2.0)) {
            hintActive = false
        }
    }

    func stopDangerPulse() {
        dangerPulseActive = false
        dangerPulseSpeed = .none
        dangerPulseProgress = 0
    }

    func cancelAll() {
        clearFlashActive = false
        scorePopActive = false
        comboEffectActive = false
        stopDangerPulse()
        perfectClearActive = false
        bombFlashActive = false
        hintActive = false
    }
}
