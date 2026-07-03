# BlockBlastPuzzle — iOS 架构文档

> **最后更新**: 2026-07-02 (v3 — 单元测试 + 暗色主题 + AnimationManager + 危险脉冲 + 音效对齐)
> **语言**: Swift 5.9+ · SwiftUI 5 · iOS 16.0+  
> **架构**: MVVM（`@MainActor ObservableObject` + 值类型 `GameLogic`）  
> **Bundle ID**: `com.meimi.blockblastpuzzle` · Display: 方块爆炸拼图 · EN: Block Blast Puzzle  
> **项目规模**: 29 个 `.swift` 源码 + 9 个测试文件 · 15 种语言 · 10 个功能目录

---

## 一、完整目录树

```
BlockBlastPuzzle-iOS/
├── .gitignore                               ← Xcode 忽略规则
├── ARCHITECTURE.md                          ← 你正在看的文档
├── BlockBlastPuzzle.xcodeproj/
│   └── project.pbxproj                      ← 含 15 语言 knownRegions
├── scripts/
│   └── screenshot_generator.sh              ← App Store 截图自动化脚本
│
├── BlockBlastPuzzle/                      ← ★ 源代码根
    │
    ├── Info.plist                           ← Bundle 标识 · CFBundleLocalizations(15) · 竖屏
    ├── Assets.xcassets/                     ← AppIcon / AccentColor
    │
    ├── App/
    │   └── BlockBlastPuzzleApp.swift       ← @main 入口 · 主页 · 高分/连签 · 4 个导航按钮
    │
    ├── Game/                                ← ★ 纯逻辑 · 零 UI 依赖
    │   ├── Models/
    │   │   ├── BlockShape.swift              ← 形状值类型 · rotate() · allOrientations()
    │   │   ├── BlockType.swift               ← .normal / .bomb / .rainbow / .frozen
    │   │   ├── Grid.swift                    ← N×N [[Int]] · 冰冻/彩虹 · canPlace/place/clear
    │   │   └── LeaderboardEntry.swift        ← 排行榜条目 (mode + label + score + date)
    │   │
    │   └── Engine/
    │       ├── GameLogic.swift               ← 核心状态机 · 放置/消除/结束 · snapshot/restore
    │       ├── BlockGenerator.swift          ← 三层策略生成 · xorshift* 确定性 RNG
    │       ├── GeneratorConfig.swift         ← 生成器可调参数
    │       ├── ScoreSystem.swift             ← 放置分 + 消除分 + Combo 倍增
    │       ├── SituationEvaluator.swift      ← 场况评估（AI 辅助生成）
    │       ├── SpecialBlockCooldown.swift    ← 特殊方块冷却
    │       └── DailyChallenge.swift          ← 日期种子 · 连签统计
    │
    ├── Models/                              ← 非游戏领域模型
    │   ├── Achievement.swift                 ← 12 个成就 · title/description 计算属性走 L10n
    │   ├── Skin.swift                        ← 9 套皮肤 · name 计算属性走 L10n
    │   └── AppTheme.swift                    ← 浅色/深色完整色板 · AppearanceMode 三态切换
    │
    ├── ViewModel/
    │   ├── GameViewModel.swift               ← @MainActor 中枢 · 4 种模式 · 道具 · LevelInfo
    │   └── AppPreferences.swift              ← UserDefaults 单例持久化
    │
    ├── Views/
    │   ├── Game/
    │   │   └── GameView.swift                ← Canvas 棋盘 + 待选方块 + 道具栏 + 顶栏 (单文件)
    │   ├── Dialogs/
    │   │   └── Dialogs.swift                 ← GameOver / LevelComplete / Settings (单文件)
    │   └── Pages/
    │       └── Pages.swift                   ← Leaderboard / Stats / SkinPicker (单文件)
    │
    ├── Services/
    │   ├── L10n.swift                        ← 15 语言 NSLocalizedString 封装 · levelName/achTitle/skinName
    │   ├── TutorialManager.swift             ← 5 步新手引导
    │   ├── SoundManager.swift                ← AVAudioEngine 合成 12 个 SFX（无音频文件）
    │   ├── AnimationManager.swift            ← 7 种动画管理器 (消除/分数/连击/危险脉冲/完美/炸弹/提示)
    │   ├── ScreenShakeManager.swift          ← 屏幕震动 (combo/消除/炸弹分级)
    │   ├── HapticManager.swift               ← UIImpactFeedbackGenerator 触觉反馈
    │   └── ParticleSystem.swift              ← 消除粒子特效
    │
    ├── Extensions/
    │   ├── Color+Hex.swift                   ← Color(hex: UInt) / hexValue 扩展
    │   └── Array+Safe.swift                  ← Array[safe:] 安全下标访问
    │
    └── {lang}.lproj/  × 15
        ├── Localizable.strings               ← 85+ 条 UI 翻译（含 level_name_1~10, ach_desc_xxx）
        └── InfoPlist.strings                  ← 权限描述翻译

└── BlockBlastPuzzleTests/                  ← ★ 9 个测试文件 · 108+ 用例
    ├── Game/
    │   ├── BlockShapeTest.swift          ← 18 形状 · 旋转 · 坐标一致性
    │   ├── GridTest.swift                ← 初始/放置/消除/冰冻/彩虹/炸弹
    │   ├── ScoreSystemTest.swift         ← 计分/Combo/完美清空/单色加成
    │   ├── GameLogicTest.swift           ← 状态机/快照/撤销/hint
    │   ├── BlockGeneratorTest.swift      ← 批次生成/种子稳定/保底机制
    │   ├── DailyChallengeTest.swift      ← 日期种子/连签/完成状态
    │   ├── GeneratorConfigTest.swift     ← 参数验证/概率单调性
    │   └── SituationEvaluatorTest.swift  ← 填充率/危险度/卡死检测
    └── Audio/
        └── SoundManagerTest.swift        ← 静音/快速连发/同步测试

  15 种语言: zh-Hans / en / ja / ko / es / fr / de / pt-BR / ru / ar / th / vi / id / it / tr
```

