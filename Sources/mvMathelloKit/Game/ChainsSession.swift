import Foundation

/// **Chains** — the solo combo mode. Place pentominoes on the board (scored by
/// the Collatz stopping-times of the land cells they cover, like Hailstorm) and
/// keep the chain alive: if a new piece **touches** the previous one
/// (orthogonally adjacent), the chain length grows and the score multiplier
/// climbs **×φ per link**; place away from the chain and it resets to ×1.
///
/// (The literal "five cells forming a Collatz chain" is infeasible on Pascal's
/// values, so the chain is *spatial* — snake one long connected run — while
/// Collatz drives the per-piece score and φ drives the multiplier.)
public struct ChainsSession: Sendable {
    public let board: PascalBoard
    public private(set) var claimed: Set<Coord> = []
    public private(set) var current: Pentomino
    public private(set) var score: Int = 0
    /// Current run of consecutive touching placements (0 before the first piece).
    public private(set) var chainLength: Int = 0
    public private(set) var placements: Int = 0
    private var lastCells: [Coord] = []
    private var bag: PentominoBag

    public init(rows: Int = 12, seed: UInt64 = 0x5EED) {
        self.board = PascalBoard(rows: rows)
        var bag = PentominoBag(seed: seed)
        self.current = bag.next()
        self.bag = bag
    }

    public func nextPieces(_ count: Int = 3) -> [Pentomino] { bag.peek(count) }

    /// The previous placement's cells — the tail you must touch to extend.
    public var chainTail: [Coord] { lastCells }

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

    /// Whether a candidate placement touches the current chain tail.
    public func touchesChain(orientationIndex: Int, at origin: Coord) -> Bool {
        guard !lastCells.isEmpty else { return false }
        let cs = cells(orientationIndex: orientationIndex, at: origin)
        return cs.contains { c in
            lastCells.contains { abs($0.x - c.x) + abs($0.y - c.y) == 1 }
        }
    }

    private func baseScore(_ cs: [Coord]) -> Int {
        cs.reduce(0) { sum, c in
            board.isLand(row: c.y, col: c.x)
                ? sum + Collatz.stoppingTime(board.value(row: c.y, col: c.x) ?? 0)
                : sum
        }
    }

    /// Points a placement would bank now (Collatz base × the would-be ×φ multiplier).
    public func potentialScore(orientationIndex: Int, at origin: Coord) -> Int? {
        guard canPlace(orientationIndex: orientationIndex, at: origin) else { return nil }
        let cs = cells(orientationIndex: orientationIndex, at: origin)
        let nextLength = touchesChain(orientationIndex: orientationIndex, at: origin) ? chainLength + 1 : 1
        return Int((Double(baseScore(cs)) * Foundation.pow(Fibonacci.phi, Double(nextLength - 1))).rounded())
    }

    @discardableResult
    public mutating func place(orientationIndex: Int, at origin: Coord) -> Bool {
        guard canPlace(orientationIndex: orientationIndex, at: origin) else { return false }
        let cs = cells(orientationIndex: orientationIndex, at: origin)
        chainLength = touchesChain(orientationIndex: orientationIndex, at: origin) ? chainLength + 1 : 1
        score += Int((Double(baseScore(cs)) * Foundation.pow(Fibonacci.phi, Double(chainLength - 1))).rounded())
        for c in cs { claimed.insert(c) }
        lastCells = cs
        placements += 1
        current = bag.next()
        return true
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

    public var isOver: Bool { firstValidPlacement() == nil }
}
