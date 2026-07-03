import XCTest
@testable import ClassicBlockPuzzle

/// 评分系统测试：放置分、消除分、连击倍增、完美清空、同色奖励
final class ScoreSystemTest: XCTestCase {

    var scorer: ScoreSystem!

    override func setUp() {
        super.setUp()
        scorer = ScoreSystem()
    }

    func test初始分数为0() {
        XCTAssertEqual(scorer.score, 0)
        XCTAssertEqual(scorer.combo, 0)
        XCTAssertEqual(scorer.maxCombo, 0)
    }

    func test放置方块加分等于格数() {
        let gained = scorer.onPlace(blockSize: 5)
        XCTAssertEqual(gained, 5)
        XCTAssertEqual(scorer.score, 5)
        XCTAssertEqual(scorer.lastGain, 5)
    }

    func test消除1行基础分10() {
        var g = Grid(size: 3)
        for c in 0..<3 { g.cells[1][c] = 1 }
        _ = scorer.onPlace(blockSize: 3)
        _ = scorer.onClear(rows: [1], cols: [], grid: g)
        XCTAssertEqual(scorer.score, 13)
    }

    func test消除2行享受15倍加成() {
        var g = Grid(size: 4)
        for r in 2...3 { for c in 0..<4 { g.cells[r][c] = 1 } }
        _ = scorer.onPlace(blockSize: 4)
        _ = scorer.onClear(rows: [2, 3], cols: [], grid: g)
        XCTAssertEqual(scorer.score, 34)
    }

    func test消除3行享受20倍加成() {
        var g = Grid(size: 4)
        for r in 1...3 { for c in 0..<4 { g.cells[r][c] = 1 } }
        _ = scorer.onPlace(blockSize: 2)
        _ = scorer.onClear(rows: [1, 2, 3], cols: [], grid: g)
        XCTAssertEqual(scorer.score, 62)
    }

    func test消除4行享受30倍加成() {
        var g = Grid(size: 5)
        for r in 0...3 { for c in 0..<5 { g.cells[r][c] = 1 } }
        _ = scorer.onPlace(blockSize: 2)
        _ = scorer.onClear(rows: [0, 1, 2, 3], cols: [], grid: g)
        XCTAssertEqual(scorer.score, 122)
    }

    func test消除5行享受40倍加成() {
        var g = Grid(size: 6)
        for r in 0..<5 { for c in 0..<6 { g.cells[r][c] = 1 } }
        _ = scorer.onPlace(blockSize: 2)
        _ = scorer.onClear(rows: [0, 1, 2, 3, 4], cols: [], grid: g)
        XCTAssertEqual(scorer.score, 202)
        XCTAssertEqual(scorer.lastGain, 5)
    }

    func test连击加成递增() {
        _ = scorer.onPlace(blockSize: 3)
        _ = scorer.onClear(rows: [0], cols: [], grid: fillRow(size: 3, row: 0))
        XCTAssertEqual(scorer.score, 13); XCTAssertEqual(scorer.combo, 1)

        _ = scorer.onPlace(blockSize: 3)
        _ = scorer.onClear(rows: [1], cols: [], grid: fillRow(size: 3, row: 1))
        XCTAssertEqual(scorer.score, 28); XCTAssertEqual(scorer.combo, 2)

        _ = scorer.onPlace(blockSize: 3)
        _ = scorer.onClear(rows: [0], cols: [], grid: fillRow(size: 3, row: 0))
        XCTAssertEqual(scorer.score, 45); XCTAssertEqual(scorer.combo, 3)
    }

    func test无消除断连击() {
        _ = scorer.onPlace(blockSize: 3)
        _ = scorer.onClear(rows: [0], cols: [], grid: fillRow(size: 3, row: 0))
        XCTAssertEqual(scorer.combo, 1)
        _ = scorer.onPlace(blockSize: 4)
        _ = scorer.onClear(rows: [], cols: [], grid: Grid(size: 3))
        XCTAssertEqual(scorer.combo, 0)
        XCTAssertEqual(scorer.maxCombo, 1)
    }

