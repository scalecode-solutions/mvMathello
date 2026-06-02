import SwiftUI
import mvMathelloKit

/// A plain RGB triple (0...1) so the land heat-gradient lerps without poking at
/// `UIColor`/`NSColor` internals (which differ by platform and colorspace).
public struct RGB: Sendable, Hashable {
    public var r, g, b: Double
    public init(_ r: Double, _ g: Double, _ b: Double) { self.r = r; self.g = g; self.b = b }
    public var color: Color { Color(red: r, green: g, blue: b) }
    public func lerp(to other: RGB, _ t: Double) -> RGB {
        let u = min(1, max(0, t))
        return RGB(r + (other.r - r) * u, g + (other.g - g) * u, b + (other.b - b) * u)
    }
}

/// Color palette for the Mathello board. Land cells are drawn on a heat scale by
/// Collatz stopping-time (dim → hot), so the Sierpiński pattern reads as a
/// scoring landscape; holes recede; power-of-two "anchors" glow.
public struct Theme: Sendable {
    public var pageBackground: Color
    /// Land heat endpoints (low / juiciest stopping-time).
    public var landLow: RGB
    public var landHigh: RGB
    public var hole: Color
    public var claimed: Color
    public var anchor: Color
    public var ghostLegal: Color
    public var ghostIllegal: Color
    public var headlineColor: Color
    public var bodyColor: Color
    public var golden: Color
    /// Parity-mode territory colors (defaults so the init/presets need no change).
    public var playerOne: Color = Color(red: 1.00, green: 0.36, blue: 0.62)
    public var playerTwo: Color = Color(red: 0.30, green: 0.82, blue: 0.96)

    /// Territory color for a Parity player.
    public func color(for player: Player) -> Color {
        player == .one ? playerOne : playerTwo
    }

    public init(
        pageBackground: Color, landLow: RGB, landHigh: RGB, hole: Color,
        claimed: Color, anchor: Color, ghostLegal: Color, ghostIllegal: Color,
        headlineColor: Color, bodyColor: Color, golden: Color
    ) {
        self.pageBackground = pageBackground
        self.landLow = landLow
        self.landHigh = landHigh
        self.hole = hole
        self.claimed = claimed
        self.anchor = anchor
        self.ghostLegal = ghostLegal
        self.ghostIllegal = ghostIllegal
        self.headlineColor = headlineColor
        self.bodyColor = bodyColor
        self.golden = golden
    }

    /// Heat color for a land cell, `heat` normalized 0...1.
    public func landColor(heat: Double) -> Color {
        landLow.lerp(to: landHigh, heat).color
    }
}

extension Theme {
    /// Neon fractal: ink page, cool→hot land heat, gold anchors.
    public static let neonFractal = Theme(
        pageBackground: Color(red: 0.05, green: 0.05, blue: 0.09),
        landLow: RGB(0.18, 0.26, 0.52),
        landHigh: RGB(1.00, 0.30, 0.62),
        hole: Color(red: 0.10, green: 0.10, blue: 0.15),
        claimed: Color(red: 0.36, green: 0.90, blue: 0.76),
        anchor: Color(red: 1.00, green: 0.84, blue: 0.38),
        ghostLegal: Color(red: 0.40, green: 1.00, blue: 0.70),
        ghostIllegal: Color(red: 1.00, green: 0.35, blue: 0.40),
        headlineColor: Color(red: 0.96, green: 0.96, blue: 1.0),
        bodyColor: Color(red: 0.72, green: 0.74, blue: 0.86),
        golden: Color(red: 1.00, green: 0.84, blue: 0.38)
    )
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .neonFractal
}

extension EnvironmentValues {
    public var mathelloTheme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension View {
    public func mathelloTheme(_ theme: Theme) -> some View {
        environment(\.mathelloTheme, theme)
    }
}
