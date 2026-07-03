import Foundation

// MARK: - 确定性随机数生成器（对标 Android Random(seed)）

/// 基于 UInt64 种子的可预测随机数生成器，用于每日挑战
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    /// 64 位 xorshift* 算法
    mutating func next() -> UInt64 {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 0x2545F4914F6CDD1D
    }

    /// 生成 [0, 1) 浮点数
    mutating func nextFloat() -> Float {
        Float(next() & 0x00FF_FFFF_FFFF_FFFF) / Float(0x0100_0000_0000_0000)
    }
}

// MARK: - 待用方块

/// 待用方块（与 Kotlin PendingBlock 一致）
struct PendingBlock: Equatable, Codable {
    var shape: BlockShape
    var color: Int
    var used: Bool = false
    var type: BlockType = .normal
}

// MARK: - 方块生成器

/// 方块生成器 — 三层策略模型，与 Android BlockGenerator 完全一致
final class BlockGenerator {
    private var random: SeededRandomNumberGenerator
    private let allowFrozen: Bool
    private let dailyMode: Bool

    private var batchesSinceLastSpecial = 0
    private var cooldown = SpecialBlockCooldown()

    init(seed: UInt64? = nil, allowFrozen: Bool = true, dailyMode: Bool = false) {
        if let seed {
            self.random = SeededRandomNumberGenerator(seed: seed)
        } else {
            self.random = SeededRandomNumberGenerator(seed: UInt64.random(in: 0...UInt64.max))
        }
        self.allowFrozen = allowFrozen
        self.dailyMode = dailyMode
    }

    private let colors: [Int] = [1, 2, 3, 4, 5, 6, 7]

    /// 生成一批方块（3个）
    func generateBatch(
        grid: Grid,
        combo: Int = 0,
        prevPendingBlocks: [PendingBlock] = []
    ) -> [PendingBlock] {
        cooldown.onBatchStart()
        let eval = SituationEvaluator(grid: grid)

        let placeableShapes = ShapeLibrary.all.filter { grid.canPlaceAnywhere($0) }
        if placeableShapes.isEmpty {
            return fallbackMinBlocks()
        }

        let fillRate = eval.fillRate()
        let groups = groupBySize(placeableShapes)
        let weights = GeneratorConfig.sizeWeights(fillRate: fillRate)

        let effectiveCombo = dailyMode ? 0 : combo

        var result: [PendingBlock] = []
        var specialGenerated = false

        for _ in 0..<GeneratorConfig.batchSize {
            let shape = weightedPick(
                small: groups.small, medium: groups.medium, large: groups.large,
                wSmall: weights.small, wMedium: weights.medium
            )
            let color = colors.randomElement(using: &random)!

            let type = decideBlockType(
                eval: eval,
                prevPendingBlocks: prevPendingBlocks,
                combo: effectiveCombo
            )
            if type != .normal { specialGenerated = true }

            result.append(PendingBlock(shape: shape, color: color, type: type))
        }

        // 保底检查
        if !dailyMode && !specialGenerated && shouldGuarantee() {
            let idx = Int.random(in: 0..<result.count, using: &random)
            let forcedType = decideBlockType(
                eval: eval,
                prevPendingBlocks: prevPendingBlocks,
                combo: effectiveCombo,
                force: true
            )
            result[idx] = PendingBlock(shape: result[idx].shape, color: result[idx].color, type: forcedType)
            specialGenerated = true
        }

        if !dailyMode && specialGenerated {
            batchesSinceLastSpecial = 0
            for block in result where block.type != .normal {
                cooldown.onSpecialGenerated(block.type)
            }
        } else if !dailyMode {
            batchesSinceLastSpecial += 1
        }

        ensureHasSmall(&result, smallShapes: groups.small)

        return result
    }

    // MARK: - 决策引擎

