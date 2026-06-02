import Foundation

/// **Spiral** — the φ capstone. Pascal's anti-diagonals (cells where
/// `row + col == d`) sum to the Fibonacci numbers. You cover the **land cells of
/// the active diagonal**; completing it banks that Fibonacci value and the
/// active diagonal climbs outward — chasing ever-bigger golden sums up the
/// triangle. Solo, untimed; ends when you're stuck or every diagonal is done.
public struct SpiralSession: Sendable {
    public let board: PascalBoard
    public private(set) var claimed: Set<Coord> = []
    public private(set) var current: Pentomino
    public private(set) var score: Int = 0
    public private(set) var activeDiagonal: Int = 0
    public private(set) var completedDiagonals: Int = 0
    public private(set) var placements: Int = 0
    private let fib: [Int]
    private var bag: PentominoBag

    public var maxDiagonal: Int { 2 * (board.rows - 1) }

    public init(rows: Int = 12, seed: UInt64 = 0x5EED) {
        self.board = PascalBoard(rows: rows)
        self.fib = Fibonacci.sequence(count: 2 * rows + 2)
        var bag = PentominoBag(seed: seed)
        self.current = bag.next()
        self.bag = bag
        self.activeDiagonal = 0
        advancePastDone()
    }

    public func nextPieces(_ count: Int = 3) -> [Pentomino] { bag.peek(count) }

    /// Land cells on anti-diagonal `d` (`row + col == d`), in the triangle.
    public func landOnDiagonal(_ d: Int) -> [Coord] {
        var out: [Coord] = []
        for row in 0..<board.rows {
            let col = d - row
            if col >= 0, board.isLand(row: row, col: col) { out.append(Coord(col, row)) }
        }
        return out
    }

    private func diagonalComplete(_ d: Int) -> Bool {
        let land = landOnDiagonal(d)
        return !land.isEmpty && land.allSatisfy { claimed.contains($0) }
    }

    /// The active diagonal's target land cells (for the UI highlight).
    public func targetCells() -> [Coord] { landOnDiagonal(activeDiagonal) }

    /// The Fibonacci value the active diagonal is worth.
    public var fibTarget: Int { activeDiagonal < fib.count ? fib[activeDiagonal] : 0 }

    public func cells(orientationIndex: Int, at origin: Coord) -> [Coord] {
        let all = current.orientations
        let idx = ((orientationIndex % all.count) + all.count) % all.count
        return all[idx].cells.map { $0 + origin }
    }

    public func canPlace(orientationIndex: Int, at origin: Coord) -> Bool {
        cells(orientationIndex: orientationIndex, at: origin).allSatisfy { c in
            board.contains(row: c.y, col: c.x) && !claimed.contains(c)
        }
    }

    @discardableResult
    public mutating func place(orientationIndex: Int, at origin: Coord) -> Bool {
        guard canPlace(orientationIndex: orientationIndex, at: origin) else { return false }
        for c in cells(orientationIndex: orientationIndex, at: origin) { claimed.insert(c) }
        placements += 1
        advancePastDone()
        current = bag.next()
        return true
    }

    /// Skip empty diagonals and score completed ones, stopping at the first
    /// land-bearing diagonal that isn't finished yet.
    private mutating func advancePastDone() {
        while activeDiagonal <= maxDiagonal {
            let land = landOnDiagonal(activeDiagonal)
            if land.isEmpty { activeDiagonal += 1; continue }
            if land.allSatisfy({ claimed.contains($0) }) {
                score += activeDiagonal < fib.count ? fib[activeDiagonal] : 0
                completedDiagonals += 1
                activeDiagonal += 1
                continue
            }
            break
        }
    }

    public func firstValidPlacement() -> (orientationIndex: Int, origin: Coord)? {
        let orientCount = current.orientations.count
        for row in 0..<board.rows {
            for col in 0...row {
                for oi in 0..<orientCount where canPlace(orientationIndex: oi, at: Coord(col, row)) {
                    return (oi, Coord(col, row))
                }
            }
        }
        return nil
    }

    /// Over when every diagonal is done, or the current piece can't be placed.
    public var isOver: Bool { activeDiagonal > maxDiagonal || firstValidPlacement() == nil }
}
