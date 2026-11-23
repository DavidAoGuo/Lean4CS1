```lean
import Mathlib.Order.BooleanAlgebra.Set
```

# Sets

## Sets as membership predicates

A set is usually treated as a primitive notion, with its own membership
relation governed by its own axioms. Lean and Mathlib make a different
choice: a *set* over type `α` is **represented as** a predicate on `α` —
call it the set's **membership predicate**, the term this chapter will use
throughout for a predicate that represents a set.

```lean
def Set (α : Type u) : Type u := α → Prop
```

A set `s : Set α` *is* its membership predicate: a function that takes an
element `x : α` and returns a proposition `s x : Prop` — the claim that `x`
belongs to `s`. Membership `x ∈ s` is *defined to be* `s x`; there is no
independent membership relation to reason about.

This representation choice is the single most important idea in this
chapter: **because a set is a membership predicate, every claim about sets
is already a claim about propositions, and every proof about sets reduces
to a proof in predicate logic.** To show `x ∈ s`, unfold `s` at `x` and you are holding an
ordinary proposition built from `∧`, `∨`, `¬`, `→`, `∀`, `∃` — the same
connectives and quantifiers from earlier chapters. Nothing new has to be
invented for sets: `∩`, `∪`, `ᶜ`, `⊆`, and the rest each unfold to a familiar
connective, and every theorem about them is just the matching fact of
predicate logic, imported rather than reproved.
```lean
namespace E17
```

### Reminder: what a predicate is

A *predicate* on a type `α` is just a function `p : α → Prop`: hand it a
subject `x : α`, and `p x` is the proposition it asserts about `x`. Nothing
set-specific yet — this is the same notion of predicate from earlier
chapters, applied to one concrete subject at a time.

Take `p := fun x => x = 1 ∨ x = 2`. Applying `p` to `2` gives the proposition
`2 = 1 ∨ 2 = 2`: true, via its right disjunct and `rfl`. Applying `p` to `0`
gives `0 = 1 ∨ 0 = 2`: false, since `0` is neither — and that, too, has a
term-mode proof, of the negation.
```lean
def P : Nat → Prop := fun x => x = 1 ∨ x = 2

example : P 2 := Or.inr rfl

example : ¬ P 0 := fun h => h.elim nofun nofun
```

### The reduction, worked by hand

Here is that reduction in miniature, with no library notation in the way.
Define a set directly as its membership predicate — no `{...}` literal, no Mathlib lemma:
```lean
def Small : Set Nat := fun x => x = 3 ∨ x = 5
```

By that `def`, `x ∈ Small` *is* `x = 3 ∨ x = 5` — definitionally, with no
unfolding lemma needed. So the set-membership claim `3 ∈ Small` has exactly
the proof of the proposition `3 = 3 ∨ 3 = 5`: pick the left disjunct, and
`rfl` settles the equation.
```lean
example : (3 : Nat) ∈ Small := Or.inl rfl
```

`Or.inl` and `rfl` are moves of predicate logic, not of set theory — nothing
about `Small` being a *set* was used beyond unfolding it to its membership
predicate. That is the reduction the rest of this chapter relies on.
## Set membership and basic notation
```lean
-- Set α is defined in Mathlib as α → Prop
#check @Set        -- (α : Type u) → Type u
#print Set         -- def Set (α : Type u) := α → Prop
```

The brace notation `{1, 2, 3}` is built from two more primitive set operations,
`insert` and the singleton `{·}` — `{1, 2, 3} = insert 1 (insert 2 {3})`. Both are
still just membership predicates:
```lean
-- insert a s : Set α  (= fun x => x = a ∨ s x) -- adds a to s
theorem mem_insert_iff (x a : α) (s : Set α) :
    x ∈ insert a s ↔ x = a ∨ x ∈ s :=
  Set.mem_insert_iff

-- {a} : Set α  (= fun x => x = a) -- the set containing exactly a
theorem mem_singleton_iff (x a : α) :
    x ∈ ({a} : Set α) ↔ x = a :=
  Set.mem_singleton_iff
```

Chaining those two unfolds `{1, 2, 3}` to exactly the membership predicate you'd expect:
`x ∈ {1, 2, 3} ↔ x = 1 ∨ x = 2 ∨ x = 3`. So the literal is still "a function to
`Prop`"; it is just built up one element at a time rather than written as a `fun`.

### Reminder: tactic mode

