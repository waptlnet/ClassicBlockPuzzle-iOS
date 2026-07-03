import SwiftUI

/// 粒子系统 — 方块放置/消除时粒子效果
struct Particle: Identifiable {
    let id = UUID()
    let colorIndex: Int
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var life: Double
    var maxLife: Double
    var size: CGFloat
}

@MainActor
final class ParticleSystem: ObservableObject {
    @Published var particles: [Particle] = []

    func emit(at center: CGPoint, colorIndex: Int, count: Int = 12) {
        for _ in 0..<count {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 40...120)
            let p = Particle(
                colorIndex: colorIndex,
                x: center.x, y: center.y,
                vx: CGFloat(cos(angle)) * speed,
                vy: CGFloat(sin(angle)) * speed - 30,
                life: 0, maxLife: Double.random(in: 0.3...0.8),
                size: CGFloat.random(in: 3...7)
            )
            particles.append(p)
        }
    }

    func emitLineClear(at center: CGPoint, colors: [Int], count: Int = 20) {
        for _ in 0..<count {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 60...200)
            let colorIdx = colors.randomElement() ?? 1
            let p = Particle(
                colorIndex: colorIdx,
                x: center.x, y: center.y,
                vx: CGFloat(cos(angle)) * speed,
                vy: CGFloat(sin(angle)) * speed - 60,
                life: 0, maxLife: Double.random(in: 0.5...1.0),
                size: CGFloat.random(in: 4...10)
            )
            particles.append(p)
        }
    }

    func update(deltaTime: TimeInterval) {
        particles = particles.compactMap { p in
            var p = p
            p.life += deltaTime
            if p.life > p.maxLife { return nil }
            p.x += p.vx * CGFloat(deltaTime)
            p.y += p.vy * CGFloat(deltaTime)
            p.vy += 200 * CGFloat(deltaTime) // gravity
            return p
        }
    }
}

// MARK: - ParticleCanvas

struct ParticleCanvas: View {
    @ObservedObject var system: ParticleSystem
    let skin: Skin

    var body: some View {
        Canvas { context, _ in
            for p in system.particles {
                let opacity = 1.0 - (p.life / p.maxLife)
                let color = skin.blockColors[safe: p.colorIndex]?.opacity(opacity) ?? .clear
                let rect = CGRect(x: p.x - p.size / 2, y: p.y - p.size / 2, width: p.size, height: p.size)
                context.fill(Path(ellipseIn: rect), with: .color(color))
            }
        }
        .allowsHitTesting(false)
    }
}
