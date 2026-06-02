import Foundation

/// The Mathello board: Pascal's triangle, **left-aligned onto a square grid** so
/// square pentominoes tile it. Cell `(row, col)` holds the binomial coefficient
/// `C(row, col)` for `0 <= col <= row`; cells with `col > row` are off the
/// triangle.
///
/// Parity is the geometry: **odd cells are land, even cells are holes** — the
/// lit (odd) cells form the Sierpiński triangle (Pascal mod 2 = Rule 90 / XOR).
///
/// Values are built additively (`C(n,k) = C(n-1,k-1) + C(n-1,k)`); keep `rows`
/// modest (≲ 30) so the coefficients stay inside `Int`.
public struct PascalBoard: Sendable {
    public let rows: Int
    /// `values[row]` has `row + 1` entries: `C(row, 0) ... C(row, row)`.
    public let values: [[Int]]

    public init(rows: Int) {
        precondition(rows >= 1, "PascalBoard needs at least one row")
        self.rows = rows
        var table: [[Int]] = []
        for n in 0..<rows {
            if n == 0 {
                table.append([1])
            } else {
                let prev = table[n - 1]
                var row = [1]
                for k in 1..<n {
                    row.append(prev[k - 1] + prev[k])
                }
                row.append(1)
                table.append(row)
            }
        }
        self.values = table
    }

    /// True if `(row, col)` is inside the triangle.
    public func contains(row: Int, col: Int) -> Bool {
        row >= 0 && row < rows && col >= 0 && col <= row
    }

    /// The binomial coefficient at `(row, col)`, or nil if off the triangle.
    public func value(row: Int, col: Int) -> Int? {
        guard contains(row: row, col: col) else { return nil }
        return values[row][col]
    }

    /// Land (odd cell) = part of the Sierpiński fractal; placeable.
    public func isLand(row: Int, col: Int) -> Bool {
        guard let v = value(row: row, col: col) else { return false }
        return v % 2 == 1
    }

    /// A power-of-two cell — both a Pascal landmark and Collatz's safe slide.
    public func isAnchor(row: Int, col: Int) -> Bool {
        guard let v = value(row: row, col: col) else { return false }
        return v > 0 && (v & (v - 1)) == 0
    }

    /// Total land (odd) cells — the tiling target for Fractal mode.
    public var landCount: Int {
        var n = 0
        for row in values { for v in row where v % 2 == 1 { n += 1 } }
        return n
    }
}
