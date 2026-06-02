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
        guard session.place(orientationIndex: orientationIndex, at: ghostOrigin) else {
            Haptics.play(.illegal)
            return
        }
        orientationIndex = 0
        Haptics.play(.place)
        if session.isOver { Haptics.play(.golden) }
    }

    public func newGame(seed: UInt64) {
        let rows = session.board.rows
        session = ParitySession(rows: rows, seed: seed)
        orientationIndex = 0
    }
}
