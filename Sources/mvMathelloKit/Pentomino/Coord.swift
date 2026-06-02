import Foundation

// Lifted from mvBlocks (the pentomino engine is stable, tested, and shared by
// design). If a third consumer ever appears, extract a `mvPentomino` package.

/// An integer grid coordinate. `x` increases to the right, `y` increases
/// downward (screen/board convention).
public struct Coord: Hashable, Sendable, Codable, Comparable {
    public var x: Int
    public var y: Int

    public init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }

    public static func + (lhs: Coord, rhs: Coord) -> Coord {
        Coord(lhs.x + rhs.x, lhs.y + rhs.y)
    }

    public static func - (lhs: Coord, rhs: Coord) -> Coord {
        Coord(lhs.x - rhs.x, lhs.y - rhs.y)
    }

    public static func < (lhs: Coord, rhs: Coord) -> Bool {
        (lhs.y, lhs.x) < (rhs.y, rhs.x)
    }
}
