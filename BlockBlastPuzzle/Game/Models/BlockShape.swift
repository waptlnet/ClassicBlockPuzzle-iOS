import Foundation

/// 方块形状：用相对坐标集合表示。值类型，旋转通过 rotate() 生成新实例。
struct BlockShape: Equatable, Hashable, Codable {

    // Position 别名（文件级可用）
    let cells: [Position]

    var height: Int { (cells.map(\.row).max() ?? 0) + 1 }
    var width: Int { (cells.map(\.col).max() ?? 0) + 1 }
    var size: Int { cells.count }

    /// 顺时针旋转 90 度：(r, c) → (c, -r)，再平移回 (0,0)
    func rotate() -> BlockShape {
        let rotated = cells.map { Position($0.col, -$0.row) }
        let minR = rotated.map(\.row).min() ?? 0
        let minC = rotated.map(\.col).min() ?? 0
        return BlockShape(cells: rotated.map { Position($0.row - minR, $0.col - minC) })
    }

    /// 旋转 n 次（n 可为负，逆时针）
    func rotate(_ n: Int) -> BlockShape {
        let times = ((n % 4) + 4) % 4
        var s = self
        for _ in 0..<times { s = s.rotate() }
        return s
    }

    /// 所有旋转去重形态
    func allOrientations() -> [BlockShape] {
        var result = [self]
        var cur = self
        for _ in 0..<3 {
            cur = cur.rotate()
            if !result.contains(cur) { result.append(cur) }
        }
        return result
    }
}

// MARK: - Position

/// 网格坐标
struct Position: Equatable, Hashable, Codable {
    let row: Int
    let col: Int

    init(_ row: Int, _ col: Int) {
        self.row = row
        self.col = col
    }
}

// MARK: - ShapeLibrary

/// 方块形状库：18 种基础形状
enum ShapeLibrary {
    static let all: [BlockShape] = [
        // 1×1
        BlockShape(cells: [Position(0, 0)]),
        // 2×1
        BlockShape(cells: [Position(0, 0), Position(0, 1)]),
        // 3×1
        BlockShape(cells: [Position(0, 0), Position(0, 1), Position(0, 2)]),
        // I 形 4 格
        BlockShape(cells: [Position(0, 0), Position(0, 1), Position(0, 2), Position(0, 3)]),
        // 5 格长条
        BlockShape(cells: [Position(0, 0), Position(0, 1), Position(0, 2), Position(0, 3), Position(0, 4)]),
        // O 形 2×2
        BlockShape(cells: [Position(0, 0), Position(0, 1), Position(1, 0), Position(1, 1)]),
        // 3×3 大方块
        BlockShape(cells: [
            Position(0, 0), Position(0, 1), Position(0, 2),
            Position(1, 0), Position(1, 1), Position(1, 2),
            Position(2, 0), Position(2, 1), Position(2, 2),
        ]),
        // L3
        BlockShape(cells: [Position(0, 0), Position(1, 0), Position(1, 1)]),
        // J3
        BlockShape(cells: [Position(0, 1), Position(1, 0), Position(1, 1)]),
        // L4
        BlockShape(cells: [Position(0, 0), Position(1, 0), Position(2, 0), Position(2, 1)]),
        // J4
        BlockShape(cells: [Position(0, 1), Position(1, 1), Position(2, 0), Position(2, 1)]),
        // T4
        BlockShape(cells: [Position(0, 0), Position(0, 1), Position(0, 2), Position(1, 1)]),
        // S4
        BlockShape(cells: [Position(0, 1), Position(0, 2), Position(1, 0), Position(1, 1)]),
        // Z4
        BlockShape(cells: [Position(0, 0), Position(0, 1), Position(1, 1), Position(1, 2)]),
        // S竖
        BlockShape(cells: [Position(0, 0), Position(1, 0), Position(1, 1), Position(2, 1)]),
        // Z竖
        BlockShape(cells: [Position(0, 1), Position(1, 0), Position(1, 1), Position(2, 0)]),
        // L5
        BlockShape(cells: [Position(0, 0), Position(1, 0), Position(2, 0), Position(3, 0), Position(3, 1)]),
        // J5
        BlockShape(cells: [Position(0, 1), Position(1, 1), Position(2, 1), Position(3, 0), Position(3, 1)]),
    ]
}
