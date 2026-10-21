/- @@@
# Typeclasses: A Language of Arithmetic

Suppose we didn't have a even a Nat type or any
of its operations, such as *add* or *multiply*,
not to mention its notations, such as \* or +.

In this section, we'll revisit the strategy of
*deep* embedding of a language, here of natural
number arithmetic, into Lean, and we will meet
for the first time the very important mechanism
call *typeclasses*.

Typeclasses and their instances, first introduced
in Haskell, support not only operator overloading,
in the usual sense, but also *type guards*, which
allow for the definitions of functions *taking any
type, but only if there's a typeclass instance for
that type, providing additional data, such as how
to perform the operation of *that particular type*
of arguments.

We'll illustrate these ideas concretely here with
the beginnings of a Lean-like library of natural
number arithmentic. We'll start at the beginning
by defining our own type `KNat`, a set of ordinary
arithmetic operations (increment, add, multiply,
and exponentiation to start with), and typeclass
instances (the classes thenselves being defined
in Lean libraries) both to overload these widely
overloaded operations (add, etc.) and also showing
how to use such instances as *type guards* when
definition polymorphic functions.
@@@ -/


/- @@@
## KNat: A natural number semantic domain

A formal language usually has a:
- *syntactic specification*, defining the universe of legal terms (sentences, formulae) in the language;
- *semantic domain*, defining a universe of values in which the meanings of syntax terms are defined;
- *semantics* defining the semantic *meaning* or *denotation* of each possible *syntactic* term.

One of the sub-languages, as it were, of any
general-purpose software language will be a language
of arithmetic. Here terms are arithmetic expressions,
such as `X + 1`, where `X` is an arithmetic *variable*,
and the meanings of such terms, under interpretations
of their variables* are natural numbers. Evaluating
`X + 1` under an interpretation that assigns the
value, 4, to `X`, would be 5, for example.

Let's proceed and see the rest as we go.
@@@ -/

/- @@@
It's always good form to enclose your work in some
namespace, to ensure that your definitions to conflict
with those already in scope from automatically imported
Lean libraries.
@@@ -/
namespace KNat

/- @@@
### KNat type

Our `KNat` (from scratch) type just mimics Nat.
@@@ -/

inductive KNat where
| zero
| succ (n : KNat)


/- @@@
### Special Values

The `KNat` type provides not only the visible
constructors but also a recursor that enables
definitions of total functions from this type.
As a start, we can bind mnemonic identifiers
to special values of type type, which include
terms representing zero (`KNat.zero`) and one
(`KNat.succ KNat.zero`).
@@@ -/

def kzero := KNat.zero
def kone := KNat.succ kzero
def ktwo := KNat.succ kone
def kthree := KNat.succ ktwo


/- @@@
### Operations

We implement arithmetic operations on our
custom representation of natural numbers as
total functions in Lean. Total functions are
ultimately supported by the basic induction
principle for the `KNat` type. But applying
these functions directly is something almost
no one would do, as Lean provides supportive
notations. You'd thus see definitions such
as those that follow here. Look for the step
functions when you study this material (hint:
as defined in non-base cases).

@@@ -/

-- Increment: no need to destructure argument
def inc (n: KNat) := n.succ   -- Notation for KNat.succ n

-- Decrement: must destructure (pattern match) argument
-- So the argument must be to the right of the colon
def dec : KNat → KNat
| KNat.zero => kzero          -- decrement zero is zero (truncation)
| KNat.succ n' => n'          -- decrement *one more than any n'* is n'

-- Convert to Nat, for readable test output
def toNat : KNat → Nat
| KNat.zero => 0
| KNat.succ n' => toNat n' + 1

/- @@@
Recursive Arithmetic Functions
@@@ -/

/- @@@
We start on the recursive functions with
addition implemented, by case analysis on
its second argument and use of induction.
If the second argument is zero, we return
the first argument. If it's one more than
`n'` we return the successor of the sum of
the first argument and n'. This maneuver just
rewrites `a +  (b + 1)` as `1 + (a + b)` and
then evaluates `a + b` by recursion. At the
end of the day, the add function increments
the first argument `a`, `b` times for any `b`.
@@@ -/
def add : KNat → KNat → KNat                -- Addition function
  | a, KNat.zero   => a
  | a, KNat.succ b => inc (add a b)

