---
name: polygon-test-generator-cafe
description: Generate cafe-grader test data (uniform per-test scoring, no groups) for a competitive programming problem, authored and uploaded through Codeforces Polygon, producing at most 50 tests that all carry the same score and sum to exactly 100, subtasks kept as score goals met by test count, subtask-aware testlib.h generators, a full-constraint validator, partial/wrong/TLE solutions, a flat script.txt, a scores.txt manifest, the bundled poly_to_cafe.sh converter, and an UPLOAD.md click-through checklist. Use when the target judge is cafe-grader or any judge that scores every test individually.
when_to_use: Trigger phrases include "cafe", "cafe-grader", "grader.in.th", "per-test score", "no subtask groups". For IOI group scoring use polygon-test-generator-ioi; for plain Polygon tests use polygon-test-generator.
---

# Cafe-Grader Test Generator

Produce a complete, verified cafe-grader package from a problem statement (Markdown or LaTeX) and the provided solutions. cafe-grader scores every test file individually with one uniform score and has no groups, so three platform constraints shape the whole plan:

1. **At most 50 tests**, hand-crafted and generated combined.
2. **The full score is exactly 100.**
3. **Every test carries the same score**, an exact decimal. The test count therefore has to divide 100 cleanly: 10, 20, 25, or 50 tests (10, 5, 4, or 2 points each), or 40 tests at 2.5 points only when half points are acceptable. 30 tests (3.33… each) is not representable.

The package is authored, verified, and uploaded through Polygon exactly like the IOI skill; cafe-grader's format is the constraint the plan is designed around, not the upload destination. Subtasks still exist, as score goals: each subtask gets a goal that is a multiple of the per-test score, the goals sum to 100, and a goal is met by test count (goal ÷ score tests). The statement shows the goals like any IOI problem; only the grader differs, since a contestant simply keeps the points of every test they pass.

Keep the user informed: show the subtask table and the test/score budget before generating anything, give a one-line update as each stage completes, and close with a recap listing every produced file, the solution tag and score table, and any verification that failed or was skipped. Deliver the whole package in one pass; if a part cannot be produced (for example, a custom checker), say so in the recap instead of stopping early.

## What you produce

