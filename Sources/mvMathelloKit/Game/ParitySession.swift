import Foundation

/// The two players in a Parity match.
public enum Player: String, Sendable, Hashable, Codable, CaseIterable {
    case one, two
    public var other: Player { self == .one ? .two : .one }
    public var label: String { self == .one ? "Player 1" : "Player 2" }
}

/// **Parity** — the two-player territory mode (Othello, but the board is the
/// Sierpiński triangle and pieces are pentominoes). Players alternate placing a
/// pentomino; the **land (odd) cells it covers become the player's color**, and
/// covering the opponent's cells **captures** them. Each placement must claim at
/// least one *unclaimed* land cell, so the board strictly fills and the game
/// ends; most land wins.
///
/// Pure and deterministic given a seed. Holes (even cells) are never territory.
public struct ParitySession: Sendable {
    public let board: PascalBoard
    /// Owner of each claimed land cell (`Coord(x: col, y: row)`).
    public private(set) var owner: [Coord: Player] = [:]
    public private(set) var current: Player = .one
    public private(set) var currentPiece: Pentomino
    private var bag: PentominoBag

    public init(rows: Int = 10, seed: UInt64 = 0x5EED) {
        self.board = PascalBoard(rows: rows)
        var bag = PentominoBag(seed: seed)
        self.currentPiece = bag.next()
        self.bag = bag
    }

    public func nextPieces(_ count: Int = 2) -> [Pentomino] { bag.peek(count) }

    /// Absolute cells for placing `currentPiece` at `origin` in `orientationIndex`.
    public func cells(orientationIndex: Int, at origin: Coord) -> [Coord] {
        let all = currentPiece.orientations
        let idx = ((orientationIndex % all.count) + all.count) % all.count
        return all[idx].cells.map { $0 + origin }
    }

    /// Covered cells that are land (odd) — the ones that become territory.
    public func landCovered(orientationIndex: Int, at origin: Coord) -> [Coord] {
        cells(orientationIndex: orientationIndex, at: origin)
            .filter { board.isLand(row: $0.y, col: $0.x) }
    }

    /// Legal iff every covered cell is in the triangle and at least one covered
    /// land cell is currently unclaimed.
    public func canPlace(orientationIndex: Int, at origin: Coord) -> Bool {
        let all = cells(orientationIndex: orientationIndex, at: origin)
        guard all.allSatisfy({ board.contains(row: $0.y, col: $0.x) }) else { return false }
        return landCovered(orientationIndex: orientationIndex, at: origin).contains { owner[$0] == nil }
    }

    /// Place for the current player: claim/capture covered land cells, then pass
    /// the turn and draw the next piece. Returns whether it succeeded.
    @discardableResult
    public mutating func place(orientationIndex: Int, at origin: Coord) -> Bool {
        guard canPlace(orientationIndex: orientationIndex, at: origin) else { return false }
        for c in landCovered(orientationIndex: orientationIndex, at: origin) {
            owner[c] = current
        }
        current = current.other
        currentPiece = bag.next()
        return true
    }

    public func score(_ player: Player) -> Int {
        owner.values.filter { $0 == player }.count
    }

    /// Unclaimed land cells remaining.
    public var unclaimedLand: Int { board.landCount - owner.count }

    /// First legal placement for the current piece, scanning the board.
    public func firstValidPlacement() -> (orientationIndex: Int, origin: Coord)? {
        let orientCount = currentPiece.orientations.count
        for row in 0..<board.rows {
            for col in 0...row {
                for oi in 0..<orientCount where canPlace(orientationIndex: oi, at: Coord(col, row)) {
                    return (oi, Coord(col, row))
                }
            }
        }
        return nil
    }

    /// Over when the land is fully claimed, or the current player can't move.
    public var isOver: Bool {
        unclaimedLand == 0 || firstValidPlacement() == nil
    }

    /// The leader once the game is over (nil while playing or on a tie).
    public var winner: Player? {
        guard isOver else { return nil }
        let s1 = score(.one), s2 = score(.two)
        return s1 == s2 ? nil : (s1 > s2 ? .one : .two)
    }
}
