---
name: polygon-test-generator
description: Generate Codeforces Polygon-compatible test data from a competitive programming problem statement and solutions. Produces multiple testlib.h-based generator files (gen_edge.cpp, gen_random.cpp, gen_adversarial.cpp), validator.cpp, hand-crafted test files, a Polygon test script, and wrong/TLE solutions for stress testing. Always use this skill when the user wants to create test cases for a CP problem on Codeforces Polygon, mentions "gen.cpp", "testlib", "polygon tests", "stress test", or provides a problem statement with a model solution and asks to generate test data. Invoke even if the user just says "generate tests" or "make test cases" for a competitive programming problem.
---

# Polygon Test Generator

Generate Codeforces Polygon-compatible test data from a problem statement (Markdown or LaTeX) and provided solutions.

## What You Produce

| File | Upload destination in Polygon |
|------|-------------------------------|
| `gen_edge.cpp` | Files → Source Files (generator) |
| `gen_random.cpp` | Files → Source Files (generator) |
| `gen_adversarial.cpp` | Files → Source Files (generator) |
| `gen_special.cpp` | Files → Source Files (generator) |
| `gen_stress.cpp` | Files → Source Files (generator) |
| `validator.cpp` | Files → Source Files (validator) |
| `01`, `02`, `03`, … | Tests → Add Test (manual) |
| `script.txt` | Tests → Test Script (copy-paste) |
| `brute.cpp` | Local stress testing only (not Polygon) |
| `wa_*.cpp` | Local hack testing only (not Polygon) |
| `tle_*.cpp` | Local hack testing only (not Polygon) |

`testlib.h` is pre-available in Polygon — do not upload it. For local testing:
`https://raw.githubusercontent.com/MikeMirzayanov/testlib/refs/heads/master/testlib.h`

---

## Step 1 — Parse the Problem Statement

Read the statement carefully (Markdown or LaTeX). Extract:

- **Input format**: variable names, structure, exact reading order
- **Constraints**: every bound (N ≤ ?, 1 ≤ aᵢ ≤ ?, etc.)
- **Multiple test cases?** If the first line is T, note it — handle T-wrapping in all generators
- **Output spec**: unique answer, any valid answer, yes/no, floating point — decide if the answer is unique. A **custom checker** is needed whenever multiple outputs are valid: printing an actual path/assignment/permutation (not just its cost), any-valid-answer constructive problems, floating point with tolerance. If a checker is needed, note it but don't generate it — it's too problem-specific. For the rest of this skill, assume the checker question is already settled.
- **Problem type**: see heuristics table at the end

---

## Step 2 — Classify Solutions

Identify every provided file by name and content:

| Role | Common names |
|------|-------------|
| Model solution (authoritative) | `ac`, `main_sol`, `model`, `solution`, `sol`, `correct` |
| Brute force (slow but correct) | `brute`, `slow`, `naive`, `bf`, `n2`, `n3` |
| Wrong solutions (intentionally bad) | `wa`, `tle`, `mle`, `wrong`, `hack`, `bad` |

Wrong solutions tell you what the test suite must catch. If no brute force is provided, write one (see Step 6).

---

## Step 3 — Write gen_edge.cpp

Generates deterministic edge and corner cases. Takes a single `subtype` argument.

```cpp
#include "testlib.h"
#include <bits/stdc++.h>
using namespace std;

const int MAXN   = /* from problem */;
const int MINVAL = /* from problem */;
const int MAXVAL = /* from problem */;

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int subtype = argc > 1 ? atoi(argv[1]) : 0;

    // subtype 0: N = 1 (minimum)
    // subtype 1: N = MAXN, all values = MINVAL
    // subtype 2: N = MAXN, all values = MAXVAL
    // subtype 3: N = MAXN, sorted ascending
    // subtype 4: N = MAXN, sorted descending
    // subtype 5: N = MAXN, all values identical (random value)
    // + problem-specific edges (see heuristics)
    
    // generate and print...
    return 0;
}
```

Use `rnd.next(lo, hi)` even for "deterministic" cases that need a random value within a fixed structural pattern — this keeps tests reproducible via the seed baked into `registerGen`.

---

