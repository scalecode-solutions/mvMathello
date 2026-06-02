import SwiftUI
import mvMathelloKit

/// Owns the Hailstorm session plus the real-time bits the pure engine stays out
/// of: the ghost piece (where you're aiming), the countdown timer, and the
/// placement burst that drives the Metal overlay.
@MainActor
@Observable
public final class HailstormViewModel {
    public enum Status: Sendable { case ready, playing, over }

    public private(set) var session: HailstormSession
    public var ghostOrigin: Coord
    public private(set) var orientationIndex = 0
    public private(set) var status: Status = .ready
    public private(set) var secondsRemaining: Int
    public private(set) var lastBurst: BurstEvent?

    public let duration: Int
    /// Max land stopping-time on this board — normalizes the heat scale.
    public let maxStoppingTime: Int

    private var timerTask: Task<Void, Never>?
    private var burstCounter = 0

    public init(rows: Int = 12, seed: UInt64 = 0x5EED, duration: Int = 90) {
        let session = HailstormSession(rows: rows, seed: seed)
        self.session = session
        self.duration = duration
        self.secondsRemaining = duration
        self.ghostOrigin = Coord(0, min(rows - 1, max(2, rows / 2)))

        var m = 1
        for r in 0..<session.board.rows {
            for c in 0...r where session.board.isLand(row: r, col: c) {
                m = max(m, Collatz.stoppingTime(session.board.value(row: r, col: c) ?? 0))
            }
        }
        self.maxStoppingTime = m
    }

    // MARK: - Derived

    public var ghostCells: [Coord] {
        session.cells(orientationIndex: orientationIndex, at: ghostOrigin)
    }
    public var ghostLegal: Bool {
        session.canPlace(orientationIndex: orientationIndex, at: ghostOrigin)
    }
    public var ghostScore: Int? {
        session.potentialScore(orientationIndex: orientationIndex, at: ghostOrigin)
    }

    /// Land-cell heat, 0...1, for coloring.
    public func heat(row: Int, col: Int) -> Double {
        guard session.board.isLand(row: row, col: col),
              let v = session.board.value(row: row, col: col) else { return 0 }
        return Double(Collatz.stoppingTime(v)) / Double(maxStoppingTime)
    }

    // MARK: - Lifecycle

    public func startIfNeeded() {
        guard status == .ready else { return }
        status = .playing
        startTimer()
    }

    public func newGame(seed: UInt64) {
        teardown()
        session = HailstormSession(rows: session.board.rows, seed: seed)
        orientationIndex = 0
        secondsRemaining = duration
        lastBurst = nil
        status = .playing
        startTimer()
    }

    public func teardown() {
        timerTask?.cancel()
        timerTask = nil
    }

    // MARK: - Input

    public func rotate() {
        orientationIndex += 1
        Haptics.play(.rotate)
    }

    /// Reserve slots (read-through for the UI).
    public var holds: [Pentomino?] { session.holds }

    /// Park/swap the current piece against a reserve slot; resets orientation.
    public func toggleHold(slot: Int) {
        guard status == .playing else { return }
        session.toggleHold(slot: slot)
        orientationIndex = 0
        Haptics.play(.rotate)
    }

    public func moveGhost(to origin: Coord) {
        ghostOrigin = origin
    }

    /// Commit the current ghost. Scores + bursts on success, buzzes on illegal.
    public func placeGhost() {
        guard status == .playing else { return }
        let score = session.potentialScore(orientationIndex: orientationIndex, at: ghostOrigin) ?? 0
        let cells = session.cells(orientationIndex: orientationIndex, at: ghostOrigin)
        guard session.place(orientationIndex: orientationIndex, at: ghostOrigin) else {
            Haptics.play(.illegal)
            return
        }
        burstCounter += 1
        lastBurst = BurstEvent(center: center(of: cells),
                               intensity: min(1.0, Double(score) / 200.0),
                               id: burstCounter)
        Haptics.play(score >= 80 ? .bigScore : .place)
        orientationIndex = 0
    }

    // MARK: - Internals

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while let self, self.status == .playing, self.secondsRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, self.status == .playing else { return }
                self.secondsRemaining -= 1
                if self.secondsRemaining <= 0 {
                    self.status = .over
                    Haptics.play(.gameOver)
                    self.timerTask?.cancel()
                }
            }
        }
    }

    private func center(of cells: [Coord]) -> Coord {
        guard !cells.isEmpty else { return ghostOrigin }
        let sx = cells.map(\.x).reduce(0, +)
        let sy = cells.map(\.y).reduce(0, +)
        return Coord(Int((Double(sx) / Double(cells.count)).rounded()),
                     Int((Double(sy) / Double(cells.count)).rounded()))
    }
}