---

## 二、架构分层

```
┌─────────────────────────────────────────────────────────┐
│                   SwiftUI Views                         │
│  App · GameView(Canvas) · Dialogs · Pages               │
│  所有 View 级别文件: 仅 3 个 .swift                       │
├─────────────────────────────────────────────────────────┤
│  ViewModel                                             │
│  GameViewModel (@MainActor, ObservableObject)           │
│  AppPreferences (UserDefaults 单例)                     │
├──────────────────┬──────────────────────────────────────┤
│  Game/Engine     │  Models + Services                    │
│  纯值类型 struct  │  Achievement / Skin / L10n           │
│  零 Apple 框架   │  Tutorial / Sound / Particle          │
└──────────────────┴──────────────────────────────────────┘
```

---

## 三、数据流

```
用户触摸拖动 / 点击
        │
        ▼
  GameView (SwiftUI Canvas + DragGesture)
        │ vm.placeBlock(...) / vm.rotateBlock(...)
        ▼
  GameViewModel (@MainActor)
        │ game.placeBlock(...)
        │
        ├─→ SoundManager.shared.playPlace()     ← 音效反馈
        ├─→ HapticManager.shared.place()        ← 触觉反馈
        ├─→ (消除时) ScreenShakeManager          ← 屏幕震动
        ▼
  GameLogic (mutating struct)
        ├── Grid.canPlace → Grid.place
        ├── Grid.clearFullLines → 消除行/列
        ├── ScoreSystem.onClear (Combo 计算)
        └── BlockGenerator.generateBatch → 新方块
        │
        ▼
  @Published 属性变更 → SwiftUI 自动 diff 重绘
```

**核心原则**: `GameLogic` 是值类型 `struct`，每次 `mutating` 生成新副本 → `@Published` 触发 SwiftUI 重绘。

