import XCTest
@testable import BlockBlastPuzzle

/// 方块形状测试：18 种基础形状、旋转、尺寸计算
final class BlockShapeTest: XCTestCase {

    func test形状库共18种() {
        XCTAssertEqual(ShapeLibrary.all.count, 18)
    }

    func test1x1方块格数为1() {
        let s = ShapeLibrary.all.first { $0.size == 1 }
        XCTAssertNotNil(s)
        XCTAssertEqual(s?.size, 1)
    }

    func test3x3方块格数为9() {
        let s = ShapeLibrary.all.first { $0.size == 9 }
        XCTAssertNotNil(s)
        XCTAssertEqual(s?.size, 9)
    }

    func testAllOrientations返回不重复变体() {
        for shape in ShapeLibrary.all {
            let orients = shape.allOrientations()
            XCTAssertFalse(orients.isEmpty)
            XCTAssertEqual(orients.count, Set(orients).count, "allOrientations 包含重复变体")
        }
    }

    func testI形2格旋转后仍为2格() {
        let i2 = ShapeLibrary.all.first { $0.height == 1 && $0.width == 2 }
        XCTAssertNotNil(i2, "形状库应包含 1×2 横向方块")
        XCTAssertEqual(i2?.rotate().size, 2)
    }

    func test所有形状cells非空() {
        for shape in ShapeLibrary.all {
            XCTAssertFalse(shape.cells.isEmpty, "形状 cells 不能为空")
            XCTAssertGreaterThan(shape.size, 0, "形状 size 必须 > 0")
        }
    }

    func test所有形状格数计算一致() {
        for shape in ShapeLibrary.all {
            XCTAssertEqual(shape.cells.count, shape.size, "Shape cells=\(shape.cells) size 不匹配")
            XCTAssertGreaterThanOrEqual(shape.height, 1)
            XCTAssertGreaterThanOrEqual(shape.width, 1)
        }
    }

    func test旋转不变总格数() {
        for shape in ShapeLibrary.all {
            XCTAssertEqual(shape.size, shape.rotate().size)
        }
    }

    func test旋转4次回到原形状() {
        for shape in ShapeLibrary.all {
            let rotated4 = shape.rotate(4)
            XCTAssertEqual(Set(shape.cells), Set(rotated4.cells),
                "Shape \(shape.cells) rotate(4) 不等于原形状")
        }
    }

    func test坐标均为非负() {
        for shape in ShapeLibrary.all {
            for (pos) in shape.cells {
                XCTAssertGreaterThanOrEqual(pos.row, 0, "Shape 含负行坐标: \(pos.row)")
                XCTAssertGreaterThanOrEqual(pos.col, 0, "Shape 含负列坐标: \(pos.col)")
            }
        }
    }

    func testAllOrientations最多4种() {
        for shape in ShapeLibrary.all {
            let orients = shape.allOrientations()
            XCTAssertTrue((1...4).contains(orients.count),
                "Shape allOrientations=\(orients.count) 不在 [1,4] 范围")
        }
    }
}
