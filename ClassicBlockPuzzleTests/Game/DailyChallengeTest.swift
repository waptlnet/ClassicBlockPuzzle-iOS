import XCTest
@testable import ClassicBlockPuzzle

/// 每日挑战测试：种子一致性、日期格式、记录与查询
final class DailyChallengeTest: XCTestCase {

    // MARK: - 种子

    func testGetTodaySeed返回8位日期数字() {
        let seed = DailyChallenge.getTodaySeed()
        let seedStr = String(seed)
        XCTAssertEqual(seedStr.count, 8, "种子应为 yyyyMMdd 格式 8 位数字")
    }

    func testGetTodaySeed与今天日期字符串一致() {
        let seed = DailyChallenge.getTodaySeed()
        let todayStr = DailyChallenge.getTodayDateStr()
        XCTAssertEqual(UInt64(todayStr), seed)
    }

    func testGetTodayDateStr格式为yyyyMMdd() {
        let s = DailyChallenge.getTodayDateStr()
        XCTAssertEqual(s.count, 8, "\(s) 不是 8 位数字")
        let year = Int(s.prefix(4)) ?? 0
        let month = Int(s.dropFirst(4).prefix(2)) ?? 0
        let day = Int(s.suffix(2)) ?? 0
        XCTAssertTrue((2020...2030).contains(year), "年份 \(year) 不合理")
        XCTAssertTrue((1...12).contains(month), "月份 \(month) 不在 [1,12]")
        XCTAssertTrue((1...31).contains(day), "日期 \(day) 不在 [1,31]")
    }

    func test同一天多次调用getTodaySeed返回相同值() {
        let s1 = DailyChallenge.getTodaySeed()
        let s2 = DailyChallenge.getTodaySeed()
        XCTAssertEqual(s1, s2, "同一天种子应稳定")
    }

    func test种子的年份合理() {
        let seed = DailyChallenge.getTodaySeed()
        let year = seed / 10000
        XCTAssertTrue((2020...2030).contains(year), "年份 \(year) 不合理")
    }

    // MARK: - 记录与查询

    func test初始未完成() {
        let prefs = AppPreferences.shared
        prefs.dailyLastDate = "19700101"
        prefs.dailyCompleted = false
        XCTAssertFalse(DailyChallenge.isCompleted())
    }

    func testRecordResult记录完成() {
        let prefs = AppPreferences.shared
        let today = DailyChallenge.getTodayDateStr()
        DailyChallenge.recordResult(score: 500)
        XCTAssertEqual(prefs.dailyLastDate, today)
        XCTAssertTrue(prefs.dailyCompleted)
        XCTAssertEqual(prefs.dailyBestScore, 500)
        // 清理
        prefs.dailyLastDate = "19700101"
        prefs.dailyCompleted = false
        prefs.dailyBestScore = 0
    }

    func testGetBestScore当日有效() {
        let prefs = AppPreferences.shared
        let today = DailyChallenge.getTodayDateStr()
        prefs.dailyLastDate = today
        prefs.dailyBestScore = 800
        XCTAssertEqual(DailyChallenge.getBestScore(), 800)
        // 清理
        prefs.dailyLastDate = "19700101"
        prefs.dailyBestScore = 0
    }

    func testGetBestScore过期归零() {
        let prefs = AppPreferences.shared
        prefs.dailyLastDate = "19700101"
        prefs.dailyBestScore = 999
        XCTAssertEqual(DailyChallenge.getBestScore(), 0)
        // 清理
        prefs.dailyBestScore = 0
    }

    func test历史记录不重复同日() {
        let prefs = AppPreferences.shared
        let today = DailyChallenge.getTodayDateStr()
        prefs.dailyHistory.removeAll()

        DailyChallenge.recordResult(score: 100)
        let count1 = prefs.dailyHistory.count

        DailyChallenge.recordResult(score: 200)
        let count2 = prefs.dailyHistory.count

        // 同日多次记录不增加历史条数（Set insert 去重）
        XCTAssertEqual(count1, count2)

        // 清理
        prefs.dailyLastDate = "19700101"
        prefs.dailyCompleted = false
        prefs.dailyBestScore = 0
        prefs.dailyHistory.removeAll()
    }

    func testStreak空历史返回0() {
        let prefs = AppPreferences.shared
        prefs.dailyHistory.removeAll()
        XCTAssertEqual(DailyChallenge.getStreak(), 0)
    }
}
