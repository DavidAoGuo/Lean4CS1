import Mathlib.Algebra.Group.Defs
import Mathlib.Algebra.Module.Defs
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.Ring

/- @@@
# E15: Theory, Implementation, and Proof

## Architecture

This lesson demonstrates a fundamental pattern in mathematics and software:

1. **Theory Layer**: Abstract definitions and axioms
   - `AffineSpaceTheory` and `VectorSpaceTheory` state what properties structures must have
   - No specific types; works over arbitrary type parameters

2. **Implementation Layer**: Concrete instances
   - Three implementations using ℚ, ℚ², ℚ³
   - Each satisfies the abstract theory

3. **Proof Bridge**: Theorems showing each implementation satisfies the theory
   - Proves that concrete instances meet abstract requirements
   - Justifies using abstract reasoning to derive facts about implementations

This pattern separates *what we require* (theory) from *what we provide* (implementation),
with proofs connecting them. This is the essence of abstraction.
@@@ -/

namespace TheoryImplProof

/- @@@
## Theory Layer: Abstract Requirements for Geometric Structures

We abstract the essential properties that make something an affine or vector space,
without committing to any specific type. Rather than re-documenting Group and
AffineSpace axioms (see E13 and E14), we provide a minimal recap here.
@@@ -/

/- @@@
### Abstract Theory: Recap and Abstraction

From E13, a Group has operation, identity, associativity, and inverses.
From E14, an AffineSpace has a Group acting on points via vadd/vsub.
Now we formalize these patterns generically over arbitrary types.
@@@ -/

class Group (α : Type) where
  op      : α → α → α
  id      : α
  assoc   : ∀ a b c : α, op (op a b) c = op a (op b c)
  idLeft  : ∀ a : α, op id a = a
  idRight : ∀ a : α, op a id = a
  inv     : α → α
  invLeft : ∀ a : α, op (inv a) a = id
  invRight: ∀ a : α, op a (inv a) = id

instance [Group α] : Add α where add := Group.op
instance [Group α] : Neg α where neg := Group.inv
instance [Group α] : Zero α where zero := Group.id

class AffineSpaceTheory (V : Type) (P : Type) where
  [groupV : Group V]
  vadd    : V → P → P
  vsub    : P → P → V
  vaddAssoc : ∀ v w : V, ∀ p : P, vadd v (vadd w p) = vadd (groupV.op v w) p
  vaddZero  : ∀ p : P, vadd groupV.id p = p
  vsubAdd   : ∀ p q : P, vadd (vsub q p) p = q
  addVsub   : ∀ v : V, ∀ p : P, vsub (vadd v p) p = v

/- Standard notation typeclasses -/
class VAdd (V : Type) (P : Type) where vadd : V → P → P
class VSub (P : Type) (V : Type) where vsub : P → P → V

instance [AffineSpaceTheory V P] : VAdd V P where vadd := AffineSpaceTheory.vadd
instance [AffineSpaceTheory V P] : VSub P V where vsub := AffineSpaceTheory.vsub

-- Both at precedence 65, matching mathlib. `-ᵥ` must bind tighter than `=`
-- (precedence 50), or a goal like `q -ᵥ p = v` fails to parse.
infixl:65 " +ᵥ " => VAdd.vadd
infixl:65 " -ᵥ " => VSub.vsub

/- @@@
### Abstract Theory: VectorSpaceTheory

A vector space requires:
- scalars `F`, carrying multiplication, a `1`, and an additive group structure
- vectors `V`, carrying an additive group structure
- a scalar multiplication `smul : F → V → V`
- four axioms relating the scalar operations to the vector ones

We reuse our own `Group` class for the additive structure of *both* `F` and
`V`, which is why `groupF` and `groupV` appear below. `groupF.op` is addition
on scalars and `groupF.id` is the scalar `0`; likewise for vectors. Scalar
multiplication and `1` come from Lean's `Mul` and `One`.

### Module or Vector Space? The Precise Difference

A qualification about the name, since these four axioms are exactly the
*module* axioms. The two notions have **identical axioms**; the difference is
entirely a condition on the scalars:

  - a **module** over `R` needs `R` to be a ring: scalars have `+`, `*`, `0`, `1`
  - a **vector space** over `K` needs `K` to be a *field*: additionally every
    non-zero scalar has a multiplicative inverse

So a vector space is not a different structure. It is a module whose scalars
can be divided by. Nothing in the axioms changes, which is exactly why every
theorem below holds in both settings.

