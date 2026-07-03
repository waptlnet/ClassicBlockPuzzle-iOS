import XCTest
@testable import BlockBlastPuzzle

/// GeneratorConfig 配置参数与权重函数测试
final class GeneratorConfigTest: XCTestCase {

    func test批次大小为3() {
        XCTAssertEqual(GeneratorConfig.batchSize, 3)
    }

    func test保底间隔为正数() {
        XCTAssertGreaterThan(GeneratorConfig.batchesGuarantee, 0)
    }

    func test尺寸分类阈值单调递增() {
        XCTAssertLessThan(GeneratorConfig.smallMaxSize, GeneratorConfig.mediumMinSize)
        XCTAssertLessThan(GeneratorConfig.mediumMaxSize, GeneratorConfig.largeMinSize)
    }

    func test卡死概率最高() {
        let stuckProb = GeneratorConfig.specialBlockProb(fillRate: 0.0, stuckCount: 1)
        XCTAssertEqual(stuckProb, GeneratorConfig.probStuck)
        let maxFillProb = GeneratorConfig.fillProbThresholds.map(\.prob).max() ?? 0
        XCTAssertGreaterThanOrEqual(stuckProb, maxFillProb, "卡死救援概率应不低于任何填充率概率")
    }

    func test空网格时特殊方块概率最低() {
        let prob = GeneratorConfig.specialBlockProb(fillRate: 0.0, stuckCount: 0)
        let lastProb = GeneratorConfig.fillProbThresholds.last?.prob ?? 0
        XCTAssertEqual(prob, lastProb)
    }

    func test高填充率时特殊方块概率最高() {
        let prob = GeneratorConfig.specialBlockProb(fillRate: 0.95, stuckCount: 0)
        let firstProb = GeneratorConfig.fillProbThresholds.first?.prob ?? 0
        XCTAssertEqual(prob, firstProb)
    }

    func test概率随填充率单调递增() {
        let low = GeneratorConfig.specialBlockProb(fillRate: 0.1, stuckCount: 0)
        let mid = GeneratorConfig.specialBlockProb(fillRate: 0.5, stuckCount: 0)
        let high = GeneratorConfig.specialBlockProb(fillRate: 0.85, stuckCount: 0)
        XCTAssertLessThanOrEqual(low, mid, "低填充率概率 \(low) 应 <= 中 \(mid)")
        XCTAssertLessThanOrEqual(mid, high, "中填充率概率 \(mid) 应 <= 高 \(high)")
    }

    func test尺寸权重随填充率偏小() {
        let lowFill = GeneratorConfig.sizeWeights(fillRate: 0.1)
        let highFill = GeneratorConfig.sizeWeights(fillRate: 0.9)
        XCTAssertLessThanOrEqual(lowFill.small, highFill.small,
            "低填充小权重 \(lowFill.small) 应 <= 高填充 \(highFill.small)")
        XCTAssertGreaterThanOrEqual(lowFill.large, highFill.large,
            "低填充大权重 \(lowFill.large) 应 >= 高填充 \(highFill.large)")
    }

    func test所有类型权重非负() {
        let allWeights: [GeneratorConfig.TypeWeights] = [
            .wStuck, .wCritical, .wHighCombo, .wHigh, .wLow, .wNormal
        ]
        for w in allWeights {
            XCTAssertGreaterThanOrEqual(w.bomb, 0)
            XCTAssertGreaterThanOrEqual(w.rainbow, 0)
            XCTAssertGreaterThanOrEqual(w.frozen, 0)
        }
    }

    func test卡死状态不生成冰冻方块() {
        XCTAssertEqual(GeneratorConfig.wStuck.frozen, 0)
    }

    func test危险临界状态不生成冰冻方块() {
        XCTAssertEqual(GeneratorConfig.wCritical.frozen, 0)
    }

    func test冷却倍数小于1() {
        XCTAssertTrue((0...1).contains(GeneratorConfig.cooldownMultiplier))
    }

    func test高连击阈值为正() {
        XCTAssertGreaterThan(GeneratorConfig.highComboThreshold, 0)
    }

    func testTypeWeights转Map包含三种类型() {
        let map = GeneratorConfig.wNormal.toMap()
        XCTAssertEqual(map.count, 3)
        XCTAssertTrue(map.keys.contains(.bomb))
        XCTAssertTrue(map.keys.contains(.rainbow))
        XCTAssertTrue(map.keys.contains(.frozen))
    }

    func test尺寸权重三段之和合理() {
        for fillRate in [0.1, 0.3, 0.5, 0.7, 0.9] {
            let w = GeneratorConfig.sizeWeights(fillRate: Float(fillRate))
            XCTAssertGreaterThanOrEqual(w.small, 0)
            XCTAssertGreaterThanOrEqual(w.medium, 0)
            XCTAssertGreaterThanOrEqual(w.large, 0)
        }
    }
}
