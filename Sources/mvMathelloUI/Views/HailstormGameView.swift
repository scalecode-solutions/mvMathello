import SwiftUI
import mvMathelloKit

/// Hailstorm — the arcade Mathello mode. Drag the ghost pentomino around the
/// Pascal/Sierpiński board to aim, lift to place; score the Collatz
/// stopping-times of the land (odd) cells you cover, with a φ-scaled combo.
///
/// Ships standalone and host-embedded (`embedded: true` hides the title row so
/// a NavigationStack's chrome wraps it — for Clingy's den later).
public struct HailstormGameView: View {
    @Environment(\.mathelloTheme) private var theme
    @State private var vm: HailstormViewModel
    private let embedded: Bool

    public init(rows: Int = 12, seed: UInt64 = 0x5EED, duration: Int = 90, embedded: Bool = false) {
        _vm = State(initialValue: HailstormViewModel(rows: rows, seed: seed, duration: duration))
        self.embedded = embedded
    }

    public var body: some View {
        VStack(spacing: 14) {
            if !embedded {
                Text("Mathello · Hailstorm")
                    .font(.title3.bold())
                    .foregroundStyle(theme.headlineColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            statusBar
            BoardView(vm: vm)
                .padding(.vertical, 4)
            legend
            controls
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(theme.pageBackground.ignoresSafeArea())
        .overlay { if vm.status == .over { gameOver } }
        .onAppear { vm.startIfNeeded() }
        .onDisappear { vm.teardown() }
    }

    // MARK: - Status

    private var statusBar: some View {
        HStack {
            stat("SCORE", "\(vm.session.score)")
            Spacer()
            stat("COMBO", "×\(vm.session.combo)")
            Spacer()
            stat("TIME", timeString)
                .foregroundStyle(vm.secondsRemaining <= 10 ? theme.ghostIllegal : theme.headlineColor)
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.caption2.weight(.semibold)).tracking(0.8)
                .foregroundStyle(theme.bodyColor)
            Text(value).font(.system(.title3, design: .rounded).weight(.heavy).monospacedDigit())
                .foregroundStyle(theme.headlineColor)
        }
    }

    private var timeString: String {
        let m = vm.secondsRemaining / 60, s = vm.secondsRemaining % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(swatch(filled: false), "points · brighter = more")
            legendItem(swatch(filled: true), "placed")
            legendItem(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(theme.anchor, lineWidth: 2)
                    .frame(width: 14, height: 14),
                "power of 2"
            )
            Spacer()
        }
        .font(.caption2)
        .foregroundStyle(theme.bodyColor)
    }

    private func legendItem(_ swatch: some View, _ label: String) -> some View {
        HStack(spacing: 5) { swatch; Text(label) }
    }

    private func swatch(filled: Bool) -> some View {
        let hot = theme.landHigh.color
        return RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(filled ? hot : hot.opacity(0.16))
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(filled ? Color.white.opacity(0.35) : hot.opacity(0.9), lineWidth: filled ? 1 : 2)
            )
            .frame(width: 14, height: 14)
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                trayGroup("HOLD") {
                    HStack(spacing: 6) { holdSlot(0); holdSlot(1) }
                }
                trayGroup("NOW") {
                    piecePreview(vm.session.current, orientationIndex: vm.orientationIndex, cell: 9, color: theme.golden)
                        .frame(width: 50, height: 50)
                        .background(theme.hole, in: RoundedRectangle(cornerRadius: 10))
                }
                trayGroup("NEXT") {
                    HStack(spacing: 8) {
                        ForEach(Array(vm.session.nextPieces(2).enumerated()), id: \.offset) { _, p in
                            piecePreview(p, orientationIndex: 0, cell: 5, color: theme.bodyColor)
                        }
                    }
                }
                Spacer()
            }

            HStack(spacing: 14) {
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
    }

    private func trayGroup<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption2.weight(.semibold)).foregroundStyle(theme.bodyColor)
            content()
        }
    }

    /// A reserve slot: shows its held piece, or a "+" when empty. Tap to park
    /// the current piece (empty slot) or swap it back in (filled slot).
    private func holdSlot(_ index: Int) -> some View {
        Button { vm.toggleHold(slot: index) } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(theme.hole)
                    .frame(width: 50, height: 50)
                if let piece = vm.holds[index] {
                    piecePreview(piece, orientationIndex: 0, cell: 7, color: theme.golden)
                } else {
                    Image(systemName: "plus").font(.headline).foregroundStyle(theme.bodyColor.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
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
        VStack(spacing: 14) {
            Text("Time!").font(.largeTitle.bold()).foregroundStyle(theme.headlineColor)
            Text("Score \(vm.session.score)").font(.title2).foregroundStyle(theme.golden)
            Text("\(vm.session.placements) placements").font(.subheadline).foregroundStyle(theme.bodyColor)
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
