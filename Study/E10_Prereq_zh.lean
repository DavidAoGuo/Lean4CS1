/- @@@
# E10 前置知识（中文详解）

- **讲解对象**：读 `FPCourse/ClassNotes/E10_Arith.lean` 之前需要、而 L00 没有覆盖的
  三块前置知识。不是某一份源文件的逐行详解。
- **取材来源**：`FPCourse/ClassNotes/E10_Arith.lean`、`E09_induction.lean`、
  `E02_PropLogic.lean`、`FPCourse/T05_AbstractTypesAndTypeClasses/W12_TypeClassesDecidable.lean`
- **基于 upstream commit**：`ec7a8f5`（2026-10-20）
- **写作日期**：2026-10-21
- **前置**：`Study/L00_Syntax_zh.lean`（全部）。本文档引用它时写「L00 §x.y」，
  L00 讲过的语法不重讲。
- **编译**：本文件不 `import` 任何东西，在容器内仓库根目录执行
  `lean Study/E10_Prereq_zh.lean`。
- **生成预览**：`python3 scripts/convert.py Study/E10_Prereq_zh.lean Study/E10_Prereq_zh.md`

---

# 1. 导读

## 1.1 为什么需要这一份

L00 把 E00 到 E08 用到的语法拆完了。E10 却在三个地方跳出了 L00 的范围：

1. **递归函数**。L00 §4.2 讲过「构造子的字段类型可以是正在定义的那个类型」，
   也在 §5.3 里顺手用了一次递归调用。但它没讲**怎么系统地在递归类型上写函数**，
   更没讲为什么 Lean 有时会拒绝你的递归定义。E10 的 `add`、`mul`、`exp`
   全是这种函数，而且它们之间有一个必须看出来的共同形状。
2. **typeclass**。L00 只在 §11.1 提过一句方括号 `[Decidable p]` 是实例隐式参数。
   E10 的后半截全是 `class` 和 `instance`：`0`、`1`、`+`、`*`、`^`
   这些写法凭什么能用在一个刚造出来的类型上。
3. **把一门语言嵌进 Lean**。L00 §5.3 为了讲模式匹配，把 E02 的命题逻辑语法
   抄过去用了，但没讲那三个定义**为什么要这么分**。E10 末尾的 `Arith`
   命名空间是同一套做法的第二个例子，老师的作业题也是让你补这套做法。

这份文档只做这三件事，按上面的顺序。每一块都先讲概念，再逐行拆代码。

## 1.2 读完之后应该能做什么

- 看到一个递归的 `inductive`，能说出在它上面写函数要写几个分支、
  哪个分支里会出现递归调用、递归调用的参数必须是什么。
- 看到 `instance : C T where f := g`，能说出 `C` 是什么、`f` 是哪来的名字、
  `g` 要是什么类型；看到 `failed to synthesize` 能说出缺的是哪个实例。
- 看到一门小语言的三个定义，能指出哪个是语法、哪个是语义域、哪个是语义，
  并且能照着给语言加一个新构造子。

## 1.3 目录

| 节 | 内容 |
|---|---|
| 1 | 导读 |
| 2 | 第一块：递归 `inductive` 上的结构递归；迭代视角；`Nat.rec` |
| 3 | 第二块：typeclass —— `class`、`instance`、记法解析、type guard、数字字面量 |
| 4 | 第三块：深嵌入三件套 —— 语法、语义域、语义；变量与解释 |
| 5 | 速查表 |
| 6 | 术语表 |

## 1.4 本文档不写什么

老师在 E10 里布置了作业：`tet`、`hyperop`、以及末尾 `EXERCISES` 的四道题
（减法与负号的运算和实例、把 `Nat` 换成 `KNat`、给算术语言加变量、再补几个例子）。
按 `Study/README.md` 第 4 节的规定，这份文档**不碰** `KNat`，
不定义 `tet` 或 `hyperop`，不写 `Sub` 或 `Neg` 的实例，也不写算术语言。

所以第 2 节的四层只用库里的 `Nat` 演示，第 3 节的实例写在一个
和算术无关的二维向量类型上，第 4 节的小语言是字符串拼接语言。
每节末尾的练习都是**变式题**：和作业用的是同一套概念，但换了类型、换了方向，
做完它们不会顺手得到任何一道作业题的答案。
@@@ -/

/- @@@
---

# 2. 第一块：递归 `inductive` 上的结构递归

这一节的全部内容可以压成一句话：

> **递归类型的构造子表长什么样，在它上面写的函数的分支表就长什么样；
> 带递归字段的那个构造子，对应的分支里就会出现递归调用。**

剩下的都是这句话的展开。
@@@ -/

namespace P2

/- @@@
## 2.1 递归类型：构造子表里有「基」也有「步」

L00 §4.2 讲过 `inductive` 的构造子表，也讲过字段类型可以是正在定义的类型本身。
把这两件事放一起看，`Nat` 这类类型的构造子表就有一个固定的两段式结构。

Lean 库里的 `Nat` 定义成这样（这是真实定义，这里只是抄一遍看形状）：

```lean
inductive Nat where
| zero : Nat
| succ (n : Nat) : Nat
```

- `zero` **不带**任何 `Nat` 字段。它是一个**基构造子（base constructor）**：
  不引用自己，所以不需要先有一个 `Nat` 就能用它造出一个 `Nat`。
- `succ` 带一个 `Nat` 字段。它是一个**递归构造子（recursive constructor）**：
  必须先有一个 `Nat`，才能用它造出下一个 `Nat`。

于是 `Nat` 的每一个值都是「从 `zero` 出发，套了若干层 `succ`」：

```text
Nat.zero                          -- 0
Nat.succ Nat.zero                 -- 1
Nat.succ (Nat.succ Nat.zero)      -- 2
```

`#eval` 和 `#check`（L00 §2.1、§2.2）可以直接验证这件事。
注意 Lean 打印 `Nat` 时用的是十进制数字，不是 `succ` 链：
@@@ -/

#check Nat.zero                             -- Nat
#check Nat.succ                             -- Nat → Nat
#eval  Nat.succ (Nat.succ Nat.zero)         -- 2
#eval  (2 : Nat)                            -- 2，和上一行是同一个值
#guard Nat.succ (Nat.succ Nat.zero) = 2     -- 真的是同一个值

/- @@@
`List` 是同一个形状，只是递归构造子多带了一个字段。
库里的定义（抄一遍看形状）：

```lean
inductive List (α : Type u) where
| nil : List α
| cons (head : α) (tail : List α) : List α
```

- `nil` 是基构造子，记法是 `[]`。
- `cons` 是递归构造子：一个 `α` 加上一个更短的 `List α`。记法是 `::`（中缀）。

`(α : Type u)` 是类型参数，写在类型名后面、冒号前面，这是 L00 §4.2
「类型参数：参数化的 inductive」讲过的写法。
@@@ -/

#check @List.nil                            -- {α : Type u_1} → List α
#check @List.cons                           -- {α : Type u_1} → α → List α → List α
#eval  List.cons 7 (List.cons 8 List.nil)   -- [7, 8]
#eval  (7 :: 8 :: [] : List Nat)            -- [7, 8]，同一个值
#guard List.cons 7 (List.cons 8 List.nil) = [7, 8]

/- @@@
**把两个类型并排放**，形状就看出来了：

| | 基构造子 | 递归构造子 | 递归字段 |
|---|---|---|---|
| `Nat` | `zero` | `succ (n : Nat)` | 一个，`n` |
| `List α` | `nil`（`[]`） | `cons (head : α) (tail : List α)`（`::`） | 一个，`tail` |

E10 的 `KNat` 就是照 `Nat` 这张表抄的，构造子名字一样，只是换了类型名。
E02 的 `PropLogicSyntax`（L00 §5.3 抄过）也是这个形状，只是基构造子有两个
（`T`、`F`、`Var`），递归构造子有三个（`And`、`Or`、`Not`），
而且 `And`、`Or` 各带**两个**递归字段。

## 2.2 在递归类型上写函数：基值加步进

现在反过来：手里有一个递归类型的值，要算出一个结果。

L00 §5.2 讲过等式形式的 `def`：左边写模式，右边写结果，一个构造子一个分支。
**穷尽性**要求你为每个构造子都给一个分支。于是：

- 基构造子的那个分支，右边**不能**有递归调用（没有更小的值可以递归），
  必须直接给出一个答案。这个答案叫**基值（base value）**。
- 递归构造子的那个分支，右边**可以**对字段里那个更小的值递归调用，
  再把结果加工一下。这个加工动作叫**步进（step）**。

这就是**结构递归（structural recursion）**。先看最小的例子，
一个把 `Nat` 加倍的函数：
@@@ -/

def myDouble : Nat → Nat
| Nat.zero      => Nat.zero                      -- 基值
| Nat.succ n'   => Nat.succ (Nat.succ (myDouble n'))   -- 步进

#eval myDouble 0        -- 0
#eval myDouble 3        -- 6

/- @@@
**第一层，整体**。类型签名 `Nat → Nat` 读成「接受一个 `Nat`，还你一个 `Nat`」。
参数写在冒号**右边**（而不是像 `def f (n : Nat) : Nat` 那样写在左边），
因为函数体要对这个参数做模式匹配——L00 §5.2 讲过这个要求，
E10 的注释里也专门写了一句 `So the argument must be to the right of the colon`。

**第二层，逐 token**。

| token | 角色 |
|---|---|
| `myDouble` | 被定义的名字；在自己的函数体里出现就是**递归调用** |
| `Nat.zero` （第一个） | 构造子模式，没有字段要绑定 |
| `Nat.zero` （第二个） | 这一支的**结果**，一个 `Nat` 值 |
| `Nat.succ n'` | 构造子模式；要求参数是用 `succ` 造的，并把它的字段绑定到新名字 `n'` |
| `n'` | 变量模式绑定出来的名字。撇号只是命名习惯，表示「比参数小一级的那个」 |
| `myDouble n'` | 递归调用，参数是 `n'`，**不是**原来那个参数 |
| 外面两层 `Nat.succ` | 步进：把递归结果加 2 |

**第三层，对哪个构造子对应哪条规则**。
`match` 的每一支对应「这个值是用哪个构造子造的」这一种可能。
`inductive` 的构造子是这个类型的**引入规则**（L00 §4.2），
而写满所有分支、拿到一个结果，就是这个类型的**消去规则**。
第 2.7 节会把这件事和 `Nat.rec` 对上。

**第四层，迁移**。换成 `List`，形状原样照用，只是构造子名字换掉：
@@@ -/

def myLengthDemo : List Nat → Nat
| List.nil            => 0                         -- 基值
| List.cons _ tail    => 1 + myLengthDemo tail     -- 步进

#eval myLengthDemo []            -- 0
#eval myLengthDemo [7, 8, 9]     -- 3

/- @@@
`_` 是通配符模式（L00 §5.3）：这里的 `head` 字段用不到，所以不给它起名字。
递归调用的参数是 `tail`，也就是递归构造子里那个「更小的 `List`」。

也可以用记法写模式，意思完全一样：
@@@ -/

def myLength' : List Nat → Nat
| []        => 0
| _ :: t    => 1 + myLength' t

#guard myLength' [7, 8, 9] = 3

/- @@@
`Nat` 也有这种记法写法：`0` 当 `Nat.zero` 的模式，`n' + 1` 当 `Nat.succ n'` 的模式。
E09 的 `fac` 就是这么写的：

```lean
def fac : Nat → Nat
| 0 => 1
| (n' + 1) => (n' + 1) * fac n'
```

四种写法（`Nat.zero` / `0`、`Nat.succ n'` / `n' + 1`）互相等价，混着用也行。
E10 写的是 `KNat.zero` 和 `KNat.succ b`，因为 `KNat` 是自己定义的类型，
库里没给它配 `0` 和 `+1` 的模式记法。

