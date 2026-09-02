# UPLOAD.md specification

`UPLOAD.md` is the last file in the package: a click-through checklist the user works down in Polygon's UI and then in cafe-grader. Write it as mechanically as `script.txt`: one action per line, `- [ ]` checkboxes, and the real file names and real solution tags for this problem rather than placeholders.

Conventions used in every line:

- `UPLOAD` = pick this file from disk
- `PASTE` = paste text into a field
- `DO NOT UPLOAD` = keep local

## Required sections, in order

1. **General info**: time limit, memory limit, checker (name the standard one, or the custom checker file), and "test groups/points: leave OFF" since scoring lives in cafe-grader.
2. **Source files (generators)**: `UPLOAD` each `generators/*.cpp`, `gen_manual.cpp` first with a note on what it carries. `DO NOT UPLOAD testlib.h`; Polygon provides it.
3. **Validator**: `UPLOAD validator.cpp` and set it as the validator.
4. **Solutions**: a table with one row per file: `UPLOAD this file | Set solution type to | Verified behavior`, using the tags from the tagging step. Call out any `Incorrect` (mixed) row and why a pure tag would be rejected.
5. **Tests**: state plainly that no manual test is added; all tests come from the script. `PASTE script.txt`, mark the sample test, run Polygon's solution check, and state the exact test count Polygon must end up showing.
6. **Build, download, convert**: build and download the package, unzip so the tests land in `poly/tests/`, run `./poly_to_cafe.sh`, and `diff` the result against a local export to prove Polygon built what was designed.
7. **cafe-grader**: `UPLOAD` the `cafe/` pairs, set the test count, the uniform per-test score, and the time limit.
8. **Never uploaded anywhere**: a closing table listing `testlib.h`, the `stK/` files (they live inside `gen_manual.cpp`), `scores.txt`, local tooling (`build/`, the verification scripts), and working directories.

## The fact to make unmissable

The only things uploaded to Polygon by hand are **source files**. Zero test *data* is uploaded manually, so Polygon's test indices match `scores.txt` 1:1.

## If gen_manual is deliberately skipped

Not recommended, but if the hand-crafted tests are uploaded as Polygon manual tests instead, `UPLOAD.md` lists each `stK/xx` file as a manual test upload, in order, **before** the `PASTE` of `script.txt`. The script's `> $` continues after the manual tests, so their indices decide the whole judge order, and `scores.txt` has to be renumbered to match.
