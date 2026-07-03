import AVFoundation
import SwiftUI

/// 音效管理器 — 使用 AVAudioEngine 合成，对标 Android SoundPool
@MainActor
final class SoundManager: ObservableObject {
    static let shared = SoundManager()

    @AppStorage("sound.muted") var isMuted = false
    @AppStorage("sound.sfx_enabled") var sfxEnabled = true
    @AppStorage("sound.bgm_enabled") var bgmEnabled = true

    private let engine = AVAudioEngine()
    private var bgmPlayer: AVAudioPlayerNode?
    private var bgmBuffer: AVAudioPCMBuffer?

    private init() {
        setupEngine()
    }

    private func setupEngine() {
        let mixer = engine.mainMixerNode
        _ = mixer // connected by default
    }

    // MARK: - SFX（合成短音）

    private func playTone(freq: Float, duration: TimeInterval, volume: Float = 0.3) {
        guard !isMuted, sfxEnabled else { return }
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }

        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = Float(exp(-t * 8.0)) // 衰减
            data[i] = sin(2.0 * .pi * Double(freq) * t) * volume * envelope
        }

        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        player.scheduleBuffer(buffer, at: nil, options: .interruptsAtLoop) { [weak self] in
            self?.engine.detach(player)
        }
        do {
            try engine.start()
            player.play()
        } catch {
            print("Sound error: \(error)")
        }
    }

    /// 方波音色（用于拒绝等需要"蜂鸣感"的音效）
    private func playSquare(freq: Float, duration: TimeInterval, volume: Float = 0.3) {
        guard !isMuted, sfxEnabled else { return }
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }

        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = Float(exp(-t * 12.0))
            let phase = 2.0 * .pi * Double(freq) * t
            data[i] = (sin(phase) >= 0 ? 1.0 : -1.0) * Float(volume) * envelope
        }

        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        player.scheduleBuffer(buffer, at: nil, options: .interruptsAtLoop) { [weak self] in
            self?.engine.detach(player)
        }
        do { try engine.start(); player.play() } catch {}
    }

    /// 上升琶音（连击奖励音效，各频率依次快速奏响）
    private func playRisingArpeggio(freqs: [Float], duration: TimeInterval, volume: Float = 0.3) {
        guard !isMuted, sfxEnabled else { return }
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }

        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let progress = Double(i) / Double(frameCount)
            let idx = min(Int(progress * Double(freqs.count)), freqs.count - 1)
            let freq = freqs[idx]
            let envelope = Float(exp(-t * 10.0))
            data[i] = sin(2.0 * .pi * Double(freq) * t) * volume * envelope
        }

        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        player.scheduleBuffer(buffer, at: nil, options: .interruptsAtLoop) { [weak self] in
            self?.engine.detach(player)
        }
        do { try engine.start(); player.play() } catch {}
    }

    private func playNoise(duration: TimeInterval, volume: Float = 0.2) {
        guard !isMuted, sfxEnabled else { return }
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = Float(exp(-t * 5.0))
            data[i] = Float.random(in: -0.5...0.5) * volume * envelope
        }
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        player.scheduleBuffer(buffer, at: nil, options: .interruptsAtLoop) { [weak self] in
            self?.engine.detach(player)
        }
        do { try engine.start(); player.play() } catch {}
    }

    /// 频率扫描（从 start → end 线性变化），用于 gameover/undo
    private func playSweep(start: Float, end: Float, duration: TimeInterval, volume: Float = 0.35) {
        guard !isMuted, sfxEnabled else { return }
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }

        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let progress = t / duration
            let freq = Double(start) + (Double(end) - Double(start)) * progress
            let envelope = Float(exp(-t * 4.0))
            data[i] = sin(2.0 * .pi * freq * t) * volume * envelope
        }

        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        player.scheduleBuffer(buffer, at: nil, options: .interruptsAtLoop) { [weak self] in
            self?.engine.detach(player)
        }
        do { try engine.start(); player.play() } catch {}
    }

    /// 和弦合成（多个频率同时发声，带衰减）
    private func playChord(freqs: [Float], duration: TimeInterval, volume: Float = 0.3) {
        guard !isMuted, sfxEnabled else { return }
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }

        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = Float(exp(-t * 6.0))
            var sum: Float = 0
            for freq in freqs {
                sum += sin(2.0 * .pi * Double(freq) * t)
            }
            data[i] = (sum / Float(freqs.count)) * volume * envelope
        }

        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        player.scheduleBuffer(buffer, at: nil, options: .interruptsAtLoop) { [weak self] in
            self?.engine.detach(player)
        }
        do { try engine.start(); player.play() } catch {}
    }

    // MARK: - Public

    func playPlace() { playTone(freq: 330, duration: 0.08, volume: 0.3) }
    func playRotate() { playTone(freq: 880, duration: 0.06, volume: 0.25) }
    func playClearLine() { playTone(freq: 880, duration: 0.12, volume: 0.35) }
    func playGameOver() { playSweep(start: 440, end: 165, duration: 0.3, volume: 0.4) }
    func playLevelComplete() { playTone(freq: 1047, duration: 0.15, volume: 0.4) }
    func playButtonTap() { playTone(freq: 550, duration: 0.04, volume: 0.2) }

    /// 炸弹音效 — 低频和弦 + 噪音 组合，对标 Android bomb
    func playBomb() {
        // 播放低频和弦 (C2+E2+G2)，营造爆炸感
        playChord(freqs: [65.41, 82.41, 98.0], duration: 0.35, volume: 0.35)
        // 叠加噪音
        playNoise(duration: 0.3, volume: 0.25)
    }

    func playPerfectClear() { playTone(freq: 1200, duration: 0.2, volume: 0.4) }
    func playUndo() { playSweep(start: 660, end: 330, duration: 0.1, volume: 0.25) }

    /// 拒绝音效 — 方波蜂鸣 180Hz，对标 Android reject
    func playReject() { playSquare(freq: 180, duration: 0.08, volume: 0.3) }

    /// 提示音效 — 三角波柔和提示 880Hz，对标 Android hint
    func playHint() { playTone(freq: 880, duration: 0.08, volume: 0.35) }

    /// 连击音效 — 上升琶音 (C5→E5→G5→C6)，分级音量，对标 Android combo
    func playCombo(level: Int = 1) {
        let freqs: [Float] = [523.25, 659.25, 783.99, 1046.5]
        let vol = (0.4 + Float(level - 1) * 0.1).clamped(to: 0.4...1.0)
        playRisingArpeggio(freqs: freqs, duration: 0.18, volume: vol)
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