What invertible scalars buy is the ability to *undo* a scaling. Over a field,
if `a ≠ 0` then `a⁻¹ • (a • v) = (a⁻¹ * a) • v = 1 • v = v`, by `mulSmul`
then `oneSmul`. Over a mere ring there is no `a⁻¹` to apply: working over ℤ
you can double a vector but not halve it.

The sharpest symptom of that gap is *torsion*. In a module, `a • v = 0` can
happen with `a ≠ 0` and `v ≠ 0` -- take ℤ/6 as a module over ℤ, where
`2 • 3 = 6 = 0` though neither factor is zero. In a vector space this is
impossible: scale by `a⁻¹` and `v = a⁻¹ • 0 = 0`, using `vector_scalar_zero`
proven later in this file. Torsion is in turn why a module need not have a
basis or a well-defined dimension, while every vector space has both; ℤ/6 has
no ℤ-basis at all.

Modules over ℤ are precisely the abelian groups, so this is a genuinely wider
notion rather than a technicality. Mathlib reflects all of this: it provides
`Module R M` for a semiring `R`, and a vector space is just `Module K V` with
`K` a field -- there is no separate `VectorSpace` class.

We do not state the field requirement here, because none of the theorems
below need it. So `VectorSpaceTheory F V` says "`V` is a module over `F`",
and it is a vector space exactly when `F` is a field, as ℚ is in all three
implementations.
@@@ -/

class VectorSpaceTheory (F V : Type) [Mul F] [One F] where
  [groupF : Group F]
  [groupV : Group V]
  smul    : F → V → V
  -- Scaling by 1 does nothing.
  oneSmul : ∀ v : V, smul 1 v = v
  -- Scaling by a product is scaling twice.
  mulSmul : ∀ a b : F, ∀ v : V, smul (a * b) v = smul a (smul b v)
  -- Scalar multiplication distributes over vector addition.
  smulAdd : ∀ a : F, ∀ v w : V,
    smul a (groupV.op v w) = groupV.op (smul a v) (smul a w)
  -- ...and over scalar addition.
  addSmul : ∀ a b : F, ∀ v : V,
    smul (groupF.op a b) v = groupV.op (smul a v) (smul b v)

instance [Mul F] [One F] [VectorSpaceTheory F V] : SMul F V where
  smul := VectorSpaceTheory.smul

/- @@@
## Implementation Layer: Three Concrete Instances

Each implementation provides both an AffineSpaceTheory and VectorSpaceTheory instance.
@@@ -/

/- @@@
### Implementation 1: ℚ (1-Dimensional)

Both the affine space and vector space of rational numbers.
@@@ -/

instance : Group Rat where
  op      : Rat → Rat → Rat := (· + ·)
  id      : Rat := 0
  assoc   : ∀ a b c : Rat, (a + b) + c = a + (b + c) := Rat.add_assoc
  idLeft  : ∀ a : Rat, 0 + a = a := Rat.zero_add
  idRight : ∀ a : Rat, a + 0 = a := Rat.add_zero
  inv     : Rat → Rat := fun q => -q
  invLeft : ∀ a : Rat, (-a) + a = 0 := Rat.neg_add_cancel
  invRight: ∀ a : Rat, a + (-a) = 0 := Rat.add_neg_cancel

instance : AffineSpaceTheory Rat Rat where
  groupV  := inferInstance
  vadd    : Rat → Rat → Rat := (· + ·)
  vsub    : Rat → Rat → Rat := (· - ·)
  vaddAssoc : ∀ v w : Rat, ∀ p : Rat, v + (w + p) = (v + w) + p :=
    fun v w p => (Rat.add_assoc v w p).symm
  vaddZero : ∀ p : Rat, 0 + p = p := Rat.zero_add
  vsubAdd : ∀ p q : Rat, (q - p) + p = q := fun p q => by norm_num
  addVsub : ∀ v : Rat, ∀ p : Rat, (v + p) - p = v := fun v p => by norm_num

instance : VectorSpaceTheory Rat Rat where
  groupF  := inferInstance
  groupV  := inferInstance
  smul    : Rat → Rat → Rat := (· * ·)
  oneSmul := fun v => by show (1 : Rat) * v = v; ring
  mulSmul := fun a b v => by show (a * b) * v = a * (b * v); ring
  smulAdd := fun a v w => by show a * (v + w) = a * v + a * w; ring
  addSmul := fun a b v => by show (a + b) * v = a * v + b * v; ring

