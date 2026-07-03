import Foundation

/// 排行榜条目
struct LeaderboardEntry: Codable, Equatable {
    let score: Int
    let date: String       // "2026-07-02"
    let mode: String       // "FREE"/"LEVEL"/"DAILY"/"SURVIVAL"
    let levelLabel: String
}
