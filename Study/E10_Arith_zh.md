# E10：Typeclass 与算术语言（中文详解）

- **讲解对象**：`FPCourse/ClassNotes/E10_Arith.lean`（320 行）
- **基于 upstream commit**：`ec7a8f5`（2026-10-20）
- **写作日期**：2026-10-21
- **前置**：`Study/L00_Syntax_zh.lean`（语法手册）、`Study/E10_Prereq_zh.lean`（三块前置知识）
- **编译**：本文件不 `import` 任何东西，在容器内仓库根目录执行
  `lean Study/E10_Arith_zh.lean`，不到一秒出结果。
- **生成预览**：`python3 scripts/convert.py Study/E10_Arith_zh.lean Study/E10_Arith_zh.md`

> **本章含老师布置的作业。第 9 节和第 12 节不给答案**，只翻译题意、指出要用的概念、
> 列出坑、讨论老师的提示。作业自己写在 `Study/HW_E10.lean` 里。

---

# 1. 导读

## 1.1 这一章在做什么

一句话：**假装 Lean 里没有 `Nat`，从零造一遍自然数和它的算术，再把「算术表达式」
这门小语言深嵌入（deep embedding）到 Lean 里。**

路上会第一次正式用到 **typeclass（类型类）**。typeclass 在这一章有两个用处，
源文件开头的散文就是冲着这两个用处写的：

1. **operator overloading（运算符重载）**：让 `0`、`1`、`+`、`*`、`^`
   这些写法在我们自己造的类型上也能用。
2. **type guard（类型守卫）**：写一个「接受任何类型」的函数，但**只在那个类型
   有某个实例时**才放行。源文件里的 `addAnyTypeAsLongItsAddable` 就是这个。

## 1.2 怎么读

和 L00 一样，两个窗口并排：左边开 `Study/E10_Arith_zh.md` 的 Markdown 预览
（`Ctrl+Shift+V`），右边开 `.lean` 把光标放在代码上看 infoview。

每段代码按 L00 §1.2 的**三层拆法**读：

1. **整体**：这段在定义什么？类型签名用中文读出来。
2. **逐 token**：每个符号的角色是什么？谁是构造子、谁是被绑定的变量名、
   `=>` 左右各是什么、隐式参数在哪里被填上了。
3. **对应**：这一步在计算上做了什么？递归在哪个参数上变小？

然后第四步是**迁移**：同类的题换了什么、没换什么。

## 1.3 前置依赖：哪些东西本文档不重讲

本文档遵守 `Study/README.md` 第 4 节「回指 L00，不重讲」。下面这些语法在
L00 里已经逐 token 拆过，这里**只回指，不重复解释**：

| 语法 | 回指 |
|---|---|
| `inductive`、构造子、递归字段 | L00 §4.2 |
| `def` 的等式形式 `\| 模式 => ...` | L00 §5.2 |
| 多参数一起匹配、通配符 `_` | L00 §5.3 |
| 点记法 `n.succ`、投影 `.1` | L00 §4.2、§5.5 |
| 隐式参数 `{α : Type}`、实例隐式 `[C α]` | L00 §6.4、§11.1 |
| `namespace` / `end` / `open` | L00 §6.6、§6.7 |
| `#check`、`#eval`、`#print`、`#guard_msgs` | L00 §2.1、§2.2、§9.1、§9.4 |
| `rfl` | L00 §7.3 |

另外三块「L00 没覆盖、读 E10 之前要先有」的内容在 `Study/E10_Prereq_zh.lean` 里：

- **Prereq §2（第一块）**：递归 inductive 上的结构递归（structural recursion）。
  §2.2 基值加步进、§2.3 对哪个参数递归、§2.4 为什么递归参数必须结构变小、
  §2.5 手工展开、§2.6「把低一级的函数作用 y 次」的迭代视角、§2.7 `Nat.rec`。
- **Prereq §3（第二块）**：typeclass。§3.1 `class` 是一张接口表、
  §3.2 `instance` 是给某个具体类型填表、§3.3 `+` 怎么靠实例解析、
  §3.4 `[C α]` 当 type guard、§3.5 数字字面量靠 `Zero`/`One`/`OfNat`、
  §3.6 `failed to synthesize` 这个报错怎么读。
- **Prereq §4（第三块）**：深嵌入三件套。§4.1 三件套是什么、§4.2 语法 inductive、
  §4.3 语义域、§4.4 求值函数、§4.5 变量表达式和解释函数、§4.6 对照表。

Prereq 用的演示对象和 E10 **故意不同**（它用库里的 `Nat` 讲四层、用二维向量讲实例、
用字符串拼接语言讲三件套），所以同一套概念你会看到两遍、两个不同的壳子。

> 另外 `Study/E10_Crash_zh.lean`（3 小时速成版）覆盖的是同一批内容的压缩版。
> 本文档不依赖它。

## 1.4 源文件地图

读的时候对着行号走，确认没漏东西。

| 源文件行 | 内容 | 本文档 |
|---|---|---|
| 1–34 | 开篇散文：没有 `Nat` 的世界、typeclass 的两个用处 | §2 |
| 37–55 | `## KNat: A natural number semantic domain`：形式语言三件套 | §3 |
| 57–63 | `namespace KNat` 和「为什么要圈起来」 | §4 |
| 65–74 | `### KNat type`：`inductive KNat` | §5 |
| 76–92 | `### Special Values`：`kzero` 到 `kthree` | §6 |
| 94–119 | `### Operations`：`inc`、`dec` | §7 |
| 120–161 | 递归算术函数：`add`、`mul`、`exp` | §8 |
| **164–175** | **EXERCISE：`tet` 和 `hyperop`（作业，不给答案）** | **§9** |
| 177–230 | `### Classes`：五条 instance、字面量、优先级 | §10 |
| 233–246 | `addAnyTypeAsLongItsAddable`：type guard | §11 |
| **248–274** | **EXERCISES：四道题（作业，不给答案）** | **§12** |
| 276–320 | `end KNat`、`namespace Arith`：语法 / 操作语义 / 例子 | §13 |

## 1.5 目录

| 节 | 内容 |
|---|---|
| 1 | 导读 |
| 2 | 开篇：为什么要重新造一遍算术 |
| 3 | `KNat`：一个自然数语义域 |
| 4 | `namespace KNat`：先把工作圈起来 |
| 5 | `KNat` 类型 |
| 6 | 特殊值 `kzero` 到 `kthree` |
| 7 | 操作：`inc` 和 `dec` |
| 8 | 递归算术函数：`add`、`mul`、`exp`（含五个定义的并排比较） |
| 9 | **作业（一）**：`tet` 和 `hyperop` |
| 10 | Classes：五条 instance，和 `1 + 1 : KNat` 到底被解析成了什么 |
| 11 | type guard：`addAnyTypeAsLongItsAddable` |
| 12 | **作业（二）**：四道题 |
| 13 | `Arith`：语法、操作语义、例子 |
| 14 | 本章速查表 |
| 15 | 做作业前的自检清单 |
| 16 | 术语表 |
---

# 2. 开篇：为什么要重新造一遍算术

源文件第 1 到 34 行是三段散文。逐段读。

## 2.1 「假设我们连 `Nat` 都没有」

> *Suppose we didn't have even a Nat type or any of its operations, such as add
> or multiply, not to mention its notations, such as `*` or `+`.*

这是一个**思想实验**，但它不是空想：Lean 的 `Nat` 本身就是这么造出来的。
整章的练法是「把库里已经有的东西，自己从零造一遍」，这样做有三个好处：

1. 你会看清 `Nat` 并不是内置的魔法，它就是一个两构造子的 `inductive`。
2. 你会看清 `+`、`*`、`^` 这些记法**不属于**任何类型，它们是靠 typeclass
   实例「挂」到类型上的。
3. 你会第一次写出「同一个模式的四层」：后继、加、乘、乘方。
   这个模式是第 9 节作业的全部内容。

## 2.2 这一章要重新造的东西

> *we'll revisit the strategy of deep embedding of a language, here of natural
> number arithmetic, into Lean, and we will meet for the first time the very
> important mechanism call typeclasses.*

两个关键词：

- **deep embedding（深嵌入）**：把一门语言的**语法**表示成 Lean 里的一个
  `inductive` 类型，再写一个函数把语法项映射到含义。语法项是**数据**，
  不是 Lean 代码；要算出它的值必须显式调用求值函数。
  这个策略 L00 §5.3 已经见过一次（命题逻辑的 `PropLogicSyntax` + `eval`），
  Prereq §4 从头演示过一遍（字符串拼接语言）。
- **typeclass（类型类）**：Prereq §3 的内容。本章只用，不再讲 `class` 怎么声明。

## 2.3 typeclass 的两个用处

> *Typeclasses and their instances, first introduced in Haskell, support not only
> operator overloading, in the usual sense, but also type guards, which allow for
> the definitions of functions taking any type, but only if there's a typeclass
> instance for that type, providing additional data, such as how to perform the
> operation of that particular type of arguments.*

这段话要拆成两半看，因为它们在源文件里对应两个不同的小节：

| 用处 | 中文 | 源文件哪里 | 本文档 |
|---|---|---|---|
| operator overloading | 运算符重载：让 `+` 在新类型上也能写 | `### Classes`（177–230） | §10 |
| type guard | 类型守卫：函数接受任何类型，**但要求该类型有实例** | `addAnyTypeAsLongItsAddable`（233–246） | §11 |

注意这句 *providing additional data, such as how to perform the operation of
that particular type*。这是 typeclass 的本质：实例不只是一张「许可证」，
它**装着数据**——`Add KNat` 这个实例里装的就是「KNat 上的加法函数」本身。
所以当一个多态函数拿到 `[Add α]`，它同时拿到了「α 可加」这个许可和
「α 上怎么加」这个具体函数。

## 2.4 本章的交付物清单

> *We'll start at the beginning by defining our own type `KNat`, a set of ordinary
> arithmetic operations (increment, add, multiply, and exponentiation to start
> with), and typeclass instances ... both to overload these widely overloaded
> operations (add, etc.) and also showing how to use such instances as type guards
> when definition polymorphic functions.*

读完这段你应该能预期后面会出现什么：

1. 一个自己的类型 `KNat`；
2. 四个运算：increment（增一）、add（加）、multiply（乘）、exponentiation（乘方）；
3. 若干 typeclass 实例，用来（a）重载记法、（b）当 type guard。

三条都会在下面原样出现。源文件有几处拼写笔误（`necxt`、`thenselves`、
`funciton`、`arithmentic`、`interated`），不影响阅读，看到不要慌。
---

# 3. `KNat`：一个自然数语义域

源文件第 37 到 55 行。

## 3.1 形式语言的三件套

> *A formal language usually has a:*
> - *syntactic specification, defining the universe of legal terms (sentences, formulae) in the language;*
> - *semantic domain, defining a universe of values in which the meanings of syntax terms are defined;*
> - *semantics defining the semantic meaning or denotation of each possible syntactic term.*

这就是 Prereq §4.1 的三件套，在 Lean 里各自是什么：

| 三件套 | 中文 | 在 Lean 里是 | 本章的例子 |
|---|---|---|---|
| syntactic specification | 语法规定 | 一个 `inductive` 类型 | §13 的 `Arith.Expr` |
| semantic domain | 语义域 | 一个类型（值的集合） | §5 的 `KNat`（本章先造它） |
| semantics | 语义 | 一个从语法到语义域的函数 | §13 的 `arithEval` |

**本章的叙述顺序是「先造语义域，最后才造语法」**，这一点一开始容易迷路：
标题写着 `A natural number semantic domain`，但接下来 200 行都在造 `KNat`
和它的运算，一直到第 279 行进了 `namespace Arith` 才出现语法 `Expr`。
看地图（§1.4）定位，就不会迷。

## 3.2 「变量」和「解释」从哪来

> *Here terms are arithmetic expressions, such as `X + 1`, where `X` is an
> arithmetic variable, and the meanings of such terms, under interpretations of
> their variables, are natural numbers. Evaluating `X + 1` under an interpretation
> that assigns the value, 4, to `X`, would be 5, for example.*

这段话很重要，因为它**预告了第 12 节的作业第 3 题**。两个术语：

- **variable（变量）**：语法里的一个构造子，它自己**没有值**。
- **interpretation（解释）**：一个函数，把每个变量映射到语义域里的一个值。
  在 L00 §5.3 的命题逻辑例子里，这个函数的类型是 `Variable → Bool`
  （那里叫 `varInterp`，而 `i1` 是它的一个具体值）。

于是求值函数要多吃一个参数：`eval : 语法 → 解释 → 语义域`。
L00 §5.3 的 `eval : PropLogicSyntax → varInterp → Bool` 就是这个形状，
它的 `| (PropLogicSyntax.Var v), i => i v` 这一支正是「查表」。

注意源文件的 `Arith.arithEval`（§13）**没有**这个参数，因为它的语法里没有变量。
作业第 3 题要你把变量加进去，那时就必须加这个参数——这是那道题最容易漏的一步。

> *Let's proceed and see the rest as we go.*

好，往下走。
---

# 4. `namespace KNat`：先把工作圈起来

源文件第 57 到 63 行。

> *It's always good form to enclose your work in some namespace, to ensure that
> your definitions to conflict with those already in scope from automatically
> imported Lean libraries.*

（这句英文漏了个 `don't`，意思是「确保你的定义**不**和已经在作用域里的库定义冲突」。）

`namespace` 的语法见 L00 §6.6，不重讲。这里只说**为什么这一章非得圈起来**：
本章要定义的名字是 `add`、`mul`、`exp`、`zero`、`succ`——
全都是库里已经有的名字。不圈起来，`add` 会和 `Nat.add` 之类撞车，
或者至少在读报错时让你分不清说的是谁。
```lean
namespace KNat
```

**一个马上会咬人的细节**：这个 namespace 叫 `KNat`，而下一步要定义的类型
**也**叫 `KNat`。于是那个类型的全名（fully qualified name）是 `KNat.KNat`，
它的构造子全名是 `KNat.KNat.zero` 和 `KNat.KNat.succ`。

这不是错误，只是重名。但它会在两个地方露出来，提前知道就不会慌：

1. `#eval` 打印 `KNat` 的值时打的是全名，你会看到
   `KNat.KNat.succ (KNat.KNat.zero)` 这种双层前缀（§10.9 会看到真实输出）。
2. 在 namespace 内部写 `KNat.zero` 时，Lean 的查找顺序是
   「先试 `KNat.KNat.zero`，再试 `_root_.KNat.zero`」。
   前者存在，所以 `KNat.zero` 指的是**构造子**。这正是源文件想要的。

名字解析规则见 L00 §6.6、§6.7。第 13 节还会再碰一次这件事，
而且那次（`open KNat` 之后 `add` 到底是谁）是作业的坑之一。
---

# 5. `KNat` 类型

源文件第 65 到 74 行。

> *Our `KNat` (from scratch) type just mimics Nat.*
```lean
inductive KNat where
| zero
| succ (n : KNat)
```

**第一层：整体。**

这段定义了一个新类型 `KNat`（全名 `KNat.KNat`），它恰好有两种造法：
要么是 `zero`，要么是「某个已有的 `KNat` 的后继」。
中文读出来：**一个 KNat 要么是零，要么是某个 KNat 加一。**