/- @@@
### Implementation 2: ℚ × ℚ (2-Dimensional)

Both the affine space and vector space of the rational plane.
@@@ -/

instance : Group (Rat × Rat) where
  op      : Rat × Rat → Rat × Rat → Rat × Rat := fun (a, b) (c, d) => (a + c, b + d)
  id      : Rat × Rat := (0, 0)
  assoc   : ∀ a b c : Rat × Rat, ((a.1 + b.1) + c.1, (a.2 + b.2) + c.2) = (a.1 + (b.1 + c.1), a.2 + (b.2 + c.2)) := fun _ _ _ => by ext <;> simp [Rat.add_assoc]
  idLeft  : ∀ a : Rat × Rat, (0 + a.1, 0 + a.2) = a := fun _ => by simp
  idRight : ∀ a : Rat × Rat, (a.1 + 0, a.2 + 0) = a := fun _ => by simp
  inv     : Rat × Rat → Rat × Rat := fun (a, b) => (-a, -b)
  invLeft : ∀ a : Rat × Rat, (-a.1 + a.1, -a.2 + a.2) = (0, 0) := fun _ => by
    ext <;> simp
  invRight: ∀ a : Rat × Rat, (a.1 + (-a.1), a.2 + (-a.2)) = (0, 0) := fun _ => by
    ext <;> simp

instance : AffineSpaceTheory (Rat × Rat) (Rat × Rat) where
  groupV  := inferInstance
  vadd    : Rat × Rat → Rat × Rat → Rat × Rat := fun (v₁, v₂) (p₁, p₂) => (v₁ + p₁, v₂ + p₂)
  vsub    : Rat × Rat → Rat × Rat → Rat × Rat := fun (q₁, q₂) (p₁, p₂) => (q₁ - p₁, q₂ - p₂)
  vaddAssoc := fun (v₁, v₂) (w₁, w₂) (p₁, p₂) => by
    ext <;> simp [Group.op, Rat.add_assoc]
  vaddZero := fun (p₁, p₂) => by ext <;> simp [Group.id]
  vsubAdd := fun (p₁, p₂) (q₁, q₂) => by ext <;> simp
  addVsub := fun (v₁, v₂) (p₁, p₂) => by ext <;> simp

instance : VectorSpaceTheory Rat (Rat × Rat) where
  groupF  := inferInstance
  groupV  := inferInstance
  smul    : Rat → Rat × Rat → Rat × Rat := fun a (v₁, v₂) => (a * v₁, a * v₂)
  oneSmul := fun (v₁, v₂) => by ext <;> simp
  mulSmul := fun a b (v₁, v₂) => by ext <;> simp [mul_assoc]
  smulAdd := fun a (v₁, v₂) (w₁, w₂) => by ext <;> simp [Group.op, mul_add]
  addSmul := fun a b (v₁, v₂) => by ext <;> simp [Group.op, add_mul]

/- @@@
### Implementation 3: ℚ × ℚ × ℚ (3-Dimensional)

Both the affine space and vector space of 3D rational space.
@@@ -/

instance : Group (Rat × Rat × Rat) where
  op      : Rat × Rat × Rat → Rat × Rat × Rat → Rat × Rat × Rat := fun (a, b, c) (d, e, f) => (a + d, b + e, c + f)
  id      : Rat × Rat × Rat := (0, 0, 0)
  assoc   : ∀ a b c : Rat × Rat × Rat, ((a.1 + b.1) + c.1, (a.2.1 + b.2.1) + c.2.1, (a.2.2 + b.2.2) + c.2.2) = (a.1 + (b.1 + c.1), a.2.1 + (b.2.1 + c.2.1), a.2.2 + (b.2.2 + c.2.2)) := fun _ _ _ => by ext <;> simp [Rat.add_assoc]
  idLeft  : ∀ a : Rat × Rat × Rat, (0 + a.1, 0 + a.2.1, 0 + a.2.2) = a := fun _ => by simp
  idRight : ∀ a : Rat × Rat × Rat, (a.1 + 0, a.2.1 + 0, a.2.2 + 0) = a := fun _ => by simp
  inv     : Rat × Rat × Rat → Rat × Rat × Rat := fun (a, b, c) => (-a, -b, -c)
  invLeft : ∀ a : Rat × Rat × Rat, (-a.1 + a.1, -a.2.1 + a.2.1, -a.2.2 + a.2.2) = (0, 0, 0) := fun _ => by
    ext <;> simp
  invRight: ∀ a : Rat × Rat × Rat, (a.1 + (-a.1), a.2.1 + (-a.2.1), a.2.2 + (-a.2.2)) = (0, 0, 0) := fun _ => by
    ext <;> simp

