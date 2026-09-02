---
name: polygon-test-generator-ioi
description: Generate IOI-style test data with subtasks for a competitive programming problem, authored for upload to Codeforces Polygon, producing subtask-aware testlib.h generators, a group-aware validator, hand-crafted tests per subtask embedded through gen_manual, a partial-solution ladder (sol_st1, sol_st1_2, …), wrong/TLE solutions, a script.txt with @N group markers, empirically derived Polygon solution tags, and an UPLOAD.md click-through checklist. Use when the problem has subtasks with partial scoring or the user asks for IOI/CMS-style tests.
when_to_use: Trigger phrases include "IOI", "CMS", "subtasks", "partial scoring", "task groups", or "generate tests" for a statement that lists subtask constraints. For plain Polygon tests use polygon-test-generator; for cafe-grader per-test scoring use polygon-test-generator-cafe.
---

# IOI Test Generator

Produce a complete, verified IOI-style package from a problem statement (Markdown or LaTeX) and the provided solutions. IOI scoring is per subtask: a contestant earns a subtask's points only when every test in that group passes, so the package is organized around subtasks from the first step to the upload checklist.

Keep the user informed as you go: show the subtask table before generating anything, give a one-line update as each stage completes, and close with a recap that lists every produced file, the solution tag table, and any verification that failed or was skipped. Deliver the whole package in one pass; if a part cannot be produced (for example, a custom checker), say so in the recap instead of stopping early.

## What you produce

| Path | Purpose |
|------|---------|
| `generators/gen_edge.cpp` | Edge and corner cases, subtask-aware |
| `generators/gen_random.cpp` | Random tests within a subtask's constraints |
| `generators/gen_special.cpp` | Structural shapes (algebraic/combinatorial) |
| `generators/gen_adversarial.cpp` | Worst-case inputs per subtask |
| `generators/gen_stress.cpp` | Tiny tests for the stress loop |
| `generators/gen_manual.cpp` | Emits each hand-crafted test verbatim so `script.txt` can list every test |
| `validator.cpp` | Validates input and checks per-group constraints |
| `st1/01`, `st1/02`, … `stK/…` | Hand-crafted tests per subtask (source of truth, embedded in `gen_manual`) |
| `script.txt` | Test script with `@N` group markers |
| `solutions/sol.cpp` | Model solution, full score |
| `solutions/brute.cpp` | Correct but slow |
| `solutions/sol_st1.cpp`, `sol_st1_2.cpp`, `sol_st1_2_3.cpp` | Partial ladder: passes subtasks 1, 1–2, 1–3 (the last only with 4+ subtasks) |
| `solutions/wa_*.cpp` | 3–4 wrong-answer solutions with distinct failure modes |
| `solutions/tle_*.cpp` | 1–2 correct-but-slow solutions |
| `UPLOAD.md` | Click-through upload checklist: every file, where it goes, which tag |

```
problem/
├── generators/     # every gen_*.cpp
├── solutions/      # model + brute + partial ladder + wa_* + tle_*
├── validator.cpp   # package root: Polygon has its own upload slot for it
├── st1/ … stK/     # hand-crafted tests per subtask
├── script.txt
└── UPLOAD.md
```

Generators and solutions live in their own directories so each set can be bulk-uploaded to Polygon in one go. Compiled binaries and generated tests go in a local `build/` directory, kept out of the source directories. `script.txt` refers to generators by bare name (`gen_edge …`) because Polygon resolves uploaded generators by name. `testlib.h` is already available in Polygon, so it is not uploaded; for local builds download it from `https://raw.githubusercontent.com/MikeMirzayanov/testlib/refs/heads/master/testlib.h`.

## Step 1 — Define the subtasks

Everything else is built on the subtask table, so settle it first. Read every "Subtask" or "Constraints" section and produce:

| Subtask | Points | Additional constraints |
|---------|--------|----------------------|
| 1 | p₁ | N ≤ 10 |
| 2 | p₂ | N ≤ 1 000 |
| 3 | p₃ | All aᵢ equal |
| 4 | p₄ | No further constraints (N ≤ 100 000) |

Subtasks are cumulative: a subtask-k test is also a valid subtask k−1 input, unless the statement says otherwise (for example "exactly k distinct values"). The final subtask is the full constraint set.

