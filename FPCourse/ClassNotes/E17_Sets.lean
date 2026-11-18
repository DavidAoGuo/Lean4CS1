import Mathlib.Order.BooleanAlgebra.Set

/-! @@@
# Sets

## Sets as predicates

In Lean (and in Mathlib), a *set* over type `α` is simply a predicate:

```lean
def Set (α : Type u) : Type u := α → Prop
```

A set `s : Set α` is a function that takes an element `x : α` and
returns a proposition `s x : Prop` — the claim that `x` belongs to `s`.

This definition is mathematically natural and computationally illuminating:
membership is a proposition, and propositions are types.  A proof that
`x ∈ s` is a term of type `s x`.

The connection to the course themes: sets are logical types indexed by
their elements.  Every operation on sets is an operation on propositions.
@@@ -/

namespace E17

/-! @@@
## Set membership and basic notation
@@@ -/

-- Set α is defined in Mathlib as α → Prop
#check @Set        -- (α : Type u) → Type u
#print Set         -- def Set (α : Type u) := α → Prop

-- Membership: x ∈ s is notation for s x
example : (3 : Nat) ∈ ({1, 2, 3} : Set Nat) := by decide
example : (5 : Nat) ∉ ({1, 2, 3} : Set Nat) := by decide

/-! @@@
> **Checkpoint — set membership.** `x ∈ s` is just `s x`, the proposition that `x`
> satisfies the predicate. **Predict** the Boolean below — is `3` one of the listed
> elements? — then check.
@@@ -/

#eval decide ((3 : Nat) ∈ ({1, 2, 3} : Set Nat))   -- predict first

-- The universal set (all elements)
#check @Set.univ   -- Set α  (= fun _ => True)

-- The empty set
#check (∅ : Set _)  -- Set α  (= fun _ => False)

-- Membership in univ and empty:
theorem mem_univ (x : α) : x ∈ (Set.univ : Set α) :=
  trivial

theorem not_mem_empty (x : α) : x ∉ (∅ : Set α) :=
  False.elim

/-! @@@
> **Checkpoint — `Set.univ` and `∅`.** `univ = fun _ => True` and `∅ = fun _ => False`
> are the two constant sets. **Predict** both Booleans — everything is in `univ`, nothing
> is in `∅` — then check.
@@@ -/

#eval decide ((7 : Nat) ∈ (Set.univ : Set Nat))   -- predict first
#eval decide ((7 : Nat) ∈ (∅ : Set Nat))          -- predict first

/-! @@@
## Set operations as proposition operations

Because sets are predicates, every set operation corresponds to a
propositional connective.

