# Code templates

Full templates for every file the skill produces. `MAXN`, `MINVAL`, `MAXVAL` come from the problem statement.

## gen_edge.cpp

Deterministic edge and corner cases. Takes a single `subtype` argument.

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
    // + problem-specific edges (see patterns.md)

    // generate and print...
    return 0;
}
```

Use `rnd.next(lo, hi)` for any random value inside a fixed structural pattern; the seed baked into `registerGen` keeps the test reproducible.

## gen_random.cpp

Fully random tests across the constraint range. Takes `n` (or range bounds) as argument; extra trailing arguments only change the seed.

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
    // If the generator also reads an edge count from argv[2], clamp it so a trailing
    // seed token can never produce an invalid header:
    //   int m = argc > 2 ? max(n - 1, atoi(argv[2])) : rnd.next(n - 1, MAXM);

    // generate n, then n random values / edges / characters, in the exact input format
    return 0;
}
```

## gen_special.cpp

Problem-specific structural inputs. Each subtype encodes a distinct mathematical structure, not a size variation.

```cpp
#include "testlib.h"
#include <bits/stdc++.h>
using namespace std;

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int subtype = argc > 1 ? atoi(argv[1]) : 0;

    // Pick the shapes relevant to the problem:
    // Trees:        complete binary tree, star, bamboo, Fibonacci-heavy-path, caterpillar
    // Strings:      all-distinct chars, pure palindrome, period-2 pattern, Thue-Morse sequence
    // Numbers:      all prime, all powers of 2, all Fibonacci, arithmetic progression
    // Graphs:       bipartite, complete bipartite, clique + isolated vertices, grid graph
    // Permutations: cyclic shift by K, bitonic (up then down), many fixed points

    return 0;
}
```

A segment-tree solution can be fine on sorted input and break on a specific permutation pattern; a string DP can be fine on random text and explode on a period-2 string. Aim for 4–6 subtypes.

## gen_stress.cpp

Small inputs for stress testing against `brute.cpp`. Volume, not structure: thousands of tiny cases so the probability of hitting any bug approaches 1.

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

    // Same structure as gen_random but capped at STRESS_MAXN so the brute runs instantly.
    return 0;
}
```

## gen_adversarial.cpp

Worst-case inputs designed to break naive solutions. Takes a `subtype` argument and always uses maximum N.

```cpp
#include "testlib.h"
#include <bits/stdc++.h>
using namespace std;

const int MAXN = /* from problem */;

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int subtype = argc > 1 ? atoi(argv[1]) : 0;

    // subtype 0: worst case for O(N²) naive — e.g. sorted ascending
    // subtype 1: worst case for greedy — carefully constructed counter-example
    // subtype 2: problem-specific — e.g. bamboo tree, star graph, all-'a' string
    // ...

    return 0;
}
```

Edge ordering for graph and tree generators, so a structured sequence never lands in topological order:

```cpp
// Option A — shuffle with rnd so the order is reproducible but non-topological
shuffle(edges.begin(), edges.end());
for (auto [u, v] : edges) cout << u << " " << v << " " << w << "\n";

// Option B — reverse order for a bamboo (forces N-1 Bellman-Ford rounds)
for (int i = n - 1; i >= 1; i--)
    cout << i << " " << (i + 1) << " " << w << "\n";
```

Confirm the effect after writing each adversarial subtype:

```bash
timeout 3 ./tle_solution < adversarial_input && echo "FAIL: did not TLE" || echo "OK: TLE confirmed"
```

## brute.cpp

```cpp
// brute.cpp — O(?) brute force, correct but slow
// Use for stress testing: diff <(./sol < test) <(./brute < test)
#include <bits/stdc++.h>
using namespace std;
int main() {
    // simplest possible correct implementation, no regard for complexity
}
```

## wa_*.cpp

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

## tle_*.cpp

```cpp
// tle_n2.cpp — CORRECT but O(N²): [describe the approach]
// TLEs on: N ≥ [threshold] — triggers with gen_adversarial 0 or gen_random MAXN
#include <bits/stdc++.h>
using namespace std;
int main() {
    // correct but slow implementation
}
```

## validator.cpp

```cpp
#include "testlib.h"
using namespace std;

int main(int argc, char* argv[]) {
    registerValidation(argc, argv);

    // Read input exactly as the problem specifies.
    //   inf.readInt(lo, hi, "name")      — integer with bounds check
    //   inf.readLong(lo, hi, "name")     — long long
    //   inf.readToken("[a-z]+", "name")  — string matching regex
    //   inf.readSpace()                  — assert ' '
    //   inf.readEoln()                   — assert '\n'
    //   inf.readEof()                    — assert end of file

    // Graphs: reject self-loops and parallel edges; check connectivity (union-find)
    // when the statement guarantees it.
    return 0;
}
```
