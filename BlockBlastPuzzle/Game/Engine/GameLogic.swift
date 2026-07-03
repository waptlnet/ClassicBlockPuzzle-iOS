import Foundation

/// 游戏状态快照（撤销道具用）— 与 Kotlin GameStateSnapshot 一致
struct GameStateSnapshot: Codable {
    let gridData: [[Int]]
    let frozenCells: [Position: Int]
    let rainbowCells: Set<Position>
    let score: Int
    let combo: Int
    let snapPendingBlocks: [PendingBlock]
}

/// 游戏主逻辑 — 与 Android GameLogic 完全一致
struct GameLogic {
    let gridSize: Int
    var grid: Grid
    var pendingBlocks: [PendingBlock]
    private(set) var scorer: ScoreSystem
    let generator: BlockGenerator

    var score: Int { scorer.score }
    var combo: Int { scorer.combo }
    var maxCombo: Int { scorer.maxCombo }
    var lastGain: Int { scorer.lastGain }

    private(set) var isGameOver: Bool = false

    private(set) var lastClearedRows: [Int] = []
    private(set) var lastClearedCols: [Int] = []
    private(set) var lastClearedColors: [Position: Int] = [:]

    var lastPlacedTriggeredClear: Bool {
        !lastClearedRows.isEmpty || !lastClearedCols.isEmpty
    }

    private(set) var isPerfectClear: Bool = false

    init(gridSize: Int = 9, generator: BlockGenerator = BlockGenerator()) {
        self.gridSize = gridSize
        self.grid = Grid(size: gridSize)
        self.generator = generator
        self.scorer = ScoreSystem()
        self.pendingBlocks = []
    }

    // MARK: - 生命周期

    mutating func start() {
        grid.reset()
        scorer.reset()
        generator.reset()
        isGameOver = false
        isPerfectClear = false
        lastClearedRows = []
        lastClearedCols = []
        lastClearedColors = [:]
        pendingBlocks.removeAll()
        pendingBlocks = generator.generateBatch(grid: grid)
    }

    mutating func restoreScoreState(score: Int, combo: Int, maxCombo: Int) {
        scorer.restoreState(score: score, combo: combo, maxCombo: maxCombo)
    }

    // MARK: - 核心操作

    /// 放置方块。返回 true=成功
    @discardableResult
    mutating func placeBlock(atIndex index: Int, atRow baseR: Int, col baseC: Int) -> Bool {
        guard !isGameOver,
              index >= 0, index < pendingBlocks.count,
              !pendingBlocks[index].used else { return false }

        let block = pendingBlocks[index]
        let pos = Position(baseR, baseC)
        guard grid.canPlace(block.shape, at: pos) else { return false }

        grid.place(block.shape, at: pos, color: block.color, type: block.type)
        pendingBlocks[index].used = true
        scorer.onPlace(blockSize: block.shape.size)

        if block.type == .bomb {
            let centerR = baseR + block.shape.height / 2
            let centerC = baseC + block.shape.width / 2
            _ = grid.bombExplode(centerRow: centerR, centerCol: centerC)

            let (chainRows, chainCols) = grid.findFullLines()
            lastClearedRows = chainRows
            lastClearedCols = chainCols

            if !chainRows.isEmpty || !chainCols.isEmpty {
                lastClearedColors = collectClearedColors(rows: chainRows, cols: chainCols)
                scorer.onClear(rows: chainRows, cols: chainCols, grid: grid)
                grid.clearLines(rows: chainRows, cols: chainCols)
            } else {
                lastClearedColors = [:]
                _ = scorer.onClear(rows: [], cols: [], grid: grid)
            }
        } else {
            let (rows, cols) = grid.findFullLines()
            lastClearedRows = rows
            lastClearedCols = cols

            if !rows.isEmpty || !cols.isEmpty {
                lastClearedColors = collectClearedColors(rows: rows, cols: cols)
                scorer.onClear(rows: rows, cols: cols, grid: grid)
                grid.clearLines(rows: rows, cols: cols)
            } else {
                lastClearedColors = [:]
                _ = scorer.onClear(rows: [], cols: [], grid: grid)
            }
        }

        // 完美清空检测
        isPerfectClear = grid.isEmptyGrid()
        if isPerfectClear {
            scorer.onPerfectClear()
        }

        // 当前批用完 → 生成下一批
        if pendingBlocks.allSatisfy({ $0.used }) {
            pendingBlocks.removeAll()
            pendingBlocks = generator.generateBatch(
                grid: grid,
                combo: scorer.combo,
                prevPendingBlocks: []
            )
        }

        // GameOver 检测
        if checkGameOver() {
            isGameOver = true
        }

        grid.tickFreeze()
        return true
    }

    /// 旋转方块。返回 true=成功
    @discardableResult
    mutating func rotateBlock(atIndex index: Int) -> Bool {
        guard index >= 0, index < pendingBlocks.count, !pendingBlocks[index].used else { return false }

        let block = pendingBlocks[index]
        let rotated = block.shape.rotate()
        if rotated == block.shape { return false }

        let unplacedCount = pendingBlocks.filter { !$0.used }.count
        if unplacedCount > 1 {
            if grid.canPlaceAnywhere(block.shape) && !grid.canPlaceAnywhere(rotated) {
                return false
            }
        }

        pendingBlocks[index].shape = rotated
        return true
    }

    // MARK: - 道具支持

    func snapshot() -> GameStateSnapshot {
        GameStateSnapshot(
            gridData: grid.cells,
            frozenCells: grid.frozenCells,
            rainbowCells: grid.rainbowCells,
            score: scorer.score,
            combo: scorer.combo,
            snapPendingBlocks: pendingBlocks
        )
    }

    mutating func restore(_ s: GameStateSnapshot) {
        grid.cells = s.gridData
        grid.frozenCells = s.frozenCells
        grid.rainbowCells = s.rainbowCells
        scorer.restoreState(score: s.score, combo: s.combo)
        pendingBlocks = s.snapPendingBlocks
    }

    // MARK: - 内部方法

    private func checkGameOver() -> Bool {
        for block in pendingBlocks {
            if block.used { continue }
            if grid.canPlaceAnywhere(block.shape) { return false }
        }
        return true
    }

    func isAnyBlockStuck() -> Bool {
        pendingBlocks.contains { !$0.used && !grid.canPlaceAnywhere($0.shape) }
    }

    private func collectClearedColors(rows: [Int], cols: [Int]) -> [Position: Int] {
        var result: [Position: Int] = [:]
        for r in rows {
            for c in 0..<gridSize {
                let color = grid.get(r, c)
                if color != 0 { result[Position(r, c)] = color }
            }
        }
        for c in cols {
            for r in 0..<gridSize {
                result[Position(r, c)] = grid.get(r, c)
            }
        }
        return result
    }

    /// 提示：找到第一个可放置位置 → (blockIndex, row, col)，无则 nil
    func findHint() -> (Int, Int, Int)? {
        for (i, block) in pendingBlocks.enumerated() {
            if block.used { continue }
            for r in 0...(gridSize - block.shape.height) {
                for c in 0...(gridSize - block.shape.width) {
                    if grid.canPlace(block.shape, at: Position(r, c)) {
                        return (i, r, c)
                    }
                }
            }
        }
        return nil
    }
}