## Step 4 — Write gen_random.cpp

Generates fully random tests across the constraint range. Takes `n` (or range bounds) as argument.

```cpp
#include "testlib.h"
#include <bits/stdc++.h>
using namespace std;

const int MAXN   = /* from problem */;
const int MINVAL = /* from problem */;
const int MAXVAL = /* from problem */;

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int n = argc > 1 ? atoi(argv[1]) : rnd.next(1, MAXN);

    // generate n, then generate n random values/edges/characters etc.
    // print in exact input format
    return 0;
}
```

In the test script, call it with different `n` values. To get multiple distinct tests at the same size, append a different trailing integer — `registerGen(argc, argv, 1)` seeds the RNG from **all** argv, so `gen_random 100000 1` and `gen_random 100000 2` produce completely different tests.

**Seed-vs-m collision:** if gen_random reads `argv[2]` as `m`, a trailing seed like `gen_random 10 2` will be parsed as n=10, m=2 — but the spanning tree alone needs n−1=9 edges, so the header would say m=2 while 9 lines follow, failing the validator. Fix this in the generator by clamping: `m = max(n - 1, atoi(argv[2]))`. This way the seed still changes the RNG while m is always legal, and explicit large-m calls (e.g. `gen_random 100000 200000 3`) work unchanged because 200000 ≥ n−1.

---

## Step 5 — Write gen_special.cpp

Generates problem-specific structural inputs that don't fit the generic edge/adversarial categories. Think about what *shapes* of input are mathematically meaningful for this problem — things that stress a particular property of the data rather than just "max size" or "sorted order".

```cpp
#include "testlib.h"
#include <bits/stdc++.h>
using namespace std;

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int subtype = argc > 1 ? atoi(argv[1]) : 0;

    // Examples (pick the ones relevant to the problem):
    // Trees:        complete binary tree, star, bamboo, Fibonacci-heavy-path, caterpillar
    // Strings:      all-distinct chars, pure palindrome, period-2 pattern, Thue-Morse sequence
    // Numbers:      all prime, all powers of 2, all Fibonacci, arithmetic progression
    // Graphs:       bipartite, complete bipartite, clique + isolated vertices, grid graph
    // Permutations: cyclic shift by K, bitonic (up then down), many fixed points

    return 0;
}
```

**Why this matters:** `gen_edge` covers generic bounds and `gen_adversarial` covers worst-case sizes, but neither targets the *algebraic/combinatorial structure* that many problem solutions depend on. A segment-tree solution might be fine on sorted input but break on a specific permutation pattern; a string DP might be fine on random text but explode on a period-2 string.

Aim for 4–6 subtypes. Each subtype should encode a distinct mathematical structure, not just a variation in size.

---

## Step 5b — Write gen_stress.cpp

Generates small-scale inputs (tiny N) specifically for stress testing against `brute.cpp`. These are not about finding bugs via structure — they're about volume: run thousands of small random cases so the probability of hitting any bug approaches 1.

```cpp
#include "testlib.h"
#include <bits/stdc++.h>
using namespace std;

const int STRESS_MAXN = /* something brute handles in <50ms, e.g. 10–20 */;
const int MINVAL = /* from problem */;
const int MAXVAL = /* from problem */;

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int n = argc > 1 ? atoi(argv[1]) : rnd.next(1, STRESS_MAXN);

    // Generate a small random valid input — same structure as gen_random
    // but capped at STRESS_MAXN so the brute runs instantly.
    return 0;
}
```

**Why separate from gen_random?** `gen_random` targets the full constraint range (large N). Using it for stress testing means either running brute on huge inputs (too slow) or manually shrinking N each time (error-prone). `gen_stress` bakes the small-N constraint in so the stress loop just calls `./gen_stress > test.in` with no extra arguments.

---

## Step 6 — Write gen_adversarial.cpp

Generates worst-case inputs designed to break naive solutions. Takes a `subtype` argument.

