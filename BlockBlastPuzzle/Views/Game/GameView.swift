import SwiftUI

// MARK: - Main Game View

struct GameView: View {
    @ObservedObject var vm: GameViewModel
    @ObservedObject var skinManager: SkinManager
    @ObservedObject var animationManager: AnimationManager
    @Binding var isPresented: Bool
    @State private var selectedBlockIndex: Int? = nil
    @State private var showGameOver = false
    @State private var showLevelComplete = false
    @State private var showSurvivalOver = false
    @State private var showSettings = false
    @State private var showLeaderboard = false
    @State private var showStats = false
    @State private var showSkinPicker = false
    @State private var showExitConfirm = false

    var skin: Skin { skinManager.current }

    var body: some View {
        GeometryReader { geo in
            let isPad = geo.size.width > 600
            let boardSize = min(geo.size.width - 32, geo.size.height * 0.55)
            let cellSize = boardSize / CGFloat(vm.game.gridSize)

            VStack(spacing: 0) {
                TopBarView(vm: vm, skin: skin, onModeTap: { vm.switchMode() })

                // 棋盘 — 点击放置（含动画层）
                ZStack {
                    BoardCanvas(
                        game: vm.game,
                        skin: skin,
                        cellSize: cellSize,
                        selectedBlockIndex: selectedBlockIndex,
                        onCellTap: { r, c in
                            guard let idx = selectedBlockIndex else { return }
                            vm.saveForUndo()
                            if vm.placeBlock(atIndex: idx, atRow: r, col: c) {
                                selectedBlockIndex = nil
                                AppPreferences.shared.totalPlaces += 1
                                // 危险脉冲：根据网格填充率更新
                                let fillRate = SituationEvaluator(grid: vm.game.grid).fillRate()
                                animationManager.triggerDangerPulse(fillRate: fillRate)

                                if vm.game.isGameOver {
                                    vm.handleGameOver()
                                    showGameOverSheet()
                                } else if vm.gameMode == .level, vm.checkLevelComplete() {
                                    vm.levelScoreTotal += vm.game.score
                                    showLevelComplete = true
                                }
                            }
                        }
                    )

                    // ── 动画覆盖层 ──

                    // 消除闪烁
                    if animationManager.clearFlashActive,
                       let pos = animationManager.clearFlashPosition {
                        Rectangle()
                            .fill(.white.opacity(0.6))
                            .frame(width: cellSize, height: cellSize)
                            .position(x: CGFloat(pos.col) * cellSize + cellSize / 2,
                                      y: CGFloat(pos.row) * cellSize + cellSize / 2)
                    }

                    // 危险脉冲
                    if animationManager.dangerPulseActive {
                        Rectangle()
                            .fill(.red.opacity(animationManager.dangerPulseProgress * 0.2))
                            .animation(nil, value: animationManager.dangerPulseProgress)
                    }

                    // 完美清空
                    if animationManager.perfectClearActive {
                        Rectangle()
                            .fill(.yellow.opacity(animationManager.perfectClearProgress * 0.5))
                            .allowsHitTesting(false)
                    }

                    // 炸弹闪光
                    if animationManager.bombFlashActive,
                       let pos = animationManager.bombFlashPosition {
                        Circle()
                            .fill(.white.opacity(0.7))
                            .frame(width: cellSize * 2, height: cellSize * 2)
                            .position(x: CGFloat(pos.col) * cellSize + cellSize / 2,
                                      y: CGFloat(pos.row) * cellSize + cellSize / 2)
                    }

                    // 提示高亮
                    if animationManager.hintActive,
                       let pos = animationManager.hintPosition {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.yellow, lineWidth: 2)
                            .frame(width: cellSize, height: cellSize)
                            .position(x: CGFloat(pos.col) * cellSize + cellSize / 2,
                                      y: CGFloat(pos.row) * cellSize + cellSize / 2)
                            .opacity(animationManager.hintActive ? 1 : 0)
                    }

                    // 连击特效
                    if animationManager.comboEffectActive {
                        VStack(spacing: 4) {
                            Text("🔥")
                                .font(.system(size: 36))
                            Text("x\(animationManager.comboEffectLevel)")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundColor(.orange)
                        }
                        .scaleEffect(1.0 + animationManager.comboEffectProgress * 0.4)
                        .opacity(1.0 - animationManager.comboEffectProgress)
                    }

                    // 分数弹跳
                    if animationManager.scorePopActive {
                        Text("+\(vm.game.score)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                            .position(animationManager.scorePopPosition)
                            .opacity(animationManager.scorePopActive ? 1 : 0)
                    }
                }
                .frame(width: boardSize, height: boardSize)

                // 道具栏
                PowerUpBar(vm: vm, skin: skin)

                // 底部方块槽 — 点击选中/旋转
                BlockSlotsView(
                    pendingBlocks: vm.game.pendingBlocks,
                    cellSize: cellSize * 1.1,
                    skin: skin,
                    selectedIndex: selectedBlockIndex,
                    onSelect: { idx in
                        if selectedBlockIndex == idx {
                            // 再次点击已选中的 → 旋转
                            _ = vm.rotateBlock(atIndex: idx)
                            AppPreferences.shared.totalRotates += 1
                        } else {
                            selectedBlockIndex = idx
                        }
                    }
                )
                .padding(.top, 12)

                // 底部菜单栏
                HStack(spacing: 20) {
                    Spacer()
                    MenuButton(icon: "🏆", label: L10n.leaderboard) { showLeaderboard = true }
                    MenuButton(icon: "📊", label: L10n.statistics) { showStats = true }
                    MenuButton(icon: "🎨", label: L10n.skin) { showSkinPicker = true }
                    MenuButton(icon: "⚙️", label: L10n.settings) { showSettings = true }
                    Spacer()
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, isPad ? 40 : 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(skin.bgColor)
            .screenShake()
        }
        .sheet(isPresented: $showGameOver) {
            GameOverView(
                score: vm.currentScore(),
                highScore: vm.highScore,
                isNewRecord: vm.currentScore() > AppPreferences.shared.highScore,
                label: gameOverLabel,
                onRestart: { vm.restart(); showGameOver = false },
                onExit: { showGameOver = false; showExitConfirm = true }
            )
        }
        .sheet(isPresented: $showLevelComplete) {
            LevelCompleteView(
                level: GameViewModel.levels[safe: vm.currentLevelIndex],
                score: vm.levelScoreTotal,
                onNext: { vm.advanceLevel(); showLevelComplete = false },
                onExit: { showLevelComplete = false; showExitConfirm = true }
            )
        }
        .sheet(isPresented: $showSurvivalOver) {
            GameOverView(
                score: vm.survivalTotalScore,
                highScore: vm.highScore,
                isNewRecord: vm.survivalTotalScore > AppPreferences.shared.highScore,
                label: String(format: L10n.survivalOverLabel, 3 - vm.survivalLives),
                onRestart: { vm.restart(); showSurvivalOver = false },
                onExit: { showSurvivalOver = false; showExitConfirm = true }
            )
        }
        .sheet(isPresented: $showSettings) { SettingsView(vm: vm, skin: skin) }
        .sheet(isPresented: $showLeaderboard) { LeaderboardView(entries: vm.leaderboardEntries, skin: skin) }
        .sheet(isPresented: $showStats) { StatsView(skin: skin) }
        .sheet(isPresented: $showSkinPicker) { SkinPickerView(skinManager: skinManager) }
        .alert(L10n.confirmExit, isPresented: $showExitConfirm) {
            Button(L10n.cancel, role: .cancel) { }
            Button(L10n.exitToHome, role: .destructive) {
                vm.saveToPrefs()
                isPresented = false
            }
        } message: {
            Text(L10n.autoSaveMsg)
        }
    }

    private var gameOverLabel: String {
        if vm.gameMode == .level {
            return GameViewModel.levels[safe: vm.currentLevelIndex].map { "\(L10n.levelFailed) — \(L10n.level($0.id, $0.label))" } ?? L10n.gameOver
        }
        return L10n.gameOver
    }

    private func showGameOverSheet() {
        if vm.gameMode == .survival {
            showSurvivalOver = true
        } else {
            showGameOver = true
        }
    }
}

// MARK: - Top Bar

struct TopBarView: View {
    @ObservedObject var vm: GameViewModel
    let skin: Skin

    var onModeTap: () -> Void

    private var modeTitle: String {
        switch vm.gameMode {
        case .free: return L10n.freeMode
        case .level:
            let lvl = GameViewModel.levels[safe: vm.currentLevelIndex]
            return lvl.map { L10n.level($0.id, $0.label) } ?? L10n.levelMode
        case .dailyChallenge: return L10n.dailyChallenge
        case .survival: return L10n.survivalMode
        }
    }

    private var modeEmoji: String {
        switch vm.gameMode {
        case .free: return "🎮"
        case .level:
            let lvl = GameViewModel.levels[safe: vm.currentLevelIndex]
            return lvl.map { _ in "🏰" } ?? "🎯"
        case .dailyChallenge: return "📅"
        case .survival:
            let full = String(repeating: "🟢", count: vm.survivalLives)
            let empty = String(repeating: "⬛", count: 3 - vm.survivalLives)
            return full + empty
        }
    }

    var body: some View {
        HStack {
            // 左侧：分数
            VStack(alignment: .leading, spacing: 2) {
                Text("\(vm.currentScore())")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(skin.textPrimary)
                Text(String(format: L10n.highScoreFmt, vm.highScore))
                    .font(.caption)
                    .foregroundColor(skin.textSecondary)
            }

            Spacer()

            // 中间：模式信息
            VStack(spacing: 2) {
                if vm.gameMode == .survival {
                    Text(modeEmoji)
                        .font(.title3)
                }
                Text(modeTitle)
                    .font(.caption)
                    .foregroundColor(skin.textSecondary)
            }

            Spacer()

            // 右侧：模式切换按钮
            Button(action: onModeTap) {
                Text(modeSwitchLabel)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(skin.buttonFill)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(skin.buttonStroke, lineWidth: 1)
                    )
            }
            .foregroundColor(skin.textPrimary)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }

    private var modeSwitchLabel: String {
        switch vm.gameMode {
        case .free: return String(format: L10n.switchTo, L10n.levelMode)
        case .level: return String(format: L10n.switchTo, L10n.dailyChallenge)
        case .dailyChallenge: return vm.allLevelsCleared ? String(format: L10n.switchTo, L10n.survivalMode) : String(format: L10n.switchTo, L10n.freeMode)
        case .survival: return String(format: L10n.switchTo, L10n.freeMode)
        }
    }
}

// MARK: - Board Canvas

struct BoardCanvas: View {
    let game: GameLogic
    let skin: Skin
    let cellSize: CGFloat
    let selectedBlockIndex: Int?

    var onCellTap: (Int, Int) -> Void

    var body: some View {
        Canvas { context, size in
            let gridW = CGFloat(game.gridSize) * cellSize
            let ox = (size.width - gridW) / 2
            let oy = (size.height - gridW) / 2

            // 背景
            context.fill(Path(CGRect(x: ox, y: oy, width: gridW, height: gridW)),
                         with: .color(skin.gridBgColor))

            // 网格线
            for i in 0...game.gridSize {
                let x = ox + CGFloat(i) * cellSize
                let y = oy + CGFloat(i) * cellSize
                var vLine = Path(); vLine.move(to: CGPoint(x: x, y: oy)); vLine.addLine(to: CGPoint(x: x, y: oy + gridW))
                var hLine = Path(); hLine.move(to: CGPoint(x: ox, y: y)); hLine.addLine(to: CGPoint(x: ox + gridW, y: y))
                context.stroke(vLine, with: .color(skin.gridLineColor.opacity(0.3)), lineWidth: 0.5)
                context.stroke(hLine, with: .color(skin.gridLineColor.opacity(0.3)), lineWidth: 0.5)
            }

            // 已放置方块
            for r in 0..<game.gridSize {
                for c in 0..<game.gridSize {
                    let colorIdx = game.grid.cells[r][c]
                    if colorIdx != 0 {
                        let rect = CGRect(x: ox + CGFloat(c) * cellSize + 1, y: oy + CGFloat(r) * cellSize + 1,
                                          width: cellSize - 2, height: cellSize - 2)
                        drawBlock(context: &context, rect: rect, colorIdx: colorIdx)
                    }
                }
            }

            // 冰冻/彩虹标记
            for (pos, _) in game.grid.frozenCells {
                let rect = CGRect(x: ox + CGFloat(pos.col) * cellSize, y: oy + CGFloat(pos.row) * cellSize,
                                  width: cellSize, height: cellSize)
                context.fill(Path(rect), with: .color(.white.opacity(0.4)))
                context.draw(Text("❄️").font(.system(size: cellSize * 0.5)), at: CGPoint(x: rect.midX, y: rect.midY))
            }
            for pos in game.grid.rainbowCells {
                let rect = CGRect(x: ox + CGFloat(pos.col) * cellSize, y: oy + CGFloat(pos.row) * cellSize,
                                  width: cellSize, height: cellSize)
                context.draw(Text("🌈").font(.system(size: cellSize * 0.4)), at: CGPoint(x: rect.midX, y: rect.midY))
            }

            // 高亮可放置位置
            if let idx = selectedBlockIndex, idx < game.pendingBlocks.count, !game.pendingBlocks[idx].used {
                let block = game.pendingBlocks[idx]
                for r in 0..<game.gridSize {
                    for c in 0..<game.gridSize {
                        if game.grid.canPlace(block.shape, at: Position(r, c)) {
                            let rect = CGRect(x: ox + CGFloat(c) * cellSize + 2, y: oy + CGFloat(r) * cellSize + 2,
                                              width: cellSize - 4, height: cellSize - 4)
                            context.stroke(Path(rect), with: .color(.white.opacity(0.5)), lineWidth: 1.5)
                        }
                    }
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    let gridW = cellSize * CGFloat(game.gridSize)
                    let loc = value.location
                    guard loc.x >= 0, loc.x < gridW, loc.y >= 0, loc.y < gridW else { return }
                    let col = Int(loc.x / cellSize)
                    let row = Int(loc.y / cellSize)
                    onCellTap(row, col)
                }
        )
    }

    private func drawBlock(context: inout GraphicsContext, rect: CGRect, colorIdx: Int) {
        let color = skin.blockColors[safe: colorIdx] ?? .gray
        switch skin.glossStyle {
        case .glass:
            context.fill(Path(rect), with: .color(color))
            let highlight = Path(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height * 0.4))
            context.fill(highlight, with: .color(.white.opacity(0.3)))
        case .metallic:
            let gradient = Gradient(colors: [color.opacity(0.6), color, color.opacity(0.8)])
            context.fill(Path(rect), with: .linearGradient(gradient, startPoint: CGPoint(x: rect.minX, y: 0), endPoint: CGPoint(x: rect.maxX, y: 0)))
        case .subtle:
            context.fill(Path(rect), with: .color(color))
            let top = Path(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height * 0.2))
            context.fill(top, with: .color(.white.opacity(0.2)))
        case .none:
            context.fill(Path(rect), with: .color(color))
        }
    }
}

// MARK: - Block Slots

struct BlockSlotsView: View {
    let pendingBlocks: [PendingBlock]
    let cellSize: CGFloat
    let skin: Skin
    let selectedIndex: Int?
    var onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 16) {
            ForEach(Array(pendingBlocks.enumerated()), id: \.offset) { idx, block in
                BlockSlot(
                    block: block,
                    color: skin.blockColors[safe: block.color] ?? .gray,
                    cellSize: cellSize,
                    isSelected: selectedIndex == idx,
                    skin: skin,
                    onTap: { onSelect(idx) }
                )
                .opacity(block.used ? 0.3 : 1.0)
            }
        }
        .padding(.horizontal, 8)
    }
}

