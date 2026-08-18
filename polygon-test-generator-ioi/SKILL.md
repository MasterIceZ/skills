---
name: polygon-test-generator-ioi
description: Generate IOI-style test data with subtask structure from a competitive programming problem statement and solutions. Produces testlib.h-based generators, a subtask-aware validator, hand-crafted tests organized per subtask, subtask-specific partial solutions (sol_st1.cpp, sol_st1_2.cpp, …), wrong/TLE solutions for stress testing, and a test script with group markers. Always use this skill when the user wants to generate IOI tests, mentions "subtasks", "partial scoring", "IOI", "CMS", "task groups", or provides a problem with subtask constraints and asks for test data. Invoke even if the user just says "generate tests" for an IOI-style CP problem.
---

# IOI Test Generator

Generate IOI-style test data from a problem statement (Markdown or LaTeX) and provided solutions.
IOI problems use **subtask-based partial scoring**: contestants receive points for each subtask whose constraints are fully satisfied by their solution.

## What You Produce

| File | Purpose |
|------|---------|
| `generators/gen_edge.cpp` | Edge/corner cases, subtask-aware |
| `generators/gen_random.cpp` | Random tests, subtask-aware |
| `generators/gen_adversarial.cpp` | Worst-case inputs |
| `generators/gen_special.cpp` | Structural inputs (algebraic/combinatorial shapes) |
| `generators/gen_stress.cpp` | Tiny tests for stress testing against brute |
| `validator.cpp` | Validates input; checks per-subtask group constraints |
| `st1/01`, `st1/02`, … | Hand-crafted tests, organized per subtask |
| `st2/01`, `st2/02`, … | (repeat for each subtask) |
| `script.txt` | Test script with `@N` group markers |
| `solutions/sol.cpp` | Model solution (full score) — fix/confirm the provided one |
| `solutions/brute.cpp` | Correct but slow (handles all small subtasks) |
| `solutions/sol_st1.cpp` | Passes **only** subtask 1 |
| `solutions/sol_st1_2.cpp` | Passes subtasks 1–2 |
| `solutions/sol_st1_2_3.cpp` | Passes subtasks 1–3 (if ≥4 subtasks exist) |
| `solutions/wa_*.cpp` | Wrong-answer solutions (3–4 distinct failure modes) |
| `solutions/tle_*.cpp` | Correct-logic but TLE solutions (1–2 files) |

**Directory layout** — keep generators and solutions in their own directories so each set can be bulk-uploaded to Polygon in one go:

```
problem/
├── generators/     # every gen_*.cpp
├── solutions/      # model + brute + partial ladder + wa_* + tle_*
├── validator.cpp   # stays at the package root (own upload slot in Polygon)
├── st1/ … stK/     # hand-crafted tests per subtask
└── script.txt
```
Compiled binaries and generated tests go in a local `build/` directory — never mixed into the source dirs. In `script.txt`, reference generators by bare name (`gen_edge …`), not by path — Polygon resolves uploaded generators by name.

`testlib.h` is pre-available in Polygon — do not upload it. For local testing:
`https://raw.githubusercontent.com/MikeMirzayanov/testlib/refs/heads/master/testlib.h`

---

## Step 0 — Identify and Define Subtasks

Before writing any generator, extract (or infer) the subtask structure. This is the foundation everything else is built on.

### From the problem statement

Read every "Subtask" or "Constraints" section. Produce a table:

| Subtask | Points | Additional constraints |
|---------|--------|----------------------|
| 1 | p₁ | N ≤ 10, no further constraints |
| 2 | p₂ | N ≤ 1 000 |
| 3 | p₃ | All aᵢ equal |
| 4 | p₄ | No further constraints (N ≤ 100 000) |

Subtasks are **cumulative**: subtask k tests are also valid subtask k−1 inputs (unless stated otherwise, e.g., "exactly k distinct values"). The final subtask is always the full constraint set.

### If subtasks are missing or too coarse

