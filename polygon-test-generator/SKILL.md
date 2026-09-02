---
name: polygon-test-generator
description: Generate Codeforces Polygon test data from a competitive programming problem statement and its solutions, producing testlib.h generators (edge, random, special, stress, adversarial), a validator, hand-crafted tests, a Polygon test script, and brute/wrong/TLE solutions for local stress testing. Use when the user wants test cases for a CP problem on Polygon with plain all-or-nothing scoring (no subtasks, no per-test scores).
when_to_use: Trigger phrases include "generate tests", "make test cases", "gen.cpp", "testlib", "polygon tests", "stress test", or a problem statement plus a model solution with a request for test data. For subtask/partial scoring use polygon-test-generator-ioi; for cafe-grader per-test scoring use polygon-test-generator-cafe.
---

# Polygon Test Generator

Produce a complete, verified Polygon test package from a problem statement (Markdown or LaTeX) and the provided solutions. Work through the steps in order; each later step depends on the constraints and solution roles established in Steps 1 and 2.

Keep the user informed: say what you are about to do before starting, give a one-line update as each stage completes (generators written, solutions written, stress test result), and close with a recap that lists every produced file and any local verification that failed or was skipped. Deliver the whole package in one pass; if a part cannot be produced (for example, a custom checker), say so in the recap rather than stopping early.

## What you produce

| File | Upload destination in Polygon |
|------|-------------------------------|
| `gen_edge.cpp`, `gen_random.cpp`, `gen_special.cpp`, `gen_stress.cpp`, `gen_adversarial.cpp` | Files → Source Files (generator) |
| `validator.cpp` | Files → Source Files (validator) |
| `01`, `02`, `03`, … | Tests → Add Test (manual) |
| `script.txt` | Tests → Test Script (paste) |
| `brute.cpp`, `wa_*.cpp`, `tle_*.cpp` | Local stress and hack testing only, not uploaded |

`testlib.h` is already available in Polygon, so it is not uploaded. For local compilation download it from
`https://raw.githubusercontent.com/MikeMirzayanov/testlib/refs/heads/master/testlib.h`.

## Step 1 — Parse the problem statement

Extract:

- **Input format**: variable names, structure, exact reading order.
- **Constraints**: every bound (N ≤ ?, 1 ≤ aᵢ ≤ ?, …).
- **Multiple test cases**: if the first line is T, every generator wraps its output in T cases.
- **Output spec**: decide whether the answer is unique. A custom checker is needed when several outputs are valid (printing a path, assignment, or permutation rather than its cost; any-valid-answer constructive problems; floating point with tolerance). Note that a checker is needed but do not write one; it is too problem-specific for this skill.
- **Problem type**: match against [reference/patterns.md](reference/patterns.md) to pick edge and adversarial shapes.

## Step 2 — Classify the provided solutions

| Role | Common names |
|------|-------------|
| Model solution (authoritative) | `ac`, `main_sol`, `model`, `solution`, `sol`, `correct` |
| Brute force (slow but correct) | `brute`, `slow`, `naive`, `bf`, `n2`, `n3` |
| Wrong solutions (intentionally bad) | `wa`, `tle`, `mle`, `wrong`, `hack`, `bad` |

Wrong solutions tell you what the test suite has to catch. If no brute force is provided, write one in Step 4.

## Step 3 — Write the generators

All five generators share one skeleton. Full per-generator templates with comment scaffolds are in [reference/templates.md](reference/templates.md).

```cpp
#include "testlib.h"
#include <bits/stdc++.h>
using namespace std;

const int MAXN   = /* from problem */;
const int MINVAL = /* from problem */;
const int MAXVAL = /* from problem */;

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int arg = argc > 1 ? atoi(argv[1]) : 0;   // subtype, or n for gen_random / gen_stress
    // build the input, then print it in the exact input format
    return 0;
}
```

