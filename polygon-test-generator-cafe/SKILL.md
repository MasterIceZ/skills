---
name: polygon-test-generator-cafe
description: Generate cafe-grader-style test data (per-test scoring, NO groups) from a competitive programming problem statement and solutions. Like polygon-test-generator-ioi but every test carries its own score: at most 50 tests ALWAYS, full score exactly 100, and every per-test score an exact decimal (4, 5, 2.5 — never 100/3 = 0.333…). Produces testlib.h-based generators, a full-constraint validator, hand-crafted tests per constraint tier, tier-specific partial solutions (sol_st1.cpp, …), wrong/TLE solutions, a flat test script, and a scores.txt manifest. Always use this skill when the user wants tests for cafe-grader ("cafe", "cafe-grader", "grader.in.th") or any judge with per-test scores and no subtask grouping.
---

# Cafe-Grader Test Generator

Generate test data for cafe-grader from a problem statement (Markdown or LaTeX) and provided solutions.
cafe-grader scores **every test file individually** — there are no subtask groups and no all-or-nothing group scoring. Three hard rules drive everything below:

1. **Never more than 50 tests** (hand-crafted + generated combined). Aim for 20–40.
2. **The full score is exactly 100.**
3. **Every per-test score is an exact decimal** — integers or clean halves like 2.5, never a repeating decimal (100/3 = 0.333… is forbidden). Prefer integers.

Constraint **tiers** (what IOI calls subtasks) remain the core design tool: they structure the generators, the partial-solution ladder, and how the 100 points are spread — but scoring is strictly per test.

## What You Produce

| File | Purpose |
|------|---------|
| `generators/gen_edge.cpp` | Edge/corner cases, tier-aware |
| `generators/gen_random.cpp` | Random tests, tier-aware |
| `generators/gen_adversarial.cpp` | Worst-case inputs |
| `generators/gen_special.cpp` | Structural inputs (algebraic/combinatorial shapes) |
| `generators/gen_stress.cpp` | Tiny tests for stress testing against brute |
| `validator.cpp` | Validates input against the full constraint set (no groups) |
| `tier1/01`, `tier1/02`, … | Hand-crafted tests, organized per tier |
| `tier2/01`, `tier2/02`, … | (repeat for each tier) |
| `script.txt` | Flat test script — no group markers |
| `scores.txt` | Per-test score manifest — exact decimals, sums to exactly 100 |
| `solutions/sol.cpp` | Model solution (full score) — fix/confirm the provided one |
| `solutions/brute.cpp` | Correct but slow (handles all small tiers) |
| `solutions/sol_st1.cpp` | Passes **only** tier 1 |
| `solutions/sol_st1_2.cpp` | Passes tiers 1–2 |
| `solutions/sol_st1_2_3.cpp` | Passes tiers 1–3 (if ≥4 tiers exist) |
| `solutions/wa_*.cpp` | Wrong-answer solutions (3–4 distinct failure modes) |
| `solutions/tle_*.cpp` | Correct-logic but TLE solutions (1–2 files) |

**Directory layout** — keep generators and solutions in their own directories so each set can be bulk-uploaded to Polygon in one go:

```
problem/
├── generators/     # every gen_*.cpp
├── solutions/      # model + brute + partial ladder + wa_* + tle_*
├── validator.cpp   # stays at the package root (own upload slot in Polygon)
├── tier1/ … tierK/     # hand-crafted tests per tier
├── script.txt
└── scores.txt      # test → points manifest (sums to exactly 100)
```
Compiled binaries and generated tests go in a local `build/` directory — never mixed into the source dirs. In `script.txt`, reference generators by bare name (`gen_edge …`), not by path — Polygon resolves uploaded generators by name.

`testlib.h` is pre-available in Polygon — do not upload it. For local testing:
`https://raw.githubusercontent.com/MikeMirzayanov/testlib/refs/heads/master/testlib.h`

---

## Step 0 — Identify and Define Tiers

Before writing any generator, extract (or infer) the tier structure. This is the foundation everything else is built on.

### From the problem statement

Read every "Subtask" or "Constraints" section (IOI-style statements often define subtasks — adopt them as tiers). Produce a table:

| Tier | Points | Additional constraints |
|---------|--------|----------------------|
| 1 | p₁ | N ≤ 10, no further constraints |
| 2 | p₂ | N ≤ 1 000 |
| 3 | p₃ | All aᵢ equal |
| 4 | p₄ | No further constraints (N ≤ 100 000) |