---

## 四、核心模块详解

### 4.1 App 入口 — `BlockBlastPuzzleApp.swift`

```swift
@main
struct BlockBlastPuzzleApp: App {
    @StateObject private var vm = GameViewModel()
    @StateObject private var skinManager = SkinManager()
    @StateObject private var soundManager = SoundManager.shared
    @StateObject private var animationManager = AnimationManager()

    var body: some Scene {
        WindowGroup {
            ContentView(
                viewModel: vm,
                skinManager: skinManager,
                animationManager: animationManager
            )
            .withAppTheme()
            .onAppear { vm.saveToPrefs() }  // 后台存档
        }
    }
}
```

主页布局: Logo → 高分 / 连签天数 → 开始游戏 → 排行榜 / 统计 / 皮肤 / 引导

### 4.2 游戏引擎 — `Game/Engine/`

| 文件 | 类型 | 职责 |
|------|------|------|
| `GameLogic` | struct | 核心状态机：放置/消除/结束/快照/恢复 |
| `ScoreSystem` | struct (Codable) | 放置分 + 消除分 + Combo 倍增 + 完美清空奖励(500) |
| `BlockGenerator` | class | 三层策略方块生成，xorshift* 确定性种子 |
| `GeneratorConfig` | struct | 生成器可调参数（概率/权重/冷却） |
| `SituationEvaluator` | struct | 场况评估（AI 辅助生成，填充率/危险度/最优位置） |
| `SpecialBlockCooldown` | struct | 特殊方块冷却（每N批保底1特殊块） |
| `DailyChallenge` | enum | 日期种子 + 连签统计 |

**方块生成三层策略**: 概率动态化（填充率↑→特殊方块↑）→ 类型权重（卡死→炸弹；连击→彩虹）→ 保底冷却（每 4 批保证 1 特殊块）

### 4.3 游戏模型 — `Game/Models/`

| 类型 | 说明 |
|------|------|
| `BlockShape` (struct, Codable, Hashable) | 相对坐标 `[Position]`，`rotate()` 支持 4 方向 |
| `BlockType` (enum) | `.normal` · `.bomb`(5×5) · `.rainbow`(同色清除) · `.frozen`(冻结N回合) |
| `Grid` (struct, Codable) | N×N `[[Int]]` (0=空, 1-7=颜色)；`frozenCells` / `rainbowCells` |
| `Position` | `(row: Int, col: Int)` |
| `PendingBlock` (struct, Codable) | 待用方块：shape + color + type + used |
| `LeaderboardEntry` | 排行榜：mode + label + score + date |

### 4.4 ViewModel — `GameViewModel.swift`

```swift
@MainActor
final class GameViewModel: ObservableObject {
    @Published var gameMode: GameMode    // free / level / dailyChallenge / survival
    @Published var game: GameLogic       // 核心游戏实例
    @Published var highScore: Int
    @Published var currentLevelIndex: Int
    @Published var levelScoreTotal: Int  // 关卡累计分
    @Published var survivalLives: Int    // 3→0
    @Published var survivalTotalScore: Int
    @Published var powerUpState: PowerUpState
    @Published var leaderboardEntries: [LeaderboardEntry]  // Top 20

    static let levels: [LevelInfo]       // 10 关 (id + targetScore + gridSize)
}
```

**四种模式**:

| 模式 | 网格 | 特殊规则 |
|------|------|----------|
| 自由 (free) | 9×9 | 无限，追求高分 |
| 关卡 (level) | 9→5 递减（每级 2 关） | 10 关，目标分递增，过关晋级 |
| 每日挑战 (dailyChallenge) | 固定种子 | 每日一次，全球同日方块序列相同 |
| 极限 (survival) | 5×5 | 通关全部 10 关后解锁，3 条命，死局（所有方块均无法放置）时 -1 命并重置棋盘 |

