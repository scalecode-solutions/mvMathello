# Mathello — Design Notes

> **Othello, if the discs obeyed number theory.**
> A territory game on a Pascal–Sierpiński board where pieces flip by the
> Collatz rule, score by the golden ratio, and the whole thing runs on binary.

**Name:** *Mathello* = Math + Othello.
**Package:** `mvMathello` → `mvMathelloKit` (engine) + `mvMathelloUI` (SwiftUI +
Metal), per the Scalecode `mv` convention (siblings: mvBingo, mvBlocks).
**Status:** Concept captured 2026-06-01. No code yet. Designed to *reuse the
`mvBlocks` engine*. Destined for Clingy's den, same as the others.

---

## The realization that named it

We set out to fuse **pentominoes + Collatz + Pascal + golden ratio**, kept
circling the word "parity," and discovered that the agency loop we'd designed —
*place a piece → cells flip in a cascade → claim territory* — **is the
Othello/Reversi family.** We reinvented Othello's DNA by accident.

The novelty is the **flip rule**: Othello flips a *geometric* bracket of discs;
Mathello flips by a *number-theoretic* rule (Collatz parity / XOR). Same verb,
totally different grammar. Battle-tested skeleton, original math skin.

This is also what handed us the missing **two-player / couples hook** (the den is
a shared space): Othello is territory-versus, so Mathello has a 2-player mode.

---

## The five pillars — four visible, one substrate ("four-on-one")

Four ingredients you see; they all **compile down to base-2**. That's *more*
elegant than a flat list of five — it mirrors the package's own UI-on-Kit shape.

| Pillar | Its one job | Verified fact |
|---|---|---|
| **Pascal's triangle** | the **board** — numbers + geometry | left-align onto a square grid so square pentominoes fit |
| **Pentominoes** | the **pieces** — your verb on *space* | 12 shapes, **63** fixed orientations, flip mechanic (already built in `mvBlocks`) |
| **Collatz (3n+1)** | the **transform** — your verb on *numbers*; flipping parity reshapes the board | 27 → **111 steps**, peak **9,232** @ step 77 |
| **Golden ratio / Fibonacci** | the **growth spine** — scoring, golden targets, the Spiral mode | Fibonacci = Pascal's shallow diagonals → ratios → **φ = 1.618** |
| **Binary / base-2** | the **substrate** the other four are made of (a *lens*, not a mechanic) | parity = bit 0; `/2` = `>>1`; Pascal mod 2 = XOR = Rule 90 = Sierpiński; `2ⁿ` = row sums & Collatz attractor |

### Why exactly these (and why we're done collecting)

Pascal has **two** famous emergent structures, and we use **both**:

- **mod 2 → Sierpiński → parity** → powers the **Collatz / transform** half.
- **diagonals → Fibonacci → φ** → powers the **growth / scoring** half.

*Parity* and *growth*. Beneath both sits **binary** — and there's no 6th
substrate under base-2. The set is complete and self-consistent.

```
the board's parity (Pascal mod 2) is the Sierpiński fractal:
█
█ █
█ · █
█ █ █ █
█ · · · █
█ █ · · █ █
█ · █ · █ · █
█ █ █ █ █ █ █ █
  odd = land / your color   ·   even = hole / other color
```

---

## The agency loop (and its true name)

```
   pentominoes ──act on──▶ SPACE
        ▲                    │
        │                    │  parity = geometry
        │                    ▼
   COLLATZ steps ◀──act on── NUMBERS
   (the player's verb on the math)
```

You transform a number → its **parity flips** → land appears/vanishes in the
Sierpiński board → you tile the new shape with pentominoes → which sets up the
next transform. All three systems feed each other.

**True name of the flip cascade:** editing a bit and watching the **XOR /
Rule-90 cellular automaton** recompute. The morph *is* a binary CA ripple —
which is exactly Othello's flip-cascade with the rule swapped out.

---

## The board

- Left-aligned **Pascal's triangle** on a square grid. Cell value = `C(n,k)`.
- **Parity colors it**: odd = land / your color, even = hole / other color. The
  lit cells form the **Sierpiński** fractal — self-similar, non-trivial to tile.
