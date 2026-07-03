import Foundation
import SwiftUI

/// 关卡信息
struct LevelInfo: Codable {
    let id: Int
    let targetScore: Int
    var label: String { L10n.levelName(id) }
    let gridSize: Int
}

/// 游戏模式
enum GameMode: String, Codable, CaseIterable {
    case free, level, dailyChallenge, survival
}

/// 核心 ViewModel — 对标 Android GameStateManager
@MainActor
final class GameViewModel: ObservableObject {
    private let prefs = AppPreferences.shared

    // ══════════════════════════════════════
    //  关卡数据
    // ══════════════════════════════════════
    static let levels: [LevelInfo] = [
        LevelInfo(id: 1, targetScore: 300, gridSize: 9),
        LevelInfo(id: 2, targetScore: 600, gridSize: 9),
        LevelInfo(id: 3, targetScore: 900, gridSize: 8),
        LevelInfo(id: 4, targetScore: 1300, gridSize: 8),
        LevelInfo(id: 5, targetScore: 1700, gridSize: 7),
        LevelInfo(id: 6, targetScore: 2200, gridSize: 7),
        LevelInfo(id: 7, targetScore: 2700, gridSize: 6),
        LevelInfo(id: 8, targetScore: 3300, gridSize: 6),
        LevelInfo(id: 9, targetScore: 4000, gridSize: 5),
        LevelInfo(id: 10, targetScore: 5000, gridSize: 5),
    ]

    var allLevelsCleared: Bool { prefs.hasClearedAllLevels }

    // ══════════════════════════════════════
    //  @Published 状态
    // ══════════════════════════════════════

    @Published var gameMode: GameMode = .free
    @Published var game: GameLogic
    @Published var highScore: Int = 0

    // 关卡
    @Published var currentLevelIndex: Int = 0
    @Published var levelScoreTotal: Int = 0

    // 极限模式
    @Published var survivalLives: Int = 3
    @Published var survivalTotalScore: Int = 0

    // 道具
    @Published var powerUpState = PowerUpState()
    private var powerUpHistory: [GameStateSnapshot] = []

    // 排行榜
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    private(set) var needShowGameOver = false
    var gameOverInfo: (() -> Void)?

    /// 本局峰值追踪（成就用）
    private var maxLinesClearedThisGame: Int = 0

    // ══════════════════════════════════════
    //  初始化
    // ══════════════════════════════════════

    init() {
        self.game = GameLogic(gridSize: 9)
        self.highScore = prefs.highScore

        // 一次性迁移
        if !prefs.survivalMigrationDone && !prefs.hasClearedAllLevels {
            if prefs.currentLevel == 0 && prefs.highScore > 0 {
                prefs.hasClearedAllLevels = true
            }
            prefs.survivalMigrationDone = true
        }

        if !loadFromPrefs() {
            restart()
        }
    }

    // ══════════════════════════════════════
    //  生命周期
    // ══════════════════════════════════════

    func restart() {
        clearSave()
        switch gameMode {
        case .level:
            currentLevelIndex = prefs.currentLevel
            levelScoreTotal = 0
            if let lvl = Self.levels[safe: currentLevelIndex] {
                game = createLevelGame(gridSize: lvl.gridSize)
            }
            applyLevelUnlocks()
        case .dailyChallenge:
            let seed = DailyChallenge.getTodaySeed()
            game = GameLogic(gridSize: 9, generator: BlockGenerator(seed: seed))
            powerUpState.reset()
        case .survival:
            survivalLives = 3
            survivalTotalScore = 0
            game = GameLogic(gridSize: 5)
            powerUpState.reset()
        case .free:
            game = GameLogic(gridSize: 9)
            powerUpState.reset()
        }
        resetCommonStateAndStart()
    }

    func switchMode() {
        clearSave()
        let hasClearedAll = prefs.hasClearedAllLevels
        gameMode = switch gameMode {
        case .free: .level
        case .level: .dailyChallenge
        case .dailyChallenge: hasClearedAll ? .survival : .free
        case .survival: .free
        }

        switch gameMode {
        case .level:
            currentLevelIndex = prefs.currentLevel
            levelScoreTotal = 0
            if let lvl = Self.levels[safe: currentLevelIndex] {
                game = createLevelGame(gridSize: lvl.gridSize)
            }
            applyLevelUnlocks()
        case .dailyChallenge:
            let seed = DailyChallenge.getTodaySeed()
            game = GameLogic(gridSize: 9, generator: BlockGenerator(seed: seed, dailyMode: true))
            powerUpState.reset()
        case .survival:
            survivalLives = 3
            survivalTotalScore = 0
            game = GameLogic(gridSize: 5)
            powerUpState.reset()
        case .free:
            game = GameLogic(gridSize: 9)
            powerUpState.reset()
        }
        resetCommonStateAndStart()
    }

