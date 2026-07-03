import Foundation

/// 局势评估器 — 与 Android SituationEvaluator 完全一致
struct SituationEvaluator {
    let grid: Grid

    init(grid: Grid) {
        self.grid = grid
    }

    /// 填充率：已填格子数 / 总格子数
    func fillRate() -> Float {
        var filled = 0
        for r in 0..<grid.size {
            for c in 0..<grid.size {
                if grid.get(r, c) != 0 { filled += 1 }
            }
        }
        return Float(filled) / Float(grid.size * grid.size)
    }

    /// 待用方块中无处可放的数量
    func stuckBlockCount(pendingBlocks: [PendingBlock]) -> Int {
        pendingBlocks.filter { !$0.used && !grid.canPlaceAnywhere($0.shape) }.count
    }

    enum DangerLevel {
        case none, low, high, critical
    }

    func dangerLevel(pendingBlocks: [PendingBlock]) -> DangerLevel {
        let fr = fillRate()
        let stuck = stuckBlockCount(pendingBlocks: pendingBlocks)
        if fr > 0.80 || stuck >= 1 { return .critical }
        if fr > 0.65 { return .high }
        if fr > 0.45 { return .low }
        return .none
    }
}
