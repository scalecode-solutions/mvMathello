import Foundation

/// One concrete placement-shape of a piece: a normalized, canonically-ordered
/// set of five cells. Lifted from mvBlocks.
public struct Orientation: Hashable, Sendable, Codable {
    public let cells: [Coord]

    public init(_ cells: [Coord]) {
        self.cells = Orientation.normalize(cells)
    }

    public var width: Int { (cells.map(\.x).max() ?? -1) + 1 }
    public var height: Int { (cells.map(\.y).max() ?? -1) + 1 }

    static func rotateCW(_ cells: [Coord]) -> [Coord] {
        cells.map { Coord(-$0.y, $0.x) }
    }

    static func reflect(_ cells: [Coord]) -> [Coord] {
        cells.map { Coord(-$0.x, $0.y) }
    }

    static func normalize(_ cells: [Coord]) -> [Coord] {
        guard let minX = cells.map(\.x).min(), let minY = cells.map(\.y).min() else {
            return []
        }
        return cells.map { Coord($0.x - minX, $0.y - minY) }.sorted()
    }

    static func allFixed(of base: [Coord]) -> [Orientation] {
        var seen = Set<[Coord]>()
        var result: [Orientation] = []
        for start in [base, reflect(base)] {
            var current = start
            for _ in 0..<4 {
                let normalized = normalize(current)
                if seen.insert(normalized).inserted {
                    result.append(Orientation(normalized))
                }
                current = rotateCW(current)
            }
        }
        return result
    }
}