instance : AffineSpaceTheory (Rat × Rat × Rat) (Rat × Rat × Rat) where
  groupV  := inferInstance
  vadd    : Rat × Rat × Rat → Rat × Rat × Rat → Rat × Rat × Rat := fun (v₁, v₂, v₃) (p₁, p₂, p₃) => (v₁ + p₁, v₂ + p₂, v₃ + p₃)
  vsub    : Rat × Rat × Rat → Rat × Rat × Rat → Rat × Rat × Rat := fun (q₁, q₂, q₃) (p₁, p₂, p₃) => (q₁ - p₁, q₂ - p₂, q₃ - p₃)
  vaddAssoc := fun (v₁, v₂, v₃) (w₁, w₂, w₃) (p₁, p₂, p₃) => by
    ext <;> simp [Group.op, Rat.add_assoc]
  vaddZero := fun (p₁, p₂, p₃) => by ext <;> simp [Group.id]
  vsubAdd := fun (p₁, p₂, p₃) (q₁, q₂, q₃) => by ext <;> simp
  addVsub := fun (v₁, v₂, v₃) (p₁, p₂, p₃) => by ext <;> simp

instance : VectorSpaceTheory Rat (Rat × Rat × Rat) where
  groupF  := inferInstance
  groupV  := inferInstance
  smul    : Rat → Rat × Rat × Rat → Rat × Rat × Rat := fun a (v₁, v₂, v₃) => (a * v₁, a * v₂, a * v₃)
  oneSmul := fun (v₁, v₂, v₃) => by ext <;> simp
  mulSmul := fun a b (v₁, v₂, v₃) => by ext <;> simp [mul_assoc]
  smulAdd := fun a (v₁, v₂, v₃) (w₁, w₂, w₃) => by ext <;> simp [Group.op, mul_add]
  addSmul := fun a b (v₁, v₂, v₃) => by ext <;> simp [Group.op, add_mul]

/- @@@
## Proof Bridge Layer: Theorems About the Abstract Theory

Now we prove facts about the abstract theory. These theorems apply to *all* implementations.
The proofs work generically over any type satisfying the theory, then apply to all three
concrete instances for free.
@@@ -/

/- @@@
### General Theorems About Affine Spaces

These theorems hold for *any* affine space satisfying `AffineSpaceTheory`.
@@@ -/

theorem affine_translation_inversion {V P : Type} [aff : AffineSpaceTheory V P] (p q : P) :
    aff.vadd (aff.vsub q p) p = q :=
  aff.vsubAdd p q

theorem affine_vector_recovery {V P : Type} [aff : AffineSpaceTheory V P] (v : V) (p : P) :
    aff.vsub (aff.vadd v p) p = v :=
  aff.addVsub v p

/- @@@
This one is the real content: the displacement from `p` to `r` is the
composition of the displacements `p → q` and `q → r`. It follows from the
axioms alone, with no appeal to commutativity and no reference to ℚ -- which
is the whole claim of the theory layer.
@@@ -/

theorem affine_transitivity {V P : Type} [aff : AffineSpaceTheory V P] (p q r : P) :
    aff.groupV.op (aff.vsub r q) (aff.vsub q p) = aff.vsub r p := by
  -- Translating p by the composed displacement lands on r:
  --   (r-q) ∘ (q-p) applied to p  =  (r-q) applied to ((q-p) applied to p)  =  (r-q) applied to q  =  r
  have h : aff.vadd (aff.groupV.op (aff.vsub r q) (aff.vsub q p)) p = r := by
    rw [← aff.vaddAssoc, aff.vsubAdd, aff.vsubAdd]
  -- and `addVsub` says the displacement that lands on r from p is unique.
  calc aff.groupV.op (aff.vsub r q) (aff.vsub q p)
      = aff.vsub (aff.vadd (aff.groupV.op (aff.vsub r q) (aff.vsub q p)) p) p :=
        (aff.addVsub _ _).symm
    _ = aff.vsub r p := by rw [h]

/- @@@
### General Theorems About Vector Spaces

These theorems hold for *any* vector space satisfying `VectorSpaceTheory` (with appropriate type constraints).
The pattern demonstrates reusable proofs: write once over the abstract theory, apply to all implementations.
@@@ -/