| Set operation | Logical meaning | Notation |
|--------------|----------------|---------|
| `s ∩ t` (intersection) | `s x ∧ t x` | `∩` |
| `s ∪ t` (union) | `s x ∨ t x` | `∪` |
| `sᶜ` (complement) | `¬ s x` | `ᶜ` |
| `s \ t` (difference) | `s x ∧ ¬ t x` | `\` |
| `s ⊆ t` (subset) | `∀ x, s x → t x` | `⊆` |

Read `s ⊆ t` aloud: "for every `x`, if `x` belongs to `s` then `x` belongs to `t`."
`s ∩ t = s ∪ t` would mean that for every `x`, `x ∈ s ∧ x ∈ t` iff
`x ∈ s ∨ x ∈ t`. An element that belongs to exactly one of the two sets
refutes that equality.

Notice the pattern: **every set statement reduces to a statement about propositions,
quantified over elements.** When you prove something about sets, you are doing
propositional logic with `∀` threading through.
@@@ -/

-- Intersection is ∧:
theorem mem_inter_iff (x : α) (s t : Set α) :
    x ∈ s ∩ t ↔ x ∈ s ∧ x ∈ t :=
  Set.mem_inter_iff x s t

/-! @@@
> **Checkpoint — intersection `∩`.** By `mem_inter_iff`, `x ∈ s ∩ t` means `x ∈ s ∧ x ∈ t`.
> **Predict** whether `3` is in *both* sets below, then check.
@@@ -/

#eval decide ((3 : Nat) ∈ (({1, 2, 3} ∩ {3, 4, 5}) : Set Nat))   -- predict first

-- Union is ∨:
theorem mem_union_iff (x : α) (s t : Set α) :
    x ∈ s ∪ t ↔ x ∈ s ∨ x ∈ t :=
  Set.mem_union x s t

/-! @@@
> **Checkpoint — union `∪`.** By `mem_union_iff`, `x ∈ s ∪ t` means `x ∈ s ∨ x ∈ t`.
> **Predict** whether `1` is in *either* set below, then check.
@@@ -/

#eval decide ((1 : Nat) ∈ (({1, 2, 3} ∪ {3, 4, 5}) : Set Nat))   -- predict first

-- Subset is ∀/→:
theorem subset_def (s t : Set α) :
    s ⊆ t ↔ ∀ x, x ∈ s → x ∈ t :=
  Iff.intro (fun h _x hx => h hx) (fun h x hx => h x hx)

/-! @@@
> **Checkpoint — complement `ᶜ`.** `x ∈ sᶜ` means `¬ (x ∈ s)`. **Predict** whether `5`,
> which is not listed, belongs to the complement below, then check.
@@@ -/

#eval decide ((5 : Nat) ∈ (({1, 2, 3} : Set Nat)ᶜ))   -- predict first

/-! @@@
> **Checkpoint — difference `\`.** `x ∈ s \ t` means `x ∈ s ∧ ¬ (x ∈ t)`. **Predict**
> whether `1` survives removing `{3, 4}` from `{1, 2, 3}`, then check.
@@@ -/

#eval decide ((1 : Nat) ∈ (({1, 2, 3} \ {3, 4}) : Set Nat))   -- predict first

/-! @@@
> **Checkpoint — subset `⊆`.** `s ⊆ t` is `∀ x, x ∈ s → x ∈ t` — one implication *per
> element*. Here Lean can decide an individual implication at a concrete `Nat`. **Predict**
> that implication at `x = 2` (is `2 ∈ {1,2} → 2 ∈ {1,2,3}` true?), then check.
@@@ -/

#eval decide ((2 : Nat) ∈ ({1, 2} : Set Nat) → (2 : Nat) ∈ ({1, 2, 3} : Set Nat))   -- predict first

/-! @@@
## Set algebraic laws as propositions

These laws are propositions that hold for all sets.  The proofs are
provided as term-mode proofs.
@@@ -/

-- Commutativity:
theorem inter_comm (s t : Set α) : s ∩ t = t ∩ s :=
  Set.inter_comm s t

theorem union_comm (s t : Set α) : s ∪ t = t ∪ s :=
  Set.union_comm s t

/-! @@@
> **Checkpoint — `∩` commutativity.** `inter_comm` says `s ∩ t = t ∩ s`, so membership
> must agree on either side. **Predict** the Boolean (an `↔` of memberships at `x = 2`),
> then check.
@@@ -/

#eval decide ((2 : Nat) ∈ (({1, 2, 3} ∩ {2, 3, 4}) : Set Nat) ↔ (2 : Nat) ∈ (({2, 3, 4} ∩ {1, 2, 3}) : Set Nat))   -- predict first

-- Distributivity:
theorem inter_union_distrib (r s t : Set α) :
    r ∩ (s ∪ t) = (r ∩ s) ∪ (r ∩ t) :=
  Set.inter_union_distrib_left r s t

/-! @@@
> **Checkpoint — `∩`/`∪` distributivity.** `r ∩ (s ∪ t) = (r ∩ s) ∪ (r ∩ t)`. **Predict**
> the membership `↔` below at `x = 2`, then check.
@@@ -/

#eval decide ((2 : Nat) ∈ (({1, 2} ∩ ({2, 3} ∪ {4, 5})) : Set Nat) ↔ (2 : Nat) ∈ ((({1, 2} ∩ {2, 3}) ∪ ({1, 2} ∩ {4, 5})) : Set Nat))   -- predict first

-- De Morgan:
theorem compl_union (s t : Set α) : (s ∪ t)ᶜ = sᶜ ∩ tᶜ :=
  Set.compl_union s t

/-! @@@
> **Checkpoint — De Morgan.** `(s ∪ t)ᶜ = sᶜ ∩ tᶜ`: being outside the union means
> being outside both sets.
> **Predict** the membership `↔` at `x = 5` (in neither `{1,2}` nor `{3,4}`), then check.
@@@ -/

#eval decide ((5 : Nat) ∈ ((({1, 2} ∪ {3, 4}) : Set Nat)ᶜ) ↔ (5 : Nat) ∈ ((({1, 2} : Set Nat)ᶜ ∩ ({3, 4} : Set Nat)ᶜ)))   -- predict first

-- Subset is transitive:
theorem subset_trans {s t u : Set α} (h1 : s ⊆ t) (h2 : t ⊆ u) : s ⊆ u :=
  Set.Subset.trans h1 h2

/-! @@@
## Exercises

Each exercise carries a banner — `[id] · competency · tier · level · target` — and,
where it asks you to build something, an **acceptance check**: paste it beneath your
definition in your own file and it must succeed.  `#guard` is silent on success and
errors on failure, so the compiler is your grader.  See `EXERCISE_CONVENTIONS.md` for
the schema.  Do every **core** exercise; **stretch** exercises go deeper and are
optional.