```cpp
#include "testlib.h"
#include <bits/stdc++.h>
using namespace std;

const int MAXN = /* from problem */;

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int subtype = argc > 1 ? atoi(argv[1]) : 0;

    // Always use maximum N.
    // subtype 0: worst case for O(N²) naive — e.g. sorted ascending
    // subtype 1: worst case for greedy — carefully constructed counter-example
    // subtype 2: problem-specific — e.g. bamboo tree, star graph, all-'a' string
    // ...

    return 0;
}
```

See the heuristics table for what adversarial cases to generate per problem type. Think about what the **wrong/TLE solutions** would fail on and target those.

### Edge ordering in graph generators

For graph and tree problems, **the order edges are printed can silently neuter an adversarial test.** Bellman-Ford, for example, degrades from O(NM) to O(M) when edges happen to be in topological order — one pass relaxes every node at once, so it finishes in milliseconds on a case intended to TLE it.

Rule: whenever a graph generator prints edges in a structured sequence (chain 1→2→3→…→N, BFS/DFS order, spanning tree order), either shuffle them or print them in reverse:

```cpp
// Option A — shuffle with rnd so the order is reproducible but non-topological
shuffle(edges.begin(), edges.end());
for (auto [u, v] : edges) cout << u << " " << v << " " << w << "\n";

// Option B — reverse order for a bamboo (forces N-1 Bellman-Ford rounds)
for (int i = n - 1; i >= 1; i--)
    cout << i << " " << (i + 1) << " " << w << "\n";
```

After writing any adversarial generator, verify the TLE solution actually TLEs:

```bash
timeout 3 ./tle_solution < adversarial_input && echo "FAIL: did not TLE" || echo "OK: TLE confirmed"
```

If it finishes in time, the generator is producing an accidentally easy ordering.

### Connectivity and reachability

`gen_random` always builds a spanning tree first, so node N is reachable. `gen_adversarial` and `gen_special` have no such guarantee — you must enforce reachability explicitly, or you'll produce accidental -1 tests.

- **If the problem can output -1** (unreachable / impossible): include at least one disconnected adversarial case intentionally, and verify your other cases are connected by checking the output of `./sol` is not -1 unexpectedly.
- **If the problem never outputs -1** (always a path exists): every generator must guarantee reachability. For chain/bamboo generators this is automatic; for generators that add edges randomly, start from a spanning tree as gen_random does before adding extra edges.

---

## Step 7 — Write Wrong/TLE Solutions

Always produce at least four "bad" solutions for stress testing. These are not uploaded to Polygon — they're for local correctness and performance verification.

### brute.cpp
Write a simple, obviously-correct but slow solution. Aim for the simplest possible approach regardless of complexity. Correctness is the only goal here — complexity doesn't matter.

- For sequence problems: O(N²) or O(N³) scan
- For graph problems: Floyd-Warshall or exponential DFS
- For string problems: O(N²) substring check

```cpp
// brute.cpp — O(?) brute force, correct but slow
// Use for stress testing: diff <(./sol < test) <(./brute < test)
#include <bits/stdc++.h>
using namespace std;
int main() {
    // simplest possible correct implementation
}
```

### wa_*.cpp — Wrong Answer Solutions (3–4 files)

Write 3–4 solutions that each implement a *distinct* common wrong approach for this problem type. Variety matters: if all your WA solutions fail on the same class of input, you're only testing one thing. Cover different failure modes.

Good sources for wrong approaches:
- A greedy that picks locally optimal without lookahead
- A DP with wrong base case or transition
- An approach that mishandles edge cases (empty input, N=1, overflow)
- A solution that's correct on random inputs but wrong on a specific structure (all-equal values, sorted/reverse, graph with multiple components)
- Correct algorithm, wrong implementation detail (e.g., off-by-one in binary search, wrong modular arithmetic)

Name clearly: `wa_greedy.cpp`, `wa_dp.cpp`, `wa_overflow.cpp`, `wa_edge.cpp`, etc.

```cpp
// wa_greedy.cpp — WRONG: [describe the mistake in one line]
// Fails on: [describe what kind of input breaks it]
// To expose: gen_special 2 or gen_edge 5
#include <bits/stdc++.h>
using namespace std;
int main() {
    // wrong implementation
}
```

The comment headers are important — they establish a direct contract between the wrong solution and the test cases that must exist to catch it. Add a "To expose:" line pointing to which generator subtype will produce the failing input.

