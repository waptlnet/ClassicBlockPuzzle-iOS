import Foundation

/// 网格数据结构。值类型，cells[r][c]==0 表示空，非0表示颜色编号 1..7
struct Grid: Codable {
    let size: Int
    var cells: [[Int]]

    /// 冰冻格子：Key=坐标，Value=剩余冻结回合数
    var frozenCells: [Position: Int] = [:]

    /// 彩虹格子集合
    var rainbowCells: Set<Position> = []

    init(size: Int = 9) {
        self.size = size
        self.cells = Array(repeating: Array(repeating: 0, count: size), count: size)
    }

    func get(_ r: Int, _ c: Int) -> Int {
        guard r >= 0, r < size, c >= 0, c < size else { return 0 }
        return cells[r][c]
    }

    func get(_ pos: Position) -> Int {
        get(pos.row, pos.col)
    }

    mutating func reset() {
        cells = Array(repeating: Array(repeating: 0, count: size), count: size)
        frozenCells.removeAll()
        rainbowCells.removeAll()
    }

    // MARK: - 放置

    func canPlace(_ shape: BlockShape, at pos: Position) -> Bool {
        for cell in shape.cells {
            let r = pos.row + cell.row
            let c = pos.col + cell.col
            guard r >= 0, r < size, c >= 0, c < size else { return false }
            if cells[r][c] != 0 { return false }
        }
        return true
    }

    mutating func place(_ shape: BlockShape, at pos: Position, color: Int, type: BlockType = .normal) {
        for cell in shape.cells {
            let r = pos.row + cell.row
            let c = pos.col + cell.col
            cells[r][c] = color
            switch type {
            case .frozen: frozenCells[Position(r, c)] = 12
            case .rainbow: rainbowCells.insert(Position(r, c))
            default: break
            }
        }
    }

    // MARK: - 消除

    func findFullLines() -> (rows: [Int], cols: [Int]) {
        var fullRows: [Int] = []
        var fullCols: [Int] = []

        for r in 0..<size {
            var isFull = true
            for c in 0..<size {
                let pos = Position(r, c)
                if frozenCells[pos] != nil { isFull = false; break }
                if cells[r][c] == 0 && !rainbowCells.contains(pos) { isFull = false; break }
            }
            if isFull { fullRows.append(r) }
        }

        for c in 0..<size {
            var isFull = true
            for r in 0..<size {
                let pos = Position(r, c)
                if frozenCells[pos] != nil { isFull = false; break }
                if cells[r][c] == 0 && !rainbowCells.contains(pos) { isFull = false; break }
            }
            if isFull { fullCols.append(c) }
        }

        return (fullRows, fullCols)
    }

    mutating func clearLines(rows: [Int], cols: [Int]) {
        for r in rows {
            for c in 0..<size {
                if frozenCells[Position(r, c)] == nil {
                    cells[r][c] = 0
                    rainbowCells.remove(Position(r, c))
                }
            }
        }
        for c in cols {
            for r in 0..<size {
                if frozenCells[Position(r, c)] == nil {
                    cells[r][c] = 0
                    rainbowCells.remove(Position(r, c))
                }
            }
        }
    }

    mutating func clearCell(_ r: Int, _ c: Int) {
        let pos = Position(r, c)
        if frozenCells[pos] == nil {
            cells[r][c] = 0
            rainbowCells.remove(pos)
        }
    }

    // MARK: - 炸弹

    /// 炸弹爆炸：清除 5×5 区域（跳过冰冻），返回清除数
    mutating func bombExplode(centerRow: Int, centerCol: Int) -> Int {
        var cleared = 0
        for dr in -2...2 {
            for dc in -2...2 {
                let r = centerRow + dr
                let c = centerCol + dc
                guard r >= 0, r < size, c >= 0, c < size else { continue }
                let pos = Position(r, c)
                if frozenCells[pos] != nil { continue }
                if cells[r][c] != 0 { cleared += 1 }
                cells[r][c] = 0
                rainbowCells.remove(pos)
            }
        }
        return cleared
    }

    /// 道具炸弹：清除所有格子（含冰冻），返回清除数
    mutating func clearAllCells() -> Int {
        var cleared = 0
        for r in 0..<size {
            for c in 0..<size {
                if cells[r][c] != 0 { cleared += 1 }
                cells[r][c] = 0
            }
        }
        frozenCells.removeAll()
        rainbowCells.removeAll()
        return cleared
    }

    // MARK: - 查询

    func canPlaceAnywhere(_ shape: BlockShape) -> Bool {
        for r in 0...(size - shape.height) {
            for c in 0...(size - shape.width) {
                if canPlace(shape, at: Position(r, c)) { return true }
            }
        }
        return false
    }

    func isEmptyGrid() -> Bool {
        for r in 0..<size {
            for c in 0..<size {
                if cells[r][c] != 0 { return false }
            }
        }
        return true
    }

    /// 每回合调用：冰冻倒计时-1，归零解冻
    mutating func tickFreeze() {
        var toRemove: [Position] = []
        for (pos, turns) in frozenCells {
            if turns <= 1 {
                toRemove.append(pos)
            } else {
                frozenCells[pos] = turns - 1
            }
        }
        for pos in toRemove { frozenCells.removeValue(forKey: pos) }
    }
}