IOI problems should typically have 4–6 subtasks. If the problem only has 2–3, **add intermediate subtasks** at natural algorithmic complexity boundaries:

- After the brute-force boundary (N ≤ 10 or N ≤ 100 for O(N³) or O(N²) brutes)
- After the quadratic boundary (N ≤ 3 000–5 000 for O(N²))
- After the N log N boundary (N ≤ 100 000)
- Any problem-specific structural subtask (e.g., "tree is a path/star", "all values distinct", "graph is bipartite")

Announce the final subtask list to the user before proceeding.

---

## Step 1 — Parse the Problem Statement

Extract:

- **Input format**: variable names, structure, exact reading order
- **Full constraints**: every bound across all subtasks
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

Generates deterministic edge and corner cases. Takes `subtask` and `subtype` arguments.

```cpp
#include "testlib.h"
#include <bits/stdc++.h>
using namespace std;

// Per-subtask N limits — match your subtask table exactly
const int MAXN_ST[] = {0, 10, 1000, 5000, 100000};  // index 0 unused

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int st      = argc > 1 ? atoi(argv[1]) : 4;   // subtask
    int subtype = argc > 2 ? atoi(argv[2]) : 0;

    int MAXN = MAXN_ST[st];

    // subtype 0: N = 1 (minimum)
    // subtype 1: N = MAXN for this subtask, all values = MINVAL
    // subtype 2: N = MAXN for this subtask, all values = MAXVAL
    // subtype 3: N = MAXN, sorted ascending
    // subtype 4: N = MAXN, sorted descending
    // subtype 5+: problem-specific edges
    
    // generate and print...
    return 0;
}
```

The `st` argument controls which subtask's N limit is used — `gen_edge 1 0` produces a tiny N=1 case for subtask 1, while `gen_edge 4 1` produces a max-N edge case for the final subtask.

---

## Step 4 — Write generators/gen_random.cpp

Generates random tests within a subtask's constraint range. Takes `subtask`, `n` (optional), and a seed.

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

    // Generate n, then generate values/edges/etc. within subtask constraints.
    // Subtask-specific constraints (e.g., "all aᵢ equal" for subtask 3) must be enforced here.
    // print in exact input format
    return 0;
}
```

**Important:** enforce per-subtask constraints inside the generator, not just by size. If subtask 3 requires all values equal, `gen_random 3 500` must produce all-equal values even at N=500 — the constraint is structural, not just a bound.

To get distinct tests at the same subtask+size, append a different trailing integer — `gen_random 4 100000 1` and `gen_random 4 100000 2` produce completely different tests.

---

## Step 5 — Write generators/gen_special.cpp

Generates structural inputs with mathematical shapes. Takes `subtask` and `subtype`.

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

Aim for 4–6 subtypes per generator. For maximum-constraint subtasks (the final ones), use `MAXN_ST[4]`; for earlier subtasks, cap to their bounds.

---

## Step 6 — Write generators/gen_stress.cpp

Tiny tests for stress testing against `brute.cpp`. Capped well below even subtask 1's limit.

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
    // Do NOT enforce subtask-specific structural constraints here — stress testing
    // should explore the full valid space even if it crosses subtask boundaries.
    return 0;
}
```

---

## Step 7 — Write generators/gen_adversarial.cpp