/- @@@
First, two small facts about any group. Both vector space theorems below need
them, so we prove them once rather than twice.
@@@ -/

theorem Group.eq_id_of_idem {α : Type} (g : Group α) {a : α}
    (h : g.op a a = a) : a = g.id := by
  -- An idempotent element of a group is the identity: cancel one copy of `a`.
  have h' := congrArg (g.op (g.inv a)) h
  rwa [← g.assoc, g.invLeft, g.idLeft] at h'

theorem Group.inv_eq_of_op_eq_id {α : Type} (g : Group α) {a b : α}
    (h : g.op a b = g.id) : b = g.inv a := by
  -- Inverses in a group are unique.
  have h' := congrArg (g.op (g.inv a)) h
  rwa [← g.assoc, g.invLeft, g.idLeft, g.idRight] at h'

/- @@@
Now the vector space theorems. Note that `0 • v = 0` and `a • 0 = 0` are
*not* axioms -- they are consequences, and the derivation is the same trick
in both cases: show the thing is idempotent, then invoke the group fact above.

For `0 • v`: distributing `(0 + 0) • v` gives `0 • v + 0 • v`, but `0 + 0 = 0`,
so `0 • v` equals its own double and must therefore be the zero vector.
@@@ -/

theorem vector_zero_scalar {F V : Type} [Mul F] [One F] [vs : VectorSpaceTheory F V]
    (v : V) : vs.smul vs.groupF.id v = vs.groupV.id := by
  apply Group.eq_id_of_idem vs.groupV
  rw [← vs.addSmul, vs.groupF.idLeft]

theorem vector_scalar_zero {F V : Type} [Mul F] [One F] [vs : VectorSpaceTheory F V]
    (a : F) : vs.smul a vs.groupV.id = vs.groupV.id := by
  apply Group.eq_id_of_idem vs.groupV
  rw [← vs.smulAdd, vs.groupV.idLeft]

/- @@@
And scaling a negated vector negates the result, because `a • v` and
`a • (-v)` sum to `a • 0 = 0`, so the second is the inverse of the first.
@@@ -/

theorem vector_neg_scalar {F V : Type} [Mul F] [One F] [vs : VectorSpaceTheory F V]
    (a : F) (v : V) :
    vs.smul a (vs.groupV.inv v) = vs.groupV.inv (vs.smul a v) := by
  apply Group.inv_eq_of_op_eq_id vs.groupV
  rw [← vs.smulAdd, vs.groupV.invRight]
  exact vector_scalar_zero a

/- @@@
## Summary: The Theory-Implementation-Proof Pattern

**Theory Layer**: Abstract axioms define what properties a structure must have.
- `AffineSpaceTheory V P`: what axioms make something an affine space
- `VectorSpaceTheory F V`: what axioms make `V` a module over the scalars `F`
  (a vector space when `F` is a field)

**Implementation Layer**: Concrete types satisfy the theory.
- Rat, Rat × Rat, Rat × Rat × Rat are implementations
- Proofs that they satisfy the abstract axioms

**Proof Bridge Layer**: Generic theorems about the theory apply to all implementations.
- `affine_translation_inversion` and `affine_transitivity`: true for any
  affine space
- `vector_zero_scalar`, `vector_scalar_zero` and `vector_neg_scalar`: true for
  any module, hence for any vector space. None of these is an axiom; each is
  derived from the four scalar axioms plus two facts about groups.

This separation allows:
1. Reasoning abstractly (proving once for all implementations)
2. Checking concreteness (verifying implementations satisfy theory)
3. Reusing results (generic theorems apply everywhere)

The pattern scales: one abstract theory + many implementations + shared proofs.
@@@ -/

/- @@@
## Concrete Demonstration: One Proof, Three Implementations

`affine_translation_inversion` and `affine_transitivity` were each proven once,
over an arbitrary `AffineSpaceTheory V P`. Below they are applied at all three
dimensions. Note what is *absent*: there is no proof in any of these, only the
name of the generic theorem. That is the payoff the whole lesson is about.
@@@ -/

/- The type ascription on `vsub` is needed because the vector type `V` appears
   only in that field's *result*, so Lean cannot infer it from `p` and `q`
   alone. It is a hint to instance search, not an extra assumption. -/

example (p q : Rat) :
    AffineSpaceTheory.vadd (AffineSpaceTheory.vsub q p : Rat) p = q :=
  affine_translation_inversion p q

example (p q : Rat × Rat) :
    AffineSpaceTheory.vadd (AffineSpaceTheory.vsub q p : Rat × Rat) p = q :=
  affine_translation_inversion p q

