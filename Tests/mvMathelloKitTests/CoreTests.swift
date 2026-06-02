import Testing
@testable import mvMathelloKit

@Suite("Pentomino engine (lifted)")
struct PentominoTests {
    @Test("Twelve pentominoes, 63 fixed orientations total")
    func orientations() {
        #expect(Pentomino.allCases.count == 12)
        let total = Pentomino.allCases.reduce(0) { $0 + $1.orientations.count }
        #expect(total == 63)
    }
}

@Suite("Pascal board")
struct PascalBoardTests {

    @Test("Row values are the binomial coefficients")
    func rowValues() {
        let board = PascalBoard(rows: 5)
        #expect(board.values[4] == [1, 4, 6, 4, 1])
        #expect(board.value(row: 4, col: 2) == 6)
        #expect(board.value(row: 4, col: 5) == nil)   // off the triangle
    }

    @Test("Parity is the Sierpiński land mask")
    func parityIsSierpinski() {
        let board = PascalBoard(rows: 4)
        // Row 2 = 1,2,1 → land, hole, land.
        #expect(board.isLand(row: 2, col: 0) == true)
        #expect(board.isLand(row: 2, col: 1) == false)
        #expect(board.isLand(row: 2, col: 2) == true)
        // Row 3 = 1,3,3,1 → all odd → all land.
        #expect((0...3).allSatisfy { board.isLand(row: 3, col: $0) })
    }

    @Test("Anchor cells are the powers of two")
    func anchors() {
        let board = PascalBoard(rows: 5)
        #expect(board.isAnchor(row: 2, col: 1) == true)   // C(2,1) = 2
        #expect(board.isAnchor(row: 4, col: 1) == true)   // C(4,1) = 4
        #expect(board.isAnchor(row: 4, col: 2) == false)  // C(4,2) = 6
    }
}

@Suite("Collatz")
struct CollatzTests {

    @Test("27 reaches 1 in 111 steps")
    func twentySeven() {
        #expect(Collatz.stoppingTime(27) == 111)
        #expect(Collatz.trajectory(27).max() == 9232)
    }

    @Test("step + successor + powers of two")
    func basics() {
        #expect(Collatz.step(82) == 41)        // even → /2
        #expect(Collatz.step(41) == 124)       // odd → 3n+1
        #expect(Collatz.isSuccessor(82, 41) == true)
        #expect(Collatz.isSuccessor(82, 40) == false)
        #expect(Collatz.isPowerOfTwo(16) == true)
        #expect(Collatz.isPowerOfTwo(6) == false)
    }
}

@Suite("Fibonacci / golden ratio")
struct FibonacciTests {

    @Test("Pascal's shallow diagonals sum to the Fibonacci sequence")
    func diagonalsAreFibonacci() {
        let board = PascalBoard(rows: 9)
        #expect(Fibonacci.diagonalSums(of: board) == [1, 1, 2, 3, 5, 8, 13, 21, 34])
    }

    @Test("isFibonacci recognizes membership")
    func membership() {
        #expect(Fibonacci.isFibonacci(13) == true)
        #expect(Fibonacci.isFibonacci(21) == true)
        #expect(Fibonacci.isFibonacci(12) == false)
        #expect(Fibonacci.isFibonacci(0) == false)
    }

    @Test("ratios approach φ")
    func goldenRatio() {
        let f = Fibonacci.sequence(count: 20)
        let ratio = Double(f[19]) / Double(f[18])
        #expect(abs(ratio - Fibonacci.phi) < 0.0001)
    }
}