/- @@@
Whereas addition is interated incrementing,
multiplication is iterated addition. To get
`a * b` just add `a` to itself `b` *times*.
Adding `a` to itself zero times is defined
to be zero, which is exactly what is needed
to make our library faithful to the actual
math.
@@@ -/
def mul : KNat → KNat → KNat
| _a, KNat.zero => KNat.zero
| a, KNat.succ b => add a (mul a b)

/- @@@
Exponentiation is iterated multiplication in
just the same way. `a ^ b` is `a` *multiplied*
by itself `b` times.
@@@ -/
def exp : KNat → KNat → KNat
| _, KNat.zero => kone      -- kone is defined above
| a, KNat.succ b' =>  mul (exp a b') a

/- @@@
EXERCISE: define the tetration, call it `tet`.
Lean has no special notation for it. What it
does have is a way to take advantage of the
pattern you're seeing here. Call the `identity`
funciton the 0th hyperoperation, increment the
1st hyperop, add the 2nd, multiplication, the
3rd, and tetration the fourth. First write `tet`
following the pattern above. Second, harder,
see if you can define `hyperop`, taking three
arguments, the first being the `hyper-depth`,
in which case `tet a b` is `hyperop 4 a b`.
@@@ -/

-- Tetration: iterated exponentiation. a↑↑0 = 1, a↑↑(b+1) = a ^ (a↑↑b)
def tet : KNat → KNat → KNat
| _, KNat.zero    => kone
| a, KNat.succ b' => exp a (tet a b')

-- Hyperoperation tower, numbered as in Mathlib:
-- level 0 = successor, 1 = add, 2 = mul, 3 = exp, 4 = tet, ...
-- Base cases differ by level (a + 0 = a, a * 0 = 0, a ^ 0 = 1 and above);
-- the step is uniform: level n+1 at (k+1) = level n applied to m and (level n+1 at k).
def hyperop : Nat → KNat → KNat → KNat
| 0,     _, k           => inc k
| 1,     m, KNat.zero   => m
| 2,     _, KNat.zero   => KNat.zero
| _ + 3, _, KNat.zero   => kone
| n + 1, m, KNat.succ k => hyperop n m (hyperop (n + 1) m k)

#eval toNat (tet ktwo ktwo)           -- 4
#eval toNat (tet ktwo kthree)         -- 16
#eval toNat (hyperop 1 ktwo kthree)   -- 5
#eval toNat (hyperop 2 ktwo kthree)   -- 6
#eval toNat (hyperop 3 ktwo kthree)   -- 8
#eval toNat (hyperop 4 ktwo ktwo)     -- 4, same as tet ktwo ktwo

-- Truncated subtraction: same shape as add, stepping with dec instead of inc
def sub : KNat → KNat → KNat
| a, KNat.zero   => a
| a, KNat.succ b => dec (sub a b)

-- Unary negation: naturals have no negatives, so negation truncates to zero,
-- consistent with truncated subtraction.
def neg : KNat → KNat
| _ => KNat.zero

/- @@@
### Classes
@@@ -/

/- @@@
Here's the `Zero` typeclass in Lean. An
instance associates a value, given by the
value of the field, `Add.zero`, with any
type given by `α`. We will necxt create an
instance of this class *for the KNat type*,
to define what we mean by zero for *KNat*.
```lean
class Zero (α : Type u) where
  zero : α
```
@@@ -/
instance : Zero KNat where
zero := KNat.zero

-- Among other things, `0` is now notation
#check (0 : KNat)

instance : One KNat where
one := kone
#check (1 : KNat)

instance : Add KNat where
  add := KNat.add      -- class field name on left, add function on right

instance : Mul KNat where
mul := mul

instance : Pow KNat KNat where
pow := exp

instance : Sub KNat where
  sub := sub

instance : Neg KNat where
  neg := neg

#eval (1 + 1 : KNat)
#eval ktwo * kthree
#eval ktwo ^ kthree

/- @@@
Not only do we get these notations, but
they also come (thank you Lean library)
with the right associativity, precedence,
etc.
@@@ -/

#eval ktwo *  ktwo + ktwo    -- six
#eval ktwo * (ktwo + ktwo)   -- eight!
#eval ktwo +  ktwo * ktwo    -- six
#eval ktwo + (ktwo * ktwo)   -- six