Tiers are **cumulative**: tier k tests are also valid tier k−1 inputs (unless stated otherwise, e.g., "exactly k distinct values"). The final tier is always the full constraint set.

### If tiers are missing or too coarse

Aim for 3–5 tiers. If the statement gives fewer (or none), **add intermediate tiers** at natural algorithmic complexity boundaries:

- After the brute-force boundary (N ≤ 10 or N ≤ 100 for O(N³) or O(N²) brutes)
- After the quadratic boundary (N ≤ 3 000–5 000 for O(N²))
- After the N log N boundary (N ≤ 100 000)
- Any problem-specific structural tier (e.g., "tree is a path/star", "all values distinct", "graph is bipartite")

---

## Step 0.5 — Fix the Test & Score Budget FIRST

Before writing any generator, decide the exact test count and every test's score. Hard rules, no exceptions:

- **Total tests ≤ 50** (hand-crafted + generated combined). Target 20–40.
- **Scores sum to exactly 100.**
- **Every score is an exact decimal.** Prefer integers; halves (2.5) are acceptable; anything repeating is not. For uniform scoring pick a count from {10, 20, 25, 40, 50} → {10, 5, 4, 2.5, 2} points per test. Otherwise assign per-tier values that stay integer/half.

Allocate points per tier like IOI weights, then split evenly inside each tier. Example, 4 tiers mirroring a 20/20/25/35 split:

| Tier | Tests | Points each | Subtotal |
|------|-------|-------------|----------|
| 1 | 5 | 4 | 20 |
| 2 | 5 | 4 | 20 |
| 3 | 5 | 5 | 25 |
| 4 | 7 | 5 | 35 |
| **Total** | **22** | | **100** |

Per-test scoring has NO group all-or-nothing effect — a wrong solution keeps the points of every individual test it sneaks past. Therefore:

- Each failure mode needs **multiple** killer tests spread across tiers; one killer only costs one test's points.
- With so few tests, every test must earn its slot: pick each generator's single most lethal subtype per tier instead of enumerating all subtypes.
- Compute the expected score of every partial/wa/tle solution from the per-test budget and verify it empirically (Step 13).

Announce the final tier table AND this budget to the user before proceeding.

---

## Step 1 — Parse the Problem Statement

Extract:

- **Input format**: variable names, structure, exact reading order
- **Full constraints**: every bound across all tiers
- **Multiple test cases?** If first line is T, note it — handle T-wrapping in all generators
- **Output spec**: unique answer, any valid answer, yes/no, floating point — decide if the answer is unique. A **custom checker** is needed whenever multiple outputs are valid: printing an actual path/assignment/permutation (not just its cost), any-valid-answer constructive problems, floating point with tolerance. If a checker is needed, note it but don't generate it — it's too problem-specific.
- **Problem type**: see heuristics table at the end

---

## Step 2 — Classify Solutions

Identify every provided file by name and content:

| Role | Common names |
|------|-------------|
| Model solution (full) | `ac`, `main_sol`, `model`, `solution`, `sol`, `correct` |
| Brute force | `brute`, `slow`, `naive`, `bf`, `n2`, `n3` |
| Wrong solutions | `wa`, `tle`, `mle`, `wrong`, `hack`, `bad` |

If no brute force is provided, write one (see Step 8).

---

## Step 3 — Write generators/gen_edge.cpp

Generates deterministic edge and corner cases. Takes `tier` and `subtype` arguments.

```cpp
#include "testlib.h"
#include <bits/stdc++.h>
using namespace std;

// Per-tier N limits — match your tier table exactly
const int MAXN_ST[] = {0, 10, 1000, 5000, 100000};  // index 0 unused

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int st      = argc > 1 ? atoi(argv[1]) : 4;   // tier
    int subtype = argc > 2 ? atoi(argv[2]) : 0;

    int MAXN = MAXN_ST[st];

    // subtype 0: N = 1 (minimum)
    // subtype 1: N = MAXN for this tier, all values = MINVAL
    // subtype 2: N = MAXN for this tier, all values = MAXVAL
    // subtype 3: N = MAXN, sorted ascending
    // subtype 4: N = MAXN, sorted descending
    // subtype 5+: problem-specific edges
    
    // generate and print...
    return 0;
}
```

The `st` argument controls which tier's N limit is used — `gen_edge 1 0` produces a tiny N=1 case for tier 1, while `gen_edge 4 1` produces a max-N edge case for the final tier.