IOI problems typically have 4–6 subtasks. If the statement has only 2–3, add intermediate subtasks at natural complexity boundaries: after the brute-force bound (N ≤ 10 or N ≤ 100), after the quadratic bound (N ≤ 3 000–5 000), after the N log N bound (N ≤ 100 000), plus any problem-specific structural subtask ("tree is a path", "all values distinct", "graph is bipartite"). Show the final table to the user before writing generators.

## Step 2 — Parse the problem statement

Extract:

- **Input format**: variable names, structure, exact reading order.
- **Full constraints**: every bound across all subtasks.
- **Multiple test cases**: if the first line is T, every generator wraps its output in T cases.
- **Output spec**: decide whether the answer is unique. A custom checker is needed when several outputs are valid (printing a path, assignment, or permutation rather than its cost; any-valid-answer constructive problems; floating point with tolerance). Note that one is needed but do not write it; it is too problem-specific for this skill.
- **Problem type**: match against [reference/patterns.md](reference/patterns.md) to choose edge and adversarial shapes.

## Step 3 — Classify the provided solutions

| Role | Common names |
|------|-------------|
| Model solution (full) | `ac`, `main_sol`, `model`, `solution`, `sol`, `correct` |
| Brute force | `brute`, `slow`, `naive`, `bf`, `n2`, `n3` |
| Wrong solutions | `wa`, `tle`, `mle`, `wrong`, `hack`, `bad` |

If no brute force is provided, write one in Step 5.

## Step 4 — Write the generators

Every generator except `gen_stress` and `gen_manual` takes the subtask as its first argument and caps N with a per-subtask table that mirrors Step 1 exactly. Full templates with comment scaffolds are in [reference/templates.md](reference/templates.md).

```cpp
#include "testlib.h"
#include <bits/stdc++.h>
using namespace std;

const int MAXN_ST[] = {0, 10, 1000, 5000, 100000};  // index 0 unused; match the subtask table

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int st      = argc > 1 ? atoi(argv[1]) : 4;   // subtask
    int subtype = argc > 2 ? atoi(argv[2]) : 0;   // or n for gen_random
    int MAXN    = MAXN_ST[st];
    // build an input that satisfies every constraint of subtask st, then print it
    return 0;
}
```

| Generator | Arguments | Produces |
|-----------|-----------|----------|
| `gen_edge` | `st subtype` | Deterministic corners at this subtask's bound: N=1; N=MAXN with all MINVAL, all MAXVAL, sorted ascending, sorted descending; then problem-specific edges. `gen_edge 1 0` is a tiny subtask-1 case, `gen_edge 4 1` a max-N case for the final subtask |
| `gen_random` | `st [n] [seed]` | Random inputs with `n = min(atoi(argv[2]), MAXN)` (random in range when omitted). Structural subtask constraints are enforced here too: if subtask 3 requires all values equal, `gen_random 3 500` produces all-equal values, not just N ≤ 500 |
| `gen_special` | `st subtype` | 4–6 structural shapes, each a distinct mathematical structure rather than a size variant (bamboo, star, caterpillar; palindromes, period-2 strings; all-prime, powers of 2; bipartite, grid; cyclic-shift or bitonic permutations) |
| `gen_stress` | `[n]` | Tiny inputs (STRESS_MAXN ≈ 8–15, whatever `brute` solves in under 50 ms). It explores the full valid space and deliberately ignores structural subtask constraints, because the stress loop is looking for any disagreement between `sol` and `brute` |
| `gen_adversarial` | `st subtype` | Maximum-N inputs for the subtask built to break naive solutions: the O(N²) killer, the anti-greedy counter-example, the problem-specific worst case. Aim each subtype at a specific `wa_*`, `tle_*`, or ladder solution |
| `gen_manual` | `st idx` | Prints hand-crafted test `st<st>/<idx>` verbatim (Step 8) |

Rules that are easy to get wrong:

- **Random values come from testlib's `rnd`** (`rnd.next(lo, hi)`), even inside an otherwise deterministic pattern. `registerGen` seeds `rnd` from the full argv, so every test is reproducible.
- **Seeding**: because the seed is derived from all arguments, `gen_random 4 100000 1` and `gen_random 4 100000 2` differ while two identical lines produce identical tests. Every repeated call in `script.txt` needs a distinct trailing token. Generators that never call `rnd` are fully deterministic, so call each of their subtypes once.
- **Seed vs. m collision**: if `gen_random` reads an edge count `m` from argv, a trailing seed could set m below n−1 and the validator would reject the header. Clamp with `m = max(n - 1, atoi(argv[k]))`.
- **Edge order in graph generators**: chain, BFS, or spanning-tree order can neuter an adversarial case (Bellman-Ford finishes in one pass on topologically ordered edges). Shuffle edges with testlib's `shuffle` or print a bamboo in reverse.
- **Reachability**: `gen_adversarial` and `gen_special` do not build a spanning tree automatically. If the problem never outputs −1, every subtype guarantees the required reachability; if −1 is legal, include one intentionally disconnected adversarial case.
- **Verify the TLE**: after writing an adversarial generator, run `timeout <TL> build/tle_x < input`; an exit code of 0 means the case is accidentally easy.

