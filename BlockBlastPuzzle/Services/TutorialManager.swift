import SwiftUI

/// 新手引导管理器
@MainActor
final class TutorialManager: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var isActive: Bool = false
    @Published var highlightRect: CGRect = .zero
    @Published var message: String = ""

    private let prefs = AppPreferences.shared

    static let steps: [TutorialStep] = [
        TutorialStep(id: 0, message: L10n.tutorialStep0, highlight: .bottomSlots),
        TutorialStep(id: 1, message: L10n.tutorialStep1, highlight: .board),
        TutorialStep(id: 2, message: L10n.tutorialStep2, highlight: .bottomSlots),
        TutorialStep(id: 3, message: L10n.tutorialStep3, highlight: .board),
        TutorialStep(id: 4, message: L10n.tutorialStep4, highlight: .powerBar),
    ]

    var isCompleted: Bool { prefs.tutorialCompleted }

    init() {
        isActive = !prefs.tutorialCompleted
    }

    func nextStep() {
        currentStep += 1
        if currentStep >= Self.steps.count {
            complete()
        }
    }

    func skip() { complete() }

    private func complete() {
        isActive = false
        prefs.tutorialCompleted = true
        prefs.tutorialStep = Self.steps.count
    }

    struct TutorialStep {
        let id: Int; let message: String; let highlight: HighlightArea
    }

    enum HighlightArea { case board, bottomSlots, powerBar }
}

// MARK: - Tutorial Overlay

struct TutorialOverlay: View {
    @ObservedObject var manager: TutorialManager
    let skin: Skin

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture { manager.nextStep() }

            VStack(spacing: 16) {
                Spacer()
                // 引导文字
                VStack(spacing: 12) {
                    Text(Self.steps[safe: manager.currentStep] ?? "")
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)

                    HStack(spacing: 16) {
                        Button(L10n.skipTutorial) { manager.skip() }
                            .font(.callout).foregroundColor(.white.opacity(0.7))

                        Button(L10n.nextStep) { manager.nextStep() }
                            .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }

    private static let steps = TutorialManager.steps.map { $0.message }
}