## 2.3 对哪个参数递归

函数有两个参数时，「对哪个参数递归」是一个**选择**，而且这个选择决定了整段代码的样子。

E10 的 `add` 选的是第二个参数。先把同样的东西用库里的 `Nat` 写一遍：
@@@ -/

def myAdd : Nat → Nat → Nat
| a, Nat.zero      => a                       -- 基值：第二个参数是 0，答案就是 a
| a, Nat.succ b'   => Nat.succ (myAdd a b')   -- 步进：对第二个参数剥一层，结果加 1

#eval myAdd 2 3     -- 5
#eval myAdd 0 4     -- 4
#eval myAdd 4 0     -- 4

/- @@@
**逐 token 拆第二个分支** `| a, Nat.succ b' => Nat.succ (myAdd a b')`：

- 逗号分隔两个参数的模式，这是 L00 §5.3 的多参数匹配；
- `a` 是变量模式：匹配任何东西，绑定到名字 `a`。**第一个参数从头到尾没被拆过**，
  它在每一层递归里原样传下去；
- `Nat.succ b'` 是构造子模式，只作用在第二个参数上，绑定出 `b'`；
- `=>` 右边 `myAdd a b'`：递归调用，第一个参数**不变**，第二个参数**小一级**；
- 最外面的 `Nat.succ` 是步进。

**怎么判断「对哪个参数递归」**：看递归调用里哪个位置的参数比模式里的小了一级。
这里是第二个位置（`Nat.succ b'` 进去，`b'` 出来），所以是对第二个参数递归。
`#print`（L00 §9.1）可以确认这件事——Lean 编译出来的代码里，
被拿去做递归的是第二个参数：
@@@ -/

#print myAdd
-- def P2.myAdd : Nat → Nat → Nat :=
-- fun x x_1 => Nat.brecOn (motive := fun x => Nat → Nat) x_1 myAdd._f x
--                                                         ↑ 第二个参数

/- @@@
`Nat.brecOn` 是 Lean 为结构递归生成的东西，它是 `Nat.rec` 的一个包装，
第 2.7 节再说。这里只需要看 `x_1`（第二个参数）出现在被消去的位置上。

**换成对第一个参数递归**也能写出加法，只是基值和步进都要跟着换地方：
@@@ -/

def myAdd' : Nat → Nat → Nat
| Nat.zero,     b => b                        -- 基值：第一个参数是 0，答案是 b
| Nat.succ a',  b => Nat.succ (myAdd' a' b)   -- 对第一个参数剥一层

#guard myAdd' 2 3 = 5
#guard myAdd' 2 3 = myAdd 2 3     -- 两个定义算出来一样

/- @@@
两个定义在数值上等价，但它们是**不同的程序**：`myAdd` 剥的是 `b`，`myAdd'` 剥的是 `a`。
以后要证明关于它们的定理时，这个差别会直接决定证明好不好写——
因为归纳法要对被剥的那个参数做。这是 E09 的话题，这里只提一句。

## 2.4 为什么递归调用的参数必须在结构上变小

Lean 里所有函数都必须是**全函数（total function）**：对每一个合法输入都要在有限步内给出结果。
不是「最好是」，是「必须是」。原因有两条：

1. `#eval` 要能停下来。一个死循环的定义没法当程序跑。
2. 更要紧的是**一致性**。在 Lean 里，`theorem` 的证明就是一个 term（L00 §7.1）。
   如果允许写 `def loop : False := loop`，那就凭空造出了一个 `False` 的证明，
   整个逻辑系统就垮了。所以 Lean 必须在接受定义之前确认它会停。

Lean 判断「会停」的第一招叫**结构递归检查**：要求每个递归调用的参数都是
当前参数的一个**真子项（strict subterm）**，也就是从模式匹配里剥出来的那个更小的值。
`myAdd a b'` 里的 `b'` 是从 `Nat.succ b'` 里剥出来的，所以通过。

反过来，下面这个定义**过不去**。`#guard_msgs`（L00 §9.4）把报错钉在源码里，
这样它既是文档也是编译器检查过的事实：
@@@ -/

/--
error: fail to show termination for
  P2.noShrink
with errors
failed to infer structural recursion:
Cannot use parameter #1:
  failed to eliminate recursive application
    noShrink n'.succ


failed to prove termination, possible solutions:
  - Use `have`-expressions to prove the remaining goals
  - Use `termination_by` to specify a different well-founded relation
  - Use `decreasing_by` to specify your own tactic for discharging this kind of goal
n' : Nat
⊢ False
-/
#guard_msgs in
def noShrink : Nat → Nat
| Nat.zero      => 0
| Nat.succ n'   => noShrink (Nat.succ n')   -- 参数没变小，和进来的一样

/- @@@
**报错怎么读**，从后往前：

- `failed to infer structural recursion` / `Cannot use parameter #1`：
  Lean 试过把第 1 个参数当递归参数，不行。
- `failed to eliminate recursive application noShrink n'.succ`：
  具体卡在哪一个递归调用上。`n'.succ` 就是 `Nat.succ n'`（点记法，L00 §12.4）。
  模式里剥出来的是 `n'`，可递归调用传的是 `n'.succ`，比 `n'` 大一级。
- `failed to prove termination`：结构递归这条路断了，Lean 退到第二招
  **良基递归（well-founded recursion）**，要求你证明某个度量在变小。
- 最后两行 `n' : Nat ⊢ False` 是它留给你的目标。`False` 是证不出来的
  （L00 §7.9），这就是在说「这个定义真的不会停，没救」。

**第二个例子**：减一看起来是在变小，但 `n - 1` 不是**结构上**的子项——
它是一次函数调用的结果，不是从构造子里剥出来的。所以结构递归检查也不认：
@@@ -/

/--
error: fail to show termination for
  P2.minusOneLoop
with errors
failed to infer structural recursion:
Cannot use parameter #1:
  failed to eliminate recursive application
    minusOneLoop (n - 1)


failed to prove termination, possible solutions:
  - Use `have`-expressions to prove the remaining goals
  - Use `termination_by` to specify a different well-founded relation
  - Use `decreasing_by` to specify your own tactic for discharging this kind of goal
n : Nat
⊢ n - 1 < n
-/
#guard_msgs in
def minusOneLoop : Nat → Nat
| 0 => 0
| n => minusOneLoop (n - 1)

/- @@@
这次留下的目标是 `n - 1 < n`，不是 `False`。这个目标**在 `n = 0` 时是假的**
（`Nat` 的减法在零处截断，`0 - 1 = 0`，而 `0 < 0` 不成立），
所以它也证不出来。要让 Lean 接受这个定义，得改写成剥构造子的形式：
@@@ -/

def countDown : Nat → Nat
| Nat.zero      => 0
| Nat.succ n'   => countDown n'     -- 剥出来的 n'，通过

#eval countDown 100      -- 0

/- @@@
**走开时带走这一条**：写递归定义时，递归调用的参数要么是模式里剥出来的那个名字
（`n'`、`tail`、`b'`），要么是从它再剥出来的。只要你是在**往模式里剥出来的名字**上递归，
就不会撞上终止性报错。这也是 E10 里 `add`、`mul`、`exp`
三个定义递归调用全部写成 `... a b`（`b` 是剥出来的）的原因。

## 2.5 手工展开：看清计算过程

`#eval` 只给最终答案。要看懂一个递归定义，得会手工展开。
展开的规则只有一条：**把函数应用换成匹配上的那一支的右边，同时把模式里的名字替换成实际值。**

展开 `myAdd 2 3`。先把数字写成 `succ` 链，`2` 是 `s (s z)`，`3` 是 `s (s (s z))`
（这里把 `Nat.succ` 简写成 `s`、`Nat.zero` 简写成 `z`）：

```text
myAdd 2 3
= myAdd 2 (s 2)              -- 第二个参数匹配 `Nat.succ b'`，b' := 2
= s (myAdd 2 2)              -- 用第二支：s (myAdd a b')
= s (myAdd 2 (s 1))          -- 再匹配一次，b' := 1
= s (s (myAdd 2 1))
= s (s (myAdd 2 (s 0)))      -- 再匹配一次，b' := 0
= s (s (s (myAdd 2 0)))
= s (s (s 2))                -- 第二个参数是 0，匹配第一支，答案是 a = 2
= s (s (s (s (s z))))
= 5
```

数一数：`s` 一共套了 **3** 层在 `2` 外面。
这正是 E10 注释里那句话——**加法就是把第一个参数自增第二个参数那么多次**。

`#guard`（L00 §9.3）可以把展开过程中的每一步钉下来，让编译器替你核对：
@@@ -/

#guard myAdd 2 3 = Nat.succ (myAdd 2 2)
#guard myAdd 2 2 = Nat.succ (myAdd 2 1)
#guard myAdd 2 1 = Nat.succ (myAdd 2 0)
#guard myAdd 2 0 = 2
#guard myAdd 2 3 = 5

/- @@@
`List` 上同样展开一遍 `myLengthDemo [7, 8]`：

```text
myLengthDemo [7, 8]
= myLengthDemo (7 :: [8])       -- 匹配 cons，head := 7，tail := [8]
= 1 + myLengthDemo [8]
= 1 + (1 + myLengthDemo [])     -- 再匹配一次
= 1 + (1 + 0)                   -- 匹配 nil，基值 0
= 2
```

注意递归是**先一路剥到基构造子，再一层层往回算**。
`1 +` 那些加号是在「往回」的路上才真正算起来的。
@@@ -/

#guard myLengthDemo [7, 8] = 1 + myLengthDemo [8]
#guard myLengthDemo [8]    = 1 + myLengthDemo ([] : List Nat)
#guard myLengthDemo ([] : List Nat) = 0

/- @@@
## 2.6 迭代视角：把低一级的函数作用 y 次

这一小节是 E10 的核心，也是老师作业题的全部出发点。

回头看 2.5 节那段展开，`myAdd a b` 做的事情是：
**从 `a` 出发，把「加 1」这个动作做 `b` 次**。
写成一句模板：

> 「把**低一级的运算** `g`，从某个**基值**出发，对 `a` 作用 `b` 次。」

同一个模板换不同的 `g` 和不同的基值，就得到不同的运算。先把前两层摆出来。

**第 1 层，后继（successor）**：不递归，直接套一层构造子。
E10 里叫 `inc`，并且注释特意写了 `no need to destructure argument`
——它不需要拆参数，所以参数可以写在冒号左边：
@@@ -/

def myInc (n : Nat) : Nat := Nat.succ n

#eval myInc 4      -- 5

/- @@@
**第 2 层，加法**：把 `myInc` 作用 `b` 次，起点是 `a`。
把 2.3 节的 `myAdd` 重写一遍，让步进函数显式出现：
@@@ -/

def myAdd2 : Nat → Nat → Nat
| a, Nat.zero      => a                      -- 基值：a 本身（作用 0 次）
| a, Nat.succ b'   => myInc (myAdd2 a b')    -- 步进：再作用一次 myInc

#eval myAdd2 2 3      -- 5
#guard myAdd2 2 3 = myAdd 2 3

/- @@@
和 2.3 节的 `myAdd` 比一下，唯一的区别是把 `Nat.succ (...)` 写成了 `myInc (...)`。
它们是同一个函数（`myInc n` 就是 `Nat.succ n`），
但写成 `myInc` 之后，**「步进用的是低一级的运算」**这件事就摆在脸上了。
E10 的 `add` 正是这么写的：`| a, KNat.succ b => inc (add a b)`。

**第 3 层，乘法**：把 `myAdd2` 作用 `b` 次，起点是 `0`。
@@@ -/

def myMul : Nat → Nat → Nat
| _a, Nat.zero     => 0                       -- 基值：0（加 0 次）
| a,  Nat.succ b'  => myAdd2 a (myMul a b')   -- 步进：再加一次 a

