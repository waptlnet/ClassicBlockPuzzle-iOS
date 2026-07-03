import SwiftUI

// MARK: - Leaderboard

struct LeaderboardView: View {
    let entries: [LeaderboardEntry]
    let skin: Skin

    var body: some View {
        NavigationStack {
            List {
                if entries.isEmpty {
                    Text(L10n.noRecords).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .center).padding()
                }
                ForEach(Array(entries.enumerated()), id: \.offset) { idx, entry in
                    HStack {
                        Text("\(idx + 1)").font(.headline.monospacedDigit()).foregroundColor(rankColor(idx)).frame(width: 36)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(entry.score)").font(.title3.monospacedDigit())
                            HStack {
                                Text(iconFor(entry.mode)).font(.caption)
                                Text(entry.levelLabel).font(.caption).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Text(entry.date).font(.caption2).foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(L10n.leaderboard)
        }
    }

    private func rankColor(_ r: Int) -> Color {
        switch r { case 0: .orange; case 1: .gray; case 2: .brown; default: .secondary }
    }

    private func iconFor(_ mode: String) -> String {
        switch mode { case "FREE": "🎮"; case "LEVEL": "🏰"; case "DAILY": "📅"; case "SURVIVAL": "🔥"; default: "📊" }
    }
}

// MARK: - Stats

struct StatsView: View {
    let skin: Skin
    private let prefs = AppPreferences.shared

    var body: some View {
        NavigationStack {
            List {
                Section(L10n.gameDataSection) {
                    StatRow(L10n.gamesPlayed, "\(prefs.totalGamesPlayed)")
                    StatRow(L10n.timesPlaced, "\(prefs.totalPlaces)")
                    StatRow(L10n.timesRotated, "\(prefs.totalRotates)")
                    StatRow(L10n.linesCleared, "\(prefs.totalLinesCleared)")
                }
                Section(L10n.levelSection) {
                    StatRow(L10n.levelsCompleted, "\(prefs.levelsCompleted)")
                    StatRow(L10n.allLevelsCleared, prefs.hasClearedAllLevels ? "✅" : "❌")
                }
                Section(L10n.dailySection) {
                    StatRow(L10n.bestStreak, "\(prefs.bestDailyStreak)\(L10n.dayUnit)")
                    StatRow(L10n.currentStreak, "\(DailyChallenge.getStreak())\(L10n.dayUnit)")
                }
                Section(L10n.powerUpSection) {
                    StatRow(L10n.undosUsed, "\(prefs.totalUndosUsed)")
                    StatRow(L10n.bombsUsed, "\(prefs.totalBombsUsed)")
                    StatRow(L10n.clearLinesUsed, "\(prefs.totalClearLinesUsed)")
                }
                Section(L10n.achievementSection) {
                    ForEach(AchievementData.all) { ach in
                        HStack {
                            Text(ach.icon)
                            Text(ach.title).font(.callout)
                            Spacer()
                            Text(checkAchievement(ach) ? "✅" : "🔒").font(.caption)
                        }
                    }
                }
            }
            .navigationTitle(L10n.statistics)
        }
    }

    private func checkAchievement(_ ach: Achievement) -> Bool {
        switch ach.id {
        case .firstClear: return prefs.totalLinesCleared > 0
        case .combo3: return prefs.maxComboEver >= 3
        case .combo5: return prefs.maxComboEver >= 5
        case .clear4Lines: return prefs.maxLinesClearedOnce >= 4
        case .perfectClear: return prefs.hasPerfectClear
        case .score1000: return prefs.highScore >= 1000
        case .score5000: return prefs.highScore >= 5000
        case .rotate100: return prefs.totalRotates >= 100
        case .place500: return prefs.totalPlaces >= 500
        case .clear100Lines: return prefs.totalLinesCleared >= 100
        case .allLevels: return prefs.hasClearedAllLevels
        case .daily7Days: return prefs.bestDailyStreak >= 7
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String

    init(_ label: String, _ value: String) {
        self.label = label; self.value = value
    }

    var body: some View {
        HStack { Text(label).foregroundColor(.secondary); Spacer(); Text(value).font(.body.monospacedDigit()).bold() }
    }
}

// MARK: - Skin Picker

struct SkinPickerView: View {
    @ObservedObject var skinManager: SkinManager

    let columns = [GridItem(.adaptive(minimum: 110))]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(SkinRepo.all) { skin in
                        Button {
                            if skinManager.isUnlocked(skin) {
                                skinManager.select(skin)
                            }
                        } label: {
                            VStack(spacing: 6) {
                                // 预览色块
                                HStack(spacing: 1) {
                                    ForEach(1..<8) { i in
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(skin.blockColors[i])
                                            .frame(width: 8, height: 16)
                                    }
                                }
                                .padding(8)
                                .background(skin.gridBgColor)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(skinManager.current.id == skin.id ? Color.blue : Color.clear, lineWidth: 3)
                                )

                                HStack(spacing: 4) {
                                    Text(skin.emoji)
                                    Text(L10n.skinName(skin.id)).font(.caption).foregroundColor(.primary)
                                }
                            }
                        }
                        .opacity(skinManager.isUnlocked(skin) ? 1 : 0.4)
                    }
                }
                .padding()
            }
            .navigationTitle(L10n.skin)
        }
    }
}
