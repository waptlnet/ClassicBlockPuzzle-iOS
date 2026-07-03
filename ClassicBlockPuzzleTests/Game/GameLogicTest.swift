import XCTest
@testable import ClassicBlockPuzzle

/// GameLogic 主状态机测试：放置、旋转、消除、GameOver、撤销快照、提示
final class GameLogicTest: XCTestCase {

    var game: GameLogic!

    override func setUp() {
        super.setUp()
        game = GameLogic(gridSize: 5, generator: BlockGenerator(seed: 42))
        game.start()
    }

    // MARK: - 初始状态

    func testStart后网格清空且生成3个待用方块() {
        for r in 0..<5 { for c in 0..<5 { XCTAssertEqual(game.grid.get(r, c), 0) } }
        XCTAssertEqual(game.pendingBlocks.count, 3)
        XCTAssertFalse(game.isGameOver)
        XCTAssertEqual(game.score, 0)
    }

    // MARK: - 放置

    func test放置成功后方块被标记used并加分() {
        let block = game.pendingBlocks[0]
        guard let (pr, pc) = findPlaceable(block.shape) else {
            XCTFail("找不到可放置位置")
            return
        }
        let ok = game.placeBlock(atIndex: 0, atRow: pr, col: pc)
        XCTAssertTrue(ok)
        XCTAssertTrue(game.pendingBlocks[0].used)
        XCTAssertEqual(game.score, block.shape.size)
    }

    func test放置越界返回false() {
        XCTAssertFalse(game.placeBlock(atIndex: 0, atRow: 10, col: 10))
        XCTAssertFalse(game.pendingBlocks[0].used)
    }

    func testPlaceBlock索引越界返回false() {
        XCTAssertFalse(game.placeBlock(atIndex: -1, atRow: 0, col: 0))
        XCTAssertFalse(game.placeBlock(atIndex: 99, atRow: 0, col: 0))
    }

    func testPlaceBlock到已占用格子返回false() {
        game.grid.cells[0][0] = 1
        let block = game.pendingBlocks[0]
        if block.shape.cells.contains(Position(0, 0)) {
            XCTAssertFalse(game.placeBlock(atIndex: 0, atRow: 0, col: 0))
        }
    }

    // MARK: - 旋转

    func test旋转未用方块返回true且形状改变() {
        let original = game.pendingBlocks[0].shape
        let ok = game.rotateBlock(atIndex: 0)
        if original != original.rotate() {
            XCTAssertTrue(ok)
            XCTAssertNotEqual(original, game.pendingBlocks[0].shape)
        }
    }

    func test旋转已用方块返回false() {
        guard let pos = findPlaceable(game.pendingBlocks[0].shape) else { return }
        _ = game.placeBlock(atIndex: 0, atRow: pos.0, col: pos.1)
        XCTAssertFalse(game.rotateBlock(atIndex: 0))
    }

    func test旋转越界索引返回false() {
        XCTAssertFalse(game.rotateBlock(atIndex: -1))
        XCTAssertFalse(game.rotateBlock(atIndex: 99))
    }

    // MARK: - 提示

    func testFindHint返回可放置位置() {
        let hint = game.findHint()
        XCTAssertNotNil(hint)
        guard let (idx, r, c) = hint else { return }
        XCTAssertTrue(game.pendingBlocks.indices.contains(idx))
        XCTAssertTrue(game.grid.canPlace(game.pendingBlocks[idx].shape, at: Position(r, c)))
    }

    // MARK: - 快照与恢复

    func testSnapshot和Restore能回滚状态() {
        guard let pos = findPlaceable(game.pendingBlocks[0].shape) else {
            XCTFail("找不到位置")
            return
        }
        _ = game.placeBlock(atIndex: 0, atRow: pos.0, col: pos.1)
        let scoreBefore = game.score
        let snap = game.snapshot()

        if let pos2 = findPlaceable(game.pendingBlocks.first(where: { !$0.used })?.shape ?? BlockShape(cells: [])) {
            let idx2 = game.pendingBlocks.firstIndex(where: { !$0.used }) ?? 0
            _ = game.placeBlock(atIndex: idx2, atRow: pos2.0, col: pos2.1)
        }

        game.restore(snap)
        XCTAssertEqual(scoreBefore, game.score)
    }

    // MARK: - 状态恢复

    func testRestoreScoreState恢复分数和连击() {
        game.restoreScoreState(score: 250, combo: 3, maxCombo: 5)
        XCTAssertEqual(game.score, 250)
        XCTAssertEqual(game.combo, 3)
        XCTAssertEqual(game.maxCombo, 5)
    }

    // MARK: - GameOver

    func testIsGameOver初始为false() {
        XCTAssertFalse(game.isGameOver)
    }

    // MARK: - 辅助

    private func findPlaceable(_ shape: BlockShape) -> (Int, Int)? {
        let gs = game.grid.size
        for r in 0...(gs - shape.height) {
            for c in 0...(gs - shape.width) {
                if game.grid.canPlace(shape, at: Position(r, c)) {
                    return (r, c)
                }
            }
        }
        return nil
    }
}
