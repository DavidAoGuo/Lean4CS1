```lean
import Mathlib.Algebra.Group.Defs
import Mathlib.Algebra.Module.Defs
import Mathlib.Data.Real.Basic
```

# Vector Spaces: Modules Over a Field

## What Vector Spaces Are: Linear Combinations and Dimension

A *vector space* is an algebraic structure that lets you add elements
together and scale them by numbers from a field (like ℚ or ℝ). The key
idea is *linearity*: the operations are simple, predictable, and compose
in a way that lets you reason about high-dimensional geometry using
low-dimensional intuitions.

More formally, a vector space `V` over a field `F` is:
  - An abelian (commutative) group under addition, with identity `0`
  - A scalar multiplication operation `• : F → V → V` for `f : F` and `v : V`
  - Compatibility laws that ensure scalar multiplication "respects" both
    the field structure and the vector space structure

Vector spaces are the language of linear algebra: every line, plane,
or hyperplane you've encountered is a vector space. The span of a set
of vectors is a vector space. The kernel of a linear map is a vector
space. The central concept of *linear independence* and *dimension*
emerge naturally from the structure.

In today's lesson, we formalize vector spaces using Lean's standard library
definitions. Rather than re-implementing everything from scratch, we'll
leverage mathlib's `Field` typeclass for scalars and the `Module` typeclass,
which bundles the vector space operations and laws together in Lean's
modern typeclass system.

## Why Use Mathlib Here?

Previous lessons (E11–E13) built custom typeclasses to understand structure.
Here, we shift strategy: Lean's mathlib has mature, battle-tested definitions
of fields and modules. Rather than re-derive everything, we leverage them.

This is realistic: in practice, you build custom types for *new* problems,
but reuse standard library abstractions for well-understood mathematics.

The Module typeclass is exactly what we need: a vector space is a module
over a field. Mathlib's instances automatically handle 1D, 2D, 3D, etc.
without requiring you to re-prove the axioms for each dimension.

**The payoff**: one theorem about modules instantly applies to ℚ, ℚ², ℚ³,
spaces of polynomials, and infinite-dimensional Hilbert spaces—anywhere
the Module structure holds.

## Why Vector Spaces Matter

Vector spaces unify a hundred different-looking problems into a single
framework:
  - Solutions to systems of linear equations
  - Probability distributions (if you drop the "must be positive" constraint)
  - Images and filters in computer graphics
  - Quantum states in quantum mechanics
  - Gradients and optimization in machine learning

The structure is so fundamental that once you understand one vector space,
you understand them all.
```lean
namespace VectorSpaces
```

## Vector Space Instances in Lean's Mathlib

Mathlib has a mature definition of this structure, but it pays to be precise
about what it is *called*, because a reasonable expectation turns out to be
wrong: **mathlib has no `VectorSpace` typeclass.** Looking for one is a dead
end. There is only `Module`.

`Module R M` says that `M` is a module over the semiring `R`: `M` is an
additive commutative group, and `R` acts on it by a scalar multiplication
satisfying the usual compatibility laws.

A vector space is then not a separate structure but a *special case* of that
one: `Module K V` where the scalars `K` form a field. "Vector space" is
vocabulary for that situation rather than a class to instantiate, so there is
nothing additional to declare. If you have a `Module` and your scalars are a
field, you already have a vector space, and every `Module` lemma applies to
it unchanged.

What the field assumption adds is that non-zero scalars become invertible, so
a scaling can be undone. That is what gives vector spaces bases and a
well-defined dimension, which modules in general may lack.

The key operations are:
  - `+ : V → V → V` (addition)
  - `• : F → V → V` (scalar multiplication, written with the `•` symbol)
  - `0 : V` (additive identity)
  - `- : V → V` (negation)

These come with laws bundled into the typeclasses `Add`, `SMul`, `Zero`, `Neg`,
and the full `Module` structure.
## Instance 1: ℚ as a Vector Space Over Itself

The rational numbers ℚ form a vector space over themselves. Addition is
ordinary rational addition, and scalar multiplication is ordinary rational
multiplication. This is the simplest non-trivial example.

In mathlib this instance is built-in: any field is a module over itself, and
being a field, it is therefore a vector space over itself.

Rather than assert that, we can ask Lean. The two `#check`s below are the
whole content of "ℚ is a ℚ-vector space" -- a `Module` instance plus the fact
that the scalars are a field. There is no third `VectorSpace` instance to
look for, which is the point made above.
```lean
/- ℚ is a module over itself... -/
#check (inferInstance : Module Rat Rat)

/- ...and ℚ is a field. Together: ℚ is a vector space over ℚ. -/
#check (inferInstance : Field Rat)

/- Basic operations in the 1D vector space ℚ -/
#eval (2 : Rat) * (3 : Rat)  -- 6 (scalar multiplication)
#eval (1 : Rat) * (5 : Rat)  -- 5 (identity element: 1 • v = v)
#eval (2 : Rat) + (3 : Rat)  -- 5 (vector addition)
```

The rational numbers are a concrete representation of a 1-dimensional vector
space. Any two non-zero rationals are linearly independent in the sense that
neither is a scalar multiple of the other unless they're equal (up to sign).
Wait, that's not quite right for a 1D space...

In a 1-dimensional space, any two vectors are linearly *dependent*: one is a
scalar multiple of the other (or one is zero). This is true for ℚ: any rational
q₁ can be expressed as `c * q₂` for some c (as long as q₂ ≠ 0).
## Instance 2: ℚ × ℚ (The Rational Plane) as a Vector Space Over ℚ