**第二层：逐 token。**

| token | 角色 |
|---|---|
| `inductive` | 关键字：造一个新类型（L00 §4.2） |
| `KNat` | 新类型的名字 |
| `where` | 引出构造子表（L00 §4.2） |
| `\| zero` | 第一个 constructor（构造子），**不带参数** |
| `\| succ` | 第二个构造子 |
| `(n : KNat)` | `succ` 的一个显式参数（字段），名字 `n`，**类型是正在定义的 `KNat` 本身** |

`(n : KNat)` 里的 `KNat` 指的是正在被定义的这个类型——这叫 **recursive
inductive type（递归 inductive 类型）**，是 Prereq §2.1 的核心。
正因为它递归，这个类型的值可以无限多：

```
KNat.zero
KNat.succ KNat.zero
KNat.succ (KNat.succ KNat.zero)
...
```

**第三层：对应。**

构造子就是这个类型的 **introduction rule（引入规则）**：想造一个 `KNat`，
只有这两条路。反过来，想**用**一个 `KNat`（写一个从 `KNat` 出发的函数），
就得对这两条路各写一支——这是 **elimination（消去）**，在 Lean 里表现为
模式匹配，底层是 `KNat.rec`（E09 的要点，Prereq §2.7 点到过）。

**第四层：迁移。**

和库里的 `Nat` 并排看，一模一样：

| 本章 | 库 |
|---|---|
| `KNat.zero` | `Nat.zero`，也写 `0` |
| `KNat.succ n` | `Nat.succ n`，也写 `n + 1` |

区别只有一个：库的 `Nat` 自带一大堆记法和实例，而 `KNat` 现在**什么都没有**。
后面 §10 的五条 instance 就是在补这些。

另外源文件**没写** `deriving Repr`（L00 §4.4）。它照样能 `#eval`，
原因在 §10.9 讲。
## 5.1 本节练习

1. 写出 `KNat.succ (KNat.succ (KNat.succ KNat.zero))` 对应的是哪个自然数。
2. `KNat` 一共有多少个值？为什么？
3. 如果把 `succ` 的字段类型从 `KNat` 改成 `Nat`，这个类型还递归吗？它有多少个值？

---

**先自己做，再往下看。**

---

**答案。**

1. 3。`zero` 是 0，每套一层 `succ` 加一，套了三层。
2. 无限多。`zero` 是一个，而 `succ` 把任何一个 `KNat` 变成一个新的、
   不等于它的 `KNat`，所以可以一直造下去。
   对比 L00 §4.5「数清一个类型有几个值」里的 `Bool`（2 个）、`Unit`（1 个）、
   `Empty`（0 个）：那些类型的构造子都不拿自己当参数，所以值的个数是有限的。
3. 不递归了。写成 `succ (n : Nat)` 的话，这个类型就是「一个 `zero`
   加上每个自然数各一个 `succ n`」——值还是无限多，但它**不是**自然数的
   表示了：`succ 3` 和 `succ (succ 3)` 里后者根本写不出来，
   因为 `succ 3 : KNat` 而 `succ` 要求的是 `Nat`。递归字段才是「能一层层叠」的来源。
---

# 6. 特殊值 `kzero` 到 `kthree`

源文件第 76 到 92 行。

> *The `KNat` type provides not only the visible constructors but also a recursor
> that enables definitions of total functions from this type. As a start, we can
> bind mnemonic identifiers to special values of type type, which include terms
> representing zero (`KNat.zero`) and one (`KNat.succ KNat.zero`).*

两件事：

- **recursor（递归子）**：`inductive` 一声明，Lean 自动生成 `KNat.rec`。
  它是「从 `KNat` 出发定义 total function（全函数）」的唯一底层手段。
  Prereq §2.7 讲过，E09 会细讲。本章只需记住：**你写的每个 `match`
  最终都编译成对 recursor 的调用**，所以 Lean 才敢保证函数对每个输入都有结果。
- **mnemonic identifier（助记名）**：给常用的值起个好记的名字。下面四行就是。
```lean
def kzero := KNat.zero
def kone := KNat.succ kzero
def ktwo := KNat.succ kone
def kthree := KNat.succ ktwo
```

**第一层：整体。**

四个 `def`，给 0、1、2、3 的表示各起一个名字。
每一行都用**上一行**，所以 `kthree` 展开后是三层 `succ` 套一个 `zero`。

**第二层：逐 token。**

拿第二行 `def kone := KNat.succ kzero` 说：

| token | 角色 |
|---|---|
| `def` | 定义一个名字（L00 §2.3） |
| `kone` | 名字 |
| 没有 `: 类型` | 返回类型留给 Lean 推断，推出来是 `KNat`（即 `KNat.KNat`） |
| `:=` | 「定义为」 |
| `KNat.succ` | 构造子，当函数用，类型 `KNat → KNat` |
| `kzero` | 参数，前一行定义的名字 |

注意 `KNat.succ kzero` 是**函数应用**（L00 §3.3）：构造子带参数时就当函数用，
应用就是一个空格。

**第三层：对应。**

这四行只用了 introduction（引入）：拿构造子造值，没有任何消去。
展开到底是这样：

```
kzero  = KNat.zero
kone   = KNat.succ KNat.zero
ktwo   = KNat.succ (KNat.succ KNat.zero)
kthree = KNat.succ (KNat.succ (KNat.succ KNat.zero))
```

`def` 不是不透明的：`rfl`（L00 §7.3）会把名字展开到底再比较，所以下面这条能过。
```lean
example : kthree = KNat.succ (KNat.succ (KNat.succ KNat.zero)) := rfl
```

**第四层：迁移。**

想加 `kfour`？照抄模式：`def kfour := KNat.succ kthree`。
这几行的唯一变化点是名字和被套的那一层。

## 6.1 一个本文档自己加的辅助函数

`KNat` 的值打印出来是一串 `succ`，数起来很累。为了后面看得清输出，
这里加一个**源文件里没有**的小函数，把 `KNat` 翻译成库里的 `Nat`：
```lean
def toNat : KNat → Nat
| KNat.zero => 0
| KNat.succ n' => toNat n' + 1

#eval toNat kthree    -- 3
```

它是 Prereq §2.2 那个「基值加步进」模式的最简例子：
对参数做模式匹配，`zero` 支给基值 `0`，`succ n'` 支递归处理 `n'` 再加一。
**注意递归调用的参数是 `n'`，比输入的 `KNat.succ n'` 在结构上小一层**，
Lean 因此接受这个定义。等式形式 `| 模式 => ...` 见 L00 §5.2。

声明一下：这个函数不属于源文件，也不属于任何作业。
它只是本文档的读数工具，下文凡是要看一个 `KNat` 等于几，都用 `toNat` 包一层。

## 6.2 本节练习

1. 定义 `kfour` 和 `kfive`。
2. `def kzero := KNat.zero` 没写返回类型，怎么确认 Lean 推断对了？
3. 用 `example ... := rfl` 验证 `kthree` 的后继等于你的 `kfour`。

---

**先自己做，再往下看。**

---

**答案。**
```lean
namespace Answers_6

def kfour := KNat.succ kthree
def kfive := KNat.succ kfour

-- 第 2 题：`#check` 问类型（L00 §2.1）
#check kzero            -- KNat.kzero : KNat

-- 第 3 题
example : KNat.succ kthree = kfour := rfl
example : toNat kfive = 5 := rfl

end Answers_6
```

第 2 题的输出是 `KNat.kzero : KNat`。左边是 `kzero` 的全名（它定义在 namespace
`KNat` 里，所以全名带前缀）；右边本该是全名 `KNat.KNat`，但因为我们此刻**正在**
namespace `KNat` 里面，pretty printer（美化打印器）把能省的前缀省掉了，于是只显示 `KNat`。
`#eval` 的退回打印（§10.9）不做这个省略，所以那里会看到 `KNat.KNat.succ`。

答案包在 `namespace Answers_6` 里是为了不和正文的名字撞车（`Study/README.md` 第 4 节的约定）。
---

# 7. 操作：`inc` 和 `dec`

源文件第 94 到 119 行。

> *We implement arithmetic operations on our custom representation of natural
> numbers as total functions in Lean. Total functions are ultimately supported by
> the basic induction principle for the `KNat` type. But applying these functions
> directly is something almost no one would do, as Lean provides supportive
> notations. You'd thus see definitions such as those that follow here.
> **Look for the step functions when you study this material (hint: as defined in
> non-base cases).***

这段散文有三句话，每句都要兑现：

1. **total function（全函数）**：对每个输入都有结果，不崩、不死循环。
   Lean 只接受全函数，底子是上面说的 induction principle（归纳原理）/ recursor。
2. **「几乎没人会直接调用这些函数」**：因为有记法。`add a b` 以后会写成 `a + b`，
   靠的是 §10 的实例。所以下面的定义是**底层实现**，记法是**外壳**。
3. **「学这段时去找 step function（步进函数），提示：它在非基情形里」**：
   这是老师给整章划的重点，也是第 9 节作业的钥匙。
   每个递归定义都长成「基情形 + 非基情形」，而**非基情形里那个被调用的
   低一级函数就是 step function**。§8.4 的并排表会把五个定义的 step 全部点出来。

## 7.1 `inc`：不用拆参数
```lean
-- Increment: no need to destructure argument
def inc (n: KNat) := n.succ   -- Notation for KNat.succ n
```

**第一层：整体。**

`inc` 把一个 `KNat` 变成它的后继。类型中文读出来：**吃一个 KNat，还一个 KNat**。
它**不递归**，就是构造子 `succ` 的一个别名。

**第二层：逐 token。**

| token | 角色 |
|---|---|
| `def` | 定义 |
| `inc` | 名字 |
| `(n: KNat)` | 显式参数，名字 `n`，类型 `KNat`（L00 §2.4） |
| 没写 `: 返回类型` | 推断出来是 `KNat` |
| `n.succ` | **点记法**（L00 §4.2、§5.5）：因为 `n : KNat`，`n.succ` 展开成 `KNat.succ n` |

`#check inc` 确认签名：
```lean
#check inc      -- KNat.inc (n : KNat) : KNat
#eval toNat (inc ktwo)    -- 3
```

**第三层：对应。**

只用了 `succ` 这条引入规则，没有消去。参数**不需要拆**，所以参数可以写在冒号左边
（`(n: KNat)` 的形式）。这正是源文件注释 *no need to destructure argument* 的意思。

## 7.2 `dec`：必须拆参数
```lean
-- Decrement: must destructure (pattern match) argument
-- So the argument must be to the right of the colon
def dec : KNat → KNat
| KNat.zero => kzero          -- decrement zero is zero (truncation)
| KNat.succ n' => n'          -- decrement *one more than any n'* is n'
```

**第一层：整体。**

`dec` 求前驱。类型 `KNat → KNat` 中文读出来：**吃一个 KNat，还一个 KNat**。
它也**不递归**，但它必须 **destructure（拆解）** 参数——想知道前驱是谁，
就得看输入是用哪个构造子造的。

**第二层：逐 token。**

| token | 角色 |
|---|---|
| `def dec : KNat → KNat` | 参数写在冒号**右边**：签名只给类型，参数由下面的分支表引入 |
| `\| KNat.zero => kzero` | 第一支。模式是**构造子模式**（无字段），`=>` 右边是结果 |
| `\| KNat.succ n' => n'` | 第二支。模式要求输入是 `succ` 造的，并把它的字段**绑定**到新名字 `n'` |
| `n'` | 一个**变量模式**绑定来的名字；`'` 只是名字的一部分，没有语法含义 |

这种「参数在冒号右边 + 分支表」的写法就是 L00 §5.2 的等式形式。
它和下面这个 `match` 版本完全等价，可以互换：

```lean
def dec' (n : KNat) : KNat :=
  match n with
  | KNat.zero => kzero
  | KNat.succ n' => n'
```

**第三层：对应。**

两支正对应 `KNat` 的两个构造子，这是 `KNat` 的 **elimination（消去）**：
把一个 `KNat` 拆开，按它的造法分情况处理。两支都写了，所以 Lean 认它是全函数。

**第四层：迁移 + 一个要记住的坑。**

`dec kzero = kzero`。零的前驱**不是负数，是零**。这叫 **truncation（截断）**，
源文件注释里的 `(truncation)` 就是这个词。

这件事现在看着无害，但它是第 12 节作业第 1 题的全部难点所在：
`KNat` 里根本没有负数这个概念（类型只有 `zero` 和 `succ` 两个构造子），
所以凡是「会算出负数」的运算，在 `KNat` 上**只能截断**。
```lean
example : dec kzero = kzero := rfl
example : dec (dec ktwo) = kzero := rfl
```

## 7.3 本节练习

1. 定义 `isZero : KNat → Bool`，零时返回 `true`。
2. `inc` 能把参数写在冒号左边，`dec` 不能——这个说法准确吗？
3. 用 `example ... := rfl` 验证 `inc (dec ktwo) = ktwo`，再验证
   `inc (dec kzero) = kzero` 是**不是** `kzero`。想清楚再写。

---

**先自己做，再往下看。**

---

**答案。**
```lean
namespace Answers_7

-- 第 1 题
def isZero : KNat → Bool
| KNat.zero => true
| KNat.succ _ => false

#eval isZero kzero      -- true
#eval isZero ktwo       -- false

-- 第 3 题
example : inc (dec ktwo) = ktwo := rfl
example : inc (dec kzero) = kone := rfl     -- 不等于 kzero！

end Answers_7
```

**第 1 题**：只需要分情况，不需要递归。第二支用通配符 `_`（L00 §5.3）
是因为那个字段用不上；写成 `KNat.succ n => false` 也对，但 Lean 会提示 `n` 没用到。

**第 2 题**：不准确。准确的说法是：**不拆参数的函数可以两种写法任选，
要拆参数的函数必须让参数能被模式匹配**。既可以把参数放到冒号右边用分支表
（源文件的写法），也可以放在左边再在体里写 `match`（上面的 `dec'`）。
源文件注释 *So the argument must be to the right of the colon* 说的是
前一种写法的要求，不是唯一出路。

**第 3 题**：`inc (dec kzero)` 是 `inc kzero`，也就是 `kone`，**不是** `kzero`。
截断把信息弄丢了，所以 `inc` 和 `dec` 不是互逆的：`inc ∘ dec` 在零处失效。
这条等式失效的经验，到作业第 1 题会原样重演（减法和负号一样丢信息）。
---

# 8. 递归算术函数：`add`、`mul`、`exp`

源文件第 120 到 161 行。标题是 *Recursive Arithmetic Functions*。
这一节是全章的核心，**第 9 节的作业就是把这一节的模式再往上推一层**。

## 8.1 `add`：迭代地 `inc`

> *We start on the recursive functions with addition implemented, by case analysis
> on its second argument and use of induction. If the second argument is zero, we
> return the first argument. If it's one more than `n'` we return the successor of
> the sum of the first argument and n'. This maneuver just rewrites `a + (b + 1)`
> as `1 + (a + b)` and then evaluates `a + b` by recursion. At the end of the day,
> the add function increments the first argument `a`, `b` times for any `b`.*

散文已经把三件事说全了，记住这三句，后面每一层都照这三句找：

1. **对哪个参数做 case analysis（分情形）**：第二个。
2. **基情形返回什么**：第一个参数 `a`。
3. **非基情形怎么步进**：把 `a + (b+1)` 改写成 `(a + b) + 1`，然后对 `a + b` 递归。

最后一句是**迭代视角**（Prereq §2.6）：`add a b` 就是**把 `inc` 作用在 `a` 上 `b` 次**。
```lean
def add : KNat → KNat → KNat                -- Addition function
  | a, KNat.zero   => a
  | a, KNat.succ b => inc (add a b)
