-- Plan: cover W00 through W02 today W03 on Wed
-- Start by showing exploring the actual type definitions
-- Show corresponding elim rules as function examples

#check Empty
#check False

#check Unit
#check True

example : Nat := 3
example : True := True.intro
example : Unit := Unit.unit

#check Bool

namespace hidden

inductive Bool : Type where
  | false : Bool
  | true : Bool

def b2s (b : Bool) : String :=
  match b with
  | Bool.true => "It's true"
  | Bool.false => "It's false"

end hidden

#check Option Bool

#check Nat
namespace hidden
inductive Nat : Type where
| zero : Nat
| succ (n : Nat) : Nat

open hidden.Nat

def zero : Nat := Nat.zero
def one := Nat.succ zero
def two := Nat.succ (Nat.succ Nat.zero)
def two' := Nat.succ one
def three := Nat.succ two

def NatToTally (n : Nat) : String :=
match n with
| Nat.zero => ""
| Nat.succ n' => "|" ++ NatToTally n'

#eval NatToTally three
end hidden

#check Prod
#check Sum

-- Ch 2. Option type used not defined
-- Ad hoc polymorphism (vs. parametric)

-- Ch 3 (types & values) instance not defined
-- What does a full library for a type include
-- type def with intro rules (ctors)
-- elim rules (functions)
-- notation definitions
-- often additions defs/theorems
-- tactics

-- Explain parametric polymorphism

-- `_h` is never used in the body (in general can be
-- you'd get a warning, silenced by the _ in front of h

def nan : Float := 0.0 / 0.0
#eval decide (nan == nan)   -- !!!

-- Chapter 3, Functions

-- concept of currying, and example add3
-- emphasize beta reduction by substitution of actuals for formals

-- Note: some examples do take/require prooofs

-- Function composition. Read (g ∘ f) as "g after f"
-- Note implicit type parameters. I don't recommend.
-- Note use of polymorphic identity funciton, id (type inference)
-- THEN: write comp3, taking any function and returning it composed wit itself 3 times

def comp3 {α : Type} (f : α → α) := f ∘ f ∘ f
#eval ((comp3 Nat.succ) 0)
#eval ((comp3 (fun n => n * 2)) 5)

-- Explain (· + 1) notation
-- Work A ⊕ B → B ⊕ A
-- Cover safe list to elt

-- #eval decide (∀ n : Nat, n + 0 = n)
