import SwiftUI

// MARK: - GameOver

struct GameOverView: View {
    let score: Int
    let highScore: Int
    let isNewRecord: Bool
    let label: String
    var onRestart: () -> Void
    var onExit: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            if isNewRecord {
                Text("🏆 \(L10n.newRecord)")
                    .font(.largeTitle.bold())
                    .foregroundStyle(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
            } else {
                Text(L10n.gameOver)
                    .font(.largeTitle.bold())
            }
            Text(label).font(.callout).foregroundColor(.secondary)
            Divider()
            HStack(spacing: 40) {
                VStack { Text(L10n.scoreLabel).font(.caption).foregroundColor(.secondary); Text("\(score)").font(.title.monospacedDigit()) }
                VStack { Text(L10n.highScoreLabel).font(.caption).foregroundColor(.secondary); Text("\(highScore)").font(.title.monospacedDigit()) }
            }
            Divider()
            HStack(spacing: 24) {
                Button(L10n.restart, action: onRestart)
                    .buttonStyle(PrimaryButtonStyle())
                Button(L10n.exit, action: onExit)
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(32)
        .presentationDetents([.fraction(0.5)])
    }
}

// MARK: - Level Complete

struct LevelCompleteView: View {
    let level: LevelInfo?
    let score: Int
    var onNext: () -> Void
    var onExit: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text("🎉 \(L10n.levelComplete)")
                .font(.largeTitle.bold())
            if let lvl = level {
                Text(L10n.level(lvl.id, lvl.label))
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            Divider()
            Text(String(format: L10n.scoreFormat, score))
                .font(.title2.monospacedDigit())
            if let lvl = level {
                Text(String(format: L10n.targetFormat, lvl.targetScore))
                    .foregroundColor(.secondary)
            }
            Divider()
            HStack(spacing: 24) {
                Button(L10n.nextLevel, action: onNext)
                    .buttonStyle(PrimaryButtonStyle())
                Button(L10n.exit, action: onExit)
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(32)
        .presentationDetents([.fraction(0.45)])
    }
}

// MARK: - Settings

struct SettingsView: View {
    @ObservedObject var vm: GameViewModel
    @State private var soundMuted = AppPreferences.shared.soundMuted
    @State private var sfxEnabled = AppPreferences.shared.sfxEnabled
    @State private var bgmEnabled = AppPreferences.shared.bgmEnabled
    @State private var agreementAccepted = AppPreferences.shared.agreementAccepted
    let skin: Skin
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.soundSection) {
                    Toggle(L10n.mute, isOn: $soundMuted)
                    Toggle(L10n.sfx, isOn: $sfxEnabled)
                    Toggle(L10n.bgm, isOn: $bgmEnabled)
                }
                Section(L10n.otherSection) {
                    Toggle(L10n.agreement, isOn: $agreementAccepted)
                }
            }
            .navigationTitle(L10n.settings)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.done) {
                        AppPreferences.shared.soundMuted = soundMuted
                        AppPreferences.shared.sfxEnabled = sfxEnabled
                        AppPreferences.shared.bgmEnabled = bgmEnabled
                        AppPreferences.shared.agreementAccepted = agreementAccepted
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.5)])
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.secondary)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