    private func decideBlockType(
        eval: SituationEvaluator,
        prevPendingBlocks: [PendingBlock],
        combo: Int,
        force: Bool = false
    ) -> BlockType {
        let prob = force ? 1.0 : GeneratorConfig.specialBlockProb(
            fillRate: eval.fillRate(),
            stuckCount: eval.stuckBlockCount(pendingBlocks: prevPendingBlocks)
        )
        if Float.random(in: 0...1, using: &random) >= prob { return .normal }

        let weights = typeWeights(eval: eval, pendingBlocks: prevPendingBlocks, combo: combo)
        guard !weights.isEmpty else { return .normal }

        let total = weights.values.reduce(0, +)
        var r = Float.random(in: 0..<total, using: &random)
        for (type, w) in weights {
            r -= w
            if r <= 0 { return type }
        }
        return weights.keys.sorted().last ?? .normal
    }

    private func typeWeights(
        eval: SituationEvaluator,
        pendingBlocks: [PendingBlock],
        combo: Int
    ) -> [BlockType: Float] {
        let danger = eval.dangerLevel(pendingBlocks: pendingBlocks)
        let stuck = eval.stuckBlockCount(pendingBlocks: pendingBlocks)

        let base: [BlockType: Float] = {
            if stuck >= 1 { return GeneratorConfig.wStuck.toMap() }
            switch danger {
            case .critical: return GeneratorConfig.wCritical.toMap()
            case .high where combo >= GeneratorConfig.highComboThreshold:
                return GeneratorConfig.wHighCombo.toMap()
            case .high: return GeneratorConfig.wHigh.toMap()
            case .low: return GeneratorConfig.wLow.toMap()
            default: return GeneratorConfig.wNormal.toMap()
            }
        }()

        return base
            .mapValues { (type, w) in cooldown.isCooling(type) ? w * GeneratorConfig.cooldownMultiplier : w }
            .filter { !($0.key == .frozen && !allowFrozen) }
    }

    private func shouldGuarantee() -> Bool {
        batchesSinceLastSpecial >= GeneratorConfig.batchesGuarantee
    }

    // MARK: - 辅助

    func reset() {
        batchesSinceLastSpecial = 0
        cooldown.reset()
    }

    func restoreGeneratorState(batchesSinceLast: Int) {
        batchesSinceLastSpecial = batchesSinceLast
    }

    var batchesSinceLast: Int { batchesSinceLastSpecial }

    private func fallbackMinBlocks() -> [PendingBlock] {
        let minShape = ShapeLibrary.all.min { $0.size < $1.size } ?? ShapeLibrary.all[0]
        return (0..<3).map { _ in
            PendingBlock(shape: minShape, color: colors.randomElement(using: &random)!)
        }
    }

    private func groupBySize(_ shapes: [BlockShape]) -> (small: [BlockShape], medium: [BlockShape], large: [BlockShape]) {
        let small = shapes.filter { $0.size <= GeneratorConfig.smallMaxSize }
        let medium = shapes.filter { $0.size >= GeneratorConfig.mediumMinSize && $0.size <= GeneratorConfig.mediumMaxSize }
        let large = shapes.filter { $0.size >= GeneratorConfig.largeMinSize }
        return (small, medium, large)
    }

    private func weightedPick(
        small: [BlockShape], medium: [BlockShape], large: [BlockShape],
        wSmall: Float, wMedium: Float
    ) -> BlockShape {
        let r = Float.random(in: 0...1, using: &random)
        if r < wSmall, !small.isEmpty { return small.randomElement(using: &random)! }
        if r < wSmall + wMedium, !medium.isEmpty { return medium.randomElement(using: &random)! }
        if !large.isEmpty { return large.randomElement(using: &random)! }
        if !medium.isEmpty { return medium.randomElement(using: &random)! }
        if !small.isEmpty { return small.randomElement(using: &random)! }
        return ShapeLibrary.all[0]
    }

    private func ensureHasSmall(_ result: inout [PendingBlock], smallShapes: [BlockShape]) {
        let hasSmall = result.contains { $0.shape.size <= GeneratorConfig.smallMaxSize }
        if !hasSmall, !smallShapes.isEmpty {
            let idx = Int.random(in: 0..<result.count, using: &random)
            result[idx] = PendingBlock(
                shape: smallShapes.randomElement(using: &random)!,
                color: result[idx].color,
                type: result[idx].type
            )
        }
    }
}
