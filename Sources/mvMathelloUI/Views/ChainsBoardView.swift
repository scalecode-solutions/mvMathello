import SwiftUI
import mvMathelloKit

/// The Chains playfield: heat-mapped land (like Hailstorm) with the chain tail
/// highlighted in gold — touch it with your next piece to keep the ×φ multiplier
/// climbing. Drag to aim, lift to place.
struct ChainsBoardView: View {
    @Environment(\.mathelloTheme) private var theme
    let vm: ChainsViewModel

    private var board: PascalBoard { vm.session.board }
    private var rows: Int { board.rows }
    private static let aimLift = 3

    var body: some View {
        GeometryReader { geo in
            let cell = min(geo.size.width, geo.size.height) / CGFloat(rows)
            let claimed = vm.session.claimed
            let tail = Set(vm.session.chainTail)
            let ghost = Set(vm.ghostCells)
            let extends = vm.ghostExtends && vm.ghostLegal
            let ghostColor = !vm.ghostLegal ? theme.ghostIllegal : (extends ? theme.golden : theme.ghostLegal)

            ZStack(alignment: .topLeading) {
                Canvas { ctx, _ in
                    for row in 0..<rows {
                        for col in 0...row {
                            let coord = Coord(col, row)
                            let rect = CGRect(x: CGFloat(col) * cell + 1, y: CGFloat(row) * cell + 1,
                                              width: cell - 2, height: cell - 2)
                            let path = Path(roundedRect: rect, cornerRadius: cell * 0.2)

                            if claimed.contains(coord) {
                                let heat = vm.heat(row: row, col: col)
                                ctx.fill(path, with: .color(theme.landColor(heat: heat)))
                                // Chain tail glows gold — the piece to touch next.
                                if tail.contains(coord) {
                                    ctx.stroke(path, with: .color(theme.golden), lineWidth: max(1.5, cell * 0.12))
                                } else {
                                    ctx.stroke(path, with: .color(.white.opacity(0.25)), lineWidth: max(1, cell * 0.05))
                                }
                            } else if board.isLand(row: row, col: col) {
                                let heat = vm.heat(row: row, col: col)
                                let c = theme.landColor(heat: heat)
                                ctx.fill(path, with: .color(c.opacity(0.16)))
                                ctx.stroke(path, with: .color(c.opacity(0.9)),
                                           lineWidth: max(1, cell * 0.045 + heat * cell * 0.07))
                            } else {
                                ctx.fill(path, with: .color(theme.hole.opacity(0.55)))
                            }

                            if ghost.contains(coord) {
                                ctx.fill(path, with: .color(ghostColor.opacity(0.5)))
                                ctx.stroke(path, with: .color(ghostColor), lineWidth: max(1.5, cell * 0.12))
                            }
                        }
                    }
                }
                .frame(width: cell * CGFloat(rows), height: cell * CGFloat(rows))

                if let burst = vm.lastBurst {
                    TimelineView(.animation) { tl in
                        BurstView(burst: burst, cell: cell, span: cell * 5, start: tl.date, tint: theme.golden)
                    }
                    .id(burst.id)
                    .allowsHitTesting(false)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let col = Int(value.location.x / cell)
                        let row = Int(value.location.y / cell) - Self.aimLift
                        vm.moveGhost(to: Coord(col, row))
                    }
                    .onEnded { _ in vm.placeGhost() }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
