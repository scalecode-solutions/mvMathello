import SwiftUI
import mvMathelloKit

/// A placement/capture event the board animates with the Metal burst shader.
public struct BurstEvent: Equatable, Sendable {
    public var center: Coord
    public var intensity: Double
    public var id: Int
    public init(center: Coord, intensity: Double, id: Int) {
        self.center = center
        self.intensity = intensity
        self.id = id
    }
}

/// Transparent radial burst (Metal `hailstoneBurst`) centered on a board cell,
/// animating over ~0.7s. Drop inside a `TimelineView(.animation)` keyed
/// `.id(burst.id)`; shared by both Hailstorm and Parity boards.
struct BurstView: View {
    let burst: BurstEvent
    let cell: CGFloat
    let span: CGFloat
    let start: Date
    /// Ray color — the shader uses the fill color, so callers tint the burst.
    var tint: Color = .white

    @State private var began = Date()

    var body: some View {
        let progress = min(1, start.timeIntervalSince(began) / 0.7)
        Rectangle()
            .fill(tint)
            .frame(width: span, height: span)
            .colorEffect(
                ShaderLibrary.bundle(.module).hailstoneBurst(
                    .float2(span, span),
                    .float(Float(progress)),
                    .float(Float(burst.intensity)),
                    .float(Float(burst.id % 17))
                )
            )
            .blendMode(.screen)
            .position(x: (CGFloat(burst.center.x) + 0.5) * cell,
                      y: (CGFloat(burst.center.y) + 0.5) * cell)
            .onAppear { began = Date() }
            .opacity(progress < 1 ? 1 : 0)
    }
}