    func testReset清空状态() {
        _ = scorer.onPlace(blockSize: 3)
        _ = scorer.onClear(rows: [0], cols: [], grid: fillRow(size: 3, row: 0))
        scorer.reset()
        XCTAssertEqual(scorer.score, 0)
        XCTAssertEqual(scorer.combo, 0)
    }

    func testRestoreState恢复状态() {
        scorer.restoreState(score: 100, combo: 3, maxCombo: 5)
        XCTAssertEqual(scorer.score, 100)
        XCTAssertEqual(scorer.combo, 3)
        XCTAssertEqual(scorer.maxCombo, 5)
    }

    func test完美清空加分500() {
        _ = scorer.onPlace(blockSize: 2)
        scorer.onPerfectClear()
        XCTAssertEqual(scorer.score, 502)
        XCTAssertEqual(scorer.lastGain, 500)
    }

    func test完美清空增加combo() {
        _ = scorer.onPlace(blockSize: 2)
        scorer.onPerfectClear()
        XCTAssertEqual(scorer.combo, 1)
        XCTAssertEqual(scorer.maxCombo, 1)
    }

    func test同色行额外加50分() {
        var g = Grid(size: 4)
        for c in 0..<4 { g.cells[2][c] = 1 }
        _ = scorer.onPlace(blockSize: 3)
        _ = scorer.onClear(rows: [2], cols: [], grid: g)
        XCTAssertEqual(scorer.score, 63)
    }

    func test彩虹格子视为同色通配符() {
        var g = Grid(size: 4)
        g.cells[2][0] = 1
        g.cells[2][1] = 1
        g.cells[2][2] = 1
        g.rainbowCells.insert(Position(2, 3))
        _ = scorer.onPlace(blockSize: 3)
        _ = scorer.onClear(rows: [2], cols: [], grid: g)
        XCTAssertEqual(scorer.score, 63)
    }

    func test混合不同色含彩虹不加同色奖励() {
        var g = Grid(size: 4)
        g.cells[2][0] = 1
        g.cells[2][1] = 1
        g.cells[2][2] = 2
        g.rainbowCells.insert(Position(2, 3))
        _ = scorer.onPlace(blockSize: 3)
        _ = scorer.onClear(rows: [2], cols: [], grid: g)
        XCTAssertEqual(scorer.score, 13)
    }

    func test全彩虹行视为同色() {
        var g = Grid(size: 3)
        g.rainbowCells.insert(Position(1, 0))
        g.rainbowCells.insert(Position(1, 1))
        g.rainbowCells.insert(Position(1, 2))
        _ = scorer.onPlace(blockSize: 2)
        _ = scorer.onClear(rows: [1], cols: [], grid: g)
        XCTAssertEqual(scorer.score, 62)
    }

    func test同色列额外加50分() {
        var g = Grid(size: 4)
        for r in 0..<4 { g.cells[r][1] = 2 }
        _ = scorer.onPlace(blockSize: 3)
        _ = scorer.onClear(rows: [], cols: [1], grid: g)
        XCTAssertEqual(scorer.score, 63)
    }

    func test高分不溢出() {
        var g = Grid(size: 9)
        for r in 0..<9 { for c in 0..<9 { g.cells[r][c] = 1 } }
        for _ in 0..<100 {
            _ = scorer.onPlace(blockSize: 9)
            _ = scorer.onClear(rows: Array(0..<9), cols: [], grid: g)
        }
        XCTAssertGreaterThan(scorer.score, 0)
    }

    // MARK: - Helpers

    private func fillRow(size: Int, row: Int) -> Grid {
        var g = Grid(size: size)
        for c in 0..<size { g.cells[row][c] = 1 }
        return g
    }
}
