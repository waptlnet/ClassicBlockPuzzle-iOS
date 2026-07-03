import Foundation

/// 成就 ID — 与 Android AchievementId 完全一致（12 个）
enum AchievementId: String, CaseIterable, Codable {
    case firstClear      // 首次消除
    case combo3          // 连击×3
    case combo5          // 连击×5
    case clear4Lines     // 单次消4行
    case perfectClear    // 完美清空
    case score1000       // 单局1000分
    case score5000       // 单局5000分
    case rotate100       // 旋转100次
    case place500        // 放置500次
    case clear100Lines   // 累计消除100行
    case allLevels       // 通关全部10关
    case daily7Days      // 连续7天每日挑战
}

struct Achievement: Identifiable {
    let id: AchievementId
    var title: String { L10n.achTitle(id) }
    var description: String { L10n.achDescription(id) }
    let icon: String
    let goal: Int
}

enum AchievementData {
    static let all: [Achievement] = [
        Achievement(id: .firstClear,    icon: "🎯", goal: 1),
        Achievement(id: .combo3,        icon: "🔥", goal: 3),
        Achievement(id: .combo5,        icon: "💥", goal: 5),
        Achievement(id: .clear4Lines,   icon: "⚡", goal: 4),
        Achievement(id: .perfectClear,  icon: "✨", goal: 1),
        Achievement(id: .score1000,     icon: "⭐", goal: 1000),
        Achievement(id: .score5000,     icon: "🏆", goal: 5000),
        Achievement(id: .rotate100,     icon: "🔄", goal: 100),
        Achievement(id: .place500,      icon: "🤲", goal: 500),
        Achievement(id: .clear100Lines, icon: "🧹", goal: 100),
        Achievement(id: .allLevels,     icon: "👑", goal: 10),
        Achievement(id: .daily7Days,    icon: "📅", goal: 7),
    ]
}