#eval myMul 2 3      -- 6
#eval myMul 5 0      -- 0
#eval myMul 0 5      -- 0

/- @@@
`_a` 前面那个下划线是 L00 §5.3 讲的通配符的一个变体：
**名字前加 `_` 表示「我绑定了它但故意不用」**，这样 Lean 不会报
`unused variable` 警告。E10 的 `mul` 第一支就写成 `| _a, KNat.zero => KNat.zero`。
写成纯 `_` 也行；写 `_a` 的好处是读代码的人知道这个位置是第一个加数。

**基值为什么是 `0` 而不是 `a`**？因为「把 `a` 加到自己身上 0 次」的结果是 0。
E10 的注释专门解释了这一句：`Adding a to itself zero times is defined to be zero,
which is exactly what is needed to make our library faithful to the actual math`。
基值选错了，`myMul a 0` 就不等于 0，整个库就和数学不符了。

**第 4 层，乘方**：把 `myMul` 作用 `b` 次，起点是 `1`。
@@@ -/

def myPow : Nat → Nat → Nat
| _a, Nat.zero     => 1                       -- 基值：1（乘 0 次）
| a,  Nat.succ b'  => myMul (myPow a b') a    -- 步进：再乘一次 a

#eval myPow 2 3      -- 8
#eval myPow 2 0      -- 1
#eval myPow 5 1      -- 5
#guard myPow 2 10 = 1024

/- @@@
**四层并排**，这张表是这一节最该背下来的东西：

| 层 | 名字 | 基值（第二个参数为 0 时） | 步进用的运算 | 读法 |
|---|---|---|---|---|
| 1 | `myInc` | ——（不递归） | 构造子 `Nat.succ` | 套一层 `succ` |
| 2 | `myAdd2 a b` | `a` | `myInc` | 把 `myInc` 作用 `b` 次 |
| 3 | `myMul a b` | `0` | `myAdd2 a` | 把「加 `a`」作用 `b` 次 |
| 4 | `myPow a b` | `1` | `myMul · a` | 把「乘 `a`」作用 `b` 次 |

三件事值得单独指出来：

1. **递归的位置完全一样**：三个定义都是对第二个参数递归，
   都是 `| _, zero => 基值` 加 `| a, succ b' => 步进 (f a b')`。
   换层只换两样东西：基值和步进用的那个运算。
2. **基值随层级变化**，而且不是随便定的。它必须等于「该层的步进运算作用 0 次的结果」。
   第 3、4 层的基值正好是那一层步进运算的**单位元（identity element）**：
   `myMul` 的步进是加法，加法的单位元是 `0`；`myPow` 的步进是乘法，乘法的单位元是 `1`。
   第 2 层的基值是 `a` 而不是一个常数，因为那一层的步进（后继）是一元的，
   「作用 0 次」就是原样返回第一个参数。选错基值，整个运算就错了。
3. **步进的参数顺序在第 4 层变了**：`myPow` 写的是 `myMul (myPow a b') a`，
   而 `myMul` 写的是 `myAdd2 a (myMul a b')`。
   因为加法和乘法可交换，`myMul` 那一支写成哪个顺序都对；
   但为了和 E10 的 `exp` 对上（`mul (exp a b') a`），这里保持同一个顺序。
   乘方本身不可交换，所以写乘方的**底数**和**指数**时顺序不能乱。

E10 的 `inc`、`add`、`mul`、`exp` 就是这四层，只是把 `Nat` 换成了 `KNat`。
作业里的 `tet` 和 `hyperop` 是在这张表上往下再走——按 `Study/README.md` 第 4 节，
这份文档到此为止，不替你写第 5 层。

## 2.7 `Nat.rec` 是什么：`match` 最终编译成什么

这是 E09 的要点，这里点到为止，为的是让你读 E10 时知道
「总函数最终由归纳原理支撑」这句注释在说什么。

每个 `inductive` 类型，Lean 都自动生成一个**recursor（递归子）**，名字是
`类型名.rec`。它是「怎么**用**这个类型的一个值」的唯一原理性答案：
你为每个构造子提供一份结果，它还你一个对**任何**该类型值都有定义的全函数。
@@@ -/

#check @Nat.rec
/- @@@
```lean
@Nat.rec :
  {motive : Nat → Sort u_1} →            -- 想要什么结果类型
  motive Nat.zero →                      -- zero 这一支的结果（= 基值）
  ((n : Nat) → motive n → motive n.succ) → -- succ 这一支（= 步进）
  (t : Nat) →                            -- 要消去的那个值
  motive t                               -- 结果
```

对着 2.2 节那张「基值加步进」的说法读，三个参数一一对上：

- `motive Nat.zero` 这个参数，就是**基值**。
- `(n : Nat) → motive n → motive n.succ` 这个参数，就是**步进**。
  它拿到两样东西：剥出来的小一级的 `n`，以及**已经为 `n` 算好的结果**
  （类型 `motive n`，E09 叫它 induction hypothesis，归纳假设）。
  有了「已经算好的结果」，递归才是真递归，而不是一次性的分情况讨论。
- `(t : Nat)` 是实际要处理的那个值。

`{motive : Nat → Sort u_1}` 是隐式参数（L00 §6.4），
它是一个**类型值函数**而不是一个固定类型，因为在依值类型论里
返回类型允许依赖于你匹配到的是哪个构造子。
我们这些例子不用这个自由度，`motive` 就是「忽略参数，总是返回 `Nat`」。

直接用 `Nat.rec` 写一遍 `myDouble`：
@@@ -/

def myDoubleRec : Nat → Nat :=
  Nat.rec
    0                            -- 基值：zero 这一支
    (fun _n ih => ih + 2)        -- 步进：ih 是「已经为 n 算好的结果」

#eval myDoubleRec 3      -- 6
#guard myDoubleRec 3 = myDouble 3

/- @@@
`fun _n ih => ih + 2` 是一个匿名函数（L00 §3.1）。
`_n` 是剥出来的小一级的数（这里用不到），`ih` 是对它已经算好的结果。
对比 2.2 节的 `| Nat.succ n' => Nat.succ (Nat.succ (myDouble n'))`：
那里的 `myDouble n'` 就是这里的 `ih`。
**递归调用在 recursor 的世界里不是调用，而是一个已经递给你的参数。**

`List` 的 recursor 是同一个形状，只是 `cons` 这一支多拿一个 `head`：
@@@ -/

#check @List.rec
/- @@@
```lean
@List.rec :
  {α : Type u_2} → {motive : List α → Sort u_1} →
  motive [] →                                                  -- nil 这一支（基值）
  ((head : α) → (tail : List α) → motive tail → motive (head :: tail)) →  -- cons 这一支
  (t : List α) → motive t
```
@@@ -/

noncomputable def myLengthRec : List Nat → Nat :=
  List.rec
    0                                   -- nil 这一支
    (fun _head _tail ih => 1 + ih)      -- cons 这一支，ih 是 tail 的长度

#reduce myLengthRec [7, 8, 9]      -- 3

/- @@@
`noncomputable` 和 `#reduce` 这两个东西要解释一下，E09 开头专门写了一段。
Lean 的代码生成器认识 `match` 记法，也认识 `Nat.rec`（所以上面的
`myDoubleRec` 可以 `#eval`），但它**还不认识**大多数别的 recursor，
`List.rec` 就在其中。于是：

- 定义必须标 `noncomputable`（L00 §11.4 讲过这个关键字），意思是「这个定义不产生可执行代码」；
- 验证不能用 `#eval`（它要编译好的代码），得用 `#reduce`——
  在类型检查器里做纯符号求值，不需要编译。

这是工具链的限制，不是概念上的差别。E09 里好几个 `def` 都因为同一个原因标了
`noncomputable` 并改用 `#reduce`。

**最后一句，也是 E09 的主旨**：`match`、等式形式的 `def`、以及 2.6 节那四个定义，
统统是**语法糖**，Lean 把它们编译成对 recursor 的调用。
2.3 节 `#print myAdd` 看到的 `Nat.brecOn` 就是证据——
`brecOn` 是 Lean 在 `Nat.rec` 之上包的一层，专门用来支持结构递归。

这解释了 2.2 到 2.4 节的三条规则**为什么**是那样：

- 为什么每个构造子都要有一个分支：recursor 要求你为每个构造子都提供一个参数。
- 为什么基构造子那一支不能递归：那个参数的类型里没有「已经算好的结果」可用。
- 为什么递归调用的参数必须结构上变小：recursor 只把**剥出来的那个**子项
  连同它的结果递给你，别的值它不给。

读 E10 时碰到那句 `Total functions are ultimately supported by the basic
induction principle for the KNat type`，说的就是这件事。
细节在 E09，这里不展开。

## 2.8 本节练习

**[2.1]（读）** 下面这个定义对哪个参数递归？基值是什么？步进用的是哪个运算？

```lean
def f : Nat → Nat → Nat
| Nat.zero,    b => b
| Nat.succ a', b => Nat.succ (Nat.succ (f a' b))
```

它算的是什么？用 `f 3 10` 验证你的答案。

**[2.2]（写）** 定义 `mySum : List Nat → Nat`，把一个列表里所有数加起来。
空列表的和是 0。写完 `#eval mySum [1, 2, 3]`。

**[2.3]（写）** 定义 `upTo : Nat → List Nat`，`upTo 3` 给出 `[3, 2, 1]`
（从参数往下数到 1，不含 0）。想清楚基值是什么。

**[2.4]（判）** 下面这个定义能不能编译通过？为什么？
如果不能，把它改成能通过的形式，并说清你改了什么。

```lean
def half : Nat → Nat
| 0 => 0
| 1 => 0
| n => 1 + half (n - 2)
```

**[2.5]（写）** 定义 `iterStr : (String → String) → Nat → String → String`，
`iterStr f n s` 把函数 `f` 对 `s` 作用 `n` 次。
然后用它和 `fun s => s ++ "!"` 算出 `"hi!!!"`。
说一句：这个定义和 2.6 节的模板是什么关系？

**[2.6]（读）** 手工展开 `mySum [4, 5]`（用 [2.2] 的定义），
每一步写出来，并用 `#guard` 把中间两步钉下来。

---

**先自己做，再往下看。**

---
@@@ -/

namespace Answers_2

/- @@@
**[2.1]** 对**第一个**参数递归（模式 `Nat.succ a'` 剥的是第一个位置，
递归调用 `f a' b` 里第一个参数小一级，第二个不变）。
基值是 `b`（第一个参数为 0 时的答案）。步进套了**两层** `Nat.succ`，
也就是「加 2」。所以它算的是 `b + 2 * a`：把 `b` 自增 2 次，共做 `a` 次。
@@@ -/

def f : Nat → Nat → Nat
| Nat.zero,    b => b
| Nat.succ a', b => Nat.succ (Nat.succ (f a' b))

#eval f 3 10          -- 16 = 10 + 2*3
#guard f 3 10 = 16

/- @@@
**[2.2]** 思路：和 2.2 节的 `myLengthDemo` 同一个形状，
只是 `cons` 那一支不再丢掉 `head`，而是把它加进去。
@@@ -/

def mySum : List Nat → Nat
| []       => 0
| h :: t   => h + mySum t

#eval mySum [1, 2, 3]       -- 6
#eval mySum []              -- 0

/- @@@
**[2.3]** 基值是 `[]`（数到 0 就停，而且 0 不进列表）。
步进：把当前这个数放到对 `n'` 递归结果的前面。
注意模式里绑定的是 `n'`，而要放进列表的是 `n' + 1`，不是 `n'`。
@@@ -/

def upTo : Nat → List Nat
| Nat.zero     => []
| Nat.succ n'  => (n' + 1) :: upTo n'

#eval upTo 3        -- [3, 2, 1]
#eval upTo 0        -- []
#guard upTo 3 = [3, 2, 1]