    func advanceLevel() {
        clearSave()
        currentLevelIndex += 1
        if currentLevelIndex >= Self.levels.count {
            currentLevelIndex = 0
            prefs.hasClearedAllLevels = true
        }
        levelScoreTotal = 0
        prefs.currentLevel = currentLevelIndex

        if let lvl = Self.levels[safe: currentLevelIndex] {
            game = createLevelGame(gridSize: lvl.gridSize)
        }
        applyLevelUnlocks()
        resetCommonStateAndStart()
        SoundManager.shared.playLevelComplete()
        HapticManager.shared.perfectClear()
    }

    // MARK: - 死局处理

    /// 极限模式死局处理。返回 true = 真正 GameOver
    func handleSurvivalStuck() -> Bool {
        guard gameMode == .survival else { return true }
        survivalTotalScore += game.score
        survivalLives -= 1
        if survivalLives <= 0 {
            return true
        }
        game = GameLogic(gridSize: 5)
        resetCommonStateAndStart()
        return false
    }

    // MARK: - 分数

    func currentScore() -> Int {
        switch gameMode {
        case .level: return levelScoreTotal
        case .survival: return survivalTotalScore
        default: return game.score
        }
    }

    func checkLevelComplete() -> Bool {
        guard gameMode == .level else { return false }
        guard let lvl = Self.levels[safe: currentLevelIndex] else { return false }
        return levelScoreTotal >= lvl.targetScore
    }

    // MARK: - GameOver 处理

    func handleGameOver() {
        if gameMode == .survival {
            if !handleSurvivalStuck() {
                return
            }
        }
        if gameMode == .level {
            levelScoreTotal += game.score
        }
        // 成就追踪
        updateAchievementStats()
        clearSave()
        addToLeaderboard()
        needShowGameOver = true
        SoundManager.shared.playGameOver()
        HapticManager.shared.gameOver()
    }

    /// 根据当前对局结果更新成就里程碑
    private func updateAchievementStats() {
        let prefs = AppPreferences.shared
        // 最大连击
        if game.maxCombo > prefs.maxComboEver {
            prefs.maxComboEver = game.maxCombo
        }
        // 单次消除行数纪录（取本局峰值）
        if maxLinesClearedThisGame > prefs.maxLinesClearedOnce {
            prefs.maxLinesClearedOnce = maxLinesClearedThisGame
        }
        // 完美清空
        if game.isPerfectClear {
            prefs.hasPerfectClear = true
        }
    }

    // MARK: - 游戏操作（封装 @Published struct 突变）

    private func mutateGame(_ block: (inout GameLogic) -> Void) {
        var g = game
        block(&g)
        game = g
    }

    @discardableResult
    func placeBlock(atIndex idx: Int, atRow r: Int, col c: Int) -> Bool {
        let comboBefore = game.combo
        var g = game
        let result = g.placeBlock(atIndex: idx, atRow: r, col: c)
        game = g

        if result {
            SoundManager.shared.playPlace()
            HapticManager.shared.place()

            // 消除反馈
            if game.lastPlacedTriggeredClear {
                let cleared = game.lastClearedRows.count + game.lastClearedCols.count
                if cleared > maxLinesClearedThisGame { maxLinesClearedThisGame = cleared }
                SoundManager.shared.playClearLine()
                HapticManager.shared.clear(lines: cleared)
                ScreenShakeManager.shared.triggerClearShake(lines: cleared)
            }

            // 连击反馈
            if game.combo > comboBefore, game.combo >= 2 {
                SoundManager.shared.playCombo(level: game.combo)
                HapticManager.shared.combo(level: game.combo)
                ScreenShakeManager.shared.triggerComboShake(combo: game.combo)
            }

            // 完美清空
            if game.isPerfectClear {
                SoundManager.shared.playPerfectClear()
                HapticManager.shared.perfectClear()
            }
        } else {
            SoundManager.shared.playReject()
        }

        return result
    }

