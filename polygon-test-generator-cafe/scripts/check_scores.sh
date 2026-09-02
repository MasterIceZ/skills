#!/bin/bash
# Machine-check scores.txt against the cafe-grader constraints and script.txt.
# Run from the package root.
#
#   - at most 50 tests
#   - tests numbered 1..N in order
#   - every score identical (cafe-grader supports uniform per-test scoring only)
#   - total exactly 100
#   - source column equals script.txt line-for-line (comments and blank lines ignored)
#   - when a comment "# subtask K — goal G" precedes each block, count x score == G
#
# Usage: ./check_scores.sh [scores.txt] [script.txt]
set -euo pipefail

SCORES=${1:-scores.txt}
SCRIPT=${2:-script.txt}
[ -f "$SCORES" ] || { echo "no such file: $SCORES" >&2; exit 1; }
[ -f "$SCRIPT" ] || { echo "no such file: $SCRIPT" >&2; exit 1; }

awk -v script="$SCRIPT" '
function closeblock() {
    if (goal != "" && blockcount * score != goal + 0) {
        printf("ERROR: %s has %d tests x %s = %s, but its goal is %s\n",
               blockname, blockcount, score, blockcount * score, goal)
        bad = 1
    }
}
BEGIN {
    n = 0; nscript = 0; total = 0; bad = 0
    goal = ""; blockcount = 0; blockname = ""
    # generator lines of script.txt, in order, with comments and "> $" stripped
    while ((getline line < script) > 0) {
        sub(/#.*/, "", line)
        gsub(/^[ \t]+|[ \t]+$/, "", line)
        if (line == "") continue
        sub(/[ \t]*>[ \t]*\$$/, "", line)
        gsub(/[ \t]+/, " ", line)
        scriptsrc[++nscript] = line
    }
}
/^[ \t]*#/ {
    if (match($0, /subtask[ \t]+[0-9]+/)) {
        closeblock()
        blockname = substr($0, RSTART, RLENGTH)
        if (match($0, /goal[ \t]+[0-9.]+/)) {
            goal = substr($0, RSTART + 4, RLENGTH - 4); gsub(/[ \t]/, "", goal)
        } else goal = ""
        blockcount = 0
    }
    next
}
/^[ \t]*$/ { next }
{
    n++; blockcount++
    if ($1 + 0 != n) { printf("ERROR: line numbered %s, expected %d\n", $1, n); bad = 1 }
    if (n == 1) score = $2 + 0
    else if ($2 + 0 != score) {
        printf("ERROR: test %d has score %s, expected %s (all scores must be identical)\n", n, $2, score)
        bad = 1
    }
    total += $2
    src = $0
    sub(/^[ \t]*[0-9]+[ \t]+[0-9.]+[ \t]+/, "", src)
    gsub(/[ \t]+$/, "", src); gsub(/[ \t]+/, " ", src)
    if (n <= nscript && src != scriptsrc[n]) {
        printf("ERROR: test %d source \"%s\" != script.txt line \"%s\"\n", n, src, scriptsrc[n])
        bad = 1
    }
}
END {
    closeblock()
    if (n == 0) { print "ERROR: no test lines found"; bad = 1 }
    if (n > 50) { printf("ERROR: %d tests, cafe-grader limit is 50\n", n); bad = 1 }
    if (total + 0 != 100) { printf("ERROR: scores total %s, must be exactly 100\n", total); bad = 1 }
    if (n != nscript) {
        printf("ERROR: %d tests in scores file but %d generator lines in script\n", n, nscript)
        bad = 1
    }
    if (!bad) printf("scores OK: %d tests x %s = 100, source column matches script line-for-line\n", n, score)
    exit bad
}' "$SCORES"