Worst-case inputs designed to break naive solutions. Takes `subtask` and `subtype`.

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

    // Always use maximum N for the given subtask.
    // subtype 0: worst case for O(N²) naive — sorted ascending
    // subtype 1: worst case for greedy — carefully constructed counter-example
    // subtype 2+: problem-specific

    return 0;
}
```

**Edge ordering in graph generators:** always shuffle edges or print in reverse topological order to prevent accidentally easy orderings that let naive solutions pass.

**Connectivity:** guarantee reachability unless the problem can output -1 (unreachable), in which case include at least one disconnected adversarial case intentionally.

---

## Step 8 — Write Subtask-Specific Solutions

This is the most IOI-specific part. Write one solution per subtask boundary — each one passes all subtasks up to k but is **intentionally too slow or wrong** for subtask k+1.

### solutions/brute.cpp — Subtask 1 boundary

Simple, obviously-correct, slow solution. Should pass subtask 1 (and maybe 2) but TLE on higher subtasks.

```cpp
// brute.cpp — O(?) brute force, correct but too slow for large N
// Passes: subtask 1 (N ≤ 10), possibly subtask 2 (N ≤ 1000) if fast enough
// Use for stress testing: diff <(./sol < test) <(./brute < test)
#include <bits/stdc++.h>
using namespace std;
int main() {
    // simplest possible correct implementation, no regard for complexity
}
```

### solutions/sol_st1.cpp — Passes only subtask 1

A solution whose algorithm is correct for the small constraints of subtask 1 but is too slow or has a missing case for larger inputs. Typical: O(N^k) with large k, or a special-case solution that only handles the structural constraint of subtask 1.

```cpp
// sol_st1.cpp — Passes subtask 1 (N ≤ 10) ONLY
// Algorithm: [name the algorithm]
// Why it fails subtask 2+: [TLE at O(N³), or missing case for larger N, etc.]
#include <bits/stdc++.h>
using namespace std;
int main() { /* ... */ }
```

### solutions/sol_st1_2.cpp — Passes subtasks 1–2

Passes up through subtask 2 (e.g., N ≤ 1 000) but not further. Usually an O(N²) algorithm.

```cpp
// sol_st1_2.cpp — Passes subtasks 1–2 (N ≤ 1000) ONLY
// Algorithm: [e.g., O(N²) DP]
// Why it fails subtask 3+: [TLE at N=5000, or missing structural subtask constraint]
#include <bits/stdc++.h>
using namespace std;
int main() { /* ... */ }
```

### solutions/sol_st1_2_3.cpp — Passes subtasks 1–3 (if ≥4 subtasks)

Only needed when there are 4+ subtasks. This solution is the "good but not full" contestant submission.

```cpp
// sol_st1_2_3.cpp — Passes subtasks 1–3 ONLY
// Algorithm: [e.g., O(N log² N)]
// Why it fails subtask 4+: [explain the gap]
#include <bits/stdc++.h>
using namespace std;
int main() { /* ... */ }
```

### Selecting the right algorithm per subtask boundary

| Subtask | Typical N limit | Common algorithm class |
|---------|----------------|----------------------|
| 1 | ≤ 10–100 | Brute force / O(N^k) |
| 2 | ≤ 1 000–3 000 | O(N²) DP or O(N² log N) |
| 3 | ≤ 10 000–50 000 | O(N log N) or O(N√N) |
| 4 (full) | ≤ 100 000–500 000 | O(N log N) or better |

If the problem has structural subtasks (e.g., "tree is a path"), write the specialized solution that only handles that structure and breaks on a general input.

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
// Passes: subtask 1 and 2 (same as sol_st1_2.cpp but written independently)
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

    // Read the group (subtask) from --group flag:
    // In Polygon, pass --group=1 --testset=tests to the validator.
    // testlib provides it as: inf.group() or via argv parsing.
    // If using Polygon groups, you can do:
    //   string group = validator.group();
    //   int st = group.empty() ? 0 : stoi(group);
    //
    // Then add per-group constraint checks after reading:
    //   if (st >= 1) ensuref(n <= 10, "subtask 1: n must be <= 10");
    //   if (st >= 2) ensuref(n <= 1000, "subtask 2: n must be <= 1000");
    //   ...

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

Create a directory per subtask (`st1/`, `st2/`, …). Within each, write 2–3 static tests:

- `01` — minimum valid input within subtask constraints (N=1 or simplest)
- `02` — maximum N for this subtask, all maximum values
- `03` — problem-specific must-have for this subtask (e.g., if subtask 3 restricts to "path graphs", include the extremal path)

Tests for subtask k must satisfy **all** constraints of subtask k (they will also implicitly satisfy subtasks 1 through k−1).

---

## Step 12 — Test Script (script.txt)

### Group markers

Use `@N` to mark the start of each subtask group. All tests between `@1` and `@2` belong to subtask 1, and so on.

```
@1
gen_edge 1 0 > $
gen_edge 1 1 > $
gen_random 1 10 1 > $
gen_random 1 10 2 > $
gen_random 1 10 3 > $
@2
gen_edge 2 0 > $
gen_edge 2 1 > $
gen_random 2 500 1 > $
gen_random 2 1000 1 > $
gen_random 2 1000 2 > $
gen_adversarial 2 0 > $
@3
gen_edge 3 0 > $
gen_special 3 0 > $
gen_special 3 1 > $
gen_random 3 5000 1 > $
gen_random 3 5000 2 > $
gen_adversarial 3 0 > $
gen_adversarial 3 1 > $
@4
gen_edge 4 0 > $
gen_edge 4 1 > $
gen_edge 4 2 > $
gen_special 4 0 > $
gen_special 4 1 > $
gen_special 4 2 > $
gen_special 4 3 > $
gen_random 4 100000 1 > $
gen_random 4 100000 2 > $
gen_random 4 100000 3 > $
gen_random 4 100000 4 > $
gen_random 4 100000 5 > $
gen_adversarial 4 0 > $
gen_adversarial 4 1 1 > $
gen_adversarial 4 1 2 > $
gen_adversarial 4 2 > $
```

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

Also include a subtask validation check:

```bash
# Verify subtask solutions pass their expected subtasks
g++ -O2 -std=c++17 -o build/sol_st1 solutions/sol_st1.cpp
for f in st1/*; do
    build/sol_st1 < "$f" > /tmp/out.txt
    build/sol     < "$f" > /tmp/ref.txt
    diff /tmp/out.txt /tmp/ref.txt || echo "FAIL: $f"
done
echo "Subtask 1 solution verified."
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

- [ ] Subtask table written and shown to user (with added intermediate subtasks if original had fewer than 4)
- [ ] Generators in `generators/`, all solutions in `solutions/`, `validator.cpp` at the root
- [ ] All generator files compile: `g++ -O2 -I. generators/gen_edge.cpp -o build/gen_edge` etc.
- [ ] `validator.cpp` reads input in exact format; checks per-group constraints
- [ ] Hand-crafted tests exist in `stK/` directories for each subtask K
- [ ] All hand-crafted tests pass the validator
- [ ] `script.txt` uses `@N` group markers and references all generators
- [ ] No two lines in `script.txt` share the same generator+arguments — every repeated call has a distinct trailing seed
- [ ] `gen_random` clamps m to `max(n-1, atoi(argv[...]))` so seed suffixes never produce an invalid edge count
- [ ] `gen_special` subtypes each encode a distinct structural shape
- [ ] `gen_stress` caps N well below subtask 1's limit for fast brute runs
- [ ] `solutions/brute.cpp` gives correct output; passes subtask 1 (and maybe 2)
- [ ] `solutions/sol_st1.cpp` exists and passes ONLY subtask 1; comment explains why it fails subtask 2+
- [ ] `solutions/sol_st1_2.cpp` exists and passes ONLY subtasks 1–2; comment explains failure mode
- [ ] `solutions/sol_st1_2_3.cpp` exists if ≥4 subtasks; comment explains failure mode
- [ ] 3–4 `wa_*.cpp` files with "Fails on:" and "To expose:" comment headers
- [ ] 1–2 `tle_*.cpp` files with "TLEs on:" header
- [ ] Graph/tree generators: edges shuffled or reverse-topological — never bare sequential
- [ ] Every adversarial/special generator guarantees reachability or is intentionally testing the -1 case
- [ ] Constraints in all generators match the subtask table exactly