| Generator | Argument | Produces |
|-----------|----------|----------|
| `gen_edge` | `subtype` | Deterministic corner cases: N=1; N=MAXN with all MINVAL, all MAXVAL, sorted ascending, sorted descending, all identical; then problem-specific edges from the patterns table |
| `gen_random` | `n` (random in range when omitted) | Uniform random inputs across the constraint range; graph inputs start from a spanning tree so node N is reachable |
| `gen_special` | `subtype` | 4–6 structural shapes, each a distinct mathematical structure rather than a size variant (bamboo, star, caterpillar; palindromes, period-2 strings; all-prime, powers of 2; bipartite, grid; cyclic-shift or bitonic permutations). These target the algebraic structure a solution depends on, which neither size-based edges nor adversarial cases cover |
| `gen_stress` | `n` (random ≤ STRESS_MAXN when omitted) | Tiny inputs (STRESS_MAXN ≈ 10–20, whatever `brute` solves in under 50 ms) so the Step 8 stress loop can run thousands of cases without shrinking N by hand |
| `gen_adversarial` | `subtype` | Maximum-N inputs built to break naive solutions: the O(N²) killer, the anti-greedy counter-example, the problem-specific worst case. Aim each subtype at a specific `wa_*` or `tle_*` solution |

Rules that are easy to get wrong:

- **Random values come from testlib's `rnd`** (`rnd.next(lo, hi)`), even inside an otherwise deterministic pattern. `registerGen` seeds `rnd` from the full argv, so every test stays reproducible.
- **Seeding**: because the seed is derived from all arguments, `gen_random 100000 1` and `gen_random 100000 2` give different tests while two identical lines give identical tests. Every repeated call in `script.txt` needs a distinct trailing token. Generators that never call `rnd` are fully deterministic, so call each of their subtypes once.
- **Seed vs. m collision**: if `gen_random` reads `argv[2]` as an edge count `m`, a trailing seed like `gen_random 10 2` would set m=2 while the spanning tree alone needs 9 edges, and the validator would reject the file. Clamp with `m = max(n - 1, atoi(argv[2]))` so the seed still varies the RNG and m is always legal; explicit large-m calls such as `gen_random 100000 200000 3` keep working.
- **Edge order in graph generators**: printing edges in chain, BFS, or spanning-tree order can neuter an adversarial case. Bellman-Ford, for instance, finishes in one pass when edges arrive in topological order. Shuffle edges with testlib's `shuffle(edges.begin(), edges.end())` or print a bamboo in reverse (`for (i = n-1; i >= 1; --i)`).
- **Reachability**: `gen_adversarial` and `gen_special` do not build a spanning tree automatically. If the problem never outputs −1, every subtype has to guarantee the required reachability. If −1 is a legal answer, include one intentionally disconnected case and confirm the others are connected by checking that `./sol` does not print −1 unexpectedly.
- **Verify the TLE**: after writing an adversarial generator, run `timeout <TL> ./tle_x < input`. If it exits 0, the ordering or structure is accidentally easy and the generator needs fixing.

## Step 4 — Write brute, wrong, and TLE solutions

These stay local; they prove the tests do their job. Templates and comment-header conventions are in [reference/templates.md](reference/templates.md); common wrong and slow approaches per problem type are in [reference/patterns.md](reference/patterns.md).

- **`brute.cpp`**: the simplest obviously-correct solution, complexity irrelevant. O(N²) or O(N³) scans, Floyd–Warshall, exponential DFS, and O(N²) substring checks are all fine.
- **`wa_*.cpp`** (3–4 files): each implements a *different* wrong approach, so the suite is tested against several failure modes rather than one. Sources: greedy without lookahead, DP with a wrong base case or transition, mishandled edge cases (N=1, empty input, overflow), correct on random input but wrong on a specific structure, correct algorithm with an implementation slip (binary-search off-by-one, modular arithmetic). Name them by mistake: `wa_greedy.cpp`, `wa_overflow.cpp`, …
- **`tle_*.cpp`** (1–2 files): correct logic, too-high complexity, the kind a contestant would actually submit: O(N² log N) where O(N log N) is required, an extra loop in a DP, `std::set` in a tight inner loop, rebuilding adjacency per query. They differ from `brute` in intent: `brute` checks correctness, `tle_*` checks that the large tests are actually stressful.

Every bad solution starts with a header that ties it to the tests that expose it:

```cpp
// wa_greedy.cpp — WRONG: [the mistake in one line]
// Fails on: [what kind of input breaks it]
// To expose: gen_special 2 or gen_edge 5
```

```cpp
// tle_n2.cpp — CORRECT but O(N²): [the approach]
// TLEs on: N ≥ [threshold] — triggers with gen_adversarial 0 or gen_random MAXN
```

