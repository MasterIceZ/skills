# Problem-type heuristics and common bad solutions

Load this when identifying the problem type (to choose edge, special, and adversarial subtypes) and when writing `wa_*` and `tle_*` solutions.

## Problem-type heuristics

| Type | Signals | Edge subtypes | Adversarial subtypes |
|------|---------|--------------|----------------------|
| Array/sequence | "N integers", "sequence" | min/max/sorted/reverse/all-equal | sorted asc (breaks O(N²)), all-equal |
| Permutation | "permutation of 1..N" | identity, reverse, random | cyclic shift, reverse |
| Graph | "N nodes M edges" | N=2, tree (M=N-1), complete (M=N(N-1)/2), star | star, path/chain, bipartite |
| Tree | "N nodes, N-1 edges" | N=2, chain (bamboo), star, single path | bamboo (depth=N, breaks recursion), star |
| String | "string of length N" | N=1, all 'a', all 'z', alternating "ab…", full palindrome | all 'a' (max palindromic partitions), "abababab…" |
| Grid | "N×M grid" | 1×M, N×1, checkerboard, all same | all same char, checkerboard |
| Geometry | "N points" | N=1, all collinear, convex hull | collinear (breaks some convex hull), all same point |
| Multiple T-cases | "first line T" | max T min-N cases; one max-N single case | max T, each case adversarial |

Tree problems: include a bamboo (chain of N nodes); recursive solutions without an iterative DFS stack-overflow on it.
Graph problems: include a path graph and a star, and a near-complete graph when M allows it.

## Structural shapes for gen_special

- Trees: complete binary tree, star, bamboo, Fibonacci-heavy-path, caterpillar
- Strings: all-distinct chars, pure palindrome, period-2 pattern, Thue–Morse sequence
- Numbers: all prime, all powers of 2, all Fibonacci, arithmetic progression
- Graphs: bipartite, complete bipartite, clique plus isolated vertices, grid graph
- Permutations: cyclic shift by K, bitonic (up then down), many fixed points

## Wrong-answer patterns (wa_*.cpp)

| Problem type | Common wrong approach | Breaks on |
|-------------|----------------------|-----------|
| Sorting/searching | Greedy picks local minimum without lookahead | Carefully constructed anti-greedy input |
| DP | Wrong base case (dp[0]=1 when it should be 0) | Small inputs near the base case |
| Graph shortest path | BFS on weighted graph (correct for unit weights only) | Graph with varying edge weights |
| MST | Always picking cheapest edge from node 1 (wrong Prim) | Non-trivial MST structure |
| String | Not handling overlapping patterns, off-by-one in indices | Strings with many overlapping occurrences |
| Geometry | Not handling collinear/degenerate cases | All-collinear point sets |
| Counting | Forgetting modular arithmetic, overflow with int instead of long long | Large values near INT_MAX |
| Graph/Tree | Assuming connected input without checking | Disconnected graph |
| Binary search | Wrong predicate direction or off-by-one in lo/hi | Boundary answer at lo or hi |

## TLE patterns (tle_*.cpp)

| Problem type | TLE approach | Correct complexity | TLE complexity |
|-------------|-------------|-------------------|----------------|
| Sequence queries | Recompute from scratch for each query | O(N + Q) with prefix sums | O(N·Q) |
| Sorting-based | Insertion sort or selection sort | O(N log N) | O(N²) |
| Graph BFS/DFS | Rebuild adjacency list every call | O(N + M) once | O(N·(N + M)) |
| String matching | Naive double loop | O(N) KMP/Z-function | O(N²) |
| DP with transitions | Extra loop over all states for each transition | O(N log N) with monotone deque | O(N²) |
| Segment tree | Iterate all elements for range query | O(log N) per query | O(N) per query |
| Number theory | Trial division in inner loop | O(sqrt(N)) per number | O(N) per number |