---

## Step 4 — Write generators/gen_random.cpp

Generates random tests within a tier's constraint range. Takes `tier`, `n` (optional), and a seed.

```cpp
#include "testlib.h"
#include <bits/stdc++.h>
using namespace std;

const int MAXN_ST[] = {0, 10, 1000, 5000, 100000};

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int st   = argc > 1 ? atoi(argv[1]) : 4;
    int MAXN = MAXN_ST[st];
    int n    = argc > 2 ? min(atoi(argv[2]), MAXN) : rnd.next(1, MAXN);
    // argv[3] acts as seed suffix (no need to read it — testlib uses all argv for seeding)

    // Generate n, then generate values/edges/etc. within tier constraints.
    // Tier-specific constraints (e.g., "all aᵢ equal" for tier 3) must be enforced here.
    // print in exact input format
    return 0;
}
```

**Important:** enforce per-tier constraints inside the generator, not just by size. If tier 3 requires all values equal, `gen_random 3 500` must produce all-equal values even at N=500 — the constraint is structural, not just a bound.

To get distinct tests at the same tier+size, append a different trailing integer — `gen_random 4 100000 1` and `gen_random 4 100000 2` produce completely different tests.

---

## Step 5 — Write generators/gen_special.cpp

Generates structural inputs with mathematical shapes. Takes `tier` and `subtype`.

```cpp
#include "testlib.h"
#include <bits/stdc++.h>
using namespace std;

const int MAXN_ST[] = {0, 10, 1000, 5000, 100000};

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int st      = argc > 1 ? atoi(argv[1]) : 4;
    int subtype = argc > 2 ? atoi(argv[2]) : 0;
    int MAXN    = MAXN_ST[st];

    // Examples:
    // Trees:        complete binary tree, star, bamboo, caterpillar
    // Strings:      pure palindrome, period-2 pattern, Thue-Morse
    // Numbers:      all prime, all powers of 2, arithmetic progression
    // Graphs:       bipartite, complete bipartite, grid graph
    // Permutations: cyclic shift, bitonic, many fixed points

    return 0;
}
```

Aim for 4–6 subtypes per generator. For maximum-constraint tiers (the final ones), use `MAXN_ST[4]`; for earlier tiers, cap to their bounds.

---

## Step 6 — Write generators/gen_stress.cpp

Tiny tests for stress testing against `brute.cpp`. Capped well below even tier 1's limit.

```cpp
#include "testlib.h"
#include <bits/stdc++.h>
using namespace std;

const int STRESS_MAXN = /* something brute handles in <50ms, typically 8–15 */;
const int MINVAL = /* from problem */;
const int MAXVAL = /* from problem */;

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int n = argc > 1 ? atoi(argv[1]) : rnd.next(1, STRESS_MAXN);
    // Same structure as gen_random but capped at STRESS_MAXN.
    // Do NOT enforce tier-specific structural constraints here — stress testing
    // should explore the full valid space even if it crosses tier boundaries.
    return 0;
}
```

---

## Step 7 — Write generators/gen_adversarial.cpp

Worst-case inputs designed to break naive solutions. Takes `tier` and `subtype`.

```cpp
#include "testlib.h"
#include <bits/stdc++.h>
using namespace std;

const int MAXN_ST[] = {0, 10, 1000, 5000, 100000};

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int st      = argc > 1 ? atoi(argv[1]) : 4;
    int subtype = argc > 2 ? atoi(argv[2]) : 0;
    int MAXN    = MAXN_ST[st];

    // Always use maximum N for the given tier.
    // subtype 0: worst case for O(N²) naive — sorted ascending
    // subtype 1: worst case for greedy — carefully constructed counter-example
    // subtype 2+: problem-specific

    return 0;
}
```

**Edge ordering in graph generators:** always shuffle edges or print in reverse topological order to prevent accidentally easy orderings that let naive solutions pass.

**Connectivity:** guarantee reachability unless the problem can output -1 (unreachable), in which case include at least one disconnected adversarial case intentionally.

---

## Step 8 — Write Tier-Specific Solutions

The ladder still matters under per-test scoring: each rung collects exactly the points of the tests it passes. Write one solution per tier boundary — each passes all tiers up to k but is **intentionally too slow or wrong** for tier k+1.

### solutions/brute.cpp — Tier 1 boundary

Simple, obviously-correct, slow solution. Should pass tier 1 (and maybe 2) but TLE on higher tiers.