Every proof so far in this chapter has been a single term, written directly
after `:=`. Lean's other proof style, *tactic mode* — introduced back in
`E05_Exists` — writes the proof as a script of tactics instead: subroutines,
entered with `by`, that each transform the remaining goal and build the
term for you.

The tactic below is `simp only [lemmas...]`: it rewrites the goal using
*only* the listed `↔`/`=` lemmas, left to right, as many times as any of
them applies. Here it rewrites `x ∈ {1, 2, 3}` by `mem_insert_iff` and then
`mem_singleton_iff` until the goal reads `x = 1 ∨ x = 2 ∨ x = 3` — exactly
the statement being proved, so the tactic script ends there.
```lean
example (x : Nat) : x ∈ ({1, 2, 3} : Set Nat) ↔ x = 1 ∨ x = 2 ∨ x = 3 := by
  simp only [mem_insert_iff, mem_singleton_iff]
```

The next tactic is `decide`: it evaluates a *decidable* proposition to
`true` or `false` by direct computation, and closes the goal when the
result is `true`. Membership in a finite literal set like `{1, 2, 3}` is
decidable, so `decide` settles both claims below by just computing.
```lean
-- Membership: x ∈ s is notation for s x
example : (3 : Nat) ∈ ({1, 2, 3} : Set Nat) := by decide
example : (5 : Nat) ∉ ({1, 2, 3} : Set Nat) := by decide
```

> **Checkpoint — set membership.** `x ∈ s` is just `s x`, the proposition that `x`
> satisfies the membership predicate. **Predict** the Boolean below — is `3` one of the listed
> elements? — then check.
```lean
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
```

> **Checkpoint — `Set.univ` and `∅`.** `univ = fun _ => True` and `∅ = fun _ => False`
> are the two constant sets. **Predict** both Booleans — everything is in `univ`, nothing
> is in `∅` — then check.
```lean
#eval decide ((7 : Nat) ∈ (Set.univ : Set Nat))   -- predict first
#eval decide ((7 : Nat) ∈ (∅ : Set Nat))          -- predict first
```

## Set operations as proposition operations

Because sets are membership predicates, every set operation corresponds to a
propositional connective — some *construct* a set from scratch (the first
four rows, already met above), the rest *combine* sets that already exist.

| Set operation | Logical meaning | Notation |
|--------------|----------------|---------|
| `∅` (empty set) | `False` | `∅` |
| `Set.univ` (universal set) | `True` | `Set.univ` |
| `insert a s` (insert) | `x = a ∨ s x` | `insert` |
| `{a}` (singleton) | `x = a` | `{a}` |
| `s ∩ t` (intersection) | `s x ∧ t x` | `∩` |
| `s ∪ t` (union) | `s x ∨ t x` | `∪` |
| `sᶜ` (complement) | `¬ s x` | `ᶜ` |
| `s \ t` (difference) | `s x ∧ ¬ t x` | `\` |
| `s ⊆ t` (subset) | `∀ x, s x → t x` | `⊆` |
| `s ⊇ t` (superset) | `∀ x, t x → s x`, i.e. `t ⊆ s` | `⊇` |
| `s ⊂ t` (strict subset) | `(∀ x, s x → t x) ∧ s ≠ t` | `⊂` |
| `s ⊃ t` (strict superset) | `(∀ x, t x → s x) ∧ s ≠ t` | `⊃` |
| `s = t` (equality) | `∀ x, s x ↔ t x` | `=` |
| `s ×ˢ t` (product) | `fun (a, b) => s a ∧ t b` | `×ˢ` |
| `𝒫 s` (powerset) | `fun x => x ⊆ s` | `𝒫` |

Read `s ⊆ t` aloud: "for every `x`, if `x` belongs to `s` then `x` belongs to `t`."
`s ∩ t = s ∪ t` would mean that for every `x`, `x ∈ s ∧ x ∈ t` iff
`x ∈ s ∨ x ∈ t`. An element that belongs to exactly one of the two sets
refutes that equality.

The last two rows change what kind of thing the elements are. `s ×ˢ t : Set (α × β)`
is a membership predicate on *pairs*: `(a, b)` belongs iff `a` belongs to `s` and `b`
belongs to `t`. `𝒫 s : Set (Set α)` is a membership predicate on *sets*: `x` (itself a
`Set α`) belongs to `𝒫 s` iff `x ⊆ s`. Both are still just functions to `Prop` — only
the input type changed, from `α` to `α × β` or to `Set α`.

Notice the pattern: **every set statement reduces to a statement about propositions,
quantified over elements.** When you prove something about sets, you are doing
propositional logic with `∀` threading through.
```lean
-- Intersection is ∧:
theorem mem_inter_iff (x : α) (s t : Set α) :
    x ∈ s ∩ t ↔ x ∈ s ∧ x ∈ t :=
  Set.mem_inter_iff x s t