The "To expose" and "TLEs on" lines are a contract: the named generator subtype has to exist and has to make that solution fail.

## Step 5 — Write validator.cpp

The validator is the canonical definition of a valid input, so it reads the input exactly as the statement specifies, including spaces and newlines.

```cpp
#include "testlib.h"
using namespace std;

int main(int argc, char* argv[]) {
    registerValidation(argc, argv);
    // inf.readInt(lo, hi, "name")      integer with bounds check
    // inf.readLong(lo, hi, "name")     long long
    // inf.readToken("[a-z]+", "name")  token matching a regex
    // inf.readSpace()  inf.readEoln()  inf.readEof()
    return 0;
}
```

For graphs, check for self-loops and parallel edges, and check connectivity with union-find when the statement guarantees it.

## Step 6 — Hand-crafted tests

Write at least three static files, named without extension:

- `01`: minimum valid input (N=1 or the simplest case).
- `02`: maximum N, all maximum values.
- `03`: maximum N, all minimum values.
- More when the problem has must-have deterministic cases.

Run each one through the validator before packaging.

## Step 7 — Test script (script.txt)

Every repeated generator call carries a distinct trailing seed token (Step 3). Deterministic generators are called once per subtype.

```
gen_edge 0 > $
gen_edge 1 > $
gen_edge 2 > $
gen_edge 3 > $
gen_edge 4 > $
gen_edge 5 > $
gen_special 0 > $
gen_special 1 > $
gen_special 2 > $
gen_special 3 > $
gen_random 10 1 > $
gen_random 100 1 > $
gen_random 1000 1 > $
gen_random MAXN 1 > $
gen_random MAXN 2 > $
gen_random MAXN 3 > $
gen_random MAXN 4 > $
gen_random MAXN 5 > $
gen_adversarial 0 > $
gen_adversarial 1 1 > $
gen_adversarial 1 2 > $
gen_adversarial 2 1 > $
gen_adversarial 2 2 > $
```

Match the `gen_special` and `gen_adversarial` lines to the subtypes actually implemented, and replace `MAXN` with the real bound.

## Step 8 — Local stress test

Copy [scripts/stress.sh](scripts/stress.sh) next to the sources and run it whenever a brute force exists. It compiles `gen_stress`, the model solution, and `brute` with `$CXX` (default `g++`; on macOS set `CXX` to a GNU compiler such as `g++-15`, because Apple's `g++` is clang and lacks `bits/stdc++.h`), runs 1000 iterations with the iteration number as the seed (so every iteration is a different test), and stops at the first difference. It uses `gen_stress` rather than `gen_random` so the brute force keeps up.

Also run each `wa_*` and `tle_*` solution over the generated tests and confirm it fails where its header says it should.

## Final checklist

- [ ] All five generators compile (`g++ -O2 -std=c++17 gen_edge.cpp -o gen_edge`, etc.)
- [ ] `validator.cpp` reads the input in the exact format, with no extra or missing whitespace
- [ ] Hand-crafted tests `01`, `02`, `03` pass the validator
- [ ] `script.txt` uses the real generator names (`gen_edge`, `gen_random`, `gen_special`, `gen_adversarial`), not a bare `gen`
- [ ] No two `script.txt` lines share a generator and argument list; repeated calls differ by a trailing seed
- [ ] `gen_random` clamps m to `max(n - 1, atoi(argv[2]))`
- [ ] `gen_special` subtypes are distinct structures, not size variants
- [ ] `gen_stress` caps N at a size `brute` solves in under 50 ms
- [ ] `brute.cpp` is correct; 3–4 `wa_*.cpp` with distinct failure modes and "Fails on" / "To expose" headers; 1–2 `tle_*.cpp` with a "TLEs on" header
- [ ] Each `tle_*` verified locally: `timeout <TL> ./tle_x < adversarial_input` exits non-zero
- [ ] Graph and tree generators shuffle edges or print them in reverse topological order
- [ ] Every adversarial and special subtype either guarantees reachability or is a deliberate −1 case
- [ ] Constraints in every generator match the statement exactly

## Additional resources

- [reference/templates.md](reference/templates.md): full generator, solution, and validator templates with comment scaffolds
- [reference/patterns.md](reference/patterns.md): problem-type heuristics and common wrong/TLE approaches
- [scripts/stress.sh](scripts/stress.sh): the local stress loop
