import Foundation

/// 持久化封装 — 对标 Android AppPreferences (DataStore)
/// 使用 @AppStorage + UserDefaults 标准键值存储
final class AppPreferences: ObservableObject {
    static let shared = AppPreferences()

    private let defaults = UserDefaults.standard

    // MARK: - 游戏分数

    var highScore: Int {
        get { defaults.integer(forKey: "game.high_score") }
        set { defaults.set(newValue, forKey: "game.high_score") }
    }

    var highFreeScore: Int {
        get { defaults.integer(forKey: "game.high_free_score") }
        set { defaults.set(newValue, forKey: "game.high_free_score") }
    }

    var highLevelScore: Int {
        get { defaults.integer(forKey: "game.high_level_score") }
        set { defaults.set(newValue, forKey: "game.high_level_score") }
    }

    var highDailyScore: Int {
        get { defaults.integer(forKey: "game.high_daily_score") }
        set { defaults.set(newValue, forKey: "game.high_daily_score") }
    }

    // MARK: - 教程

    var tutorialDone: Bool {
        get { defaults.bool(forKey: "game.tutorial_done") }
        set { defaults.set(newValue, forKey: "game.tutorial_done") }
    }

    var tutorialStep: Int {
        get { defaults.integer(forKey: "tutorial.step") }
        set { defaults.set(newValue, forKey: "tutorial.step") }
    }

    var tutorialCompleted: Bool {
        get { defaults.bool(forKey: "tutorial.completed") }
        set { defaults.set(newValue, forKey: "tutorial.completed") }
    }

    // MARK: - 游戏存档

    var gameSaveData: String? {
        get { defaults.string(forKey: "save.data") }
        set { defaults.set(newValue, forKey: "save.data") }
    }

    // MARK: - 关卡进度

    var currentLevel: Int {
        get { defaults.integer(forKey: "level.current") }
        set { defaults.set(newValue, forKey: "level.current") }
    }

    var hasClearedAllLevels: Bool {
        get { defaults.bool(forKey: "level.has_cleared_all") }
        set { defaults.set(newValue, forKey: "level.has_cleared_all") }
    }

    var survivalMigrationDone: Bool {
        get { defaults.bool(forKey: "_migration_survival_unlock") }
        set { defaults.set(newValue, forKey: "_migration_survival_unlock") }
    }

    // MARK: - 音效

    var soundMuted: Bool {
        get { defaults.bool(forKey: "sound.muted") }
        set { defaults.set(newValue, forKey: "sound.muted") }
    }

    var sfxEnabled: Bool {
        get { defaults.object(forKey: "sound.sfx_enabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "sound.sfx_enabled") }
    }

    var bgmEnabled: Bool {
        get { defaults.object(forKey: "sound.bgm_enabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "sound.bgm_enabled") }
    }

    // MARK: - 皮肤

    var currentSkinId: String {
        get { defaults.string(forKey: "skin.current") ?? "morandi" }
        set { defaults.set(newValue, forKey: "skin.current") }
    }

    func isSkinUnlocked(_ id: String) -> Bool {
        defaults.bool(forKey: "skin.unlocked_\(id)")
    }

    func setSkinUnlocked(_ id: String) {
        defaults.set(true, forKey: "skin.unlocked_\(id)")
    }

    // MARK: - 每日挑战

    var dailyLastDate: String {
        get { defaults.string(forKey: "dc.last_date") ?? "" }
        set { defaults.set(newValue, forKey: "dc.last_date") }
    }

    var dailyCompleted: Bool {
        get { defaults.bool(forKey: "dc.completed") }
        set { defaults.set(newValue, forKey: "dc.completed") }
    }

    var dailyBestScore: Int {
        get { defaults.integer(forKey: "dc.best_score") }
        set { defaults.set(newValue, forKey: "dc.best_score") }
    }

    var dailyHistory: Set<String> {
        get { Set(defaults.stringArray(forKey: "dc.history_dates") ?? []) }
        set { defaults.set(Array(newValue), forKey: "dc.history_dates") }
    }

    // MARK: - 排行榜

    var leaderboardData: String? {
        get { defaults.string(forKey: "leaderboard.data") }
        set { defaults.set(newValue, forKey: "leaderboard.data") }
    }

    // MARK: - 成就统计

    var totalRotates: Int {
        get { defaults.integer(forKey: "ach.total_rotates") }
        set { defaults.set(newValue, forKey: "ach.total_rotates") }
    }

    var totalPlaces: Int {
        get { defaults.integer(forKey: "ach.total_places") }
        set { defaults.set(newValue, forKey: "ach.total_places") }
    }

    var totalLinesCleared: Int {
        get { defaults.integer(forKey: "ach.total_lines") }
        set { defaults.set(newValue, forKey: "ach.total_lines") }
    }

    var levelsCompleted: Int {
        get { defaults.integer(forKey: "ach.levels_completed") }
        set { defaults.set(newValue, forKey: "ach.levels_completed") }
    }

    var totalGamesPlayed: Int {
        get { defaults.integer(forKey: "ach.total_games") }
        set { defaults.set(newValue, forKey: "ach.total_games") }
    }

    var totalBombsUsed: Int {
        get { defaults.integer(forKey: "ach.total_bombs") }
        set { defaults.set(newValue, forKey: "ach.total_bombs") }
    }

    var totalUndosUsed: Int {
        get { defaults.integer(forKey: "ach.total_undos") }
        set { defaults.set(newValue, forKey: "ach.total_undos") }
    }

    var totalClearLinesUsed: Int {
        get { defaults.integer(forKey: "ach.total_clearlines") }
        set { defaults.set(newValue, forKey: "ach.total_clearlines") }
    }

    var bestDailyStreak: Int {
        get { defaults.integer(forKey: "ach.daily_streak_best") }
        set { defaults.set(newValue, forKey: "ach.daily_streak_best") }
    }

    // MARK: - 协议

    var agreementAccepted: Bool {
        get { defaults.bool(forKey: "game.agreement_accepted") }
        set { defaults.set(newValue, forKey: "game.agreement_accepted") }
    }

    // MARK: - 成就里程碑

    var maxComboEver: Int {
        get { defaults.integer(forKey: "ach.max_combo") }
        set { defaults.set(newValue, forKey: "ach.max_combo") }
    }

    var maxLinesClearedOnce: Int {
        get { defaults.integer(forKey: "ach.max_lines_once") }
        set { defaults.set(newValue, forKey: "ach.max_lines_once") }
    }

    var hasPerfectClear: Bool {
        get { defaults.bool(forKey: "ach.perfect_clear") }
        set { defaults.set(newValue, forKey: "ach.perfect_clear") }
    }
}
