import SwiftUI

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
            .onAppear {
                // 后台存档
                vm.saveToPrefs()
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var skinManager: SkinManager
    @ObservedObject var animationManager: AnimationManager

    @State private var showGame = false
    @State private var showLeaderboard = false
    @State private var showStats = false
    @State private var showSkinPicker = false
    @State private var showTutorial = false
    @State private var showSettings = false

    var body: some View {
        if showGame {
            GameViewHost(vm: viewModel, skinManager: skinManager, animationManager: animationManager, isPresented: $showGame)
        } else {
            HomeScreen(
                showGame: $showGame,
                showLeaderboard: $showLeaderboard,
                showStats: $showStats,
                showSkinPicker: $showSkinPicker,
                showSettings: $showSettings,
                showTutorial: $showTutorial,
                vm: viewModel,
                skinManager: skinManager,
                skin: skinManager.current
            )
        }
    }
}

// MARK: - Home

struct HomeScreen: View {
    @Binding var showGame: Bool
    @Binding var showLeaderboard: Bool
    @Binding var showStats: Bool
    @Binding var showSkinPicker: Bool
    @Binding var showSettings: Bool
    @Binding var showTutorial: Bool
    @ObservedObject var vm: GameViewModel
    @ObservedObject var skinManager: SkinManager
    let skin: Skin

    var body: some View {
        ZStack {
            LinearGradient(colors: [skin.bgColor, skin.gridBgColor], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // 标题
                VStack(spacing: 8) {
                    Text("🧊")
                        .font(.system(size: 72))
                    Text(L10n.appTitle)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(skin.textPrimary)
                    Text(L10n.appSubtitle)
                        .font(.callout)
                        .foregroundColor(skin.textSecondary)
                }

                // 分数展示
                HStack(spacing: 40) {
                    VStack {
                        Text("\(AppPreferences.shared.highScore)")
                            .font(.title.monospacedDigit()).bold()
                        Text(L10n.highScore).font(.caption).foregroundColor(skin.textSecondary)
                    }
                    VStack {
                        Text("\(DailyChallenge.getStreak())\(L10n.dayUnit)")
                            .font(.title.monospacedDigit()).bold()
                        Text(L10n.streakDays).font(.caption).foregroundColor(skin.textSecondary)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 32)
                .background(skin.buttonFill.opacity(0.6))
                .cornerRadius(16)

                // 主按钮
                VStack(spacing: 12) {
                    Button {
                        showGame = true
                    } label: {
                        HStack {
                            Text("🎮").font(.title2)
                            Text(L10n.startGame)
                                .font(.title2.bold())
                        }
                        .frame(maxWidth: 220)
                        .padding(.vertical, 16)
                        .background(LinearGradient(colors: [.blue, .purple.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }

                    HStack(spacing: 16) {
                        HomeButton("🏆", L10n.leaderboard) { showLeaderboard = true }
                        HomeButton("📊", L10n.statistics) { showStats = true }
                        HomeButton("🎨", L10n.skin) { showSkinPicker = true }
                        HomeButton("📖", L10n.tutorial) { showTutorial = true }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showLeaderboard) { LeaderboardView(entries: vm.leaderboardEntries, skin: skin) }
        .sheet(isPresented: $showStats) { StatsView(skin: skin) }
        .sheet(isPresented: $showSkinPicker) { SkinPickerView(skinManager: skinManager) }
        .sheet(isPresented: $showSettings) { SettingsView(vm: vm, skin: skin) }
        .fullScreenCover(isPresented: $showTutorial) {
            ZStack {
                skin.bgColor.ignoresSafeArea()
                TutorialOverlay(manager: TutorialManager(), skin: skin)
            }
        }
    }
}

struct HomeButton: View {
    let icon: String; let title: String; let action: () -> Void

    init(_ icon: String, _ title: String, action: @escaping () -> Void) {
        self.icon = icon; self.title = title; self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(icon).font(.title2)
                Text(title).font(.system(size: 11)).foregroundColor(.secondary)
            }
            .frame(width: 64, height: 64)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}
