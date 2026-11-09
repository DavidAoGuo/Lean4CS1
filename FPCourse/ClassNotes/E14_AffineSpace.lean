import Mathlib.Algebra.Group.Defs
import Mathlib.Algebra.Module.Defs
import Mathlib.Data.Real.Basic

/- @@@
# Affine Spaces: Groups Acting on Structure-Free Geometry

## What Affine Spaces Are: Geometry Without an Origin

Last class we saw that a *torsor* is a set `T` where a group `G` acts
in two special ways: *freely* (no non-identity element fixes any point)
and *transitively* (any two points are related by some group element).

An *affine space* is a torsor with a specific structure: we have a group `V`
(the "displacement vectors") acting on a set `P` (the "points") in a torsor fashion.
The group structure on `V` lets us describe how displacements compose:
to move from point `p` by displacement `v`, we compute `v +ᵥ p`.
The freeness and transitivity of the action mean every pair of points has a unique
displacement vector relating them, and conversely, every vector can translate
any point to some other point.

Note the operand order: the *vector* goes on the left, the *point* on the right.
That is not arbitrary. It is what makes the composition law below read in the
same direction as function composition, and it is the convention mathlib uses
for `AddTorsor`. Writing `p + v` instead would force the composition law to
reverse the group operation, which is invisible for ℚ (where addition commutes)
but wrong for any non-commutative group of displacements.

Why does this matter? Because it captures *pure geometry* -- the essence
of space without imposing a choice of origin or coordinate system. In a vector space,
there's a distinguished point: the zero vector, which is both an algebraic and
geometric identity. In an affine space, there's no such point. All points
are equivalent, related only through the group action.

Examples: points in a Euclidean plane, events in spacetime (with vectors
representing intervals), locations on a calendar (with integer vectors
representing day offsets), positions in a color space.

An affine space has two core operations:
  - *Point translation*: given vector `v` and point `p`, compute `v +ᵥ p` (new point)
  - *Vector subtraction*: given points `p` and `q`, compute `q -ᵥ p` (displacement vector)

