import XCTest
@testable import BlockBlastPuzzle

/// 网格测试：放置、消除、炸弹、冰冻、彩虹
final class GridTest: XCTestCase {

    var grid: Grid!

    override func setUp() {
        super.setUp()
        grid = Grid(size: 5)
    }

    func test初始网格全为0() {
        for r in 0..<5 {
            for c in 0..<5 {
                XCTAssertEqual(grid.get(r, c), 0)
            }
        }
    }

    func test直接赋值cells可读回() {
        grid.cells[2][3] = 5
        XCTAssertEqual(grid.get(2, 3), 5)
    }

    func testFindFullLines检测满行() {
        for c in 0..<5 { grid.cells[2][c] = 1 }
        let (rows, cols) = grid.findFullLines()
        XCTAssertTrue(rows.contains(2))
        XCTAssertTrue(cols.isEmpty)
    }

    func testFindFullLines不检测不满行() {
        for c in 0..<4 { grid.cells[2][c] = 1 }
        XCTAssertFalse(grid.findFullLines().rows.contains(2))
    }

    func testFindFullLines检测满列() {
        for r in 0..<5 { grid.cells[r][3] = 2 }
        let (rows, cols) = grid.findFullLines()
        XCTAssertTrue(rows.isEmpty)
        XCTAssertTrue(cols.contains(3))
    }

    func testFindFullLines同时返回满行和满列() {
        for c in 0..<5 { grid.cells[2][c] = 1 }
        for r in 0..<5 { grid.cells[r][4] = 2 }
        let (rows, cols) = grid.findFullLines()
        XCTAssertEqual(rows, [2])
        XCTAssertEqual(cols, [4])
    }

    func testClearLines清空指定行列() {
        for c in 0..<5 { grid.cells[2][c] = 1 }
        for r in 0..<5 { grid.cells[r][3] = 2 }
        grid.clearLines(rows: [2], cols: [3])
        for c in 0..<5 { XCTAssertEqual(grid.get(2, c), 0) }
        for r in 0..<5 { XCTAssertEqual(grid.get(r, 3), 0) }
    }

    func testBombExplode清除5x5区域() {
        for r in 0..<5 { for c in 0..<5 { grid.cells[r][c] = 1 } }
        _ = grid.bombExplode(centerRow: 2, centerCol: 2)
        for r in 0..<5 { for c in 0..<5 { XCTAssertEqual(grid.get(r, c), 0) } }
    }

    func test冰冻方块阻止行消除() {
        for c in 0..<5 { grid.cells[2][c] = 1 }
        grid.frozenCells[Position(2, 2)] = 3
        XCTAssertFalse(grid.findFullLines().rows.contains(2))
    }

    func testTickFreeze倒计时到0自动解冻() {
        grid.cells[3][3] = 1
        grid.frozenCells[Position(3, 3)] = 3
        grid.tickFreeze(); XCTAssertEqual(grid.frozenCells[Position(3, 3)], 2)
        grid.tickFreeze(); XCTAssertEqual(grid.frozenCells[Position(3, 3)], 1)
        grid.tickFreeze(); XCTAssertNil(grid.frozenCells[Position(3, 3)])
    }

    func testReset清空全部() {
        for r in 0..<5 { for c in 0..<5 { grid.cells[r][c] = (r + c) % 7 + 1 } }
        grid.frozenCells[Position(1, 1)] = 5
        grid.reset()
        for r in 0..<5 { for c in 0..<5 { XCTAssertEqual(grid.get(r, c), 0) } }
        XCTAssertTrue(grid.frozenCells.isEmpty)
    }

    func test空网格可放置任意形状() {
        for shape in ShapeLibrary.all {
            XCTAssertTrue(grid.canPlaceAnywhere(shape),
                "Size \(shape.size) should fit in \(grid.size)x\(grid.size)")
        }
    }

    func test满网格1x1无法放置() {
        for r in 0..<5 { for c in 0..<5 { grid.cells[r][c] = 1 } }
        XCTAssertFalse(grid.canPlaceAnywhere(ShapeLibrary.all.first { $0.size == 1 }!))
    }

    func testClearAllCells清除全部含冰冻() {
        for r in 0..<5 { for c in 0..<5 { grid.cells[r][c] = 1 } }
        grid.frozenCells[Position(1, 1)] = 5
        XCTAssertEqual(grid.clearAllCells(), 25)
        XCTAssertTrue(grid.frozenCells.isEmpty)
    }

    func test彩虹格子视为已填() {
        for c in 0..<4 { grid.cells[2][c] = 1 }
        grid.rainbowCells.insert(Position(2, 4))
        XCTAssertTrue(grid.findFullLines().rows.contains(2))
    }

    func testBombExplode跳过冰冻格子() {
        for r in 0..<5 { for c in 0..<5 { grid.cells[r][c] = 1 } }
        grid.frozenCells[Position(2, 2)] = 3
        _ = grid.bombExplode(centerRow: 2, centerCol: 2)
        XCTAssertEqual(grid.get(2, 2), 1)
        XCTAssertEqual(grid.get(1, 1), 0)
    }
}
