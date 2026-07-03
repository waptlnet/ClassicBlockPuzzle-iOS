import Foundation

/// 方块生成器配置 — 与 Android GeneratorConfig 完全一致
enum GeneratorConfig {
    static let batchSize = 3
    static let batchesGuarantee = 4

    // 尺寸分类
    static let smallMaxSize = 3
    static let mediumMinSize = 4
    static let mediumMaxSize = 6
    static let largeMinSize = 7

    // 卡死救援概率
    static let probStuck: Float = 0.40

    struct FillProbThreshold {
        let fillRateMax: Float
        let prob: Float
    }

    static let fillProbThresholds: [FillProbThreshold] = [
        FillProbThreshold(fillRateMax: 1.0, prob: 0.28),
        FillProbThreshold(fillRateMax: 0.80, prob: 0.18),
        FillProbThreshold(fillRateMax: 0.65, prob: 0.12),
        FillProbThreshold(fillRateMax: 0.45, prob: 0.08),
        FillProbThreshold(fillRateMax: 0.30, prob: 0.05),
    ]

    static func specialBlockProb(fillRate: Float, stuckCount: Int) -> Float {
        if stuckCount >= 1 { return probStuck }
        for t in fillProbThresholds {
            if fillRate > t.fillRateMax { return t.prob }
        }
        return fillProbThresholds.last?.prob ?? 0.05
    }

    // 类型权重结构
    struct TypeWeights {
        let bomb: Float
        let rainbow: Float
        let frozen: Float

        func toMap() -> [BlockType: Float] {
            [.bomb: bomb, .rainbow: rainbow, .frozen: frozen]
        }
    }

    static let wStuck = TypeWeights(bomb: 8, rainbow: 2, frozen: 0)
    static let wCritical = TypeWeights(bomb: 8, rainbow: 1.5, frozen: 0)
    static let wHighCombo = TypeWeights(bomb: 1, rainbow: 3, frozen: 0.3)
    static let wHigh = TypeWeights(bomb: 5, rainbow: 2, frozen: 0.5)
    static let wLow = TypeWeights(bomb: 2, rainbow: 2, frozen: 1.5)
    static let wNormal = TypeWeights(bomb: 0.5, rainbow: 1.5, frozen: 0.8)

    static let highComboThreshold = 3
    static let cooldownMultiplier: Float = 0.3

    /// 根据填充率返回 (小方块权重, 中方块权重, 大方块权重)
    static func sizeWeights(fillRate: Float) -> (small: Float, medium: Float, large: Float) {
        switch fillRate {
        case ...0.30: return (0.30, 0.50, 0.20)
        case ...0.45: return (0.40, 0.45, 0.15)
        case ...0.60: return (0.55, 0.38, 0.07)
        case ...0.75: return (0.70, 0.28, 0.02)
        default:      return (0.85, 0.15, 0.00)
        }
    }
}