These must satisfy:
  - `v +ᵥ (w +ᵥ p) = (v + w) +ᵥ p`  (translating twice = translating by the sum)
  - `0 +ᵥ p = p`                     (the zero vector doesn't move anything)
  - `(q -ᵥ p) +ᵥ p = q`              (the displacement from p to q, applied to p, reaches q)
  - `(v +ᵥ p) -ᵥ p = v`              (translating p by v, then differencing against p, recovers v)
@@@ -/

namespace AffineSpace

/- @@@
## Recap: `Group` (from the groups lesson)

We'll need the group structure we developed earlier: an associative
operation with identity and inverses.
@@@ -/

class Group (α : Type) where
  op      : α → α → α
  id      : α
  assoc   : ∀ a b c, op (op a b) c = op a (op b c)
  idLeft  : ∀ a, op id a = a
  idRight : ∀ a, op a id = a
  inv     : α → α
  invLeft : ∀ a, op (inv a) a = id
  invRight: ∀ a, op a (inv a) = id

instance {α : Type} [Group α] : Add α where add := Group.op
instance {α : Type} [Group α] : Neg α where neg := Group.inv
instance {α : Type} [Group α] : Zero α where zero := Group.id

/- @@@
## `AffineSpace`: A Torsor Structure

An affine space is exactly a torsor: it pairs a set of points `P` with a group `V`
(the "vectors" or "displacements") where `P` is a torsor for the group action of `V`.
The group acts on points via a translation operation in a way that is both
*free* (no non-identity group element fixes any point) and *transitive*
(any two points are related by some group element). This means:
- Every pair of points has a unique displacement vector between them
- Every vector can translate any point to some other point

Here, we bundle the translation operation (`vadd`) and its inverse (`vsub`)
with proofs that they satisfy the affine axioms. The `VAdd` and `VSub`
typeclasses provide standard notation: `v +ᵥ p` for translation
and `q -ᵥ p` for vector subtraction.
@@@ -/

class AffineSpace (V : Type) (P : Type) where
  [groupV : Group V]
  vadd    : V → P → P
  vsub    : P → P → V
  vaddAssoc : ∀ v w : V, ∀ p : P, vadd v (vadd w p) = vadd (groupV.op v w) p
  vaddZero  : ∀ p : P, vadd groupV.id p = p
  vsubAdd   : ∀ p q : P, vadd (vsub q p) p = q
  addVsub   : ∀ v : V, ∀ p : P, vsub (vadd v p) p = v

/- Standard notation typeclasses for affine operations -/
class VAdd (V : Type) (P : Type) where vadd : V → P → P
class VSub (P : Type) (V : Type) where vsub : P → P → V

instance {V P : Type} [AffineSpace V P] : VAdd V P where vadd := AffineSpace.vadd
instance {V P : Type} [AffineSpace V P] : VSub P V where vsub := AffineSpace.vsub

-- Both at precedence 65, matching mathlib. `-ᵥ` must bind tighter than `=`
-- (precedence 50), or a goal like `q -ᵥ p = v` fails to parse.
infixl:65 " +ᵥ " => VAdd.vadd
infixl:65 " -ᵥ " => VSub.vsub

/- @@@
## Connection to the `Torsor` Class

An affine space is the same mathematical idea as a torsor -- a group acting
freely and transitively -- but packaged differently, and the difference is
worth being precise about rather than calling it mere notation.

`Torsor` states transitivity as an *existence claim*:

  `actTransitive : ∀ t₁ t₂ : T, ∃ g : G, act g t₁ = t₂`

`AffineSpace` instead provides an *operation* that produces the group element:

  `vsub : P → P → V`

That is the real change: a proof that something exists becomes a function
that computes it. The existential tells you two points *are* related by some
displacement; `vsub` hands you the displacement. Only the second lets you
write `q -ᵥ p` and get a value out, which is why the geometry in this file
computes while the torsor version could only be reasoned about.

Freeness also changes character. In `Torsor` it is a separate axiom; here it
is a consequence of `addVsub`, which says `vsub` inverts `vadd` and so forces
the displacement between two points to be *unique*, not merely existent.

The secondary benefit is the type separation: `vadd : V → P → P` keeps
vectors and points apart, where `Torsor`'s `act : G → T → T` is usually
instantiated with `G` and `T` the same type.
@@@ -/

/- @@@
## Instance 1: `Rat` × `Rat` (Rational Points in the Plane)

The rational plane is an affine space over the vector space `Rat × Rat`.
Points and displacement vectors are both pairs of rationals, but
conceptually they play different roles: vectors represent displacements,
points represent locations (with no special origin).

The translation operation is componentwise addition, and the subtraction
operation subtracts coordinates to recover the displacement vector.
@@@ -/

instance : Group (Rat × Rat) where
  op      : Rat × Rat → Rat × Rat → Rat × Rat := fun (a, b) (c, d) => (a + c, b + d)
  id      : Rat × Rat := (0, 0)
  assoc   : ∀ a b c : Rat × Rat, ((a.1 + b.1) + c.1, (a.2 + b.2) + c.2) = (a.1 + (b.1 + c.1), a.2 + (b.2 + c.2)) := fun _ _ _ => by simp [Rat.add_assoc]
  idLeft  : ∀ a : Rat × Rat, (0 + a.1, 0 + a.2) = a := fun _ => by simp
  idRight : ∀ a : Rat × Rat, (a.1 + 0, a.2 + 0) = a := fun _ => by simp
  inv     : Rat × Rat → Rat × Rat := fun (a, b) => (-a, -b)
  invLeft : ∀ a : Rat × Rat, (-a.1 + a.1, -a.2 + a.2) = (0, 0) := fun (a, b) => by ext <;> simp
  invRight: ∀ a : Rat × Rat, (a.1 + (-a.1), a.2 + (-a.2)) = (0, 0) := fun (a, b) => by ext <;> simp

instance : AffineSpace (Rat × Rat) (Rat × Rat) where
  groupV  := inferInstance
  vadd    : Rat × Rat → Rat × Rat → Rat × Rat := fun (v₁, v₂) (p₁, p₂) => (v₁ + p₁, v₂ + p₂)
  vsub    : Rat × Rat → Rat × Rat → Rat × Rat := fun (q₁, q₂) (p₁, p₂) => (q₁ - p₁, q₂ - p₂)
  -- v +ᵥ (w +ᵥ p) = (v + w) +ᵥ p, componentwise: v₁ + (w₁ + p₁) = (v₁ + w₁) + p₁
  vaddAssoc := fun (v₁, v₂) (w₁, w₂) (p₁, p₂) => by
    ext <;> simp [Group.op, Rat.add_assoc]
  vaddZero := fun (p₁, p₂) => by
    ext <;> simp [Group.id]
  -- note the binder order: p first, then q, matching `∀ p q : P` in the class
  vsubAdd := fun (p₁, p₂) (q₁, q₂) => by
    ext <;> simp
  addVsub := fun (v₁, v₂) (p₁, p₂) => by
    ext <;> simp

/- @@@
This instance encodes a fundamental truth: the rational plane has no
distinguished origin. We can pick any point as a reference, and describe
all others relative to it via vectors. The structure guarantees that the
two directions of translation (point + vector, point - point) are inverses.
@@@ -/

/- With the VAdd instance, we can now write `v +ᵥ p` for translation.
   Example: translating point (2, 3) by vector (1, -1) gives (3, 2).
-/

/- @@@
## Instance 2: Decidable Equality Points Over ℚ Vectors

For a general decidable equality type `P` (the points), we can construct
an affine space where the vectors are `Rat` and the action is addition
of a rational scalar to... well, we'd need `P` to be a `Rat`-module, which
requires more structure. Instead, let's construct an affine space where
both `P` and `V` are the same type with decidable equality, and the action
is a free group action via an embedding `f : V → P → P`.

Actually, the cleanest general instance: treat `P` itself as a `Rat`
vector space (which we'll formalize next class), and then the affine
space is just `P` acting on itself.
@@@ -/

/- @@@
## Properties of Affine Spaces

Once we have an affine space, we can derive useful facts. For instance,
vector subtraction is a kind of "difference" operation: the vector that
takes us from one point to another is unique, and going from p to q to r
is the same as going directly from p to r.

This is captured in the affine space axioms:

  **vsubAdd**: `(q -ᵥ p) +ᵥ p = q`
  ```
    Geometric meaning: if we take the vector from p to q, and apply it to p,
    we get back to q.

    p ──────────(q - p)─────────> q
            (add to p)

    This says: the displacement from p to q, when added to p, reconstructs q.
  ```

  **addVsub**: `(v +ᵥ p) -ᵥ p = v`
  ```
    Geometric meaning: if we translate p by vector v, the difference between
    the new point and the original is the vector v.

    p ─────v────> (v + p)
            (subtract p)

    This says: translating p by v, then computing the vector back to p,
    recovers the original vector v.
  ```
@@@ -/

/- @@@
## Concrete Examples: Small Geometric Worlds

Now let's see the affine space in action with concrete geometric worlds.
The key is that all operations are coordinate-free and don't require choosing
an origin.
@@@ -/

/- @@@
### Example 1: A Triangle in the Rational Plane

Define three vertices of a triangle:
@@@ -/

def triangle_A : Rat × Rat := (1, 2)
def triangle_B : Rat × Rat := (4, 2)
def triangle_C : Rat × Rat := (2, 5)

/- @@@
Compute the vectors forming the sides of the triangle.
Note: we use the `-ᵥ` operator to compute displacements.
@@@ -/

def side_AB : Rat × Rat := triangle_B -ᵥ triangle_A  -- (3, 0)
def side_BC : Rat × Rat := triangle_C -ᵥ triangle_B  -- (-2, 3)
def side_CA : Rat × Rat := triangle_A -ᵥ triangle_C  -- (-1, -3)

/- @@@
Verify the closure property: going around the triangle brings you back home.
The sum of all displacement vectors around a closed loop is the zero vector.

Displacements compose with the *group* operation on `V` -- that is the whole
point of requiring `V` to be a group, so we use `Group.op` rather than
re-deriving componentwise addition by hand.
@@@ -/

def close_the_loop : Rat × Rat := Group.op (Group.op side_AB side_BC) side_CA

#eval side_AB         -- (3, 0)
#eval side_BC         -- (-2, 3)
#eval side_CA         -- (-1, -3)
#eval close_the_loop  -- (0, 0): AB + BC + CA = 0, the loop closes

/- @@@
### Example 2: Translation and Reconstruction

Translate a point by a vector, then recover the original vector from the
difference.
@@@ -/

def point_P : Rat × Rat := (0, 0)
def vector_v : Rat × Rat := (3, 4)

/- @@@
Here we must write `AffineSpace.vadd` rather than the `+ᵥ` notation, and the
reason is instructive. We have chosen `V` and `P` to be the *same* type,
`ℚ × ℚ`. But mathlib already knows `ℚ × ℚ` is an additive monoid acting on
itself, so it already has a `+ᵥ` for this pair of types. Our notation and
mathlib's are both in scope and both apply, so `vector_v +ᵥ point_P` is
genuinely ambiguous and Lean refuses to guess.

This is not a notational annoyance -- it is the type system telling us
something true. Modelling points and vectors as the same type throws away the
distinction the whole lesson is about. The fix is not to fight the ambiguity
but to give points and vectors *different* types, which is exactly what the
ℚ² demo does. There, `+ᵥ` is unambiguous because only one instance applies.
@@@ -/

def translated_point : Rat × Rat := AffineSpace.vadd vector_v point_P

/- @@@
Now recover the original vector by taking the difference:
@@@ -/

def recovered_vector : Rat × Rat := translated_point -ᵥ point_P

#eval translated_point                  -- (3, 4)
#eval recovered_vector                  -- (3, 4)
#eval recovered_vector = vector_v       -- true

/- @@@
That last line is the `addVsub` axiom showing up as a computation rather than
a claim: `(v +ᵥ p) -ᵥ p = v`. Since we have actually *proven* `addVsub` for
this instance, the equality is guaranteed for every `v` and `p`, not just the
one pair we happened to evaluate.
@@@ -/

example : (AffineSpace.vadd vector_v point_P) -ᵥ point_P = vector_v :=
  AffineSpace.addVsub vector_v point_P

/- @@@
### Example 3: Geometric Relationships Without an Origin

Consider a line defined by two points. We can describe all points on the line
using just the affine structure — no special origin needed.
@@@ -/

def line_point_1 : Rat × Rat := (1, 1)
def line_point_2 : Rat × Rat := (2, 3)

def direction : Rat × Rat := line_point_2 -ᵥ line_point_1  -- (1, 2)

/- @@@
A point at t=2 along this line (2 times the direction vector from point_1):
@@@ -/

def point_on_line_t2 : Rat × Rat :=
  AffineSpace.vadd (2 * direction.1, 2 * direction.2) line_point_1

#eval direction         -- (1, 2)
#eval point_on_line_t2  -- (3, 5)

/- @@@
Note what we had to do to scale the direction vector: we reached into the
components and multiplied. That is *not* an affine operation. An affine space
gives us a group of displacements, and a group only lets us compose and invert
them -- it has no notion of "twice this vector." Scaling needs `V` to carry
scalar multiplication, i.e. to be a vector space, which is the structure the
next lesson adds. The affine axioms alone cannot parametrize a line.
@@@ -/

/- @@@
The affine space structure lets us:
  - Define geometric objects (lines, triangles) by their points
  - Compute displacements between points without a global coordinate system
  - Verify geometric properties (like closure of a triangle)
  - Reconstruct vectors from differences

All of this works *purely relationally* — we never need to pick a special point
as "the origin." The geometry emerges from the group action alone.
@@@ -/

/- @@@
The key insight: affine spaces capture *pure geometry* in the sense that
we can describe the relationships between points without choosing an origin.
The group action encodes all the geometric information we need.

In the next lesson we add the missing structure: scalar multiplication, which
turns the group of displacements into a *vector space*. Rather than build it
from scratch as we did here, we will switch strategy and use mathlib's
`Module` typeclass -- a deliberate contrast worth noticing, since it is the
difference between defining an abstraction to understand it and reusing one
to get work done.
@@@ -/

end AffineSpace
