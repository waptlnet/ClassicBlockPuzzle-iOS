import Foundation

// MARK: - 多语言本地化封装
// 用法: Text(L10n.startGame)  或  Button(L10n.restart) 等
// 默认语言为简体中文 (zh-Hans)，英文本地化通过 en.lproj/Localizable.strings 提供

enum L10n {
    // ---- 主页 ----
    static var appTitle: String          { NSLocalizedString("app_title",          value: "方块爆炸拼图", comment: "App title") }
    static var appSubtitle: String       { NSLocalizedString("app_subtitle",       value: "Block Blast Puzzle", comment: "") }
    static var highScore: String         { NSLocalizedString("high_score",         value: "最高分", comment: "") }
    static var highScoreFmt: String      { NSLocalizedString("high_score_fmt",      value: "最高 %d", comment: "Top bar score") }
    static var streakDays: String        { NSLocalizedString("streak_days",        value: "连续打卡", comment: "") }
    static var dayUnit: String           { NSLocalizedString("day_unit",            value: "天", comment: "Day unit suffix") }
    static var startGame: String         { NSLocalizedString("start_game",         value: "开始游戏", comment: "") }
    static var leaderboard: String       { NSLocalizedString("leaderboard",        value: "排行榜", comment: "") }
    static var statistics: String        { NSLocalizedString("statistics",         value: "统计", comment: "") }
    static var skin: String              { NSLocalizedString("skin",               value: "皮肤", comment: "") }
    static var tutorial: String          { NSLocalizedString("tutorial",           value: "引导", comment: "") }

    // ---- 游戏界面 ----
    static var freeMode: String          { NSLocalizedString("free_mode",          value: "自由模式", comment: "") }
    static var levelMode: String         { NSLocalizedString("level_mode",         value: "关卡模式", comment: "") }
    static var dailyChallenge: String    { NSLocalizedString("daily_challenge",    value: "每日挑战", comment: "") }
    static var survivalMode: String      { NSLocalizedString("survival_mode",      value: "极限挑战 · 5×5", comment: "") }
    static var levelLabel: String        { NSLocalizedString("level_label",        value: "关卡 %@", comment: "Level N") }
    static func level(_ id: Int, _ label: String) -> String {
        String(format: NSLocalizedString("level_fmt", value: "第%ld关·%@", comment: ""), id, label)
    }
    static func levelName(_ id: Int) -> String { NSLocalizedString("level_name_\(id)", value: levelNameDefault(id), comment: "Level name") }
    private static func levelNameDefault(_ id: Int) -> String {
        switch id {
        case  1: "初入江湖"
        case  2: "小试牛刀"
        case  3: "渐入佳境"
        case  4: "游刃有余"
        case  5: "炉火纯青"
        case  6: "登峰造极"
        case  7: "出神入化"
        case  8: "天下无双"
        case  9: "超凡入圣"
        case 10: "Legend"
        default: ""
        }
    }
    static var levelFailed: String       { NSLocalizedString("level_failed",       value: "关卡失败", comment: "") }
    static var gameOver: String          { NSLocalizedString("game_over",          value: "游戏结束", comment: "") }
    static var survivalOverLabel: String { NSLocalizedString("survival_over",      value: "极限挑战 · %d/3 命耗尽", comment: "") }
    static var survivalLBFmt: String     { NSLocalizedString("survival_lb_fmt",    value: "极限-%d分", comment: "Leaderboard survival label") }
    static var confirmExit: String       { NSLocalizedString("confirm_exit",       value: "确认退出", comment: "") }
    static var cancel: String            { NSLocalizedString("cancel",             value: "取消", comment: "") }
    static var exitToHome: String        { NSLocalizedString("exit_to_home",       value: "退出到主页", comment: "") }
    static var autoSaveMsg: String       { NSLocalizedString("auto_save_msg",      value: "当前进度将自动保存", comment: "") }
    static var switchTo: String          { NSLocalizedString("switch_to",          value: "%@ ▸", comment: "Switch to mode") }

    // ---- 道具栏 ----
    static var undo: String              { NSLocalizedString("undo",               value: "撤销", comment: "") }
    static var hint: String              { NSLocalizedString("hint",               value: "提示", comment: "") }
    static var clearLine: String         { NSLocalizedString("clear_line",         value: "消行", comment: "") }
    static var bomb: String              { NSLocalizedString("bomb",               value: "炸弹", comment: "") }