/- @@@
**[2.4]** 不能。`n - 2` 和 2.4 节的 `n - 1` 一样，是一次函数调用的结果，
不是从构造子里剥出来的子项，所以结构递归检查不认。
报错会留下一个 `n - 2 < n` 的目标——在 `n = 0` 时它是假的。

改法：把「剥两层」写进模式。`Nat.succ (Nat.succ n')`
（或记法 `n' + 2`）一次剥掉两层，递归调用的参数就是剥出来的 `n'`：
@@@ -/

def half : Nat → Nat
| 0             => 0
| 1             => 0
| Nat.succ (Nat.succ n') => 1 + half n'

#eval half 0     -- 0
#eval half 7     -- 3
#eval half 8     -- 4
#guard half 7 = 3

/- @@@
用记法写模式，一模一样：
@@@ -/

def half' : Nat → Nat
| 0        => 0
| 1        => 0
| n' + 2   => 1 + half' n'

#guard half' 9 = 4

/- @@@
**[2.5]** 这就是 2.6 节那个模板本身，只是把「低一级的运算」抽成了参数 `f`，
并且作用的对象从 `Nat` 换成了 `String`。
基值是 `s`（作用 0 次就是原样），步进是再作用一次 `f`。
和 `myAdd2` 对比：`myAdd2 a b` 就是 `iter myInc b a`——
同一个形状，只不过 `myAdd2` 把 `f` 钉死成了 `myInc`。
@@@ -/

def iterStr : (String → String) → Nat → String → String
| _f, Nat.zero,     s => s
| f,  Nat.succ n',  s => f (iterStr f n' s)

#eval iterStr (fun s => s ++ "!") 3 "hi"      -- "hi!!!"
#guard iterStr (fun s => s ++ "!") 3 "hi" = "hi!!!"
#guard iterStr (fun s => s ++ "!") 0 "hi" = "hi"

/- @@@
**[2.6]** 展开过程：

```text
mySum [4, 5]
= mySum (4 :: [5])        -- 匹配 h :: t，h := 4，t := [5]
= 4 + mySum [5]
= 4 + (5 + mySum [])      -- 再匹配一次，h := 5，t := []
= 4 + (5 + 0)             -- 匹配 []，基值 0
= 9
```
@@@ -/

#guard mySum [4, 5] = 4 + mySum [5]
#guard mySum [5]    = 5 + mySum ([] : List Nat)
#guard mySum [4, 5] = 9

end Answers_2
end P2

/- @@@
---

# 3. 第二块：typeclass

第 2 节都是在写函数。这一节换一个问题：

> 已经有了一个新类型和它上面的运算，怎么让 `0`、`1`、`+`、`*`、`^`
> 这些现成的写法在它身上也能用？

L00 §10 讲过 `notation`、`infixl` 这些声明记法的办法。
但 `+` 这个符号 Lean 库里**已经**声明过了，而且 `Nat`、`Int`、`Float`、`String` 的
加法各不相同——不可能为每个类型各声明一遍 `+`。
解决这件事的机制叫 **typeclass（类型类）**。

这一节的全部内容也可以压成一句话：

> **`class` 声明一张接口表（有哪些字段、各是什么类型），
> `instance` 为某个具体类型把这张表填满，
> 而 `+` 这类记法展开后会去「实例库」里按类型查表。**
@@@ -/

namespace P3

/- @@@
## 3.1 `class` 是一张接口表

先看库里最简单的那几个类。`#print`（L00 §9.1）可以把它们打出来：
@@@ -/

#print Zero
/- @@@
```text
class Zero.{u} (α : Type u) : Type u
number of parameters: 1
fields:
  Zero.zero : α
constructor:
  Zero.mk.{u} {α : Type u} (zero : α) : Zero α
```

E10 的注释里抄的就是这个类的声明形式：

```lean
class Zero (α : Type u) where
  zero : α
```

逐 token 读这三行：

| token | 角色 |
|---|---|
| `class` | 关键字。声明一个 typeclass |
| `Zero` | 类名 |
| `(α : Type u)` | 类的**参数**：这张表是「为某个类型 `α` 填的」 |
| `where` | 引出字段表（和 `structure` 的 `where` 同一个用法，L00 §4.3） |
| `zero : α` | 唯一一个**字段（field）**：一个 `α` 类型的值 |

`#print` 的输出暴露了一件关键的事：**`class` 就是一个 `structure`**。
它有 `fields:` 和 `constructor:`，和 L00 §4.3 讲的 `structure` 一字不差。
`Zero.mk` 就是它的构造子，`Zero.zero` 就是它的字段投影（L00 §5.5）。

`class` 和 `structure` 唯一的区别是：`class` 声明的类型，
Lean 会把它的值登记进一个**实例库**，并且在需要时**自动**去那里找。
`structure` 的值要你自己传。

再看两个：
@@@ -/

#print One
#print Add
/- @@@
```text
class One.{u} (α : Type u) : Type u
fields:
  One.one : α

class Add.{u} (α : Type u) : Type u
fields:
  Add.add : α → α → α
```

`Add` 的字段 `add` 不是一个值，而是一个**二元函数** `α → α → α`。
所以「`α` 上的加法」这件事，在 Lean 里就是一个 `Add α` 类型的值，
里面装着那个函数。

**类名和字段名怎么找**。两条命令，这就是 E10 作业里
`Use your search engine or agent to find the names of the right classes` 的手工办法：

- `#print 类名`：看这个类有哪些字段、字段叫什么、各是什么类型。
- `#check @字段全名`：看这个字段作为函数用时的完整签名，包括隐式参数。

`@` 关闭隐式推断（L00 §6.4），这样隐式参数会显示出来：
@@@ -/

#check @Add.add
/- @@@
```text
@Add.add : {α : Type u_1} → [self : Add α] → α → α → α
```

读法：给一个类型 `α`（隐式，Lean 从参数推），
再给一个 `Add α` 的实例（**方括号**，Lean 自己去找），
然后给两个 `α`，还你一个 `α`。

方括号 `[self : Add α]` 就是 L00 §11.1 见过的 **instance implicit（实例隐式参数）**，
L00 在 `[Decidable p]` 上讲过它。这一节会反复见到。

## 3.2 `instance` 是给某个具体类型填表

有了表的形状，接下来给一个具体类型填表。E10 填的是 `KNat`；
按 `Study/README.md` 第 4 节，这份文档换一个**和算术无关**的类型来填：
一个二维向量。先定义类型（`structure`、`deriving Repr`，L00 §4.3、§4.4）：
@@@ -/

structure Vec2 where
  x : Nat
  y : Nat
deriving Repr

def v12 : Vec2 := ⟨1, 2⟩        -- 匿名构造，L00 §5.4
def v30 : Vec2 := ⟨3, 0⟩

#eval v12          -- { x := 1, y := 2 }
#eval v12.x        -- 1，字段投影，L00 §5.5

/- @@@
现在给它填 `Add` 这张表。两个向量相加就是分量各自相加：
@@@ -/

instance : Add Vec2 where
  add v w := ⟨v.x + w.x, v.y + w.y⟩

/- @@@
**逐 token 拆这三行**：

| token | 角色 |
|---|---|
| `instance` | 关键字。和 `def` 几乎一样，区别是它把结果登记进实例库 |
| （名字缺失） | 实例**可以不起名字**，Lean 会自动生成一个。E10 的所有实例都不起名 |
| `:` | 「的类型是」 |
| `Add Vec2` | 这个实例的类型：`Add` 这张表，为 `Vec2` 填的那一份 |
| `where` | 引出字段赋值表 |
| `add` | **左边是类的字段名**，必须和 `#print Add` 看到的名字一致 |
| `v w` | 字段 `add` 是个二元函数，这里把它的两个参数直接写在字段名后面 |
| `:=` | 「定义为」 |
| `⟨v.x + w.x, v.y + w.y⟩` | 字段的值。这里的 `+` 是 **`Nat` 上的加法**，不是正在定义的那个 |

最后一行里的 `+` 值得停一下：它作用在 `v.x`、`w.x` 上，而这两个是 `Nat`，
所以 Lean 查到的是库里 `Nat` 的加法实例。
**正在定义 `Vec2` 的加法时用 `Nat` 的加法，不是循环定义**。

`add v w := ...` 这种「参数写在字段名后面」的写法是糖。等价的两种写法：

```lean
instance : Add Vec2 where
  add := fun v w => ⟨v.x + w.x, v.y + w.y⟩     -- 用 fun（L00 §3.1）

instance : Add Vec2 := ⟨fun v w => ⟨v.x + w.x, v.y + w.y⟩⟩   -- 用匿名构造
```

E10 的实例用的是第一类写法的最简形式，右边直接给一个**已经定义好的函数名**：

```lean
instance : Add KNat where
  add := KNat.add      -- class field name on left, add function on right
```

E10 那行注释就是在强调这件事：**等号左边是类的字段名，右边是你自己写的那个函数**。
两边名字恰好都叫 `add` 容易看晕，但它们是两个不同的东西。

填 `Mul` 也一样。向量的逐分量乘法：
@@@ -/

instance : Mul Vec2 where
  mul v w := ⟨v.x * w.x, v.y * w.y⟩

#eval v12 + v30        -- { x := 4, y := 2 }
#eval v12 * v30        -- { x := 3, y := 0 }

/- @@@
两行 `#eval` 就是全部回报：`Vec2` 上现在能写 `+` 和 `*` 了，
而我们一个字的记法声明都没写。

**结合性和优先级也是白送的**。`+` 和 `*` 的优先级写在库里那条记法声明上，
和具体类型无关，所以 `Vec2` 自动继承：
@@@ -/

#eval v12 * v30 + v30         -- 先乘后加：{ x := 6, y := 0 }
#eval v12 * (v30 + v30)       -- 括号改变顺序：{ x := 6, y := 0 }
#eval v30 + v12 * v12         -- 先乘后加：{ x := 4, y := 4 }

/- @@@
E10 里那四行 `#eval ktwo * ktwo + ktwo` 之类的例子，验证的正是这件事，
注释写的是 `they also come (thank you Lean library) with the right
associativity, precedence, etc.`。

## 3.3 `+` 到底是怎么被解析的

`v12 + v30` 这一步，Lean 做了两次查找，不是一次。中间多出来的那一层叫 `HAdd`。
@@@ -/

#check @HAdd.hAdd
#check @instHAdd
/- @@@
```text
@HAdd.hAdd : {α : Type u_1} → {β : Type u_2} → {γ : outParam (Type u_3)} →
             [self : HAdd α β γ] → α → β → γ

@instHAdd : {α : Type u_1} → [Add α] → HAdd α α α
```

- `+` 这个记法本身展开成 `HAdd.hAdd`。`HAdd` 是**异质（heterogeneous）加法**：
  左右两边和结果允许是**三个不同的类型**，这样 `Nat + Int` 这种混合式才有机会表达。
- `instHAdd` 是库里的一条**桥梁实例**：
  只要有 `Add α`，就自动有 `HAdd α α α`（三个类型都一样的那种情况）。

所以 `v12 + v30` 的完整解析链是：

```text
v12 + v30
→ HAdd.hAdd v12 v30                 -- 记法展开
→ 要找 HAdd Vec2 Vec2 ?            -- 实例查找，第一次
→ 用 instHAdd，它要求 Add Vec2      -- 实例查找，第二次
→ 找到我们写的那个 instance        -- 命中
→ Add.add v12 v30
→ ⟨v12.x + v30.x, v12.y + v30.y⟩   -- 展开我们填的那个函数
→ ⟨4, 2⟩
```

**实践上的结论**：要让 `+` 能用，你写 `Add α` 的实例就行，
`HAdd` 那一层由库里的 `instHAdd` 自动接上。
`*` 和 `Mul`/`HMul` 的关系一模一样。
知道 `HAdd` 存在的唯一用处，是报错信息里出现的是 `HAdd` 而不是 `Add`
（第 3.7 节）。

