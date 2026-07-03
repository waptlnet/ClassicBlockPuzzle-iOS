import Foundation

/// 特殊方块冷却管理器 — 与 Android SpecialBlockCooldown 完全一致
struct SpecialBlockCooldown {
    private let cooldownBatches = 1

    private var recentTypes: [(type: BlockType, batch: Int)] = []
    private var batchNumber: Int = 0

    mutating func onBatchStart() {
        batchNumber += 1
        while let first = recentTypes.first, batchNumber - first.batch > cooldownBatches {
            recentTypes.removeFirst()
        }
    }

    mutating func onSpecialGenerated(_ type: BlockType) {
        recentTypes.append((type, batchNumber))
    }

    func isCooling(_ type: BlockType) -> Bool {
        recentTypes.contains { $0.type == type }
    }

    mutating func reset() {
        recentTypes.removeAll()
        batchNumber = 0
    }
}
