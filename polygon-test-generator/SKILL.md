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
| `validator.cpp` | Files → Source Files (validator) |
| `01`, `02`, `03`, … | Tests → Add Test (manual) |
| `script.txt` | Tests → Test Script (copy-paste) |
| `brute.cpp` | Local stress testing only (not Polygon) |
| `wa_*.cpp` | Local hack testing only (not Polygon) |

`testlib.h` is pre-available in Polygon — do not upload it. For local testing:
`https://raw.githubusercontent.com/MikeMirzayanov/testlib/refs/heads/master/testlib.h`

---

## Step 1 — Parse the Problem Statement

Read the statement carefully (Markdown or LaTeX). Extract:

- **Input format**: variable names, structure, exact reading order
- **Constraints**: every bound (N ≤ ?, 1 ≤ aᵢ ≤ ?, etc.)
- **Multiple test cases?** If the first line is T, note it — handle T-wrapping in all generators
- **Output spec**: unique answer, any valid answer, yes/no, floating point — if multiple valid outputs exist, note that a custom checker would be needed (don't generate it; it's too problem-specific)
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

In the test script, call it with different `n` values and Polygon auto-varies the seed, covering the space well.

---

## Step 5 — Write gen_adversarial.cpp

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

---

## Step 6 — Write Wrong/TLE Solutions

Always produce at least two "bad" solutions for stress testing. These are not uploaded to Polygon — they're for local correctness and performance verification.

### brute.cpp
Write a simple, obviously-correct but slow solution. Aim for the simplest possible approach regardless of complexity:
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

### wa_*.cpp
Write 1–2 solutions that implement common wrong approaches for this problem type. The wrong approach should be something a contestant might actually write:
- A greedy that doesn't account for an edge case
- A DP with wrong base case or transition
- An approach that fails on specific structural inputs (all-same values, sorted input, etc.)

Name clearly: `wa_greedy.cpp`, `wa_dp.cpp`, etc.

```cpp
// wa_greedy.cpp — WRONG: [describe the mistake in one line]
// Fails on: [describe what kind of input breaks it]
#include <bits/stdc++.h>
using namespace std;
int main() {
    // wrong implementation
}
```

The comment headers are important — they tell you what tests need to exist to catch the bug.

---

## Step 7 — Write validator.cpp

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

## Step 8 — Hand-crafted Test Files

Write 3+ static test files for critical deterministic cases (name without extension):

- `01` — minimum valid input (N=1 or simplest possible)
- `02` — maximum N, all maximum values
- `03` — maximum N, all minimum values
- More if the problem has problem-specific must-have cases

---

## Step 9 — Test Script (script.txt)

```
# Manual tests 01, 02, 03 are uploaded separately

# Edge cases
gen_edge 0 > $
gen_edge 1 > $
gen_edge 2 > $
gen_edge 3 > $
gen_edge 4 > $
gen_edge 5 > $

# Random — small to large
gen_random 10 > $
gen_random 100 > $
gen_random 1000 > $
gen_random MAXN > $
gen_random MAXN > $
gen_random MAXN > $

# Adversarial
gen_adversarial 0 > $
gen_adversarial 1 > $
gen_adversarial 2 > $
```

Polygon auto-seeds each line differently, so repeated `gen_random MAXN > $` lines produce distinct tests.

---

## Step 10 — Local Stress Test Script

Provide this if a brute force exists (provided or generated):

```bash
g++ -O2 -std=c++17 -o gen_random   gen_random.cpp
g++ -O2 -std=c++17 -o sol          solution.cpp
g++ -O2 -std=c++17 -o brute        brute.cpp

for i in $(seq 1 300); do
    ./gen_random $((RANDOM % 50 + 2)) > test.in
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

Adjust the size range to something brute can handle in under 1 second.

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

## Common Wrong Solution Patterns (to write as wa_*.cpp)

| Problem type | Common wrong approach |
|-------------|----------------------|
| Sorting/searching | Greedy that picks local minimum without lookahead |
| DP | Wrong base case (e.g., dp[0]=1 when it should be 0) |
| Graph shortest path | BFS on weighted graph (correct only for unit weights) |
| MST | Always picking cheapest edge from node 1 (wrong Prim) |
| String | Not handling overlapping patterns, off-by-one in indices |
| Geometry | Not handling collinear/degenerate cases |
| Counting | Forgetting modular arithmetic, overflow with int instead of long long |

---

## Final Checklist

- [ ] All three generator files compile: `g++ -O2 gen_edge.cpp -o gen_edge` etc.
- [ ] `validator.cpp` reads input in exact format — no extra/missing spaces or newlines
- [ ] Hand-crafted tests `01`, `02`, `03` pass the validator
- [ ] `script.txt` references `gen_edge`, `gen_random`, `gen_adversarial` (not `gen`)
- [ ] `brute.cpp` gives correct output but is slow enough to need stress testing
- [ ] `wa_*.cpp` files have a comment explaining exactly what's wrong and what input breaks them
- [ ] Constraints in all generator files match the problem statement exactly

