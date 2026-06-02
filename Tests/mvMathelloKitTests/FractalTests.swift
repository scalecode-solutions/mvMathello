import Testing
@testable import mvMathelloKit

@Suite("Fractal session")
struct FractalTests {

    @Test("Fresh board: nothing covered, a move available")
    func startState() {
        let s = FractalSession(rows: 12, seed: 1)
        #expect(s.claimed.isEmpty)
        #expect(s.coverage == 0)
        #expect(s.isOver == false)
    }

    @Test("Placing claims five cells and raises coverage")
    func placeCovers() {
        var s = FractalSession(rows: 12, seed: 2)
        guard let (oi, origin) = s.firstValidPlacement() else { Issue.record("no move"); return }
        let landInPiece = s.cells(orientationIndex: oi, at: origin)
            .filter { s.board.isLand(row: $0.y, col: $0.x) }.count
        #expect(s.place(orientationIndex: oi, at: origin) == true)
        #expect(s.claimed.count == 5)
        #expect(s.landCovered == landInPiece)
        #expect(s.coverage > 0)
    }

    @Test("Placements never overlap")
    func noOverlap() {
        var s = FractalSession(rows: 14, seed: 5)
        for _ in 0..<8 {
            guard let (oi, origin) = s.firstValidPlacement() else { break }
            s.place(orientationIndex: oi, at: origin)
        }
        // Each placement added exactly 5 distinct cells.
        #expect(s.claimed.count == s.placements * 5)
    }

    @Test("Greedy play terminates with coverage in 0...1")
    func playToCompletion() {
        var s = FractalSession(rows: 10, seed: 7)
        var guardrail = 0
        while !s.isOver, guardrail < 500 {
            guard let (oi, origin) = s.firstValidPlacement() else { break }
            s.place(orientationIndex: oi, at: origin)
            guardrail += 1
        }
        #expect(s.isOver == true)
        #expect(s.coverage > 0 && s.coverage <= 1)
    }
}