struct BlockSlot: View {
    let block: PendingBlock
    let color: Color
    let cellSize: CGFloat
    let isSelected: Bool
    let skin: Skin
    var onTap: () -> Void

    var body: some View {
        VStack(spacing: 2) {
            // 特殊标记
            if block.type != .normal {
                Text(typeEmoji(block.type))
                    .font(.system(size: 10))
            }
            // 形状预览
            Canvas { context, size in
                let sc = min(cellSize, size.width / CGFloat(block.shape.width + 1),
                             size.height / CGFloat(block.shape.height + 1))
                let ox = (size.width - CGFloat(block.shape.width) * sc) / 2
                let oy = (size.height - CGFloat(block.shape.height) * sc) / 2
                for cell in block.shape.cells {
                    let rect = CGRect(x: ox + CGFloat(cell.col) * sc + 1,
                                      y: oy + CGFloat(cell.row) * sc + 1,
                                      width: sc - 2, height: sc - 2)
                    context.fill(Path(rect), with: .color(color))
                }
            }
            .frame(width: cellSize * 4, height: cellSize * 4)
        }
        .padding(6)
        .background(isSelected ? Color.blue.opacity(0.2) : skin.buttonFill.opacity(0.5))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.blue : skin.buttonStroke.opacity(0.3), lineWidth: isSelected ? 3 : 1)
        )
        .onTapGesture { onTap() }
    }

    private func typeEmoji(_ t: BlockType) -> String {
        switch t { case .bomb: "💣"; case .rainbow: "🌈"; case .frozen: "❄️"; default: "" }
    }
}

