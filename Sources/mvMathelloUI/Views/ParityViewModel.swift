import SwiftUI
import mvMathelloKit

/// Drives the two-player Parity board: whose turn, the ghost piece being aimed,
/// and placement. Turn-based, so there's no clock.
@MainActor
@Observable
public final class ParityViewModel {
    public private(set) var session: ParitySession
    public var ghostOrigin: Coord
    public private(set) var orientationIndex = 0
    public private(set) var lastBurst: BurstEvent?
    private var burstCounter = 0

    public init(rows: Int = 10, seed: UInt64 = 0x5EED) {
        let session = ParitySession(rows: rows, seed: seed)
        self.session = session
        self.ghostOrigin = Coord(0, min(rows - 1, max(2, rows / 2)))
    }

    public var ghostCells: [Coord] {
        session.cells(orientationIndex: orientationIndex, at: ghostOrigin)
    }
    public var ghostLegal: Bool {
        session.canPlace(orientationIndex: orientationIndex, at: ghostOrigin)
    }
    public var isOver: Bool { session.isOver }

    public func rotate() {
        orientationIndex += 1
        Haptics.play(.rotate)
    }

    public func moveGhost(to origin: Coord) { ghostOrigin = origin }

    public func placeGhost() {
        guard !session.isOver else { return }
        let land = session.landCovered(orientationIndex: orientationIndex, at: ghostOrigin)
        guard session.place(orientationIndex: orientationIndex, at: ghostOrigin) else {
            Haptics.play(.illegal)
            return
        }
        burstCounter += 1
        lastBurst = BurstEvent(center: centroid(of: land),
                               intensity: min(1.0, Double(land.count) / 5.0),
                               id: burstCounter)
        orientationIndex = 0
        Haptics.play(.place)
        if session.isOver { Haptics.play(.golden) }
    }

    public func newGame(seed: UInt64) {
        let rows = session.board.rows
        session = ParitySession(rows: rows, seed: seed)
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