```cpp
// brute.cpp — O(?) brute force, correct but too slow for large N
// Passes: tier 1 (N ≤ 10), possibly tier 2 (N ≤ 1000) if fast enough
// Use for stress testing: diff <(./sol < test) <(./brute < test)
#include <bits/stdc++.h>
using namespace std;
int main() {
    // simplest possible correct implementation, no regard for complexity
}
```

### solutions/sol_st1.cpp — Passes only tier 1

A solution whose algorithm is correct for the small constraints of tier 1 but is too slow or has a missing case for larger inputs. Typical: O(N^k) with large k, or a special-case solution that only handles the structural constraint of tier 1.

```cpp
// sol_st1.cpp — Passes tier 1 (N ≤ 10) ONLY
// Algorithm: [name the algorithm]
// Why it fails tier 2+: [TLE at O(N³), or missing case for larger N, etc.]
#include <bits/stdc++.h>
using namespace std;
int main() { /* ... */ }
```

### solutions/sol_st1_2.cpp — Passes tiers 1–2

Passes up through tier 2 (e.g., N ≤ 1 000) but not further. Usually an O(N²) algorithm.

```cpp
// sol_st1_2.cpp — Passes tiers 1–2 (N ≤ 1000) ONLY
// Algorithm: [e.g., O(N²) DP]
// Why it fails tier 3+: [TLE at N=5000, or missing structural tier constraint]
#include <bits/stdc++.h>
using namespace std;
int main() { /* ... */ }
```

### solutions/sol_st1_2_3.cpp — Passes tiers 1–3 (if ≥4 tiers)

Only needed when there are 4+ tiers. This solution is the "good but not full" contestant submission.

```cpp
// sol_st1_2_3.cpp — Passes tiers 1–3 ONLY
// Algorithm: [e.g., O(N log² N)]
// Why it fails tier 4+: [explain the gap]
#include <bits/stdc++.h>
using namespace std;
int main() { /* ... */ }
```

### Selecting the right algorithm per tier boundary

| Tier | Typical N limit | Common algorithm class |
|---------|----------------|----------------------|
| 1 | ≤ 10–100 | Brute force / O(N^k) |
| 2 | ≤ 1 000–3 000 | O(N²) DP or O(N² log N) |
| 3 | ≤ 10 000–50 000 | O(N log N) or O(N√N) |
| 4 (full) | ≤ 100 000–500 000 | O(N log N) or better |

If the problem has structural tiers (e.g., "tree is a path"), write the specialized solution that only handles that structure and breaks on a general input.

---

## Step 9 — Write Wrong/TLE Solutions

### solutions/wa_*.cpp — Wrong Answer Solutions (3–4 files)

Each implements a *distinct* common wrong approach. Cover different failure modes.

```cpp
// wa_greedy.cpp — WRONG: [describe the mistake in one line]
// Fails on: [describe what kind of input breaks it]
// To expose: gen_special 4 2 or gen_edge 4 5
#include <bits/stdc++.h>
using namespace std;
int main() { /* ... */ }
```

Good wrong approaches: greedy without lookahead, DP with wrong base case, mishandled edge cases, overflow with int instead of long long, off-by-one in binary search.

### solutions/tle_*.cpp — TLE Solutions (1–2 files)

Correct logic but too-high complexity. Model realistic contestant mistakes.

```cpp
// tle_n2.cpp — CORRECT but O(N²): [describe the approach]
// TLEs on: N ≥ [threshold] — triggers with gen_adversarial 4 0
// Passes: tier 1 and 2 (same as sol_st1_2.cpp but written independently)
#include <bits/stdc++.h>
using namespace std;
int main() { /* ... */ }
```

---

## Step 10 — Write validator.cpp

The validator lives at the package root, not in `generators/` — Polygon uploads it in its own slot.

```cpp
#include "testlib.h"
using namespace std;

int main(int argc, char* argv[]) {
    registerValidation(argc, argv);

    // cafe-grader has no test groups — validate the FULL constraint set only.
    // Tier-specific bounds are the generators' responsibility (checked by the
    // per-test budget review), NOT the validator's: every single test, whatever
    // tier it was designed for, must pass this one validator.

    // Read input exactly as the problem specifies.
    // Key methods:
    //   inf.readInt(lo, hi, "name")      — integer with bounds check
    //   inf.readLong(lo, hi, "name")     — long long
    //   inf.readToken("[a-z]+", "name")  — string matching regex
    //   inf.readSpace()                  — assert ' '
    //   inf.readEoln()                   — assert '\n'
    //   inf.readEof()                    — assert end of file

    return 0;
}
```

