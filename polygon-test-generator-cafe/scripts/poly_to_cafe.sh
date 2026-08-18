#!/bin/bash
# Convert a downloaded Polygon package's tests into cafe-grader judge data.
#
#   poly/tests/01, 01.a, …, 20, 20.a   ->   cafe/1.in, 1.sol, …, 20.in, 20.sol
#
# Rules: `.a` (Polygon's answer file) becomes `.sol`, an extensionless test becomes `.in`,
# and leading zeros are stripped from the number (cafe-grader wants 1.in, not 01.in).
#
# This script is problem-independent — copy it into any cafe-grader package as-is.
#
# Usage: ./poly_to_cafe.sh [SRC_DIR] [DEST_DIR]     (defaults: poly/tests, cafe)
set -euo pipefail

SRC=${1:-poly/tests}
DEST=${2:-cafe}

[ -d "$SRC" ] || { echo "no such directory: $SRC" >&2; exit 1; }

# Refuse to silently convert a package containing names we don't understand.
if bad=$(ls "$SRC" | grep -Ev '^[0-9]+(\.a)?$'); then
    echo "unexpected filenames in $SRC (expected NN and NN.a):" >&2
    echo "$bad" >&2
    exit 1
fi

shopt -s nullglob
srcfiles=("$SRC"/*)
[ ${#srcfiles[@]} -gt 0 ] || { echo "ERROR: $SRC is empty — did the Polygon build finish?" >&2; exit 1; }

rm -rf "$DEST"
mkdir -p "$DEST"

for f in "${srcfiles[@]}"; do
    b=$(basename "$f")
    case "$b" in
        *.a) num="${b%.a}"; ext="sol" ;;
          *) num="$b";      ext="in"  ;;
    esac
    cp "$f" "$DEST/$((10#$num)).$ext"
done

n_in=$(ls "$DEST"/*.in | wc -l | tr -d ' ')
n_sol=$(ls "$DEST"/*.sol | wc -l | tr -d ' ')
echo "$DEST: $n_in inputs + $n_sol answers"
[ "$n_in" = "$n_sol" ] || { echo "ERROR: input/answer count mismatch" >&2; exit 1; }

# Every test must have both halves, numbered 1..N with no gaps.
for i in $(seq 1 "$n_in"); do
    [ -f "$DEST/$i.in" ]  || { echo "ERROR: missing $DEST/$i.in" >&2;  exit 1; }
    [ -f "$DEST/$i.sol" ] || { echo "ERROR: missing $DEST/$i.sol" >&2; exit 1; }
done
echo "numbering 1..$n_in complete, every test has .in and .sol"

# Cross-check against the score manifest: Polygon must have built exactly the tests the
# budget plans for, or the per-test scores no longer add up to 100.
if [ -f scores.txt ]; then
    n_manifest=$(grep -Ecv '^\s*(#|$)' scores.txt || true)
    if [ "$n_in" != "$n_manifest" ]; then
        echo "ERROR: $n_in tests built but scores.txt lists $n_manifest" >&2
        exit 1
    fi
    echo "matches scores.txt ($n_manifest tests)"
fi
