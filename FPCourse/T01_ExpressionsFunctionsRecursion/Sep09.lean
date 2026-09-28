/- @@@
# In-Class Plan

The plan for today is to continue to learn about and practice with
inductive type definitions. For today, pair up with a study buddy:
someone to work and chat with today.
@@@ -/


/- @@@
## Computational types and Logical types

- Empty and False
- Unit(void) and True
- Polymorphic types
- ⬆ This is list of type (ex: list of bool, list of prop, even list of type)
- Sum (⊕) and Or (∨)
-- ⬆ Sum (Polymorephic Computational type) Or (Logic type)
-- ⬆ Proof A OR B
- Prod (×) and And (∧)
-- ⬆ Prod Nat String = Nat x String,
-- ⬆ Proof A AND B
- _ → Empty and Not (¬)
@@@ -/

/- @@@
## Parametric Polymorphism

Suppose you've defined some type, α, and now you wish
to define the identity function on values of this type.
Here's what that looks like with α = Nat, α = Bool, and
α = List Nat. It even works for the Empty type.
@@@ -/

-- identity function, same type to same type
def id_Empty   : Empty    → Empty    := fun n => n
def id_Bool    : Bool     → Bool     := fun n => n
def id_Nat     : Nat      → Nat      := fun n => n
def id_ListNat : List Nat → List Nat := fun n => n

#eval id_Nat 5 --return 5

/- @@@
It should be obvious that every implementation is exactly
the same *except* for the single type of value it consumes
and returns.


## Factor Into Fixed Template with Variable Parameters

In such cases we can refactor these programs into a single
parameterized definition, with a fixed template capturing
the commonalities, and parameters that can be set to any
value to express the variability. This is what looks like.
@@@ -/

-- Sort
def id' (α : Sort u) : α → α
  := fun n => n

#eval id' Nat 3
#eval id' Bool true
#eval id' (List Nat) [1, 2, 3]

#check Nat.add
#check Nat.add 3

def myAdd := Nat.add
#eval myAdd 3 4
#check myAdd

def add3 := Nat.add 3
#eval add3 7
#check add3

def sum := Nat.add 3 4
#check sum

def add33 : Nat → Nat → Nat → Nat := fun a b c => a + b + c
#eval add33 1 2 3

def f' (b1 b2 b3 : Bool) : Bool := true
#eval (f' true true true)

-- demo of function application!! It is left-associative so from 0 to 01 to 0123
-- (((f'' 0) 1) 2)
-- f'' : Nat → (Nat → (Nat → Nat))
-- → is right-associative
def f'' (b1 b2 b3 : Nat) : Nat := 0
#eval (f'' 1 2 3)
#check (f'' 0)
#eval (f'' 0)
#check ((f'' 0) 1)
#eval ((f'' 0) 1)
#check (((f'' 0) 1) 2)
#eval (((f'' 0) 1) 2)

/-@@@
the first parameter. The type checker enforces
this rule. Try it. This is an example of what
we've called *dependent typing.* The *value* of
α (a type), determines the *type* of the second
argument.

Q: What does that say, in principle, about the
need to give the first argument explicitly?

def id' (α : Sort u) : α → α
  := fun n => n

@@@ -/

#eval id' _ 3        -- 3
#eval id' _ true     -- true
#eval id' _ [1,2,3]  -- [1, 2, 3]


/- @@@
## Implicit Arguments for Better Readability

Lean syntax allows for even further cleanup in
the form of what Lean calls *implicit arguments*.
Curly braces around a parameter declaration tells
Lean to infer it, allowing the user not to write
anything at all.
@@@ -/

def id'' {α : Sort u} : α → α := fun n => n

#eval id'' 3        -- 3
#eval id'' true     -- true
#eval id'' [1,2,3]  -- [1, 2, 3]

/- @@@
## Providing Explicit Arguments When Necessary

You may *also* provide an implicit parameter
explicitly. If Lean can't infer an implicit
argument and you must give it explicitly you
can turn off *implicitness* locally using @.
@@@ -/

-- will not work
#eval id'' Nat 3

#eval @id'' Nat 3

/- @@@
Lean's standard library includes the polymorphic
identity function for you. It's called `id`. Let's
look at its type and a few applications.
@@@ -/

#check id''      -- C-style and explicit args
#check (id'')    -- ~ notation and meta-variables
#check @id''     -- C-style and explicit args
#check (@id'')   -- ~ notation, explicit args (my fav)

/- @@@
## Parametricity

Parametric polymorphism depends on the implementation
*not* relying on any knowledge at all of its actual
argument type. Polymorphic functions must handle their
arguments as entirely *opaque*. You cannot switch on
a value of a polymorphic type argument. Interestingly
polymorphic functions sometimes have a single unique
implementation, one that's literally forced. How else
can you explain this function definition except with
"there is no other choice"
@@@ -/

def id''' {α : Sort u} (a : α) : α := a
def id'''1 {α : Sort u} [ImpplementsPlus α] (a : α) : α := a