### tle_*.cpp — TLE Solutions (1–2 files)

Write 1–2 solutions with **correct logic but too-high complexity** — the kind of solution a contestant might actually submit thinking it's fast enough. These differ from `brute.cpp` in intent: `brute` is for stress-testing correctness; `tle` solutions model realistic contestant mistakes.

Good TLE candidates:
- O(N² log N) when the correct bound requires O(N log N)
- O(N · sqrt(N)) when O(N log N) is needed
- A correct DP with an extra unneeded loop that multiplies complexity by N
- Using `std::set`/`std::map` operations in a tight inner loop when a hash-map or sorted array suffices
- Correct BFS/DFS but rebuilding the adjacency list on every call

```cpp
// tle_n2.cpp — CORRECT but O(N²): [describe the approach]
// TLEs on: N ≥ [threshold] — triggers with gen_adversarial 0 or gen_random MAXN
#include <bits/stdc++.h>
using namespace std;
int main() {
    // correct but slow implementation
}
```

**Why write TLE solutions?** They confirm your large-N test cases are actually stressful — if a TLE solution passes all your Polygon tests, your test suite has a gap.

---

## Step 8 — Write validator.cpp

```cpp
#include "testlib.h"
using namespace std;

int main(int argc, char* argv[]) {
    registerValidation(argc, argv);

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

The validator is the canonical spec of valid input — write it carefully. For graphs, check no self-loops, no parallel edges, and optionally connectivity (Union-Find).

---

## Step 9 — Hand-crafted Test Files

Write 3+ static test files for critical deterministic cases (name without extension):

- `01` — minimum valid input (N=1 or simplest possible)
- `02` — maximum N, all maximum values
- `03` — maximum N, all minimum values
- More if the problem has problem-specific must-have cases

---

## Step 10 — Test Script (script.txt)

### Seeding rule — read this first

`registerGen(argc, argv, 1)` seeds the RNG from **all** command-line arguments concatenated. Two script lines with identical arguments run the generator with the same seed and produce **identical tests**. To get distinct outputs, append a different trailing token (an integer or short string) to each repeated call:

```
gen_random 100000 1 > $   # seed differs from line below
gen_random 100000 2 > $   # different output, same n
gen_random 100000 3 > $   # different output again
```

The generator doesn't need to read `argv[2]` — testlib uses it purely for seeding. This rule applies to every generator in the script. **Never repeat the same `generator args` on two lines without a distinct trailing seed.**

Generators that produce fully deterministic output (never call `rnd`) are immune — adding extra args changes nothing since `rnd` is never used — so call them only once per subtype.

### Example script

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

Adjust the number of `gen_special` and `gen_adversarial` calls to match the subtypes you actually implemented.

---

## Step 11 — Local Stress Test Script

Provide this if a brute force exists (provided or generated):

```bash
g++ -O2 -std=c++17 -o gen_stress   gen_stress.cpp
g++ -O2 -std=c++17 -o sol          solution.cpp
g++ -O2 -std=c++17 -o brute        brute.cpp

for i in $(seq 1 1000); do
    ./gen_stress > test.in
    ./sol   < test.in > out_sol.txt
    ./brute < test.in > out_brute.txt
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

Use `gen_stress` (not `gen_random`) for stress testing so brute force can keep up. Run more iterations (1000+) since each case is tiny and fast.

---

## Problem-Type Heuristics

| Type | Signals | Edge subtypes | Adversarial subtypes |
|------|---------|--------------|----------------------|
| Array/sequence | "N integers", "sequence" | min/max/sorted/reverse/all-equal | sorted asc (breaks O(N²)), all-equal |
| Permutation | "permutation of 1..N" | identity, reverse, random | cyclic shift, reverse |
| Graph | "N nodes M edges" | N=2, tree (M=N-1), complete (M=N*(N-1)/2), star | star, path/chain, bipartite |
| Tree | "N nodes, N-1 edges" | N=2, chain (bamboo), star, single path | bamboo (depth=N, breaks recursion), star |
| String | "string of length N" | N=1, all 'a', all 'z', alternating "ab…", full palindrome | all 'a' (max palindromic partitions), "abababab…" |
| Grid | "N×M grid" | 1×M, N×1, checkerboard, all same | all same char, checkerboard |
| Geometry | "N points" | N=1, all collinear, convex hull | collinear (breaks some convex hull), all same point |
| Multiple T-cases | "first line T" | max T min-N cases; one max-N single case | max T, each case adversarial |