---

**[E17.1]** · *specification writing* · tier 1 (+ tier-3 reading) · **core** · target `DeMorganInterSpec`

State, as a `Prop`, De Morgan's law for intersection: *"for all sets `s t` and every `x`,
`x ∈ (s ∩ t)ᶜ ↔ x ∈ sᶜ ∪ tᶜ`."*  Do **not** prove the general statement — that proof is
`Set.compl_inter`. For the tier-3 reading, see `Set.compl_union` in the set algebra section above.
Confirm the spec on concrete sets, covering an element in **both**, in **neither**, and in
**exactly one**:

```lean
-- def DeMorganInterSpec : Prop :=
--   ∀ (s t : Set Nat) (x : Nat), x ∈ (s ∩ t)ᶜ ↔ x ∈ sᶜ ∪ tᶜ
#guard decide ((2 : Nat) ∈ ((({1,2} ∩ {2,3}) : Set Nat)ᶜ) ↔ (2 : Nat) ∈ ((({1,2} : Set Nat)ᶜ) ∪ (({2,3} : Set Nat)ᶜ)))   -- 2 in both
#guard decide ((5 : Nat) ∈ ((({1,2} ∩ {2,3}) : Set Nat)ᶜ) ↔ (5 : Nat) ∈ ((({1,2} : Set Nat)ᶜ) ∪ (({2,3} : Set Nat)ᶜ)))   -- 5 in neither
#guard decide ((1 : Nat) ∈ ((({1,2} ∩ {2,3}) : Set Nat)ᶜ) ↔ (1 : Nat) ∈ ((({1,2} : Set Nat)ᶜ) ∪ (({2,3} : Set Nat)ᶜ)))   -- 1 in exactly one
```

In one line: which tier does the *general* statement live in, and which the three checks?

---

**[E17.2]** · *decidability identification* · tier 1 · **core**

For each proposition, say **whether `decide` can close it and why** — a *finite literal
set* is decidable, but `⊆` and an unbounded `∀` both range over *all* of `Nat` — the
judgment is the point, not the tool-use.  *Then* check only the decidable ones:

(a) `(3 : Nat) ∈ ({1, 2, 3} : Set Nat)`
(b) `({1, 2} : Set Nat) ⊆ {1, 2, 3}`
(c) `∀ a : Nat, a ≤ a`
(d) `(1 : Nat) ∈ (({1, 2} ∪ {3}) : Set Nat)`

```lean
#guard decide ((3 : Nat) ∈ ({1, 2, 3} : Set Nat)) = true
#guard decide ((1 : Nat) ∈ (({1, 2} ∪ {3}) : Set Nat)) = true
-- (b) and (c) have no check on purpose: say why decide cannot close each
--     (both quantify over every Nat, not over a finite literal set).
```

@@@ -/

end E17