    // ---- 结算弹窗 ----
    static var newRecord: String         { NSLocalizedString("new_record",         value: "新纪录！", comment: "") }
    static var scoreLabel: String        { NSLocalizedString("score_label",        value: "得分", comment: "") }
    static var highScoreLabel: String    { NSLocalizedString("high_score_label",   value: "最高分", comment: "Same as highScore but used in result dialog") }
    static var restart: String           { NSLocalizedString("restart",            value: "重新开始", comment: "") }
    static var exit: String              { NSLocalizedString("exit",               value: "退出", comment: "") }
    static var levelComplete: String     { NSLocalizedString("level_complete",     value: "关卡通过！", comment: "") }
    static var scoreFormat: String       { NSLocalizedString("score_format",       value: "得分：%d", comment: "") }
    static var targetFormat: String      { NSLocalizedString("target_format",      value: "目标：%d", comment: "") }
    static var nextLevel: String         { NSLocalizedString("next_level",         value: "下一关", comment: "") }

    // ---- 设置 ----
    static var settings: String          { NSLocalizedString("settings",           value: "设置", comment: "") }
    static var soundSection: String      { NSLocalizedString("sound_section",      value: "音效", comment: "") }
    static var mute: String              { NSLocalizedString("mute",               value: "静音", comment: "") }
    static var sfx: String               { NSLocalizedString("sfx",                value: "音效", comment: "SFX toggle") }
    static var bgm: String               { NSLocalizedString("bgm",                value: "背景音乐", comment: "") }
    static var otherSection: String      { NSLocalizedString("other_section",      value: "其他", comment: "") }
    static var agreement: String         { NSLocalizedString("agreement",          value: "同意用户协议", comment: "") }
    static var done: String              { NSLocalizedString("done",               value: "完成", comment: "") }

    // ---- 统计页 ----
    static var gameDataSection: String   { NSLocalizedString("game_data_section",  value: "游戏数据", comment: "") }
    static var gamesPlayed: String       { NSLocalizedString("games_played",       value: "对局数", comment: "") }
    static var timesPlaced: String       { NSLocalizedString("times_placed",       value: "放置次数", comment: "") }
    static var timesRotated: String      { NSLocalizedString("times_rotated",      value: "旋转次数", comment: "") }
    static var linesCleared: String      { NSLocalizedString("lines_cleared",      value: "消除行数", comment: "") }
    static var levelSection: String      { NSLocalizedString("level_section",      value: "关卡", comment: "") }
    static var levelsCompleted: String   { NSLocalizedString("levels_completed",   value: "通关关数", comment: "") }
    static var allLevelsCleared: String  { NSLocalizedString("all_levels_cleared", value: "全部通关", comment: "") }
    static var dailySection: String      { NSLocalizedString("daily_section",      value: "每日挑战", comment: "") }
    static var bestStreak: String        { NSLocalizedString("best_streak",        value: "最佳连胜", comment: "") }
    static var currentStreak: String     { NSLocalizedString("current_streak",     value: "当前连胜", comment: "") }
    static var powerUpSection: String    { NSLocalizedString("powerup_section",    value: "道具", comment: "") }
    static var undosUsed: String         { NSLocalizedString("undos_used",         value: "撤销次数", comment: "") }
    static var bombsUsed: String         { NSLocalizedString("bombs_used",         value: "炸弹次数", comment: "") }
    static var clearLinesUsed: String    { NSLocalizedString("clear_lines_used",   value: "消行次数", comment: "") }
    static var achievementSection: String { NSLocalizedString("achievement_section", value: "成就", comment: "") }
    static var noRecords: String         { NSLocalizedString("no_records",         value: "暂无记录", comment: "") }

    // ---- 引导 ----
    static var skipTutorial: String      { NSLocalizedString("skip_tutorial",      value: "跳过引导", comment: "") }
    static var nextStep: String          { NSLocalizedString("next_step",          value: "下一步", comment: "") }
    static var tutorialStep0: String     { NSLocalizedString("tutorial_step0",     value: "欢迎来到经典方块消除！\n滑动下方方块放入网格", comment: "") }
    static var tutorialStep1: String     { NSLocalizedString("tutorial_step1",     value: "拖动方块到合适位置\n松开即可放置", comment: "") }
    static var tutorialStep2: String     { NSLocalizedString("tutorial_step2",     value: "点击方块可以旋转\n每个方块有4种方向", comment: "") }
    static var tutorialStep3: String     { NSLocalizedString("tutorial_step3",     value: "填满一行或一列就会消除\n一次消除越多加分越高！", comment: "") }
    static var tutorialStep4: String     { NSLocalizedString("tutorial_step4",     value: "使用道具帮你摆脱困境\n准备好开始了吗？🎉", comment: "") }

