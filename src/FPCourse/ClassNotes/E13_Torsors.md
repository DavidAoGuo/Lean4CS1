# Torsors: Free and Transitive Group Actions

So far we've studied groups as abstract algebraic objects. But groups
are most interesting when they *act* on something: a rotation acts on
the corners of a square, a permutation acts on a sequence of elements,
a translation acts on the points of a plane.

A *torsor* for a group `G` is a set `T` where `G` acts on elements of
`T` in two special ways:
  - *Free*: no non-identity element of `G` leaves any point of `T` fixed
  - *Transitive*: any two points of `T` are related by some element of `G`

Together, these properties mean that `T` has no intrinsic identity or
structure -- all points are equivalent, and they're only distinguished
by the group action. A torsor is "a group without a distinguished element."

The phrase is worth unpacking, because it is the whole idea. A group has a
distinguished element: the identity. A torsor for `G` looks exactly like `G`
once you arbitrarily nominate one of its points to serve as "zero" -- but
nothing in the structure nominates one for you. Clock positions are like this.
There is nothing intrinsically special about 12 o'clock; it is a convention.
What *is* intrinsic is the three-hour shift that takes 12 to 3, and that
shift is a group element, not a position.

Examples: clock hours under time shifts, calendar dates under day shifts,
points in a plane under translations, directions in space under rotations.

This lesson builds on the `Group` class from the previous one, which we
import rather than redefine.
```lean
import FPCourse.ClassNotes.E13_Groups

namespace Torsors

open Groups
```

## The `Torsor` Class

Four fields of data and law. The group `G` is an instance-implicit parameter,
so a torsor always carries the group structure it acts by.
```lean
class Torsor (G T : Type) where
  [groupG : Group G]
  act        : G → T → T
  actId      : ∀ t : T, act groupG.id t = t
  actComp    : ∀ g h : G, ∀ t : T, act (groupG.op g h) t = act g (act h t)
  actFree    : ∀ g : G, ∀ t : T, act g t = t → g = groupG.id
  actTransitive : ∀ t₁ t₂ : T, ∃ g : G, act g t₁ = t₂
```

One caveat about this definition, stated plainly because it is a real gap
rather than a subtlety. The axioms above are all satisfied *vacuously* when
`T` is empty: there is no point for a group element to fix, and no pair of
points to relate. So by these axioms the empty type is a "torsor" for every
group, which is not what anyone means. The standard definition additionally
requires `T` to be nonempty, and only then does "a group without a
distinguished element" follow -- a nonempty torsor really is in bijection
with `G`. We leave the axioms as they are for readability, but the
nonemptiness requirement is part of the real definition.
## Instance 1: Clock Hours (Integers Modulo 12)

The motivating example from the start of this lesson. The positions are
`Fin 12`, the shifts are also `Fin 12`, and the action is addition mod 12.
Adding an hour offset to a current hour gives the new hour, wrapping at 12.

First the group of shifts:
```lean
instance : Group (Fin 12) where
  op      : Fin 12 → Fin 12 → Fin 12 := (· + ·)
  id      : Fin 12 := 0
  assoc   : ∀ a b c : Fin 12, (a + b) + c = a + (b + c) :=
    fun a b c => by ext; simp [Fin.add_def, Nat.add_assoc]
  idLeft  : ∀ a : Fin 12, 0 + a = a := fun a => by ext; simp [Fin.add_def]
  idRight : ∀ a : Fin 12, a + 0 = a := fun a => by ext; simp [Fin.add_def]
  inv     : Fin 12 → Fin 12 := fun a => -a
  invLeft : ∀ a : Fin 12, (-a) + a = 0 :=
    fun a => by ext; simp [Fin.add_def, Fin.neg_def]
  invRight: ∀ a : Fin 12, a + (-a) = 0 :=
    fun a => by ext; simp [Fin.add_def, Fin.neg_def]
```

And now the torsor. Because `Fin 12` is *finite*, we get to prove all four
axioms by a method unavailable for ℚ: exhaustive case analysis. `decide`
checks every one of the 12, 144, or 1728 cases and reports back. This is
worth seeing once -- for finite structures, "is this a theorem?" can be a
decidable question, and Lean will simply answer it.
```lean
instance : Torsor (Fin 12) (Fin 12) where
  groupG        := inferInstance
  act           := (· + ·)
  actId         := by decide
  actComp       := by decide
  actFree       := by decide
  actTransitive := by decide

#eval (3 : Fin 12) + (5 : Fin 12)   -- 8
#eval (10 : Fin 12) + (5 : Fin 12)  -- 3 (wraps around)
#eval (0 : Fin 12) + (7 : Fin 12)   -- 7
```

Freeness is the interesting axiom here. It says that the only shift leaving
any hour unchanged is the zero shift -- a 5-hour shift moves *every* position.
Transitivity says you can get from any hour to any other by some shift. Taken
together: the twelve positions are interchangeable, and all the structure
lives in the shifts.
## Instance 2: ℚ (Rational Numbers)