    @discardableResult
    func rotateBlock(atIndex idx: Int) -> Bool {
        var g = game
        let result = g.rotateBlock(atIndex: idx)
        game = g
        if result {
            SoundManager.shared.playRotate()
            HapticManager.shared.rotate()
        }
        return result
    }

    // MARK: - 道具

    func canUsePowerUp(_ type: PowerUpType) -> Bool {
        switch type {
        case .undo: return powerUpState.undoCount > 0 && !powerUpHistory.isEmpty
        case .hint: return powerUpState.hintCount > 0
        case .bomb: return powerUpState.bombCount > 0
        case .clearLine: return powerUpState.clearLineCount > 0
        }
    }

    func saveForUndo() {
        powerUpHistory.append(game.snapshot())
        if powerUpHistory.count > 5 { powerUpHistory.removeFirst() }
    }

    func usePowerUp(_ type: PowerUpType) -> Bool {
        guard canUsePowerUp(type) else { return false }
        switch type {
        case .undo:
            powerUpState.undoCount -= 1
            guard let snap = powerUpHistory.popLast() else { return false }
            mutateGame { $0.restore(snap) }
            SoundManager.shared.playUndo()
            HapticManager.shared.powerUp()
        case .hint:
            powerUpState.hintCount -= 1
            SoundManager.shared.playHint()
            HapticManager.shared.powerUp()
        case .clearLine:
            powerUpState.clearLineCount -= 1
            SoundManager.shared.playClearLine()
            HapticManager.shared.powerUp()
        case .bomb:
            powerUpState.bombCount -= 1
            SoundManager.shared.playBomb()
            HapticManager.shared.bomb()
            ScreenShakeManager.shared.triggerBombShake()
        }
        return true
    }

    // MARK: - 排行榜

    func addToLeaderboard() {
        let mode: String = switch gameMode {
        case .free: "FREE"
        case .level: "LEVEL"
        case .dailyChallenge: "DAILY"
        case .survival: "SURVIVAL"
        }
        let label: String = switch gameMode {
        case .level:
            Self.levels[safe: currentLevelIndex].map { L10n.level($0.id, $0.label) } ?? ""
        case .survival: String(format: L10n.survivalLBFmt, survivalTotalScore)
        default: ""
        }
        let lbScore = gameMode == .survival ? survivalTotalScore : game.score

        let entry = LeaderboardEntry(
            score: lbScore,
            date: dateStr(),
            mode: mode,
            levelLabel: label
        )
        var entries = leaderboardEntries
        if let idx = entries.firstIndex(where: { $0.score < lbScore }) {
            entries.insert(entry, at: idx)
        } else {
            entries.append(entry)
        }
        leaderboardEntries = Array(entries.prefix(20))
        saveLeaderboard()

        // 更新最高分
        if lbScore > prefs.highScore {
            prefs.highScore = lbScore
            highScore = lbScore
        }
    }

    // MARK: - 存档

    func saveToPrefs() {
        struct SaveData: Codable {
            let mode: String
            let score: Int; let combo: Int; let maxCombo: Int
            let gridSize: Int; let highScore: Int
            let levelScoreTotal: Int; let levelIndex: Int
            let survivalLives: Int; let survivalTotalScore: Int
            let cells: [[Int]]
            let frozen: [String: Int]
            let rainbow: [[Int]]
            let blocks: [PendingBlock]
            let powerUps: [String: Int]
        }

        let frozenDict = Dictionary(uniqueKeysWithValues: game.grid.frozenCells.map {
            ("\($0.key.row),\($0.key.col)", $0.value)
        })
        let rainbowArr = game.grid.rainbowCells.map { [$0.row, $0.col] }

        let data = SaveData(
            mode: gameMode.rawValue,
            score: game.score, combo: game.combo, maxCombo: game.maxCombo,
            gridSize: game.gridSize, highScore: highScore,
            levelScoreTotal: levelScoreTotal, levelIndex: currentLevelIndex,
            survivalLives: survivalLives, survivalTotalScore: survivalTotalScore,
            cells: game.grid.cells,
            frozen: frozenDict,
            rainbow: rainbowArr,
            blocks: game.pendingBlocks,
            powerUps: [
                "undo": powerUpState.undoCount,
                "hint": powerUpState.hintCount,
                "clearLine": powerUpState.clearLineCount,
                "bomb": powerUpState.bombCount,
            ]
        )

        if let json = try? JSONEncoder().encode(data),
           let str = String(data: json, encoding: .utf8) {
            prefs.gameSaveData = str
        }
    }

