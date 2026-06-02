import Testing
@testable import mvMathelloKit

@Suite("Spiral session")
struct SpiralTests {

    @Test("Active diagonal starts on a land-bearing diagonal with a Fibonacci target")
    func startState() {
        let s = SpiralSession(rows: 12, seed: 1)
        #expect(s.score == 0)
        #expect(s.targetCells().isEmpty == false)        // the active diagonal has land
        #expect(s.fibTarget >= 1)
        #expect(s.isOver == false)
    }

    @Test("Covering all of a diagonal's land completes it and banks its Fibonacci value")
    func completesDiagonal() {
        // Use the lowest diagonal that has more than one land cell so it's coverable.
        var s = SpiralSession(rows: 12, seed: 5)
        let startScore = s.score
        // Greedily play; over a full game at least one diagonal must complete.
        var guardrail = 0, completedSeen = false
        while !s.isOver, guardrail < 800 {
            guard let (oi, origin) = s.firstValidPlacement() else { break }
            let before = s.completedDiagonals
            s.place(orientationIndex: oi, at: origin)
            if s.completedDiagonals > before { completedSeen = true }
            guardrail += 1
        }
        #expect(completedSeen == true)
        #expect(s.score > startScore)
    }

    @Test("Placements never overlap")
    func noOverlap() {
        var s = SpiralSession(rows: 12, seed: 3)
        for _ in 0..<6 {
            guard let (oi, origin) = s.firstValidPlacement() else { break }
            s.place(orientationIndex: oi, at: origin)
        }
        #expect(s.claimed.count == s.placements * 5)
    }

    @Test("Greedy play terminates")
    func playToCompletion() {
        var s = SpiralSession(rows: 10, seed: 7)
        var guardrail = 0
        while !s.isOver, guardrail < 800 {
            guard let (oi, origin) = s.firstValidPlacement() else { break }
            s.place(orientationIndex: oi, at: origin)
            guardrail += 1
        }
        #expect(s.isOver == true)
    }
}