Now for something more interesting: the vector space ℚ² (pairs of rationals).
This is the canonical example of a 2-dimensional vector space. Addition is
componentwise, and scalar multiplication scales each component.

Mathlib has a generic instance: if `V` is a module over `R`, then `V × V`
is also a module over `R` (with componentwise operations).
```lean
/- ℚ × ℚ is a module over ℚ (the 2D vector space)
   Mathlib automatically provides this instance for products of modules. -/

/- Basic vector space operations on pairs -/
#eval let v : Rat × Rat := (2, 3);
      let w : Rat × Rat := (1, -1);
      show Rat × Rat from (v.1 + w.1, v.2 + w.2)
      -- Evaluates to `(3, 2)` (componentwise addition)

#eval let v : Rat × Rat := (2, 3);
      let s : Rat := (1/2 : Rat);
      show Rat × Rat from (s * v.1, s * v.2)
      -- Evaluates to `(1, 3/2)` (scalar multiplication)
```

The rational plane is our first "true" vector space: it has dimension 2.
Any point can be described using a pair of coordinates. Linear combinations
of two independent vectors (like `(1, 0)` and `(0, 1)`) span the entire plane.
## Instance 3: ℚ × ℚ × ℚ (3D Rational Space)

The pattern extends naturally to three dimensions and beyond. Mathlib provides
generic instances for all finite products, so ℚ³ is automatically a vector space
over ℚ with componentwise addition and scalar multiplication.
```lean
/- ℚ × ℚ × ℚ is a module over ℚ (the 3D vector space)
   Mathlib automatically provides this instance for products of modules. -/

/- Vector space operations on triples -/
#eval let v : Rat × Rat × Rat := (1, 2, 3);
      let w : Rat × Rat × Rat := (1, 1, 1);
      show Rat × Rat × Rat from (v.1 + w.1, v.2.1 + w.2.1, v.2.2 + w.2.2)
      -- Evaluates to `(2, 3, 4)` (componentwise addition)

#eval let v : Rat × Rat × Rat := (2, 4, 6);
      let s : Rat := (1/2 : Rat);
      show Rat × Rat × Rat from (s * v.1, s * v.2.1, s * v.2.2)
      -- Evaluates to `(1, 2, 3)` (scalar multiplication)
```

In 3D space, we can describe any point using three coordinates. Three linearly
independent vectors (like the standard basis vectors `(1, 0, 0)`, `(0, 1, 0)`,
`(0, 0, 1)`) span the entire space. This is the geometric foundation of 3D
computer graphics, physics simulations, and much of applied mathematics.
## Vector Space Properties from Mathlib

Once we have the vector space structure in place, mathlib provides powerful
theorems that hold automatically:

- **Distributivity**: `s • (v + w) = s • v + s • w`
- **Compatibility**: `(s * t) • v = s • (t • v)`
- **Identity**: `1 • v = v`
- **Zero properties**: `0 • v = 0` and `s • 0 = 0`

These laws ensure that any computation we do with scalar multiplication and
addition is consistent and well-defined.

Unlike our custom formalization in the affine space lesson, we don't need to
re-prove these axioms for each instance. Mathlib's generic instances handle
the boilerplate, and we get the theorems "for free" as long as we build our
instances from mathlib's building blocks.
## Linear Maps (Preview)

In the full theory of vector spaces, we're interested not just in the spaces
themselves, but in *functions between them that preserve the structure*.

A linear map `f : V → W` between vector spaces is one that satisfies:
  - `f (v₁ + v₂) = f v₁ + f v₂` (respects addition)
  - `f (s • v) = s • f v` (respects scalar multiplication)

Linear maps are crucial because they let us translate geometric intuitions
(rotation, projection, reflection) into algebraic calculations. The space of
all linear maps from `V` to `W` is itself a vector space!

Mathlib formalizes this through the `LinearMap` type, which bundles a function
with proofs of linearity. We'll explore linear maps more deeply in the next
lesson.
## From Concrete to Abstract

What we've done here is take a concrete structure (rationals, pairs of rationals)
and shown that they're all instances of an abstract algebraic concept (a module
over a field, aka a vector space). This is the power of abstraction: write a
theorem once, and it applies to infinitely many instances.

For example, suppose we prove:
  `theorem span_of_two_independent_vecs (v w : V) (hind : ¬ LinearDependent (v, w)) :
    Submodule.span ℚ {v, w} = ⊤`

This theorem holds for *any* vector space V over ℚ (or any field). We don't
need to re-prove it for ℚ², ℚ³, spaces of polynomials, or any other instance.
The abstraction pays dividends.

## The Big Picture

Vector spaces are fundamental to modern mathematics and science. They appear in:

- **Linear algebra**: systems of equations, eigenvalues, matrix decompositions
- **Functional analysis**: infinite-dimensional spaces, Hilbert spaces, operators
- **Differential geometry**: tangent spaces, differential forms
- **Quantum mechanics**: state spaces, observables, probability amplitudes
- **Machine learning**: feature spaces, embeddings, neural network architectures
- **Signal processing**: Fourier analysis, wavelets, compression

By formalizing vector spaces, we're equipping ourselves to reason rigorously
about all of these domains. The structure is so universal that understanding
it well pays off across the entire landscape of mathematical and computational
practice.
```lean
end VectorSpaces
```


<div class="issue-box">📝 <a href="https://github.com/kevinsullivan/Lean4CS1/issues/new">Report an issue</a> with this section</div>

