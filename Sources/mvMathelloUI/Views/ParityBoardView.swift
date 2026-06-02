import SwiftUI
import mvMathelloKit

/// The Parity playfield: the Sierpiński triangle with two-color territory. Drag
/// a ghost pentomino (in the current player's color) to aim, lift to place.
struct ParityBoardView: View {
    @Environment(\.mathelloTheme) private var theme
    let vm: ParityViewModel

    private var board: PascalBoard { vm.session.board }
    private var rows: Int { board.rows }
    private static let aimLift = 3

    var body: some View {
        GeometryReader { geo in
            let cell = min(geo.size.width, geo.size.height) / CGFloat(rows)
            let ghost = Set(vm.ghostCells)
            let legal = vm.ghostLegal
            let turnColor = theme.color(for: vm.session.current)

            ZStack(alignment: .topLeading) {
            Canvas { ctx, _ in
                for row in 0..<rows {
                    for col in 0...row {
                        let coord = Coord(col, row)
                        let rect = CGRect(x: CGFloat(col) * cell + 1, y: CGFloat(row) * cell + 1,
                                          width: cell - 2, height: cell - 2)
                        let path = Path(roundedRect: rect, cornerRadius: cell * 0.2)

                        if let player = vm.session.owner[coord] {
                            ctx.fill(path, with: .color(theme.color(for: player)))    // territory
                        } else if board.isLand(row: row, col: col) {
                            ctx.fill(path, with: .color(theme.bodyColor.opacity(0.14))) // open land
                            ctx.stroke(path, with: .color(theme.bodyColor.opacity(0.4)), lineWidth: 1)
                        } else {
                            ctx.fill(path, with: .color(theme.hole.opacity(0.55)))      // hole
                        }

                        if ghost.contains(coord) {
                            let c = legal ? turnColor : theme.ghostIllegal
                            ctx.fill(path, with: .color(c.opacity(0.5)))
                            ctx.stroke(path, with: .color(c), lineWidth: max(1.5, cell * 0.12))
                        }
                    }
                }
            }
            .frame(width: cell * CGFloat(rows), height: cell * CGFloat(rows))

                if let burst = vm.lastBurst {
                    TimelineView(.animation) { tl in
                        // Tint with the player who just placed (turn already passed).
                        BurstView(burst: burst, cell: cell, span: cell * 5, start: tl.date,
                                  tint: theme.color(for: vm.session.current.other))
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