For **tree** problems: always include bamboo (chain of N nodes). Recursive solutions that don't iteratively DFS will stack-overflow on this.

For **graph** problems: always include a path graph and a star. If M allows it, include a near-complete graph.

---

## Common Wrong/TLE Solution Patterns

### Wrong Answer patterns (wa_*.cpp)

| Problem type | Common wrong approach | Breaks on |
|-------------|----------------------|-----------|
| Sorting/searching | Greedy picks local minimum without lookahead | Carefully constructed anti-greedy input |
| DP | Wrong base case (dp[0]=1 when it should be 0) | Small inputs near the base case |
| Graph shortest path | BFS on weighted graph (correct for unit weights only) | Graph with varying edge weights |
| MST | Always picking cheapest edge from node 1 (wrong Prim) | Non-trivial MST structure |
| String | Not handling overlapping patterns, off-by-one in indices | Strings with many overlapping occurrences |
| Geometry | Not handling collinear/degenerate cases | All-collinear point sets |
| Counting | Forgetting modular arithmetic, overflow with int instead of long long | Large values near INT_MAX |
| Graph/Tree | Assuming connected input without checking | Disconnected graph |
| Binary search | Wrong predicate direction or off-by-one in lo/hi | Boundary answer at lo or hi |

### TLE patterns (tle_*.cpp)

| Problem type | TLE approach | Correct complexity | TLE complexity |
|-------------|-------------|-------------------|----------------|
| Sequence queries | Recompute from scratch for each query | O(N + Q) with prefix sums | O(N·Q) |
| Sorting-based | Insertion sort or selection sort | O(N log N) | O(N²) |
| Graph BFS/DFS | Rebuild adjacency list every call | O(N + M) once | O(N·(N + M)) |
| String matching | Naive double loop | O(N) KMP/Z-function | O(N²) |
| DP with transitions | Extra loop over all states for each transition | O(N log N) with monotone deque | O(N²) |
| Segment tree | Iterate all elements for range query | O(log N) per query | O(N) per query |
| Number theory | Trial division in inner loop | O(sqrt(N)) per number | O(N) per number |

---

## Final Checklist

- [ ] All five generator files compile: `g++ -O2 gen_edge.cpp -o gen_edge` etc.
- [ ] `validator.cpp` reads input in exact format — no extra/missing spaces or newlines
- [ ] Hand-crafted tests `01`, `02`, `03` pass the validator
- [ ] `script.txt` references `gen_edge`, `gen_random`, `gen_adversarial`, `gen_special` (not bare `gen`)
- [ ] No two lines in `script.txt` share the same generator name + arguments — every repeated call has a distinct trailing seed integer (e.g., `gen_random 100000 1`, `gen_random 100000 2`)
- [ ] `gen_random` clamps m to `max(n-1, atoi(argv[2]))` so seed suffixes never produce an invalid edge count in the header
- [ ] `gen_special` subtypes each encode a distinct structural shape, not just a size variation
- [ ] `gen_stress` caps N at a value brute handles in under 50ms
- [ ] `brute.cpp` gives correct output but is slow enough to need stress testing
- [ ] 3–4 `wa_*.cpp` files — each targets a distinct failure mode, has "Fails on:" and "To expose:" comment headers
- [ ] 1–2 `tle_*.cpp` files — correct logic, wrong complexity; "TLEs on:" header says what input triggers it
- [ ] Each TLE solution verified locally: `timeout <TL> ./tle_x < adversarial_input` exits non-zero
- [ ] Graph/tree generators: edges are shuffled with `rnd` or printed in reverse topological order — never bare sequential order
- [ ] Every `gen_adversarial` and `gen_special` subtype either guarantees node N is reachable or is intentionally testing the -1 case
- [ ] Constraints in all generator files match the problem statement exactly