| Path | Purpose |
|------|---------|
| `generators/gen_edge.cpp` | Edge and corner cases, subtask-aware |
| `generators/gen_random.cpp` | Random tests within a subtask's constraints |
| `generators/gen_special.cpp` | Structural shapes (algebraic/combinatorial) |
| `generators/gen_adversarial.cpp` | Worst-case inputs per subtask |
| `generators/gen_stress.cpp` | Tiny tests for the stress loop |
| `generators/gen_manual.cpp` | Emits each hand-crafted test verbatim so `script.txt` can list every test |
| `validator.cpp` | Validates input against the full constraint set (no groups) |
| `st1/01`, `st1/02`, … `stK/…` | Hand-crafted tests per subtask (source of truth, embedded in `gen_manual`) |
| `script.txt` | Flat test script, no group markers |
| `scores.txt` | Per-test score manifest: exact decimals, sums to exactly 100 |
| `poly_to_cafe.sh` | Converts the downloaded Polygon package into cafe-grader judge data (copied from this skill's `scripts/`) |
| `UPLOAD.md` | Click-through upload checklist: every file, where it goes, which tag |
| `solutions/sol.cpp` | Model solution, full score |
| `solutions/brute.cpp` | Correct but slow |
| `solutions/sol_st1.cpp`, `sol_st1_2.cpp`, `sol_st1_2_3.cpp` | Partial ladder: passes subtasks 1, 1–2, 1–3 (the last only with 4+ subtasks) |
| `solutions/wa_*.cpp` | 3–4 wrong-answer solutions with distinct failure modes |
| `solutions/tle_*.cpp` | 1–2 correct-but-slow solutions |

```
problem/
├── generators/     # every gen_*.cpp
├── solutions/      # model + brute + partial ladder + wa_* + tle_*
├── validator.cpp   # package root: Polygon has its own upload slot for it
├── st1/ … stK/     # hand-crafted tests per subtask
├── script.txt
├── scores.txt      # test → points manifest
├── poly_to_cafe.sh # poly/tests -> cafe/N.in + N.sol
└── UPLOAD.md
```

Generators and solutions live in their own directories so each set can be bulk-uploaded to Polygon in one go. Compiled binaries and generated tests go in a local `build/` directory. `script.txt` refers to generators by bare name because Polygon resolves uploaded generators by name. `testlib.h` is already available in Polygon, so it is not uploaded; for local builds download it from `https://raw.githubusercontent.com/MikeMirzayanov/testlib/refs/heads/master/testlib.h`.

## Step 1 — Define the subtasks and their score goals

Read every "Subtask" or "Constraints" section and produce a table whose Points column sums to exactly 100:

| Subtask | Points | Additional constraints |
|---------|--------|----------------------|
| 1 | p₁ | N ≤ 10 |
| 2 | p₂ | N ≤ 1 000 |
| 3 | p₃ | All aᵢ equal |
| 4 | p₄ | No further constraints (N ≤ 100 000) |

Subtasks are cumulative: a subtask-k test is also a valid subtask k−1 input unless the statement says otherwise. The final subtask is the full constraint set. Aim for 3–5 subtasks; if the statement gives fewer or none, add intermediate subtasks at natural complexity boundaries: after the brute-force bound (N ≤ 10 or N ≤ 100), after the quadratic bound (N ≤ 3 000–5 000), after the N log N bound (N ≤ 100 000), plus any problem-specific structural subtask.

## Step 2 — Fix the test and score budget

Decide the exact test count and per-test score before writing any generator, in two stages:

1. **Pick the uniform per-test score s**, which fixes the test count at 100 / s. 20 tests × 5 points is the usual sweet spot; 25 × 4 gives finer granularity, 10 × 10 coarser.
2. **Give each subtask a goal that is a multiple of s**, goals summing to 100 (with s = 5: 20 / 20 / 25 / 35, or 20 / 30 / 50). Each subtask then gets goal / s tests.

| Subtask | Goal | Tests (goal / 5) |
|---------|------|------------------|
| 1 | 20 | 4 |
| 2 | 20 | 4 |
| 3 | 25 | 5 |
| 4 | 35 | 7 |
| **Total** | **100** | **20** |

Per-test scoring has no all-or-nothing effect: a wrong solution keeps the points of every test it slips past. Three consequences follow:

- Each failure mode needs several killer tests spread across subtasks, because one killer costs only one test's points.
- With so few tests, every slot has to earn its place: choose each generator's single most lethal subtype per subtask instead of enumerating all subtypes.
- Compute the expected score of every partial, wrong, and TLE solution from the budget, and verify it empirically in Step 11.

Show the subtask table and this budget to the user before proceeding.

## Step 3 — Parse the problem statement

Extract:

- **Input format**: variable names, structure, exact reading order.
- **Full constraints**: every bound across all subtasks.
- **Multiple test cases**: if the first line is T, every generator wraps its output in T cases.
- **Output spec**: decide whether the answer is unique. A custom checker is needed when several outputs are valid (printing a path, assignment, or permutation rather than its cost; any-valid-answer constructive problems; floating point with tolerance). Note that one is needed but do not write it; it is too problem-specific for this skill.
- **Problem type**: match against [reference/patterns.md](reference/patterns.md) to choose edge and adversarial shapes.

## Step 4 — Classify the provided solutions

| Role | Common names |
|------|-------------|
| Model solution (full) | `ac`, `main_sol`, `model`, `solution`, `sol`, `correct` |
| Brute force | `brute`, `slow`, `naive`, `bf`, `n2`, `n3` |
| Wrong solutions | `wa`, `tle`, `mle`, `wrong`, `hack`, `bad` |

If no brute force is provided, write one in Step 6.

## Step 5 — Write the generators

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
| `gen_edge` | `st subtype` | Deterministic corners at this subtask's bound: N=1; N=MAXN with all MINVAL, all MAXVAL, sorted ascending, sorted descending; then problem-specific edges |
| `gen_random` | `st [n] [seed]` | Random inputs with `n = min(atoi(argv[2]), MAXN)` (random in range when omitted). Structural subtask constraints are enforced here too: if subtask 3 requires all values equal, `gen_random 3 500` produces all-equal values, not just N ≤ 500 |
| `gen_special` | `st subtype` | 4–6 structural shapes, each a distinct mathematical structure rather than a size variant (bamboo, star, caterpillar; palindromes, period-2 strings; all-prime, powers of 2; bipartite, grid; cyclic-shift or bitonic permutations) |
| `gen_stress` | `[n]` | Tiny inputs (STRESS_MAXN ≈ 8–15, whatever `brute` solves in under 50 ms). It explores the full valid space and deliberately ignores structural subtask constraints, because the stress loop is looking for any disagreement between `sol` and `brute` |
| `gen_adversarial` | `st subtype` | Maximum-N inputs for the subtask built to break naive solutions: the O(N²) killer, the anti-greedy counter-example, the problem-specific worst case. Aim each subtype at a specific `wa_*`, `tle_*`, or ladder solution |
| `gen_manual` | `st idx` | Prints hand-crafted test `st<st>/<idx>` verbatim (Step 9) |

Rules that are easy to get wrong:

- **Random values come from testlib's `rnd`** (`rnd.next(lo, hi)`), even inside an otherwise deterministic pattern. `registerGen` seeds `rnd` from the full argv, so every test is reproducible.
- **Seeding**: because the seed is derived from all arguments, `gen_random 4 100000 1` and `gen_random 4 100000 2` differ while two identical lines produce identical tests. Every repeated call in `script.txt` needs a distinct trailing token. Generators that never call `rnd` are fully deterministic, so call each of their subtypes once.
- **Seed vs. m collision**: if `gen_random` reads an edge count `m` from argv, a trailing seed could set m below n−1 and the validator would reject the header. Clamp with `m = max(n - 1, atoi(argv[k]))`.
- **Edge order in graph generators**: chain, BFS, or spanning-tree order can neuter an adversarial case (Bellman-Ford finishes in one pass on topologically ordered edges). Shuffle edges with testlib's `shuffle` or print a bamboo in reverse.
- **Reachability**: `gen_adversarial` and `gen_special` do not build a spanning tree automatically. If the problem never outputs −1, every subtype guarantees the required reachability; if −1 is legal, include one intentionally disconnected adversarial case.
- **Verify the TLE**: after writing an adversarial generator, run `timeout <TL> build/tle_x < input`; an exit code of 0 means the case is accidentally easy.

## Step 6 — Write the partial-solution ladder

The ladder still matters under per-test scoring: each rung collects exactly the points of the tests it passes, and that expected score is what Step 11 verifies. Write one solution per subtask boundary; each passes every subtask up to k and is intentionally too slow or too specialized for k+1. Header templates are in [reference/templates.md](reference/templates.md).

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

## Step 7 — Write wrong and TLE solutions

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

## Step 8 — Write validator.cpp

The validator sits at the package root because Polygon uploads it in its own slot. cafe-grader has no groups, so it validates the full constraint set only: every test, whatever subtask it was designed for, has to pass this one validator. Subtask-specific bounds are the generators' responsibility and are checked by the budget review in Step 11.

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

## Step 9 — Hand-crafted tests and gen_manual

Create one directory per subtask (`st1/`, `st2/`, …) with 1–2 static tests each; they count toward the ≤ 50 budget. Name them without extension:

- `01`: minimum valid input within the subtask's constraints.
- `02`: maximum N for this subtask, all maximum values.
- `03`: the subtask's problem-specific must-have (for a "path graphs" subtask, the extremal path).

A test in `stK/` satisfies every constraint of subtask K, which makes it valid for subtasks 1 through K−1 as well.

These files are the human-readable source of truth, but they are not uploaded as Polygon manual tests: Polygon scripts cannot reference uploaded manual tests, and with every test in the script Polygon's test indices `1..N` line up with `scores.txt` 1:1 and the whole set is reproducible from source. Generate `generators/gen_manual.cpp` programmatically from the `stK/` directories so each file is embedded verbatim:

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

Step 11 asserts that `gen_manual <st> <idx>` reproduces each `stK/xx` byte-for-byte so the two can never drift.

## Step 10 — Test script and score manifest

### script.txt

cafe-grader has no groups, so `script.txt` is a flat list of generator calls with no `@N` markers, grouped by subtask in judge order, and its line count equals the Step 2 budget exactly. Example for the 20-test budget above (6 hand-crafted through `gen_manual` plus 14 generated):

```
# --- subtask 1 (goal 20) ---
gen_manual 1 1 > $
gen_manual 1 2 > $
gen_edge 1 0 > $
gen_random 1 1000 1 > $
# --- subtask 2 (goal 20) ---
gen_manual 2 1 > $
gen_edge 2 1 > $
gen_random 2 100000 1 > $
gen_adversarial 2 1 > $
# --- subtask 3 (goal 25) ---
gen_manual 3 1 > $
gen_edge 3 3 > $
gen_random 3 100000 1 > $
gen_adversarial 3 1 > $
gen_adversarial 3 2 > $
# --- subtask 4 (goal 35) ---
gen_manual 4 1 > $
gen_manual 4 2 > $
gen_edge 4 7 > $
gen_random 4 100000 1 > $
gen_special 4 3 > $
gen_adversarial 4 1 > $
gen_adversarial 4 3 > $
```

That is exactly 20 generator lines: 4 + 4 + 5 + 7, matching the goal-derived counts. Repeated calls differ by a trailing seed token (Step 5).

### scores.txt

One line per test in final judge order: `test_number  score  source`. `#` starts a comment. The source column matches `script.txt` line-for-line, so a Polygon test index equals the number here.

```
# subtask 1 — goal 20 (4 tests x 5)
1   5  gen_manual 1 1
2   5  gen_manual 1 2
3   5  gen_edge 1 0
4   5  gen_random 1 1000 1
# subtask 2 — goal 20 (4 tests x 5)
5   5  gen_manual 2 1
...
# subtask 4 — goal 35 (7 tests x 5)
...
20  5  gen_adversarial 4 3
# 20 tests x 5 points; goals 20+20+25+35 = 100
```

[scripts/check_scores.sh](scripts/check_scores.sh) machine-checks the manifest: at most 50 lines, all scores identical, total exactly 100, each `# subtask K — goal G` block's count × score equal to G, and the source column equal to `script.txt` line-for-line.

## Step 11 — Verify locally

Copy the scripts from this skill's `scripts/` directory into the package and run them from the package root. They expect `testlib.h` there (or `TESTLIB_DIR` set) and compile with `$CXX`, default `g++`; on macOS set `CXX` to a GNU compiler such as `g++-15`, because Apple's `g++` is clang and lacks `bits/stdc++.h`. Report every failure to the user; a red result is a bug in a generator, a solution, or the budget.

- [scripts/stress.sh](scripts/stress.sh): compiles `gen_stress`, `sol`, and `brute` into `build/`, runs 1000 iterations with the iteration number as the seed, and stops at the first disagreement.
- [scripts/check_manual.sh](scripts/check_manual.sh): compiles `gen_manual` and compares `gen_manual <st> <idx>` with every `stK/xx` file, reporting any drift.
- [scripts/check_solution.sh](scripts/check_solution.sh): compiles one solution and compares it with `sol` on every test in the given directories. `check_solution.sh solutions/sol_st1.cpp st1` should report no failures, and `check_solution.sh solutions/sol_st1.cpp st2` should fail or time out on at least one test.
- [scripts/check_scores.sh](scripts/check_scores.sh): validates `scores.txt` against the budget and `script.txt`.

Then generate the full test set locally from `script.txt`, run every solution over every test, and record two things per solution from the same run: the verdict kind per test (for Step 12) and the sum of the scores of the tests it passes. Compare that sum with the expected score from Step 2 and report both in the recap.

## Step 12 — Tag every solution for Polygon

Polygon asks for a solution type per file and verifies it: a tag claiming more than the solution does fails the solution check and blocks the package. The tag describes how a solution fails, not how badly.

| Polygon tag | Means | Use for |
|-------------|-------|---------|
| Main correct solution | passes every test; exactly one per problem | `sol.cpp` |
| Correct | passes every test | any other full solution |
| Wrong answer | WA somewhere, never TLE or RTE | `wa_*.cpp`, fast-but-wrong partials |
| Time limit exceeded | TLE somewhere, never wrong where it finishes | `brute.cpp`, `tle_*.cpp`, partials that are only ever too slow |
| Time limit exceeded or correct | may TLE or pass, never wrong | borderline solutions you don't want to pin down |
| Memory limit exceeded | exceeds the memory limit | a deliberately memory-hungry file |
| Presentation error | right values, malformed formatting | only if the checker distinguishes PE |
| Incorrect | fails somehow, the catch-all | any solution with a mixed failure profile |

Partial solutions often fail two ways at once: too slow on the big tests and plain wrong on a subtask whose inputs they mishandle (an O(N·M) solution that also reads values into `int`, for example). Such a file is neither `Wrong answer` nor `Time limit exceeded`; it is `Incorrect`.

Derive the tag from the Step 11 run rather than from reading the source: `{OK}` → Correct, `{OK, WA}` → Wrong answer, `{OK, TLE}` → Time limit exceeded, anything else mixed → Incorrect. The classification snippet is in [reference/polygon-tags.md](reference/polygon-tags.md). Report a table to the user (file → tag → observed mix → cafe score). Under per-test scoring a wrong solution keeps the points of every test its bug doesn't reach, so score and tag are separate facts; record both. The tags matter only to Polygon: cafe-grader has no notion of solution types, and there the expected score is what counts.

## Step 13 — UPLOAD.md, Polygon build, and conversion

Upload to Polygon exactly as in the IOI skill, then paste the flat script and leave Polygon's groups and points OFF, since scoring lives in cafe-grader.

`UPLOAD.md` is as mechanical as `script.txt`: one action per line with `- [ ]` checkboxes, each marked `UPLOAD` (pick the file from disk), `PASTE` (paste text into a field), or `DO NOT UPLOAD`, with the real file names and the real Step 12 tags rather than placeholders. The section-by-section spec, including the fallback when `gen_manual` is deliberately skipped, is in [reference/upload-checklist.md](reference/upload-checklist.md). The fact to make unmissable: the only things uploaded to Polygon by hand are source files, so Polygon's test indices match `scores.txt` 1:1.

After Polygon builds the package, download it, unzip it so the tests land in `poly/tests/`, and run the bundled [scripts/poly_to_cafe.sh](scripts/poly_to_cafe.sh), copied into the package as-is. It is problem-independent and renames `tests/01`, `tests/01.a`, … to `cafe/1.in`, `cafe/1.sol`, … (`.a` → `.sol`, extensionless → `.in`, leading zeros stripped). It refuses unfamiliar filenames, checks that the result is a gapless `1..N` with both halves per test, and, when `scores.txt` sits alongside, asserts the built test count equals the manifest count so a short Polygon build cannot silently break the 100-point total.

```bash
./poly_to_cafe.sh                # poly/tests -> cafe/
diff -rq cafe <local export>     # byte-identical output proves Polygon built what was designed
```

Materialize the same pairs locally from your own generators and `diff` the two directories, then enter the test count, the uniform per-test score, and the time limit in cafe-grader's problem setup.

## Final checklist

- [ ] Subtask table with score goals shown to the user: goals sum to exactly 100, each a multiple of the uniform per-test score, at most 50 tests
- [ ] All tests carry the same score; each subtask's test count × score equals its goal
- [ ] Generators in `generators/`, solutions in `solutions/`, `validator.cpp` at the root
- [ ] Every generator compiles (`g++ -O2 -std=c++17 -I. generators/gen_edge.cpp -o build/gen_edge`, etc.)
- [ ] `validator.cpp` reads the exact input format and validates the full constraint set (no groups)
- [ ] `stK/` directories exist for every subtask and every hand-crafted test passes the validator
- [ ] `script.txt` is flat (no `@N`), lists every test including hand-crafted ones through `gen_manual`, and has at most 50 lines
- [ ] `check_manual.sh` reports no drift
- [ ] `scores.txt` lists every test in judge order, matches `script.txt` line-for-line, uses one uniform exact-decimal score, and totals exactly 100 (`check_scores.sh` passes)
- [ ] Expected cafe score of every partial, wrong, and TLE solution computed and verified empirically
- [ ] Every solution's Polygon tag comes from its observed verdict mix; mixed WA+TLE files are tagged `Incorrect`
- [ ] `UPLOAD.md` has real file names and tags, explicit UPLOAD / PASTE / DO NOT UPLOAD actions, and states that no test data is uploaded by hand (or, if `gen_manual` was skipped, lists each `stK/xx` manual test and its index)
- [ ] `poly_to_cafe.sh` copied into the package; `cafe/` built from the Polygon download and byte-identical to the local export
- [ ] No two `script.txt` lines share a generator and argument list; repeated calls differ by a trailing seed
- [ ] `gen_random` clamps m to `max(n - 1, atoi(argv[k]))`
- [ ] `gen_special` subtypes are distinct structures, not size variants
- [ ] `gen_stress` caps N well below subtask 1's limit
- [ ] `brute.cpp` is correct and passes subtask 1 (maybe 2); `stress.sh` finds no disagreement
- [ ] `sol_st1.cpp` passes only subtask 1, `sol_st1_2.cpp` only subtasks 1–2, `sol_st1_2_3.cpp` (with 4+ subtasks) only subtasks 1–3; each header explains why it fails the next subtask
- [ ] 3–4 `wa_*.cpp` with distinct failure modes and "Fails on" / "To expose" headers; 1–2 `tle_*.cpp` with a "TLEs on" header
- [ ] Graph and tree generators shuffle edges or print them in reverse topological order
- [ ] Every adversarial and special subtype guarantees reachability or is a deliberate −1 case
- [ ] Constraints in every generator match the subtask table exactly

## Additional resources

- [reference/templates.md](reference/templates.md): full generator, ladder, wrong/TLE, and validator templates
- [reference/patterns.md](reference/patterns.md): problem-type heuristics and common wrong/TLE approaches
- [reference/polygon-tags.md](reference/polygon-tags.md): tag semantics and the empirical classification snippet
- [reference/upload-checklist.md](reference/upload-checklist.md): required sections of `UPLOAD.md`, including the Polygon build and cafe-grader upload steps
- [scripts/stress.sh](scripts/stress.sh), [scripts/check_manual.sh](scripts/check_manual.sh), [scripts/check_solution.sh](scripts/check_solution.sh), [scripts/check_scores.sh](scripts/check_scores.sh): local verification
- [scripts/poly_to_cafe.sh](scripts/poly_to_cafe.sh): Polygon package → cafe-grader judge data