The rational numbers form a torsor under themselves via addition.
Every rational can be shifted to every other rational by adding an
appropriate rational offset, and only 0 leaves any rational unchanged.

This uses the `Group ℚ` instance from the groups lesson. Note that here we
cannot appeal to `decide`: ℚ is infinite, so the proofs must be genuine
arguments rather than exhaustive checks.
```lean
instance : Torsor Rat Rat where
  groupG    := inferInstance
  act       := (· + ·)
  actId     := Rat.zero_add
  actComp   := fun g h t => Rat.add_assoc g h t
  actFree   := fun g t h => by
    -- If g + t = t, then g = 0 (the identity).
    -- Subtract t from both sides and cancel.
    have eq : g + t - t = t - t := by rw [h]
    simp [Rat.add_sub_cancel, Rat.sub_self] at eq
    exact eq
  actTransitive := fun t₁ t₂ => ⟨t₂ - t₁, by simp [Rat.sub_add_cancel]⟩
```

## Instance 3: ℚ × ℚ, the Rational Plane

The Cartesian product ℚ × ℚ is a torsor for the group ℚ × ℚ under
componentwise addition. Every point can be shifted by any vector, and the
only vector fixing any point is the zero vector `(0, 0)`.

This is the example that matters most for what follows: it is the first
time we see *points* being acted on by *translations*, which is exactly the
structure an affine space formalizes. The group instance again comes from
the groups lesson.
```lean
instance : Torsor (Rat × Rat) (Rat × Rat) where
  groupG    := inferInstance
  act       := fun (g₁, g₂) (t₁, t₂) => (g₁ + t₁, g₂ + t₂)
  -- Identity action: (0, 0) + (t₁, t₂) = (t₁, t₂), componentwise 0 + tᵢ = tᵢ
  actId     := fun ⟨t₁, t₂⟩ => by
    show ((0 : Rat) + t₁, (0 : Rat) + t₂) = (t₁, t₂)
    simp [Rat.zero_add]
  -- Composition: (g + h) + t = g + (h + t), by associativity in each component
  actComp   := fun ⟨g₁, g₂⟩ ⟨h₁, h₂⟩ ⟨t₁, t₂⟩ => by
    show ((g₁ + h₁) + t₁, (g₂ + h₂) + t₂) = (g₁ + (h₁ + t₁), g₂ + (h₂ + t₂))
    simp [Rat.add_assoc]
  -- Freeness: if (g₁, g₂) + (t₁, t₂) = (t₁, t₂) then g = (0, 0).
  -- Same cancellation argument as the ℚ case, applied in each component.
  actFree   := fun ⟨g₁, g₂⟩ ⟨t₁, t₂⟩ h => by
    have h' : (g₁ + t₁, g₂ + t₂) = (t₁, t₂) := h
    have e₁ : g₁ + t₁ = t₁ := congrArg Prod.fst h'
    have e₂ : g₂ + t₂ = t₂ := congrArg Prod.snd h'
    have f₁ : g₁ = 0 := by
      have c : g₁ + t₁ - t₁ = t₁ - t₁ := by rw [e₁]
      simp [Rat.add_sub_cancel, Rat.sub_self] at c
      exact c
    have f₂ : g₂ = 0 := by
      have c : g₂ + t₂ - t₂ = t₂ - t₂ := by rw [e₂]
      simp [Rat.add_sub_cancel, Rat.sub_self] at c
      exact c
    show ((g₁, g₂) : Rat × Rat) = ((0 : Rat), (0 : Rat))
    rw [f₁, f₂]
  actTransitive := fun (t₁, t₂) (s₁, s₂) => ⟨(s₁ - t₁, s₂ - t₂), by simp [Rat.sub_add_cancel]⟩
```

## What the Torsor Abstraction Buys

All four axioms are machine-checked for all three instances -- no `sorry`
anywhere -- so each instance is also computable and its operations run.

The laws ensure that:
  - Applying the identity doesn't move anything
  - Actions compose consistently
  - Every point can reach every other point
  - No non-identity element fixes any point

One abstraction, and clocks, rationals, and the plane all satisfy it. That
is the payoff: reasoning done once about `Torsor G T` applies to every
instance, whether the underlying set is finite or infinite.

## Where This Goes Next

Notice what the ℚ × ℚ instance does *not* express. We wrote `Torsor (ℚ × ℚ)
(ℚ × ℚ)`, using the same type for shifts and for positions, so nothing stops
us from adding two positions together -- an operation with no geometric
meaning. The action is also given as a bare function with an existence proof
for transitivity, rather than an operation that *computes* the displacement
between two points.

The next lesson addresses both: it gives points and vectors distinct types,
and replaces "there exists a group element relating these points" with a
`vsub` operation that produces it. That structure is an *affine space*, and
it is a torsor with better ergonomics.
```lean
end Torsors
```


<div class="issue-box">📝 <a href="https://github.com/kevinsullivan/Lean4CS1/issues/new">Report an issue</a> with this section</div>