E10 的 `Pow` 稍有不同，它本来就是**两个**类型参数：

```lean
instance : Pow KNat KNat where
  pow := exp
```

`Pow α β` 表示「底数是 `α`，指数是 `β`」。
`Nat` 的 `^` 用的是 `Pow Nat Nat`，而 `Float ^ Nat` 这种也存在，
所以这个类从一开始就留了两个位置。

## 3.4 `[C α]` 写在参数表里：type guard

到这里 typeclass 还只是「运算符重载」。它的第二个用途更有意思，
E10 开头的散文专门点出来了：**type guard（类型守卫）**。

想写一个「对任何类型都能用」的函数，但函数体里要用到 `+`。
光写类型参数不够——不是每个类型都有加法。
办法是在参数表里加一个方括号参数：
@@@ -/

def addIfAddable {α : Type} [Add α] : α → α → α
| a, b => a + b

/- @@@
**逐 token**：

| token | 角色 |
|---|---|
| `{α : Type}` | 隐式类型参数（L00 §6.4）。调用时 Lean 从实参推出它 |
| `[Add α]` | 实例隐式参数。**没有名字**，因为函数体里不直接提它 |
| `: α → α → α` | 剩下两个参数写在冒号右边，因为下面要做模式匹配（L00 §5.2） |
| `\| a, b => a + b` | 两个变量模式；`a + b` 能写出来，**全靠 `[Add α]` 这个参数在场** |

这就是 E10 的 `addAnyTypeAsLongItsAddable`，名字直译是
「只要它可加，什么类型都能加」。

`[Add α]` 做了两件事，一体两面：

1. **放行**：对有 `Add` 实例的类型，调用合法。
2. **挡住**：对没有 `Add` 实例的类型，调用**在编译期**就被拒绝。

这就是「守卫」的意思。试一圈：
@@@ -/

#eval addIfAddable 3 4                    -- 7，Nat 的实例，库里有
#eval addIfAddable (3/4 : Rat) (1/2)      -- (5 : Rat)/4，Rat 的实例，库里有
#eval addIfAddable v12 v30                -- { x := 4, y := 2 }，我们刚写的实例

/- @@@
而 `String` 过不去。`String` 有拼接（`++`），但库里**没有**给它 `Add` 的实例，
所以这一行连编译都过不了。用 `#guard_msgs` 把报错钉下来：
@@@ -/

/--
info: failed to synthesize instance of type class
  Add String

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
-/
#guard_msgs in
#check_failure addIfAddable "Hi" "There"

/- @@@
（`#check_failure` 是「我**预期**这一行通不过类型检查」的命令，
它把错误降级成一条 info，所以上面的 docstring 写的是 `info:` 而不是 `error:`。
L00 §9.4 讲过 `#guard_msgs` 的 docstring 要和实际输出逐字一致。）

报错点名的类是 **`Add`**，不是 3.3 节那个 `HAdd`。这个差别有用：

- 直接写 `+`（比如 `"Hi" + "There"`）时，查找从记法展开后的 `HAdd` 那一层开始，
  报错是 `HAdd String String ?m...`；
- 调用一个带 `[Add α]` 守卫的函数时，卡住的是**守卫这个参数本身**，
  报错直接就是 `Add String`。

两条路缺的是同一张表（`Add String`），只是报错停在了不同的深度。

E10 的源文件把这一行**注释掉**了，并在旁边写 `NOPE, no instance in library`。
它和这里做的是同一件事，只是我们用 `#guard_msgs` 把那条报错变成了编译器会核对的事实。

**`String` 想通过怎么办**？两条路，但都不该随便走：

- 为 `String` 写一个 `Add String` 实例。技术上可行，但给库里的类型加实例
  会影响所有代码，而且「字符串的加法」语义上也讲不通。
- 用对的那个类。拼接的类叫 `Append`，字段叫 `append`，记法是 `++`：
@@@ -/

#print Append
#check @Append.append
/- @@@
```text
class Append.{u} (α : Type u) : Type u
fields:
  Append.append : α → α → α

@Append.append : {α : Type u_1} → [self : Append α] → α → α → α
```

`Append` 和 `Add` 的**形状完全一样**（一个 `α → α → α` 的字段），
但它是**另一个类**，于是 `+` 和 `++` 各走各的实例库，互不干扰。
这正是 typeclass 的分寸：同形状的运算也要用不同的类名区分，
因为类名承载的是**意图**。
@@@ -/

def catIfAppendable {α : Type} [Append α] : α → α → α
| a, b => a ++ b

#eval catIfAppendable "Hi" "There"           -- "HiThere"
#eval catIfAppendable [1, 2] [3, 4]          -- [1, 2, 3, 4]，List 也有 Append 实例

/- @@@
同一个函数体 `a ++ b`，换了类型就换了实现——这是「守卫」放行之后的好处：
**一份代码，所有填过表的类型都能用**。

## 3.5 数字字面量 `0`、`1`、`2` 靠哪些类

`#eval (0 : Vec2)` 现在还不能写。`0` 不是一个 `Vec2`，
Lean 得先知道「`Vec2` 上的零是哪个值」。这就是 `Zero` 和 `One` 两个类的用处。
填表：
@@@ -/

instance : Zero Vec2 where
  zero := ⟨0, 0⟩

instance : One Vec2 where
  one := ⟨1, 1⟩

#eval (0 : Vec2)        -- { x := 0, y := 0 }
#eval (1 : Vec2)        -- { x := 1, y := 1 }
#eval (0 : Vec2) + 1    -- { x := 1, y := 1 }

/- @@@
`(0 : Vec2)` 里的 `0` 是**数字字面量（numeric literal）**，
`(... : Vec2)` 是 type ascription（类型标注，L00 §2.1）。
加上标注，Lean 才知道要在哪个类型上找零。

E10 填完 `Zero KNat` 之后立刻写了一句注释：
`Among other things, 0 is now notation`，然后 `#check (0 : KNat)` 验证。

**那 `2` 呢**？`Zero` 和 `One` 只管 `0` 和 `1` 两个字面量，别的数字过不去：
@@@ -/

/--
error: failed to synthesize instance of type class
  OfNat Vec2 2
numerals are polymorphic in Lean, but the numeral `2` cannot be used in a context where the expected type is
  Vec2
due to the absence of the instance above

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
-/
#guard_msgs in
#check (2 : Vec2)

/- @@@
报错里点名的类是 `OfNat`，不是 `Zero`。把它打出来看：
@@@ -/

#print OfNat
#check @OfNat.ofNat
/- @@@
```text
class OfNat.{u} (α : Type u) : Nat → Type u
number of parameters: 2
fields:
  OfNat.ofNat : α

@OfNat.ofNat : {α : Type u_1} → (x : Nat) → [self : OfNat α x] → α
```

注意 `OfNat` 的签名是 `(α : Type u) : Nat → Type u`——
它有**两个**参数：一个类型，**加上那个具体的数字**。
所以 `OfNat Vec2 2` 和 `OfNat Vec2 7` 是两个不同的类型，各要各自的实例。
Lean 看到字面量 `n` 在类型 `T` 的位置上，就去找 `OfNat T n` 的实例。

那 `(0 : Vec2)` 为什么能用？因为库里有两条桥梁实例，
从 `Zero α` 和 `One α` 分别接到 `OfNat α 0` 和 `OfNat α 1`
（和 3.3 节 `instHAdd` 从 `Add` 接到 `HAdd` 是同一个套路）。
**所以：填 `Zero` 和 `One` 只解锁 `0` 和 `1` 这两个字面量。**

要让任意字面量都能写，就直接填 `OfNat`。
这里换一个类型演示，免得和上面的 `Zero`/`One` 实例撞车：
@@@ -/

structure Count where
  n : Nat
deriving Repr

instance (k : Nat) : OfNat Count k where
  ofNat := ⟨k⟩

#eval (0 : Count)        -- { n := 0 }
#eval (7 : Count)        -- { n := 7 }
#eval (255 : Count)      -- { n := 255 }

/- @@@
`instance (k : Nat) : OfNat Count k where ...` 是一个**参数化的实例**：
`k` 是显式参数，所以这一条声明一次性覆盖了**所有** `k`。
字段 `ofNat` 的类型是 `α`（看 `#print OfNat` 的 `fields`），
所以右边要给一个 `Count` 的值，这里用 `k` 装进去。

这也顺手解释了 L00 §6.1 里那个坑。`def MyNatD := Nat` 之后写不进 `3`，
报错是 `failed to synthesize instance of type class OfNat MyNatD 3`——
现在能完整读懂了：`def` 挡住了 Lean 的视线（不透明），
它看不出 `MyNatD` 就是 `Nat`，于是查不到 `Nat` 的那条 `OfNat` 实例。

## 3.6 `failed to synthesize` 这个报错怎么读

这是学 typeclass 时最常见的报错，上面已经见过三次。它的结构固定：

```text
failed to synthesize instance of type class
  <类名> <类型参数...>
```

**翻译**：「我需要一个 `<类名> <类型参数>` 类型的值（也就是那张填好的表），
在实例库里找了一圈，没有。」

**三步排查**：

1. **看类名**。报错里的类名就是你缺的那张表。
   如果报的是 `HAdd`（而不是 `Add`），回到 3.3 节：你要填的是 `Add`，
   `HAdd` 那一层库里会自动接上。同理 `HMul` 对 `Mul`。
   报 `Add` 还是 `HAdd` 取决于卡在哪一步（§3.4 末尾），要填的表是同一张。
2. **看类型参数**。`HAdd String String ?m.4` 里的 `String` 告诉你
   Lean 是在哪个类型上找。如果这个类型不是你以为的那个，
   问题就不在实例上，而在前面某处的类型推断上。
   （`?m.4` 是一个还没确定的类型变量——结果类型取决于找到哪条实例，
   没找到就还是个洞。）
3. **看是不是透明性问题**。如果类型参数是你用 `def` 起的一个别名，
   换成 `abbrev`（L00 §6.1）。

**三个最常见的真实原因**：

| 报错 | 原因 | 修法 |
|---|---|---|
| `OfNat T 2` | 只填了 `Zero`/`One`，没填 `OfNat` | 填 `OfNat T k`（参数化） |
| `HAdd T T ?m` | 直接写了 `+`，而没填 `Add T` | 写 `instance : Add T where add := ...` |
| `Add T` | 调了带 `[Add α]` 守卫的函数，而没填 `Add T` | 同上 |
| `OfNat MyAlias 3` | 别名是用 `def` 定的，不透明 | 改成 `abbrev` |

最后一条通用建议：`#print 类名` 和 `#check @类名.字段名` 这两条命令，
在不确定该填哪张表、字段叫什么时直接用，比搜索引擎快。

## 3.7 本节练习

**[3.1]（读）** 不运行 Lean，先说出下面这条命令的输出会长什么样，再去验证：

```lean
#check @Mul.mul
```

然后说明：`Mul` 这个类有几个字段？字段的类型是什么？
方括号里那个参数的作用是什么？

**[3.2]（写）** 定义一个 `structure Vec3`，有三个 `Nat` 字段 `x`、`y`、`z`，
`deriving Repr`。给它填 `Add` 和 `Zero` 两张表（逐分量相加；零向量是三个 0）。
然后 `#eval` 验证 `⟨1,2,3⟩ + ⟨10,20,30⟩` 和 `(0 : Vec3)`。

**[3.3]（写）** 用 type guard 写一个函数 `square {α : Type} [Mul α] : α → α`，
把参数和自己相乘。用它算 `Nat` 的 `square 7`，再算 `Vec3` 上的
`square ⟨1,2,3⟩`（需要先给 `Vec3` 填 `Mul`）。

**[3.4]（判）** 下面这段为什么编译不过？报错里的类名会是什么？
不要新写 `Add` 实例，用**换一个类**的办法让它通过。