---

## Step 11 — Hand-crafted Test Files

Create a directory per tier (`tier1/`, `tier2/`, …). Within each, write 1–2 static tests — they count toward the ≤ 50 budget:

- `01` — minimum valid input within tier constraints (N=1 or simplest)
- `02` — maximum N for this tier, all maximum values
- `03` — problem-specific must-have for this tier (e.g., if tier 3 restricts to "path graphs", include the extremal path)

Tests for tier k must satisfy **all** constraints of tier k (they will also implicitly satisfy tiers 1 through k−1).

---

## Step 12 — Test Script (script.txt)

### Flat script — no group markers

cafe-grader has no groups, so `script.txt` is a flat list of generator calls with NO `@N` markers. Hand-crafted tests are uploaded first (manual tests), generated ones follow. The TOTAL (manual + generated) must respect the Step 0.5 budget — never more than 50. Choose each generator's single most lethal subtype per tier.

Example matching the 22-test budget above (5 hand-crafted in tier dirs + 17 generated):

```
gen_edge 1 0 > $
gen_edge 1 3 > $
gen_random 1 1000 1 > $
gen_adversarial 1 1 > $
gen_random 2 100000 1 > $
gen_special 2 2 > $
gen_adversarial 2 0 > $
gen_edge 3 3 > $
gen_random 3 100000 1 > $
gen_special 3 0 > $
gen_adversarial 3 1 > $
gen_adversarial 3 2 > $
gen_edge 4 2 > $
gen_random 4 100000 1 > $
gen_random 4 100000 2 > $
gen_special 4 3 > $
gen_adversarial 4 3 > $
```

### scores.txt — the score manifest

One line per test **in final judge order** (manual tests first): `test_number  score  source`. `#` starts a comment.

```
1   4  tier1/01
2   4  tier1/02
3   4  gen_edge 1 0
4   4  gen_edge 1 3
...
21  5  gen_special 4 3
22  5  gen_adversarial 4 3
# 22 tests, sum = 100
```

Machine-check before finishing: line count ≤ 50, scores sum to exactly 100, every score an exact decimal.

### Exporting for cafe-grader

cafe-grader consumes numbered pairs `1.in`/`1.sol`, `2.in`/`2.sol`, … Materialize inputs locally in judge order (manual tests first, then script lines), produce each `.sol` with the model solution, and enter the per-test scores from `scores.txt` in the grader's problem configuration.

### Seeding rule

`registerGen(argc, argv, 1)` seeds the RNG from **all** command-line arguments. Two lines with identical arguments produce identical tests. Append a distinct trailing integer to get different outputs from the same generator+args combination:

```
gen_random 4 100000 1 > $   # distinct seed
gen_random 4 100000 2 > $   # different output
```

Generators that never call `rnd` are immune — call each subtype only once.

---

## Step 13 — Local Stress Test Script

```bash
mkdir -p build
g++ -O2 -std=c++17 -I. -o build/gen_stress generators/gen_stress.cpp
g++ -O2 -std=c++17 -o build/sol   solutions/sol.cpp    # full correct solution
g++ -O2 -std=c++17 -o build/brute solutions/brute.cpp

for i in $(seq 1 1000); do
    build/gen_stress "$i" > test.in   # pass $i: testlib seeds from argv, no args = same test forever
    build/sol   < test.in > out_sol.txt
    build/brute < test.in > out_brute.txt
    if ! diff -q out_sol.txt out_brute.txt > /dev/null 2>&1; then
        echo "DIFFERENCE on iteration $i"
        cat test.in
        echo "--- sol ---"; cat out_sol.txt
        echo "--- brute ---"; cat out_brute.txt
        break
    fi
done
echo "Stress test done."
```

Also include a tier validation check:

```bash
# Verify tier solutions pass their expected tiers
g++ -O2 -std=c++17 -o build/sol_st1 solutions/sol_st1.cpp
for f in tier1/*; do
    build/sol_st1 < "$f" > /tmp/out.txt
    build/sol     < "$f" > /tmp/ref.txt
    diff /tmp/out.txt /tmp/ref.txt || echo "FAIL: $f"
done
echo "Tier 1 solution verified."
```

---

## Problem-Type Heuristics