    @discardableResult
    func loadFromPrefs() -> Bool {
        guard let str = prefs.gameSaveData, let data = str.data(using: .utf8) else { return false }
        struct SaveData: Codable {
            let mode: String; let score: Int; let combo: Int; let maxCombo: Int
            let gridSize: Int; let highScore: Int
            let levelScoreTotal: Int; let levelIndex: Int
            let survivalLives: Int; let survivalTotalScore: Int
            let cells: [[Int]]
            let frozen: [String: Int]
            let rainbow: [[Int]]
            let blocks: [PendingBlock]
            let powerUps: [String: Int]
        }

        guard let save = try? JSONDecoder().decode(SaveData.self, from: data) else { return false }
        gameMode = GameMode(rawValue: save.mode) ?? .free
        highScore = save.highScore
        levelScoreTotal = save.levelScoreTotal
        currentLevelIndex = save.levelIndex
        survivalLives = save.survivalLives
        survivalTotalScore = save.survivalTotalScore

        var g = GameLogic(gridSize: save.gridSize)
        g.grid.cells = save.cells
        g.grid.frozenCells.removeAll()
        for (key, val) in save.frozen {
            let parts = key.split(separator: ",")
            if parts.count == 2, let r = Int(parts[0]), let c = Int(parts[1]) {
                g.grid.frozenCells[Position(r, c)] = val
            }
        }
        g.grid.rainbowCells = Set(save.rainbow.map { Position($0[0], $0[1]) })
        g.restoreScoreState(score: save.score, combo: save.combo, maxCombo: save.maxCombo)
        g.pendingBlocks = save.blocks
        game = g

        powerUpState.undoCount = save.powerUps["undo"] ?? 1
        powerUpState.hintCount = save.powerUps["hint"] ?? 2
        powerUpState.clearLineCount = save.powerUps["clearLine"] ?? 1
        powerUpState.bombCount = save.powerUps["bomb"] ?? 1

        // load leaderboard
        loadLeaderboard()

        return true
    }

    func clearSave() {
        prefs.gameSaveData = nil
    }

    // MARK: - 内部

    private func createLevelGame(gridSize: Int) -> GameLogic {
        GameLogic(gridSize: gridSize, generator: BlockGenerator(allowFrozen: false))
    }

    private func resetCommonStateAndStart() {
        powerUpHistory.removeAll()
        maxLinesClearedThisGame = 0
        prefs.totalGamesPlayed += 1
        game.start()
    }

    private func applyLevelUnlocks() {
        powerUpState.reset()
        let level = currentLevelIndex + 1
        switch level {
        case ..<3: powerUpState.disableAll()
        case 3:
            powerUpState.reset()
            powerUpState.hintCount = 1
            powerUpState.undoCount = 0
            powerUpState.clearLineCount = 0
            powerUpState.bombCount = 0
        case 4:
            powerUpState.reset(); powerUpState.hintCount = 2
            powerUpState.undoCount = 0; powerUpState.clearLineCount = 0; powerUpState.bombCount = 0
        case 5:
            powerUpState.reset()
        default: powerUpState.disableAll()
        }
    }

    private func dateStr() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date())
    }

    private func saveLeaderboard() {
        if let json = try? JSONEncoder().encode(leaderboardEntries),
           let str = String(data: json, encoding: .utf8) {
            prefs.leaderboardData = str
        }
    }

    private func loadLeaderboard() {
        guard let str = prefs.leaderboardData, let data = str.data(using: .utf8),
              let entries = try? JSONDecoder().decode([LeaderboardEntry].self, from: data) else { return }
        leaderboardEntries = entries
    }
}

// MARK: - 道具

enum PowerUpType { case undo, hint, clearLine, bomb }

struct PowerUpState {
    var undoCount = 1
    var hintCount = 2
    var clearLineCount = 1
    var bombCount = 1

    mutating func reset() {
        undoCount = 1; hintCount = 2; clearLineCount = 1; bombCount = 1
    }

    mutating func disableAll() {
        undoCount = 0; hintCount = 0; clearLineCount = 0; bombCount = 0
    }
}
