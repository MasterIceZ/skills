# Polygon solution tags

Polygon asks for a solution type per uploaded solution and verifies it against the tests. A tag that claims more than the solution delivers fails Polygon's solution check and blocks the package, so the tag has to describe *how* the solution fails, not how badly.

## Tag semantics

| Polygon tag | Means | Use for |
|-------------|-------|---------|
| **Main correct solution** | passes every test; exactly one per problem | the model solution |
| **Correct** | passes every test | a second, independently written full solution |
| **Wrong answer** | produces WA somewhere, and never TLEs or crashes | `wa_*.cpp`, fast-but-wrong partials (e.g. one that overflows `int` on the last subtask) |
| **Time limit exceeded** | TLEs somewhere, and is never wrong where it finishes | `brute.cpp`, `tle_*.cpp`, partials that are only ever too slow |
| **Time limit exceeded or correct** | may TLE or may pass; never wrong | borderline solutions you don't want to pin down |
| **Memory limit exceeded** | exceeds the memory limit | only a deliberately memory-hungry file |
| **Presentation error** | right values, malformed formatting | only if the checker distinguishes PE |
| **Incorrect** | fails *somehow*; the catch-all | any solution with a mixed failure profile |

## The purity rule

`Wrong answer` and `Time limit exceeded` are pure tags: each promises the solution fails in only that one way. Ladder solutions frequently break the promise. An O(N·M) solution that also reads values into `int` TLEs on the max-size groups *and* wrong-answers the small tests carrying out-of-range values. That file is neither `Wrong answer` nor `Time limit exceeded`; it is `Incorrect`.

## Classify empirically

Reading the source is not enough to know which way a file fails. Run every solution over every test, record the verdict kind per test, and derive the tag from the observed set:

```python
# per solution: run each test, classify, then tag from the set of kinds seen
#   {OK}                -> Correct (or Main correct solution)
#   {OK, WA}            -> Wrong answer
#   {OK, TLE}           -> Time limit exceeded
#   anything else mixed -> Incorrect
kinds = set()
for t in tests:
    r = run(sol, t, timeout=2 * TL)
    if   r.timed_out:            kinds.add("TLE")
    elif r.returncode != 0:      kinds.add("RTE")
    elif r.output != answer[t]:  kinds.add("WA")
    elif r.elapsed > TL:         kinds.add("TLE")
    else:                        kinds.add("OK")
```

Running at `2 * TL` and then comparing `elapsed` with `TL` separates "slow but right" from "wrong": a solution that finishes at 1.5×TL with the right answer is TLE, not WA.

## Report

Give the user one table, so tagging at upload time is mechanical:

| File | Polygon tag | Observed mix | Expected score |
|------|-------------|--------------|----------------|
| `solutions/sol.cpp` | Main correct solution | OK on all | 100 |
| `solutions/sol_st1_2.cpp` | Incorrect | OK st1–2, WA st3, TLE st4 | points of subtasks 1–2 |
| … | | | |

The tag and the score are separate facts: a solution's score says nothing about which tag Polygon will accept, so record both. The same table feeds the Solutions section of `UPLOAD.md`.
