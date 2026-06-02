import SwiftUI
import mvMathelloKit

/// Renders the left-aligned Pascal / Sierpiński triangle and handles aiming:
/// drag a ghost pentomino around the board, lift to place. Land cells are a
/// heat map (Collatz stopping-time), holes recede, power-of-two anchors ring in
/// gold, and a Metal burst fires over each placement.
struct BoardView: View {
    @Environment(\.mathelloTheme) private var theme
    let vm: HailstormViewModel

    private var board: PascalBoard { vm.session.board }
    private var rows: Int { board.rows }

    /// Cells to lift the ghost above the fingertip while aiming.
    private static let aimLift = 3

    var body: some View {
        GeometryReader { geo in
            let cell = min(geo.size.width, geo.size.height) / CGFloat(rows)
            let claimed = vm.session.claimed
            let ghost = Set(vm.ghostCells)
            let legal = vm.ghostLegal

            ZStack(alignment: .topLeading) {
                Canvas { ctx, _ in
                    for row in 0..<rows {
                        for col in 0...row {
                            let coord = Coord(col, row)
                            let rect = CGRect(x: CGFloat(col) * cell + 1, y: CGFloat(row) * cell + 1,
                                              width: cell - 2, height: cell - 2)
                            let path = Path(roundedRect: rect, cornerRadius: cell * 0.2)

                            if claimed.contains(coord) {
                                // Placed = a SOLID tile (shows the captured value) with a sheen.
                                let heat = vm.heat(row: row, col: col)
                                ctx.fill(path, with: .color(theme.landColor(heat: heat)))
                                ctx.stroke(path, with: .color(.white.opacity(0.35)), lineWidth: max(1, cell * 0.06))
                            } else if board.isLand(row: row, col: col) {
                                // Open scoring cell = a glowing WELL: faint fill, heat-bright outline.
                                let heat = vm.heat(row: row, col: col)
                                let c = theme.landColor(heat: heat)
                                ctx.fill(path, with: .color(c.opacity(0.16)))
                                ctx.stroke(path, with: .color(c.opacity(0.9)),
                                           lineWidth: max(1, cell * 0.045 + heat * cell * 0.07))
                            } else {
                                // Hole = closed, no points.
                                ctx.fill(path, with: .color(theme.hole.opacity(0.55)))
                            }

                            if board.isAnchor(row: row, col: col) && !claimed.contains(coord) {
                                ctx.stroke(path, with: .color(theme.anchor), lineWidth: max(1, cell * 0.08))
                            }

                            // Ghost overlay tint.
                            if ghost.contains(coord) {
                                ctx.fill(path, with: .color((legal ? theme.ghostLegal : theme.ghostIllegal).opacity(0.55)))
                                ctx.stroke(path, with: .color(legal ? theme.ghostLegal : theme.ghostIllegal),
                                           lineWidth: max(1.5, cell * 0.1))
                            }
                        }
                    }
                }
                .frame(width: cell * CGFloat(rows), height: cell * CGFloat(rows))

                burstOverlay(cell: cell)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // Aim a few cells ABOVE the finger so the ghost stays
                        // visible while you drag (your fingertip isn't covering it).
                        let col = Int(value.location.x / cell)
                        let row = Int(value.location.y / cell) - Self.aimLift
                        vm.moveGhost(to: Coord(col, row))
                    }
                    .onEnded { _ in vm.placeGhost() }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func burstOverlay(cell: CGFloat) -> some View {
        if let burst = vm.lastBurst {
            let span = cell * 5
            TimelineView(.animation) { tl in
                BurstView(burst: burst, cell: cell, span: span, start: tl.date)
            }
            .id(burst.id)
            .allowsHitTesting(false)
        }
    }
}

/// One placement burst, driven by the Metal `hailstoneBurst` shader over ~0.7s.
private struct BurstView: View {
    let burst: HailstormViewModel.Burst
    let cell: CGFloat
    let span: CGFloat
    let start: Date

    @State private var began = Date()

    var body: some View {
        let elapsed = start.timeIntervalSince(began)
        let progress = min(1, elapsed / 0.7)
        Rectangle()
            .fill(Color.white.opacity(0.001))
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
