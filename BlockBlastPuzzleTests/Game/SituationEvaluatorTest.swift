import XCTest
@testable import BlockBlastPuzzle

/// 局势评估器测试：填充率、危险等级、卡死计数
final class SituationEvaluatorTest: XCTestCase {

    func test空网格填充率为0() {
        let grid = Grid(size: 5)
        let eval = SituationEvaluator(grid: grid)
        XCTAssertEqual(eval.fillRate(), 0.0)
    }

    func test满网格填充率为1() {
        var grid = Grid(size: 3)
        for r in 0..<3 { for c in 0..<3 { grid.cells[r][c] = 1 } }
        XCTAssertEqual(SituationEvaluator(grid: grid).fillRate(), 1.0)
    }

    func test一半填充率() {
        var grid = Grid(size: 4)
        for r in 0..<4 { for c in 0..<2 { grid.cells[r][c] = 1 } }
        XCTAssertEqual(SituationEvaluator(grid: grid).fillRate(), 0.5)
    }

    func test空网格无危险() {
        XCTAssertEqual(
            SituationEvaluator.DangerLevel.none,
            SituationEvaluator(grid: Grid(size: 5)).dangerLevel(pendingBlocks: [])
        )
    }

    func test填充率045以上低危险() {
        var grid = Grid(size: 5)
        for i in 0..<12 { grid.cells[i / 5][i % 5] = 1 }
        XCTAssertEqual(
            SituationEvaluator.DangerLevel.low,
            SituationEvaluator(grid: grid).dangerLevel(pendingBlocks: [])
        )
    }

    func test填充率065以上高危险() {
        var grid = Grid(size: 5)
        for i in 0..<17 { grid.cells[i / 5][i % 5] = 1 }
        XCTAssertEqual(
            SituationEvaluator.DangerLevel.high,
            SituationEvaluator(grid: grid).dangerLevel(pendingBlocks: [])
        )
    }

    func test填充率080以上临界() {
        var grid = Grid(size: 5)
        for i in 0..<21 { grid.cells[i / 5][i % 5] = 1 }
        XCTAssertEqual(
            SituationEvaluator.DangerLevel.critical,
            SituationEvaluator(grid: grid).dangerLevel(pendingBlocks: [])
        )
    }

    func test卡死方块数统计() {
        var grid = Grid(size: 3)
        for i in 0..<8 { grid.cells[i / 3][i % 3] = 1 }
        let eval = SituationEvaluator(grid: grid)
        let bigShapes = ShapeLibrary.all.filter { $0.size > 1 }
        let pending = bigShapes.map { PendingBlock(shape: $0, color: 1) }
        XCTAssertGreaterThan(eval.stuckBlockCount(pendingBlocks: pending), 0)
    }
}