    // ---- 成就 ----
    static var achFirstClear: String     { NSLocalizedString("ach_first_clear",    value: "初出茅庐", comment: "") }
    static var achCombo3: String         { NSLocalizedString("ach_combo3",         value: "连击新手", comment: "") }
    static var achCombo5: String         { NSLocalizedString("ach_combo5",         value: "连击大师", comment: "") }
    static var achClear4Lines: String    { NSLocalizedString("ach_clear4_lines",   value: "横扫千军", comment: "") }
    static var achPerfectClear: String   { NSLocalizedString("ach_perfect_clear",  value: "一尘不染", comment: "") }
    static var achScore1000: String      { NSLocalizedString("ach_score_1000",     value: "千分玩家", comment: "") }
    static var achScore5000: String      { NSLocalizedString("ach_score_5000",     value: "万分达人", comment: "") }
    static var achRotate100: String      { NSLocalizedString("ach_rotate_100",     value: "旋转之王", comment: "") }
    static var achPlace500: String       { NSLocalizedString("ach_place_500",      value: "勤劳之手", comment: "") }
    static var achClear100Lines: String  { NSLocalizedString("ach_clear_100_lines", value: "消除专家", comment: "") }
    static var achAllLevels: String      { NSLocalizedString("ach_all_levels",     value: "通关大师", comment: "") }
    static var achDaily7Days: String     { NSLocalizedString("ach_daily_7_days",   value: "坚持不懈", comment: "") }
    static func achTitle(_ id: AchievementId) -> String {
        switch id {
        case .firstClear:    return achFirstClear
        case .combo3:        return achCombo3
        case .combo5:        return achCombo5
        case .clear4Lines:   return achClear4Lines
        case .perfectClear:  return achPerfectClear
        case .score1000:     return achScore1000
        case .score5000:     return achScore5000
        case .rotate100:     return achRotate100
        case .place500:      return achPlace500
        case .clear100Lines: return achClear100Lines
        case .allLevels:     return achAllLevels
        case .daily7Days:    return achDaily7Days
        }
    }

    // ---- 成就描述 ----
    static func achDescription(_ id: AchievementId) -> String {
        switch id {
        case .firstClear:    return NSLocalizedString("ach_desc_first_clear",    value: "完成首次消除", comment: "")
        case .combo3:        return NSLocalizedString("ach_desc_combo3",         value: "达成3连击", comment: "")
        case .combo5:        return NSLocalizedString("ach_desc_combo5",         value: "达成5连击", comment: "")
        case .clear4Lines:   return NSLocalizedString("ach_desc_clear4_lines",   value: "单次消除4行", comment: "")
        case .perfectClear:  return NSLocalizedString("ach_desc_perfect_clear",  value: "完美清空整个网格", comment: "")
        case .score1000:     return NSLocalizedString("ach_desc_score_1000",     value: "单局达到1000分", comment: "")
        case .score5000:     return NSLocalizedString("ach_desc_score_5000",     value: "单局达到5000分", comment: "")
        case .rotate100:     return NSLocalizedString("ach_desc_rotate_100",     value: "累计旋转100次", comment: "")
        case .place500:      return NSLocalizedString("ach_desc_place_500",      value: "累计放置500次", comment: "")
        case .clear100Lines: return NSLocalizedString("ach_desc_clear_100_lines", value: "累计消除100行", comment: "")
        case .allLevels:     return NSLocalizedString("ach_desc_all_levels",     value: "通关全部10关", comment: "")
        case .daily7Days:    return NSLocalizedString("ach_desc_daily_7_days",   value: "连续7天每日挑战", comment: "")
        }
    }

    // ---- 皮肤名 ----
    static var skinMorandi: String       { NSLocalizedString("skin_morandi",       value: "莫兰迪", comment: "") }
    static var skinMacaron: String       { NSLocalizedString("skin_macaron",       value: "马卡龙", comment: "") }
    static var skinGrayscale: String     { NSLocalizedString("skin_grayscale",     value: "灰阶", comment: "") }
    static var skinOcean: String         { NSLocalizedString("skin_ocean",         value: "海洋", comment: "") }
    static var skinLava: String          { NSLocalizedString("skin_lava",          value: "熔岩", comment: "") }
    static var skinForest: String        { NSLocalizedString("skin_forest",        value: "森林", comment: "") }
    static var skinSunset: String        { NSLocalizedString("skin_sunset",        value: "日落", comment: "") }
    static var skinMidnight: String      { NSLocalizedString("skin_midnight",      value: "暗夜", comment: "") }
    static var skinDeepSea: String       { NSLocalizedString("skin_deep_sea",      value: "深海", comment: "") }
    static func skinName(_ id: String) -> String {
        switch id {
        case "morandi":   return skinMorandi
        case "macaron":   return skinMacaron
        case "grayscale": return skinGrayscale
        case "ocean":     return skinOcean
        case "lava":      return skinLava
        case "forest":    return skinForest
        case "sunset":    return skinSunset
        case "midnight":  return skinMidnight
        case "deep_sea":  return skinDeepSea
        default:          return id
        }
    }
}