example (p q : Rat × Rat × Rat) :
    AffineSpaceTheory.vadd (AffineSpaceTheory.vsub q p : Rat × Rat × Rat) p = q :=
  affine_translation_inversion p q

/- The composition law, likewise proven once and reused at each dimension. -/

example (p q r : Rat) :
    Group.op (AffineSpaceTheory.vsub r q : Rat) (AffineSpaceTheory.vsub q p : Rat)
      = (AffineSpaceTheory.vsub r p : Rat) :=
  affine_transitivity p q r

example (p q r : Rat × Rat) :
    Group.op (AffineSpaceTheory.vsub r q : Rat × Rat) (AffineSpaceTheory.vsub q p : Rat × Rat)
      = (AffineSpaceTheory.vsub r p : Rat × Rat) :=
  affine_transitivity p q r

example (p q r : Rat × Rat × Rat) :
    Group.op (AffineSpaceTheory.vsub r q : Rat × Rat × Rat)
             (AffineSpaceTheory.vsub q p : Rat × Rat × Rat)
      = (AffineSpaceTheory.vsub r p : Rat × Rat × Rat) :=
  affine_transitivity p q r

/- @@@
And because the axioms are now proven rather than assumed, the instances are
computable: the operations actually run.
@@@ -/

#eval (AffineSpaceTheory.vsub ((7 : Rat), (9 : Rat)) ((2 : Rat), (3 : Rat)) : Rat × Rat)
      -- (5, 6): the displacement from (2,3) to (7,9)

#eval (AffineSpaceTheory.vadd ((5 : Rat), (6 : Rat)) ((2 : Rat), (3 : Rat)) : Rat × Rat)
      -- (7, 9): applying that displacement to (2,3) returns to (7,9)

#eval (AffineSpaceTheory.vsub ((1 : Rat), (2 : Rat), (3 : Rat)) ((1 : Rat), (1 : Rat), (1 : Rat))
       : Rat × Rat × Rat)
      -- (0, 1, 2)

/- @@@
## The Same Pattern on the Vector Space Side

`vector_zero_scalar`, `vector_scalar_zero` and `vector_neg_scalar` were each
proven once over an arbitrary `VectorSpaceTheory F V`. Here they are at all
three dimensions -- again with no proof, only the theorem's name.

Recall that `Group.id` *is* the zero: it is `0` for ℚ, `(0, 0)` for ℚ², and
`(0, 0, 0)` for ℚ³.
@@@ -/

/- `0 • v = 0`, for every vector in every one of the three spaces. -/

example (v : Rat) :
    VectorSpaceTheory.smul (Group.id : Rat) v = (Group.id : Rat) :=
  vector_zero_scalar v

example (v : Rat × Rat) :
    VectorSpaceTheory.smul (Group.id : Rat) v = (Group.id : Rat × Rat) :=
  vector_zero_scalar v

example (v : Rat × Rat × Rat) :
    VectorSpaceTheory.smul (Group.id : Rat) v = (Group.id : Rat × Rat × Rat) :=
  vector_zero_scalar v

/- `a • 0 = 0`, for every scalar. -/

example (a : Rat) :
    VectorSpaceTheory.smul a (Group.id : Rat × Rat) = (Group.id : Rat × Rat) :=
  vector_scalar_zero a

/- `a • (-v) = -(a • v)`. -/

example (a : Rat) (v : Rat × Rat) :
    VectorSpaceTheory.smul a (Group.inv v) = Group.inv (VectorSpaceTheory.smul a v) :=
  vector_neg_scalar a v

/- @@@
And the scalar multiplications compute, too.
@@@ -/

#eval (VectorSpaceTheory.smul (2 : Rat) ((3 : Rat), (4 : Rat)) : Rat × Rat)
      -- (6, 8)
#eval (VectorSpaceTheory.smul (0 : Rat) ((3 : Rat), (4 : Rat)) : Rat × Rat)
      -- (0, 0), as vector_zero_scalar guarantees
#eval (VectorSpaceTheory.smul (1 : Rat) ((3 : Rat), (4 : Rat)) : Rat × Rat)
      -- (3, 4), as the oneSmul axiom requires
#eval (VectorSpaceTheory.smul (1/2 : Rat) ((1 : Rat), (2 : Rat), (3 : Rat)) : Rat × Rat × Rat)
      -- (1/2, 1, 3/2)

end TheoryImplProof
