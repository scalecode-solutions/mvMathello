import SwiftUI
import mvMathelloKit

/// The Spiral playfield: covered cells fill in, and the **active diagonal**
/// glows gold — cover its land to bank the Fibonacci value and climb outward.
struct SpiralBoardView: View {
    @Environment(\.mathelloTheme) private var theme
    let vm: SpiralViewModel

    private var board: PascalBoard { vm.session.board }
    private var rows: Int { board.rows }
    private static let aimLift = 3

    var body: some View {
        GeometryReader { geo in
            let cell = min(geo.size.width, geo.size.height) / CGFloat(rows)
            let claimed = vm.session.claimed
            let target = Set(vm.session.targetCells())
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
                                ctx.fill(path, with: .color(land ? theme.claimed : theme.claimed.opacity(0.3)))
                            } else if target.contains(coord) {
                                // Active diagonal's uncovered land — the target, glowing gold.
                                ctx.fill(path, with: .color(theme.golden.opacity(0.28)))
                                ctx.stroke(path, with: .color(theme.golden), lineWidth: max(1.5, cell * 0.12))
                            } else if land {
                                ctx.fill(path, with: .color(theme.bodyColor.opacity(0.12)))
                                ctx.stroke(path, with: .color(theme.bodyColor.opacity(0.4)), lineWidth: 1)
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