```

> **Checkpoint — intersection `∩`.** By `mem_inter_iff`, `x ∈ s ∩ t` means `x ∈ s ∧ x ∈ t`.
> **Predict** whether `3` is in *both* sets below, then check.
```lean
#eval decide ((3 : Nat) ∈ (({1, 2, 3} ∩ {3, 4, 5}) : Set Nat))   -- predict first

-- Union is ∨:
theorem mem_union_iff (x : α) (s t : Set α) :
    x ∈ s ∪ t ↔ x ∈ s ∨ x ∈ t :=
  Set.mem_union x s t
```

> **Checkpoint — union `∪`.** By `mem_union_iff`, `x ∈ s ∪ t` means `x ∈ s ∨ x ∈ t`.
> **Predict** whether `1` is in *either* set below, then check.
```lean
#eval decide ((1 : Nat) ∈ (({1, 2, 3} ∪ {3, 4, 5}) : Set Nat))   -- predict first

-- Subset is ∀/→:
theorem subset_def (s t : Set α) :
    s ⊆ t ↔ ∀ x, x ∈ s → x ∈ t :=
  Iff.intro (fun h _x hx => h hx) (fun h x hx => h x hx)
```

> **Checkpoint — subset `⊆`.** By `subset_def`, `s ⊆ t` is `∀ x, x ∈ s → x ∈ t` — one
> implication *per element*. Here Lean can decide an individual implication at a concrete
> `Nat`. **Predict** that implication at `x = 2` (is `2 ∈ {1,2} → 2 ∈ {1,2,3}` true?), then
> check.
```lean
#eval decide ((2 : Nat) ∈ ({1, 2} : Set Nat) → (2 : Nat) ∈ ({1, 2, 3} : Set Nat))   -- predict first

-- Complement is ¬:
theorem mem_compl_iff (x : α) (s : Set α) :
    x ∈ sᶜ ↔ ¬ x ∈ s :=
  Set.mem_compl_iff s x
```

> **Checkpoint — complement `ᶜ`.** By `mem_compl_iff`, `x ∈ sᶜ` means `¬ (x ∈ s)`.
> **Predict** whether `5`, which is not listed, belongs to the complement below, then check.
```lean
#eval decide ((5 : Nat) ∈ (({1, 2, 3} : Set Nat)ᶜ))   -- predict first

-- Difference is ∧ ¬:
theorem mem_diff_iff (x : α) (s t : Set α) :
    x ∈ s \ t ↔ x ∈ s ∧ ¬ x ∈ t :=
  Set.mem_sdiff x
```

> **Checkpoint — difference `\`.** By `mem_diff_iff`, `x ∈ s \ t` means `x ∈ s ∧ ¬ (x ∈ t)`.
> **Predict** whether `1` survives removing `{3, 4}` from `{1, 2, 3}`, then check.
```lean
#eval decide ((1 : Nat) ∈ (({1, 2, 3} \ {3, 4}) : Set Nat))   -- predict first
```

### Beyond the core five

`⊇`, `⊂`, `⊃` are `⊆` flipped or sharpened with `≠`; `=` is the finest-grained way
to compare two sets — each of these four is a `Prop`-valued predicate on a *pair* of
sets, not itself a new set. `×ˢ` and `𝒫`, by contrast, each build a new membership
predicate whose elements are pairs or sets, rather than elements of `α`.
```lean
example (s t : Set α) : s ⊇ t ↔ t ⊆ s := Iff.rfl

example (s t : Set α) : s ⊂ t ↔ s ⊆ t ∧ s ≠ t :=
  Set.ssubset_iff_subset_ne

example (s t : Set α) : s = t ↔ ∀ x, x ∈ s ↔ x ∈ t :=
  Set.ext_iff

-- Product: pairs whose first component is in s and second is in t
example (s : Set α) (t : Set β) (p : α × β) :
    p ∈ s ×ˢ t ↔ p.1 ∈ s ∧ p.2 ∈ t :=
  Set.mem_prod