// MARK: - PowerUp Bar

struct PowerUpBar: View {
    @ObservedObject var vm: GameViewModel
    let skin: Skin

    var body: some View {
        HStack(spacing: 12) {
            PowerUpButton(icon: "↩️", count: vm.powerUpState.undoCount, label: L10n.undo,
                          enabled: vm.canUsePowerUp(.undo),
                          action: { _ = vm.usePowerUp(.undo) })

            PowerUpButton(icon: "💡", count: vm.powerUpState.hintCount, label: L10n.hint,
                          enabled: vm.canUsePowerUp(.hint),
                          action: { _ = vm.usePowerUp(.hint) })

            PowerUpButton(icon: "🧹", count: vm.powerUpState.clearLineCount, label: L10n.clearLine,
                          enabled: vm.canUsePowerUp(.clearLine),
                          action: { _ = vm.usePowerUp(.clearLine) })

            PowerUpButton(icon: "💣", count: vm.powerUpState.bombCount, label: L10n.bomb,
                          enabled: vm.canUsePowerUp(.bomb),
                          action: { _ = vm.usePowerUp(.bomb) })
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - PowerUp Button

struct PowerUpButton: View {
    let icon: String
    let count: Int
    let label: String
    let enabled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(icon).font(.title3)
                Text("\(count)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                Text(label).font(.system(size: 9))
            }
            .frame(minWidth: 52)
            .padding(.vertical, 6)
            .background(enabled ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }
}

// MARK: - Menu Button

struct MenuButton: View {
    let icon: String
    let label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(icon).font(.title2)
                Text(label).font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(width: 56, height: 56)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - GameViewHost (桥接 App 层到 GameView)

/// 包装器：将 App 层的 @StateObject 传递给 GameView
struct GameViewHost: View {
    @ObservedObject var vm: GameViewModel
    @ObservedObject var skinManager: SkinManager
    @ObservedObject var animationManager: AnimationManager
    @Binding var isPresented: Bool

    var body: some View {
        GameView(vm: vm, skinManager: skinManager, animationManager: animationManager, isPresented: $isPresented)
    }
}
