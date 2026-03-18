import SwiftUI

private struct SparkleParticle {
    let seed: Double
    let baseX: Double
    let size: Double
    let fallSpeed: Double
    let driftAmplitude: Double
    let driftFrequency: Double
    let opacity: Double
    let phaseOffset: Double
    let isStarPoint: Bool

    func position(at time: Double, in size: CGSize) -> CGPoint {
        let cycle = time * driftFrequency + phaseOffset
        let drift = sin(cycle) * driftAmplitude
        let y = (time * fallSpeed + seed).truncatingRemainder(dividingBy: size.height + 50) - 50
        let x = baseX + drift
        return CGPoint(x: x, y: y)
    }

    func currentOpacity(at time: Double) -> Double {
        let cycle = (time * 0.5 + phaseOffset).truncatingRemainder(dividingBy: .pi * 2)
        return opacity * (0.5 + 0.5 * sin(cycle))
    }
}

struct GoldSparkleOverlay: View {
    private let particleCount = 48
    private let primaryColor = CSColor.signalPrimary
    private let starColor = Color.white

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            Canvas { ctx, size in
                let time = context.date.timeIntervalSinceReferenceDate
                for i in 0..<particleCount {
                    let p = particle(for: i, canvasSize: size)
                    let pos = p.position(at: time, in: size)
                    let alpha = p.currentOpacity(at: time)
                    let r = p.size
                    let rect = CGRect(x: pos.x - r, y: pos.y - r, width: r * 2, height: r * 2)
                    let color = p.isStarPoint ? starColor : primaryColor
                    let baseAlpha = p.isStarPoint ? alpha * 0.7 : alpha * 0.6
                    ctx.fill(
                        Path(ellipseIn: rect),
                        with: .color(color.opacity(baseAlpha))
                    )
                    ctx.fill(
                        Path(ellipseIn: rect.insetBy(dx: -1, dy: -1)),
                        with: .color(color.opacity(baseAlpha * 0.3))
                    )
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func particle(for index: Int, canvasSize: CGSize) -> SparkleParticle {
        let seed = Double(index) * 0.137
        let baseX = (seed * 1.1).truncatingRemainder(dividingBy: 1.0) * canvasSize.width
        let size = 2.0 + (seed * 0.7).truncatingRemainder(dividingBy: 3.0)
        let fallSpeed = 25 + (seed * 1.3).truncatingRemainder(dividingBy: 45.0)
        let driftAmplitude = 8 + (seed * 0.9).truncatingRemainder(dividingBy: 16.0)
        let driftFrequency = 0.8 + (seed * 0.4).truncatingRemainder(dividingBy: 0.8)
        let opacity = 0.4 + (seed * 0.5).truncatingRemainder(dividingBy: 0.5)
        let phaseOffset = seed * .pi * 2
        let isStarPoint = index % 5 == 0
        return SparkleParticle(
            seed: seed * (canvasSize.height + 100),
            baseX: baseX,
            size: isStarPoint ? size * 0.7 : size,
            fallSpeed: fallSpeed,
            driftAmplitude: driftAmplitude,
            driftFrequency: driftFrequency,
            opacity: opacity,
            phaseOffset: phaseOffset,
            isStarPoint: isStarPoint
        )
    }
}

#Preview {
    ZStack {
        Color.black
        GoldSparkleOverlay()
    }
    .frame(height: 220)
}
