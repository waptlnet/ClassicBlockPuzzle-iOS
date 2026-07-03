import Foundation

/// 评分系统 — 与 Android ScoreSystem 逻辑完全一致
struct ScoreSystem: Codable {
    private(set) var score: Int = 0
    private(set) var combo: Int = 0
    private(set) var maxCombo: Int = 0
    private(set) var lastGain: Int = 0

    mutating func restoreState(score: Int, combo: Int, maxCombo: Int = 0) {
        self.score = score
        self.combo = combo
        self.maxCombo = maxCombo
    }

    mutating func reset() {
        score = 0
        combo = 0
        maxCombo = 0
        lastGain = 0
    }

    /// 放置方块（不触发消除）
    @discardableResult
    mutating func onPlace(blockSize: Int) -> Int {
        score += blockSize
        lastGain = blockSize
        return blockSize
    }

    /// 触发消除 rows+cols 条线
    @discardableResult
    mutating func onClear(rows: [Int], cols: [Int], grid: Grid) -> Int {
        let lines = rows.count + cols.count
        if lines == 0 {
            combo = 0
            lastGain = 0
            return 0
        }

        combo += 1
        let baseScore = lines * 10
        let lineMultiplier: Double = switch lines {
        case 1: 1.0
        case 2: 1.5
        case 3: 2.0
        case 4: 3.0
        case 5: 4.0
        default: 4.0 + Double(lines - 5) * 1.0
        }
        let comboBonus = combo > 1 ? 1.0 + Double(combo - 1) * 0.2 : 1.0
        var gained = Int(Double(baseScore) * lineMultiplier * comboBonus)

        // 同色行/列额外加分
        for r in rows {
            if isMonochromeRow(r, grid: grid) { gained += 50 }
        }
        for c in cols {
            if isMonochromeCol(c, grid: grid) { gained += 50 }
        }

        score += gained
        lastGain = gained
        if combo > maxCombo { maxCombo = combo }
        return gained
    }

    mutating func onPerfectClear() {
        let bonus = 500
        score += bonus
        lastGain = bonus
        combo += 1
        if combo > maxCombo { maxCombo = combo }
    }

    // MARK: - 同色检测

    private func isMonochromeRow(_ row: Int, grid: Grid) -> Bool {
        var baseColor = 0
        for c in 0..<grid.size {
            let pos = Position(row, c)
            if grid.rainbowCells.contains(pos) { continue }
            let color = grid.get(row, c)
            if color == 0 { return false }
            if baseColor == 0 { baseColor = color }
            else if color != baseColor { return false }
        }
        return true
    }

    private func isMonochromeCol(_ col: Int, grid: Grid) -> Bool {
        var baseColor = 0
        for r in 0..<grid.size {
            let pos = Position(r, col)
            if grid.rainbowCells.contains(pos) { continue }
            let color = grid.get(r, col)
            if color == 0 { return false }
            if baseColor == 0 { baseColor = color }
            else if color != baseColor { return false }
        }
        return true
    }
}
