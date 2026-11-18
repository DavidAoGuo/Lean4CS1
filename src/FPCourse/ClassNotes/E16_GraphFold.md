```lean
import GraphFold
```

# Graph Folds and Specification Validation

In [Generalized Fold](./E10_GeneralizedFold.md), we used one operation over
several container shapes. Here we fix a graph shape and vary the algebra. The
same graph fold can answer whether a vertex is reachable, how many paths reach
it, or what the cheapest path costs. We will also inspect the theorem that
connects each of GraphFold's implementations to the recurrence.

## Fold over incoming edges

GraphFold stores each vertex as a `Row` with a base contribution and a list of
`(predecessor, weight)` pairs. In topological order, every predecessor of vertex
`v` has already been processed when we reach `v`.

$$
F(v) = b(v) \oplus \sum_{u \to v} \bigl(F(u) \otimes w(u,v)\bigr)
$$

`times` extends a result along one edge. `plus` combines alternatives arriving
at the same vertex. `zero` represents the empty collection of alternatives.
The `Algebra` structure supplies these operations, associativity of `plus`,
and its right identity law. Read the fields with `#print`.

The equation writes the same operation twice, at two arities. The small `⊕` is
the binary `plus`: give it two values and it combines them. The capital `Σ` is
its indexed form, `plus` applied across a whole family of values, here one
contribution per incoming edge `u → v`. A vertex can have any number of
incoming edges, so that aggregation is not a single binary application, and the
subscript is what ties the recurrence to the graph.

Read `Σ` as iterated `⊕`, not as ordinary addition. The symbol comes from
arithmetic, where it abbreviates repeated `+`, but here it abbreviates repeated
`plus`, whatever the instance makes `plus` mean. For shortest paths `plus` is
`min`, so `Σ` minimizes; for cost spectra it is list append, so `Σ`
concatenates. Only for path counting is it ordinary addition.

The empty family is why `zero` has to exist. Aggregate over no edges and you
get `zero`, so the equation reduces to `F(v) = b(v) ⊕ zero`, which `plus_zero`
turns into `b(v)`. That is literally how `specStep` is written: the `Σ` is
`r.incoming.foldr combine A.zero`, and the outer `⊕` is the final
`A.plus r.base incomingTotal`. Compare the two `#print` outputs below.
```lean
namespace E16

open GraphFold

#print Algebra
#print specStep
```

## The same semirings in databases and graphs