```

**第一层：整体。**

类型 `KNat → KNat → KNat` 中文读出来：**吃两个 KNat，还一个 KNat**。
（两个参数是柯里化的，见 L00 §3.2；`→` 右结合，见 L00 §3.4。）

**第二层：逐 token。**

| token | 角色 |
|---|---|
| `add : KNat → KNat → KNat` | 两个参数都在冒号右边，因为第二个要拆 |
| `\| a, KNat.zero => a` | **多参数一起匹配**（L00 §5.3）：逗号左边是第一个参数的模式，右边是第二个的 |
| `a`（逗号左） | 变量模式：匹配任何东西并绑定到 `a` |
| `KNat.zero`（逗号右） | 构造子模式：要求第二个参数是 `zero` |
| `=> a` | 基情形的结果：原封不动还回第一个参数 |
| `\| a, KNat.succ b` | 第二支：第二个参数必须是 `succ` 造的，字段绑定到 `b` |
| `inc (add a b)` | 结果：**递归调用** `add a b`，再套一层 `inc` |
| `(add a b)` 的括号 | 必需。没括号的 `inc add a b` 会被读成 `((inc add) a) b`（L00 §3.3） |

**第三层：对应。**

递归的合法性：第二个参数从 `KNat.succ b` 变成了 `b`，**结构上小了一层**，
所以这个递归一定会在有限步内撞到 `zero` 支停下来（Prereq §2.4）。
注意第一个参数 `a` 在递归中**一直不变**——它是被反复 `inc` 的那个累积值。

手工展开（`k2` 表示 `ktwo`，为了短）：

```
add k2 k2
= add k2 (succ k1)        -- 第二支，b := k1
= inc (add k2 k1)
= inc (add k2 (succ k0))  -- 第二支，b := k0
= inc (inc (add k2 k0))
= inc (inc k2)            -- 第一支（基情形）
= 4
```

数一下：`inc` 恰好出现了两次，而 `k2` 是第二个参数的值。
这就是 *increments the first argument `a`, `b` times* 的字面意思。
```lean
example : add ktwo ktwo = KNat.succ (KNat.succ ktwo) := rfl
#eval toNat (add ktwo kthree)     -- 5
```

## 8.2 `mul`：迭代地 `add`

> *Whereas addition is iterated incrementing, multiplication is iterated addition.
> To get `a * b` just add `a` to itself `b` times. Adding `a` to itself zero times
> is defined to be zero, which is exactly what is needed to make our library
> faithful to the actual math.*
```lean
def mul : KNat → KNat → KNat
| _a, KNat.zero => KNat.zero
| a, KNat.succ b => add a (mul a b)
```

**第一层：整体。** 同样吃两个 `KNat` 还一个，同样对第二个参数递归。

**第二层：逐 token。** 和 `add` 只有两处不同，正是要盯住的两处：

| 位置 | `add` | `mul` |
|---|---|---|
| 基情形的结果 | `a` | `KNat.zero` |
| 非基情形的步进 | `inc (add a b)` | `add a (mul a b)` |

还有一个新 token：

| token | 角色 |
|---|---|
| `_a` | 一个**名字以下划线开头的参数模式**。它和 `_` 一样匹配任何东西，但保留了名字以便阅读；下划线前缀告诉 Lean「我知道它没被用到，别警告我」 |

写成 `| _, KNat.zero => KNat.zero` 也完全一样（`exp` 的第一支就是这么写的）。
源文件两种都用了，不是笔误，只是风格不统一。

**第三层：对应。**

基情形为什么必须是 `zero` 而不是 `a`？因为 *adding `a` to itself zero times*
应该是 0。如果照抄 `add` 的基情形写成 `a`，那 `mul a kzero` 就等于 `a`，
整个库对不上数学。**基值跟着层级变，不能照抄上一层**——
这是第 9 节和第 12 节作业最常踩的坑，第一次出现在这里。

手工展开：

```
mul k2 k3
= add k2 (mul k2 k2)
= add k2 (add k2 (mul k2 k1))
= add k2 (add k2 (add k2 (mul k2 k0)))
= add k2 (add k2 (add k2 zero))      -- 基情形
= 6
```

`add` 出现 3 次（= 第二个参数），最里面是基值 `zero`。
```lean
#eval toNat (mul ktwo kthree)     -- 6
```

## 8.3 `exp`：迭代地 `mul`

> *Exponentiation is iterated multiplication in just the same way. `a ^ b` is `a`
> multiplied by itself `b` times.*
```lean
def exp : KNat → KNat → KNat
| _, KNat.zero => kone      -- kone is defined above
| a, KNat.succ b' =>  mul (exp a b') a
```

**第二层：逐 token。** 和前两个比，三处不同：

| 位置 | `add` | `mul` | `exp` |
|---|---|---|---|
| 基情形的结果 | `a` | `KNat.zero` | `kone` |
| 步进用的函数 | `inc` | `add` | `mul` |
| 递归调用的位置 | `inc (add a b)` | `add a (mul a b)`（递归在**第二个**实参） | `mul (exp a b') a`（递归在**第一个**实参） |

第三行值得停一下。`mul a (mul a b)` 和 `mul (exp a b') a` 的实参顺序不一样。
对数学来说无所谓（乘法交换），但**读代码时别把它当成模式的一部分**——
模式的要点是「步进函数吃两个东西：递归结果和 `a`」，顺序是作者的自由。

**第三层：对应。** 基值又变了：这次是 `kone`，因为「`a` 自乘 0 次」是 1。
手工展开：

```
exp k2 k3
= mul (exp k2 k2) k2
= mul (mul (exp k2 k1) k2) k2
= mul (mul (mul (exp k2 k0) k2) k2) k2
= mul (mul (mul kone k2) k2) k2      -- 基情形
= 8
```
```lean
#eval toNat (exp ktwo kthree)     -- 8
```

## 8.4 五个定义并排：共同形状

这是本节最重要的一张表。**第 9 节的作业就是给这张表再加一行。**

| 函数 | 类型 | 对哪个参数递归 | 基情形（第二参数为 `zero`）返回 | 步进用的低一级函数 | 迭代读法 |
|---|---|---|---|---|---|
| `inc` | `KNat → KNat` | **不递归** | —— | 构造子 `succ` 本身 | 「`succ` 作用 1 次」 |
| `dec` | `KNat → KNat` | **不递归**（只拆一层） | `kzero`（截断） | —— | 不在这条阶梯上，它是反方向的 |
| `add` | `KNat → KNat → KNat` | 第二个 | `a`（第一个参数原样） | `inc` | 把 `inc` 作用在 `a` 上 `b` 次 |
| `mul` | `KNat → KNat → KNat` | 第二个 | `KNat.zero` | `add` | 把 `a` 加到自己身上 `b` 次 |
| `exp` | `KNat → KNat → KNat` | 第二个 | `kone` | `mul` | 把 `a` 乘到自己身上 `b` 次 |

把三个递归定义抽成一个骨架，`g` 代表「低一级的函数」，`base` 代表基值：

```
def f : KNat → KNat → KNat
| a, KNat.zero    => base          -- base 可能用到 a，也可能是个常量
| a, KNat.succ b  => g ... (f a b) ...   -- 递归结果喂给 g，连同 a
```

三个要素，每上一层都要**重新决定**：

1. **对哪个参数递归**：三层都是第二个。递归让它从 `succ b` 降到 `b`，
   所以循环次数由第二个参数决定。第一个参数全程不变，是「被反复作用」的那个。
2. **基值**：`a` → `zero` → `one`。**每层都不一样，而且都不是照抄上一层。**
   判断方法只有一个：问「把低一级的运算作用 **0** 次，结果按数学该是什么」。
3. **步进函数**：`inc` → `add` → `mul`。**每层用的是紧挨着的下一层**，
   不是跳级。所以写第 n 层之前，第 n−1 层必须已经存在。

记住这三条，你就有了写任意一层的配方；也就看懂了老师那句
*Look for the step functions*（步进函数在非基情形里）。

## 8.5 为什么能这么叠：迭代视角

把三条迭代读法连起来看：

```
add a b = a 上面叠 b 个 inc
mul a b = a 上面叠 b 个「加 a」
exp a b = a 上面叠 b 个「乘 a」
```

每一层都是「**把低一级的运算重复 b 次**」。这个结构叫
**hyperoperation（超运算）阶梯**，第 9 节作业要你再往上走一级（甚至写出通用的那一层）。
在那之前先把这三层读熟：**同一个形状，换了基值和步进函数**。

## 8.6 本节练习

1. 手工展开 `add kone kthree` 的每一步，数出 `inc` 出现几次。
2. `add` 对第二个参数递归。写一个对**第一个**参数递归的版本 `addL`，
   并用 `example ... := rfl` 验证它和 `add` 在 `ktwo`、`kthree` 上结果相同。
3. 定义 `double : KNat → KNat`，用 `add` 实现。它是 `mul` 的哪个特例？

---

**先自己做，再往下看。**

---

**答案。**
```lean
namespace Answers_8
```

第 1 题：

```
add k1 k3
= inc (add k1 k2)
= inc (inc (add k1 k1))
= inc (inc (inc (add k1 k0)))
= inc (inc (inc k1))        -- 基情形，返回第一个参数
= 4
```

`inc` 出现 3 次，等于第二个参数 `kthree`。
```lean
-- 第 2 题：对第一个参数递归。基情形变成「第一个参数是 zero 时返回第二个参数」
def addL : KNat → KNat → KNat
| KNat.zero, b => b
| KNat.succ a', b => inc (addL a' b)

example : addL ktwo kthree = add ktwo kthree := rfl
example : toNat (addL ktwo kthree) = 5 := rfl

-- 第 3 题
def double (n : KNat) : KNat := add n n

example : toNat (double kthree) = 6 := rfl

end Answers_8
```

**第 2 题**要注意：换了递归的参数，**基值也得换**。
`add` 的基情形在「第二个参数是 `zero`」时返回第一个参数；
`addL` 的基情形在「第一个参数是 `zero`」时必须返回**第二个**参数。
照抄成 `| KNat.zero, b => KNat.zero` 或 `=> b` 以外的任何东西都是错的。
这再次说明：**递归在哪个参数上 + 基值是什么，这两件事是绑在一起的**。

**第 3 题**：`double n = mul n ktwo`（也等于 `mul ktwo n`，但按定义展开的步数不同）。
`double` 不是新的一层，它只是固定了 `mul` 的一个参数。
---

# 9. 作业（一）：`tet` 和 `hyperop`

源文件第 164 到 175 行。

> **这是老师布置的作业。按 `Study/README.md` 第 4 节，本节只做四件事：
> 翻译题意、指出要用的概念并回指、列出坑、讨论老师的提示。
> 不给代码，也不出「改个名字就是答案」的变式题。**
> 作业自己写在 `Study/HW_E10.lean` 里；写完卡住了，把你的代码贴出来，
> 我帮你看错在哪，不帮你写。

## 9.1 原文

> *EXERCISE: define the tetration, call it `tet`. Lean has no special notation for
> it. What it does have is a way to take advantage of the pattern you're seeing
> here. Call the `identity` function the 0th hyperoperation, increment the 1st
> hyperop, add the 2nd, multiplication, the 3rd, and tetration the fourth. First
> write `tet` following the pattern above. Second, harder, see if you can define
> `hyperop`, taking three arguments, the first being the `hyper-depth`, in which
> case `tet a b` is `hyperop 4 a b`.*

## 9.2 题意翻译

**题目一（`tet`）**：定义 **tetration（迭代幂次 / 幂塔）**，叫 `tet`。
Lean 没有它的专用记法。按上面 `add`、`mul`、`exp` 的**同一个模式**写出来。

tetration 是什么：`exp` 是「把 `a` 乘自己 `b` 次」，那么 tetration 就是
「把 `a` **乘方**自己 `b` 次」，也就是一座 `b` 层高的幂塔。例如
`tet 2 3` 应该是 `2 ^ (2 ^ 2)` = 16（算的时候注意结合方向，见 §9.4 的坑 3）。

**题目二（`hyperop`，更难）**：老师在题目里给了一套编号——
identity（恒等函数）是第 0 级 hyperoperation（超运算），
increment 第 1 级，add 第 2 级，multiplication 第 3 级，tetration 第 4 级。
要求定义一个吃**三个**参数的 `hyperop`，第一个参数是 **hyper-depth（超运算层级）**，
使得 `tet a b` 等于 `hyperop 4 a b`。

换句话说：**把 §8.4 那张表本身写成一个函数**。表里每一行的三个要素
（对哪个参数递归 / 基值 / 步进函数）都要变成由 depth 决定的东西。

## 9.3 这两题要用的概念，分别回指哪里

| 你需要的东西 | 回指 |
|---|---|
| 「基值 + 步进」的递归骨架，为什么递归调用的参数必须结构变小 | 本文档 §8.4、Prereq §2.2、§2.4 |
| 对第二个参数做 case analysis、多参数一起匹配、通配符 | 本文档 §8.1、L00 §5.3 |
| 每层的步进函数是紧挨着的下一层（`inc`→`add`→`mul`→…） | 本文档 §8.4 第 3 条 |
| 基值每层都变、不能照抄 | 本文档 §8.2（`mul` 的基值为什么不是 `a`）、§8.6 第 2 题 |
| 迭代视角「把低一级的运算重复 b 次」 | 本文档 §8.5、Prereq §2.6 |
| 递归函数的类型签名怎么写、参数放冒号左边还是右边 | 本文档 §7.2、L00 §5.2 |
| 第三个参数（depth）如果用 `Nat`，`Nat` 的 `n+1` 模式怎么写 | Prereq §2.1、§2.2（库里的 `Nat` 那段） |
| 想给 `tet` 配个记法 | 本文档 §10、L00 §10（`infixl` 等），但题目说「没有专用记法」，可以不配 |

## 9.4 容易踩的坑

**坑 1：基值随层级变化，不能照抄上一层。**
`add` 的基值是 `a`，`mul` 是 `zero`，`exp` 是 `one`——三层三个不同的值（§8.4）。
所以第四层的基值**必须自己推**，推的方法是问：
「把第三层的运算（`exp`）作用 **0** 次，结果按数学该是什么？」
把这个问题答出来并写在注释里，再动手写代码。照抄 `exp` 的 `kone`
可能对也可能不对，但**不经推导地照抄一定是错的做法**。

**坑 2：`hyperop` 的基情形不止一个。**
`hyperop` 的基值取决于 depth（因为每层基值不同，见坑 1）。
如果你只写一个统一的「第二个值参数为 `zero`」分支，低层级就会算错。
动手前先把表格填完整：对每个 depth，`b = 0` 时返回什么。

**坑 3：结合方向。**
幂塔不是结合的：`2 ^ (2 ^ 2)` = 16，而 `(2 ^ 2) ^ 2` = 16 这个例子巧合相等，
换成 `tet 2 4` 或 `tet 3 3` 就会立刻分叉（`3 ^ (3 ^ 3)` = 3 的 27 次方，
而 `(3 ^ 3) ^ 3` = 19683）。所以**写步进时要想清楚递归结果放在哪一侧**。
注意 §8.3 指出过 `exp` 的步进写的是 `mul (exp a b') a`，递归结果在**左**；
对乘法来说左右无所谓，对乘方**有所谓**。照抄 `exp` 那一行的形状而不想清楚方向，
就会写出一个「底数和指数搞反」的 `tet`。

**坑 4：`hyperop` 的 depth 参数用 `Nat` 还是 `KNat`，会影响你怎么写 `hyperop 4 a b`。**
如果 depth 的类型是 `KNat`，那么 `hyperop 4 a b` 里的 `4` **写不出来**：
`KNat` 上只有 `Zero` 和 `One` 两个实例，`(2 : KNat)` 都会报
`failed to synthesize OfNat KNat 2`（§10.11 有实测报错）。
两条出路：depth 用库里的 `Nat`（那么 `4` 就是普通的 `Nat` 字面量），
或者 depth 用 `KNat` 但把 `4` 写成四层 `succ`（或先 `def kfour`）。
**两条都行，自己选一条并保持一致。**

**坑 5：嵌套递归可能过不了终止检查。**
`hyperop` 的自然写法里，递归调用的**参数本身又是一个递归调用**
（「第 n 级作用在第 n+1 级的结果上」那种形状）。这时 Lean 可能报
`fail to show termination`，因为它看不出哪个参数在单调下降。
遇到这个报错，先在纸上说清「是哪两个参数按什么顺序下降的」，再决定
是调整定义形状，还是显式写终止证明。这不是一个「再试一次就能过」的报错，
是一个**要先想清楚再动手**的信号。

**坑 6：unary 表示会爆。**
`KNat` 是一元（unary）表示：数 `n` 占 `n` 层 `succ`。`tet 2 3` = 16 还好，
`tet 2 4` = 65536 在这种表示下已经很吃力，`tet 3 3` 是天文数字，`#eval` 不要碰。
**测试只用极小的输入**，而且用 §6.1 那种 `toNat` 风格的辅助函数把结果读成 `Nat`，
否则你会得到一屏幕的 `KNat.KNat.succ`。

**坑 7：`KNat` 上没有 `BEq`，`#guard` 直接用不了。**
想断言结果，两条路：写 `example : ... = ... := rfl`（L00 §7.3），
或者先转成 `Nat` 再 `#guard`（`Nat` 有 `DecidableEq`）。
见 L00 §9.3 关于 `#guard` 的说明。

## 9.5 老师公告里的提示怎么理解

老师在公告里给的提示是：**Mathlib 把第 0 级 hyperoperation 定成「后继」**。
这条提示的真正用处不是告诉你怎么写代码，而是**替你排掉一个编号陷阱**。

把两套编号并排放：

| 级别 | 源文件题目里的编号 | Mathlib 的编号 |
|---|---|---|
| 0 | identity（恒等） | successor（后继，即 `inc`） |
| 1 | increment | addition |
| 2 | addition | multiplication |
| 3 | multiplication | exponentiation |
| 4 | **tetration** | **tetration** |

看出问题了吗：**源文件那一列把 exponentiation 整个漏掉了**。
照它的列法数下去，第 4 级应该是 exponentiation，tetration 得是第 5 级；
可题目又说 `tet a b` 是 `hyperop 4 a b`。两句话自己冲突。

而在 Mathlib 的编号里，`tet = hyperop 4` 恰好成立。所以这条提示在说：

1. **题目里那串「identity 第 0 级…」的话不要当圣经**，它数漏了一级；
   以「`tet a b = hyperop 4 a b`」这个约束为准，它和 Mathlib 的编号一致。
2. **两种编号都可以用**——你可以把 identity 放在第 0 级（那就得往上重数一遍，
   并且 `tet` 不再是第 4 级），也可以按 Mathlib 把 successor 放第 0 级
   （`tet` 就是第 4 级）。标准做法是后者。
3. **但必须自洽**。自洽的判据是三条，缺一条就是编号没理清：
   - 对每个 depth `n`，你能说出「第 `n` 级是哪个运算」；
   - 对每个 `n`，你能说出「第 `n` 级的基值是什么」（坑 1、坑 2）；
   - 你写的 `hyperop` 在小输入上和你已有的函数**对得上**：
     按你的编号，某一级应该等于 `add`，某一级应该等于 `mul`、`exp`，
     而第 4 级（或你选的那个级）应该等于你自己写的 `tet`。
     把这几条用 `example ... := rfl` 或转成 `Nat` 后 `#guard` 钉在源码里，
     就等于给自己的编号写了测试。

还有一个 arity（元数）上的小坎，这条提示也顺手解决了：
identity 吃**一个**参数，increment 也吃**一个**，而 add、mul 吃**两个**。
`hyperop n a b` 却必须对所有 `n` 都吃两个值参数。
所以低层级那一个「多余」的参数怎么处理，需要你定一个说法
（Mathlib 的做法是让第 0 级无视第一个参数，直接对第二个参数取后继）。
不管你选哪套编号，这个说法必须写下来，并且和上面三条判据对得上。

## 9.6 自检

动手之前，先能回答 §15 自检清单里「作业（一）」那几条。答不上来就回 §8 再读一遍。
---

# 10. Classes：五条 instance

源文件第 177 到 230 行，标题 `### Classes`。

这一节兑现 §2.3 表里的第一行：**operator overloading（运算符重载）**。
目标是让下面这些写法在 `KNat` 上合法：`0`、`1`、`a + b`、`a * b`、`a ^ b`。

`class` 和 `instance` 的机制本身是 Prereq §3 的内容（`class` 是一张接口表、
`instance` 是给某个具体类型填表、`[C α]` 写在参数表里是 type guard、
数字字面量靠 `Zero`/`One`/`OfNat`、怎么用 `#check @Add.add` 和 `#print Add` 查字段名、
`failed to synthesize` 怎么读）。这里**不重讲机制**，只逐 token 拆这五条实例，
并且把「`1 + 1 : KNat` 里的 `1` 和 `+` 各自被解析成了什么」追到底。

## 10.1 源文件引用的 `Zero` 类

> *Here's the `Zero` typeclass in Lean. An instance associates a value, given by
> the value of the field, `Add.zero`, with any type given by `α`. We will next
> create an instance of this class for the KNat type, to define what we mean by
> zero for KNat.*
> ```lean
> class Zero (α : Type u) where
>   zero : α
> ```

**先改一个笔误**：散文里写的字段名 `Add.zero` 是错的，应该是 `Zero.zero`。
`Add` 是加法那个类，和 `Zero` 没关系。这个笔误正好提醒一件事：
**类名和字段名是两个不同的名字，不要凭印象写，要查。**（怎么查见 Prereq §3.1。）

**逐 token 读这张接口表：**

| token | 角色 |
|---|---|
| `class` | 关键字：声明一个 typeclass（一张接口表） |
| `Zero` | 类名，首字母大写 |
| `(α : Type u)` | 类的参数：这张表是**对某个类型 `α`** 填的。`u` 是 universe（宇宙）层级，`Type u` 见 L00 §6.4 |
| `where` | 引出字段表 |
| `zero : α` | 唯一的字段，名字 `zero`（小写），类型是 `α` 本身 |

关键一句：**`Zero α` 这张表里装的不是「α 可以有零」这个许可，而是零那个值本身。**
实例化之后，`Zero.zero` 就是一个「从实例里取值」的函数。
自己查一下它的签名：
```lean
#check @Zero.zero     -- {α : Type u_1} → [self : Zero α] → α
#check @One.one       -- {α : Type u_1} → [self : One α] → α
```

读这两个签名：`{α : Type u_1}` 是隐式参数（L00 §6.4），
`[self : Zero α]` 是**实例隐式参数**（L00 §11.1）——Lean 自动去找实例填进去，
返回的是 `α` 的一个值。所以 `Zero.zero` 的意思是「给我一个类型和它的 `Zero` 实例，
我还你那个类型的零」。

## 10.2 `instance : Zero KNat`
```lean
instance : Zero KNat where
zero := KNat.zero
```

**第一层：整体。** 给 `KNat` 这个具体类型填 `Zero` 那张表。表只有一个字段，所以只填一行。

**第二层：逐 token。**

| token | 角色 |
|---|---|
| `instance` | 关键字：声明一个实例（给某个类型填表） |
| 没有实例名 | 可以不起名，Lean 自动生成一个（这里叫 `instZeroKNat`，§10.8 会在输出里看到） |
| `:` | 后面跟这个实例的**类型** |
| `Zero KNat` | 实例的类型：「`KNat` 的 `Zero` 表」。注意这里 `KNat` 是**类型**（全名 `KNat.KNat`，见 §4） |
| `where` | 引出字段赋值 |
| `zero` | **字段名**，必须和 `class Zero` 里那个字段同名；写成 `Zero.zero` 或 `Zero` 都会报错 |
| `:=` | 赋值 |
| `KNat.zero` | 填进去的值：构造子。在 namespace `KNat` 内部，这个名字解析成 `KNat.KNat.zero`（§4） |

**缩进提醒**：源文件把 `zero := KNat.zero` 写在了第 0 列（完全不缩进），
照样能编译，因为 `where` 块只要在下一行开始就行。
但**惯例是缩进两格**，下面那条 `Add` 实例源文件就缩进了。
风格不统一不是错误，读的时候别以为自己看错了。

**第三层：对应。** 这条实例一旦声明，就进了全局的实例库
（instance 的可见性和 `namespace` 没关系，不像普通 `def` 那样要加前缀）。
从此 Lean 在任何地方需要 `Zero KNat` 时都能找到它。

**马上的效果**：源文件的注释 *Among other things, `0` is now notation* 说的就是——
`0` 这个**数字字面量**现在可以当 `KNat` 用了。
```lean
-- Among other things, `0` is now notation
#check (0 : KNat)     -- 0 : KNat
```

`(0 : KNat)` 是 type ascription（类型标注，L00 §2.1）：告诉 Lean「把这个 `0`
当 `KNat` 读」。输出 `0 : KNat` 看着平淡，但中间发生了三步，`pp.explicit`
可以看到（§10.8 做同样的事）：`0` 先变成 `OfNat.ofNat 0`，
Lean 要找 `OfNat KNat 0` 的实例，找到了库里的桥 `Zero.toOfNat0`，
这座桥要求 `Zero KNat`，于是用上了我们刚声明的实例。

## 10.3 `instance : One KNat`
```lean
instance : One KNat where
one := kone
#check (1 : KNat)     -- 1 : KNat
```

**逐 token** 只有三处和 `Zero` 那条不同：

| 位置 | `Zero` 那条 | 这一条 |
|---|---|---|
| 实例类型 | `Zero KNat` | `One KNat` |
| 字段名 | `zero` | `one` |
| 填的值 | 构造子 `KNat.zero` | **我们自己定义的** `kone`（§6） |

第三行值得注意：填进字段的**不必是构造子**，任何类型对的 term 都行。
`kone` 是个 `def`，一样可以填。

和 `Zero` 对称，库里有桥 `One.toOfNat1 : [One α] → OfNat α 1`，
所以 `1` 这个字面量现在也能当 `KNat` 用了。

**只有 `0` 和 `1`。**`Zero` 和 `One` 两个类只管这两个字面量，
`2`、`3`、`4` 都不行——§10.11 有实测报错。这件事是作业（一）坑 4 的来源。

## 10.4 `instance : Add KNat`
```lean
instance : Add KNat where
  add := KNat.add      -- class field name on left, add function on right
```

**逐 token。** 源文件自己的注释已经把要点写在那儿了：
*class field name on left, add function on right*（左边是类的字段名，右边是我们的函数）。

| token | 角色 |
|---|---|
| `Add KNat` | 实例类型。查 `#print Add` 可知 `Add` 只有一个字段 `add : α → α → α` |
| `add`（`:=` 左边） | **字段名**，属于 `Add` 这个类，全名 `Add.add` |
| `KNat.add`（`:=` 右边） | **我们 §8.1 定义的那个函数**。在 namespace `KNat` 内部，这个名字先试 `KNat.KNat.add`（不存在），再试 `KNat.add`（存在），所以指的是我们的 `add` |

**这里有一个必须看清的区分**：`:=` 左边的 `add` 和右边的 `KNat.add` 是**两个不同的名字**，
只是长得像。左边是类的字段名（固定，由 `class Add` 规定），右边是你的实现（随你命名）。
下一条实例把这件事推到极致。

## 10.5 `instance : Mul KNat`
```lean
instance : Mul KNat where
mul := mul
```

**`mul := mul` 看着像在自我定义，其实不是。**

| 位置 | 这个 `mul` 是谁 | 为什么 |
|---|---|---|
| `:=` 左边 | 类 `Mul` 的字段 `Mul.mul` | `where` 块里 `:=` 左边的位置**只能**放字段名，Lean 按字段名解析，不走普通的名字查找 |
| `:=` 右边 | 我们 §8.2 定义的 `KNat.mul` | 普通的名字查找：在 namespace `KNat` 内部，`mul` 就是 `KNat.mul` |

所以这一行读作：「`Mul` 类的 `mul` 字段，填我们的 `mul` 函数」。没有循环。
源文件上一条写成 `add := KNat.add`（右边写全名），这一条写成 `mul := mul`（右边写短名），
两种都对。**写全名更不容易让自己读糊**。

## 10.6 `instance : Pow KNat KNat`
```lean
instance : Pow KNat KNat where
pow := exp
```

**这一条和前面四条有结构性的不同：类名后面跟了两个类型。**

查一下这个类：
```lean
#check @Pow.pow     -- {α : Type u_1} → {β : Type u_2} → [self : Pow α β] → α → β → α
```

`Pow` 有**两个**类型参数：`Pow α β` 的字段类型是 `α → β → α`。
也就是说底数和指数**允许是不同的类型**（库里 `Float ^ Nat`、`Nat ^ Nat` 都有实例）。

| token | 角色 |
|---|---|
| `Pow KNat KNat` | 我们选择让底数和指数都是 `KNat`，所以两个参数都填 `KNat` |
| `pow` | 字段名 |
| `exp` | 我们 §8.3 的函数。它的类型 `KNat → KNat → KNat` 正好对上 `α → β → α`（因为这里 α = β = KNat） |

顺带记一笔：`^` 这个记法实际展开成 `HPow.hPow`（heterogeneous power，异构乘方），
`HPow` 有三个类型参数（底数、指数、结果），库里有一条从 `Pow α β` 到
`HPow α β α` 的桥。`+`、`*` 同理，分别经过 `HAdd`、`HMul`。
平时不用管这层，但 §10.8 的 `pp.explicit` 输出里会看到 `HAdd.hAdd`，别被它吓到。

## 10.7 五条实例的并排总结

| 实例 | 类 | 类的参数个数 | 字段名 | 填进去的东西 | 换来的写法 |
|---|---|---|---|---|---|
| `Zero KNat` | `Zero` | 1 | `zero` | 构造子 `KNat.zero` | 字面量 `0` |
| `One KNat` | `One` | 1 | `one` | `def kone` | 字面量 `1` |
| `Add KNat` | `Add` | 1 | `add` | 函数 `KNat.add` | `a + b` |
| `Mul KNat` | `Mul` | 1 | `mul` | 函数 `KNat.mul` | `a * b` |
| `Pow KNat KNat` | `Pow` | 2 | `pow` | 函数 `KNat.exp` | `a ^ b` |

**模式**：`instance : 类名 类型参数... where 字段名 := 你的实现`。
要填对，你得知道三件事：类名、字段名、字段的类型签名。三件事都用
`#print 类名` 和 `#check @类名.字段名` 查（Prereq §3.1）。

## 10.8 `#eval (1 + 1 : KNat)`：`1` 和 `+` 各自被解析成了什么

这是本节的点题之处。先看结果：
```lean
#eval (1 + 1 : KNat)
#eval toNat (1 + 1 : KNat)     -- 2，用 toNat 读得清楚些
```

第一条 `#eval` 的真实输出是：

```
KNat.KNat.succ (KNat.KNat.succ (KNat.KNat.zero))
```

**两件事要解释：为什么能打印，以及 `1` 和 `+` 是怎么来的。**

**（甲）为什么没有 `deriving Repr` 也能打印。**
`#eval` 要把结果变成文字，通常靠 `Repr` 或 `ToString` 实例（L00 §4.4）。
`KNat` 两个都没有。Lean 这时**退回**到直接打印构造子应用的形式，
并且用**全名**打印，于是出现双层前缀 `KNat.KNat.succ`（§4 预告过）。
这是个方便的兜底，但读起来累——所以本文档加了 `toNat`（§6.1）。

**（乙）`1` 和 `+` 的解析链。**
用 `pp.explicit`（把所有隐式参数和实例都打出来）看 Lean 实际构造了什么：
```lean
set_option pp.explicit true in
#check (1 + 1 : KNat)
```

输出（手工折行）是：

```
@HAdd.hAdd KNat KNat KNat (@instHAdd KNat instAddKNat)
  (@OfNat.ofNat KNat (nat_lit 1) (@One.toOfNat1 KNat instOneKNat))
  (@OfNat.ofNat KNat (nat_lit 1) (@One.toOfNat1 KNat instOneKNat))
  : KNat
```

一层层读。**先读两个 `1`**：

| 步 | 发生了什么 |
|---|---|
| 1 | 源码里的 `1` 是一个 `Nat` 字面量，Lean 把它变成 `OfNat.ofNat (nat_lit 1)`。`nat_lit 1` 表示「真正的、未经重载的数字 1」 |
| 2 | 这个 term 的类型要是 `KNat`，所以 Lean 要找实例 `OfNat KNat 1` |
| 3 | 我们**没有**直接写 `OfNat KNat 1` 的实例。但库里有桥 `One.toOfNat1 : {α} → [One α] → OfNat α 1` |
| 4 | 这座桥要求 `One KNat`。有——就是 §10.3 那条，自动名 `instOneKNat` |
| 5 | 于是 `1` 最终等于 `One.one`，也就是我们填进去的 `kone` |

**再读 `+`**：

| 步 | 发生了什么 |
|---|---|
| 1 | `a + b` 这个记法展开成 `HAdd.hAdd a b`（异构加法，允许两边类型不同） |
| 2 | 这里两边都是 `KNat`，Lean 要找 `HAdd KNat KNat KNat` |
| 3 | 库里有桥 `instHAdd : {α} → [Add α] → HAdd α α α` |
| 4 | 这座桥要求 `Add KNat`。有——§10.4 那条，自动名 `instAddKNat` |
| 5 | 于是 `+` 最终就是我们填进去的 `KNat.add` 函数 |

**一句话总结**：`1` 走的是 `OfNat ← One.toOfNat1 ← One KNat`，
`+` 走的是 `HAdd ← instHAdd ← Add KNat`。
**记法和字面量本身不属于任何类型，它们都是「先展开成某个类的字段调用，
再由实例解析（instance resolution）决定落到哪个具体函数上」。**
这就是 operator overloading 在 Lean 里的全部机制。

剩下两条 `#eval` 同理，分别落到 `mul` 和 `exp`：
```lean
#eval toNat (ktwo * kthree)     -- 6
#eval toNat (ktwo ^ kthree)     -- 8
```

## 10.9 记法还白送了优先级和结合性

> *Not only do we get these notations, but they also come (thank you Lean library)
> with the right associativity, precedence, etc.*

这是实例机制的一个附带好处：`+`、`*`、`^` 的优先级（precedence）和
结合性（associativity）是**库在声明这些记法时一次性定好的**（L00 §10.2 有那张表），
和 `KNat` 无关。你只要填了实例，就自动继承了「`*` 比 `+` 紧」这类规则，
不用自己写 `infixl`。

源文件用四个 `#eval` 验证：
```lean
#eval toNat (ktwo *  ktwo + ktwo)    -- six
#eval toNat (ktwo * (ktwo + ktwo))   -- eight!
#eval toNat (ktwo +  ktwo * ktwo)    -- six
#eval toNat (ktwo + (ktwo * ktwo))   -- six
```

读这四行：

| 写法 | 实际结合成 | 值 |
|---|---|---|
| `ktwo * ktwo + ktwo` | `(2 * 2) + 2` | 6 |
| `ktwo * (ktwo + ktwo)` | `2 * (2 + 2)` | 8 |
| `ktwo + ktwo * ktwo` | `2 + (2 * 2)` | 6 |
| `ktwo + (ktwo * ktwo)` | 显式括号，同上 | 6 |

第三、四行值的**相同**，这正是要点：**`*` 比 `+` 优先级高**，
所以第三行不写括号也按第四行那样结合。
第一、二行值的**不同**，说明括号真的改变了结合方式，不是摆设。

```lean
不是你漏看了内容，它就是空的。）

## 10.10 `(2 : KNat)` 为什么报错

我们只填了 `Zero` 和 `One`，所以只有 `0` 和 `1` 两个字面量可用。
`2` 会报错——下面用 `#guard_msgs`（L00 §9.4）把这个报错钉在源码里，
这样它既能展示报错，又不影响本文件编译通过：
```


/--
error: failed to synthesize instance of type class
  OfNat KNat 2
numerals are polymorphic in Lean, but the numeral `2` cannot be used in a context where the expected type is
  KNat
due to the absence of the instance above

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
-/
#guard_msgs in
#check (2 : KNat)

```lean
**这个报错怎么读**（Prereq §3.5、§3.6 讲过格式，这里对照本例）：

- `failed to synthesize instance of type class` = 「我需要一个实例，但找不到」。
  **失败发生在编译期**，不是运行期。
- `OfNat KNat 2` = 缺的正是这个实例。注意 `OfNat` 的第二个参数是**数字本身**，
  所以 `OfNat KNat 2` 和 `OfNat KNat 1` 是两个不同的实例需求。
- 第二段话解释了后果：数字字面量在 Lean 里是多态的，但 `2` 用不到 `KNat` 上。

想让 `2` 也能写，办法是给 `KNat` 提供通用的 `OfNat KNat n` 实例
（需要一个把 `Nat` 转成 `KNat` 的函数）。本章不做；作业（一）坑 4 给了两条绕开的路。

## 10.11 本节练习

1. 用 §6.1 的 `toNat` 给 `KNat` 写一个 `ToString` 实例，让 `toString kthree` 得到 `"3"`。
   （提示：先 `#print ToString` 查字段名和字段类型。）
2. 不跑代码，先预测 `ktwo ^ ktwo + ktwo` 的值，再验证。
3. `instance : Mul KNat where mul := mul` 里两个 `mul` 分别是谁？
   用 `#check @Mul.mul` 和 `#check KNat.mul` 把你的回答坐实。

---

**先自己做，再往下看。**

---

**答案。**
```


namespace Answers_10

-- 第 1 题。`ToString` 的字段名是 `toString`，类型 `α → String`
local instance : ToString KNat where
  toString n := toString (toNat n)

#eval toString kthree       -- "3"
#eval s!"ktwo = {ktwo}"     -- "ktwo = 2"

-- 第 2 题：`^` 比 `+` 紧，所以是 (2^2) + 2 = 6
#eval toNat (ktwo ^ ktwo + ktwo)     -- 6
example : toNat (ktwo ^ ktwo + ktwo) = 6 := rfl

-- 第 3 题
#check @Mul.mul       -- {α : Type u_1} → [self : Mul α] → α → α → α
#check KNat.mul       -- KNat.mul : KNat → KNat → KNat

end Answers_10

```lean
**第 1 题**用了 `local instance`：`local` 让这条实例只在当前 namespace / section
内有效，出了 `end Answers_10` 就失效。这样做是故意的——否则后面所有 `#eval`
的输出都会变成这个实例打印的样子，和源文件的输出对不上了。

**第 2 题**：`^` 的优先级比 `*` 还高，`*` 又比 `+` 高。顺序是 `^` > `*` > `+`（L00 §10.2）。

**第 3 题**：`Mul.mul` 是类的字段，带一个实例隐式参数 `[self : Mul α]`；
`KNat.mul` 是我们自己的函数，不带实例参数。实例声明做的事就是把后者装进前者。
```


```lean
---

# 11. type guard：`addAnyTypeAsLongItsAddable`

源文件第 233 到 246 行。

这一节兑现 §2.3 表里的第二行：**type guard（类型守卫）**。
函数名就是说明书：*add any type as long as it's addable*
（任何类型都能加，只要它是可加的）。
```


def addAnyTypeAsLongItsAddable {α : Type} [Add α] : α → α → α
| a, b => a + b

```lean
**第一层：整体。**

这是一个**多态函数（polymorphic function）**：它不固定在某个类型上，
而是对任何满足条件的类型 `α` 都能用。
类型签名中文读出来：**给定一个类型 `α`，以及 `α` 的一个 `Add` 实例，
吃两个 `α`，还一个 `α`**。

**第二层：逐 token。**

| token | 角色 |
|---|---|
| `{α : Type}` | **隐式参数**（L00 §6.4）：类型参数，调用时不用写，Lean 从实参推断 |
| `[Add α]` | **实例隐式参数**（L00 §11.1）：Lean 自动去实例库里找 `Add α`。**没有名字**，因为函数体不直接提它 |
| `: α → α → α` | 两个值参数和返回值，都是那个 `α` |
| `\| a, b => a + b` | 唯一一支，两个参数都是变量模式（L00 §5.3）；这里不需要分情形，但写成等式形式也合法 |
| `a + b` | 这个 `+` **不是任何具体类型的加法**，它展开成 `HAdd.hAdd`，由 `[Add α]` 填进来的那个实例决定落到哪个函数（§10.8） |

写成 `def ... (a b : α) : α := a + b` 完全等价；源文件用等式形式是风格选择。

**第三层：对应。**

`[Add α]` 在这里扮演两个角色，缺一不可：

1. **守卫（guard）**：调用时如果 `α` 没有 `Add` 实例，Lean 在**编译期**就拒绝。
2. **数据来源**：函数体里的 `+` 需要知道「怎么加」，这个信息就来自那个实例
   （回看 §2.3 最后一段：实例装着数据）。

## 11.1 为什么 `Nat`、`Rat`、`KNat` 都放行

答案很简单：**库里（或我们自己）给这三个类型都声明了 `Add` 实例。**
用 `#synth`（让 Lean 当场找实例并把找到的实例名打出来）可以亲眼看到：
```


#synth Add Nat        -- instAddNat
#synth Add Rat        -- Rat.instAdd
#synth Add KNat       -- instAddKNat（§10.4 我们自己声明的那条）

```lean
三条都找得到，所以三种类型都能喂给 `addAnyTypeAsLongItsAddable`：
```


-- add for Nat, Add Nat instance provided by library
#eval addAnyTypeAsLongItsAddable 3 4      -- 7

-- add for rationals (instance defined in Lean library)
#eval (3/4: Rat) + 1/2                    -- (5 : Rat)/4

-- -- add for KNat
#eval addAnyTypeAsLongItsAddable (1 : KNat) 1
#eval toNat (addAnyTypeAsLongItsAddable (1 : KNat) 1)   -- 2

```lean
三行逐个读：

- **`addAnyTypeAsLongItsAddable 3 4`**：实参是 `3` 和 `4`，Lean 默认把裸数字字面量
  当 `Nat`，于是 `α := Nat`，`[Add α]` 由 `instAddNat` 填上，`+` 落到 `Nat.add`，结果 `7`。
- **`(3/4: Rat) + 1/2`**：注意**这一行其实没有用到我们的多态函数**，
  它直接写了 `+`。源文件的注释说「这是有理数的加法」，这句话没错，
  但代码走的是记法解析那条路（§10.8），不是 type guard 那条路。
  想真正测试多态函数，要写成下面这样：
```


#eval addAnyTypeAsLongItsAddable (3/4 : Rat) (1/2)      -- (5 : Rat)/4

```lean
  （`Rat` 是核心库里的有理数类型。这里 `α := Rat`，实例是 `Rat.instAdd`。）

- **`addAnyTypeAsLongItsAddable (1 : KNat) 1`**：第一个实参标注成 `KNat`，
  于是 `α := KNat`；第二个 `1` 不用标注，因为 `α` 已经定下来了，
  它经由 `One.toOfNat1` 变成 `kone`（§10.8）。
  结果打印成 `KNat.KNat.succ (KNat.KNat.succ (KNat.KNat.zero))`，用 `toNat` 读是 `2`。

**一个关键观察**：这个函数**写的时候**并不知道 `KNat` 的存在
（它比 `KNat` 的实例更一般），但它照样能用在 `KNat` 上。
这就是 type guard 的好处：**一次定义，所有「填了表」的类型都能用。**

## 11.2 为什么 `String` 被挡住

源文件把这一行注释掉了，并写明 *NOPE, no instance in library*：

```lean
-- add for String? NOPE, no instance in library
-- #eval addAnyTypeAsLongItsAddable "Hi" "There"
```

把注释去掉会怎样？下面用 `#guard_msgs`（L00 §9.4）把真实报错钉在源码里：
```


/--
error: failed to synthesize instance of type class
  Add String

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
-/
#guard_msgs in
#eval addAnyTypeAsLongItsAddable "Hi" "There"

```lean
**逐句读这个报错：**

- `failed to synthesize instance of type class / Add String`
  ——Lean 把 `α` 推断成了 `String`（从实参 `"Hi"` 来），然后去找 `Add String`，找不到。
- **失败发生在编译期，不是运行期。** 这个 `#eval` 根本没开始算。
  对比一下：如果守卫是运行期检查，你会先跑起来再崩；type guard 让它**跑之前**就被拒。
- 报错指的是**实例缺失**，不是「`String` 类型不对」。
  `addAnyTypeAsLongItsAddable` 的 `α` 可以是任何 `Type`，`String` 完全符合；
  被卡住的只有 `[Add α]` 这一关。

**`String` 为什么没有 `Add` 实例？** 这是库的设计选择，不是遗漏。
字符串的「接起来」在库里叫 **append（拼接）**，用的是另一个类和另一个记法：
```


#synth Append String          -- instAppendString
#check @Append.append         -- {α : Type u_1} → [self : Append α] → α → α → α
#eval "Hi" ++ "There"         -- "HiThere"

```lean
`Append.append` 的字段类型 `α → α → α` 和 `Add.add` **一模一样**，
但类名不同，所以 `+` 用不了，`++` 可以。
这件事说明：**typeclass 的作用不只是「签名对不对」，还包括「这个运算叫什么」。**
库作者不给 `String` 配 `Add`，是因为「字符串相加」在数学上没有意义
（比如它不交换：`"ab" ++ "cd" ≠ "cd" ++ "ab"`），不该借用 `+` 这个符号。

**所以 `[Add α]` 这一道守卫到底在守什么**：

| 类型 | 有 `Add` 实例吗 | 结果 |
|---|---|---|
| `Nat` | 有（`instAddNat`） | 放行，用 `Nat.add` |
| `Rat` | 有（`Rat.instAdd`） | 放行，用有理数加法 |
| `KNat` | 有（§10.4 我们自己声明的 `instAddKNat`） | 放行，用我们的 `KNat.add` |
| `String` | **没有**（它有 `Append`，不是 `Add`） | 编译期拒绝 |

## 11.3 本节练习

1. 照着 `addAnyTypeAsLongItsAddable` 写一个 `mulAnyTypeAsLongItsMultipliable`，
   并在 `Nat` 和 `KNat` 上各测一次。
2. 不改 `addAnyTypeAsLongItsAddable` 的定义，想办法让 `"Hi"` 和 `"There"`
   也能被「加」起来。（提示：`[Add α]` 要什么，你就给它什么。）
3. `#synth Add (List Nat)` 会成功还是失败？先猜，再试。

---

**先自己做，再往下看。**

---

**答案。**
```


namespace Answers_11

-- 第 1 题：把 `Add` 换成 `Mul`，`+` 换成 `*`，别的不动
def mulAnyTypeAsLongItsMultipliable {α : Type} [Mul α] : α → α → α
| a, b => a * b

#eval mulAnyTypeAsLongItsMultipliable 3 4                       -- 12
#eval toNat (mulAnyTypeAsLongItsMultipliable ktwo kthree)       -- 6

-- 第 2 题：自己给 String 声明一个 Add 实例，把它接到 ++ 上
local instance : Add String where
  add := fun s t => s ++ t

#eval addAnyTypeAsLongItsAddable "Hi" "There"     -- "HiThere"

-- 第 3 题
#synth Mul Nat        -- instMulNat
-- #synth Add (List Nat)  -- 失败：库里没有 Add (List Nat)，列表用 ++（Append）

end Answers_11

```lean
**第 1 题**：变的只有类名（`Add`→`Mul`）和记法（`+`→`*`）。
**没变的**是整个形状：隐式类型参数、实例隐式参数、两个同类型的值参数。
这就是 type guard 的迁移方式。

**第 2 题**：这题的意义是让你看清**守卫把守的是实例库，不是类型本身**。
我们一行没改那个多态函数，只是补了一条 `Add String` 实例，
`"Hi"` 就过关了。（用 `local` 是为了别把这条有争议的实例漏到文件后面去，
见 §10.11 答案的说明。库作者不提供它是有道理的——§11.2 讲过。）

**第 3 题**：失败。`List` 的拼接也是 `++`（`Append`/`HAppend`），不是 `+`。
把 `#synth Add (List Nat)` 的注释去掉就能看到和 §11.2 同样形状的报错。
```


```lean
---

# 12. 作业（二）：四道题

源文件第 248 到 274 行，标题 `EXERCISES`。

> **这是老师布置的作业。本节只做四件事：翻译题意、指出要用的概念并回指、
> 列出坑、讨论老师的提示。不给代码。**
> 写在 `Study/HW_E10.lean` 里。卡住了把你的代码贴出来，我帮你定位错在哪。

## 12.1 第 1 题：给 KNat 加上取负和减法

> *1. Extend KNat algebra with operations for unary Negation and Subtraction, and
> instances to provide notations and more. Use your search engine or agent to find
> the names of the right classes in Lean's libraries for these operations.*

**题意**：给 `KNat` 这套代数再加两个运算——**unary negation（一元取负）**
和 **subtraction（减法）**——并且给它们各配一条 typeclass 实例，
这样就能用上记法。老师明确要求：**库里这两个运算对应的类名，自己用搜索引擎或
agent 查出来。**（所以本节不替你查。下面只讲查到之后容易写错的地方。）

**这题分三步，缺一不可：**

1. 写出两个**函数**（一个吃一个 `KNat`，一个吃两个 `KNat`）；
2. 查出两个**类名**和它们的**字段名、字段类型**；
3. 写两条 `instance`，把函数填进字段。

**要用的概念，回指：**

| 需要 | 回指 |
|---|---|
| 怎么对 `KNat` 做模式匹配、`zero` / `succ n'` 两支 | 本文档 §7.2（`dec`）、L00 §5.2、§5.3 |
| 递归函数「基值 + 步进」的骨架 | 本文档 §8.4、Prereq §2.2 |
| 截断（truncation）是什么、为什么零的前驱是零 | 本文档 §7.2 |
| `instance : 类 类型 where 字段 := 实现` 的形状 | 本文档 §10.2 到 §10.7、Prereq §3.2 |
| 怎么查类名、字段名、字段类型（`#print 类`、`#check @类.字段` 见 Prereq §3.1；`#synth` 见本文档 §11.1） | Prereq §3.1、本文档 §11.1 |
| `failed to synthesize` 报错怎么读 | 本文档 §10.11、§11.2、Prereq §3.6 |

**坑 1：`KNat` 里没有负数，所以「取负」只能是某种截断。**
`KNat` 只有 `zero` 和 `succ` 两个构造子（§5），**类型本身就装不下负数**。
所以你必须先回答一个设计问题：`neg ktwo` 应该是什么？
没有「正确答案」从天上掉下来，**你定一个说法并写在注释里**，
然后让实例和测试都和这个说法一致。
（提示：库里的 `Nat` 面对同样的处境，它的减法 `3 - 5` 给出的是 `0`，
不是报错也不是负数。自己 `#eval (3 : Nat) - 5` 看一眼。）

**坑 2：减法在零处截断，于是熟悉的等式会失效。**
`sub a b` 在 `b > a` 时只能停在 `zero`。后果是
「先减再加」不等于原值——这和 §7.3 第 3 题里 `inc (dec kzero) ≠ kzero` 是同一件事。
写测试时别写一条你以为该成立、其实不成立的等式，然后以为自己代码错了。
**先想清楚哪些等式在截断语义下还成立**，再写断言。

**坑 3：类名、字段名、元数（arity）。**
这三件事是三个不同的东西，别混：

- **类名**首字母大写（`Add`、`Mul`、`Pow` 都是），你要查的那两个也一样；
- **字段名**小写，而且**不是**你随便取的名字——`where` 后面必须写字段名，
  写错会报 `unknown field` 之类的错（§10.2 的逐 token 表说过这件事）；
- **元数**：取负是**一元**的，它的字段类型只吃一个参数（形如 `α → α`），
  而减法是**二元**的（`α → α → α`）。
  照抄 §10.4 那条 `Add` 实例的形状去填一元类，类型就对不上。
  查清楚再写：`#print 那个类` 一行就能看到字段名和字段类型。
- 顺带一提：`-` 这个符号在 Lean 里**同时**是一元和二元两种记法，
  它们解析到**两个不同的类**。所以你写 `-a` 和写 `a - b` 用的实例不是同一条。
  （类似 §10.6 里 `^` 经过 `HPow`：`-`、`+`、`*` 都有对应的异构版本。）

**坑 4：别忘了「and more」。**
题目说 *instances to provide notations and more*。最低要求是记法能用
（`-a`、`a - b` 写得出来），但你还应该**用几个小例子验证**运算真的对
（第 4 题就是干这个的）。

## 12.2 第 2 题：把语言从 `Nat` 换成 `KNat`，并加上新运算

> *2. Replace Nat with KNat in the following definition of the syntax and semantics
> of our little language of arithmetic. Extend the language to support the
> subtraction and negation operations you've just defined.*

**题意**：下面（也就是 §13 的 `namespace Arith`）那套「语法 + 语义」是建立在库的
`Nat` 上的。把它改成建立在 `KNat` 上，然后把你第 1 题定义的减法和取负
**加进这门语言**。

**注意这题要改的是两个地方，不是一个**（这是最常漏的一步）：

- **语法**（`inductive Expr`）：字面量构造子现在装的是 `KNat` 而不是 `Nat`；
  并且要为新运算各加一个构造子（取负是一元的，所以它的构造子只带**一个**
  子表达式字段；减法带两个）；
- **语义**（求值函数）：返回类型从 `Nat` 变成 `KNat`，
  并且要为每个新构造子各加一支分支，分支里调用你第 1 题写的函数。

**要用的概念，回指：**

| 需要 | 回指 |
|---|---|
| 深嵌入三件套：语法是 inductive、语义域是类型、语义是函数 | 本文档 §3.1、§13、Prereq §4.1 到 §4.4 |
| 带字段的构造子怎么写（`\| add (e1 e2 : Expr) : Expr`） | 本文档 §13.2、L00 §4.2 |
| 求值函数怎么对每个构造子写一支、怎么递归 | 本文档 §13.3、Prereq §4.4 |
| 第 1 题定义的函数和实例 | 你自己的 `HW_E10.lean` |

**坑 5：`Arith` 里 `open KNat` 之后，名字怎么解析。**
源文件的 `namespace Arith` 开头就有一行 `open KNat`（§13.1）。
于是 `KNat` 里的所有名字都不带前缀可用了，包括 `add`、`mul`、`exp`。
而你的 `Expr` 也会有一个叫 `add` 的构造子，再加上源文件写了 `open Expr`——
**`add` 这个名字于是同时指两个东西**。

Lean 的做法是「两个候选都试，哪个能通过类型检查就用哪个」：
`add e1 e7` 里实参是 `Expr`，所以选 `Expr.add`；
`add kone ktwo` 里实参是 `KNat`，所以选 `KNat.add`。
这叫 overload resolution（重载消解），§13.1 有实测。

**它的危险在于报错会变得很难读**：当你写错一处类型，
Lean 可能抱怨的是「另一个 `add`」的类型不匹配，让你一脸茫然。
两条防御：

- 在语义函数里**写全名**（`Expr.add`、`KNat.add`），源文件的 `arithEval`
  就是这么写的（§13.3）——它写的是 `Expr.lit`、`Expr.add` 和 `Nat.add` 全名，
  一个短名都没用；
- 或者给构造子起不会撞车的名字。**但第 2 题要你改的是老师给的那段代码**，
  擅自改构造子名就偏离题目了，所以优先选第一条。

**坑 6：换成 `KNat` 之后，字面量不好写了。**
原来的 `lit 7` 里 `7` 是 `Nat` 字面量。换成 `KNat` 之后，
`7` **写不出来**（§10.11：只有 `0` 和 `1` 有实例）。
你得用 `succ` 一层层套，或者先 `def` 几个像 `kthree` 那样的名字（§6），
或者写一个 `Nat → KNat` 的转换函数再用它。三条路都行，自己选一条。
**这是把 `Nat` 换成 `KNat` 之后第一个会让你卡住的地方，提前想好。**

## 12.3 第 3 题：加上变量表达式

> *3. Extend your language of arithmetic with variable expressions, so you can
> write not just, say, two plus three, but X plus 3. See how we handled
> propositional variables in our formalization of propositional logic and use the
> same pattern here.*

**题意**：给你的算术语言加上**变量表达式**，这样不只能写「2 + 3」，
还能写「X + 3」。老师直接给了出处：**照着我们形式化命题逻辑时处理命题变量的
那个办法做。**

那个办法在 L00 §5.3 原样放着（代码在那一节，`inductive Variable`、
`PropLogicSyntax` 的 `Var` 构造子、`varInterp`、`i1`、`eval`），
Prereq §4.5 又用一门无关的小语言从头演示了一遍。**三件套变成四件套**：

1. 一个表示变量的类型（命题逻辑里叫 `Variable`，有 `Xvar`、`Yvar`、`Zvar` 三个值）；
2. 语法 inductive 里多一个构造子，它的字段是**一个变量**，不是子表达式；
3. 一个 **interpretation（解释）**：从变量到语义域的函数
   （命题逻辑里是 `Variable → Bool`；你这里语义域是 `KNat`，所以类型相应地变）；
4. 求值函数**多吃一个参数**（那个解释），并且**所有已有分支都要跟着改签名**，
   递归调用时要把解释**一路传下去**。

**要用的概念，回指：**

| 需要 | 回指 |
|---|---|
| 变量构造子 + 解释函数 + 多参数求值的完整模式 | **L00 §5.3**（命题逻辑那段，含逐 token 拆解）、Prereq §4.5 |
| 为什么求值需要「在某个解释下」 | 本文档 §3.2 |
| 多参数一起匹配、每支都要带上解释参数 | L00 §5.3 |
| 解释本身怎么写（一个 `fun v => match v with ...`） | L00 §5.3 的 `i1` |

**坑 7：第 4 件事最容易漏。**
加完变量构造子就去改求值函数，结果发现：**求值函数的类型签名必须改**
（多一个参数），于是**每一支分支都要改**，而且递归调用里必须把那个解释传下去。
漏传就是类型错误，而报错信息会指向某个你以为没动过的分支。
回去看 L00 §5.3 的 `eval`：它每一支的模式表里都有一个 `i`
（包括用不上它的 `| T, _ => true` 那两支用 `_` 占位），
递归调用写的是 `eval p1 i`——**解释一路传到底**。

**坑 8：变量类型要几个变量？**
命题逻辑那个例子用了固定的三个（`Xvar`、`Yvar`、`Zvar`）。
照抄这个最省事，也最符合「use the same pattern」。
想做得更一般（比如用 `Nat` 当变量下标），可以，但解释函数的类型会跟着变，
而且你得自己处理「没赋值的变量」——**第一次做先照抄固定几个变量的那条路**。

## 12.4 第 4 题：给新东西配例子

> *4. Provide a few examples similar to those above, testing and showing that
> expressions using subtraction, negation, and variables work with usual
> precedence and associativity.*

**题意**：照着上面那些例子（源文件的 `e1`、`e7`、`e3`、`e4` 和那四个验证优先级的
`#eval`，见 §13.4 和 §10.9），给你的减法、取负、变量**各写几个例子**，
证明它们在**通常的优先级和结合性**下工作正常。

**要用的概念，回指：**

| 需要 | 回指 |
|---|---|
| 怎么写语法项的例子、怎么 `#eval` 求值结果 | 本文档 §13.4 |
| 优先级和结合性怎么验证（成对的括号 / 无括号 `#eval` 对比） | 本文档 §10.9 的四条 `#eval` |
| `KNat` 上没有 `BEq`，`#guard` 用不了，怎么断言 | 本文档 §9.4 坑 7、L00 §7.3、§9.3 |

**坑 9：这题考的是「成对对比」，不是「跑一下看看」。**
§10.9 那四条 `#eval` 为什么是四条？因为它用
`ktwo * ktwo + ktwo` 对 `ktwo * (ktwo + ktwo)` 验证「括号真的有用」，
再用 `ktwo + ktwo * ktwo` 对 `ktwo + (ktwo * ktwo)` 验证「不写括号时按谁结合」。
**一条孤立的 `#eval` 证明不了优先级。** 照这个成对的样式写你的例子。

**坑 10：一元减号和二元减号混在一个表达式里时最容易出事。**
`-a - b`、`a - -b`、`-(a - b)` 这几种写法的解析方式不同
（一元和二元是两个不同的记法、两个不同的类，见坑 3）。
而且在截断语义下，有些你以为相等的式子其实不相等（坑 2）。
**所以这题的例子要同时检查两件事：解析成了什么，以及算出来的值对不对。**
把你期望的结果先写在注释里，再跑 `#eval` 核对；
不一致时先怀疑「我对截断语义的理解」，再怀疑代码。

**坑 11：变量的例子必须显式给出解释。**
带变量的表达式**单独没有值**（§3.2）。所以例子要写成
「在解释 `i1` 下，`X + 3` 求值得到几」。少了解释那个参数就根本调不动求值函数。

## 12.5 四道题的依赖关系

四道题是**链式**的，顺序不能乱：

```
第 1 题（KNat 上的 neg / sub 函数 + 实例）
   ↓  第 2 题要调用第 1 题的函数
第 2 题（语法换成 KNat，加 sub / neg 构造子，语义跟着改）
   ↓  第 3 题要在第 2 题的语法上再加构造子
第 3 题（加变量构造子 + 解释 + 求值多一个参数）
   ↓  第 4 题要用第 2、3 题的语言写例子
第 4 题（例子 + 优先级/结合性验证）
```

所以第 1 题没做扎实就往下走，后面每一题都会返工。
特别是**第 3 题会把第 2 题写好的求值函数的签名改掉**——
知道这件事，你就会在写第 2 题时留意别把分支写得太啰嗦。

## 12.6 自检

动手之前，先能回答 §15 自检清单里「作业（二）」那几条。
```


```lean
---

# 13. `Arith`：语法、操作语义、例子

源文件第 276 到 320 行。**这一段不是作业**，照常讲、照常给练习和答案。
（但它是作业第 2、3、4 题要动手改的那段代码，所以要读到能复述为止。）

## 13.1 `end KNat`、`namespace Arith`、`open KNat`
```


end KNat

namespace Arith
open KNat

```lean
三行，每行各做一件事（`namespace` / `open` 的语法见 L00 §6.6、§6.7）：

| 行 | 作用 |
|---|---|
| `end KNat` | 关掉 §4 开的那个 namespace。从这里起，访问里面的东西要写 `KNat.xxx` |
| `namespace Arith` | 开一个新 namespace。下面定义的 `Expr`、`arithEval` 全名都带 `Arith.` 前缀 |
| `open KNat` | 把 `KNat` 里的名字**不带前缀**地放进作用域：`kone`、`add`、`mul`、`toNat`、以及类型 `KNat` 自己 |

`open KNat` 带来的便利是 `kone` 可以直接写；代价是**名字可能和本地的撞车**。
下面 `Expr` 会有一个叫 `add` 的构造子，加上源文件紧接着写的 `open Expr`，
`add` 这个名字就同时有两个候选了。Lean 的处理方式是**重载消解
（overload resolution）**：两个候选都试着 elaborate（细化），哪个类型对就用哪个。

亲眼看一次（下面两条 `#check` 等 `Expr` 定义完才合法，所以放在 §13.4 之后重做一次；
这里先只记住结论）：**实参是 `Expr` 就选 `Expr.add`，实参是 `KNat` 就选 `KNat.add`。**

这件事是作业（二）的坑 5。**便利是真的便利，报错是真的难读。**

## 13.2 Syntax（语法）

源文件标题 `## Syntax`。这是三件套（§3.1）的第一件：**语法是一个 `inductive`**。
```


inductive Expr where
| lit (n : Nat) : Expr
| add (e1 e2 : Expr) : Expr
open Expr

```lean
**第一层：整体。**

定义算术表达式这门小语言的**语法**。一个 `Expr` 要么是一个字面量
（装着一个 `Nat`），要么是两个 `Expr` 的加法。
中文读出来：**表达式要么是字面量，要么是两个表达式相加。**

注意：**这个类型里没有任何计算**。`add (lit 2) (lit 3)` 是一棵**语法树**，
它不等于 5，也不会自己变成 5。它就是数据。要得到 5 得调用求值函数（§13.3）。
这正是 deep embedding（深嵌入，§2.2）的意思。

**第二层：逐 token。**

| token | 角色 |
|---|---|
| `inductive Expr where` | 造类型，全名 `Arith.Expr`（L00 §4.2） |
| `\| lit (n : Nat) : Expr` | 第一个构造子。`(n : Nat)` 是它的字段，装一个库的 `Nat`；`: Expr` 显式写出返回类型 |
| `\| add (e1 e2 : Expr) : Expr` | 第二个构造子。`(e1 e2 : Expr)` 是**两个同类型字段的简写**（等于 `(e1 : Expr) (e2 : Expr)`） |
| 字段类型是 `Expr` | **递归构造子**：`add` 的字段是 `Expr` 自己，所以表达式可以任意嵌套（和 §5 的 `KNat.succ` 同一个道理） |
| `open Expr` | 之后写 `lit`、`add` 可以省掉 `Expr.` 前缀 |

`: Expr` 这段其实可以省（`KNat` 那个就省了，§5）。源文件写出来了，
两种都对，写出来更清楚。

**第三层：对应。**

两个构造子就是这门语言的两条**语法规则**（引入规则）。
能写出来的 `Expr` 只有这两种拼法的组合——这就是源文件 §3.1 说的
*defining the universe of legal terms*（规定什么是合法的句子）。

**第四层：迁移。**

想给这门语言加乘法？加一个构造子 `| mul (e1 e2 : Expr) : Expr`。
想加变量？加一个字段**不是** `Expr` 而是变量类型的构造子——这是作业第 3 题。

## 13.3 Operational Semantics（操作语义）

源文件标题 `## Operational Semantics`。三件套的第三件：**语义是一个函数**。
（第二件语义域是 `Nat`，就是返回类型；本章前 200 行造的 `KNat`
在作业第 2 题里会顶替它。）
```


def arithEval : Expr → Nat
| Expr.lit n => n
| Expr.add e1 e2 => Nat.add (arithEval e1) (arithEval e2)  -- (arithEval e1) + (arithEval e2)

```lean
**第一层：整体。**

把一棵语法树映射成它的含义。类型 `Expr → Nat` 中文读出来：
**吃一个表达式，还一个自然数**。这就是 *denotation（指称）*：
每个语法项的意思是语义域里的一个值。

**第二层：逐 token。**

| token | 角色 |
|---|---|
| `arithEval : Expr → Nat` | 参数在冒号右边，因为要对它做模式匹配（L00 §5.2） |
| `\| Expr.lit n => n` | 基情形。模式要求输入是 `lit` 造的，把它的字段绑定到 `n`；`n : Nat`，所以直接还它 |
| `\| Expr.add e1 e2 => ...` | 递归情形。两个字段绑定到 `e1`、`e2`，**它们都是 `Expr`** |
| `arithEval e1`、`arithEval e2` | 两处**递归调用**：先求两个子表达式的值 |
| `Nat.add` | 把两个结果加起来。这是**库的** `Nat` 加法，不是我们的 `KNat.add`。源文件的注释写明它等价于直接写 `+` |
| 写的是 `Expr.lit` / `Expr.add` 全名 | 虽然上面 `open Expr` 了，源文件在这里仍写全名。原因见 §13.1：`add` 有两个候选，模式位置上写全名最安全 |

**第三层：对应。**

这个函数的结构和语法**一一对应**：

| 语法构造子 | 语义分支 | 做什么 |
|---|---|---|
| `lit n` | `=> n` | 字面量的意思就是它装的那个数 |
| `add e1 e2` | `=> Nat.add (arithEval e1) (arithEval e2)` | 加法的意思是「两个子表达式的意思相加」 |

这叫 **compositional semantics（组合式语义）**：
整体的含义由各部分的含义决定。写求值函数的配方就是：
**对语法的每个构造子写一支，每支里先递归求子表达式的含义，再用语义域里的
对应运算把它们组合起来。**

递归的合法性：`e1`、`e2` 是输入 `Expr.add e1 e2` 的**字段**，结构上更小，
所以递归一定终止（Prereq §2.4）。

**第四层：迁移。**

语法加一个构造子，这里就要加一支。加 `mul` 就加一支调用 `Nat.mul`；
把语义域换成 `KNat` 就把 `Nat.add` 换成 `KNat.add`、返回类型换成 `KNat`
（作业第 2 题）；加变量就要多一个解释参数（作业第 3 题）。

## 13.4 Examples（例子）

源文件标题 `## Examples`。
```


-- examples expressions using our syntax
def e1 : Expr := lit 1
def e7 : Expr := lit 7
def e3 : Expr := add e1 e7
def e4 : Expr :=   -- 7 + (6 + 9)
  add
    (lit 7)
    (add
      (lit 6)
      (lit 9)
    )

#eval arithEval e4      -- 22

```lean
**逐 token 看 `e3` 和 `e4`。**

| token | 角色 |
|---|---|
| `def e1 : Expr := lit 1` | `lit` 是构造子（`Expr.lit` 的短名，靠 `open Expr`），`1` 是它的 `Nat` 字段 |
| `def e3 : Expr := add e1 e7` | `add` 吃两个 `Expr`，这里喂的是前面定义好的两棵树 |
| `e4` 的缩进写法 | 只是排版：`add (lit 7) (add (lit 6) (lit 9))` 换行写而已。括号决定结构，缩进不决定 |

**注意名字**：`e1` 是 `lit 1`，`e7` 是 `lit 7`，但 `e3` 是 `add e1 e7`（值是 8），
`e4` 是 `7 + (6 + 9)`（值是 22）。**名字里的数字不是它的值**，别被带跑。

**`e4` 的求值手工展开**（这是读求值函数的标准练法）：

```
arithEval (add (lit 7) (add (lit 6) (lit 9)))
= Nat.add (arithEval (lit 7)) (arithEval (add (lit 6) (lit 9)))      -- 第二支
= Nat.add 7 (arithEval (add (lit 6) (lit 9)))                       -- 第一支
= Nat.add 7 (Nat.add (arithEval (lit 6)) (arithEval (lit 9)))       -- 第二支
= Nat.add 7 (Nat.add 6 9)                                           -- 第一支两次
= Nat.add 7 15
= 22
```

**现在把 §13.1 说的重载消解看清楚**（`Expr` 和两个 `open` 都齐了）：
```


#check add e1 e7            -- e1.add e7 : Expr      —— 选中了 Expr.add
#check add kone ktwo        -- KNat.add kone ktwo    —— 选中了 KNat.add
#eval toNat (add kone ktwo) -- 3                     —— 真的是 KNat 的加法

```lean
同一个源码里的 `add`，两处落到了**两个不同的函数**上，全靠实参的类型。
第一条的输出被 pretty printer 写成了点记法 `e1.add e7`，它和 `Expr.add e1 e7` 是同一个 term。

**这就是作业（二）坑 5 的全貌**：它平时帮你省字，出错时让报错指向你没想到的那个候选。
源文件的 `arithEval` 之所以通篇写全名，就是这个原因。

## 13.5 回头看三件套

| 三件套 | 本章的实现 | 在哪一节 |
|---|---|---|
| 语法（syntactic specification） | `inductive Expr` | §13.2 |
| 语义域（semantic domain） | `Nat`（作业第 2 题换成 `KNat`） | §13.3 的返回类型 |
| 语义（semantics） | `arithEval : Expr → Nat` | §13.3 |

对照 §3.1 那张表：**现在三件套齐了**。
顺手回答一个开头埋的问题：本章前 200 行造的 `KNat` 和它的五个运算，
在这个三件套里扮演的角色是**语义域**（以及语义里用到的那些运算）。
源文件先造语义域、最后造语法，所以读起来像两章——其实是一件事的两头。
```


end Arith

```lean
`end Arith` 对应第 279 行的 `namespace Arith`，源文件到这里结束（第 320 行）。

## 13.6 本节练习

1. 把 `(7 + 6) + 9` 写成 `Expr`（注意和 `e4` 的区别），求值看是不是也得 22。
   既然值一样，这两棵树是同一个 `Expr` 吗？
2. 定义 `numLits : Expr → Nat`，数一棵表达式树里有几个字面量。
3. 定义 `depth : Expr → Nat`，算一棵表达式树的深度（`lit` 算 1 层）。
4. `arithEval` 里为什么要写 `Expr.lit`、`Expr.add` 全名？不写会怎样？

---

**先自己做，再往下看。**

---

**答案。**
```


namespace Arith
open KNat
open Expr

namespace Answers_13

-- 第 1 题
def e5 : Expr := add (add (lit 7) (lit 6)) (lit 9)

#eval arithEval e5      -- 22，和 e4 一样

-- 但它们不是同一棵树：结构不同
#eval arithEval e4      -- 22

-- 第 2 题：对每个构造子一支；lit 算一个，add 把两边加起来
def numLits : Expr → Nat
| Expr.lit _ => 1
| Expr.add a b => numLits a + numLits b

#eval numLits e4        -- 3

-- 第 3 题：lit 是 1 层；add 是「两边较深的那个 + 1」
def depth : Expr → Nat
| Expr.lit _ => 1
| Expr.add a b => 1 + max (depth a) (depth b)

#eval depth e4          -- 3
#eval depth e5          -- 3

end Answers_13
end Arith

```lean
**第 1 题**：值一样，树不一样。`e4` 是 `add (lit 7) (add (lit 6) (lit 9))`，
`e5` 是 `add (add (lit 7) (lit 6)) (lit 9)`。
**加法的结合律是语义域（`Nat`）里的性质，不是语法里的性质**——
两棵不同的语法树可以有相同的含义。
这件事在作业第 4 题（验证结合性）里很关键：
`#eval` 看到的是**语义**，相等的值不等于相同的语法。

**第 2、3 题**的配方和 `arithEval` 完全一样：
**对语法的每个构造子写一支，递归处理子表达式，再把结果组合起来。**
不同的只是「组合」用的运算：`arithEval` 用加法，`numLits` 用加法但基情形是 1，
`depth` 用 `max` 再加一。
这说明求值函数不是唯一能对 `Expr` 写的函数，**它只是「组合式地处理语法树」
这个模式的一个实例**。

**第 4 题**：因为 `open KNat` 和 `open Expr` 都在作用域里，`add` 有两个候选（§13.1）。
在**模式**位置上，Lean 需要知道模式属于哪个类型才能检查穷尽性，
歧义会让报错变得难读（L00 §5.3 的末尾记过同类情形：
命题逻辑那个例子里 `And`、`Or`、`Not` 也必须写全名，否则 Lean 报
`ambiguous pattern, use fully qualified name`）。
写全名是最省事的防御。
```


```lean
---

# 14. 本章速查表

## 14.1 看到这种题，就按这个配方写

**（甲）在一个递归 inductive 类型上写「迭代低一级运算」的函数**（§8.4）：

```
def f : T → T → T
| a, T.zero    => base            -- base 要自己推：「作用 0 次时该是什么」
| a, T.succ b  => g (f a b) a     -- g 是紧挨着的低一级函数；递归结果在哪一侧要想清楚
```

三个必答问题：**对哪个参数递归？基值是什么？步进用哪个低一级函数？**

**（乙）让自己的类型支持某个记法**（§10.7）：

```
instance : 类名 你的类型 where
  字段名 := 你的实现
```

三个必查项：**类名、字段名、字段的类型签名**。查法见 14.4。

**（丙）写一个「任何类型都行，只要它有某种能力」的函数**（§11）：

```
def f {α : Type} [类名 α] : α → α → α
| a, b => 用记法或 类名.字段名 a b
```

**（丁）把一门语言深嵌入 Lean**（§13、§3.1）：

| 要素 | 写成 |
|---|---|
| 语法 | 一个 `inductive`，每条语法规则一个构造子，子表达式是递归字段 |
| 语义域 | 一个类型（求值函数的返回类型） |
| 语义 | 一个函数，**对语法的每个构造子一支**，递归求子表达式再组合 |
| （有变量时）解释 | 一个 `变量类型 → 语义域` 的函数，当求值函数的额外参数**一路传下去** |

## 14.2 五个运算并排（§8.4 的压缩版）

| 函数 | 递归在 | 基值 | 步进 | 迭代读法 |
|---|---|---|---|---|
| `inc` | 不递归 | —— | 构造子 `succ` | succ 一次 |
| `dec` | 不递归 | `kzero`（截断） | —— | 反方向，不在阶梯上 |
| `add a b` | 第二参数 | `a` | `inc` | 对 `a` 做 `b` 次 `inc` |
| `mul a b` | 第二参数 | `KNat.zero` | `add` | 把 `a` 加 `b` 次 |
| `exp a b` | 第二参数 | `kone` | `mul` | 把 `a` 乘 `b` 次 |

**基值三层三个样，这是最容易错的一栏。**

## 14.3 字面量和记法的解析链（§10.8）

| 你写的 | 展开成 | 需要的实例 | 经过的桥 | 最终落到 |
|---|---|---|---|---|
| `0` | `OfNat.ofNat 0` | `OfNat α 0` | `Zero.toOfNat0` | `Zero` 实例里的值 |
| `1` | `OfNat.ofNat 1` | `OfNat α 1` | `One.toOfNat1` | `One` 实例里的值 |
| `2`、`3`… | `OfNat.ofNat 2` … | `OfNat α 2` … | **没有桥** | **报错**（§10.11） |
| `a + b` | `HAdd.hAdd a b` | `HAdd α α α` | `instHAdd` ← `Add α` | `Add` 实例里的函数 |
| `a * b` | `HMul.hMul a b` | `HMul α α α` | `instHMul` ← `Mul α` | `Mul` 实例里的函数 |
| `a ^ b` | `HPow.hPow a b` | `HPow α β α` | ← `Pow α β` | `Pow` 实例里的函数 |

优先级：`^` > `*` > `+`（§10.9，完整的表见 L00 §10.2）。

## 14.4 查库用的命令

| 想知道 | 命令 | 例子 |
|---|---|---|
| 这个类有哪些字段、字段什么类型 | `#print 类名` | `#print Add` |
| 某个字段的完整签名（含隐式参数） | `#check @类名.字段名` | `#check @Add.add` |
| 这个类型**有没有**某个实例、实例叫什么 | `#synth 类名 类型` | `#synth Add Rat` |
| Lean 到底把我的代码细化成了什么 | `set_option pp.explicit true in #check ...` | §10.8 |
| 一个 term 算出来是什么 | `#eval` | L00 §2.2 |
| 把报错钉在源码里 | `#guard_msgs` | §10.11、§11.2 |

## 14.5 本章新出现的写法（L00 里没有的）

| 写法 | 作用 | 本文档 |
|---|---|---|
| `instance : C T where 字段 := 实现` | 给类型 `T` 填类 `C` 的表 | §10.2 |
| `local instance` | 只在当前 namespace / section 内有效的实例 | §10.11 答案 |
| `#synth C T` | 查实例是否存在及其名字 | §11.1 |
| `set_option pp.explicit true in` | 打印隐式参数和实例 | §10.8 |
| `_a` 这种下划线开头的参数名 | 匹配但声明「我知道它没用到」 | §8.2 |
| `#eval` 对没有 `Repr` 的类型 | 退回打印构造子全名 | §10.8 |
```


```lean
---

# 15. 做作业前的自检清单

**用法**：动手写每一题之前，先看对应那组问题，逐条在心里（或嘴上）答一遍。
有一条答不上来，就回到括号里标的那一节重读，别急着写代码。
答得上来再写，能省掉大半返工。

## 15.1 共通（两处作业都要先过这几条）

1. `KNat` 有几个构造子？分别是什么？`KNat.succ` 的字段类型是什么？（§5）
2. 一个递归函数被 Lean 接受，需要什么条件？`add` 里哪个参数在变小？（§8.1、Prereq §2.4）
3. 「基值 + 步进」里的三个必答问题是哪三个？（§8.4）
4. `dec kzero` 等于几？为什么不是负数？这件事对减法意味着什么？（§7.2）
5. `instance : C T where ...` 里，`:=` 左边写的是什么名字，右边写的是什么？（§10.4、§10.5）
6. 给定一个类名，你能用哪三条命令查出它的字段名、字段类型、以及某类型有没有实例？（§14.4）
7. `failed to synthesize instance of type class` 这个报错说的是什么没找到？
   它发生在编译期还是运行期？（§10.11、§11.2）
8. `(2 : KNat)` 为什么报错，而 `(1 : KNat)` 不报？（§10.3、§10.11）
9. `KNat` 没有 `BEq`，你要怎么断言两个 `KNat` 相等？（§9.4 坑 7）
10. 看到一屏 `KNat.KNat.succ`，你有什么办法读得清楚些？（§6.1、§10.8）

## 15.2 作业（一）之 `tet`

写 `tet` 之前你应该能回答：

1. tetration 是「把哪个运算重复」？重复几次？次数由哪个参数决定？（§9.2、§8.5）
2. `add`、`mul`、`exp` 三个基值分别是什么？它们为什么各不相同？（§8.4、§8.2）
3. **`tet` 的基值你定成什么，理由是什么？**（§9.4 坑 1）
   —— 这一条要能用一句话说清「作用 0 次时结果该是什么」。
4. 步进函数是哪一个？它必须已经存在吗？（§8.4 第 3 条）
5. 递归结果应该放在步进函数的左边还是右边？为什么这件事对 `exp` 之上的层级
   比对 `mul` 更要紧？（§9.4 坑 3）
6. 你打算用哪两个小输入测试？为什么不能用大的？（§9.4 坑 6）
7. 你要怎么写断言（`rfl` 还是转成 `Nat` 再 `#guard`）？（§9.4 坑 7）

## 15.3 作业（一）之 `hyperop`

1. `hyperop` 吃几个参数？第一个参数叫什么、是什么意思？（§9.2）
2. 你选哪套层级编号？在你的编号里，第 0、1、2、3、4 级分别是什么运算？（§9.5）
3. 在你的编号里，`tet a b` 等于 `hyperop 几 a b`？这和题目给的约束一致吗？（§9.5）
4. depth 参数的类型你选 `Nat` 还是 `KNat`？选了之后 `hyperop 4 a b` 里的 `4` 怎么写？（§9.4 坑 4）
5. 基情形有几个？分别在什么条件下触发、各返回什么？（§9.4 坑 2）
6. 低层级（第 0、1 级）那个「多余」的值参数怎么处理？你的说法是什么？（§9.5 最后一段）
7. 如果 Lean 报 `fail to show termination`，你准备怎么分析？
   是哪些参数在按什么顺序下降？（§9.4 坑 5）
8. 你要用哪几条断言证明「`hyperop` 的某一级真的等于 `add` / `mul` / `exp` / 你的 `tet`」？（§9.5 第 3 条）

## 15.4 作业（二）第 1 题（取负和减法）

1. 这题要交三样东西，是哪三样？（§12.1）
2. 取负是几元运算？减法是几元？它们的类的字段类型分别长什么样？（§12.1 坑 3）
3. `KNat` 里能表示负数吗？所以 `neg` 你定成什么？理由写在哪里了？（§12.1 坑 1）
4. 库里的 `Nat` 面对 `3 - 5` 给出什么？你跑过 `#eval (3 : Nat) - 5` 了吗？（§12.1 坑 1）
5. 截断之后，哪些等式**不再**成立？你的测试里有没有不小心写了这种等式？（§12.1 坑 2、§7.3 第 3 题）
6. `-a` 和 `a - b` 用的是同一条实例吗？（§12.1 坑 3）
7. 你的 `sub` 对哪个参数递归？基值是什么？步进用的是哪个已有函数？（§8.4）

## 15.5 作业（二）第 2 题（语言换成 KNat 并扩展）

1. 深嵌入三件套分别是哪三样？在源文件里各是哪段代码？（§3.1、§13.5）
2. 这题要改的是**几个**地方？分别是什么？（§12.2）
3. 取负的构造子带几个子表达式字段？减法带几个？（§12.2）
4. 求值函数的返回类型要改成什么？新增的每支分支里调用的是谁？（§12.2、§13.3）
5. 换成 `KNat` 之后，`lit 7` 里那个 `7` 怎么写？你选了三条路里的哪一条？（§12.2 坑 6）
6. 为什么 `arithEval` 通篇写 `Expr.add` 全名而不写 `add`？（§13.1、§12.2 坑 5）
7. 组合式语义的配方是什么？（§13.3 第三层）

## 15.6 作业（二）第 3 题（变量）

1. 老师让你照着哪个例子做？那个例子在哪？（§12.3，L00 §5.3）
2. 加变量要动**四**件事，是哪四件？（§12.3）
3. 解释（interpretation）的类型在你的语言里是什么？（§3.2、§12.3）
4. 带变量的表达式单独有值吗？为什么求值函数必须多一个参数？（§3.2）
5. 求值函数的**每一支**都要有解释参数吗？递归调用里要不要传它？（§12.3 坑 7）
6. 你的变量类型有几个变量？（§12.3 坑 8）

## 15.7 作业（二）第 4 题（例子）

1. 要验证优先级，为什么一条 `#eval` 不够？成对对比怎么写？（§12.4 坑 9、§10.9）
2. 你的例子覆盖了减法、取负、变量**三样**吗？（§12.4）
3. 一元减号和二元减号混写时有哪些容易出错的组合？（§12.4 坑 10）
4. 带变量的例子里，解释是哪个？你显式给了吗？（§12.4 坑 11）
5. 两棵不同的语法树可以求出相同的值吗？这对「验证结合性」意味着什么？（§13.6 第 1 题答案）
6. 期望值你是先写在注释里再跑，还是跑完再说「这就是对的」？（§12.4 坑 10）

## 15.8 交之前最后看一眼

1. `lean Study/HW_E10.lean` 真的编译通过了吗？（有 `sorry` 的话，警告在哪一行？）
2. 每个新定义是不是至少有一条 `#eval` 或 `example ... := rfl` 验证过？
3. 你为「设计选择」（取负的语义、层级编号、depth 的类型）写注释了吗？
   这些地方没有唯一答案，**写下你的选择就是答案的一部分**。
```


```lean
---

# 16. 术语表

| English | 中文 | 一句话解释 |
|---|---|---|
| typeclass | 类型类 | 一张接口表：规定「想算作某种能力，必须提供哪些字段」 |
| instance | 实例 | 给某个具体类型把那张表填好；填进去的是**数据**（函数或值） |
| field | 字段 | 表里的一项，比如 `Add` 的 `add`、`Zero` 的 `zero` |
| instance resolution | 实例解析 | Lean 在编译期自动去实例库里找所需实例的过程 |
| operator overloading | 运算符重载 | 同一个记法（`+`）在不同类型上落到不同函数 |
| type guard | 类型守卫 | 参数表里的 `[C α]`：接受任何类型，但要求它有 `C` 的实例 |
| instance-implicit argument | 实例隐式参数 | 写成 `[C α]` 的参数，由实例解析自动填上 |
| polymorphic function | 多态函数 | 带类型参数、对多种类型都能用的函数 |
| overload resolution | 重载消解 | 一个名字有多个候选时，Lean 试着 elaborate，按类型挑中一个 |
| numeral / `OfNat` | 数字字面量 | 源码里的 `0`、`1`、`2`…；经 `OfNat` 实例决定它在某类型上是什么 |
| precedence | 优先级 | 谁结合得更紧，`^` > `*` > `+` |
| associativity | 结合性 | 同优先级的运算从左还是从右结合 |
| recursor | 递归子 | `inductive` 自动生成的 `T.rec`，所有 `match` 最终编译成它 |
| structural recursion | 结构递归 | 递归调用的参数在结构上更小，因此一定终止 |
| total function | 全函数 | 对每个输入都有结果，不崩不死循环；Lean 只接受全函数 |
| base case | 基情形 | 递归定义里不再递归的那一支，返回的值叫**基值** |
| step function | 步进函数 | 非基情形里被调用的那个低一级的函数 |
| truncation | 截断 | 算不出来就停在边界，比如零的前驱定义为零 |
| unary representation | 一元表示 | 数 `n` 用 `n` 层 `succ` 表示，`KNat` 和库的 `Nat`（概念上）都是 |
| arity | 元数 | 一个运算吃几个参数；取负一元、减法二元 |
| hyperoperation | 超运算 | 「后继、加、乘、乘方、幂塔…」这条每层都是「重复下一层」的阶梯 |
| tetration | 迭代幂次 / 幂塔 | 超运算阶梯上乘方之上的那一层：把乘方重复若干次 |
| deep embedding | 深嵌入 | 把一门语言的语法表示成 Lean 的 `inductive`，含义由求值函数给出 |
| syntactic specification | 语法规定 | 哪些项是这门语言的合法句子；在 Lean 里是一个 `inductive` |
| semantic domain | 语义域 | 含义所在的那个值的世界；在 Lean 里就是一个类型 |
| semantics | 语义 | 从语法到语义域的映射；在 Lean 里是一个函数 |
| denotation | 指称 | 一个语法项在语义域里对应的那个值 |
| compositional semantics | 组合式语义 | 整体的含义由各部分的含义组合而成 |
| interpretation | 解释 | 把每个变量映射到语义域里一个值的函数 |
| variable expression | 变量表达式 | 语法里的一个构造子，自己没有值，要在某个解释下才有 |
| pretty printer | 美化打印器 | Lean 把内部 term 显示成源码样子的那一步；会省略能省的前缀 |

---

# 结语

这一章的两条主线，各用一句话收尾：

1. **算术是一条阶梯**。后继、加、乘、乘方是同一个形状的四层，
   每层「把下一层重复 b 次」。写新的一层只要回答三个问题：
   对哪个参数递归、基值是什么、步进用哪个低一级的函数。
2. **记法不属于类型，属于实例**。`0`、`1`、`+`、`*`、`^` 都是先展开成某个类的
   字段调用，再由实例解析决定落到哪个函数上。
   所以「让我的类型支持 `+`」这件事，做法永远是：查类名、查字段名、填一条 `instance`。

作业要你做的，就是把这两条各往前推一步：阶梯往上加一层（甚至写成通用的那一层），
记法再挂两条（取负和减法），然后把这套东西接进一门有语法、有语义、有变量的小语言里。

卡住的时候，先回 §15 的清单找你答不上来的那一条。
```


<div class="issue-box">📝 <a href="https://github.com/kevinsullivan/Lean4CS1/issues/new">Report an issue</a> with this section</div>

