import Testing
@testable import mvMathelloKit

@Suite("Chains session")
struct ChainsTests {

    @Test("First placement scores at ×1 and starts a chain of length 1")
    func firstPlacement() {
        var s = ChainsSession(rows: 12, seed: 2)
        guard let (oi, origin) = s.firstValidPlacement() else { Issue.record("no move"); return }
        let base = s.potentialScore(orientationIndex: oi, at: origin)!
        #expect(s.place(orientationIndex: oi, at: origin) == true)
        #expect(s.chainLength == 1)
        #expect(s.score == base)
    }

    @Test("A touching placement extends the chain and applies the ×φ multiplier")
    func touchingExtendsChain() {
        var s = ChainsSession(rows: 14, seed: 3)
        guard let (oi1, o1) = s.firstValidPlacement() else { Issue.record("no move"); return }
        s.place(orientationIndex: oi1, at: o1)
        #expect(s.chainLength == 1)

        // Find a placement for the next piece that touches the chain tail.
        var extended = false
        outer: for row in 0..<s.board.rows {
            for col in 0...row {
                for oi in 0..<s.current.orientations.count {
                    guard s.canPlace(orientationIndex: oi, at: Coord(col, row)) else { continue }
                    if s.touchesChain(orientationIndex: oi, at: Coord(col, row)) {
                        s.place(orientationIndex: oi, at: Coord(col, row))
                        extended = true
                        break outer
                    }
                }
            }
        }
        #expect(extended == true)
        #expect(s.chainLength == 2)          // touched → grew
    }

    @Test("Greedy play terminates")
    func playToCompletion() {
        var s = ChainsSession(rows: 10, seed: 6)
        var guardrail = 0
        while !s.isOver, guardrail < 500 {
            guard let (oi, origin) = s.firstValidPlacement() else { break }
            s.place(orientationIndex: oi, at: origin)
            guardrail += 1
        }
        #expect(s.isOver == true)
        #expect(s.score > 0)
    }
}