-- Subtraction and negation get the usual precedence and associativity too
#eval toNat (kthree - kone - kone)   -- (3 - 1) - 1 = 1      (left associative)
#eval toNat (kthree - kone * ktwo)   -- 3 - (1 * 2) = 1      (* before -)
#eval toNat (-ktwo + kthree)         -- (-2) + 3 = 0 + 3 = 3 (unary minus first; truncated)
#eval toNat (ktwo ^ kthree - kone)   -- (2 ^ 3) - 1 = 7      (^ before -)
#eval toNat (kone - kthree)          -- 0                    (truncation)

/- @@@

@@@ -/


def addAnyTypeAsLongItsAddable {α : Type} [Add α] : α → α → α
| a, b => a + b

-- add for Nat, Add Nat instance provided by library
#eval addAnyTypeAsLongItsAddable 3 4

-- add for rationals (instance defined in Lean library)
#eval (3/4: Rat) + 1/2

-- add for String? NOPE, no instance in library
-- #eval addAnyTypeAsLongItsAddable "Hi" "There"

-- -- add for KNat
#eval addAnyTypeAsLongItsAddable (1 : KNat) 1

/- @@@
EXERCISES

1. Extend KNat algebra with operations for
unary Negation and Subtraction, and instances
to provide notations and more. Use your search
engine or agent to find the names of the right
classes in Lean's libraries for these operations.

2. Replace Nat with KNat in the following
definition of the syntax and semantics of
our little language of arithmetic. Extend
the language to support the subtraction and
negation operations you've just defined.

3. Extend your language of arithmetic with
*variable* expressions, so you can write not
just, say, two plus three, but X plus 3. See
how we handled propositional variables in our
formalization of propositional logic and use
the same pattern here.

4. Provide a few examples similar to those
above, testing and showing that expressions
using subtraction, negation, and variables
work with usual precedence and associativity.
@@@ -/

end KNat


namespace Arith
open KNat

/- @@@
## Syntax
@@@ -/

inductive Variable where
| X
| Y
| Z
open Variable

inductive Expr where
| lit (n : KNat) : Expr
| add (e1 e2 : Expr) : Expr
| sub (e1 e2 : Expr) : Expr
| neg (e : Expr) : Expr
| var (v : Variable) : Expr
open Expr


/-@@@
## Operational Semantics
@@@ -/

-- An interpretation assigns a value to each variable
def Interp : Type := Variable → KNat

def arithEval : Expr → Interp → KNat
| Expr.lit n, _ => n
| Expr.add e1 e2, i => KNat.add (arithEval e1 i) (arithEval e2 i)
| Expr.sub e1 e2, i => KNat.sub (arithEval e1 i) (arithEval e2 i)
| Expr.neg e, i => KNat.neg (arithEval e i)
| Expr.var v, i => i v


/- @@@
## Examples
@@@ -/
-- two interpretations
def i1 : Interp := fun v => match v with
  | X => ktwo
  | Y => kone
  | Z => kzero

def i2 : Interp := fun v => match v with
  | X => kthree + kthree
  | Y => kthree
  | Z => kone

-- example expressions using our syntax
def e1 : Expr := lit kone
def e3 : Expr := lit kthree
def e4 : Expr :=   -- 3 + (2 + 1)
  add
    (lit kthree)
    (add
      (lit ktwo)
      (lit kone)
    )
def e5 : Expr := sub (var X) (var Y)                           -- X - Y
def e6 : Expr := neg (var Z)                                   -- -Z
def e7 : Expr := sub (lit kthree) (sub (lit kone) (lit kone))  -- 3 - (1 - 1)
def e8 : Expr := add (var X) (lit kthree)                      -- X + 3

#eval toNat (arithEval e4 i1)   -- 6
#eval toNat (arithEval e5 i1)   -- 1   (X = 2, Y = 1)
#eval toNat (arithEval e5 i2)   -- 3   (X = 6, Y = 3)
#eval toNat (arithEval e6 i1)   -- 0   (negation truncates)
#eval toNat (arithEval e7 i1)   -- 3   (tree structure is the grouping)
#eval toNat (arithEval e8 i1)   -- 5
#eval toNat (arithEval e8 i2)   -- 9



end Arith
