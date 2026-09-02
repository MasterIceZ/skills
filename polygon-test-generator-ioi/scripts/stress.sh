#!/bin/bash
# Stress-test the model solution against the brute force on tiny random inputs.
# Run from the package root. Stops at the first disagreement.
#
# Usage: ./stress.sh [iterations]                       (default 1000)
# Env:   SOL=solutions/sol.cpp  BRUTE=solutions/brute.cpp  CXX=g++
#        GEN=generators/gen_stress.cpp  TESTLIB_DIR=.   (directory holding testlib.h)
set -euo pipefail

# Compiler: set CXX when plain g++ is not a GNU g++ (e.g. macOS, where g++ is clang and
# lacks <bits/stdc++.h>; use CXX=g++-15 or whatever Homebrew installed).
CXX=${CXX:-g++}

ITER=${1:-1000}
SOL=${SOL:-solutions/sol.cpp}
BRUTE=${BRUTE:-solutions/brute.cpp}
GEN=${GEN:-generators/gen_stress.cpp}
TESTLIB_DIR=${TESTLIB_DIR:-.}

mkdir -p build
"$CXX" -O2 -std=c++17 -I"$TESTLIB_DIR" -o build/gen_stress "$GEN"
"$CXX" -O2 -std=c++17 -o build/sol   "$SOL"
"$CXX" -O2 -std=c++17 -o build/brute "$BRUTE"

for i in $(seq 1 "$ITER"); do
    # testlib seeds from argv, so passing $i makes every iteration a different test;
    # with no arguments every run would produce the same input.
    build/gen_stress "$i" > build/stress.in
    build/sol   < build/stress.in > build/stress.sol.out
    build/brute < build/stress.in > build/stress.brute.out
    if ! cmp -s build/stress.sol.out build/stress.brute.out; then
        echo "DIFFERENCE on iteration $i"
        cat build/stress.in
        echo "--- sol ---";   cat build/stress.sol.out
        echo "--- brute ---"; cat build/stress.brute.out
        exit 1
    fi
done
echo "Stress test passed: $ITER iterations, no differences."
