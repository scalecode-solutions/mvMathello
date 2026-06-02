import SwiftUI
import mvMathelloKit

/// Parity — two-player territory Mathello (local pass-and-play). Players
/// alternate stamping pentominoes; land cells you cover become your color, and
/// covering the opponent captures. Most land when the board fills wins.
public struct ParityGameView: View {
    @Environment(\.mathelloTheme) private var theme
    @State private var vm: ParityViewModel
    private let embedded: Bool

    public init(rows: Int = 10, seed: UInt64 = 0x5EED, embedded: Bool = false) {
        _vm = State(initialValue: ParityViewModel(rows: rows, seed: seed))
        self.embedded = embedded
    }

    public var body: some View {
        VStack(spacing: 14) {
            scoreboard
            ParityBoardView(vm: vm)
                .padding(.vertical, 4)
            controls
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(theme.pageBackground.ignoresSafeArea())
        .overlay { if vm.isOver { gameOver } }
    }

    // MARK: - Scoreboard + turn

    private var scoreboard: some View {
        VStack(spacing: 8) {
            HStack {
                scoreChip(.one)
                Spacer()
                Text("MATHELLO")
                    .font(.caption.weight(.heavy)).tracking(1.5)
                    .foregroundStyle(theme.bodyColor)
                Spacer()
                scoreChip(.two)
            }
            Text("\(vm.session.current.label)'s turn")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.color(for: vm.session.current))
            territoryBar
        }
    }

    /// Live P1 / P2 / unclaimed split of the board's land.
    private var territoryBar: some View {
        let total = max(1, vm.session.board.landCount)
        let s1 = vm.session.score(.one)
        let s2 = vm.session.score(.two)
        return GeometryReader { geo in
            HStack(spacing: 0) {
                Rectangle().fill(theme.playerOne)
                    .frame(width: geo.size.width * CGFloat(s1) / CGFloat(total))
                Rectangle().fill(theme.playerTwo)
                    .frame(width: geo.size.width * CGFloat(s2) / CGFloat(total))
                Rectangle().fill(theme.bodyColor.opacity(0.15))
            }
        }
        .frame(height: 6)
        .clipShape(Capsule())
    }

    private func scoreChip(_ player: Player) -> some View {
        let active = vm.session.current == player
        return VStack(spacing: 2) {
            Text(player == .one ? "P1" : "P2")
                .font(.caption2.weight(.bold))
                .foregroundStyle(theme.color(for: player))
            Text("\(vm.session.score(player))")
                .font(.system(.title2, design: .rounded).weight(.heavy).monospacedDigit())
                .foregroundStyle(theme.headlineColor)
        }
        .padding(.horizontal, 14).padding(.vertical, 6)
        .background(theme.color(for: player).opacity(active ? 0.28 : 0.10),
                    in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(theme.color(for: player), lineWidth: active ? 2 : 0)
        )
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("PIECE").font(.caption2.weight(.semibold)).foregroundStyle(theme.bodyColor)
                piecePreview(vm.session.currentPiece, orientationIndex: vm.orientationIndex,
                             cell: 9, color: theme.color(for: vm.session.current))
                    .frame(width: 50, height: 50)
                    .background(theme.hole, in: RoundedRectangle(cornerRadius: 10))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("NEXT").font(.caption2.weight(.semibold)).foregroundStyle(theme.bodyColor)
                HStack(spacing: 8) {
                    ForEach(Array(vm.session.nextPieces(2).enumerated()), id: \.offset) { _, p in
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
                    .background(vm.ghostLegal ? theme.color(for: vm.session.current) : theme.hole,
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
            if let w = vm.session.winner {
                Text("\(w.label) wins!").font(.largeTitle.bold())
                    .foregroundStyle(theme.color(for: w))
            } else {
                Text("Tie!").font(.largeTitle.bold()).foregroundStyle(theme.headlineColor)
            }
            Text("\(vm.session.score(.one)) – \(vm.session.score(.two))")
                .font(.title2.monospacedDigit()).foregroundStyle(theme.bodyColor)
            Button {
                vm.newGame(seed: UInt64(Date().timeIntervalSince1970 * 1000))
            } label: {
                Text("New Game").font(.headline)
                    .padding(.horizontal, 28).frame(height: 48)
                    .background(theme.headlineColor, in: Capsule())
                    .foregroundStyle(theme.pageBackground)
            }
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
    }
}
