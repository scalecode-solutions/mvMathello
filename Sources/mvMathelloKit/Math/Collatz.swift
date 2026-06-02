import Foundation

/// The Collatz (3n+1) engine — the transform half of Mathello. Parity drives
/// everything: even halves (a bit-shift), odd triples-plus-one.
public enum Collatz {

    /// One Collatz step. `n` must be a positive integer.
    public static func step(_ n: Int) -> Int {
        n % 2 == 0 ? n / 2 : 3 * n + 1
    }

    /// Whether `b` is the immediate Collatz successor of `a` — the validity
    /// rule for a "chain" of cells.
    public static func isSuccessor(_ a: Int, _ b: Int) -> Bool {
        a >= 1 && step(a) == b
    }

    /// Total stopping time: steps to reach 1 (0 for n <= 1). Used as the score
    /// weight of a cell in arcade mode (longer hailstone = bigger payoff).
    public static func stoppingTime(_ n: Int) -> Int {
        guard n > 1 else { return 0 }
        var value = n
        var steps = 0
        while value != 1 {
            value = step(value)
            steps += 1
        }
        return steps
    }

    /// The full hailstone trajectory `[n, …, 1]` (just `[n]` for n <= 1).
    public static func trajectory(_ n: Int) -> [Int] {
        guard n > 1 else { return [n] }
        var seq = [n]
        var value = n
        while value != 1 {
            value = step(value)
            seq.append(value)
        }
        return seq
    }

    /// Powers of two are the only safe slide to 1 — the board's "anchor" cells.
    public static func isPowerOfTwo(_ n: Int) -> Bool {
        n > 0 && (n & (n - 1)) == 0
    }
}