**LevelInfo**:
```swift
struct LevelInfo: Codable {
    let id: Int
    let targetScore: Int
    var label: String { L10n.levelName(id) }   // 计算属性，随系统语言切换
    let gridSize: Int
}
```

**四种道具**: 撤销 (Undo / GameStateSnapshot 回滚) · 提示 (Hint) · 消行 (Clear Line) · 炸弹 (Bomb / 5×5 爆破)

### 4.5 Models — `Models/`

| 文件 | 关键设计 |
|------|----------|
| `Achievement.swift` | 12 个成就 id → `title`/`description` 计算属性调用 `L10n.achTitle(id)` / `L10n.achDescription(id)` |
| `Skin.swift` | 9 套配色（含 blockColors/bgColor/gridBgColor/gridLineColor 等 13 个存储属性），`name` 计算属性调用 `L10n.skinName(id)`，SkinRepo 仓库枚举 + SkinManager @MainActor ObservableObject 同文件定义 |
| `AppTheme.swift` | 浅色/深色完整色板 (AppTheme struct) + `AppearanceMode` 三态切换 (system/light/dark) + `.withAppTheme()` ViewModifier |

### 4.6 持久化 — `AppPreferences.swift`

```swift
final class AppPreferences: ObservableObject {
    static let shared = AppPreferences()  // 单例
}
```

键空间: `game.*` (分数) · `sound.*` (静音/SFX/BGM) · `skin.*` (皮肤解锁)  
· `ach.*` (成就统计: rotates/places/lines/bombs/undos/clearlines)  
· `dc.*` (每日挑战日期/分数/连签历史) · `leaderboard.*` (排行榜)  
· `level.*` (关卡进度/通关标记) · `save.*` (游戏存档 JSON)  
· `tutorial.*` (引导步骤/完成) · `config.*` (协议同意)

### 4.7 Views

| 文件 | 包含的所有 View |
|------|----------------|
| `GameView.swift` | Canvas 网格 · 待选方块区 · ModeSwitch · 顶栏(分数/模式/生命) · 道具栏 · 退出确认弹窗 |
| `Dialogs.swift` | GameOverView · LevelCompleteView · SettingsView(音效/协议) |
| `Pages.swift` | LeaderboardView · StatsView · SkinPickerView |

### 4.8 Services

| 文件 | 职责 |
|------|------|
| `L10n.swift` | 15 语言本地化封装（见第五节） |
| `TutorialManager.swift` | 5 步引导教程（Android 版 7 步：含特殊方块介绍、道具、模式切换引导，iOS 暂未包含） |
| `SoundManager.swift` | AVAudioEngine 运行时合成 12 个 SFX（Android 版 11 SFX + BGM，详见 8.3） |
| `AnimationManager.swift` | 7 种动画管理器 (消除闪光/分数弹跳/连击特效/危险脉冲/完美清空/炸弹闪光/提示高亮) |
| `ScreenShakeManager.swift` | 屏幕震动 — Combo/消除/炸弹分级震动（对标 Android `ScreenShake.kt`） |
| `HapticManager.swift` | 触觉反馈 — `UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator`（对标 Android `Vibrator`） |
| `ParticleSystem.swift` | 消除粒子特效，`Particle` 内嵌为嵌套 struct |

---

## 五、本地化体系 (L10n)

```
L10n.swift
  │ NSLocalizedString(key, value: "中文fallback", comment: "")
  │ fallback 机制: 即使 .strings 文件缺失，也能显示中文
  │
  ├── 85+ 静态计算属性 (appTitle, startGame, leaderboard, ...)
  ├── levelName(_ id: Int)     → 10 个关卡名 (初入江湖 / Fresh Start / ...)
  ├── level(_ id, _ label)     → "第N关·label" / "Lv.N · label"
  ├── achTitle(_ id)           → 12 个成就标题
  ├── achDescription(_ id)     → 12 个成就描述
  └── skinName(_ id)           → 9 个皮肤名称

15× Localizable.strings      ← 每种语言独立翻译文件
15× InfoPlist.strings          ← 权限描述翻译
```

