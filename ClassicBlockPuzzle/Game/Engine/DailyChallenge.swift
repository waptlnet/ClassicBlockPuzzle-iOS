import Foundation

/// 每日挑战 — 基于日期的固定种子
enum DailyChallenge {

    /// 获取今日种子（基于日期 yyyyMMdd）
    static func getTodaySeed() -> UInt64 {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return UInt64(formatter.string(from: Date())) ?? 20260702
    }

    static func getTodayDateStr() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }

    /// 今日是否已完成
    static func isCompleted() -> Bool {
        let prefs = AppPreferences.shared
        return prefs.dailyLastDate == getTodayDateStr() && prefs.dailyCompleted
    }

    /// 今日最佳分数
    static func getBestScore() -> Int {
        let prefs = AppPreferences.shared
        if prefs.dailyLastDate == getTodayDateStr() {
            return prefs.dailyBestScore
        }
        return 0
    }

    /// 记录完成
    static func recordResult(score: Int) {
        let prefs = AppPreferences.shared
        let today = getTodayDateStr()
        let isToday = prefs.dailyLastDate == today
        let prevBest = isToday ? prefs.dailyBestScore : 0

        prefs.dailyLastDate = today
        prefs.dailyCompleted = true
        prefs.dailyBestScore = max(score, prevBest)

        var history = prefs.dailyHistory
        history.insert(today)
        prefs.dailyHistory = history
    }

    /// 获取连续打卡天数
    static func getStreak() -> Int {
        let prefs = AppPreferences.shared
        let history = prefs.dailyHistory
        guard !history.isEmpty else { return 0 }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"

        let todayStr = getTodayDateStr()
        guard var checkDate = formatter.date(from: todayStr) else { return 0 }

        // 今天还没完成，从昨天算
        if !isCompleted() {
            checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        var streak = 0
        while true {
            let dateStr = formatter.string(from: checkDate)
            if history.contains(dateStr) {
                streak += 1
                guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else {
                break
            }
        }
        return streak
    }
}
