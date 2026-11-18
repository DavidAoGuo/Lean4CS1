```lean
import Mathlib.Data.Set.Image

namespace E18
```

# Relations

In [Sets](./E17_Sets.md), membership was a proposition about one element.
Relations use a proposition about two elements.

A *relation* between types `α` and `β` is a predicate on pairs:

```lean
abbrev Rel (α β : Type*) := α → β → Prop
```

A term `r : Rel α β` applied to `a : α` and `b : β` gives a proposition
`r a b`: the claim that `a` and `b` are related.

A set `Set α` is a unary predicate. A binary relation `Rel α β` can also be
viewed as a set of pairs, `Set (α × β)`, by testing a pair `(a, b)` with `r a b`.
When the two argument types are the same, `Rel α α` is a *homogeneous relation*.
```lean
-- A binary relation is a curried predicate.
abbrev Rel (α β : Type*) := α → β → Prop

-- Example relations:
def divides : Rel Nat Nat := fun m n => ∃ k, n = m * k
def sameLength : Rel (List α) (List β) := fun xs ys => xs.length = ys.length
def lePair : Rel Nat Nat := (· ≤ ·)

-- Membership in a relation:
example : divides 3 12 := ⟨4, rfl⟩
example : divides 1 n := ⟨n, (Nat.one_mul n).symm⟩   -- for any n
```

> **Checkpoint — `divides`.** `divides m n` is `∃ k, n = m * k`; the example above
> witnesses `divides 3 12` with `k = 4`. **Predict** whether that witness equation holds,
> then check.
```lean
#eval decide (12 = 3 * 4)   -- predict first (the witness for divides 3 12)
```

> **Checkpoint — `sameLength`.** `sameLength xs ys` unfolds to `xs.length = ys.length`.
> **Predict** whether a 3-element list and a 3-element list are related, then check.
```lean
#eval decide ([1, 2, 3].length = ['a', 'b', 'c'].length)   -- predict first (sameLength unfolded)
```

> **Checkpoint — `lePair`.** `lePair` is `(· ≤ ·)` packaged as a `Rel Nat Nat`. **Predict**
> whether `3` and `5` are related, then check (using `≤` directly).
```lean
#eval decide ((3 : Nat) ≤ 5)   -- predict first (lePair 3 5)
```

## Properties of relations

Key relational properties are propositions.  We state each as a type
so that checking a relation has the property means inhabiting the type.
```lean
-- Reflexive: every element is related to itself
def RelReflexive (r : Rel α α) : Prop := ∀ a, r a a

-- Symmetric: if a is related to b then b is related to a
def RelSymmetric (r : Rel α α) : Prop := ∀ a b, r a b → r b a

-- Transitive: r a b and r b c implies r a c
def RelTransitive (r : Rel α α) : Prop := ∀ a b c, r a b → r b c → r a c

-- An equivalence relation satisfies all three:
def Equivalence' (r : Rel α α) : Prop :=
  RelReflexive r ∧ RelSymmetric r ∧ RelTransitive r

-- ≤ on Nat is reflexive and transitive but not symmetric:
example : RelReflexive (· ≤ · : Rel Nat Nat) :=
  fun a => Nat.le_refl a

example : RelTransitive (· ≤ · : Rel Nat Nat) :=
  fun _ _ _ => Nat.le_trans

example : ¬ RelSymmetric (· ≤ · : Rel Nat Nat) :=
  fun h => absurd (h 0 1 (Nat.zero_le 1)) (by decide)

-- = on Nat is an equivalence relation:
example : Equivalence' (· = · : Rel Nat Nat) :=
  ⟨fun _ => rfl,
   fun _ _ h => h.symm,
   fun _ _ _ h1 h2 => h1.trans h2⟩
```

> **Checkpoint — reflexivity.** `RelReflexive r` is `∀ a, r a a`. For `≤` on `Nat`,
> Lean can decide each concrete instance. **Predict** whether `3 ≤ 3` holds, then check.
```lean
#eval decide ((3 : Nat) ≤ 3)   -- predict first
```

> **Checkpoint — symmetry fails for `≤`.** Symmetry would need `r a b → r b a` for *all*
> `a, b`. **Predict** the witness that breaks it — `0 ≤ 1` holds but `1 ≤ 0` does not —
> then check.
```lean
#eval decide ((0 : Nat) ≤ 1 ∧ ¬ ((1 : Nat) ≤ 0))   -- predict first (a counterexample to symmetry)
```