```lean
def joinTwice {α : Type} [Add α] (a : α) : α := a + a
#eval joinTwice "ab"
```

**[3.5]（写）** 定义 `structure Tag where s : String`（`deriving Repr`），
给它填 `Append`，让 `⟨"a"⟩ ++ ⟨"b"⟩` 得到 `⟨"ab"⟩`。
再给它填 `OfNat`，让 `(3 : Tag)` 得到 `⟨"3"⟩`
（提示：`Nat` 转字符串用 `toString`）。

**[3.6]（判）** 填了 `Zero T` 和 `One T` 之后，下面哪些能写、哪些不能？说明理由。

```lean
(0 : T)    (1 : T)    (2 : T)    (0 : T) + (1 : T)
```

最后那个需要什么额外条件？

---

**先自己做，再往下看。**

---
@@@ -/

namespace Answers_3

/- @@@
**[3.1]** 输出：

```text
@Mul.mul : {α : Type u_1} → [self : Mul α] → α → α → α
```

和 `@Add.add` 一字不差，只换了类名。`Mul` 只有一个字段 `mul`，
类型是 `α → α → α`。方括号 `[self : Mul α]` 是实例隐式参数：
Lean 自己去实例库里找 `α` 上的那份乘法表，找不到就报
`failed to synthesize`（§3.6）。
@@@ -/

#check @Mul.mul
#print Mul

/- @@@
**[3.2]** 和 §3.2、§3.5 的 `Vec2` 同一个形状，多一个分量。
@@@ -/

structure Vec3 where
  x : Nat
  y : Nat
  z : Nat
deriving Repr

instance : Add Vec3 where
  add v w := ⟨v.x + w.x, v.y + w.y, v.z + w.z⟩

instance : Zero Vec3 where
  zero := ⟨0, 0, 0⟩

#eval (⟨1, 2, 3⟩ : Vec3) + ⟨10, 20, 30⟩     -- { x := 11, y := 22, z := 33 }
#eval (0 : Vec3)                             -- { x := 0, y := 0, z := 0 }

/- @@@
**[3.3]** 思路：和 §3.4 的 `addIfAddable` 同一个形状，
只是类换成 `Mul`、参数只要一个。
`a * a` 这一行能写出来，靠的就是 `[Mul α]` 在场。
@@@ -/

instance : Mul Vec3 where
  mul v w := ⟨v.x * w.x, v.y * w.y, v.z * w.z⟩

def square {α : Type} [Mul α] (a : α) : α := a * a

#eval square 7                        -- 49，用库里 Nat 的 Mul 实例
#eval square (⟨1, 2, 3⟩ : Vec3)       -- { x := 1, y := 4, z := 9 }
#guard square 7 = 49

/- @@@
**[3.4]** 编译不过，因为库里没有 `Add String` 实例（§3.4）。
报错里的类名是 **`HAdd`**（`HAdd String String ?m...`），不是 `Add`——
因为 `+` 先展开成 `HAdd.hAdd`，查找是从 `HAdd` 那一层开始的（§3.3）。

换类的办法：拼接的类叫 `Append`，记法 `++`。`String` 库里有这条实例。
@@@ -/

/--
info: failed to synthesize instance of type class
  HAdd String String ?m.3

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
-/
#guard_msgs in
#check_failure ("ab" + "ab" : String)

def joinTwice {α : Type} [Append α] (a : α) : α := a ++ a

#eval joinTwice "ab"            -- "abab"
#eval joinTwice [1, 2]          -- [1, 2, 1, 2]
#guard joinTwice "ab" = "abab"

/- @@@
**[3.5]** `Append` 的字段叫 `append`（`#print Append` 查到的）。
`OfNat` 要写成参数化实例（§3.5），字段叫 `ofNat`，类型是 `Tag` 本身。
@@@ -/

structure Tag where
  s : String
deriving Repr

instance : Append Tag where
  append a b := ⟨a.s ++ b.s⟩

instance (k : Nat) : OfNat Tag k where
  ofNat := ⟨toString k⟩

#eval (⟨"a"⟩ : Tag) ++ ⟨"b"⟩      -- { s := "ab" }
#eval (3 : Tag)                    -- { s := "3" }
#eval (42 : Tag)                   -- { s := "42" }
#guard ((3 : Tag) ++ (4 : Tag)).s = "34"

/- @@@
**[3.6]**

| 写法 | 能不能 | 理由 |
|---|---|---|
| `(0 : T)` | 能 | 库里有 `Zero T → OfNat T 0` 的桥梁实例 |
| `(1 : T)` | 能 | 同理，`One T → OfNat T 1` |
| `(2 : T)` | **不能** | 需要 `OfNat T 2`，`Zero`/`One` 不提供它（§3.5） |
| `(0 : T) + (1 : T)` | **不能**（只填了 `Zero`/`One` 的话） | `+` 还需要 `Add T` |

最后那个要额外填 `Add T`（经由 `instHAdd` 接到 `HAdd`，§3.3）。
`Zero`/`One` 只负责把字面量写进去，不负责运算。
上面 [3.2] 的 `Vec3` 两张表都填了，所以 `(0 : Vec3) + (0 : Vec3)` 能写：
@@@ -/

#eval (0 : Vec3) + (0 : Vec3)       -- { x := 0, y := 0, z := 0 }

end Answers_3
end P3

/- @@@
---

# 4. 第三块：把一门语言深嵌入 Lean 的三件套

第 2 节在**用** Lean 写函数，第 3 节在**扩展** Lean 的记法。
这一节做第三件事：在 Lean **里面**定义一门**另外的**语言，
然后用 Lean 的函数说明那门语言里每个句子是什么意思。
@@@ -/

namespace P4

/- @@@
## 4.1 三件套是什么

E10 开头那段散文给了形式语言的三件套定义，逐条翻译：

| 英文 | 中文 | 在 Lean 里是什么 |
|---|---|---|
| syntactic specification | 语法规定 | 一个 `inductive` 类型，每个构造子是一种句子形式 |
| semantic domain | 语义域 | 一个类型，里面装的是「意义」可以取的值 |
| semantics / denotation | 语义 / 指称 | 一个递归函数，从语法类型到语义域 |

三者的关系一句话：

> **语法是一棵树，语义域是答案的集合，语义是一个把树算成答案的函数。**

L00 §5.3 为了讲多参数模式匹配，已经把 E02 的命题逻辑例子整段抄过去了。
现在回头看那三个定义，它们就是这三件套：

- `inductive PropLogicSyntax`（`T`、`F`、`And`、`Or`、`Not`、`Var`）—— **语法**；
- `Bool` —— **语义域**（一个命题的意义是真或假）；
- `def eval : PropLogicSyntax → varInterp → Bool` —— **语义**。

E10 末尾的 `Arith` 命名空间是同一套做法的第二个例子：
`inductive Expr`（`lit`、`add`）是语法，`Nat` 是语义域，
`def arithEval : Expr → Nat` 是语义。

**为什么叫「深（deep）」嵌入**。E02 的开头解释了这个词，照抄要点：

- **浅嵌入（shallow embedding）**：把被嵌语言的每个连接词映射到 Lean **已有的**
  对应构造上。L00 §7 讲的全部内容就是浅嵌入——`∧` 直接用 Lean 的 `And`、
  `∨` 用 `Or`。好处是 Lean 的工具（`decide`、`simp`）直接可用。
- **深嵌入（deep embedding）**：把每个连接词映射到**自己定义的那个语法类型的
  一个构造子**上。语言的句子变成了 Lean 里的**数据**。

深嵌入的代价是什么都要自己写（语义函数、记法、定理）。
回报是**句子成了可以操作的数据**：你可以对它递归、统计它的大小、
给它换一种语义、证明两个句子等价。这是 E10 这条路线的全部动机。

下面从头演示一遍三件套。按 `Study/README.md` 第 4 节，
这里**不写算术语言**（那是作业），换一门和算术无关的：**字符串拼接语言**。

## 4.2 第一步：语法是一个 `inductive`

先定义一门最小的语言。它的句子只有两种形式：
一个字面字符串，或者两个句子拼起来。
@@@ -/

inductive SExpr0 where
| lit (s : String) : SExpr0
| cat (e1 e2 : SExpr0) : SExpr0
deriving Repr

/- @@@
**逐 token**：

| token | 角色 |
|---|---|
| `inductive SExpr0 where` | 声明一个新类型（L00 §4.2） |
| `\| lit (s : String) : SExpr0` | 基构造子。带一个 `String` 字段，**不**带 `SExpr0` 字段 |
| `\| cat (e1 e2 : SExpr0) : SExpr0` | 递归构造子。带**两个** `SExpr0` 字段 |
| `(e1 e2 : SExpr0)` | 两个字段同类型时可以共写一个冒号（L00 §4.2） |
| `: SExpr0`（行尾） | 构造子的返回类型。能推断出来，写出来更清楚 |
| `deriving Repr` | 自动生成打印代码，这样 `#eval` 能把表达式本身打出来（L00 §4.4） |

和 2.1 节的两段式结构对照：`lit` 是基，`cat` 是步。
所以 `SExpr0` 的值是一棵**二叉树**，叶子是 `lit`，内节点是 `cat`。

`open`（L00 §6.7）把前缀省掉，然后造几个句子。
这里把 `open` 关在一个 `section` 里（L00 §6.8）：
4.5 节还要定义另一门语言，它的构造子也叫 `lit`、`cat`，
两个 `open` 同时生效会让 Lean 报 `ambiguous pattern`（L00 §5.3 提过这个报错）。
@@@ -/

section
open SExpr0

def s1 : SExpr0 := lit "hello"
def s2 : SExpr0 := lit " world"
def s3 : SExpr0 := cat s1 s2
def s4 : SExpr0 :=                 -- "a" ++ ("b" ++ "c")
  cat
    (lit "a")
    (cat
      (lit "b")
      (lit "c"))

#eval s3
#eval s4

/- @@@
注意 `#eval s4` 打印出来的是**语法树本身**，不是 `"abc"`：

```text
SExpr0.cat (SExpr0.lit "a") (SExpr0.cat (SExpr0.lit "b") (SExpr0.lit "c"))
```

这就是深嵌入的那个点：`s4` 是**数据**，还没有「意义」。
E10 的 `e4` 写法一模一样（`add (lit 7) (add (lit 6) (lit 9))`），
而且它也只是数据。

## 4.3 第二步：语义域是一个类型

语义域就是「意义可以取哪些值」。对这门语言，一个句子的意义显然是一个字符串，
所以语义域是 `String`。不需要新定义任何东西，一行标注就够了：
@@@ -/

abbrev SDomain0 : Type := String

/- @@@
这里用 `abbrev` 而不是 `def`，理由是 L00 §6.1 那条：`abbrev` 透明，
Lean 能看穿它去找 `String` 的实例；`def` 不透明，会把 `++` 和字面量挡在外面。
E02 的 `def varInterp : Type := Variable → Bool` 用的是 `def`，
那里不受影响是因为那个类型只被当函数类型用，不需要查实例。

**语义域可以是任何类型**，这是三件套里最容易被忽略的自由度：

| 语言 | 语义域 | 出处 |
|---|---|---|
| 命题逻辑 | `Bool` | E02，L00 §5.3 |
| 算术 | `Nat` | E10 的 `Arith` |
| 字符串拼接 | `String` | 本节 |

甚至**同一门语法可以配不同的语义域**，得到不同的语义函数。
本节练习 [4.2] 就是这件事。

## 4.4 第三步：语义是一个求值函数

现在把树算成答案。这是一个结构递归函数，第 2 节的全部规则原样适用：
一个构造子一个分支，基构造子那一支给基值，递归构造子那一支递归加组装。
@@@ -/

def seval0 : SExpr0 → SDomain0
| lit s      => s                            -- 基：字面量的意义就是它自己
| cat e1 e2  => seval0 e1 ++ seval0 e2       -- 步：两边各自求值，再拼起来

