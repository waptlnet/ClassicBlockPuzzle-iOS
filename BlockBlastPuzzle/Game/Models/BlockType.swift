/// 特殊方块类型 — 与 Android BlockType 完全一致
enum BlockType: String, Codable, CaseIterable {
    case normal     // 普通方块
    case bomb      // 炸弹：放下后清除周围 5×5
    case rainbow   // 彩虹：消除时算任意颜色
    case frozen    // 冰冻：放下后不可被消除（障碍物，占位）
}
