import SwiftUI
import mvMathelloKit

/// The Fractal playfield: blanket the Sierpiński land. Covered cells fill in;
/// open land shows as faint wells; holes recede. Drag to aim, lift to place.
struct FractalBoardView: View {
    @Environment(\.mathelloTheme) private var theme
    let vm: FractalViewModel

    private var board: PascalBoard { vm.session.board }
    private var rows: Int { board.rows }
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
                            let land = board.isLand(row: row, col: col)

                            if claimed.contains(coord) {
                                // Covered: land blankets bright, a covered hole reads dimmer.
                                ctx.fill(path, with: .color(land ? theme.claimed : theme.claimed.opacity(0.3)))
                            } else if land {
                                // Open land = faint cover-colored well, so the Sierpiński
                                // target you're blanketing is visible before you fill it.
                                ctx.fill(path, with: .color(theme.claimed.opacity(0.14)))
                                ctx.stroke(path, with: .color(theme.claimed.opacity(0.5)), lineWidth: 1)
                            } else {
                                ctx.fill(path, with: .color(theme.hole.opacity(0.4)))
                            }

                            if ghost.contains(coord) {
                                let c = legal ? theme.ghostLegal : theme.ghostIllegal
                                ctx.fill(path, with: .color(c.opacity(0.5)))
                                ctx.stroke(path, with: .color(c), lineWidth: max(1.5, cell * 0.12))
                            }
                        }
                    }
                }
                .frame(width: cell * CGFloat(rows), height: cell * CGFloat(rows))

                if let burst = vm.lastBurst {
                    TimelineView(.animation) { tl in
                        BurstView(burst: burst, cell: cell, span: cell * 5, start: tl.date)
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
