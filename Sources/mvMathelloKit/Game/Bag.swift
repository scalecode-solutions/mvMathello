import Foundation

/// Deterministic PRNG (SplitMix64) so the piece bag is reproducible from a seed.
/// Lifted from mvBlocks.
public struct SeededGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64
    public init(seed: UInt64) { self.state = seed }
    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// A "12-bag" of pentominoes: shuffle all twelve, deal, reshuffle — bounded
/// droughts. Non-mutating `peek` for preview queues.
public struct PentominoBag: Sendable {
    private var rng: SeededGenerator
    private var queue: [Pentomino] = []

    public init(seed: UInt64) {
        self.rng = SeededGenerator(seed: seed)
        refill()
    }

    private mutating func refill() {
        queue = Pentomino.allCases.shuffled(using: &rng)
    }

    public mutating func next() -> Pentomino {
        if queue.isEmpty { refill() }
        return queue.removeFirst()
    }

    public func peek(_ count: Int) -> [Pentomino] {
        var lookahead = queue
        var generator = rng
        while lookahead.count < count {
            lookahead.append(contentsOf: Pentomino.allCases.shuffled(using: &generator))
        }
        return Array(lookahead.prefix(count))
    }
}
