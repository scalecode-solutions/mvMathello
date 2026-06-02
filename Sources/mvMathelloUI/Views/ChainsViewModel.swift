import SwiftUI
import mvMathelloKit

/// Drives the solo Chains combo puzzle: ghost aiming, placement, the ×φ chain,
/// and the capture burst. Untimed.
@MainActor
@Observable
public final class ChainsViewModel {
    public private(set) var session: ChainsSession
    public var ghostOrigin: Coord
    public private(set) var orientationIndex = 0
    public private(set) var lastBurst: BurstEvent?
    public let maxStoppingTime: Int
    private var burstCounter = 0

    public init(rows: Int = 12, seed: UInt64 = 0x5EED) {
        let session = ChainsSession(rows: rows, seed: seed)
        self.session = session
        self.ghostOrigin = Coord(0, min(rows - 1, max(2, rows / 2)))
        var m = 1
        for r in 0..<session.board.rows {
            for c in 0...r where session.board.isLand(row: r, col: c) {
                m = max(m, Collatz.stoppingTime(session.board.value(row: r, col: c) ?? 0))
            }
        }
        self.maxStoppingTime = m
    }

    public var ghostCells: [Coord] { session.cells(orientationIndex: orientationIndex, at: ghostOrigin) }
    public var ghostLegal: Bool { session.canPlace(orientationIndex: orientationIndex, at: ghostOrigin) }
    public var ghostScore: Int? { session.potentialScore(orientationIndex: orientationIndex, at: ghostOrigin) }
    /// Whether the current aim would extend the chain (touches the tail).
    public var ghostExtends: Bool { session.touchesChain(orientationIndex: orientationIndex, at: ghostOrigin) }
    public var isOver: Bool { session.isOver }
    public var multiplier: Double { Foundation.pow(Fibonacci.phi, Double(max(0, session.chainLength - 1))) }

    public func heat(row: Int, col: Int) -> Double {
        guard session.board.isLand(row: row, col: col),
              let v = session.board.value(row: row, col: col) else { return 0 }
        return Double(Collatz.stoppingTime(v)) / Double(maxStoppingTime)
    }

    public func rotate() { orientationIndex += 1; Haptics.play(.rotate) }
    public func moveGhost(to origin: Coord) { ghostOrigin = origin }

    public func placeGhost() {
        guard !session.isOver else { return }
        let cells = session.cells(orientationIndex: orientationIndex, at: ghostOrigin)
        let extended = session.touchesChain(orientationIndex: orientationIndex, at: ghostOrigin)
        guard session.place(orientationIndex: orientationIndex, at: ghostOrigin) else {
            Haptics.play(.illegal)
            return
        }
        burstCounter += 1
        lastBurst = BurstEvent(center: centroid(of: cells),
                               intensity: min(1.0, Double(session.chainLength) / 6.0),
                               id: burstCounter)
        orientationIndex = 0
        Haptics.play(extended && session.chainLength >= 3 ? .bigScore : .place)
        if session.isOver { Haptics.play(.gameOver) }
    }

    public func newGame(seed: UInt64) {
        session = ChainsSession(rows: session.board.rows, seed: seed)
        orientationIndex = 0
        lastBurst = nil
    }

    private func centroid(of cells: [Coord]) -> Coord {
        guard !cells.isEmpty else { return ghostOrigin }
        let sx = cells.map(\.x).reduce(0, +)
        let sy = cells.map(\.y).reduce(0, +)
        return Coord(Int((Double(sx) / Double(cells.count)).rounded()),
                     Int((Double(sy) / Double(cells.count)).rounded()))
    }
}
