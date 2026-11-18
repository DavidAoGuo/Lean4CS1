# Graph Folds and *Validation* Faults in Verified Code

TLDR: verification ≠ validation. Lean 4 nails one. You need both.
A small case study of a *seemingly* good formalization verified by
the Lean 4 kernel.

## Verification is *Not* All You Need

The prominent researcher into autoformalization of mathematics in
Lean, Kevin Buzzard, has written a non-technical [blog
post](https://xenaproject.wordpress.com/2026/11/12/and-the-proof-is-checked-in-lean/) on what can still go wrong even if you think you've formalized the mathematical theory of your domain in Lean 4 and proven your implementations correct against
it. Take five minutes to read it then continue through the rest of
this explanatory document.

The question, channeling Boehm,
*Did I build the thing right?* is orthogonal to the question, *Did
I build the right thing?* Basic software quality assurance (and make
no mistake; verified Lean is software) requires both. Lean 4 verifies.
It is not designed for, and is not trustworthy for, software
*validation*. This project thus comprises a case study centered on an
example of what did go wrong in a small use of autoformalization and
vibe coding of a *formally verified* but *not* carefully *validated*
software system, exactly as described by Kevin Buzzard, albeit not in
these terms.

This project started with a quick vibe-coding effort to produce an
example of the power of algorithms parameterized by diverse instances of
algebraic structures. In particular, one algorithm parameterized by a
concrete instance of a *semiring* yields diverse graph algorithms that
otherwise appear only loosely related, as though not grounded in a shared
foundation. The intended lesson was: you've seen folds parameterized
by polymorphic container type (list, tree, option, etc.). Now you see
parameterization by a concrete instance of an abstract algebra, of which a
semiring is the archetype. The core algorithm is defined against abstract `⊕`
and `⊗` operations and a single identity value, the one for `⊕`, with a choice
of, e.g., the min-plus algebra on `Option Nat`, the plus-times semiring on
`Nat`, or a cost-spectrum algebra on `List Nat`. The results
are respectively graph algorithms for (1) computing shortest paths,
(2) counting the total number of paths regardless of cost, and
(3) computing the complete multiset of path costs, from which the
minimum cost and the number of tied optimal routes can be extracted.

First, parameterizing algorithms
by diverse concrete instances of abstract algebraic structures can
reveal deep commonalities among seemingly diverse algorithms, and supports
an architectural style for verified code that separately specifies the
abstract theory (often uncomputable), diverse concrete, computable
implementations, and modular proofs that the implementations satisfy
the abstract formal specifications.

What this effort turned into fortuitously was a pretty accessible
case study illustrating what I'd consider the most threatening
of Buzzard's can-also-go-wrong failure modes: not errors in proofs but
in the statements of the very propositions to be proved, especially
when auto-formalized by inductive reasoning systems: generative AI.
To be clear, the construction here is broken in just the right way,
as a natural result of the AI methods used to produce it, to teach
my students with a reasonably accessible example from real-world work.

The repo, and most of the rest of this document, are thus written as
if they presented a *valid* (1) Lean-verified auto-formalization
of semiring-parameterizd graph folds; (2) three different graph algorithms, each a specialization by choice of an actual `Algebra` instance parameter, by definition verified against the abstract theory; and (3) its compilation into (a) three executables, one for each algorithm, to support th graphical explorer I vibe-coded for you, and (b) a Lean library that makes this work usable by other clients via Lean imports; and (4) the
interactive, animated, pedagogical, web-based GUI itself. This GUI lets you (a) write graph inputs as text, (b) select on of three `Algebra` instances and run the algorithm specialized to it on the given graph, and (c) step through an animation to see the algorithm fold your graph step by step down to a final answer. I found the animation helped me to better grasp how each of the specialized algorithms works.

I vibe-coded this whole project in Lean 4 and HTML in about two
hours, starting by having my AI auto-formalize an original work,
the paper by Mehryar Mohri, "Semiring Frameworks and Algorithms
for Shortest-Distance Problems" (2002).

I did not hand-check the generated code but Lean accepted all the proofs and my testing showed that it worked. In particular, through the GUI, I tested it to be sure it would reject inputs that failed satisfy the algorithm's crucial precondition: that the input graph be acyclic. Cyclic graphs require a different approach based on so-called fixed points. So was I done? Can I ship it to production (which here meant sending it as a working example to my students)?

At this point, it's time to put on your engineer's hard hat, start to think like a real engineer, and ask the most vital question of all: *what else could go wrong?* This project presents an unedited case of what *did* go wrong, even though Lean verified the code and when I tested it using the GUI it worked for both valid and invalid inputs, the latter of which it rejected explicitly. To help explain what still went wrong, it will help to see the system in action first.

## Quick Start

You need Lean 4 with Lake (via Elan) and **Python 3.8 or newer**. The local web
server that serves the GUI uses only the Python standard library, so there is
nothing to install and no `pip` step.

1. Open a terminal and `cd` into the `GraphFold` directory, the folder holding
   `lakefile.toml` and `web/`.
2. Build the Lean executables, then start the web server.

   ```sh
   lake build && python3 web/server.py
   ```

   Let `lake build` finish before you click anything on the page. The server
   runs the compiled binaries from `.lake/build/bin/`, and falls back to
   building on demand through `lake exe` when they are missing. That fallback
   takes longer than the server's twenty-second limit on a single request, so a
   button pressed against an unbuilt project reports a timeout rather than a
   result. Once built, each run answers in milliseconds.

3. Open the graphical tool in your browser at [http://127.0.0.1:8787](http://127.0.0.1:8787).
   In a VS Code Dev Container or Remote SSH window, forward port `8787` in the
   **Ports** tab and open the forwarded address.
4. Choose **Shortest paths**, **Count paths**, or **Optimal routes**. These choices select the tropical (min-plus), plus-times `Nat`, and cost-spectrum instances, respectively. Click **Load trace**, then **Play** or **Next** below the graph to animate the fold. Edit the edge
   list to try a different graph, or click **Reset example** to restore it.

Press **Ctrl+C** in the server terminal to stop the tool.

This formalization has not yet been rigorously checked. If you find an issue,
please report it in the [GraphFold issue tracker](https://github.com/kevinsullivan/GraphFold/issues)
or send a pull request.

## Overview

GraphFold presents a formalized **theory of generalized folds over directed acyclic graphs (DAGs)**, parameterized by the choice of an algebra—typically a semiring. A GUI lets you enter graph specifications and animate execution traces for three distinct graph algorithms, each selected by choosing a spceific, concrete `Algebra` instance. Rather than treating shortest-path calculation, path counting, and path-cost enumeration as unrelated programs, it reveals their shared mathematical structure: values propagated along edges are combined at each vertex according to algebraic operations chosen for the particular problem. A single graph-recursion pattern consequently yields several notably different graph algorithms.

The project also illustrates a broader role for dependent type theory. **Beyond enabling verification of individual programs, an expressive type system allows the common mathematical foundations of distinct computations to be represented explicitly as reusable definitions, specifications, and proofs.** In Lean 4, the algebra and graph dependency structure can be separated from implementations, while independently developed *proof bridges* establish how each concrete implementation realizes the abstract recurrence. The objective is not merely to verify three algorithms but to understand, in a precise and reusable way, *why they are instances of the same theory*.

For a vertex `v`, the governing equation is

$$
F(v)=b(v)\oplus\sum_{u\to v}\bigl(F(u)\otimes w(u,v)\bigr).
$$

- `F(v)` is the value computed at `v`: the quantity the fold produces (e.g., shortest-path cost, number of paths, or the multiset of all path costs to `v`, depending on the algebra chosen).
- `b(v)` is the initial, edge-independent contribution at `v` (e.g., the base case for a source vertex).
- `u → v` ranges over every edge into `v` from a predecessor `u`, tying the recurrence to the graph structure.
- `F(u)` is the already-computed value at predecessor `u`; a topological evaluation order guarantees it is known before `F(v)` is needed.
- `w(u,v)` is the weight on the edge from `u` to `v`.
- `⊗` *extends* a predecessor's value across an edge, combining `F(u)` with `w(u,v)` into that edge's contribution to `v`.
- `Σ` (over all `u → v`) *aggregates* the contributions of all incoming edges into a single combined value.
- `⊕` then combines that aggregated value with the base contribution `b(v)` to produce `F(v)`.

**Why the equation uses both `⊕` and `Σ`.** They are the same operation at two
different arities. The small `⊕` is the binary operation the algebra supplies:
hand it two values and it combines them. The capital `Σ` is that operation's
*indexed* form, the result of applying it across a whole family of values, here
the contribution of every incoming edge `u → v`. The difference in arity is not
decoration. A vertex may have any number of incoming edges, so the aggregation
cannot be written as a single binary application, and the subscript `u → v` is
what ties it to the graph's shape.

**Read `Σ` as iterated `⊕`, not as ordinary addition.** The symbol is borrowed
from arithmetic, where `Σ` abbreviates repeated `+`. Here it abbreviates
repeated `⊕`, and `⊕` means whatever the chosen algebra says it means. In the
shortest-path instance `⊕` is `min`, so `Σ` takes a minimum over the incoming
edges. In the cost-spectrum instance `⊕` is list append, so `Σ` concatenates.
Only in the path-counting instance, where `⊕` genuinely is `+`, does `Σ` carry
its arithmetic meaning.

The case of **no** incoming edges is why the algebra must also supply an
identity. An empty `Σ` is the algebra's `zero`, so the equation collapses to
`F(v) = b(v) ⊕ zero`, which is `b(v)` by the `plus_zero` law. In the Lean
source this reading is literal rather than notional: `specStep` in
`GraphFold/Abstract/Core.lean` computes the `Σ` as
`r.incoming.foldr combine A.zero` and then applies the outer `⊕` as
`A.plus r.base incomingTotal`. Read the two together and the notation and the
code line up field for field.

Different choices of `⊕`, `⊗`, and `b` give different meanings to the same graph computation. GraphFold implements three examples: minimum path cost, number of paths, and the multiset of all path costs (from which minima and counts of optimal paths can be extracted). For finite DAGs, a topological evaluation order makes the recurrence a well-founded fold; cyclic graphs require a separate fixed-point or closure treatment and are outside the present executables' scope.

All of that is so cool. But engineering (as everyone knows) is not about cool. It's about
solving problems by technological means with *justified* confidence that the results won't
fail in ways that contribute to (or substantially risk) unacceptably harmful outcomes.
It's impressive-sounding when an AI reports, as mine did (and I quote it), that the system
is *fully tested, with no `sorry` anywhere.* That might warm the cockles of a programmer's
heart, but it shouldn't.

**Formalization scope.** GraphFold uses **Lean 4 / Lake, without Mathlib**, and term-mode proofs with explicit types. Its core `Algebra α` asks only for the two laws on `⊕` that the implemented recurrence and fold proofs actually use — associativity and a right identity (`zero`) — and imposes no laws on `⊗` at all; a separate `SemiringLaws` record states the stronger axioms of a full semiring (commutativity of `⊕`, associativity of `⊗`, an identity `one` for `⊗`, etc.). Consequently, the implementation bridges certify the recurrence at the abstraction level actually used; they should not be mistaken for proofs of every semiring law or for graph-theoretic correctness over arbitrary cyclic graphs. The source code and tests are intended as a pedagogical formalization, and building them with Lean remains necessary to check kernel acceptance.

## 1. Project organization

| File                                                      | Purpose                                                                                                                        |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `GraphFold/Abstract/Core.lean`                            | Algebra and semiring-law interfaces, graph rows, right-fold recurrence, relational `Derives` specification, generic fold lemma |
| `GraphFold/Implementations/Shortest.lean`                 | Min-plus shortest-cost implementation and source/weight adapter                                                                |
| `GraphFold/Implementations/Paths.lean`                    | Natural-number path-count implementation and source/edge adapter                                                               |
| `GraphFold/Implementations/Optimal.lean`                  | Cost-spectrum interpreter and minimum-cost/tie-count summarizer                                                                |
| `GraphFold/Bridges/Shortest.lean`                         | Term-mode proof that shortest-cost implementation satisfies `Derives`                                                          |
| `GraphFold/Bridges/Paths.lean`                            | Independent term-mode proof for path counts                                                                                    |
| `GraphFold/Bridges/Optimal.lean`                          | Independent term-mode proof for the full path-cost spectrum                                                                    |
| `GraphFold/IO/Format.lean`                                | One shared edge-list parser, validation, conversion to graph rows                                                              |
| `GraphFold/Trace.lean`, `TraceMain.lean`                  | Lean-level trace events, algebraic fold replay, runtime result agreement check, CLI transport                                  |
| `ShortestMain.lean`, `PathsMain.lean`, `OptimalMain.lean` | Original command-line executable entry points                                                                                  |
| `Tests/Main.lean`, `test-cli.sh`                          | Library examples, parser checks, executable integration tests                                                                  |
| `examples/`                                               | Example input files, including deliberately invalid input                                                                      |
| `web/server.py`, `web/public/`                            | Local HTTP server and interactive HTML/SVG interface                                                                           |
| `web/test/`                                               | HTTP integration tests independent of the Lean toolchain                                                                       |

The parser and the algebraic interpretation are **separate**. The input graph
contains vertex identifiers, a designated source, and directed edges with
nonnegative integer labels. It contains **no algebra-specific base values**.

## 2. Build and run

First, in VS Code, click on any `.lean` file in this project. If Lean is
already installed natively, this just confirms it; if not, it triggers a
one-time download of [elan](https://lean-lang.org/lean4/doc/setup.html),
Lean 4, and Lake — wait for that download to finish before continuing.

```sh
cd GraphFold
lake update
lake build
lake exe graphfold_tests
lake exe shortest examples/diamond.txt
lake exe paths examples/diamond.txt
lake exe optimal examples/diamond.txt
lake exe optimal examples/tied-optima.txt
bash test-cli.sh
```

The `lean-toolchain` file specifies `leanprover/lean4:v4.35.0`.

## 3. Textual graph input format

Each nonblank, noncomment line is a declaration. Comments begin with `#`;
inline comments are also allowed. The first two declarations are mandatory:

```text
vertices N
source S
edge FROM TO WEIGHT
edge FROM TO WEIGHT
...
```

- `vertices N` declares **N vertices**, numbered from `0` through `N-1`.
- `source S` selects the vertex from which paths are evaluated.
- `edge U V W` declares a **directed edge U → V** with nonnegative cost `W`.
- There may be zero or more edge lines, in any order; repeated lines represent
  distinct parallel edges (and count separately as paths).
- Each edge must satisfy `0 ≤ U < V < N`. This is the input's **topological
  ordering constraint**: all edges move from an earlier to a later numbered
  vertex. It excludes cycles and permits a single forward fold.
- The parser reports invalid headers, integers, endpoints, and ordering.

For example, `examples/diamond.txt` is:

```text
# A four-vertex DAG with five weighted directed edges.
vertices 4
source 0
edge 0 1 2
edge 0 2 5
edge 1 2 3
edge 1 3 1
edge 2 3 1
```

The graph is visualized textually as:

```text
0 --2--> 1 --1--> 3
 \        |        ^
  5       3        1
   \      v       /
    ----> 2 -----
```

The **same input file** can be given to all three executables. The integer labels
are costs for shortest paths, but **not multiplicities** for path counting.
The path-count executable interprets every listed edge as multiplicity `1`.

### Shortest-path specialization (min-plus)

The carrier is `Option Nat`, with `some d` indicating a cost and `none`
representing infinity. `⊕` chooses the minimum and `⊗` adds costs. The
adapter `Shortest.fromRaw S` sets `b(S) = some 0`, `b(v) = none` otherwise,
and preserves all edge costs as `some W`.

```sh
lake exe shortest examples/diamond.txt
```

Expected output:

```text
0: 0
1: 2
2: 5
3: 3
```

Vertex `3` can be reached via `0 → 1 → 3` at cost `2 + 1 = 3`. The alternative
`0 → 2 → 3` costs `5 + 1 = 6`, and `0 → 1 → 2 → 3` costs `2 + 3 + 1 = 6`.

### Path-count specialization (natural-number plus-times)

The carrier is `Nat`; `⊕` adds counts and `⊗` multiplies by an edge
multiplicity. The file adapter `Paths.fromRaw S` sets `b(S) = 1`, `b(v) = 0`
for other vertices, and maps **every edge label to multiplicity 1**. This
counts paths in the graph independently of their costs, including one empty
path at the source.

```sh
lake exe paths examples/diamond.txt
```

Expected output:

```text
0: 1
1: 1
2: 2
3: 3
```

There is one path to vertex `1`; two to vertex `2` (`0 → 2` and `0 → 1 → 2`);
and three to vertex `3` (`0 → 1 → 3`, `0 → 2 → 3`, and `0 → 1 → 2 → 3`).

Unlike the executable file adapter, the lower-level `Paths.run` library
function still accepts arbitrary natural-number edge multiplicities and base
values. This is useful for illustrating the general algebra.

### Optimal-route specialization (cost-spectrum append-plus)

The third interpretation answers **two questions simultaneously**: what is the
cheapest route, and *how many different routes attain that cost*? This is a
useful distinction in scheduling, routing, and redundancy analysis. For
example, if two equally inexpensive routes exist, losing one of them need not
increase the minimum cost.

Rather than computing only a `(cost, number-of-ties)` pair, this pedagogical
implementation uses the carrier `Spectrum := List Nat`: each entry is one
route's **total cost**, with duplicates intentionally retained.

- `⊕` is list concatenation (`++`). Alternative routes keep their identities
  as separate entries, even when their costs agree.
- `⊗` is a Cartesian product of alternatives, adding two path costs. For
  example, extending `[2, 5]` by an edge of cost 3 gives `[5, 8]`.
- `0` for the alternative operator is `[]`; the empty source path has
  spectrum `[0]`.
- At the end, `Optimal.summarize` extracts the minimum and how many times it
  occurs. It returns `none` for an unreachable vertex.

For the diamond input, the complete spectra are:

| Vertex | All route costs (`Optimal.run`) | Minimum | Cheapest routes |
| ------ | ------------------------------- | ------: | --------------: |
| 0      | `[0]`                           |       0 |               1 |
| 1      | `[2]`                           |       2 |               1 |
| 2      | `[5, 5]`                        |       5 |               2 |
| 3      | `[3, 6, 6]`                     |       3 |               1 |

```sh
lake exe optimal examples/diamond.txt
```

```text
0: min=0,count=1
1: min=2,count=1
2: min=5,count=2
3: min=3,count=1
```

The extra example `examples/tied-optima.txt` has two **equally cheapest** routes
to vertex 3, both of cost five:

```text
vertices 4
source 0
edge 0 1 2
edge 0 2 1
edge 1 3 3
edge 2 3 4
```

```sh
lake exe optimal examples/tied-optima.txt
# Vertex 3: min=5,count=2
```

**Algebraic nuance (advanced):** Lists form an associative monoid under concatenation,
which is *all the abstract `Algebra` interface and the fold proof require*.
But concatenation is not commutative, so this concrete list carrier is **not**
a full commutative-addition semiring. Mathematically, the spectrum represents
a finite bag (multiset) of route costs; quotienting by permutation, or using a
finite cost-to-multiplicity map with convolution, yields the familiar
**polynomial / generating-function semiring**. If `x^d` denotes a path of cost
`d`, the diamond graph has the generating polynomials
`P₂(x) = 2x⁵` and `P₃(x) = x³ + 2x⁶`.

This is an intentionally transparent introductory implementation: its
**enumeration can grow exponentially** in the number of vertices. A useful
advanced exercise is to replace the spectrum list with canonical cost
coefficients, or a direct tropical-with-tie-counting semiring, and prove a new
refinement theorem without enumerating every route.

## 4. Using GraphFold as a library

```lean
import GraphFold
open GraphFold

-- This is the graph as converted by the shared edge-list parser:
def raw : Graph Nat :=
  [ { base := 0, incoming := [] }
  , { base := 0, incoming := [(0, 2)] }
  , { base := 0, incoming := [(0, 5), (1, 3)] }
  , { base := 0, incoming := [(1, 1), (2, 1)] } ]

-- Each adapter supplies the specialization's source value and edge semantics.
#eval Shortest.run (Shortest.fromRaw 0 raw)
-- [some 0, some 2, some 5, some 3]

#eval Paths.run (Paths.fromRaw 0 raw)
-- [1, 1, 2, 3]

#eval Optimal.run (Optimal.fromRaw 0 raw)
-- [[0], [2], [5, 5], [3, 6, 6]]

#eval Optimal.runSummary (Optimal.fromRaw 0 raw)
-- [some (0, 1), some (2, 1), some (5, 2), some (3, 1)]

-- Term-mode proofs connecting computed results to the abstract recurrence:
example : Satisfies Paths.algebra (Paths.fromRaw 0 raw)
    (Paths.run (Paths.fromRaw 0 raw)) :=
  Paths.sound (Paths.fromRaw 0 raw)

example : Satisfies Shortest.algebra (Shortest.fromRaw 0 raw)
    (Shortest.run (Shortest.fromRaw 0 raw)) :=
  Shortest.sound (Shortest.fromRaw 0 raw)

example : Satisfies Optimal.algebra (Optimal.fromRaw 0 raw)
    (Optimal.run (Optimal.fromRaw 0 raw)) :=
  Optimal.sound (Optimal.fromRaw 0 raw)
```

The abstract `Graph α` is a list of rows, with a base value and incoming edges
for each vertex. `Format.toGraph` maps the file's edge declarations into
those rows; the three adapters independently assign their bases and edge values.

## 5. Proof architecture and explicit typing

`specStep` uses a **right fold** of incoming edge contributions. Each concrete
`step` uses a **left fold**: unlike `foldr`, which combines the rightmost
element first and works inward (`f x1 (f x2 (... (f xn init))))`), `foldl`
walks the list left to right, combining the accumulator so far with each next
element (`f (... (f (f init x1) x2) ...) xn`). The generic `foldl_eq_foldr`
theorem proves their agreement from monoid laws. Each independent bridge constructs a `Derives`
certificate recursively, showing that its `run` produces the abstract
specification's value at each vertex. All proofs use **term mode** (no `by`
blocks or tactics), with annotated argument and important intermediate types.

Types you will see:

| Lean syntax          | Meaning                                                     |
| -------------------- | ----------------------------------------------------------- |
| `Nat`                | Nonnegative integers, also used for vertex IDs              |
| `Option Nat`         | `some n` is a finite cost; `none` is infinity               |
| `Optimal.Spectrum`   | `List Nat`: all path costs, including duplicates            |
| `Option (Nat × Nat)` | Minimum cost and number of cheapest routes (or unreachable) |
| `List α`             | List of elements having type `α`                            |
| `Nat × α`            | Incoming edge: predecessor index and algebraic edge weight  |
| `Graph α`            | List of `Row α`, in vertex-number order                     |
| `Algebra α`          | Operations `plus`, `times`, and required aggregate laws     |
| `Satisfies A g out`  | Proposition that output has a recurrence derivation         |
| `List.rec`           | Structural recursion constructing data or proof terms       |

For instance, the path-count bridge contains an explicitly typed induction
hypothesis of the following mathematical shape:

```lean
ih : ∀ (pre : List Nat),
  Derives algebra pre rs (runFrom pre rs)
```

The proof is valid for any already-computed prefix and remaining row list.
The separate DAG ordering check guarantees that, for parsed files, every
referenced predecessor is in the computed prefix when evaluated.

## 6. Scope and limitations

The algebra and abstract recurrence can be *stated* for arbitrary finite graphs.
The sequential implementation assumes all predecessors are processed earlier;
this is enforced by the **file parser**'s `FROM < TO` constraint. Cyclic graphs
are *not* within the scope of our algorithm, and need a separate fixed-point
semantics and corresponding algorithm and proof.

`SemiringLaws` states the stronger full-semiring axioms, but none of the three
implementations need to or do fully prove their operations satisfy all of them.
Each implementation proves only the smaller `Algebra` laws that the fold proof
needs.

Suggested exercises.

Picking one implementation and defining a `SemiringLaws` instance for
it (proving, for example, that `⊕` is commutative or that `⊗` distributes
over `⊕`) would be a good follow-on exercise.

List-based prefix appends are intentionally simple rather than asymptotically
optimized, and profiling for performance bugs and fixing them would be another.

Or do it all. Prove the uniqueness of `Derives`. Certify the full semiring laws.
Derive an optimized implementation by replacing list accumulation with arrays
or hash tables, and prove that the fast version is equivalent to the
proof-friendly list-based one. Add a general topological-sort phase. Formalize
a *fixed-point* semantics for cycles.

## 7. Interactive local HTML interface

A zero-dependency **Python 3** HTTP server, built on the standard library's
`http.server`, serves the graphical interface.
The browser provides **live graph rendering** with native SVG (a small,
self-contained alternative to D3). It does **not** implement any graph
algorithm: each of the three Run buttons invokes its corresponding compiled
Lean executable through the server, using the **exact contents of the editor**
as a temporary `.txt` input file. The temporary file is removed after the
run. Each result is displayed by vertex in the page.

For the build and launch commands, see [Quick start](#quick-start).
The server listens on **127.0.0.1 only** by default. To choose a different port:

```sh
PORT=9090 python3 web/server.py
```

An explicit `HOST` environment variable can change the bind address. Do not
set `HOST=0.0.0.0` on an untrusted network: the interface has no authentication
and permits invoking the local Lean executables with user-supplied graph files.

### User interface

- **Top**: **Shortest paths**, **Count paths**, and **Optimal routes**
  buttons submit the input to their corresponding Lean executables. The output area shows a field for
  each vertex or a detailed error emitted by the Lean parser/executable.
- **Below that, left**: an editable graph text area. The header must be
  `vertices N`, `source S`, followed by zero or more `edge U V W` lines. `#`
  comments and blank lines are allowed. As the text changes, syntax errors
  are shown.
- **Below that, right**: an automatically updated SVG visualization of the
  directed graph. Vertices are positioned in topological layers, edges have
  arrows, and edge weights appear beside the edges. The source is
  highlighted. Directly beneath it sit the trace playback controls (**Load
  trace**, **Previous**, **Play**, **Next**, **Restart**, and the step-delay
  slider) and, below those, a plain-text step counter, title, explanation,
  and equation for the current trace step — all right under the graph
  they're animating.
- The visualizer imposes a display limit of 150 vertices and 800 edges. This
  is a browser rendering limit, not part of the Lean theory. The Lean input
  parser additionally requires `U < V`, so the executable graph is a DAG.

The server first tries the binaries generated by `lake build` in
`.lake/build/bin/`, falling back to `lake exe` if needed. A missing Lean/Lake
installation or an unbuilt project is reported in the output panel rather
than silently producing a JavaScript-computed result.

### Web interface tests

```sh
python3 -m unittest discover -s web/test
```

These test static HTML delivery, endpoint input validation, Lean-runner
invocation boundaries, output, and error propagation. They use a **fake runner**
to exercise the HTTP layer independently of Lean, and the Python interpreter
itself stands in for a Lean executable when checking the process layer's
output bound and timeout. For true end-to-end Lean checks, first execute
`bash test-cli.sh`, and then use the browser buttons. No web assets are loaded
from a CDN and no packages need to be installed.

## 8. Animated execution traces

The local interface also supports a **runtime-checked trace replay** of all
three specializations. This is useful in class or when learning the connection
between a graph recurrence and a fold. The playback controls and the
step-by-step explanation both sit directly beneath the graph display, right
below the graph they're animating.

1. Edit the graph input, which instantly updates the SVG on the right.
2. Click **Shortest paths**, **Count paths**, or **Optimal routes**. The existing
   Lean executable calculates and displays the answer. The separate Lean `trace`
   executable records the computation and loads its timeline at step one.
3. Click **Play** for timed playback; **Pause**, **Previous**, **Next**, or
   **Restart** to explore. The step-delay slider defaults to **1 second**
   and ranges from **0.35 to 4 seconds**.
4. The active destination vertex turns **gold**; the predecessor turns **blue**;
   the active edge is highlighted. The explanation names the current step,
   describes in plain language what it's doing, and shows the underlying
   equation with the edge's weight, predecessor value, contribution, and
   accumulator before and after the step.

The local endpoint `POST /api/trace` takes the same JSON request as `/api/run`:
`{"mode":"shortest", "graph":"vertices 4\\nsource 0\\n..."}`. The server
invokes the **Lean trace executable**, not a JS reimplementation of the fold:

```sh
lake exe trace shortest examples/diamond.txt
lake exe trace paths examples/diamond.txt
lake exe trace optimal examples/diamond.txt
```

The trace line protocol is deliberately simple: `start|vertex|base`,
`edge|vertex|predecessor|weight|prior|contribution|before|after`, and
`finish|vertex|value`. The browser parses and *replays* these events without
performing algebra. The tracer computes a left fold from the same `Algebra`
operations and specialization adapters; before emitting a trace, its executable
**checks that its final values exactly match the corresponding original Lean
implementation**, failing if they differ. This is a runtime consistency check,
**not a Lean theorem of trace refinement**. The existing term-mode soundness
proofs continue to relate each original evaluator to the abstract recurrence.

The trace is held in browser memory and discarded whenever the input changes.
For large or densely connected graphs, choose step-by-step controls rather
than rapid playback. The spectrum example may produce very long text because
it deliberately enumerates every path cost.

### Animation testing and limitations

The HTTP tests cover the trace endpoint's delegation to the injected runner:

```sh
python3 -m unittest discover -s web/test
```

A Chromium visual inspection was performed with a controlled synthetic trace,
at 1440px desktop and 768px tablet widths. Its five diamond edges and the
three simultaneous highlight roles were visually inspected; the page had no
horizontal overflow at tablet width. Screenshots are included as
`animation-desktop.png` and `animation-tablet.png`. The optional
`python web/test/browser_smoke.py` replays a synthetic trace in Chromium,
checks Play/Pause, stepping, validation, active highlights, and overflow, and
regenerates the screenshots (requires Python Playwright and Chromium).

### Interface styling

The local interface uses a light, Material-inspired visual system: neutral surfaces,
subtle section borders, conventional controls, restrained typography, and muted green,
blue, and amber accents. Amber indicates the current vertex/edge in an execution
trace, while blue identifies its predecessor. The editor, SVG graph, and execution
controls remain functional without external fonts, stylesheets, or JavaScript libraries.

The desktop and tablet screenshots are generated by `python web/test/browser_smoke.py`
using Chromium with a controlled trace fixture.

## 9. What Went Wrong?

AI + proof assistants represent a radical advance in science and
technology. In its current state, this project is the result of about
two hours of vibe coding in Lean. That's remarkable. It's all based on
well developed mathematics: the algebraic path problem is decades old
and well-studied since 1971. It's all "verified" — the proofs compile,
there's no `sorry` anywhere, the test suite passes, the CLI and web UI
both produce correct-looking answers on every input anyone has tried.
So we're good, right?

No. Again, think like an engineer with a moral obligation to protect
users from errors that cause unacceptable harms. Real engineers ask
relentlessly *what else could go wrong* and then they make sure that
doesn't happen.

Knuth is widely quoted as having warned: "Beware of bugs in the above
code; I have only proved it correct, not tried it." The failure modes
he had in mind included compiler (today kernel) bugs, hardware errors,
and *specification gaps*. Some have interpreted Knuth as shilling for
testing, but what he was really telling us is that a proof only proves
that the code satisfies the specification, not that the specification
itself is right. That's the failure mode this case study is about.

To see proofs and a code-based explanation of the failure, see the file
called [`whatCanGoWrongSpecGaps.lean`](whatCanGoWrongSpecGaps.lean). An
AI, prompted to check our formalization against the actual published work,
found the failure in this case within a minute: `Shortest.run`, `Paths.run`,
and `Optimal.run` all accept a graph with a genuine cycle and silently
return a plausible-looking answer. The file-based CLI and web UI are
protected, as the parser rejects `FROM < TO` violations. The *library*
API, on the other hand, which the "Using GraphFold as a library" section
above tells you to use directly in Lean — does not. The soundness theorems
(`Shortest.sound`, `Paths.sound`, `Optimal.sound`) typecheck without error
on cyclic inputs, because `Derives`/`Satisfies` never asserted acyclicity
in the first place. The proof isn't wrong. It just proves less than you
think, because the AI got the *statement* of the theorem wrong.

You can mostly trust vibe-coded proofs to *verify* your construction, but
the claims that they're actually proving are up to *you* to validate.

A specification can have exactly the same kind of gap as an implementation.
Curry-Howard tells us that large proof constructions are just *software*.
It's thus vulnerable to oh so many other software engineering failure modes.
Examples of incorrect theorem *statements* could include a missing
precondition (as here); a false precondition, in which case anything can be
proved *vacuously*; or a check that is correct but is never actually called
(as also seen in this case).

Formally *verified* vibe-coded Lean 4 does *not* entail readiness to ship, as
it bypasses the vital orthogonal process of *validating* what has been vibed.
Knuth's quip about proving code correct without trying it could be read as
"testing still matters." But his real message was that even with proofs, much
can still go wrong including in particular gaps in the *specifications* proved
to have been satisfied. This is why, in my view, fluency in reading formal
specifications in higher-order type theories is now such an important skill.

### The Actual Error

Further investigation shows one fundamental gap: Mehryar Mohri's original
publication, "Semiring Frameworks and Algorithms for Shortest-Distance
Problems" (2002), always defines the target quantity — the
shortest distance itself, for example — independently of any algorithm, as a
sum over the actual set of paths. He only ever equates an algorithm's output
to that target *under an explicit hypothesis* (his Corollary 2: the graph is
acyclic).

GraphFold simply lacks a formalization of that independent target and
that hypothesis in its formalization of the abstract theory, `Core.lean`.
`Derives`/`Satisfies` only assert that two renderings of `specStep`'s
recursive unfolding agree with each other — a claim about the algorithm's
self-consistency, whereas what's needed is a proof of correctness against
the actual, independent mathematical theory. With no independent truth,
there is nothing for a cyclic input's output to be wrong *relative to*.
The `Algebra` laws themselves are not erroneous here. The error is that
an essential hypothesis was dropped during machine formalization. It's
present in the original peer-reviewed, human-derived mathematics, but
was simply dropped by Claude when it ingested and auto-formalized that
earlier work.

This case study suggests that fatal specification errors can plague even
the simplest of Lean formalizations, particularly AI-generated ones. So how
might one, not *verify* a major claim with proof of tens of millions of lines
of Lean code, but *validate* the proposition that the specifications of what
is to be proved reflect the actual mathematics of the domain? Hint: it's now
a large-scale software engineering problem in all respects: intellectual control,
careful modularizations, both automated and human code reviews, regression and
other forms of testing, process quality control.

The programming languages, software engineering, and AI research communities
have given us practically miraculous tools for verifying mathematical claims.
Validating the claims themselves remains an unsolved problem for formal code
at scale. Indeed, building on the remarkable success in research mathematics
applications of formal verification of very hard propositions requiring very
large proof constructions, the problem of *validation* remains largely open.
Building the thing right (it's proven) is *not* the same as building the
right thing.
