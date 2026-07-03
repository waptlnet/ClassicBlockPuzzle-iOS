import XCTest
@testable import BlockBlastPuzzle

/// 音效管理器测试：公开 API 不崩溃、静音状态切换、BGM 控制
/// 注：内部合成方法为 private，无法直接测试 PCM 样本；
/// Android SoundManagerSynthesisTest 测试的是 Kotlin 可内部访问的合成方法。
/// iOS 测试重点为公开接口的行为正确性。
final class SoundManagerTest: XCTestCase {

    var soundManager: SoundManager!

    override func setUp() {
        super.setUp()
        // 使用 shared 实例并确保非静音
        soundManager = SoundManager.shared
        soundManager.isMuted = false
        soundManager.sfxEnabled = true
    }

    override func tearDown() {
        soundManager.isMuted = false
        soundManager.sfxEnabled = true
        super.tearDown()
    }

    // MARK: - 静音/启用 状态切换

    func test静音时不触发崩溃() {
        soundManager.isMuted = true
        // 以下调用应在静音状态下安全返回（不崩溃）
        soundManager.playPlace()
        soundManager.playRotate()
        soundManager.playClearLine()
        soundManager.playCombo(level: 2)
        soundManager.playBomb()
        soundManager.playPerfectClear()
        soundManager.playUndo()
        soundManager.playReject()
        soundManager.playHint()
        soundManager.playGameOver()
        soundManager.playLevelComplete()
        soundManager.playButtonTap()
    }

    func test关闭音效时不触发崩溃() {
        soundManager.sfxEnabled = false
        soundManager.playPlace()
        soundManager.playRotate()
        soundManager.playClearLine()
        soundManager.playCombo(level: 3)
        soundManager.playBomb()
        soundManager.playPerfectClear()
        soundManager.playUndo()
        soundManager.playReject()
        soundManager.playHint()
        soundManager.playGameOver()
        soundManager.playLevelComplete()
    }

    // MARK: - 连续快速调用不崩溃

    func test连续快速播放不崩溃() {
        for _ in 0..<5 {
            soundManager.playPlace()
            soundManager.playRotate()
            soundManager.playClearLine()
            soundManager.playCombo(level: 1)
            soundManager.playCombo(level: 5)
            soundManager.playBomb()
            soundManager.playPerfectClear()
            soundManager.playUndo()
            soundManager.playReject()
            soundManager.playHint()
        }
    }

    // MARK: - 12 个 SFX 全部可调用不崩溃

    func test所有12个SFX可调用不崩溃() {
        let sfxFunctions: [() -> Void] = [
            { self.soundManager.playPlace() },
            { self.soundManager.playRotate() },
            { self.soundManager.playClearLine() },
            { self.soundManager.playCombo(level: 1) },
            { self.soundManager.playBomb() },
            { self.soundManager.playPerfectClear() },
            { self.soundManager.playUndo() },
            { self.soundManager.playReject() },
            { self.soundManager.playHint() },
            { self.soundManager.playGameOver() },
            { self.soundManager.playLevelComplete() },
            { self.soundManager.playButtonTap() },
        ]

        for sfx in sfxFunctions {
            soundManager.isMuted = false
            sfx()
        }
    }

    // MARK: - 连击分级音量

    func test连击1级以上可调用() {
        for level in 1...10 {
            soundManager.playCombo(level: level)
        }
    }

    // MARK: - BGM 控制不崩溃

    func testBGM开关切换不崩溃() {
        soundManager.bgmEnabled = false
        soundManager.bgmEnabled = true
        soundManager.bgmEnabled = false
    }
}
