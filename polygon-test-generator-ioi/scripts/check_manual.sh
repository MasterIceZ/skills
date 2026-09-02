#!/bin/bash
# Assert that gen_manual reproduces every hand-crafted stK/xx file byte-for-byte.
# gen_manual embeds copies of those files, so this is the check that keeps the two
# from drifting apart. Run from the package root.
#
# Usage: ./check_manual.sh
# Env:   TESTLIB_DIR=.   (directory holding testlib.h)  CXX=g++
set -uo pipefail

# Compiler: set CXX when plain g++ is not a GNU g++ (e.g. macOS, where g++ is clang and
# lacks <bits/stdc++.h>; use CXX=g++-15 or whatever Homebrew installed).
CXX=${CXX:-g++}

TESTLIB_DIR=${TESTLIB_DIR:-.}
mkdir -p build
"$CXX" -O2 -std=c++17 -I"$TESTLIB_DIR" -o build/gen_manual generators/gen_manual.cpp || exit 2

status=0
checked=0
for f in st*/*; do
    [ -f "$f" ] || continue
    st=${f%%/*}; st=${st#st}                 # st3/02 -> 3
    idx=$(basename "$f"); idx=$((10#$idx))   # 02 -> 2
    checked=$((checked + 1))
    if ! build/gen_manual "$st" "$idx" > build/gm.txt 2>/dev/null; then
        echo "MISSING: gen_manual $st $idx has no entry for $f"
        status=1
        continue
    fi
    if ! cmp -s build/gm.txt "$f"; then
        echo "DRIFT: gen_manual $st $idx != $f"
        status=1
    fi
done

if [ "$checked" -eq 0 ]; then
    echo "no hand-crafted tests found under st*/"
    exit 1
fi
[ $status -eq 0 ] && echo "gen_manual matches every hand-crafted file ($checked checked)."
exit $status