> **Checkpoint — transitivity.** `RelTransitive r` needs `r a b → r b c → r a c`. **Predict**
> this instance chaining `1 ≤ 2` and `2 ≤ 3`, then check.
```lean
#eval decide (((1 : Nat) ≤ 2) → ((2 : Nat) ≤ 3) → ((1 : Nat) ≤ 3))   -- predict first
```

> **Checkpoint — equivalence (`=`).** `=` on `Nat` is reflexive, symmetric, and transitive.
> **Predict** this bundle — `2 = 2` and (`2 = 3 → 3 = 2`) — then check.
```lean
#eval decide ((2 : Nat) = 2 ∧ ((2 : Nat) = 3 → (3 : Nat) = 2))   -- predict first
```

## Relational composition and image

*Composition* of relations: following `r` and then `s` relates `a` to `c`
if there exists a bridge `b` such that `r a b` and `s b c`.

The *image* of a set under a function `f` is the set of outputs reachable by applying
`f` to its elements. This is also the relational image for the graph relation
`fun a b => f a = b` induced by `f`.
```lean
-- Relational composition:
def relComp (r : Rel α β) (s : Rel β γ) : Rel α γ :=
  fun a c => ∃ b, r a b ∧ s b c
```

> **Checkpoint — relational composition.** `relComp (· ≤ ·) (· ≤ ·) 1 3` is
> `∃ b, 1 ≤ b ∧ b ≤ 3`.
> A *witness* establishes the existential claim. **Predict** whether `b = 2` works by checking
> `1 ≤ 2 ∧ 2 ≤ 3`.
```lean
#eval decide (((1 : Nat) ≤ 2) ∧ ((2 : Nat) ≤ 3))   -- predict first (b = 2 witnesses relComp)

-- Image of a set under a function (as a relation):
#check @Set.image
-- Set.image : (α → β) → Set α → Set β
-- (Set.image f s) b ↔ ∃ a ∈ s, f a = b

-- Preimage:
#check @Set.preimage
-- Set.preimage : (α → β) → Set β → Set α
-- (Set.preimage f t) a ↔ f a ∈ t

-- Image of the universal set is the range:
theorem image_univ (f : α → β) :
    Set.image f Set.univ = Set.range f :=
  Set.image_univ
```

> **Checkpoint — image / range.** `b ∈ Set.image f s` means `∃ a ∈ s, f a = b`, and
> `image f univ = range f`. A witness `a` settles one such membership. **Predict** whether
> `6` lies in the image of `(· * 2)` because `3 ↦ 6`, i.e. that `(· * 2) 3 = 6`, then check.
```lean
#eval decide ((fun (x : Nat) => x * 2) 3 = 6)   -- predict first (3 ↦ 6, so 6 ∈ image)
```

## Functions as total relations

A function `f : α → β` determines a *total functional relation*, the set of
pairs `{(a, f a) | a : α}`. A relation is *functional* when each input is related
to at most one output, and *total* when each input is related to at least one
output. Together these properties give exactly one output per input.

Sets and relations are the language in which we write specifications for
programs dealing with collections of data.  The Dict type class (Week 11)
is a partial function — a relation where each key relates to at most one
value.  Sorting is about relations between the input and output lists.
> **Checkpoint — functional relation.** A function `f` induces the relation
> `fun a b => f a = b`, in which each input relates to *exactly one* output. **Predict**
> whether `2` relates to `4` under `(· * 2)`, i.e. that `(· * 2) 2 = 4`, then check.
```lean
#eval decide ((fun (x : Nat) => x * 2) 2 = 4)   -- predict first
```

## Exercises

Each exercise carries a banner — `[id] · competency · tier · level · target` — and,
where it asks you to build something, an **acceptance check**: paste it beneath your
definition in your own file and it must succeed.  `#guard` is silent on success and
errors on failure, so the compiler is your grader.  See `EXERCISE_CONVENTIONS.md` for
the schema.  Do every **core** exercise; **stretch** exercises go deeper and are
optional.

---

**[E18.1]** · *counterexample finding* · tier 1 · **core**

A student claims *"`divides` is symmetric: if `m` divides `n` then `n` divides `m`."*  It
is **wrong**.  On `Nat`, `divides m n` (`∃ k, n = m * k`, defined above) is exactly `m ∣ n`.  Find a
witness where one direction holds and the other fails, and encode it as the fact that
**must hold**, so the check **succeeds**:

```lean
#guard decide ((3 : Nat) ∣ 12 ∧ ¬ ((12 : Nat) ∣ 3)) = true
#guard decide (¬ ((2 : Nat) ∣ 3)) = true
```

Which single property of `≤` also fails, with the *same shape* of witness?

---

