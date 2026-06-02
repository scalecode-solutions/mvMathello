import Foundation

/// The Fibonacci / golden-ratio engine — the growth spine of Mathello. These
/// are the *other* structure hiding in Pascal's triangle: its shallow diagonals
/// sum to the Fibonacci numbers, whose ratios converge to φ.
public enum Fibonacci {

    /// The golden ratio, φ = (1 + √5) / 2 ≈ 1.618 — the scoring multiplier base.
    public static let phi = (1.0 + 5.0.squareRoot()) / 2.0

    /// Fibonacci numbers `1, 1, 2, 3, 5, …` up to `count` terms.
    public static func sequence(count: Int) -> [Int] {
        guard count > 0 else { return [] }
        var seq = [1]
        if count == 1 { return seq }
        seq.append(1)
        while seq.count < count {
            seq.append(seq[seq.count - 1] + seq[seq.count - 2])
        }
        return seq
    }

    /// Whether `n` is a Fibonacci number — the "golden target" test for a sum of
    /// claimed cells. (A positive integer is Fibonacci iff `5n²±4` is a perfect
    /// square.)
    public static func isFibonacci(_ n: Int) -> Bool {
        guard n >= 1 else { return false }
        return isPerfectSquare(5 * n * n + 4) || isPerfectSquare(5 * n * n - 4)
    }

    private static func isPerfectSquare(_ n: Int) -> Bool {
        guard n >= 0 else { return false }
        let r = Int(Double(n).squareRoot())
        for candidate in max(0, r - 1)...(r + 1) where candidate * candidate == n {
            return true
        }
        return false
    }

    /// The shallow diagonals of a Pascal board, each summed — these equal the
    /// Fibonacci sequence. Used both as a "receipt" and for diagonal scoring.
    public static func diagonalSums(of board: PascalBoard) -> [Int] {
        // Diagonal d collects C(d - k, k) for k = 0… while (d - k) >= k.
        (0..<board.rows).map { d in
            var sum = 0
            var k = 0
            while d - k >= k {
                if let v = board.value(row: d - k, col: k) { sum += v }
                k += 1
            }
            return sum
        }
    }
}
