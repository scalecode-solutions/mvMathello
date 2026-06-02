import Foundation

/// **Hailstorm** — the arcade mode. Stamp pentominoes onto the Pascal triangle:
/// a placement is legal when all five cells fall on **unclaimed cells inside the
/// triangle** (any parity). You score only the **land (odd) cells** covered —
/// the sum of their Collatz stopping-times — so the Sierpiński pattern is the
/// *scoring landscape* you aim for, not a hard placement constraint. (Requiring
/// all-land placement dead-ends constantly: rigid pentominoes rarely fit the
/// sparse fractal, and the X-pentomino essentially never does.) Deeper Pascal
/// values spawn wilder hailstones, so reaching into the board pays more, and a
/// φ-scaled combo rewards back-to-back placements.
///
/// Pure and deterministic given a seed; the countdown timer lives in the UI.
/// Board cells are addressed as `Coord(x: col, y: row)` so pentomino
/// orientation cells map straight on.
public struct HailstormSession: Sendable {
    public let board: PascalBoard
    /// Claimed land cells, as `Coord(x: col, y: row)`.
    public private(set) var claimed: Set<Coord> = []
    public private(set) var score: Int = 0
    public private(set) var placements: Int = 0
    /// Consecutive successful placements (drives the combo multiplier).
    public private(set) var combo: Int = 0
    public private(set) var current: Pentomino
    /// Two reserve slots. Tap an empty slot to park `current`; tap a filled slot
    /// to swap it back in. Lets you sit on awkward pieces and deploy good ones.
    public private(set) var holds: [Pentomino?] = [nil, nil]
    private var bag: PentominoBag

    public init(rows: Int = 12, seed: UInt64 = 0x5EED) {
        self.board = PascalBoard(rows: rows)
        var bag = PentominoBag(seed: seed)
        self.current = bag.next()
        self.bag = bag
    }

    /// Upcoming pieces for the preview queue.
    public func nextPieces(_ count: Int = 3) -> [Pentomino] {
        bag.peek(count)
    }

    /// Park or swap the current piece against reserve slot `slot` (0 or 1).
    /// Empty slot → stash `current` and draw the next; filled slot → swap.
    public mutating func toggleHold(slot: Int) {
        guard holds.indices.contains(slot) else { return }
        if let held = holds[slot] {
            let outgoing = current
            current = held
            holds[slot] = outgoing
        } else {
            holds[slot] = current
            current = bag.next()
        }
    }

    /// Absolute board cells for placing `current` at `origin` in `orientationIndex`.
    public func cells(orientationIndex: Int, at origin: Coord) -> [Coord] {
        let all = current.orientations
        let idx = ((orientationIndex % all.count) + all.count) % all.count
        return all[idx].cells.map { $0 + origin }
    }

    /// Legal iff every covered cell is unclaimed and inside the triangle.
    public func canPlace(orientationIndex: Int, at origin: Coord) -> Bool {
        cells(orientationIndex: orientationIndex, at: origin).allSatisfy { c in
            board.contains(row: c.y, col: c.x) && !claimed.contains(c)
        }
    }

    /// Points a placement would score right now (before combo), or nil if
    /// illegal. Only land (odd) cells contribute; holes score 0.
    public func potentialScore(orientationIndex: Int, at origin: Coord) -> Int? {
        guard canPlace(orientationIndex: orientationIndex, at: origin) else { return nil }
        return cells(orientationIndex: orientationIndex, at: origin).reduce(0) { sum, c in
            guard board.isLand(row: c.y, col: c.x) else { return sum }
            return sum + Collatz.stoppingTime(board.value(row: c.y, col: c.x) ?? 0)
        }
    }

    /// Combo multiplier: grows by φ per consecutive placement (1, ~1.6, ~2.6, …).
    public var comboMultiplier: Double {
        Foundation.pow(Fibonacci.phi, Double(combo))
    }

    /// Place `current`. Returns whether it succeeded; on success scores, claims
    /// the cells, advances the combo, and draws the next piece.
    @discardableResult
    public mutating func place(orientationIndex: Int, at origin: Coord) -> Bool {
        guard let base = potentialScore(orientationIndex: orientationIndex, at: origin) else {
            return false
        }
        for c in cells(orientationIndex: orientationIndex, at: origin) {
            claimed.insert(c)
        }
        score += Int((Double(base) * comboMultiplier).rounded())
        combo += 1
        placements += 1
        current = bag.next()
        return true
    }

    /// The first legal placement for the current piece, scanning the board —
    /// powers `hasAnyMove` and a UI hint/auto-place.
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

    /// Game-over check: no legal placement remains for the current piece.
    public var hasAnyMove: Bool {
        firstValidPlacement() != nil
    }
}
