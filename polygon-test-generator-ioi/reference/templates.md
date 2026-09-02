# Code templates

Full templates for every file the skill produces. `MAXN_ST` mirrors the subtask table from Step 1; `MINVAL` and `MAXVAL` come from the statement.

## generators/gen_edge.cpp

Deterministic edge and corner cases. Takes `subtask` and `subtype`.

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

`gen_edge 1 0` produces a tiny N=1 case for subtask 1; `gen_edge 4 1` produces a max-N edge case for the final subtask.

## generators/gen_random.cpp

Random tests within a subtask's constraint range. Takes `subtask`, `n` (optional), and a seed.

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
    // If an edge count m is read from argv, clamp it: m = max(n - 1, atoi(argv[k]))

    // Generate n, then values/edges/etc. within subtask constraints.
    // Subtask-specific structural constraints (e.g. "all aᵢ equal" for subtask 3) are
    // enforced here, not just the size bound.
    return 0;
}
```

## generators/gen_special.cpp

Structural inputs with mathematical shapes. Takes `subtask` and `subtype`.

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

    // Trees:        complete binary tree, star, bamboo, caterpillar
    // Strings:      pure palindrome, period-2 pattern, Thue-Morse
    // Numbers:      all prime, all powers of 2, arithmetic progression
    // Graphs:       bipartite, complete bipartite, grid graph
    // Permutations: cyclic shift, bitonic, many fixed points

    return 0;
}
```

Aim for 4–6 subtypes. For the maximum-constraint subtask use the last `MAXN_ST` entry; for earlier subtasks cap to their bounds.

## generators/gen_stress.cpp

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
    // Subtask-specific structural constraints are NOT enforced here: the stress loop
    // should explore the full valid space even if it crosses subtask boundaries.
    return 0;
}
```

## generators/gen_adversarial.cpp

Worst-case inputs designed to break naive solutions. Takes `subtask` and `subtype`, always at the subtask's maximum N.

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

    // subtype 0: worst case for O(N²) naive — sorted ascending
    // subtype 1: worst case for greedy — carefully constructed counter-example
    // subtype 2+: problem-specific

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

## generators/gen_manual.cpp

Emits each hand-crafted `stK/xx` file verbatim so `script.txt` can place it. Generate this file programmatically from the `stK/` directories rather than retyping the tests.

```cpp
// gen_manual.cpp — emits a hand-crafted test verbatim.
// Usage: gen_manual <subtask> <index>   e.g. gen_manual 1 2  ->  st1/02
#include "testlib.h"
#include <bits/stdc++.h>
using namespace std;
int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int st = atoi(argv[1]), idx = atoi(argv[2]);
    map<pair<int, int>, string> tests;
    tests[{1, 1}] = R"(<contents of st1/01>)";
    // … one entry per hand-crafted file
    auto it = tests.find({st, idx});
    ensuref(it != tests.end(), "no hand-crafted test for subtask %d index %d", st, idx);
    printf("%s", it->second.c_str());
    return 0;
}
```

## solutions/brute.cpp

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

## solutions/sol_st1.cpp

```cpp
// sol_st1.cpp — Passes subtask 1 (N ≤ 10) ONLY
// Algorithm: [name the algorithm]
// Why it fails subtask 2+: [TLE at O(N³), or missing case for larger N, etc.]
#include <bits/stdc++.h>
using namespace std;
int main() { /* ... */ }
```

## solutions/sol_st1_2.cpp

```cpp
// sol_st1_2.cpp — Passes subtasks 1–2 (N ≤ 1000) ONLY
// Algorithm: [e.g., O(N²) DP]
// Why it fails subtask 3+: [TLE at N=5000, or missing structural subtask constraint]
#include <bits/stdc++.h>
using namespace std;
int main() { /* ... */ }
```

## solutions/sol_st1_2_3.cpp (4+ subtasks only)

```cpp
// sol_st1_2_3.cpp — Passes subtasks 1–3 ONLY
// Algorithm: [e.g., O(N log² N)]
// Why it fails subtask 4+: [explain the gap]
#include <bits/stdc++.h>
using namespace std;
int main() { /* ... */ }
```

## solutions/wa_*.cpp

```cpp
// wa_greedy.cpp — WRONG: [describe the mistake in one line]
// Fails on: [describe what kind of input breaks it]
// To expose: gen_special 4 2 or gen_edge 4 5
#include <bits/stdc++.h>
using namespace std;
int main() { /* ... */ }
```

## solutions/tle_*.cpp

```cpp
// tle_n2.cpp — CORRECT but O(N²): [describe the approach]
// TLEs on: N ≥ [threshold] — triggers with gen_adversarial 4 0
// Passes: subtask 1 and 2 (same as sol_st1_2.cpp but written independently)
#include <bits/stdc++.h>
using namespace std;
int main() { /* ... */ }
```

## validator.cpp (package root)

```cpp
#include "testlib.h"
using namespace std;

int main(int argc, char* argv[]) {
    registerValidation(argc, argv);

    // Polygon passes the group: validator --group=<k> --testset=tests
    string group = validator.group();
    int st = group.empty() ? 0 : stoi(group);

    // Read input exactly as the problem specifies.
    //   inf.readInt(lo, hi, "name")      — integer with bounds check
    //   inf.readLong(lo, hi, "name")     — long long
    //   inf.readToken("[a-z]+", "name")  — string matching regex
    //   inf.readSpace()                  — assert ' '
    //   inf.readEoln()                   — assert '\n'
    //   inf.readEof()                    — assert end of file

    // Per-group constraint checks after reading, one per subtask:
    //   if (st == 1) ensuref(n <= 10,   "subtask 1: n must be <= 10");
    //   if (st == 2) ensuref(n <= 1000, "subtask 2: n must be <= 1000");
    //   if (st == 3) ensuref(allEqual,  "subtask 3: all values must be equal");
    return 0;
}
```