## Step 5 — Write the partial-solution ladder

This is the most IOI-specific part. Write one solution per subtask boundary; each passes every subtask up to k and is intentionally too slow or too specialized for k+1. Header templates are in [reference/templates.md](reference/templates.md).

| File | Passes | Typical algorithm |
|------|--------|-------------------|
| `solutions/brute.cpp` | Subtask 1, maybe 2 | Simplest obviously-correct approach, complexity irrelevant; also the stress-test oracle |
| `solutions/sol_st1.cpp` | Subtask 1 only | O(N^k) with large k, or a special case that only handles subtask 1's structure |
| `solutions/sol_st1_2.cpp` | Subtasks 1–2 | Usually O(N²) |
| `solutions/sol_st1_2_3.cpp` | Subtasks 1–3 (only with 4+ subtasks) | The "good but not full" contestant submission, e.g. O(N log² N) |

| Subtask | Typical N limit | Algorithm class |
|---------|----------------|-----------------|
| 1 | ≤ 10–100 | Brute force / O(N^k) |
| 2 | ≤ 1 000–3 000 | O(N²) DP or O(N² log N) |
| 3 | ≤ 10 000–50 000 | O(N log N) or O(N√N) |
| 4 (full) | ≤ 100 000–500 000 | O(N log N) or better |

For a structural subtask ("tree is a path"), write the specialized solution that handles only that structure and breaks on a general input. Each ladder file's header states the algorithm and why it fails the next subtask:

```cpp
// sol_st1_2.cpp — Passes subtasks 1–2 (N ≤ 1000) ONLY
// Algorithm: [e.g., O(N²) DP]
// Why it fails subtask 3+: [TLE at N=5000, or missing structural constraint]
```

## Step 6 — Write wrong and TLE solutions

- **`solutions/wa_*.cpp`** (3–4 files): each implements a *different* wrong approach so the suite is tested against several failure modes: greedy without lookahead, DP with a wrong base case, mishandled edge cases, `int` overflow, binary-search off-by-one. Name by mistake: `wa_greedy.cpp`, `wa_overflow.cpp`, …
- **`solutions/tle_*.cpp`** (1–2 files): correct logic, too-high complexity, written independently of the ladder so it models a realistic contestant mistake.

Headers tie each file to the tests that expose it; the named generator subtype has to exist and has to make that solution fail:

```cpp
// wa_greedy.cpp — WRONG: [the mistake in one line]
// Fails on: [what kind of input breaks it]
// To expose: gen_special 4 2 or gen_edge 4 5
```

```cpp
// tle_n2.cpp — CORRECT but O(N²): [the approach]
// TLEs on: N ≥ [threshold] — triggers with gen_adversarial 4 0
// Passes: subtasks 1 and 2
```

Common wrong and slow approaches per problem type are listed in [reference/patterns.md](reference/patterns.md).

## Step 7 — Write validator.cpp

The validator sits at the package root because Polygon uploads it in its own slot. It reads the input exactly as the statement specifies and enforces the per-group bounds Polygon passes through `--group`:

```cpp
#include "testlib.h"
using namespace std;

int main(int argc, char* argv[]) {
    registerValidation(argc, argv);
    // Polygon runs: validator --group=<k> --testset=tests
    string group = validator.group();
    int st = group.empty() ? 0 : stoi(group);

    // inf.readInt(lo, hi, "name")      integer with bounds check
    // inf.readLong(lo, hi, "name")     long long
    // inf.readToken("[a-z]+", "name")  token matching a regex
    // inf.readSpace()  inf.readEoln()  inf.readEof()

    // per-group checks after reading the input, one per subtask, e.g.
    //   if (st == 1) ensuref(n <= 10,   "subtask 1: n must be <= 10");
    //   if (st == 2) ensuref(n <= 1000, "subtask 2: n must be <= 1000");
    return 0;
}
```

