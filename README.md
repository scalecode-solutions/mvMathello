# mvMathello

**Mathello** — a math puzzle game where four ideas turn out to be the same idea.
The board is **Pascal's triangle**; its parity (Pascal mod 2) is the **Sierpiński**
fractal, which is the *land* you play on. Pieces are **pentominoes**. Cell values
drive **Collatz** stopping-times (the scoring landscape), and Pascal's diagonals
are the **Fibonacci** numbers whose ratios give **φ** (the scoring spine).
Underneath it's all **base-2** — parity is the last bit.

Two products: a pure-Swift engine (`mvMathelloKit`) and a SwiftUI + Metal view
layer (`mvMathelloUI`). iOS 26 / Swift 6.2. (See `DESIGN.md` for the full vision,
including the planned modes.)

## Modes

- **Hailstorm** (arcade): drag a pentomino onto the board; score the Collatz
  stopping-times of the land cells you cover, with a φ-scaled combo. Beat the clock.
- **Parity** (2-player, local pass-and-play): Othello, but the board is the
  Sierpiński triangle and the pieces are pentominoes. Cover land to claim it,
  cover the opponent to capture; most land when the board fills wins.

Planned: Chains (Collatz-chain logic), Fractal (tiling), Spiral (φ capstone).

## Requirements

- iOS 26 / Xcode 26 / Swift 6.2+ (also builds on macOS 26 for `swift test`).

## Status

Pre-release. Two modes playable; engine covered by Swift Testing. Polish + the
remaining modes in progress. The pentomino engine is lifted from
[mvBlocks](https://github.com/scalecode-solutions/mvBlocks).