Recall our in-class example of parameterizing positive relational algebra
over a commutative semiring. A tuple carries an annotation. A join multiplies
the annotations of tuples used together. Union and projection add the
annotations of alternative ways to produce the same output tuple. With
`Bool`, the annotation tells you whether a tuple appears (**set semantics**).
With `Nat`, it counts its multiplicity (**bag semantics**). With provenance
polynomials over `Nat`, variables identify input tuples and the polynomial
records how those tuples contribute to the output.
[Green, Karvounarakis, and Tannen, *Provenance Semirings*](https://courses.cs.washington.edu/courses/cse544/11wi/lectures/tannen-semirings.pdf)

For example, take the [composition of relations](./E18_Relations.md), developed
in a later lecture. A join on the intermediate `b` followed by projection
onto `(a, c)` gives an annotated version of the same operation.

$$
(R ; S)(a,c) = \sum_b \bigl(R(a,b) \otimes S(b,c)\bigr)
$$

If two matches use input tuples tagged `p` and `q` for one match and `r`
and `s` for the other, provenance records `p * q + r * s`. Setting each
annotation to `true` in the Boolean semiring gives `true`. Setting each
to `1` in the natural-number semiring gives `2`.

The graph fold uses the same two operations for the same reasons. It
multiplies to extend a path along an edge and adds to combine alternative
paths. The choice of semiring determines what the answer tells you.
[Mohri, *Semiring Frameworks and Algorithms for Shortest-Distance Problems*](https://cs.nyu.edu/~mohri/pub/jalc.pdf)

| Algebra | Combine alternatives | Extend a path | Zero / one | Graph result |
| --- | --- | --- | --- | --- |
| Boolean (`Bool`) | OR | AND | `false` / `true` | Is there a path at all? |
| Natural numbers (`Nat`) | Add counts | Multiply counts | `0` / `1` | How many paths are there? |
| Tropical (`Option Nat`) | Minimum | Add costs | `none` (infinity) / `some 0` | What is the minimum cost? |
| Cost spectrum (`List Nat`) | Append | Add costs pairwise | `[]` / `[0]` | What does every route cost? |

The first three are genuine semirings. The fourth is not: list append is not
commutative, so the cost spectrum satisfies only the weaker `Algebra` laws the
fold proof actually needs. That is the point of including it.

**Be careful which three you mean.** The GUI offers the tropical,
natural-number, and cost-spectrum algebras, as **Shortest paths**, **Count
paths**, and **Optimal routes**. Boolean reachability is not one of its
buttons; it appears only in the Lean code below. So the shortest-path button is
the tropical instance, never the Boolean one, and the optimal-routes button is
the cost spectrum, not the tropical one.

The source starts with one empty path, whose annotation is the algebra's
multiplicative identity. The other vertices start with the additive identity.
In the tropical algebra, an unreachable vertex has infinite cost, and an
empty path costs zero.

## One fold, four algebras

`foldGraph` runs the project's `specStep` at every vertex. The same function
handles all four cases, the cost spectrum included. GraphFold's `Algebra`
interface carries the operations and the laws used by the fold proofs. It has
no `one` field: the multiplicative identity in the table above is what each
adapter places at the source. The remaining semiring axioms are stated
separately in `SemiringLaws`, which nothing in the project instantiates.
```lean
def foldGraph {α : Type} (algebra : Algebra α) (graph : Graph α) : List α :=
  graph.foldl (fun done row => done ++ [specStep algebra done row]) []

def reachabilityAlgebra : Algebra Bool where
  zero := false
  plus := Bool.or
  times := Bool.and
  plus_assoc := Bool.or_assoc
  plus_zero := Bool.or_false

def asReachability (source : Nat) (graph : Graph Nat) : Graph Bool :=
  graph.mapIdx fun vertex row =>
    { base := vertex == source
      incoming := row.incoming.map fun (predecessor, _) => (predecessor, true) }
```

The source is vertex 0. The route through vertex 1 costs `2 + 3 = 5` and
the route through vertex 2 costs `1 + 4 = 5`. Predict the result at vertex 3
for each semiring. The Boolean adapter marks every listed edge as present.
`Paths.fromRaw` assigns each listed edge multiplicity one, and
`Shortest.fromRaw` keeps the costs.
```lean
def tiedRoutes : Graph Nat :=
  [ { base := 0, incoming := [] }
  , { base := 0, incoming := [(0, 2)] }
  , { base := 0, incoming := [(0, 1)] }
  , { base := 0, incoming := [(1, 3), (2, 4)] } ]

#eval foldGraph reachabilityAlgebra (asReachability 0 tiedRoutes)       -- [true, true, true, true]
#eval foldGraph Paths.algebra (Paths.fromRaw 0 tiedRoutes)              -- [1, 1, 1, 2]
#eval foldGraph Shortest.algebra (Shortest.fromRaw 0 tiedRoutes)          -- [some 0, some 2, some 1, some 5]
#eval foldGraph Optimal.algebra (Optimal.fromRaw 0 tiedRoutes)          -- [[0], [2], [1], [5, 5]]
```

The cost spectrum keeps every path cost instead of collapsing to one number.
The list preserves both copies of 5 because they come from different routes,
so the summary can report the number of tied minimum-cost paths. Tropical
aggregation would have discarded that evidence at the moment the two routes
met. `Optimal.run` below is the implementation's own left fold, and it agrees
with the `foldGraph` line above.
```lean
#eval Optimal.run (Optimal.fromRaw 0 tiedRoutes)      -- [[0], [2], [1], [5, 5]]
#eval Optimal.runSummary (Optimal.fromRaw 0 tiedRoutes)
-- [some (0, 1), some (2, 1), some (1, 1), some (5, 2)]
```

## Read the proof statement

`specStep` combines incoming contributions with a right fold. The implementations
use left folds, and their `step_refines` theorems establish equality at each row.
A `Derives` proof records the steps through the graph. `Satisfies` asks for
such a derivation starting with an empty list of computed values.

This is why understanding the abstract mathematics matters when AI
formalizes a problem and constructs its proofs. The semiring tells us what
quantity to specify over paths. The graph theory tells us when a single
pass in topological order computes that quantity. Inspect the types of the
bridge theorems. Where do they state those mathematical claims?
```lean
#print Satisfies
#check Paths.step_refines
#check Paths.sound
#check Shortest.sound
#check Optimal.sound
```

## The specification gap

Enter a cycle directly as a library value. Vertex 0 depends on vertex 1,
which in turn depends on vertex 0. When the evaluator needs vertex 1
during the first step, `lookup` uses the algebra's `zero` because vertex 1
has yet to be computed. The file parser checks that every edge goes from
a lower index to a higher one. The library entry point accepts rows
constructed directly in Lean.
```lean
def cyclicRoutes : Graph (Option Nat) :=
  [ { base := some 0, incoming := [(1, some 10)] }
  , { base := none,   incoming := [(0, some 100)] } ]

#eval isOrdered cyclicRoutes     -- false
#eval Shortest.run cyclicRoutes  -- [some 0, some 100]

example : Satisfies Shortest.algebra cyclicRoutes (Shortest.run cyclicRoutes) :=
  Shortest.sound cyclicRoutes
```

The proof checks because `Satisfies` describes the same sequential recurrence,
including the default value for missing predecessors. An independent
specification for shortest distance would define the paths from the source to
each vertex and take the minimum of their costs. A correctness theorem for the
DAG evaluator would then connect its output to that specification under a
topological-order hypothesis.

**In class.** Suppose we add an `isOrdered` hypothesis to `Shortest.sound` and
keep its conclusion. Which inputs can now use the theorem? What additional
claim would establish that the output at vertex 3 is the minimum cost over
paths from vertex 0?

## Run the visualization

From the course checkout, build the standalone project and start its web app.
The quick start in `GraphFold/README.md` also covers VS Code port forwarding.

```sh
cd GraphFold
lake build && python3 web/server.py
```

Open the tool at [http://127.0.0.1:8787](http://127.0.0.1:8787).
Use `GraphFold/examples/tied-optima.txt` with **Shortest paths**, **Count paths**,
and **Optimal routes**. Run the Boolean reachability example above in Lean.
Then try `GraphFold/examples/cycle-invalid.txt` and compare the parser's response
with the response from the direct library call above.

The [GraphFold project guide](https://github.com/kevinsullivan/GraphFold/blob/9e8c1e9e7950a5d6b63066520c4dcc4fc00f26ca/README.md)
explains the library, executables, and trace format. The
[specification-gap walkthrough](https://github.com/kevinsullivan/GraphFold/blob/9e8c1e9e7950a5d6b63066520c4dcc4fc00f26ca/whatCanGoWrongSpecGaps.lean)
extends the cyclic example and proves that the recurrence has a unique
derivation result for a fixed starting prefix and graph.
```lean
end E16
```


<div class="issue-box">📝 <a href="https://github.com/kevinsullivan/Lean4CS1/issues/new">Report an issue</a> with this section</div>