- **Powers-of-two cells** = glowing **anchor** cells (safe harbors / natural
  goals — they're both Pascal row-sums and Collatz's only safe slide to 1).

---

## Modes — one Kit, many brains

| Mode | Verb | Win | Feel |
|---|---|---|---|
| **Hailstorm** (arcade) | grab high-stopping-time runs vs the clock | beat score/timer | dopamine, launches, φ combos |
| **Chains** (logic) | place pentominoes whose 5 cells form a real Collatz chain (`n→n/2`/`3n+1`) | clear by valid chains | brain-burner |
| **Fractal** (zen) | tile the Sierpiński land exactly | cover all / rebuild a smaller Sierpiński | calm, spatial |
| **Spiral** (capstone) | build along Pascal diagonals / the golden spiral chasing Fibonacci sums | hit the golden targets | the φ endgame |
| **Parity** (2-player) ⭐ | flip parity to claim territory — **Reversi where discs obey Collatz** | own more board | the den's shared/couples hook |

**Progression ramp:** Hailstorm teaches board + payoff → Chains adds the Collatz
constraint → Fractal is pure geometry → Spiral is the golden capstone → Parity
is the social/versus mode.

---

## Agency economy (interventions / boosts)

Collatz **charges** the player spends to act on numbers — directly reusing the
`mvBlocks` boost-block idea:

- **Nudge** (±1) — flip a cell's parity to dodge/forge a path.
- **Force-halve** — drive a number down a step.
- **Wormhole** — jump to a neighboring number.

5 of each free; earn more by clearing / surviving. In single-player these steer
the deterministic math; in **Parity** mode they're your move budget.

---

## Reuse map (from `mvBlocks`)

- **Lift wholesale:** Pentomino + Orientation engine (12 shapes, 63 orientations,
  rotate/flip, kick table).
- **Pattern reuse:** `ProgressStore` protocol (UserDefaults + SwiftData), Theme
  environment-key + named themes, `Haptics`, the `scalecode-metal-plugin` shader
  setup, the `embedded:` host-integration mode, the Demo-app skeleton.
- **New in `mvMathelloKit`:** `PascalBoard` generator, Collatz functions (step,
  stopping-time, chain-validation, reverse-tree), Fibonacci/φ scoring, the
  XOR/Rule-90 board-morph.

---

## Metal / visual

- Glowing Sierpiński board; powers-of-two **anchors** pulse.
- Hailstone **comets** launch from resolved pieces (height = `log₂(value)`).
- Board morph rendered as an **XOR ripple** (CA animation).
- Golden-spiral overlay in Spiral mode; φ-scaled combo flourishes.
- Candidate shaders: `CellGloss`, `FlipRipple`, `HailstoneLaunch`, `GoldenBurst`.

---

## Open questions

- **Parity mode:** real-time or turn-based? Local pass-and-play, or async via
  Clingy's sync layer (partner-vs-partner)?
- One flip rule across all modes, or mode-specific?
- How literal is the Collatz flip in Parity — does placing run a *full hailstone*,
  or just one parity step per turn?
- Board size / which Pascal rows per level. **Multiverse rule-cards** (`3n−1`,
  `5n+1`) as alternate boards/universes — a later expansion?
- Is **Spiral** distinct enough from **Fractal**, or do they merge?
- φ as quiet engine use: golden-ratio (low-discrepancy) sampling for
  non-repeating board/piece generation.

---

## The math, verified (receipts)

- **27:** 111 steps, peak 9,232 @ step 77 (41 odd / 70 even). Three-act shape:
  meander (0–60) → launch to 9232 (60–77) → avalanche with a false-bottom at 23.
- **Pascal diagonals →** 1, 1, 2, 3, 5, 8, 13, 21, 34 … → ratios → **φ = 1.618034**.
- **Pascal mod 2 = Sierpiński = Rule 90** (XOR / add-without-carry).
- `/2` = right bit-shift; parity = last bit; `2ⁿ` = row sums **and** Collatz's
  home stretch (`…16→8→4→2→1`).