| Type | Signals | Edge subtypes | Adversarial subtypes |
|------|---------|--------------|----------------------|
| Array/sequence | "N integers", "sequence" | min/max/sorted/reverse/all-equal | sorted asc (breaks O(N²)), all-equal |
| Permutation | "permutation of 1..N" | identity, reverse, random | cyclic shift, reverse |
| Graph | "N nodes M edges" | N=2, tree, complete, star | star, path/chain, bipartite |
| Tree | "N nodes, N-1 edges" | N=2, chain, star, single path | bamboo (depth=N, breaks recursion), star |
| String | "string of length N" | N=1, all 'a', alternating "ab…", palindrome | all 'a', "abababab…" |
| Grid | "N×M grid" | 1×M, N×1, checkerboard, all same | all same char, checkerboard |
| Multiple T-cases | "first line T" | max T min-N cases; one max-N single case | max T, each case adversarial |

For **tree** problems: always include bamboo (chain of N nodes). Recursive solutions that don't iteratively DFS will stack-overflow.

For **graph** problems: always include a path graph and a star. If M allows it, include a near-complete graph.

---

## Common Wrong/TLE Solution Patterns

### Wrong Answer (wa_*.cpp)

| Problem type | Common wrong approach | Breaks on |
|-------------|----------------------|-----------|
| Sorting/searching | Greedy picks local minimum without lookahead | Anti-greedy input |
| DP | Wrong base case | Small inputs near the base case |
| Graph shortest path | BFS on weighted graph | Graph with varying edge weights |
| String | Not handling overlapping patterns | Strings with many overlapping occurrences |
| Counting | Forgetting modular arithmetic / int overflow | Large values near INT_MAX |
| Binary search | Wrong predicate direction or off-by-one | Boundary answer at lo or hi |

### TLE (tle_*.cpp)

| Problem type | TLE approach | Correct complexity | TLE complexity |
|-------------|-------------|-------------------|----------------|
| Sequence queries | Recompute from scratch each query | O(N + Q) with prefix sums | O(N·Q) |
| Sorting-based | Insertion/selection sort | O(N log N) | O(N²) |
| Graph BFS/DFS | Rebuild adjacency list every call | O(N + M) once | O(N·(N+M)) |
| String matching | Naive double loop | O(N) KMP/Z-function | O(N²) |
| DP transitions | Extra loop per state | O(N log N) with monotone deque | O(N²) |

---

## Final Checklist

- [ ] Tier table AND test/score budget shown to user (≤ 50 tests, sum exactly 100, exact decimals)
- [ ] Generators in `generators/`, all solutions in `solutions/`, `validator.cpp` at the root
- [ ] All generator files compile: `g++ -O2 -I. generators/gen_edge.cpp -o build/gen_edge` etc.
- [ ] `validator.cpp` reads input in exact format; validates the FULL constraint set (no groups)
- [ ] Hand-crafted tests exist in `tierK/` directories for each tier K
- [ ] All hand-crafted tests pass the validator
- [ ] `script.txt` is flat — no `@N` markers; manual + generated test count ≤ 50
- [ ] `scores.txt` lists every test in judge order; scores are exact decimals summing to exactly 100
- [ ] Expected per-test score of every partial/wa/tle solution computed and verified empirically
- [ ] No two lines in `script.txt` share the same generator+arguments — every repeated call has a distinct trailing seed
- [ ] `gen_random` clamps m to `max(n-1, atoi(argv[...]))` so seed suffixes never produce an invalid edge count
- [ ] `gen_special` subtypes each encode a distinct structural shape
- [ ] `gen_stress` caps N well below tier 1's limit for fast brute runs
- [ ] `solutions/brute.cpp` gives correct output; passes tier 1 (and maybe 2)
- [ ] `solutions/sol_st1.cpp` exists and passes ONLY tier 1; comment explains why it fails tier 2+
- [ ] `solutions/sol_st1_2.cpp` exists and passes ONLY tiers 1–2; comment explains failure mode
- [ ] `solutions/sol_st1_2_3.cpp` exists if ≥4 tiers; comment explains failure mode
- [ ] 3–4 `wa_*.cpp` files with "Fails on:" and "To expose:" comment headers
- [ ] 1–2 `tle_*.cpp` files with "TLEs on:" header
- [ ] Graph/tree generators: edges shuffled or reverse-topological — never bare sequential
- [ ] Every adversarial/special generator guarantees reachability or is intentionally testing the -1 case
- [ ] Constraints in all generators match the tier table exactly
