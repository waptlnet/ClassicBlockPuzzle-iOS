import XCTest
@testable import BlockBlastPuzzle

/// 方块生成器测试：批量大小、可解性约束、保底小方块、种子可重现、关卡模式禁用冰冻
final class BlockGeneratorTest: XCTestCase {

    var generator: BlockGenerator!
    var grid: Grid!

    override func setUp() {
        super.setUp()
        generator = BlockGenerator(seed: 42)
        grid = Grid(size: 9)
    }

    func testGenerateBatch返回3个方块() {
        let batch = generator.generateBatch(grid: grid, combo: 0, prevPendingBlocks: [])
        XCTAssertEqual(batch.count, 3)
    }

    func test所有生成的方块颜色在1到7之间() {
        let batch = generator.generateBatch(grid: grid, combo: 0, prevPendingBlocks: [])
        for block in batch {
            XCTAssertTrue((1...7).contains(block.color), "颜色 \(block.color) 不在 [1,7]")
        }
    }

    func test所有生成的方块初始未使用() {
        let batch = generator.generateBatch(grid: grid, combo: 0, prevPendingBlocks: [])
        for block in batch {
            XCTAssertFalse(block.used)
        }
    }

    func test所有生成的方块形状来自ShapeLibrary() {
        let batch = generator.generateBatch(grid: grid, combo: 0, prevPendingBlocks: [])
        for block in batch {
            XCTAssertTrue(ShapeLibrary.all.contains(where: { $0.size == block.shape.size }),
                "生成了不在库中的方块形状")
        }
    }

    func test空网格上每批至少1个不超过3格的方块() {
        for i in 0..<20 {
            let batch = generator.generateBatch(grid: grid, combo: 0, prevPendingBlocks: [])
            XCTAssertTrue(batch.contains(where: { $0.shape.size <= GeneratorConfig.smallMaxSize }),
                "第 \(i) 批没有小方块")
        }
    }

    func test同一种子生成相同序列() {
        let g1 = BlockGenerator(seed: 123)
        let g2 = BlockGenerator(seed: 123)
        let b1 = g1.generateBatch(grid: Grid(size: 9), combo: 0, prevPendingBlocks: [])
        let b2 = g2.generateBatch(grid: Grid(size: 9), combo: 0, prevPendingBlocks: [])
        XCTAssertEqual(b1.count, b2.count)
        for i in b1.indices {
            XCTAssertEqual(b1[i].shape.cells, b2[i].shape.cells, "方块 \(i) 形状不同")
            XCTAssertEqual(b1[i].color, b2[i].color, "方块 \(i) 颜色不同")
            XCTAssertEqual(b1[i].type, b2[i].type, "方块 \(i) 类型不同")
        }
    }

    func test不同种子大概率生成不同序列() {
        let g1 = BlockGenerator(seed: 1)
        let g2 = BlockGenerator(seed: 999)
        let b1 = g1.generateBatch(grid: Grid(size: 9), combo: 0, prevPendingBlocks: [])
        let b2 = g2.generateBatch(grid: Grid(size: 9), combo: 0, prevPendingBlocks: [])
        let anyDiff = (0..<min(b1.count, b2.count)).contains { i in
            b1[i].shape.cells != b2[i].shape.cells || b1[i].color != b2[i].color
        }
        XCTAssertTrue(anyDiff, "两种子应产生不同序列")
    }

    func test关卡模式禁用冰冻方块() {
        let levelGen = BlockGenerator(allowFrozen: false)
        let levelGrid = Grid(size: 9)
        for _ in 0..<30 {
            let batch = levelGen.generateBatch(grid: levelGrid, combo: 0, prevPendingBlocks: [])
            for block in batch {
                XCTAssertNotEqual(block.type, .frozen, "关卡模式不应生成冰冻方块")
            }
            levelGen.reset()
        }
    }

    func testReset清空生成器内部状态() {
        for _ in 0..<5 {
            _ = generator.generateBatch(grid: grid, combo: 0, prevPendingBlocks: [])
        }
        generator.reset()
        XCTAssertEqual(generator.batchesSinceLast, 0)
        let batch = generator.generateBatch(grid: grid, combo: 0, prevPendingBlocks: [])
        XCTAssertEqual(batch.count, 3)
    }

    func testRestoreGeneratorState恢复保底计数() {
        generator.restoreGeneratorState(batchesSinceLast: 5)
        XCTAssertEqual(generator.batchesSinceLast, 5)
    }

    func test满网格时回退到最小方块() {
        for r in 0..<9 { for c in 0..<9 { grid.cells[r][c] = 1 } }
        let batch = generator.generateBatch(grid: grid, combo: 0, prevPendingBlocks: [])
        XCTAssertEqual(batch.count, 3)
        let minSize = ShapeLibrary.all.map(\.size).min() ?? 1
        for block in batch {
            XCTAssertEqual(block.shape.size, minSize)
        }
    }

    func test批量大小始终为3() {
        for _ in 0..<5 {
            let g = BlockGenerator()
            let b = g.generateBatch(grid: Grid(size: 9), combo: 0, prevPendingBlocks: [])
            XCTAssertEqual(b.count, GeneratorConfig.batchSize)
        }
    }
}
