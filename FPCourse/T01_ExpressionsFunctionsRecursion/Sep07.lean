-- Plan: cover W00 through W02 today W03 on Wed
-- Start by showing exploring the actual type definitions
-- Show corresponding elim rules as function examples


#check Empty     -- Empty : Type
#check False     -- False : Prop

#check Unit      -- Unit : Type
#check True      -- True : Prop
#check true      -- true : Bool

example : Nat := 3
-- Nat is type, not prop, 3 is inhabitant of Nat
example: True := True.intro
-- True.intro : True
-- True : Prop
-- Prop's inhabitant is proof
-- Prop : Type
-- 2=2 : Prop
-- True, 2=2 is inhabitant of proof
example : Unit := Unit.unit

#check Bool      -- Bool : Type

namespace hidden

inductive Bool : Type where -- definition of Bool
  | false : Bool
  | true : Bool
  | wabby : Bool

def b2s (b : Bool) : String :=
  match b with
    | Bool.true => "It's true"
    | Bool.false => "It's false"
    | Bool.wabby => "It's wabby"

end hidden

namespace hidden

inductive Dog : Type where
  | zmy : Dog

end hidden

#check Option Bool   -- Option Bool : Type
#check Nat       -- Nat : Type

namespace hidden

inductive Nat : Type where
  | Zero
  | Succ (n : Nat) : Nat

open hidden.Nat

def zero : Nat := Nat.Zero
def one := Nat.Succ zero
def two := Nat.Succ (Nat.Succ zero)

def funk (n : Nat) : String :=
match n with
  | Nat.Zero => ""
  | Nat.Succ n' => "!" ++ funk n'

#eval funk two

end hidden

#check Prod
-- Prod.{u, v} (α : Type u) (β : Type v) : Type (max u v)

#check Sum
-- Sum.{u, v} (α : Type u) (β : Type v) : Type (max u v)


-- Ch 2. Option type used not defined
-- Ad hoc polymorphism (vs. parametric)

-- Ch 3 (types & values) instance not defined
-- What does a full library for a type include
-- Type def with intro rules (ctors)
