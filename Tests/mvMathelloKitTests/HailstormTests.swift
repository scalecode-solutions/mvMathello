import Testing
@testable import mvMathelloKit

@Suite("Hailstorm session")
struct HailstormTests {

    @Test("A fresh board has at least one legal placement")
    func hasOpeningMove() {
        let s = HailstormSession(rows: 12, seed: 7)
        #expect(s.hasAnyMove == true)
    }

    @Test("Placing claims five land cells and scores their stopping-times")
    func placeScores() {
        var s = HailstormSession(rows: 14, seed: 3)
        let move = s.firstValidPlacement()
        #expect(move != nil)
        let (oi, origin) = move!
        let cells = s.cells(orientationIndex: oi, at: origin)
        // Only land (odd) cells score.
        let expected = cells.reduce(0) { sum, c in
            s.board.isLand(row: c.y, col: c.x)
                ? sum + Collatz.stoppingTime(s.board.value(row: c.y, col: c.x) ?? 0)
                : sum
        }

        #expect(s.place(orientationIndex: oi, at: origin) == true)
        #expect(s.claimed.count == 5)
        #expect(s.placements == 1)
        // First placement: combo was 0, multiplier 1.0 → score == raw sum.
        #expect(s.score == expected)
    }

    @Test("Every claimed cell is inside the triangle")
    func claimedCellsInTriangle() {
        var s = HailstormSession(rows: 16, seed: 11)
        for _ in 0..<5 {
            guard let (oi, origin) = s.firstValidPlacement() else { break }
            s.place(orientationIndex: oi, at: origin)
        }
        for c in s.claimed {
            #expect(s.board.contains(row: c.y, col: c.x) == true)
        }
    }

    @Test("Placing on already-claimed cells is rejected")
    func noOverlap() {
        var s = HailstormSession(rows: 14, seed: 5)
        guard let (oi, origin) = s.firstValidPlacement() else { Issue.record("no move"); return }
        let cells = Set(s.cells(orientationIndex: oi, at: origin))
        #expect(s.place(orientationIndex: oi, at: origin) == true)
        // Any placement overlapping those cells must now be illegal for the new piece.
        for o2 in 0..<s.current.orientations.count {
            for row in 0..<s.board.rows {
                for col in 0...row {
                    let candidate = s.cells(orientationIndex: o2, at: Coord(col, row))
                    if !Set(candidate).isDisjoint(with: cells) {
                        #expect(s.canPlace(orientationIndex: o2, at: Coord(col, row)) == false)
                    }
                }
            }
        }
    }

    @Test("Hold parks the current piece into an empty slot, then swaps it back")
    func holdParkAndSwap() {
        var s = HailstormSession(rows: 12, seed: 4)
        let first = s.current
        s.toggleHold(slot: 0)               // park `first`
        #expect(s.holds[0] == first)
        let second = s.current              // drawn from the bag, distinct within a 12-bag
        #expect(second != first)
        s.toggleHold(slot: 0)               // swap `first` back in
        #expect(s.current == first)
        #expect(s.holds[0] == second)
    }

    @Test("Combo multiplier grows by φ per placement")
    func comboGrowsByPhi() {
        var s = HailstormSession(rows: 16, seed: 2)
        #expect(s.comboMultiplier == 1.0)            // combo 0 → φ⁰
        _ = s.firstValidPlacement().map { s.place(orientationIndex: $0.orientationIndex, at: $0.origin) }
        #expect(abs(s.comboMultiplier - Fibonacci.phi) < 0.0001)  // combo 1 → φ¹
    }
}
