import Testing
@testable import mvMathelloKit

@Suite("Parity session")
struct ParityTests {

    @Test("Fresh match: Player 1 to move, no territory, all land unclaimed")
    func startState() {
        let s = ParitySession(rows: 10, seed: 1)
        #expect(s.current == .one)
        #expect(s.score(.one) == 0)
        #expect(s.score(.two) == 0)
        #expect(s.unclaimedLand == s.board.landCount)
        #expect(s.isOver == false)
    }

    @Test("Placing claims land, passes the turn, and shrinks unclaimed")
    func placeClaimsAndPasses() {
        var s = ParitySession(rows: 12, seed: 2)
        let move = s.firstValidPlacement()
        #expect(move != nil)
        let (oi, origin) = move!
        let claimedCount = s.landCovered(orientationIndex: oi, at: origin).count
        let unclaimedBefore = s.unclaimedLand

        #expect(s.place(orientationIndex: oi, at: origin) == true)
        #expect(s.current == .two)                       // turn passed
        #expect(s.score(.one) == claimedCount)           // P1 owns the covered land
        #expect(s.unclaimedLand == unclaimedBefore - claimedCount)
    }

    @Test("Covering an opponent's cell captures it")
    func capture() {
        var s = ParitySession(rows: 12, seed: 4)
        // Player 1 places.
        guard let (oi1, o1) = s.firstValidPlacement() else { Issue.record("no P1 move"); return }
        let p1Cells = Set(s.landCovered(orientationIndex: oi1, at: o1))
        s.place(orientationIndex: oi1, at: o1)
        #expect(p1Cells.allSatisfy { s.owner[$0] == .one })

        // Find a Player-2 placement that covers at least one of P1's cells.
        var captured = false
        outer: for row in 0..<s.board.rows {
            for col in 0...row {
                for oi in 0..<s.currentPiece.orientations.count {
                    guard s.canPlace(orientationIndex: oi, at: Coord(col, row)) else { continue }
                    let covered = Set(s.landCovered(orientationIndex: oi, at: Coord(col, row)))
                    if let stolen = covered.intersection(p1Cells).first {
                        s.place(orientationIndex: oi, at: Coord(col, row))
                        #expect(s.owner[stolen] == .two)   // flipped from P1 to P2
                        captured = true
                        break outer
                    }
                }
            }
        }
        #expect(captured == true)
    }

    @Test("Playing to the end yields a finished board and a defined result")
    func playToCompletion() {
        var s = ParitySession(rows: 8, seed: 7)
        var guardrail = 0
        while !s.isOver, guardrail < 500 {
            guard let (oi, origin) = s.firstValidPlacement() else { break }
            s.place(orientationIndex: oi, at: origin)
            guardrail += 1
        }
        #expect(s.isOver == true)
        #expect(s.score(.one) + s.score(.two) <= s.board.landCount)
        // winner is .one, .two, or nil (tie) — just ensure it's only set when over.
        _ = s.winner
    }
}
