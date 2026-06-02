import SwiftUI
import mvMathelloKit

/// Fractal — the solo, untimed coverage puzzle. Blanket as much of the
/// Sierpiński land as you can; the game ends when your piece won't fit.
public struct FractalGameView: View {
    @Environment(\.mathelloTheme) private var theme
    @State private var vm: FractalViewModel
    private let embedded: Bool

    public init(rows: Int = 12, seed: UInt64 = 0x5EED, embedded: Bool = false) {
        _vm = State(initialValue: FractalViewModel(rows: rows, seed: seed))
        self.embedded = embedded
    }

    public var body: some View {
        VStack(spacing: 14) {
            if !embedded {
                Text("Mathello · Fractal")
                    .font(.title3.bold())
                    .foregroundStyle(theme.headlineColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            coverageHeader
            FractalBoardView(vm: vm)
                .padding(.vertical, 4)
            controls
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(theme.pageBackground.ignoresSafeArea())
        .overlay { if vm.isOver { gameOver } }
    }

    // MARK: - Coverage

    private var coverageHeader: some View {
        VStack(spacing: 6) {
            HStack {
                Text("COVERAGE").font(.caption2.weight(.semibold)).tracking(0.8)
                    .foregroundStyle(theme.bodyColor)
                Spacer()
                Text("\(Int((vm.session.coverage * 100).rounded()))%")
                    .font(.system(.title3, design: .rounded).weight(.heavy).monospacedDigit())
                    .foregroundStyle(theme.claimed)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(theme.bodyColor.opacity(0.15))
                    Capsule().fill(theme.claimed)
                        .frame(width: geo.size.width * CGFloat(vm.session.coverage))
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("PIECE").font(.caption2.weight(.semibold)).foregroundStyle(theme.bodyColor)
                piecePreview(vm.session.current, orientationIndex: vm.orientationIndex, cell: 9, color: theme.claimed)
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
                    .background(vm.ghostLegal ? theme.claimed : theme.hole,
                                in: RoundedRectangle(cornerRadius: 14))
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

    // MARK: - Game over

    private var gameOver: some View {
        VStack(spacing: 12) {
            Text("Stuck!").font(.largeTitle.bold()).foregroundStyle(theme.headlineColor)
            Text("\(Int((vm.session.coverage * 100).rounded()))% covered")
                .font(.title2).foregroundStyle(theme.claimed)
            Text("\(vm.session.placements) pieces").font(.subheadline).foregroundStyle(theme.bodyColor)
            Button {
                vm.newGame(seed: UInt64(Date().timeIntervalSince1970 * 1000))
            } label: {
                Text("New Game").font(.headline)
                    .padding(.horizontal, 28).frame(height: 48)
                    .background(theme.claimed, in: Capsule())
                    .foregroundStyle(theme.pageBackground)
            }
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
    }
}