## Step 8 — Hand-crafted tests and gen_manual

Create one directory per subtask (`st1/`, `st2/`, …) with 2–3 static tests each, named without extension:

- `01`: minimum valid input within the subtask's constraints.
- `02`: maximum N for this subtask, all maximum values.
- `03`: the subtask's problem-specific must-have (for a "path graphs" subtask, the extremal path).

A test in `stK/` satisfies every constraint of subtask K, which makes it valid for subtasks 1 through K−1 as well.

These files are the human-readable source of truth, but they are not uploaded as Polygon manual tests. Polygon scripts cannot reference uploaded manual tests, and a manual test's group has to be set by hand in the UI, which is easy to get wrong and silently changes what that subtask verifies. Instead, generate `generators/gen_manual.cpp` programmatically from the `stK/` directories so each file is embedded verbatim:

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

Step 10 asserts that `gen_manual <st> <idx>` reproduces each `stK/xx` byte-for-byte so the two can never drift.

## Step 9 — Test script (script.txt)

`script.txt` lists every test, hand-crafted ones included. `@N` marks the start of group N; each block starts with that subtask's `gen_manual` lines so the hand-crafted tests land in the right group automatically.

```
@1
gen_manual 1 1 > $
gen_manual 1 2 > $
gen_manual 1 3 > $
gen_edge 1 0 > $
gen_edge 1 1 > $
gen_random 1 10 1 > $
gen_random 1 10 2 > $
gen_random 1 10 3 > $
@2
gen_manual 2 1 > $
gen_manual 2 2 > $
gen_edge 2 0 > $
gen_edge 2 1 > $
gen_random 2 500 1 > $
gen_random 2 1000 1 > $
gen_random 2 1000 2 > $
gen_adversarial 2 0 > $
@3
gen_manual 3 1 > $
gen_manual 3 2 > $
gen_edge 3 0 > $
gen_special 3 0 > $
gen_special 3 1 > $
gen_random 3 5000 1 > $
gen_random 3 5000 2 > $
gen_adversarial 3 0 > $
gen_adversarial 3 1 > $
@4
gen_manual 4 1 > $
gen_manual 4 2 > $
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

Repeated calls differ by a trailing seed token (Step 4). Match the `gen_special` and `gen_adversarial` lines to the subtypes actually implemented.

## Step 10 — Verify locally

Copy the scripts from this skill's `scripts/` directory into the package and run them from the package root. They expect `testlib.h` there (or `TESTLIB_DIR` set) and compile with `$CXX`, default `g++`; on macOS set `CXX` to a GNU compiler such as `g++-15`, because Apple's `g++` is clang and lacks `bits/stdc++.h`. Report every failure to the user; a red result is a bug in a generator, a solution, or the subtask table.

- [scripts/stress.sh](scripts/stress.sh): compiles `gen_stress`, `sol`, and `brute` into `build/`, runs 1000 iterations with the iteration number as the seed, and stops at the first disagreement.
- [scripts/check_manual.sh](scripts/check_manual.sh): compiles `gen_manual` and compares `gen_manual <st> <idx>` with every `stK/xx` file, reporting any drift.
- [scripts/check_solution.sh](scripts/check_solution.sh): compiles one solution and compares it with `sol` on every test in the given directories. `check_solution.sh solutions/sol_st1.cpp st1` should report no failures, and `check_solution.sh solutions/sol_st1.cpp st2` should fail or time out on at least one test.

Also run each `wa_*` and `tle_*` solution over the generated tests and confirm it fails exactly where its header says it should.

## Step 11 — Tag every solution for Polygon

Polygon asks for a solution type per file and verifies it: a tag claiming more than the solution does fails the solution check and blocks the package. The tag describes how a solution fails, not how badly.

| Polygon tag | Means | Use for |
|-------------|-------|---------|
| Main correct solution | passes every test; exactly one per problem | the model solution |
| Correct | passes every test | a second, independently written full solution |
| Wrong answer | WA somewhere, never TLE or RTE | `wa_*.cpp`, fast-but-wrong partials |
| Time limit exceeded | TLE somewhere, never wrong where it finishes | `brute.cpp`, `tle_*.cpp`, partials that are only ever too slow |
| Time limit exceeded or correct | may TLE or pass, never wrong | borderline solutions you don't want to pin down |
| Memory limit exceeded | exceeds the memory limit | a deliberately memory-hungry file |
| Presentation error | right values, malformed formatting | only if the checker distinguishes PE |
| Incorrect | fails somehow, the catch-all | any solution with a mixed failure profile |

Ladder solutions often fail two ways at once: too slow on the big groups and plain wrong on a small group whose inputs they mishandle (an O(N·M) solution that also reads values into `int`, for example). Such a file is neither `Wrong answer` nor `Time limit exceeded`; it is `Incorrect`.

Derive the tag empirically rather than from reading the source: run every solution over every test, record the verdict kind per test (OK / WA / TLE / RTE), and map the observed set: `{OK}` → Correct, `{OK, WA}` → Wrong answer, `{OK, TLE}` → Time limit exceeded, anything else mixed → Incorrect. A classification snippet is in [reference/polygon-tags.md](reference/polygon-tags.md). Report a table to the user (file → tag → observed mix → expected subtask score); tag and score are separate facts, and both go into `UPLOAD.md`.

## Step 12 — Write UPLOAD.md

Prose like "upload the generators" leaves the user interpreting. `UPLOAD.md` is as mechanical as `script.txt`: one action per line with `- [ ]` checkboxes, each marked `UPLOAD` (pick the file from disk), `PASTE` (paste text into a field), or `DO NOT UPLOAD`, with the real file names and the real Step 11 tags rather than placeholders. The section-by-section spec is in [reference/upload-checklist.md](reference/upload-checklist.md).

The fact to make unmissable: the only things uploaded to Polygon by hand are source files (generators, solutions, validator). No test data is uploaded manually, because `gen_manual` lines inside the `@N` blocks assign every hand-crafted test to its group from the script.

## Final checklist

- [ ] Subtask table shown to the user, with intermediate subtasks added if the statement had fewer than 4
- [ ] Generators in `generators/`, solutions in `solutions/`, `validator.cpp` at the root
- [ ] Every generator compiles (`g++ -O2 -std=c++17 -I. generators/gen_edge.cpp -o build/gen_edge`, etc.)
- [ ] `validator.cpp` reads the exact input format and checks per-group constraints
- [ ] `stK/` directories exist for every subtask and every hand-crafted test passes the validator
- [ ] `script.txt` uses `@N` markers and lists every test, hand-crafted ones through `gen_manual` inside their block; nothing is uploaded as a Polygon manual test
- [ ] `check_manual.sh` reports no drift
- [ ] No two `script.txt` lines share a generator and argument list; repeated calls differ by a trailing seed
- [ ] `gen_random` clamps m to `max(n - 1, atoi(argv[k]))`
- [ ] `gen_special` subtypes are distinct structures, not size variants
- [ ] `gen_stress` caps N well below subtask 1's limit
- [ ] `brute.cpp` is correct and passes subtask 1 (maybe 2); `stress.sh` finds no disagreement
- [ ] `sol_st1.cpp` passes only subtask 1, `sol_st1_2.cpp` only subtasks 1–2, `sol_st1_2_3.cpp` (with 4+ subtasks) only subtasks 1–3; each header explains why it fails the next subtask
- [ ] 3–4 `wa_*.cpp` with distinct failure modes and "Fails on" / "To expose" headers; 1–2 `tle_*.cpp` with a "TLEs on" header
- [ ] Every solution's Polygon tag comes from its observed verdict mix; mixed WA+TLE files are tagged `Incorrect`
- [ ] `UPLOAD.md` has real file names and tags, explicit UPLOAD / PASTE / DO NOT UPLOAD actions, and states that no test data is uploaded by hand
- [ ] Graph and tree generators shuffle edges or print them in reverse topological order
- [ ] Every adversarial and special subtype guarantees reachability or is a deliberate −1 case
- [ ] Constraints in every generator match the subtask table exactly

## Additional resources

- [reference/templates.md](reference/templates.md): full generator, ladder, wrong/TLE, and validator templates
- [reference/patterns.md](reference/patterns.md): problem-type heuristics and common wrong/TLE approaches
- [reference/polygon-tags.md](reference/polygon-tags.md): tag semantics and the empirical classification snippet
- [reference/upload-checklist.md](reference/upload-checklist.md): required sections of `UPLOAD.md`
- [scripts/stress.sh](scripts/stress.sh), [scripts/check_manual.sh](scripts/check_manual.sh), [scripts/check_solution.sh](scripts/check_solution.sh): local verification