#eval seval0 s3      -- "hello world"
#eval seval0 s4      -- "abc"
#guard seval0 s4 = "abc"

end          -- `open SExpr0` 到此结束；下面要写全名 `SExpr0.lit`

/- @@@
**第一层，整体**。签名 `SExpr0 → SDomain0` 读成
「接受一门语言的一个句子，还你它在语义域里的意义」。
这个签名本身就是「语义」这个词在 Lean 里的全部内容。

**第二层，逐 token**。拆第二支 `| cat e1 e2 => seval0 e1 ++ seval0 e2`：

- `cat e1 e2` 是构造子模式，把 `cat` 的两个字段绑定到 `e1`、`e2`
  （L00 §5.3 的构造子模式）；
- `=>` 右边有**两个**递归调用，因为 `cat` 有两个递归字段。
  参数 `e1`、`e2` 都是模式里剥出来的，所以结构递归检查通过（§2.4）；
- `++` 是 `String` 上的拼接。它**属于语义域**，不属于被定义的语言。

**第三层，对应关系**。这是三件套最该看清的一条：

> **语法的每个构造子，对应语义函数的一个分支；
> 那个分支右边用的运算，就是这个构造子在语义域里的「意思」。**

| 语法构造子 | 语义分支右边 | 读作 |
|---|---|---|
| `lit s` | `s` | 字面量的意义是它自己 |
| `cat e1 e2` | `seval0 e1 ++ seval0 e2` | `cat` 的意义是 `String` 的 `++` |

E02 的 `eval` 和 E10 的 `arithEval` 逐行都是这个对应：
`And` 对 `&&`、`Or` 对 `||`、`Not` 对 `!`；`lit n` 对 `n`、`add e1 e2` 对 `Nat.add`。

**第四层，迁移**。要给语言**加**一种句子形式，改两个地方，缺一不可：

1. 在 `inductive` 里加一个构造子；
2. 在语义函数里加一个分支。

只加构造子不加分支，Lean 会报穷尽性错误（这是好事，它在提醒你语义还没定义）。
加一个「重复 n 次」的构造子试试：
@@@ -/

inductive SExpr1 where
| lit (s : String) : SExpr1
| cat (e1 e2 : SExpr1) : SExpr1
| rep (n : Nat) (e : SExpr1) : SExpr1       -- 新增：把 e 的意义重复 n 次
deriving Repr

def repStr : Nat → String → String
| Nat.zero,     _ => ""
| Nat.succ n',  s => s ++ repStr n' s

def seval1 : SExpr1 → String
| SExpr1.lit s      => s
| SExpr1.cat e1 e2  => seval1 e1 ++ seval1 e2
| SExpr1.rep n e    => repStr n (seval1 e)   -- 新增的那一支

#eval seval1 (SExpr1.rep 3 (SExpr1.lit "ab"))                       -- "ababab"
#eval seval1 (SExpr1.cat (SExpr1.lit "-") (SExpr1.rep 2 (SExpr1.lit "x")))  -- "-xx"

/- @@@
注意 `rep` 的字段 `(n : Nat)` **不是**递归字段，`(e : SExpr1)` 才是。
所以 `seval1` 在这一支里只对 `e` 递归，`n` 原样交给 `repStr`。
`repStr` 本身是 §2.6 那个「作用 n 次」模板的又一个实例（基值是 `""`）。

## 4.5 第四步：变量表达式和解释函数

到这里语言还只能说「hello world」这种闭合的句子。真正有用的语言要能说
「`NAME` 后面跟一个逗号」——句子里带**变量**，变量的值由外部给定。

这需要两个新东西，E02 两个都有（L00 §5.3 抄过），E10 的作业第 3 题
明确要求照 E02 的这个 pattern 做：

1. **一个变量类型**，用来区分不同的变量；
2. **一个解释（interpretation）**，把每个变量映射到语义域里的一个值。

然后语法多一个 `var` 构造子，语义函数多一个参数。一步步来。

**变量类型**。E02 的写法是一个没有字段的 `inductive`，一个构造子一个变量名：
@@@ -/

inductive SVar where
| name
| greeting
| place
deriving Repr

open SVar

/- @@@
这是一个有限、封闭的变量集合，和 E02 的 `inductive Variable | Xvar | Yvar | Zvar`
一字不差地同形。

**语法加 `var` 构造子**。这是完整版的语言：
@@@ -/

inductive SExpr where
| lit (s : String) : SExpr
| cat (e1 e2 : SExpr) : SExpr
| var (v : SVar) : SExpr          -- 变量表达式
deriving Repr

open SExpr

/- @@@
`var` 带一个 `SVar` 字段，**不**带 `SExpr` 字段，
所以它和 `lit` 一样是**基构造子**（§2.1）。
E02 的 `| Var (v : Variable)` 也是这样，E02 的注释把语法分成三类
`literal expressions / operator expressions / variable expressions`，
对应的就是「基、步、基」。

照 E02 的做法，给几个常用的变量表达式起名字，这样写句子时短一些：
@@@ -/

def N : SExpr := var name
def G : SExpr := var greeting
def P : SExpr := var place

/- @@@
**解释的类型**。一个解释就是「从变量到语义域的函数」。
照 E02 的 `def varInterp : Type := Variable → Bool` 写：
@@@ -/

def SInterp : Type := SVar → String

/- @@@
这一行值得停一下：**它用 `def` 给一个函数类型起了名字**。
L00 §4.7 讲过「类型本身也是值」，所以 `SVar → String` 可以放在 `:=` 右边，
而这个定义的类型标注是 `: Type`。

**造两个具体的解释**。每个解释是一个函数，函数体是对变量做模式匹配：
@@@ -/

def i1 : SInterp :=
  fun v =>
    match v with
    | name     => "Ada"
    | greeting => "Hello"
    | place    => "Paris"

def i2 : SInterp :=
  fun v =>
    match v with
    | name     => "Bob"
    | greeting => "Hi"
    | place    => "Paris"

#eval i1 name        -- "Ada"
#eval i2 name        -- "Bob"

/- @@@
`fun v => match v with | ... => ...` 是 L00 §3.1 的匿名函数套 §5.1 的 `match`。
也可以写成等式形式（L00 §5.2），更短：
@@@ -/

def i3 : SInterp
| name     => "Cleo"
| greeting => "Hey"
| place    => "Rome"

#eval i3 place       -- "Rome"

/- @@@
**语义函数加一个参数**。这是最关键的一步。签名从

```lean
SExpr → String
```

变成

```lean
SExpr → SInterp → String
```

读成「给一个句子，**再给一个解释**，还你这个句子在那个解释下的意义」。
E02 的 `eval : PropLogicSyntax → varInterp → Bool` 和它同形。
@@@ -/

def seval : SExpr → SInterp → String
| lit s,     _ => s                         -- 字面量不看解释
| cat e1 e2, i => seval e1 i ++ seval e2 i  -- 解释原样传给两个子表达式
| var v,     i => i v                       -- 变量：查解释

#eval seval (cat G (cat (lit ", ") N)) i1     -- "Hello, Ada"
#eval seval (cat G (cat (lit ", ") N)) i2     -- "Hi, Bob"
#eval seval (cat N (cat (lit " of ") P)) i1   -- "Ada of Paris"

/- @@@
**逐 token 拆三个分支**（多参数匹配用逗号分隔，L00 §5.3）：

| 分支 | 第一个模式 | 第二个模式 | 右边 |
|---|---|---|---|
| 1 | `lit s`（构造子模式，绑定 `s`） | `_`（通配符，不用解释） | `s` |
| 2 | `cat e1 e2`（绑定两个子树） | `i`（变量模式，绑定解释） | 两次递归，`i` **原样**传下去 |
| 3 | `var v`（绑定变量名） | `i` | `i v`——**把解释当函数应用到变量上** |

三件事值得单独说：

1. **第一支的 `_`**：字面量的意义和解释无关，所以第二个参数用通配符。
   E02 第一支写的是 `| T, _ => true`，同一个道理。
2. **第二支里的 `i` 必须原样传下去**。如果漏了（比如写成 `seval e1 i1`），
   就把解释钉死了，整个函数就错了。这是这类函数最常见的笔误。
   递归调用的**第一个**参数在变小（`e1`、`e2` 是剥出来的），
   **第二个**参数不变——这正是 §2.3 讲的「对哪个参数递归」。
3. **第三支 `i v` 就是全部的「变量语义」**。`i : SInterp`，
   而 `SInterp` 就是 `SVar → String`，所以 `i v` 是一次函数应用（L00 §3.3），
   结果类型是 `String`，正是语义域。E02 那一支写的是 `| Var v, i => i v`，
   逐字相同。

**同一个句子、不同的解释，意义不同**——这就是引入变量的全部意义。
`#guard`（L00 §9.3）把这件事钉下来：
@@@ -/

#guard seval (cat G (cat (lit ", ") N)) i1 = "Hello, Ada"
#guard seval (cat G (cat (lit ", ") N)) i2 = "Hi, Bob"
#guard seval (lit "x") i1 = seval (lit "x") i2      -- 闭合句子不受解释影响

/- @@@
## 4.6 三件套对照表

把三个例子并排放，读 E10 和做作业时对着这张表找位置：

| | 命题逻辑（E02、L00 §5.3） | 算术（E10 `Arith`） | 字符串拼接（本节） |
|---|---|---|---|
| 变量类型 | `inductive Variable` | 作业第 3 题要加 | `inductive SVar` |
| **语法** | `inductive PropLogicSyntax` | `inductive Expr` | `inductive SExpr` |
| 基构造子 | `T`、`F`、`Var v` | `lit n` | `lit s`、`var v` |
| 递归构造子 | `And`、`Or`、`Not` | `add e1 e2` | `cat e1 e2` |
| **语义域** | `Bool` | `Nat` | `String` |
| 解释类型 | `def varInterp : Type := Variable → Bool` | 作业第 3 题要加 | `def SInterp : Type := SVar → String` |
| **语义** | `eval : ... → varInterp → Bool` | `arithEval : Expr → Nat` | `seval : SExpr → SInterp → String` |
| 构造子到运算 | `And`→`&&`，`Or`→`\|\|`，`Not`→`!` | `add`→`Nat.add` | `cat`→`++` |

注意 E10 的 `arithEval` **没有**解释参数，因为它那一版语言还没有变量。
这正是作业第 3 题要补的那一块。

**走开时带走这三条**：

- 看到一个 `inductive`，它的构造子里有带自身字段的，这大概是一门语言的**语法**；
- 看到一个函数签名 `语法类型 → 某个类型`，那是**语义**，箭头右边是**语义域**；
- 签名中间多出一个 `变量类型 → 语义域` 的参数，那是**解释**，
  而语义函数里它只做两件事：在递归调用里原样传下去，在 `var` 那一支被应用到变量上。

## 4.7 本节练习

**[4.1]（写）** 给 §4.5 的 `SExpr` 加一个构造子 `shout (e : SExpr)`，
它的意义是把子表达式的意义后面加一个 `"!"`。
照 §4.4 第四层的两步做：改 `inductive`，改语义函数。
（整套重新定义一遍，不要改原来的，因为 Lean 不允许同名定义。）
验证 `shout (var greeting)` 在 `i1` 下是 `"Hello!"`。

**[4.2]（写）** 不动语法，给 §4.2 的 `SExpr0` 写**第二个**语义函数
`ssize : SExpr0 → Nat`，算这棵语法树一共有多少个节点
（`lit` 算 1 个，`cat` 算 1 个加上两棵子树）。
说一句：这个函数的语义域是什么？这说明了三件套的哪条性质？

**[4.3]（写）** 再写一个 `SInterp`，叫 `i4`，让它把三个变量全映射到 `""`。
然后验证 `seval (cat G (cat (lit ", ") N)) i4` 等于 `", "`。