-- Powerset: the set of all subsets of s — its elements are themselves sets
example (s x : Set α) : x ∈ 𝒫 s ↔ x ⊆ s :=
  Set.mem_powerset_iff x s
```

## Set algebraic laws as propositions

These laws are propositions that hold for all sets.  The proofs are
provided as term-mode proofs.
```lean
-- Commutativity:
theorem inter_comm (s t : Set α) : s ∩ t = t ∩ s :=
  Set.inter_comm s t

theorem union_comm (s t : Set α) : s ∪ t = t ∪ s :=
  Set.union_comm s t
```

> **Checkpoint — `∩` commutativity.** `inter_comm` says `s ∩ t = t ∩ s`, so membership
> must agree on either side. **Predict** the Boolean (an `↔` of memberships at `x = 2`),
> then check.
```lean
#eval decide ((2 : Nat) ∈ (({1, 2, 3} ∩ {2, 3, 4}) : Set Nat) ↔ (2 : Nat) ∈ (({2, 3, 4} ∩ {1, 2, 3}) : Set Nat))   -- predict first

-- Distributivity:
theorem inter_union_distrib (r s t : Set α) :
    r ∩ (s ∪ t) = (r ∩ s) ∪ (r ∩ t) :=
  Set.inter_union_distrib_left r s t
```

> **Checkpoint — `∩`/`∪` distributivity.** `r ∩ (s ∪ t) = (r ∩ s) ∪ (r ∩ t)`. **Predict**
> the membership `↔` below at `x = 2`, then check.
```lean
#eval decide ((2 : Nat) ∈ (({1, 2} ∩ ({2, 3} ∪ {4, 5})) : Set Nat) ↔ (2 : Nat) ∈ ((({1, 2} ∩ {2, 3}) ∪ ({1, 2} ∩ {4, 5})) : Set Nat))   -- predict first

-- De Morgan:
theorem compl_union (s t : Set α) : (s ∪ t)ᶜ = sᶜ ∩ tᶜ :=
  Set.compl_union s t
```

> **Checkpoint — De Morgan.** `(s ∪ t)ᶜ = sᶜ ∩ tᶜ`: being outside the union means
> being outside both sets.
> **Predict** the membership `↔` at `x = 5` (in neither `{1,2}` nor `{3,4}`), then check.
```lean
#eval decide ((5 : Nat) ∈ ((({1, 2} ∪ {3, 4}) : Set Nat)ᶜ) ↔ (5 : Nat) ∈ ((({1, 2} : Set Nat)ᶜ ∩ ({3, 4} : Set Nat)ᶜ)))   -- predict first

-- Subset is transitive:
theorem subset_trans {s t u : Set α} (h1 : s ⊆ t) (h2 : t ⊆ u) : s ⊆ u :=
  Set.Subset.trans h1 h2
```

## Properties of sets

A *property* is represented the same way everything else in this chapter
is: as a predicate. The only new wrinkle is the subject. Earlier predicates
took an element `x : α` as subject; a property of sets takes a *set* as
subject — and since a set already *is* its membership predicate, a property
of sets is a predicate whose subject is a membership predicate:

```lean
Set α → Prop   -- unfolds to (α → Prop) → Prop
```

You met one already: `𝒫 s : Set (Set α)` unfolds, via
`Set (Set α) := Set α → Prop`, to exactly this shape — the property
`fun x => x ⊆ s`, tested one membership predicate `x` at a time.

Here is a property built the same way the chapter's very first examples
were: applied to a set that has it, and to one that doesn't.
```lean
def SetNonempty (s : Set α) : Prop := ∃ x, s x
```

`SetNonempty` is a predicate whose subject is a membership predicate `s`.
`Small` (from the opening example) has an element, `3`, so it has the
property — witnessed directly. `∅`'s membership predicate is `fun _ => False`,
so nothing can witness it: the negation is proved just as directly, by
taking apart the assumed witness and handing back the `False` already
inside it.
```lean
example : SetNonempty Small := ⟨3, Or.inl rfl⟩

example : ¬ SetNonempty (∅ : Set Nat) := fun ⟨_, hx⟩ => hx
```

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

```lean
end E17
```


<div class="issue-box">📝 <a href="https://github.com/kevinsullivan/Lean4CS1/issues/new">Report an issue</a> with this section</div>

