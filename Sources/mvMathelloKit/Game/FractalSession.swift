import Foundation

/// **Fractal** — the solo, untimed coverage puzzle. Place non-overlapping
/// pentominoes to blanket as much of the Sierpiński **land** (odd cells) as you
/// can. Pieces may cover holes (those just waste cells), so the skill is
/// packing the holey fractal efficiently. Exact tiling is impossible, so the
/// goal is a coverage percentage; the game ends when the current piece can't be
/// placed anywhere.
///
/// Pure and deterministic given a seed.
public struct FractalSession: Sendable {
    public let board: PascalBoard
    /// Every covered cell (land or hole), as `Coord(x: col, y: row)`.
    public private(set) var claimed: Set<Coord> = []
    public private(set) var current: Pentomino
    public private(set) var placements: Int = 0
    private var bag: PentominoBag

    public init(rows: Int = 12, seed: UInt64 = 0x5EED) {
        self.board = PascalBoard(rows: rows)
        var bag = PentominoBag(seed: seed)
        self.current = bag.next()
        self.bag = bag
    }

    public func nextPieces(_ count: Int = 3) -> [Pentomino] { bag.peek(count) }

    public func cells(orientationIndex: Int, at origin: Coord) -> [Coord] {
        let all = current.orientations
        let idx = ((orientationIndex % all.count) + all.count) % all.count
        return all[idx].cells.map { $0 + origin }
    }

    /// Legal iff every covered cell is in the triangle and unclaimed (no overlap).
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
        current = bag.next()
        return true
    }

    /// Land (odd) cells covered so far.
    public var landCovered: Int {
        claimed.filter { board.isLand(row: $0.y, col: $0.x) }.count
    }

    /// Fraction of the board's land that's covered, 0...1.
    public var coverage: Double {
        board.landCount == 0 ? 0 : Double(landCovered) / Double(board.landCount)
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

    /// Over when the current piece can't be placed anywhere.
    public var isOver: Bool { firstValidPlacement() == nil }
}
