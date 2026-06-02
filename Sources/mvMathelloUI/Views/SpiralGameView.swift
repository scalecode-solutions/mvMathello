import SwiftUI
import mvMathelloKit

/// Spiral — the φ capstone. Cover each anti-diagonal's land to bank its
/// Fibonacci value; the active diagonal climbs outward up the triangle.
public struct SpiralGameView: View {
    @Environment(\.mathelloTheme) private var theme
    @State private var vm: SpiralViewModel
    private let embedded: Bool

    public init(rows: Int = 12, seed: UInt64 = 0x5EED, embedded: Bool = false) {
        _vm = State(initialValue: SpiralViewModel(rows: rows, seed: seed))
        self.embedded = embedded
    }

    public var body: some View {
        VStack(spacing: 14) {
            if !embedded {
                Text("Mathello · Spiral")
                    .font(.title3.bold())
                    .foregroundStyle(theme.headlineColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            statusBar
            SpiralBoardView(vm: vm)
                .padding(.vertical, 4)
            targetReadout
            controls
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(theme.pageBackground.ignoresSafeArea())
        .overlay { if vm.isOver { gameOver } }
    }

    private var statusBar: some View {
        HStack {
            stat("SCORE", "\(vm.session.score)", theme.golden)
            Spacer()
            stat("DIAGONAL", "\(vm.session.activeDiagonal)", theme.headlineColor)
            Spacer()
            stat("DONE", "\(vm.session.completedDiagonals)", theme.headlineColor)
        }
    }

    private func stat(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.caption2.weight(.semibold)).tracking(0.8).foregroundStyle(theme.bodyColor)
            Text(value).font(.system(.title3, design: .rounded).weight(.heavy).monospacedDigit())
                .foregroundStyle(color)
        }
    }

    private var targetReadout: some View {
        Text("cover the gold diagonal  ·  worth \(vm.session.fibTarget)")
            .font(.subheadline.weight(.bold).monospacedDigit())
            .foregroundStyle(theme.golden)
            .frame(height: 18)
    }

    private var controls: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("PIECE").font(.caption2.weight(.semibold)).foregroundStyle(theme.bodyColor)
                piecePreview(vm.session.current, orientationIndex: vm.orientationIndex, cell: 9, color: theme.golden)
                    .frame(width: 50, height: 50)
                    .background(theme.hole, in: RoundedRectangle(cornerRadius: 10))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("NEXT").font(.caption2.weight(.semibold)).foregroundStyle(theme.bodyColor)
                HStack(spacing: 8) {
                    ForEach(Array(vm.session.nextPieces(3).enumerated()), id: \.offset) { _, p in
                        piecePreview(p, orientationIndex: 0, cell: 5, color: theme.bodyColor)
                    }
                }
            }
            Spacer()
            Button { vm.rotate() } label: {
                Image(systemName: "rotate.right.fill").font(.title2)
                    .frame(width: 52, height: 52)
                    .background(theme.hole, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(theme.headlineColor)
            }
            Button { vm.placeGhost() } label: {
                Image(systemName: "checkmark.circle.fill").font(.title2)
                    .frame(width: 52, height: 52)
                    .background(vm.ghostLegal ? theme.golden : theme.hole, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(vm.ghostLegal ? theme.pageBackground : theme.bodyColor)
            }
            .disabled(!vm.ghostLegal)
        }
    }

    private func piecePreview(_ piece: Pentomino, orientationIndex: Int, cell: CGFloat, color: Color) -> some View {
        let all = piece.orientations
        let o = all[((orientationIndex % all.count) + all.count) % all.count]
        return Canvas { ctx, _ in
            for c in o.cells {
                let rect = CGRect(x: CGFloat(c.x) * cell + 1, y: CGFloat(c.y) * cell + 1,
                                  width: cell - 2, height: cell - 2)
                ctx.fill(Path(roundedRect: rect, cornerRadius: cell * 0.2), with: .color(color))
            }
        }
        .frame(width: CGFloat(o.width) * cell, height: CGFloat(o.height) * cell)
    }

    private var gameOver: some View {
        VStack(spacing: 12) {
            Text("Spiral Complete").font(.title.bold()).foregroundStyle(theme.headlineColor)
            Text("Score \(vm.session.score)").font(.title2).foregroundStyle(theme.golden)
            Text("\(vm.session.completedDiagonals) diagonals").font(.subheadline).foregroundStyle(theme.bodyColor)
            Button {
                vm.newGame(seed: UInt64(Date().timeIntervalSince1970 * 1000))
            } label: {
                Text("New Game").font(.headline)
                    .padding(.horizontal, 28).frame(height: 48)
                    .background(theme.golden, in: Capsule())
                    .foregroundStyle(theme.pageBackground)
            }
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
    }
}