**[E18.2]** · *type-directed derivation* · tier 2 · **core** · target `converseB`

Derive `converseB : (α → β → Bool) → (β → α → Bool)`, the *converse* of a Boolean relation
— swap the two arguments, as in the definition of symmetry above.  Produce a
**derivation trace** in the Week 2 §2.6 format — the trace is the graded artifact — then
the `def`.  *First-step hint:* the result type is `β → α → Bool`, so introduce the relation
`r`, then `b : β`, then `a : α`; only `r a b` type-checks as the body.  Effort: ~3 trace
steps, 1 line of code.

```lean
#guard converseB (fun a b => decide (a ≤ b)) 5 3 = true    -- swaps to decide (3 ≤ 5)
#guard converseB (fun a b => decide (a ≤ b)) 3 5 = false   -- swaps to decide (5 ≤ 3)
#guard converseB (fun a b => a == b) 2 (2 : Nat) = true
```

---

**[E18.3]** · *specification writing + decidability identification* · tier 1 · **stretch** · target `IsOrder`

State, as a `Prop`, what it means for `r : Rel Nat Nat` to be an *order*: reflexive,
transitive, and **antisymmetric** (`∀ a b, r a b → r b a → a = b`).  Do not prove the
general claim for `≤`; instead confirm each of the three clauses on concrete `Nat`
instances — antisymmetry holds *vacuously* when the two `≤`s cannot both point the
same way:

```lean
-- def IsOrder (r : Rel Nat Nat) : Prop :=
--   (∀ a, r a a) ∧ (∀ a b c, r a b → r b c → r a c) ∧ (∀ a b, r a b → r b a → a = b)
#guard decide ((3 : Nat) ≤ 3) = true                                         -- reflexive instance
#guard decide (((1 : Nat) ≤ 2) → ((2 : Nat) ≤ 5) → ((1 : Nat) ≤ 5)) = true   -- transitive instance
#guard decide (((2 : Nat) ≤ 3) → ((3 : Nat) ≤ 2) → (2 : Nat) = 3) = true     -- antisymmetric instance
```

Why is the general `IsOrder (· ≤ ·)` statement itself **not** `decide`-checkable?

---

**[E18.4]** · *type reading (free theorems)* · tier 2 · **stretch**

Look at the type of `relComp`, namely `Rel α β → Rel β γ → Rel α γ`, polymorphic
in `α`, `β`, `γ`. Why does the definition quantify over a bridging `b : β`?
What would the composition mean if `β` were empty? Give a different definition
with the same type to show that the type alone does not require composition.
This echoes the free theorems of Week 7 (§7.2). No code to submit.
---

**[E18.5]** · *specification writing + decidability identification* · tier 1 · **stretch** · target `IsPrefix`

Define the relation `IsPrefix : Rel (List α) (List α)` — `xs` is a prefix of `ys` when some
`zs` extends it:

```lean
def IsPrefix (xs ys : List α) : Prop := ∃ zs, xs ++ zs = ys
```

Using the relation properties above (`RelReflexive` and `RelTransitive`), state — do not prove — that
`IsPrefix` is reflexive and transitive.  *Hint for reflexivity:* which `zs` witnesses
`xs ++ zs = xs`?  The bare `∃ zs` ranges over an unbounded domain, so `decide` cannot close
it; check instances through the decidable Boolean `List.isPrefixOf` instead, and say in one
line why that one computes while the `∃` does not:

```lean
#guard ([1, 2] : List Nat).isPrefixOf [1, 2, 3]
#guard ([] : List Nat).isPrefixOf [1, 2, 3]
#guard ([1, 2, 3] : List Nat).isPrefixOf [1, 2, 3]   -- reflexivity, on an instance
#guard !(([2, 3] : List Nat).isPrefixOf [1, 2, 3])
```

---

**[E18.6]** · *specification reading + counterexample finding* · tier 3 (reading) +
tier 1 · **stretch**

State the specification *"the image of `s ∩ t` under `f` is a subset of
`Set.image f s ∩ Set.image f t`."*  This is Mathlib's `Set.image_inter_subset`, whose type is
`f '' (s ∩ t) ⊆ f '' s ∩ f '' t` — look it up and read it.  Then explain in two or three
sentences why this is only a **subset** and not an equality, exhibit concrete `f`, `s`, `t`
over `Nat` for which the two sides genuinely differ, and name the property of `f` that would
buy you the reverse inclusion.  No code to submit.

```lean
end E18
```


<div class="issue-box">📝 <a href="https://github.com/kevinsullivan/Lean4CS1/issues/new">Report an issue</a> with this section</div>