**[4.4]（判）** 下面这个定义编译能过，但是错的。它错在哪？
用一个具体的表达式和一个具体的解释说明它和正确的 `seval` 给出不同答案。

```lean
def sevalBad : SExpr → SInterp → String
| lit s,     _ => s
| cat e1 e2, _ => sevalBad e1 i1 ++ sevalBad e2 i1
| var v,     i => i v
```

**[4.5]（判）** 如果只给 `SExpr` 加了 `shout` 构造子，却忘了改 `seval`，
Lean 会报什么性质的错？这是好事还是坏事？

---

**先自己做，再往下看。**

---
@@@ -/

namespace Answers_4

/- @@@
**[4.1]** 两步：`inductive` 里加一行，语义函数里加一支。
`shout` 带一个 `SExpr` 字段，所以它是**递归**构造子，那一支里要递归。

（新语言的构造子也叫 `lit`、`cat`、`var`，而 §4.5 的 `open SExpr` 还在生效，
所以下面一律写全名 `SExpr2.lit`，免得 Lean 报 `ambiguous pattern`。）
@@@ -/

inductive SExpr2 where
| lit (s : String) : SExpr2
| cat (e1 e2 : SExpr2) : SExpr2
| var (v : SVar) : SExpr2
| shout (e : SExpr2) : SExpr2          -- 新增
deriving Repr

def seval2 : SExpr2 → SInterp → String
| SExpr2.lit s,     _ => s
| SExpr2.cat e1 e2, i => seval2 e1 i ++ seval2 e2 i
| SExpr2.var v,     i => i v
| SExpr2.shout e,   i => seval2 e i ++ "!"    -- 新增的那一支

#eval seval2 (SExpr2.shout (SExpr2.var greeting)) i1       -- "Hello!"
#eval seval2 (SExpr2.shout (SExpr2.shout (SExpr2.lit "a"))) i1   -- "a!!"
#guard seval2 (SExpr2.shout (SExpr2.var greeting)) i1 = "Hello!"

/- @@@
**[4.2]** 语义域是 `Nat`，不是 `String`。
这说明：**同一门语法可以配多个语义函数，各自落在不同的语义域里**（§4.3）。
语法只规定「哪些句子合法」，它自己不决定句子是什么意思。
@@@ -/

def ssize : SExpr0 → Nat
| SExpr0.lit _       => 1
| SExpr0.cat e1 e2   => 1 + ssize e1 + ssize e2

#eval ssize s4        -- 5：两个 cat 加三个 lit
#eval ssize s1        -- 1
#guard ssize s4 = 5

/- @@@
**[4.3]** 变量全映射到空串，于是句子里只剩字面量那部分。
@@@ -/

def i4 : SInterp
| name     => ""
| greeting => ""
| place    => ""

-- 测试用的那个句子，写一次反复用
def greetName : SExpr := cat G (cat (lit ", ") N)

#eval seval greetName i4        -- ", "
#guard seval greetName i4 = ", "

/- @@@
**[4.4]** 错在 `cat` 那一支：它用 `_` 丢掉了传进来的解释 `i`，
然后在递归调用里**硬写了 `i1`**。于是不管你传什么解释，
`cat` 下面的子树一律按 `i1` 求值——解释被钉死了。

正确的写法是把 `i` 绑定出来并原样传下去（§4.5 第 2 条）。
用 `i2` 一试就现形：
@@@ -/

def sevalBad : SExpr → SInterp → String
| lit s,     _ => s
| cat e1 e2, _ => sevalBad e1 i1 ++ sevalBad e2 i1
| var v,     i => i v

#eval seval    greetName i2     -- "Hi, Bob"    ← 正确
#eval sevalBad greetName i2     -- "Hello, Ada" ← 错，用了 i1

#guard sevalBad greetName i2 ≠ seval greetName i2

/- @@@
注意最外层的 `var` 那一支是对的（它用了 `i`），
所以 `sevalBad (var greeting) i2` 碰巧还是对的——
错误只在 `cat` **下面**才显现。这类 bug 很难靠一两个例子发现，
得专门拿「同一句子换解释」去测。
@@@ -/

#guard sevalBad (var greeting) i2 = seval (var greeting) i2    -- 这一个碰巧相等

/- @@@
**[4.5]** 报的是**穷尽性（exhaustiveness）错误**：
`missing cases` / `non-exhaustive match`，Lean 指出 `shout _` 这一种形式没有分支。

这是**好事**。它说明：给语言加了一种句子形式，而你还没说这种句子是什么意思，
Lean 不让你糊过去。穷尽性检查在这里扮演的是「语义定义完整性」的守卫。

（反过来，L00 §5.3 提醒过：模式里乱用 `_` 会关掉这份保护——
以后给语法加构造子时，带 `_` 的 `match` 不报错，而你正需要它报错。）
@@@ -/

end Answers_4
end P4

/- @@@
---

# 5. 速查表

## 5.1 结构递归

| 场景 | 写什么 |
|---|---|
| 在递归类型 `T` 上写函数 | 每个构造子一个分支；基构造子给基值，递归构造子里递归 |
| 参数要做模式匹配 | 参数写在冒号**右边**：`def f : T → R` |
| 参数不做模式匹配 | 参数可以写在冒号左边：`def f (n : T) : R := ...` |
| 递归调用的参数 | 必须是模式里**剥出来的**那个名字（`n'`、`tail`、`b'`） |
| 想知道对哪个参数递归 | 看递归调用里哪个位置比模式小一级；或 `#print f` 看 `brecOn` 吃的是谁 |
| 要看计算过程 | 手工展开 + `#guard` 把中间步骤钉下来 |
| 「把低一级运算作用 n 次」 | `\| _, zero => 基值` ／ `\| a, succ b' => 低一级运算 (f a b')` |
| 想直接用归纳原理 | `T.rec 基值 (fun 剥出来的 ih => 步进) 值` |

**四层运算的形状**（§2.6）：换层只换**基值**和**步进用的运算**。

| 层 | 基值 | 步进 |
|---|---|---|
| 后继 | —— | 构造子 `succ` |
| 加法 | `a` | 后继 |
| 乘法 | `0` | 加法 |
| 乘方 | `1` | 乘法 |

## 5.2 typeclass

| 场景 | 写什么 |
|---|---|
| 想知道某个类有哪些字段 | `#print 类名` |
| 想知道字段的完整签名 | `#check @类名.字段名` |
| 给类型 `T` 填一张表 | `instance : C T where 字段名 := 实现` |
| 想让 `+` 能用 | 填 `Add T`（`HAdd` 由库自动接上） |
| 想让 `*` 能用 | 填 `Mul T` |
| 想让 `^` 能用 | 填 `Pow T T`（两个参数：底数、指数） |
| 想让 `++` 能用 | 填 `Append T` |
| 想让 `0` 能写 | 填 `Zero T` |
| 想让 `1` 能写 | 填 `One T` |
| 想让**任意**数字能写 | 填 `instance (k : Nat) : OfNat T k where ofNat := ...` |
| 想写「只对可加的类型」的函数 | 参数表里加 `[Add α]` |

**报错对照**：

| 报错 | 缺的是 |
|---|---|
| `failed to synthesize ... HAdd T T ?m` | `Add T` 实例（卡在 `+` 的记法展开处） |
| `failed to synthesize ... Add T` | `Add T` 实例（卡在 `[Add α]` 守卫处） |
| `failed to synthesize ... OfNat T 2` | `OfNat T 2`（只填 `Zero`/`One` 不够） |
| `failed to synthesize ... OfNat MyAlias 3` | 别名是 `def` 定的，改成 `abbrev` |

## 5.3 深嵌入三件套

| 三件套 | 在 Lean 里是什么 | 怎么认出来 |
|---|---|---|
| 语法 | 一个 `inductive`，构造子里有自身字段 | 是一棵树 |
| 语义域 | 一个类型 | 语义函数签名最右边那个 |
| 语义 | 一个递归函数 `语法 → 语义域` | 一个构造子一个分支 |
| 变量 | 一个无字段的 `inductive`，加一个 `var` 构造子 | `var` 是**基**构造子 |
| 解释 | `def I : Type := 变量类型 → 语义域` | 语义函数多出来的那个参数 |

**给语言加一种句子形式**：改 `inductive` 加一个构造子，改语义函数加一个分支。
两步，缺一步 Lean 会报穷尽性错误。

**写带解释的语义函数时的两条纪律**：

1. 递归调用里解释参数**原样传下去**，不要写死成某个具体解释；
2. `var v` 那一支就是 `i v`，一次函数应用，别想复杂了。

---

# 6. 术语表

| 英文 | 中文 | 一句话解释 |
|---|---|---|
| base constructor | 基构造子 | 不带自身类型字段的构造子，不需要先有一个值就能用它造值 |
| recursive constructor | 递归构造子 | 带自身类型字段的构造子，必须先有一个值才能造出下一个 |
| base value | 基值 | 递归函数里，基构造子那一支给出的答案 |
| step | 步进 | 递归函数里，把「对更小值算好的结果」加工成当前答案的那个动作 |
| structural recursion | 结构递归 | 递归调用的参数是从模式里剥出来的真子项的那种递归 |
| strict subterm | 真子项 | 模式匹配从构造子里剥出来的那个更小的值 |
| total function | 全函数 | 对每个合法输入都在有限步内给出结果的函数；Lean 只接受全函数 |
| well-founded recursion | 良基递归 | 结构递归过不去时 Lean 的第二招：要你证明某个度量在变小 |
| recursor | 递归子 | `T.rec`，Lean 为每个 `inductive` 自动生成的消去原理 |
| induction hypothesis | 归纳假设 | recursor 递给步进那一支的「已经为更小值算好的结果」 |
| iteration | 迭代 | 「把一个运算作用 n 次」这个视角；加法、乘法、乘方都是它的实例 |
| identity element | 单位元 | 某个运算作用 0 次的结果；加法是 0，乘法是 1 |
| typeclass | 类型类 | 一张接口表：声明有哪些字段、各是什么类型 |
| class field | 类字段 | 表里的一格。`instance` 的 `where` 左边写的就是它 |
| instance | 实例 | 为某个具体类型填好的那张表；Lean 自动登记并查找它 |
| instance implicit | 实例隐式参数 | 用 `[ ]` 声明的参数，Lean 自己去实例库里找（L00 §11.1） |
| instance resolution / synthesis | 实例解析 / 合成 | Lean 按类型去实例库里查表这个过程 |
| type guard | 类型守卫 | 参数表里的 `[C α]`：放行有实例的类型，挡住没有的 |
| operator overloading | 运算符重载 | 同一个记法在不同类型上走不同实例 |
| heterogeneous operation | 异质运算 | 如 `HAdd α β γ`，左右和结果允许是三个不同类型 |
| numeric literal | 数字字面量 | 源码里写的 `0`、`1`、`2`；靠 `Zero`、`One`、`OfNat` 实例落到具体类型上 |
| deep embedding | 深嵌入 | 被嵌语言的每个连接词映射到自己定义的语法类型的一个构造子 |
| shallow embedding | 浅嵌入 | 被嵌语言的每个连接词映射到 Lean 已有的对应构造 |
| syntactic specification | 语法规定 | 哪些句子合法；在 Lean 里是一个 `inductive` |
| semantic domain | 语义域 | 意义可以取哪些值；在 Lean 里是一个类型 |
| semantics / denotation | 语义 / 指称 | 每个句子是什么意思；在 Lean 里是一个递归函数 |
| variable expression | 变量表达式 | 语法里的 `var v` 构造子，意义由外部的解释决定 |
| interpretation | 解释 | 从变量类型到语义域的函数 |
| exhaustiveness | 穷尽性 | 模式匹配覆盖了所有构造子；Lean 强制要求 |
@@@ -/
