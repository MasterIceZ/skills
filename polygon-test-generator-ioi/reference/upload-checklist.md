# UPLOAD.md specification

`UPLOAD.md` is the last file in the package: a click-through checklist the user works down in Polygon's UI. Write it as mechanically as `script.txt`: one action per line, `- [ ]` checkboxes, and the real file names and real solution tags for this problem rather than placeholders.

Conventions used in every line:

- `UPLOAD` = pick this file from disk
- `PASTE` = paste text into a field
- `DO NOT UPLOAD` = keep local

## Required sections, in order

1. **General info**: time limit, memory limit, checker (name the standard one, or the custom checker file), and that test groups ARE enabled.
2. **Source files (generators)**: `UPLOAD` each `generators/*.cpp`, `gen_manual.cpp` first with a note on what it carries. `DO NOT UPLOAD testlib.h`; Polygon provides it.
3. **Validator**: `UPLOAD validator.cpp` and set it as the validator.
4. **Solutions**: a table with one row per file: `UPLOAD this file | Set solution type to | Verified behavior`, using the tags from the tagging step. Call out any `Incorrect` (mixed) row and why a pure tag would be rejected.
5. **Tests**: state plainly that no manual test is added. Every test comes from the script, hand-crafted ones through `gen_manual`. `PASTE script.txt` (its `@N` markers assign each test, including the `gen_manual` ones, to its group), mark the sample test, and state the exact test count Polygon must show.
6. **Groups and points**: enable groups, set each group's points from the subtask table, set the group dependencies and the per-group "all tests" requirement.
7. **Never uploaded anywhere**: a closing table listing `testlib.h`, the `stK/` files (they live inside `gen_manual.cpp`), local tooling (`build/`, the verification scripts), and working directories.

## The fact to make unmissable

The only things uploaded to Polygon by hand are **source files**: generators, solutions, validator. No test *data* is uploaded manually. Because `gen_manual` lines live inside the `@N` blocks, group assignment comes from the script rather than from clicking through Polygon's UI.
