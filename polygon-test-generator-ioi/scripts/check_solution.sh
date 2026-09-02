#!/bin/bash
# Compile one solution and compare it with the model solution on every test file in
# the given directories. Prints one line per failing test and a summary.
#
# Usage: ./check_solution.sh solutions/sol_st1.cpp st1 [st2 ...]
#        ./check_solution.sh solutions/wa_greedy.cpp build/tests
# Env:   SOL=solutions/sol.cpp   TL=2   (time limit in seconds)  CXX=g++
#
# Exit status 0 when every test matches, 1 when any test fails, 2 on a build error.
set -uo pipefail

# Compiler: set CXX when plain g++ is not a GNU g++ (e.g. macOS, where g++ is clang and
# lacks <bits/stdc++.h>; use CXX=g++-15 or whatever Homebrew installed).
CXX=${CXX:-g++}

[ $# -ge 2 ] || { echo "usage: $0 <solution.cpp> <test-dir>..." >&2; exit 2; }
CAND=$1; shift
SOL=${SOL:-solutions/sol.cpp}
TL=${TL:-2}

# Run a command under a time limit. Uses coreutils timeout when present (Linux, or
# `brew install coreutils` on macOS); otherwise falls back to perl's alarm, which kills
# the child with SIGALRM so the exit status is non-zero on a timeout.
run_limited() {
    if command -v timeout >/dev/null 2>&1; then
        timeout "$TL" "$@"
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$TL" "$@"
    else
        perl -e 'alarm shift; exec @ARGV' "$TL" "$@"
    fi
}

mkdir -p build
name=$(basename "${CAND%.cpp}")
"$CXX" -O2 -std=c++17 -o "build/$name" "$CAND" || exit 2
"$CXX" -O2 -std=c++17 -o build/sol "$SOL" || exit 2

fails=0
total=0
for d in "$@"; do
    for f in "$d"/*; do
        [ -f "$f" ] || continue
        case "$f" in *.a) continue ;; esac     # skip Polygon answer files
        total=$((total + 1))
        build/sol < "$f" > build/ref.out
        if ! run_limited "build/$name" < "$f" > build/cand.out 2>/dev/null; then
            echo "TLE/RTE: $name on $f"
            fails=$((fails + 1))
            continue
        fi
        if ! cmp -s build/cand.out build/ref.out; then
            echo "WA: $name on $f"
            fails=$((fails + 1))
        fi
    done
done

echo "$name: $((total - fails))/$total tests match sol"
[ $fails -eq 0 ]