**调用方式**: `Text(L10n.startGame)` · `Button(L10n.restart)` · `String(format: L10n.highScoreFmt, score)` · `L10n.skinName(skin.id)`

---

## 六、关键设计决策

| 决策 | 原因 |
|------|------|
| Game 层全 struct 值类型 | 快照/撤销利用 Swift COW（Copy-on-Write），复用时零拷贝，仅修改时触发实际复制 |
| `@MainActor` ViewModel | SwiftUI 必须在主线程更新 `@Published` |
| View 单文件合并 | 避免过度拆分，减少 @ObservedObject 传递层级 |
| L10n 用 `value:` fallback | .strings 文件缺失不崩溃，回退显示中文 |
| Achievement/Skin/LevelInfo 属性从存储改为计算 | 切换系统语言时 UI 即时刷新 |
| xorshift* RNG + 日期种子 | 每日挑战全球同序，可复现、高性能 |
| AVAudioEngine 合成音效 | 无需打包音频文件，减少 IPA 体积 |
| Canvas 而非大量 View | 减少 SwiftUI diff 开销 |

---

## 七、App Store 上架状态

| # | 项目 | 状态 |
|---|------|------|
| 1 | 15 语言本地化 (Localizable.strings + InfoPlist.strings) | ✅ |
| 2 | CFBundleLocalizations / project.pbxproj | ✅ |
| 3 | App Store Connect 创建 App + 商店页元数据 | ⬜ |
| 4 | 截图 (6.7"/6.5"/5.5" × 15 语言) | ⬜ (脚本已就位) |
| 5 | 隐私政策 / 用户协议 URL | ⬜ |
| 6 | Xcode Archive → Validate → Upload | ⬜ |
| 7 | iPad 截图 | ⬜ |
| 8 | 触觉反馈 (Haptic) | ✅ `HapticManager` (UIImpactFeedbackGenerator) |

---

## 八、与 Android 版差异对照

> Android 版路径：`D:\7tan\BlockBlastPuzzle` · Kotlin + Compose · 42 个 `.kt` 文件  
> iOS 版路径：`D:\BlockBlastPuzzle-iOS` · SwiftUI · 29 个 `.swift` 文件 + 9 个测试文件

### 8.1 模块对照表

| 模块 | Android | iOS | 差异说明 |
|------|---------|-----|----------|
| **游戏引擎** | `game/` 9 文件 | `Game/Engine/` + `Game/Models/` 11 文件 | ✅ 逻辑完全一致；iOS 拆出独立 `BlockType.swift` |
| **18 种形状** | `ShapeLibrary` in `BlockShape.kt` | `ShapeLibrary` in `BlockShape.swift` | ✅ 1:1 翻译 |
| **BlockType** | 内嵌于 `BlockShape.kt` | 独立 `BlockType.swift` | iOS 更细粒度拆分 |
| **每日挑战** | `DailyChallenge.kt` | `DailyChallenge.swift` | ✅ 日期种子 + 连签完全一致 |
| **方块生成** | 三层策略 + xorshift* | 三层策略 + xorshift* | ✅ 算法 1:1 |
| **计分** | 放置分 + 消除分 + Combo + 完美清空奖励 | 放置分 + 消除分 + Combo + 完美清空奖励 | ✅ 完全一致（+500 + combo++） |
| **道具** | `PowerUpManager.kt` (独立类) | 内嵌 `GameViewModel.swift` | iOS 合并到 VM，功能完整 |
| **成就** | `AchievementManager.kt` + `AchievementData.kt` | `Achievement.swift` (合并) | ✅ 均为 12 项成就，ID 一一对应 |
| **皮肤** | `Skin.kt` + `SkinManager.kt` + `SkinPageController.kt` | `Skin.swift` + `SkinRepo` (解锁逻辑在 `AppPreferences`) | iOS 更简洁 |
| **排行榜** | `LeaderboardManager.kt` (独立) | 内嵌 `GameViewModel.swift` → `leaderboardEntries` | 功能一致，Top 20 |
| **统计** | `GameStats.kt` (独立) | 统计字段散落 `AppPreferences.swift` | iOS 无独立统计模型 |
| **教程** | `TutorialManager.kt` (7 步) | `TutorialManager.swift` (5 步) | iOS 少 2 步 (WELCOME/ROTATE/DRAG/CLEAR/SPECIAL_BLOCK/POWER_UPS/GAME_MODES)；Android 还含 `preFillGridForTutorial` 预填网格 |
| **主入口** | `MainActivity.kt` | `BlockBlastPuzzleApp.swift` | ✅ |
| **设置** | `SettingsDialog.kt` (Compose M2) | `SettingsView` in `Dialogs.swift` | ✅ SFX/BGM/协议 |
| **GameOver** | `GameOverDialog.kt` | `GameOverView` in `Dialogs.swift` | ✅ |
| **视图架构** | `GameView.kt` + 5 个 Renderer + TouchController + AnimationManager + GameLayout | `GameView.swift`(单文件 Canvas) + `AnimationManager.swift` | iOS 用 SwiftUI Canvas 替代多模块拆分；iOS 已实现 7 种动画管理器 (消除闪光/分数弹跳/连击特效/危险脉冲/完美清空/炸弹闪光/提示高亮) |
| **暗色模式** | `Theme.kt` — 完整深色主题 (`BlockBlastDarkColors`) | ✅ `Models/AppTheme.swift` | iOS 含浅色/深色完整色板 + `AppearanceMode` 三态切换 (system/light/dark) |
| **危险预警** | `updateDangerPulse()` — 填充率 >70% 警戒脉冲，>85% 快脉 + 微震 | ✅ `AnimationManager.triggerDangerPulse(fillRate:)` | 每次放置后调用；>70% 慢脉冲，>85% 快脉冲 |

### 8.2 暂未移植的功能

| 功能 | Android 实现 | iOS 状态 | 优先级 |
|------|-------------|----------|--------|
| **连击音效** (combo) | `generateRisingArpeggio` 上升琶音 | ✅ `SoundManager.playCombo(level:)` | 🟢 已完成 |
| **拒绝音效** (reject) | 方波蜂鸣，180Hz | ✅ `SoundManager.playReject()` | 🟢 已完成 |
| **提示音效** (hint) | 三角波柔和提示，880Hz | ✅ `SoundManager.playHint()` | 🟢 已完成 |
| **屏幕震动** (ScreenShake) | `ScreenShake.kt` — Combo 分级震动 | ✅ `ScreenShakeManager` | 🟢 已完成 |
| **触觉反馈** (Haptic) | Android `Vibrator` + `VibrationEffect` | ✅ `HapticManager` (UIImpactFeedbackGenerator) | 🟢 已完成 |
| **自动更新** (UpdateManager) | 协程 + 断点续传下载 APK | N/A (App Store 自动处理) | — |
| **百度统计** | `Baidu_Mobstat_SDK_1.7.jar` | N/A (不接入) | — |
| **单元测试** | 9 个测试文件 (SoundManagerSynthesisTest, BlockShapeTest, GridTest, ScoreSysTest, GameLogicTest, BlockGeneratorTest, GeneratorConfigTest, DailyChallengeTest, SituationEvalTest) | ✅ 9 个测试文件 (`BlockBlastPuzzleTests/`) — 含 108+ 测试用例 | 🟢 已完成 |
| **暗色模式** (Dark Theme) | `Theme.kt` — `BlockBlastDarkColors` 深色主题 | ✅ `Models/AppTheme.swift` — 含浅色/深色完整色板 + `.withAppTheme()` modifier | 🟢 已完成 |
| **动画管理器** (AnimationManager) | 7 种动画 (消除闪烁/分数弹跳/连击特效/危险脉冲/完美清空/炸弹闪光/提示高亮) | ✅ `Services/AnimationManager.swift` — 7 种动画已集成 GameView | 🟢 已完成 |
| **危险预警** (Danger Pulse) | `updateDangerPulse()` — 填充率 >70% 警戒脉冲，>85% 快脉+微震 | ✅ 集成于 `GameView.placeBlock` 后调用 `triggerDangerPulse(fillRate:)` | 🟢 已完成 |
| **Color(hex:) 扩展** | — | ✅ `Extensions/Color+Hex.swift` (UInt + String 双入口) | 🟢 已完成 |
| **Array[safe:] 扩展** | — | ✅ `Extensions/Array+Safe.swift` | 🟢 已完成 |
| **GameViewHost 桥接** | — | ✅ `Views/Game/GameView.swift` 底部 wrapper | 🟢 已完成 |
| **findHint()** | `GameLogic.findHint()` → Triple | ✅ `GameLogic.findHint()` → (Int, Int, Int)? | 🟢 已完成 |
| **教程预填网格** | `preFillGridForTutorial()` — 消行教程前预填 8/9 网格 | ❌ 未实现 | 🟢 低 |
| **完美清空奖励** | `onPerfectClear()` +500 分 + combo++ | ✅ 已对齐 Android（+500 + combo++） | 🟢 已完成 |
| **防篡改检测** | `verifySignature()` — APK 签名校验 | N/A (App Store 自动保护) | — |

### 8.3 音效对照

| 音效 | Android | iOS |
|------|---------|-----|
| 旋转 | ✅ rotate (三角波 880Hz) | ✅ `playRotate()` (正弦 880Hz) |
| 放置 | ✅ place (正弦 330Hz) | ✅ `playPlace()` (正弦 330Hz) |
| 消除 | ✅ clear (C-E-G 和弦) | ✅ `playClearLine()` (880Hz 单音) |
| 游戏结束 | ✅ gameover (扫频 440→165Hz) | ✅ `playGameOver()` (扫频 440→165Hz) |
| 拒绝/无法放置 | ✅ reject (方波 180Hz) | ✅ `playReject()` (方波合成) |
| 连击 | ✅ combo (上升琶音, 分级音量) | ✅ `playCombo(level:)` (上升琶音) |
| 完美清空 | ✅ perfect (阶梯琶音) | ✅ `playPerfectClear()` (1200Hz 单音) |
| 撤销 | ✅ undo (扫频 660→330Hz) | ✅ `playUndo()` (扫频 660→330Hz) |
| 提示 | ✅ hint (三角波 880Hz) | ✅ `playHint()` (正弦 880Hz) |
| 清行道具 | ✅ clearline (扫频 440→880Hz) | ✅ (合并到 clearLine) |
| 炸弹 | ✅ bomb (和弦 方波) | ✅ `playBomb()` |
| 按钮点击 | — | ✅ `playButtonTap()` (正弦 550Hz) |
| 关卡通关 | — | ✅ `playLevelComplete()` (正弦 1047Hz) |

### 8.4 Android 版参考文档

Android 项目含 8 份架构文档（7 份在 `docs/` + 1 份在根目录），iOS 开发时可参考：

| 文档 | 内容 |
|------|------|
| `v1.3.0-architecture.md` | 特殊方块三层策略 + 引导实操化 |
| `v1.2.0-architecture.md` | 新手引导、成就/统计/排行榜、BGM 架构 |
| `skin-system-architecture.md` | 9 套皮肤系统完整设计 |
| `bgm-fusion-plan.md` | BGM 6 声部合成方案 |
| `bgm-score.md` | BGM 简谱与和弦 |
| `GameView-refactor-plan.md` | GameView 2500 行拆分为 7 模块 |
| `settings-architecture.md` | 设置面板 (SFX/BGM/震动) |
| `../改进架构方案.md` | 四阶段提升方案 (爽快感/动力/深度/质感)，**根目录** |
