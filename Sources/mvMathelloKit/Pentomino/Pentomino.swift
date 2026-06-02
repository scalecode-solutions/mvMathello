import Foundation

/// The twelve free pentominoes, named by the letters they resemble.
/// Lifted from mvBlocks. (`Coord` y grows downward.)
public enum Pentomino: String, CaseIterable, Sendable, Codable, Identifiable, Hashable {
    case f, i, l, n, p, t, u, v, w, x, y, z

    public var id: String { rawValue }
    public var label: String { rawValue.uppercased() }

    public var isChiral: Bool {
        switch self {
        case .f, .l, .n, .p, .y, .z: true
        case .i, .t, .u, .v, .w, .x: false
        }
    }

    public var baseCells: [Coord] {
        switch self {
        case .f: [Coord(1, 0), Coord(2, 0), Coord(0, 1), Coord(1, 1), Coord(1, 2)]
        case .i: [Coord(0, 0), Coord(0, 1), Coord(0, 2), Coord(0, 3), Coord(0, 4)]
        case .l: [Coord(0, 0), Coord(0, 1), Coord(0, 2), Coord(0, 3), Coord(1, 3)]
        case .n: [Coord(1, 0), Coord(1, 1), Coord(0, 2), Coord(1, 2), Coord(0, 3)]
        case .p: [Coord(0, 0), Coord(1, 0), Coord(0, 1), Coord(1, 1), Coord(0, 2)]
        case .t: [Coord(0, 0), Coord(1, 0), Coord(2, 0), Coord(1, 1), Coord(1, 2)]
        case .u: [Coord(0, 0), Coord(2, 0), Coord(0, 1), Coord(1, 1), Coord(2, 1)]
        case .v: [Coord(0, 0), Coord(0, 1), Coord(0, 2), Coord(1, 2), Coord(2, 2)]
        case .w: [Coord(0, 0), Coord(0, 1), Coord(1, 1), Coord(1, 2), Coord(2, 2)]
        case .x: [Coord(1, 0), Coord(0, 1), Coord(1, 1), Coord(2, 1), Coord(1, 2)]
        case .y: [Coord(1, 0), Coord(0, 1), Coord(1, 1), Coord(1, 2), Coord(1, 3)]
        case .z: [Coord(0, 0), Coord(1, 0), Coord(1, 1), Coord(1, 2), Coord(2, 2)]
        }
    }

    /// All distinct fixed orientations. Counts: F8 I2 L8 N8 P8 T4 U4 V4 W4 X1 Y8 Z4 = 63.
    public var orientations: [Orientation] {
        Orientation.allFixed(of: baseCells)
    }
}
