/- @@@
# L00：Lean 4 语法解剖（中文详解）

- **讲解对象**：不是某一份源文件，而是 `FPCourse/ClassNotes/` 下 E 系列文件
  实际用到的全部 Lean 语法。
- **取材来源**：`FPCourse/T01_ExpressionsFunctionsRecursion/W00` 到 `W02`、
  `ProgrammingWithTypes/C01` 到 `C05`、`FPCourse/ClassNotes/` 全部文件。
- **基于 upstream commit**：`e39df37`（2026-10-07）
- **初稿日期**：2026-10-14　**修订日期**：2026-10-21（按 `Study/L00_review.md` 重排）
- **编译**：本文件不 `import` 任何东西，在容器内仓库根目录执行
  `lean Study/L00_Syntax_zh.lean`，几秒出结果。
- **生成预览**：`python3 scripts/convert.py Study/L00_Syntax_zh.lean Study/L00_Syntax_zh.md`

---

# 1. 导读

## 1.1 这份文档是什么，怎么读

它**不是**另一本教材，是一份「看到符号知道它是什么」的对照手册。
读 E 系列文件时遇到不认识的写法，回到这里按编号查。
每一项都配一个最小可运行的例子。

讲证明内容的是 E 系列的详解文档，这一份只管语法。
所以这里出现的命题例子都是最小的，目的只是让你认得那个符号。

**怎么读**：两个窗口并排。

- 左边开 `Study/L00_Syntax_zh.md` 的 Markdown 预览（VS Code 里 `Ctrl+Shift+V`）。
  标题、表格、代码高亮都渲染出来，侧边 Outline 面板就是目录，当书看。
- 右边开 `Study/L00_Syntax_zh.lean`。光标放到任何一行代码上，
  infoview 会显示那一行的类型和（在证明里）当前目标。想改点什么试试就直接改。
- `.md` 是生成物，不要手改。改了 `.lean` 就重新跑一遍 `scripts/convert.py`。

每一节末尾有练习，**答案紧跟在练习后面**，中间有一条分隔线。
看到分隔线先停下来自己做。

## 1.2 怎么读一段 Lean 代码：三层拆法

这份文档里每个例子都按下面三层拆。自己读 E 文件时也按这三层走。

1. **整体**：这段在定义什么、或者在证明什么？把类型签名用中文读出来。
2. **逐 token**：每个符号扮演什么角色？哪个是被绑定的变量名、它的类型是什么、
   哪个是 constructor（构造子）、哪个是函数应用、哪个是模式匹配的分支、
   `=>` 左右各是什么、隐式参数在哪里被自动填上了。
3. **逻辑对应**：这一步用的是哪条规则（哪个类型的 introduction rule（引入规则）
   还是 elimination rule（消去规则））？这一步之后目标变成了什么？

然后第四步是**迁移**：换成一道同类的题，哪些地方会变、哪些地方不变。

## 1.3 一条贯穿全文的主线

Lean 里只有一种东西：**term（项）**。每个 term 有一个 **type（类型）**。
写 `e : T` 读作「`e` 的类型是 `T`」。

这句话有两种读法，而且**同时成立**：

- 计算的读法：`T` 是一个数据类型，`e` 是它的一个**值**。
- 逻辑的读法：`T` 是一个命题，`e` 是它的一个**证明**。

所以「有没有证明」这个问题，就是「这个类型有没有值」。
这叫 inhabited（有值的 / 可居留的）。一个命题为真，就是它作为类型**有值**；
为假，就是它**没有值**。

前六节只用第一种读法，第 7 节开始用第二种。两种读法用的是同一套语法。

## 1.4 这个文件本身的格式

**注释**。`--` 到行尾是单行注释。`/-` 到 `-/` 是块注释，**可以嵌套**
（嵌套注释掉一大段代码时很方便）。
@@@ -/

-- 这是单行注释
/- 这是块注释 -/
/- 外层 /- 内层 -/ 还是外层 -/

/- @@@
**文学化块**。课程文件（包括这一份）是 **literate Lean（文学化 Lean）**：
散文写在注释块里，代码裸写在块外。`@@@` 是课程的书本生成工具用的标记，
它告诉工具「这一段注释是正文，请排版成 Markdown」。
`scripts/convert.py` 认的就是这个标记。

对 Lean 来说两种写法**都只是注释**，`@@@` 没有任何语法意义：

- `/- @@@ ... @@@ -/`：普通块注释。ClassNotes 的 E 文件和这份文档用这种。
- `/-! @@@ ... @@@ -/`：module docstring（模块文档串）。
  以 `/-! ... -/` 形式写的注释，Lean 会存进文档数据库。教材 W 章节用这种。

区别只在 Lean 是否把内容记为文档，对编译结果没有影响。

## 1.5 目录

| 节 | 内容 |
|---|---|
| 1 | 导读 |
| 2 | 值和类型：`#check`、`#eval`、`def` |
| 3 | 函数：`fun`、柯里化、`→` |
| 4 | 类型：`inductive`、`structure`、基本类型、`×` 和 `⊕` |
| 5 | 模式匹配：`match`、`⟨⟩`、投影、`if`、`nomatch` |
| 6 | 定义进阶和作用域：`abbrev`、`let`、`where`、隐式参数、`namespace` |
| 7 | 命题与证明：`=`、`→`、`∀`、`∧`、`∨`、`∃`、`¬`、`↔` |
| 8 | term 模式和 tactic 模式 |
| 9 | 命令补遗：`#print`、`#guard`、`#guard_msgs` |
| 10 | 自定义记法（读 E02 之前再看） |
| 11 | `Decidable` 与 `Classical` |
| 12 | 速查表 |
| 13 | 术语表 |
@@@ -/

/- @@@
---

# 2. 值和类型

这一节只有三件事：问一个 term 的类型、问它的值、给它起名字。
全部例子只用数字、字符串、布尔值，不出现箭头类型，也不出现命题。
@@@ -/

namespace S2

/- @@@
## 2.1 `#check`：问「这个 term 的类型是什么」

`#check e` 不计算 `e`，只报告它的类型。输出形式是 `e : T`，
读作「`e` 的类型是 `T`」。
@@@ -/

#check 42                 -- 42 : Nat
#check "hello"            -- "hello" : String
#check true               -- Bool.true : Bool
#check 'x'                -- 'x' : Char

/- @@@
第三行输出的是 `Bool.true` 而不是 `true`：`true` 的**全名**是 `Bool.true`，
Lean 显示时用全名。名字带前缀这件事在 §6.6 讲。

**type ascription（类型标注）**。`(e : T)` 这种带括号的写法的意思是
「我声明 `e` 的类型是 `T`，你去检查」。
一个字面量可以属于多个类型时，必须这样说清楚：
@@@ -/

#check (42 : Nat)
#check (42 : Int)
#check (42 : Float)

/- @@@
类型对不上时 Lean 在程序跑起来之前就拒绝。下面这行取消注释会报错：
@@@ -/

-- #check ("hello" : Nat)

/- @@@
## 2.2 `#eval`：问「这个 term 算出来是什么」

`#eval e` 把 `e` 一步一步**归约（reduce）**，直到不能再归约，报告那个结果，
叫 **normal form（范式）**。

`#check` 看类型，`#eval` 看值。两者问的是完全不同的问题。
@@@ -/

#eval 2 + 3               -- 5
#eval 2 + 3 * 4           -- 14，不是 20：`*` 比 `+` 结合得紧
#eval (2 + 3) * 4         -- 20
#eval 10 - 3              -- 7
#eval true && false       -- false
#eval !true               -- false
#eval "hello" ++ ", world"
#eval "hello".length      -- 5

/- @@@
有一行值得单独看：
@@@ -/

#eval (3 - 10 : Nat)      -- 0，不是 -7

/- @@@
`Nat` 是自然数，**没有负数**。所以减法在 0 处**截断**：
`3 - 10` 必须是一个 `Nat`，而 `-7` 不是，于是结果是 `0`。
这不是 bug，是类型决定的。想要负数就用 `Int`：
@@@ -/

#eval (3 - 10 : Int)      -- -7

/- @@@
## 2.3 `def`：给一个值起名字

最简单的形式没有参数，就是「给一个值起名字」。
这个名字**一旦绑定就永不改变**——这门语言里没有赋值这回事，
所以也就没有「这个变量现在到底是什么值」这一类 bug。
@@@ -/

def answer : Nat := 42
def greeting : String := "hello"

#eval answer
#eval answer * 2
#eval greeting ++ ", " ++ greeting

/- @@@
**逐 token 拆 `def answer : Nat := 42`**。所有定义都是同一个形状，
认出这几个槽位，任何一条定义就读懂了一半：

| token | 槽位 | 角色 |
|---|---|---|
| `def` | 关键字 | 宣布「我要定义一个东西」 |
| `answer` | 名字 | 新名字 |
| （这里是空的） | 参数表 | 没有参数 |
| `: Nat` | 类型 | 类型标注，你对 Lean 做的声明，它会去检查 |
| `:=` | | 「定义为」 |
| `42` | 体（body） | 一个类型为 `Nat` 的 term |

类型标注可以省略，Lean 大多能推断出来。但写出来更好：
写出来等于你在**提出一个主张**，让机器核对你的主张，
正是类型系统替你干活的地方。

## 2.4 `def`：带参数就是函数

参数写在**名字和冒号之间**，填上刚才那个空着的槽位。
@@@ -/

def double (n : Nat) : Nat := n * 2
def add (a b : Nat) : Nat := a + b
def shout (s : String) : String := s ++ "!"

#eval double 21
#eval add 3 4
#eval shout "hello"

/- @@@
**逐 token 拆 `def add (a b : Nat) : Nat := a + b`**：

- `(a b : Nat)`：**一次声明两个同类型的参数**。同类型的参数写在一起更清楚，
  这是 E 文件里的常见写法。
- 第二个 `: Nat` 是**返回类型**。
- `a + b` 是体，里面可以用参数名 `a`、`b`。

调用的写法是 **名字、空格、实参**，不要括号：`add 3 4`。
括号在 Lean 里只表示**分组**。这件事 §3.3 细讲。

`#check` 一个带参数的定义，显示的是**签名形式**——参数照原样列在冒号左边：
@@@ -/

#check answer             -- S2.answer : Nat
#check double             -- S2.double (n : Nat) : Nat
#check add                -- S2.add (a b : Nat) : Nat

/- @@@
输出里的 `S2.` 是 namespace 前缀（§6.6），现在不用管。

## 2.5 本节练习

**[2.1]（判）** 下面两条命令，哪一条输出 `0`，哪一条输出 `3 - 10 : Nat`？为什么？

```lean
#check (3 - 10 : Nat)
#eval  (3 - 10 : Nat)
```

**[2.2]（写）** 定义一个函数 `triple`，接受一个 `Nat`，返回它的 3 倍；
再定义一个常量 `def seven : Nat := 7`，然后 `#eval triple seven`。

**[2.3]（读）** 指出 `def shout (s : String) : String := s ++ "!"`
的五个槽位：关键字、名字、参数表、返回类型、体。

**[2.4]（判）** `#eval (5 - 8 : Nat)` 和 `#eval (5 - 8 : Int)` 输出一样吗？
是什么让它们不一样？

---

**先自己做，再往下看。**

---
@@@ -/

namespace Answers_2

/- @@@
**[2.1]** `#eval` 输出 `0`，`#check` 输出 `3 - 10 : Nat`。
`#eval` 问「算出来是什么」，`#check` 问「类型是什么」，两个问题不同（§2.1、§2.2）。
@@@ -/

#check (3 - 10 : Nat)
#eval  (3 - 10 : Nat)

/- @@@
**[2.2]** 思路：参数写在名字和冒号之间（§2.4）。
@@@ -/

def triple (n : Nat) : Nat := n * 3
def seven : Nat := 7

#eval triple seven        -- 21

/- @@@
**[2.3]**

| 槽位 | 内容 |
|---|---|
| 关键字 | `def` |
| 名字 | `shout` |
| 参数表 | `(s : String)` |
| 返回类型 | `String`（第二个冒号后面那个） |
| 体 | `s ++ "!"` |

**[2.4]** 不一样：`Nat` 版输出 `0`（截断），`Int` 版输出 `-3`。
`Nat` 没有负数，所以会往下溢出的减法停在 `0`；`Int` 有负数（§2.2）。
@@@ -/

#eval (5 - 8 : Nat)       -- 0
#eval (5 - 8 : Int)       -- -3

end Answers_2
end S2

/- @@@
---

# 3. 函数

上一节的 `def double (n : Nat) : Nat := n * 2` 已经是一个函数了，
但我们还没看过函数**本身**长什么样：它的类型怎么写、
不起名字怎么写、多个参数到底是怎么回事。这一节补上。

（函数还有第二种读法——「`P → Q` 的证明就是一个函数」。那是 §7.4 的事，
这一节先只按「从输入算出输出」来理解。）
@@@ -/

namespace S3

/- @@@
## 3.1 `fun x => ...`：匿名函数

`fun` 造一个函数**值**，不需要名字。读作「给我一个 `x`，我还你 `...`」。
`=>` 左边是**被绑定的参数名**，右边是**体**。
@@@ -/

def double : Nat → Nat := fun n => n * 2
def negate : Bool → Bool := fun b => !b

#eval double 21
#eval negate true

/- @@@
注意这里 `double` 的写法和 §2.4 的不一样：

```lean
def double (n : Nat) : Nat := n * 2      -- §2.4：参数在冒号左边
def double : Nat → Nat := fun n => n * 2 -- §3.1：参数在体里用 fun 绑定
```

**两者定义的是同一个函数**，区别只在「名字在哪里被绑定」。
E 文件在这两种写法之间来回切换，两种都得认得。
它们之间有一条影响模式匹配的硬规则，见 §5.2。

`Nat → Nat` 就是「从 `Nat` 到 `Nat` 的函数」这个**类型**。
`→` 读作「到」或者「箭头」。

参数名是局部的，出了这个 `fun` 就没有意义。参数也可以标注类型，
写成 `fun (n : Nat) => ...`。

多个参数用空格隔开列在 `=>` 左边，这等价于嵌套的 `fun`：
@@@ -/

def add3  : Nat → Nat → Nat → Nat := fun a b c => a + b + c
def add3' : Nat → Nat → Nat → Nat := fun a => fun b => fun c => a + b + c

#eval add3 1 2 3
#eval add3' 1 2 3

/- @@@
**用不到的参数写 `_`**。`_` 在这里表示「我故意不给它名字」，
这样 Lean 就不会警告「这个参数没用上」：
@@@ -/

def alwaysZero : Nat → Nat := fun _ => 0

#eval alwaysZero 999

/- @@@
还有一个相关的记号，E 文件里常见：**参数名前面加一个下划线**，
比如 `(_h : ...)`。`_h` 是一个**真的名字**（可以在体里用），
但前导下划线告诉 Lean「我知道它可能没被用到，别警告我」。
@@@ -/

def ignoreSecond (n : Nat) (_m : Nat) : Nat := n

#eval ignoreSecond 5 99   -- 5

/- @@@
## 3.2 多参数就是柯里化

这件事必须真正吃进去，不然 `#check` 的输出会看不懂。

上面写了 `add3 : Nat → Nat → Nat → Nat`，一眼看去像「三个 Nat 进、一个 Nat 出」。
不是。`→` 是**右结合**的，所以这个类型的意思是：

```text
Nat → (Nat → (Nat → Nat))
```

一个接受**一个** `Nat`、返回**一个函数**的函数。

**这门语言里没有多参数函数**，只有「接受一个参数、返回函数的函数」。
这叫 **currying（柯里化）**。
@@@ -/

def add (a b : Nat) : Nat := a + b

#check add                -- 签名形式：S3.add (a b : Nat) : Nat
#check (add)              -- 箭头形式：Nat → Nat → Nat

#eval add 3 4             -- 7
#eval (add 3) 4           -- 7，完全一样：`add 3` 本身就是一个 Nat → Nat

/- @@@
加括号的 `#check (add)` 会显示**箭头形式**，柯里化看得最清楚。
不加括号显示**签名形式**，参数照原样列出来。同一个东西的两种显示。

只给一部分参数叫 **partial application（偏应用）**。
它返回一个函数，可以起名字复用：
@@@ -/

def addThree := add 3              -- 只给一个参数

#check (addThree)         -- Nat → Nat —— 还差一个参数
#eval addThree 7          -- 10

def sum := add 3 4                 -- 给满两个参数，就是一个 Nat 了

#check sum                -- Nat
#eval sum                 -- 7

/- @@@
库函数也一样。`Nat.add` 就是加法：
@@@ -/

#check (Nat.add)          -- Nat → Nat → Nat
#check (Nat.add 3)        -- Nat → Nat —— 给一个参数，剩一个函数
#eval Nat.add 3 4         -- 7

/- @@@
## 3.3 应用就是空格，而且结合得最紧

函数应用的写法是 **函数、空格、实参**。不写括号。
括号在 Lean 里只表示**分组**，不表示「这是一次调用」。

而且应用比**任何**中缀运算符结合得紧：
@@@ -/

#eval double 5            -- 10
#eval double (5 + 1)      -- 12：括号让 5 + 1 先算，实参是 6
#eval double 5 + 1        -- 11：读成 (double 5) + 1

/- @@@
多参数时也一样，应用从左往右一个一个吃：
`f 0 1 2` 读成 `(((f 0) 1) 2)`。
@@@ -/

def f : Nat → Nat → Nat → Nat := fun _ _ _ => 0

#check (((f 0) 1) 2)      -- 和 f 0 1 2 完全一样
-- #check (f 0 (1 2))     -- 这个不行：(1 2) 是把 1 当函数应用到 2 上

/- @@@
## 3.4 `→` 右结合的后果：高阶函数

`→` 右结合这件事读类型时会咬人：

- `Nat → Nat → Nat` 是 `Nat → (Nat → Nat)`。
- `(Nat → Nat) → Nat` 是**完全不同**的类型。

后者的**参数本身是一个函数**，这叫 **higher-order function（高阶函数）**。
括号在这里是必须的：不加括号就变成前者了。
@@@ -/

def twice (g : Nat → Nat) (n : Nat) : Nat := g (g n)

#check (twice)            -- (Nat → Nat) → Nat → Nat
#eval twice double 5      -- 20：double 5 = 10，double 10 = 20
#eval twice (fun n => n + 3) 1   -- 7

/- @@@
读 `(Nat → Nat) → Nat → Nat`：第一个参数是函数 `Nat → Nat`，
第二个参数是 `Nat`，返回 `Nat`。注意只有**第一对**括号是必须的，
后面的 `Nat → Nat` 本来就右结合。

（`→` 在**命题**里也会因为右结合咬人，而且和 `∀` 的优先级关系更容易搞混。
那个坑在 §7.8 讲，到那里再说。）

## 3.5 本节练习

**[3.1]（读）** 下面三个类型，分别说出：它接受几个参数、每个参数的类型是什么、
最后返回什么。注意第二个和第三个的区别。

```lean
Nat → Nat → Nat
(Nat → Nat) → Nat
Nat → (Nat → Nat)
```

**[3.2]（写）** 用 `fun` 写一个 `applyTwice : (Bool → Bool) → Bool → Bool`，
把第一个参数作用两次。然后 `#eval applyTwice (fun b => !b) true`。

**[3.3]（判）** `#eval double 5 + 1` 输出 `11`，`#eval double (5 + 1)` 输出 `12`。
用一句话说出这是哪条规则造成的。

**[3.4]（写）** 定义 `addTen := add 10`（偏应用，不要写 `fun`），
然后 `#check (addTen)` 和 `#eval addTen 5`。说出 `addTen` 的类型为什么是 `Nat → Nat`。

---

**先自己做，再往下看。**

---
@@@ -/

namespace Answers_3

/- @@@
**[3.1]**

- `Nat → Nat → Nat`：读成 `Nat → (Nat → Nat)`。接受**一个** `Nat`，
  返回一个还要一个 `Nat` 的函数。一共吃两个 `Nat`，最后给一个 `Nat`（§3.2）。
- `(Nat → Nat) → Nat`：接受**一个函数** `Nat → Nat`，返回一个 `Nat`。
  这是高阶函数（§3.4）。
- `Nat → (Nat → Nat)`：和第一个**完全一样**，因为 `→` 右结合，
  那对括号本来就在那里（§3.2）。

**[3.2]** 思路：高阶函数，第一个参数是函数（§3.4）。
@@@ -/

def applyTwice : (Bool → Bool) → Bool → Bool :=
  fun g b => g (g b)

#eval applyTwice (fun b => !b) true     -- true：翻两次翻回来了

/- @@@
**[3.3]** 函数应用比任何中缀运算符结合得紧（§3.3），
所以 `double 5 + 1` 读成 `(double 5) + 1`；括号版本里 `5 + 1` 先算成 `6`。

**[3.4]** 思路：偏应用——给满一部分参数就得到一个函数（§3.2）。
@@@ -/

def add (a b : Nat) : Nat := a + b
def addTen := add 10

#check (addTen)           -- Nat → Nat
#eval addTen 5            -- 15

/- @@@
`add` 的类型是 `Nat → (Nat → Nat)`。给它一个 `Nat`（这里是 `10`），
箭头左边那个 `Nat` 被吃掉，剩下的就是括号里的 `Nat → Nat`。
@@@ -/

end Answers_3
end S3

/- @@@
---

# 4. 类型

前两节都在用现成的类型（`Nat`、`Bool`、`String`）。这一节讲怎么**造新类型**，
以及课程用到的那几个基本类型。

这一节只管「怎么造出一个值」。**怎么把一个值拆开**是第 5 节的事。
@@@ -/

namespace S4

/- @@@
## 4.1 `Type` 和 `Prop`

类型本身也是 term，所以类型本身也有类型。
@@@ -/

#check Nat                -- Nat : Type
#check Bool               -- Bool : Type
#check (7 > 0)            -- 7 > 0 : Prop

/- @@@
`Nat` 和 `Bool` 的类型是 **`Type`**；`7 > 0` 的类型是 **`Prop`**。
两者都是「类型的类型」，区别是它们的值是什么东西：

| | `Type`（计算类型） | `Prop`（逻辑类型 / 命题） |
|---|---|---|
| 它的值是什么 | **数据** | **证明** |
| 读法 | 「`Nat` 这个类型有哪些值」 | 「`7 > 0` 这个命题有没有证明」 |
| 能不能 `#eval` 它的值 | 能 | **不能**（证明在编译时被擦除，没有可运行的内容） |

注意第三行：`7 > 0` 这个式子**本身**是一个 term，它的类型是 `Prop`。
它是**一个命题**，不是「真」也不是「假」——
在 Lean 里「真」的问法是「它有没有值（有没有证明）」。

这一节和下面两节只用左边那一列。右边那一列从第 7 节开始。

## 4.2 `inductive`：造一个新类型

`inductive` 是造类型的主力工具。形式：

```text
inductive 名字 (参数) : 它的类型 where
| 构造子1 (字段 : 类型) : 名字
| 构造子2 ...
```

**构造子就是这个类型的全部引入规则**：除了把某个构造子应用到参数上，
没有别的办法造出这个类型的值。反过来说，
构造子的列表就是这个类型的**完整清单**。

### 最简形式：若干个无参构造子
@@@ -/

inductive Light where
  | red
  | yellow
  | green
deriving Repr

#eval Light.red
#eval Light.yellow

/- @@@
读作：一个 `Light` 是一个 `red`，**或者**一个 `yellow`，**或者**一个 `green`。
一共三个值，没有第四个。对比一下「用 `String` 表示红绿灯」：
那样 `"purple"`、`"GREEN"`、`""` 全都写得出来，而这里写不出来。

`deriving Repr` 让 `#eval` 有东西可打印，见 §4.4。

Lean 已经知道期望类型时，可以把类型名省掉，只写一个点和构造子名。
这叫 **dot notation（点记法）**：
@@@ -/

#eval (.green : Light)
def caution : Light := .yellow

#eval caution

/- @@@
### 构造子可以带参数（字段）

而且**不同的构造子可以带不同的数据**。
@@@ -/

inductive Status where
  | loading
  | succeeded (content : String)
  | failed (code : Nat) (reason : String)
deriving Repr

#eval (Status.loading)
#eval (.succeeded "the report" : Status)
#eval (.failed 404 "not found" : Status)

/- @@@
`loading` 这一支什么都不带（请求还在路上，没什么可报告的），
`succeeded` 带内容，`failed` 带一个错误码和一个原因。
「某个字段在某些情况下没有意义」这个问题就不存在了，因为那个字段根本不在那一支里。

构造子的字段名（`content`、`code`、`reason`）主要是文档作用。
在模式匹配里真正起作用的是**位置**，不是名字（§5.1）。

构造子的字段类型可以就是**正在定义的那个类型**，这样类型就是**递归**的。
E02 用这种方式定义了一门小语言的语法：
@@@ -/

inductive PropLogicSyntax where
| T
| F
| And (left right : PropLogicSyntax) : PropLogicSyntax
| Or (left right : PropLogicSyntax) : PropLogicSyntax
| Not (p : PropLogicSyntax)

/- @@@
注意 `And` 那一行末尾显式写了 `: PropLogicSyntax`，而 `Not` 那一行没写。
两种都对：返回类型能推断出来，写出来只是更清楚。

### 类型参数：参数化的 inductive

类型名后面可以带参数，造出一个**类型家族**。
下面是自己手写一遍 `Option`（库里已有，这里换个名字）：
@@@ -/

inductive Maybe (α : Type) where
  | nothing
  | just (value : α)
deriving Repr

#eval (Maybe.just 5)
#eval (Maybe.nothing : Maybe Nat)

/- @@@
`(α : Type)` 写在类型名后面、冒号前面，所以 `Maybe` 本身的类型是
`Type → Type`：给它一个类型，它还你一个类型。
@@@ -/

#check Maybe              -- 签名形式
#check (Maybe)            -- Type → Type
#check Maybe Nat          -- Type

/- @@@
### 索引族：`inductive ... : Dog → Prop`

这是 E07 的关键一步，第一次见会愣住。看冒号**后面**写的是什么：
@@@ -/

inductive Dog : Type where
| Iris
| Fido
| Sargent

inductive Friendly : Dog → Prop where
| irisFriendly : Friendly Dog.Iris
| fidoFriendly : Friendly Dog.Fido

/- @@@
**怎么读 `inductive Friendly : Dog → Prop`**：
`Friendly` **不是**一个命题，它是一个**从 `Dog` 到 `Prop` 的函数**。
这样的函数叫 **predicate（谓词）**：给它一个狗，它还你一个命题。

`Friendly Dog.Iris` 才是一个命题，`Friendly Dog.Sargent` 也是一个命题。

然后看构造子。每个构造子的类型都指定了它**是哪一个** `Friendly d` 的证据：

- `irisFriendly : Friendly Dog.Iris` —— Iris 友好的证据
- `fidoFriendly : Friendly Dog.Fido` —— Fido 友好的证据
- **没有** `Friendly Dog.Sargent` 的构造子

所以 `Friendly Dog.Iris` 这个类型**有值**，`Friendly Dog.Sargent` 这个类型
**没有值**。整张「谁友好」的事实表就编码在构造子列表里。
@@@ -/

#check @Friendly                        -- Dog → Prop，一个谓词
#check Friendly Dog.Iris                -- Prop，一个具体命题
example : Friendly Dog.Iris := Friendly.irisFriendly
-- `example` 是「造一个值但不起名字」，和 def 的差别在 §7.1 讲；这里只看它的类型和值

/- @@@
「没有值」就是「命题不可证」。这件事怎么**用**（怎么由此推出矛盾），
是 §7.10 的内容。

## 4.3 `structure`：只有一个构造子的类型，字段有名字

当一个类型只有一个构造子、而且你想按名字取分量时，用 `structure`。

```text
structure 名字 (参数) where
  字段1 : 类型1
  字段2 : 类型2
```
@@@ -/

structure Employee where
  first : String
  last  : String
  age   : Nat
deriving Repr

/- @@@
一个 `structure` 自动得到两样东西：

- 一个**构造子**，默认叫 `名字.mk`；
- 每个字段一个**投影函数**，叫 `名字.字段名`。

造一个值有三种写法：
@@@ -/

-- 命名形式：顺序随意，漏一个会报错
def ada : Employee := { first := "Ada", last := "Lovelace", age := 36 }

-- 位置形式：按声明顺序给
def grace : Employee := Employee.mk "Grace" "Hopper" 45

-- 匿名构造子：Lean 已知期望类型时可用
def alan : Employee := ⟨"Alan", "Turing", 41⟩

#eval ada
#eval grace
#eval alan

/- @@@
第三种里的 `⟨ ⟩` 叫 **anonymous constructor（匿名构造子）**记号，
意思是「把期望类型的**那个唯一**构造子应用到这些参数上」。
它在模式里也能用，§5.4 细讲。

给人读的代码推荐命名形式——字段名就是文档，而且以后加字段不会把顺序搞乱。

取分量用**点记法**，`ada.age` 就是「`ada` 的 `age` 字段」。
这是 §5.5 的内容，这里先看一眼：
@@@ -/

#eval ada.age
#eval ada.first ++ " " ++ ada.last

/- @@@
改一个字段用 `with`。注意它**造一个新值**，原来那个不动——
这门语言里值不会被修改，想要改过的版本就说出来，得到一个新名字：
@@@ -/

def older : Employee := { ada with age := 37 }

#eval older.age           -- 37
#eval ada.age             -- 36，原值没变

/- @@@
### `mk ::` 自定义构造子名

构造子名可以自己指定，写法是 `构造子名 :: (字段 : 类型) ...`。
库里 `Prod` 的定义就是这个写法，`And` 也是（§7.6 会用到）：

```lean
structure Prod (α : Type u) (β : Type v) where
  mk ::  (fst : α) (snd : β)

structure And (a b : Prop) : Prop where
  intro :: (left : a) (right : b)
```

读这两段要同时看三件事：构造子名（`mk` / `intro`）、
字段名（`fst snd` / `left right`）、以及它住在哪个宇宙（`Type` / `Prop`）。
**这两个是同一个结构，只差一个宇宙。** 这件事在 §7.6 兑现。
@@@ -/

structure MyProd (α β : Type) where
  mk :: (fst : α) (snd : β)

#check @MyProd.mk
#eval (MyProd.mk 1 true).fst

/- @@@
### 无字段的 structure

一个零字段的 `structure` 恰好有**一个**值（就是它的 `mk`），
也就是说它和 `Unit`（§4.5）同构。E01 用四个这样的类型当「有值的原子类型」：
@@@ -/

structure Rice
structure Potato
structure Fish
structure Chicken

#check Chicken.mk         -- Chicken，唯一的那个值

/- @@@
## 4.4 `deriving`

`deriving Repr` 让 Lean 自动生成「怎么把这个值打印出来」的代码，
`#eval` 才有东西可显示。几乎每个你定义的类型都该加上。

还有两个常用的，多个之间用逗号隔开：

| `deriving` | 给你什么 |
|---|---|
| `Repr` | `#eval` 能打印它 |
| `BEq` | 能用 `==` 比较（返回 `Bool`） |
| `DecidableEq` | 能在 `#guard` / `decide` 里用 `=` 比较（§11.1） |
@@@ -/

structure Card where
  rank : Nat
  name : String
deriving Repr, BEq, DecidableEq

#eval ({ rank := 1, name := "ace" } : Card) == { rank := 1, name := "ace" }
#eval ({ rank := 1, name := "ace" } : Card) == { rank := 2, name := "two" }

/- @@@
`BEq` 和 `DecidableEq` 的区别就是 `Bool` 和 `Prop` 的区别（§4.1）：
`==` 算出一个布尔值，`=` 是一个命题，`DecidableEq` 提供的是「判定它的算法」。

## 4.5 基本类型：`Empty` `Unit` `Bool` `Nat`

这四个按「有几个值」排序，这个排序是整个课程的骨架。

| 类型 | 有几个值 | 值是什么 |
|---|---|---|
| `Empty` | **0** | 没有 |
| `Unit` | **1** | `Unit.unit`，也写 `()` |
| `Bool` | **2** | `true`、`false` |
| `Nat` | 无穷 | `0, 1, 2, ...` |
@@@ -/

#check Empty              -- 有这个类型，但你写不出它的任何一个值
#check Unit.unit          -- Unit 唯一的那个值
#check ()                 -- () : Unit，同一个值的另一种写法
#eval 7 / 2               -- 3：自然数除法向下取整
#eval 7 % 2               -- 1：余数

/- @@@
**`Empty` 的要点**：它**一个构造子都没有**，所以你永远写不出它的值。
正因如此它可以用来说「这种情况不可能发生」，而且这句话机器能检查。
从 `Empty` 出发的函数怎么写，见 §5.7。

**`Unit` 的要点**：它只有一个值，所以「给你一个 `Unit`」等于什么都没告诉你。
这正是「只为副作用而做的事」该有的返回类型——
在一个每个表达式都有值的语言里，它必须返回点什么，那就返回那个什么都不说的值。

### 数清一个类型有几个值

这件事是设计类型的方法论，而且**解释了那几个符号的名字**：

| 构造方式 | 写法 | 如果 `α` 有 m 个值、`β` 有 n 个值 |
|---|---|---|
| 空 | `Empty` | 0 |
| 一个 | `Unit` | 1 |
| 两个都要 | `α × β` | **m × n**（所以叫 **product**，积） |
| 要其中一个 | `α ⊕ β` | **m + n**（所以叫 **sum**，和） |
| 函数 | `α → β` | **n 的 m 次方** |

所以 `Bool × Bool` 有 4 个值，`Bool ⊕ Bool` 也有 4 个，但**不是同样的 4 个**：
前者每个值带两个布尔，后者每个值带一个布尔加上「它来自哪一边」的信息。

而 `Bool → Bool` 恰好有 4 个函数。全列出来，没有第五个：
@@@ -/

def alwaysTrue  : Bool → Bool := fun _ => true
def alwaysFalse : Bool → Bool := fun _ => false
def keepIt      : Bool → Bool := fun b => b
def flipIt      : Bool → Bool := fun b => !b

-- 每一行是一个函数的完整行为：它对 true 的答案，它对 false 的答案
#eval (alwaysTrue  true, alwaysTrue  false)
#eval (alwaysFalse true, alwaysFalse false)
#eval (keepIt      true, keepIt      false)
#eval (flipIt      true, flipIt      false)

/- @@@
你写出来的任何 `Bool → Bool` 必须在两个输入上都和这四个之一一致，
那它就**是**那一个。

## 4.6 `Prod`（`×`）和 `Sum`（`⊕`）

这两个是库里已经定义好的，但它们的定义值得抄出来看，E 文件全程在用。

```lean
structure Prod (α : Type u) (β : Type v) where
  mk ::  (fst : α) (snd : β)

inductive Sum (α : Type u) (β : Type v) where
  | inl (val : α) : Sum α β
  | inr (val : β) : Sum α β
```

一个是 `structure`（一个构造子，两个字段），一个是 `inductive`（两个构造子）。

| | `Prod α β`，记法 `α × β` | `Sum α β`，记法 `α ⊕ β` |
|---|---|---|
| 怎么造 | `Prod.mk a b`，或 `(a, b)`，或 `⟨a, b⟩` | `Sum.inl a` 或 `Sum.inr b` |
| 要造一个值你得 | 两边**都**给 | **挑一边**给 |
| 有一个值说明 | 两个类型**都**有值 | **至少一个**类型有值 |
| 怎么拆 | 投影 `.1` `.2`（§5.5） | `match` 分两支（§5.1） |
@@@ -/

-- Prod：三种写法造出同一个值
def pairA : Nat × Bool := (7, true)
def pairB : Nat × Bool := Prod.mk 7 true
def pairC : Nat × Bool := ⟨7, true⟩

#eval pairA
#eval pairB
#eval pairC

-- Sum：挑一边
def aNum : Nat ⊕ String := Sum.inl 42
def aStr : Nat ⊕ String := Sum.inr "error"

#eval aNum
#eval aStr

/- @@@
`×` 和 `⊕` 都是**右结合**的：

- `Nat × String × Bool` 是 `Nat × (String × Bool)`；
- `Unit ⊕ String ⊕ String` 是 `Unit ⊕ (String ⊕ String)`。
@@@ -/

def row : Nat × String × Bool := (1, "ada", true)

#eval row
#check (row.2)            -- String × Bool —— 第二个分量本身是个 pair

/- @@@
右结合的后果是：三个 case 的 `Sum` 要写成 `Sum.inr (Sum.inl x)`，
括号数到第几层就是第几个 case。这种写法撑不住三个以上的 case，
所以超过两个 case 就该改用带名字的 `inductive`（§4.2 的 `Status` 就是）。

## 4.7 类型本身也是值

既然类型是 term，它就能像别的值一样被装进数据结构里：
@@@ -/

def myBestTypes := [Nat, Bool, String, Bool]

#eval myBestTypes.length
#check myBestTypes        -- List Type

/- @@@
有一条限制：**不能对 `Type` 里的值做模式匹配**，不能区分它们、按它们分支。
想「按类型分情况处理」，只能先用普通数据类型给类型**编号**
（像 §4.2 的 `Light` 给三种灯编号那样），然后对那个普通数据做匹配。
理由见 §6.5。

## 4.8 本节练习

**[4.1]（写）** 定义 `inductive Suit` 含四个花色，`deriving Repr, DecidableEq`。
然后造出一个值并 `#eval` 它。

**[4.2]（读）** 读下面这个定义：`Friendly` 的类型是什么？
`irisFriendly` 的类型是什么？为什么 `Friendly Dog.Sargent` 没有值？

```lean
inductive Friendly : Dog → Prop where
| irisFriendly : Friendly Dog.Iris
| fidoFriendly : Friendly Dog.Fido
```

**[4.3]（写）** 数一数下面每个类型有几个值，写出算式：
`Bool × Unit`、`Bool ⊕ Empty`、`Unit → Bool`、`Bool → Bool → Bool`、`Empty × Bool`。

**[4.4]（写）** 定义 `structure Book`，字段 `title : String`、`pages : Nat`，
`deriving Repr`。用三种写法（命名、位置、匿名构造子）各造一个值。

**[4.5]（判）** `Nat × String × Bool` 展开成完整括号是什么？
`Nat ⊕ String ⊕ Bool` 呢？

---

**先自己做，再往下看。**

---
@@@ -/

namespace Answers_4

/- @@@
**[4.1]** 思路：`inductive` 加四个无参构造子（§4.2），`deriving` 见 §4.4。
@@@ -/

inductive Suit where
  | hearts
  | diamonds
  | spades
  | clubs
deriving Repr, DecidableEq

#eval Suit.hearts
#eval (.spades : Suit)

/- @@@
**[4.2]**

- `Friendly` 的类型是 `Dog → Prop`。它**不是**一个命题，
  是一个从 `Dog` 到 `Prop` 的函数，也就是一个 **predicate（谓词）**（§4.2）。
- `irisFriendly` 的类型是 `Friendly Dog.Iris`，
  也就是「Iris 友好」这个**命题的一个值（证明）**。
- `Friendly Dog.Sargent` 没有值，因为构造子列表里**没有**任何一个构造子
  的类型是 `Friendly Dog.Sargent`。构造子是造值的唯一办法，
  列表里没有，就造不出来（§4.2）。

**[4.3]** 用 §4.5 的算术：

| 类型 | 算式 | 结果 |
|---|---|---|
| `Bool × Unit` | 2 × 1 | **2** |
| `Bool ⊕ Empty` | 2 + 0 | **2** |
| `Unit → Bool` | 2 的 1 次方 | **2** |
| `Bool → Bool → Bool` | `Bool → (Bool → Bool)`，而 `Bool → Bool` 有 4 个，所以 4 的 2 次方 | **16** |
| `Empty × Bool` | 0 × 2 | **0** |

最后一行最容易出错：**要求一个造不出来的东西和你的数据配对，
整个类型就没人能造出来了。**

**[4.4]** 三种写法见 §4.3。
@@@ -/

structure Book where
  title : String
  pages : Nat
deriving Repr

def b1 : Book := { title := "A", pages := 100 }   -- 命名
def b2 : Book := Book.mk "B" 200                  -- 位置
def b3 : Book := ⟨"C", 300⟩                        -- 匿名构造子

#eval b1
#eval b2
#eval b3

/- @@@
**[4.5]** 两个都**右结合**（§4.6）：

- `Nat × String × Bool` 是 `Nat × (String × Bool)`；
- `Nat ⊕ String ⊕ Bool` 是 `Nat ⊕ (String ⊕ Bool)`。

所以三元组的第二个分量本身是个 pair，而三选一的第二个 case
要写成 `Sum.inr (Sum.inl ...)`。
@@@ -/

example : Nat × String × Bool := (1, "two", true)
example : Nat × (String × Bool) := (1, "two", true)   -- 同一个类型

end Answers_4
end S4

/- @@@
---

# 5. 模式匹配

上一节讲怎么**造**一个值。这一节讲怎么**拆**一个值。

造一个值叫 introduction（引入），拆一个值叫 elimination（消去），
而模式匹配就是最通用的消去手段：
它问「这个值是用哪个构造子造出来的」，然后分情况处理。

关键的好处是：**每个分支里你确切地知道自己在哪一种情况**，
所以不需要「万一都不是怎么办」那个分支——因为不存在那种可能。
@@@ -/

namespace S5

/- @@@
## 5.1 `match ... with | 模式 => ...`

最基本的形式。拿 §4.2 的红绿灯来拆：
@@@ -/

inductive Light where
  | red
  | yellow
  | green
deriving Repr

def description (l : Light) : String :=
  match l with
  | Light.red    => "stop"
  | Light.yellow => "prepare to stop"
  | Light.green  => "go"

#eval description Light.red
#eval description Light.green

/- @@@
**逐 token 拆**：

| token | 角色 |
|---|---|
| `match` | 关键字，宣布要做 case analysis（分情况分析） |
| `l` | 被匹配的 term（叫 scrutinee，被审查者） |
| `with` | 关键字，分隔被匹配者和分支表 |
| `\|` | 每个分支以它开头 |
| `Light.red` | **模式**，这里是一个构造子名，问「是不是用它造的」 |
| `=>` | 分隔模式和这一支的结果 |
| `"stop"` | 这一支的结果，类型必须是整个 `match` 的返回类型 |

**exhaustiveness（穷尽性）是被检查的**：漏掉一个构造子就编译不过，
而且 Lean 会告诉你漏了哪个。下面这段取消注释就会报错：

```lean
-- def incomplete (l : Light) : String :=
--   match l with
--   | Light.red   => "stop"
--   | Light.green => "go"
```

这是整个设计的核心好处。想想那个错误是**什么时候**出现的：
不是半夜用户撞上黄灯的时候，而是你写下这个函数的那一刻。
更重要的是以后给 `Light` 加第四个构造子时——
所有没处理它的 `match` 立刻变成编译错误，编译器把需要去改的地方**列全给你**。

构造子带字段时，模式里给那些字段**起名字**，这些名字在 `=>` 右边能用：
@@@ -/

inductive Status where
  | loading
  | succeeded (content : String)
  | failed (code : Nat) (reason : String)
deriving Repr

def report (s : Status) : String :=
  match s with
  | Status.loading            => "still working"
  | Status.succeeded content  => "got it: " ++ content
  | Status.failed code reason => "failed (" ++ toString code ++ "): " ++ reason

#eval report Status.loading
#eval report (Status.succeeded "the report")
#eval report (Status.failed 404 "not found")

/- @@@
在 `.succeeded` 那一支里 `content` 存在；在 `.failed` 那一支里它不存在，
而 `code` 和 `reason` 存在。**你只能碰到你匹配的那一支真正带着的数据**，
这是类型系统在替你执行设计，而不是靠注释提醒你小心。

模式里的名字可以随便起，起作用的是**位置**，不是构造子声明里的字段名。

## 5.2 `def` 直接写分支：等式形式

如果整个函数体就是一个 `match`，可以把 `match x with` 省掉，
直接在 `def` 的类型后面列分支。E 文件里这种写法比 `match` 还多。
@@@ -/

-- 等式形式
def yep : Bool → Bool
| true => true
| false => false

-- 完全等价的 match 形式
def yep' (b : Bool) : Bool :=
match b with
| true => true
| false => false

#eval yep true
#eval yep' true

/- @@@
**两种形式之间有一条硬规则**，不知道这条就会撞墙：

> 参数一旦在冒号**左边**被绑定了名字，就不能再用 `| 模式 => ...` 匹配它。

所以下面这段是**错的**：

```lean
-- def nope (b : Bool) : Bool
-- | true => true
-- | false => false
```

理由：`b` 已经是一个绑定好的名字了，而 `| true => ...` 这种写法
要求 Lean 自己去决定「匹配第几个参数」，那个位置已经被名字占住了。
想匹配就用 `yep'` 那种写法：在体里 `match b with`。

（这正是 §3.1 说的「两种写法的区别只在名字在哪里被绑定」的第一个实际后果。）

分支表可以横着写，`|` 还是那个 `|`：
@@@ -/

def yep'' (b : Bool) : Bool := match b with | true => true | false => false

#eval yep'' false

/- @@@
## 5.3 多个参数一起匹配，和通配符 `_`

模式表里用逗号分隔，就能同时匹配多个参数。
@@@ -/

inductive MyBool where
| true
| false
deriving Repr

def myAnd : MyBool → MyBool → MyBool
| MyBool.true, MyBool.true => MyBool.true   -- 同时匹配两个参数
| _, _ => MyBool.false                      -- 通配符：其他任何组合

def myOr : MyBool → MyBool → MyBool
| MyBool.false, MyBool.false => MyBool.false
| _, _ => MyBool.true

def myNot : MyBool → MyBool
| MyBool.true => MyBool.false
| MyBool.false => MyBool.true

#eval myAnd MyBool.true MyBool.false
#eval myOr MyBool.true MyBool.false
#eval myNot MyBool.true

/- @@@
`_` 是**通配符模式**：匹配任何东西，并且不给它起名字。

关于 `_` 有两件事要记住：

1. 它让分支表变短，但也**关掉了穷尽性检查**带来的好处。
   以后给类型加构造子时，带 `_` 的 `match` 不会报错，而你可能正需要它报错。
   所以：慎用 `_`，每写一个 `_` 就是一句「以后这个类型变了我会回来看」的承诺。
2. **分支按顺序尝试**，所以具体的模式写在前面，`_` 写在最后。

模式还可以**嵌套**，也就是模式里面套模式。
E02 的 `eval` 把两件事一起做了：嵌套模式 + 多参数匹配 + 递归。
@@@ -/

inductive Variable where
| Xvar
| Yvar
| Zvar

inductive PropLogicSyntax where
| T
| F
| And (left right : PropLogicSyntax) : PropLogicSyntax
| Or (left right : PropLogicSyntax) : PropLogicSyntax
| Not (p : PropLogicSyntax)
| Var (v : Variable)

-- 一个「解释」把每个变量映射到一个布尔值
def varInterp : Type := Variable → Bool

def i1 : varInterp :=
  fun v =>
    match v with
    | Variable.Xvar => true
    | Variable.Yvar => true
    | Variable.Zvar => false

open PropLogicSyntax in
def eval : PropLogicSyntax → varInterp → Bool
| T, _ => true
| F, _ => false
| (PropLogicSyntax.And p1 p2), i => (eval p1 i) && (eval p2 i)
| (PropLogicSyntax.Or  p1 p2), i => (eval p1 i) || (eval p2 i)
| (PropLogicSyntax.Not p1),    i => !(eval p1 i)
| (PropLogicSyntax.Var v),     i => i v

-- `open ... in` 只管下面紧跟的那一条命令，所以这里要写全名
#eval eval (PropLogicSyntax.And PropLogicSyntax.T PropLogicSyntax.F) i1
#eval eval (PropLogicSyntax.Var Variable.Xvar) i1
#eval eval (PropLogicSyntax.Not (PropLogicSyntax.Var Variable.Zvar)) i1

/- @@@
**逐 token 拆第三个分支** `| (And p1 p2), i => (eval p1 i) && (eval p2 i)`：

- 逗号左边是第一个参数的模式，右边的 `i` 是第二个参数的模式
  （一个**变量模式**：匹配任何东西，并把它**绑定**到名字 `i`）；
- `(And p1 p2)` 是一个**构造子模式**：它要求第一个参数是用 `And` 造出来的，
  并把 `And` 的两个字段**绑定**到新名字 `p1` 和 `p2`；
- `=>` 右边用 `p1`、`p2`、`i` 组装结果。这里是**递归调用** `eval`——
  对子表达式再求值，然后用 `&&` 合起来。

注意前两个分支写的是 `T` 和 `F`（不带前缀），后四个却写了全名
`PropLogicSyntax.And` 等等。前两个能省前缀是因为上面那行
`open PropLogicSyntax in`（§6.7）；后四个**不能**省，
因为 `And`、`Or`、`Not` 这几个名字 Lean 自己在 `Prop` 上也用了（§7.6、§7.7），
省掉前缀就有歧义，Lean 会报 `ambiguous pattern, use fully qualified name`。
E02 的原文就是这么写的。

## 5.4 匿名构造 `⟨a, b⟩`：既能造也能拆

§4.3 见过 `⟨ ⟩` 用来**造**一个 structure 的值。
它的完整含义是：**「把期望类型的那个唯一构造子应用到这些参数上」**。

两个前提：Lean 已经知道期望类型；那个类型**只有一个构造子**（这样才没有歧义）。

关键是：**它也能用在模式位置上**，也就是用来**拆**。
`Prod` 只有一个构造子，所以拿它当例子最干净。
@@@ -/

-- 造
def pairA : Nat × Bool := ⟨7, true⟩
def pairB : Nat × Bool := Prod.mk 7 true
def pairC : Nat × Bool := (7, true)        -- Prod 另有专门的 (_, _) 记法

-- 拆：⟨ ⟩ 出现在 => 的左边
def swapA : Nat × Bool → Bool × Nat
| ⟨n, b⟩ => ⟨b, n⟩

-- 同一件事，用 Prod 自己的 (_, _) 记法
def swapB : Nat × Bool → Bool × Nat
| (n, b) => (b, n)

#eval swapA pairA
#eval swapB pairA

/- @@@
**逐 token 拆 `| ⟨n, b⟩ => ⟨b, n⟩`**：

- `=>` **左边**的 `⟨n, b⟩` 是**模式**：它把传进来的 pair 拆开，
  把第一个分量绑定到名字 `n`（类型 `Nat`），第二个绑定到 `b`（类型 `Bool`）。
  这一步是 **Prod 的 elimination rule**。
- `=>` **右边**的 `⟨b, n⟩` 是**构造**：把 `b` 和 `n` 按相反顺序装进一个
  `Bool × Nat`。这一步是 **Prod 的 introduction rule**。

同一对尖括号，在 `=>` 左边是拆，在右边是装。

`⟨ ⟩` 可以**嵌套**，因为模式可以嵌套。而且 Lean 允许把**右嵌套**的
`⟨ ⟩` 拍平成一层，省掉内层括号：
@@@ -/

def firstOfThree : Nat × String × Bool → Nat
| ⟨n, _, _⟩ => n          -- 这是 ⟨n, ⟨_, _⟩⟩ 的简写

#eval firstOfThree (1, "two", true)

/- @@@
拍平只对**右嵌套**有效。`(Nat × Bool) × String` 是左嵌套，
它的模式必须写成 `⟨⟨n, b⟩, s⟩`，不能拍平成 `⟨n, b, s⟩`。
这是最容易错的地方，§7.6 还会再碰到。
@@@ -/

def leftNested : (Nat × Bool) × String → Nat
| ⟨⟨n, _⟩, _⟩ => n

#eval leftNested ((1, true), "x")

/- @@@
## 5.5 投影：`.1` `.2` `.fst` `.snd` `.字段名`

对**只有一个构造子**的类型（`Prod`、`structure`），
除了 `match`，还可以直接用**字段投影**取出分量。写法是 `值.字段名`。

| 类型 | 投影写法 |
|---|---|
| `Prod` | `.1` `.2`，或 `.fst` `.snd`，或 `Prod.fst p` |
| `structure` | `.字段名` |

`.1` / `.2` 是按**位置**取，`.fst` / `.字段名` 是按**名字**取。
对同一个值它们是一回事。
@@@ -/

def p : Nat × Bool := (7, true)

#eval p.1
#eval p.fst               -- 同上
#eval Prod.fst p          -- 同上，不用点记法

/- @@@
`Prod.fst` 和 `Prod.snd` 就是 `Prod` 的 **elimination rule（消去规则）**。
记住这个说法，§7.6 的 `And.left` / `And.right` 是同一件事。

**位置投影能链起来用**，因为 `×` 右结合（§4.6）：
`Nat × String × Bool` 是 `Nat × (String × Bool)`，所以中间那个分量是 `.2.1`。
@@@ -/

def row : Nat × String × Bool := (1, "ada", true)

#eval row.1               -- 1
#eval row.2               -- ("ada", true) —— 它本身是个 pair
#eval row.2.1             -- "ada"
#eval row.2.2             -- true

/- @@@
这个写法不要滥用：`employee.2.2.1` 是对的，但没人读得懂，
而且中间插一个分量会**悄悄改变**后面每一个访问的含义。
超过三个分量就该改用 `structure`，按名字取：
@@@ -/

structure Employee where
  first : String
  last  : String
  age   : Nat
deriving Repr

def ada : Employee := { first := "Ada", last := "Lovelace", age := 36 }

#eval ada.age             -- 按名字取，改字段顺序也不会错
#eval ada.last

/- @@@
## 5.6 `if then else`

`if 条件 then 这个 else 那个`。两件事要注意：

1. 条件必须是 `Bool`（或者是一个有 `Decidable` 实例的命题，§11.1）；
2. **两个分支的类型必须相同**——`if` 是一个**表达式**，它有一个值，
   所以它必须有一个类型。

可以串成 `else if` 链：
@@@ -/

def describe (n : Nat) : String :=
  if n == 0 then "zero"
  else if n < 10 then "small"
  else "big"

#eval describe 0
#eval describe 7
#eval describe 1000

/- @@@
什么时候用 `if`、什么时候用 `match`？
函数本质上是一张**表**（每个构造子一行）就用分支形式；
有一个统一的计算、只是需要判一下条件，就用 `if`。

## 5.7 `nomatch`：零个分支的模式匹配

`nomatch e` 的意思是：**对 `e` 做模式匹配，而需要写的分支数是零**。

什么时候分支数是零？当 `e` 的类型**没有任何构造子能造出它**的时候。
最干净的例子是 `Empty`（§4.5）——它一个构造子都没有：
@@@ -/

def fromEmptyNat (e : Empty) : Nat := nomatch e
def fromEmptyStr (e : Empty) : String := nomatch e

#check fromEmptyNat
#check fromEmptyStr

/- @@@
返回类型写什么都行，因为这个函数**永远不会真的返回**。

读法：「如果你真能给我一个 `Empty` 的值，我就能给你任何类型的值——
但你给不出来，所以这个函数永远不会被调用。」
这是「这种情况不可能发生」在类型层面的说法，而且机器能检查。

注意 `nomatch` 和 `match` 的关系：`match` 要求你**覆盖所有构造子**，
而 `Empty` 的构造子一个都没有，所以「覆盖所有」就是「一个都不写」。
`nomatch` 只是这件事的简写。

`nomatch` 真正大显身手的地方是在证明里——
那里会碰到「构造子存在、但一个都对不上形状」的情况。见 §7.10。

## 5.8 本节练习

**[5.1]（读）** 说出下面这个分支里每个 token 的角色：哪个是构造子模式、
哪个是被绑定的新名字、`=>` 右边在干什么。

```lean
| (Or p1 p2), i => (eval p1 i) || (eval p2 i)
```

**[5.2]（写）** 给 §5.3 的 `MyBool` 写一个 `myXor : MyBool → MyBool → MyBool`，
用等式形式、**不用** `_` 通配符（四个分支全写出来），然后 `#eval` 四种组合。

**[5.3]（判）** 下面这段为什么编译不过？两种改法分别怎么写？

```lean
def f (b : Bool) : Nat
| true => 1
| false => 0
```

**[5.4]（写）** 用 `⟨ ⟩` 模式写一个
`rotate : Nat × String × Bool → Bool × Nat × String`，
把三个分量循环左移一位（`(1, "a", true)` 变成 `(true, 1, "a")`）。

**[5.5]（判）** `(Nat × Bool) × String` 的模式能不能写成 `⟨n, b, s⟩`？
`Nat × (Bool × String)` 呢？为什么？

---

**先自己做，再往下看。**

---
@@@ -/

namespace Answers_5

/- @@@
**[5.1]** `| (Or p1 p2), i => (eval p1 i) || (eval p2 i)`

- `|` 开启一个分支；
- 逗号分隔**两个参数**的模式（§5.3）；
- `(Or p1 p2)` 是**构造子模式**：要求第一个参数是用 `Or` 造的，
  并把它的两个字段绑定到**新名字** `p1`、`p2`；
- `i` 是**变量模式**：匹配任何东西，并把第二个参数绑定到名字 `i`；
- `=>` 右边**递归调用** `eval` 求两个子表达式的值，再用 `||` 合起来。

**[5.2]** 思路：四个分支全写，不用 `_`（§5.3）。
@@@ -/

inductive MyBool where
| true
| false
deriving Repr

def myXor : MyBool → MyBool → MyBool
| MyBool.true,  MyBool.true  => MyBool.false
| MyBool.true,  MyBool.false => MyBool.true
| MyBool.false, MyBool.true  => MyBool.true
| MyBool.false, MyBool.false => MyBool.false

#eval myXor MyBool.true  MyBool.true
#eval myXor MyBool.true  MyBool.false
#eval myXor MyBool.false MyBool.true
#eval myXor MyBool.false MyBool.false

/- @@@
**[5.3]** 编译不过，因为参数 `b` 已经在冒号左边被绑定了名字，
就不能再用 `| 模式 => ...` 的等式形式匹配它（§5.2）。
@@@ -/

-- 改法一：别给参数起名字，让它留在函数类型里
def fA : Bool → Nat
| true => 1
| false => 0

-- 改法二：保留名字，在体里用 match
def fB (b : Bool) : Nat :=
match b with
| true => 1
| false => 0

#eval fA true
#eval fB true

/- @@@
**[5.4]** 思路：右嵌套的 `⟨ ⟩` 可以拍平，所以进来的模式写一层就够（§5.4）。
出去的类型 `Bool × Nat × String` 也是右嵌套，同样写一层。
@@@ -/

def rotate : Nat × String × Bool → Bool × Nat × String
| ⟨n, s, b⟩ => ⟨b, n, s⟩

#eval rotate (1, "a", true)

/- @@@
**[5.5]**

- `(Nat × Bool) × String` **不能**写成 `⟨n, b, s⟩`。它是**左嵌套**，
  第一个分量本身是个 pair，模式必须写成 `⟨⟨n, b⟩, s⟩`（§5.4）。
- `Nat × (Bool × String)` **能**写成 `⟨n, b, s⟩`。它是**右嵌套**，
  而拍平只对右嵌套有效。
@@@ -/

def leftOne : (Nat × Bool) × String → Nat
| ⟨⟨n, _⟩, _⟩ => n

def rightOne : Nat × (Bool × String) → Nat
| ⟨n, _, _⟩ => n

#eval leftOne ((1, true), "x")
#eval rightOne (1, (true, "x"))

end Answers_5
end S5

/- @@@
---

# 6. 定义进阶和作用域

第 2 节讲了 `def` 的基本形状。这一节补齐剩下的定义方式
（`abbrev`、`let`、`where`）和**隐式参数**，
再讲名字的作用域（`namespace`、`open`、`variable`）。

学完这一节，第 7 节开始的证明代码里就不会再有不认识的语法了。
@@@ -/

namespace S6

/- @@@
## 6.1 `abbrev`：定义一个「透明的」缩写

`abbrev` 和 `def` 写法完全一样，区别是 `abbrev` 定义的名字被标记为
**reducible（可归约的）**：Lean 的类型检查器会**自动展开**它，
把它当成右边那个东西的同义词。

最典型的用法是给一个类型起个好读的短名字：
@@@ -/

abbrev VarInterp := Nat → Bool          -- 类型别名
abbrev Point := Nat × Nat

def origin : Point := (0, 0)
def shift (p : Point) : Point := (p.1 + 1, p.2 + 1)

#eval shift origin

/- @@@
因为 `abbrev` 是透明的，`Point` 和 `Nat × Nat` 对 Lean 来说就是同一个类型。
@@@ -/

#eval origin.1
#check (origin : Nat × Nat)             -- 透明：Point 就是 Nat × Nat

/- @@@
**透明不透明在哪里看得出来**？在 Lean 需要「看穿」这个名字去**找东西**的时候。
最容易撞上的是数字字面量和运算符——它们要靠类型去查对应的实现：
@@@ -/

abbrev MyNatA := Nat
def    MyNatD := Nat

def xa : MyNatA := 3
#eval xa + 1              -- 4：abbrev 透明，Lean 看穿它找到了 Nat 的加法

-- def xd : MyNatD := 3   -- 报错：failed to synthesize instance of type class
--                        --       OfNat MyNatD 3
-- `def` 挡住了 Lean 的视线，它不知道 MyNatD 其实就是 Nat，于是连 `3` 都写不进去

/- @@@
什么时候用哪个：给类型或命题起短名字用 `abbrev`，定义真正的函数和数据用 `def`。
这个区别在 §11.1 的 `decide` 上还会再出现一次，表现一模一样。

## 6.2 `let`：在表达式**内部**起名字

`def` 在文件顶层起名字，`let` 在一个表达式**里面**起名字，
只在这个表达式内有效。形式是 `let 名 := 值` 换行接着写后续表达式
（也可以写 `let 名 : 类型 := 值`，把类型标出来）。
@@@ -/

def circleArea : Float :=
  let r := 3.0
  let pi := 3.14159
  pi * r * r

#eval circleArea

/- @@@
`let` 的真正价值是**给中间结果起名字，顺便把它的类型写出来**，
等于在代码里记下推导的每一步。下面这个例子（来自 E01）
把「取左、取右、重新组装」三步分别命名：
@@@ -/

def swapNatBool : (Nat × Bool) → (Bool × Nat) :=
  fun nb =>
    let n := nb.1         -- × elimination：取左（§5.5）
    let b := nb.2         -- × elimination：取右
    (b, n)                -- × introduction：组装（§4.6）

#eval swapNatBool (3, true)

/- @@@
这种「每一步标出用了哪条规则」的写法，到了第 7 节写证明时会变成主力。

## 6.3 `where`：把辅助定义挂在主定义后面

`where` 有两个**完全不同**的用处，不要混。

**用处一（本节）**：写在一条 `def` 的**末尾**，
定义只给这条 `def` 用的辅助函数。辅助函数能看到主定义的参数。
@@@ -/

def sumTwice (n : Nat) : Nat := helper n + helper n
  where helper (m : Nat) : Nat := m * 10

#eval sumTwice 3          -- 60

/- @@@
**用处二**：写在 `inductive` 或 `structure` 的头部后面，
引出构造子或字段的列表，比如 `inductive Light where | red | ...`（§4.2）。

E 文件里出现的 `where` **几乎全是**第二种。两个 `where` 只是碰巧同一个关键字。

## 6.4 隐式参数 `{ }`、`_` 推断、`@` 关闭推断

这是读 E 文件的一道门槛，E00 用了整整半份文件讲它。

从一个具体问题出发：恒等函数对每个类型都长得**一模一样**，只有类型不同。
@@@ -/

def idBool : Bool → Bool := fun n => n
def idNat  : Nat  → Nat  := fun n => n

/- @@@
那就把「类型」本身变成一个参数。这叫 **parametric polymorphism（参数多态）**。
`Type u` 里的 `u` 是一个 **universe（宇宙）** 层级，不用声明，Lean 自动处理：
@@@ -/

def id' (α : Type u) : α → α := fun n => n

#eval id' Nat 3
#eval id' Bool true
#eval id' (List Nat) [1, 2, 3]

/- @@@
**逐 token 拆 `#eval id' Nat 3`**：

- `id'` 是函数，`Nat` 是第一个实参，`3` 是第二个实参；
- 第一个实参是一个**类型**，而第二个实参的**类型**由第一个实参的**值**决定。
  这叫 **dependent typing（依值类型）**：值决定类型。

现在问一个关键问题：既然 `3` 的类型摆在那里，第一个参数还有必要**写出来**吗？
没必要。`_` 就是「这里的东西你自己推，别让我写」：
@@@ -/

#eval id' _ 3
#eval id' _ true

/- @@@
既然每次都写 `_`，不如让 Lean 默认就去推断。
参数声明改用**花括号** `{α : Type u}` 就是这个意思，
叫 **implicit argument（隐式参数）**：
@@@ -/

def idImp {α : Type u} : α → α := fun n => n

#eval idImp 3
#eval idImp true
#eval idImp [1, 2, 3]

/- @@@
三种括号对照记住：

| 写法 | 名称 | 调用时 |
|---|---|---|
| `(α : Type u)` | explicit（显式参数） | 必须写出实参 |
| `{α : Type u}` | implicit（隐式参数） | 不写，Lean 推断 |
| `_` | placeholder（占位符） | 在显式位置上让 Lean 推断这**一个** |

（还有第四种，方括号 `[ ]`，叫 instance implicit，见 §11.1。）

### `Sort u`：把 `Prop` 也包进来

E 文件里经常看到 `{α : Sort u}` 而不是 `{α : Type u}`。区别是宇宙层级：

```text
Prop   =  Sort 0
Type   =  Sort 1   （也写 Type 0）
Type 1 =  Sort 2
...
```

`Type u` 只包括 `Type` 这一列，`Sort u` 把 `Prop` 也包进来。
所以 `{α : Sort u}` 是「`α` 是任何宇宙里的任何类型，**包括命题**」，比 `Type u` 更宽。
写库函数（比如恒等函数）时用 `Sort u`，这样对命题也能用。
@@@ -/

def idSort {α : Sort u} : α → α := fun n => n

#eval idSort 3
#check @idSort

/- @@@
### `@`：关闭隐式推断

隐式参数**不许**显式传。但有时候 Lean 推不出来，你必须自己给；
或者你只是想看看一个函数的完整类型。
`@f` 的意思是「把 `f` 的所有隐式参数变成显式的」。
@@@ -/

#eval @idImp Nat 3        -- 可以：@ 之后 α 变显式
-- #eval idImp Nat 3      -- 不行：α 是隐式的（这个报错在 §9.4 用 #guard_msgs 钉住）

/- @@@
`@` 更常用的场合是**看类型**。四种写法并排 `#check` 一遍，
看清「加不加括号、加不加 `@`」各显示什么：
@@@ -/

#check idImp              -- 签名形式：隐式参数写在花括号里
#check (idImp)            -- 加括号 = 当成一个 term 用，隐式参数被实例化成 metavariable `?m.1`
#check @idImp             -- 箭头形式：隐式参数变成函数类型的一节
#check (@idImp)           -- 同上

/- @@@
### `∀` 当函数类型写

E01 有一种写法乍看会愣住：把参数写在 `∀` 后面。
@@@ -/

def swapForall : ∀ {α β : Type u}, α × β → β × α :=
  fun p => (p.2, p.1)

def swapBrace {α β : Type u} : α × β → β × α :=
  fun p => (p.2, p.1)

def swapEarly {α β : Type u} (p : α × β) : β × α := (p.2, p.1)

#eval swapForall (0, false)
#eval swapBrace (0, false)
#eval swapEarly ("No", "Way")

/- @@@
三条定义的是**同一个函数**。`∀ {α β : Type u}, ...` 在这里当**函数类型**用：
`∀` 引入带名字的形参，逗号把形参和返回类型分开。
现在只要知道它起的作用和把花括号写在名字后面一样；
`∀` 的完整含义（以及它和 `→` 的关系）见 §7.5。

注意最后一条 `swapEarly` 把 `p` 提到了冒号左边，所以不能再用等式形式
`| (a, b) => ...` 匹配它（§5.2 那条硬规则）。

## 6.5 parametricity：多态函数「不许偷看」

参数多态有一个重要后果，这里只记结论。

多态函数的实现必须**完全不依赖**实参的具体类型，
必须把类型参数当成不透明的黑盒。所以：

1. **不能对一个多态类型参数的值做 `match`**；
2. 更强地，**不能对 `Type` 里的值做模式匹配**——
   你写不出一个「收到 `Nat` 就这样、收到 `String` 就那样」的函数（§4.7）；
3. 后果是：有些多态函数的实现是**被迫唯一**的。看
   `def idSort {α : Sort u} (a : α) : α`，除了返回 `a` 你还能返回什么？
   手里没有别的 `α` 值，所以只有一种写法。

第 2 条在 E08 会展开讲，L00 不细说。

## 6.6 `namespace` / `end`：给名字加前缀

`namespace N` 到 `end N` 之间定义的每个名字，真名都是 `N.名字`。
两个作用：避免和别处重名；把一组相关的东西归堆。

这份文档每一节都用 `namespace S2`、`S3` …… 圈起来，
所以各节可以自由重用 `swap`、`double` 这种名字。
@@@ -/

namespace Inner
def value : Nat := 7
end Inner

#check Inner.value        -- 输出 S6.Inner.value：namespace 可以套
#eval Inner.value

/- @@@
在 namespace **里面**可以用短名字，出了 namespace 就得用全名。

注意一个细节：`namespace` 也会给 `inductive` 的**构造子**和
`structure` 的**字段**加前缀。所以 §4.2 的 `Dog` 定义在 `S4` 里，
它的构造子全名是 `S4.Dog.Iris`。

## 6.7 `open`：把前缀省掉

`open N` 之后，`N` 里的名字可以不写前缀直接用。
@@@ -/

open Inner
#eval value               -- 不用写 Inner.value 了

/- @@@
`open ... in` 只对**紧跟的那一条命令**生效，范围更小。
§5.3 的 `eval` 用的就是这个：
@@@ -/

open Inner in
#eval value

/- @@@
`open` 有一个坑，§5.3 已经撞过一次：如果两个 namespace 里有同名的东西，
`open` 之后那个名字就**有歧义**，Lean 会要求你写全名。
E02 的 `eval` 里 `And`、`Or`、`Not` 必须写全名就是这个原因——
Lean 自己在 `Prop` 上也用这三个名字。

## 6.8 `variable`：一次声明，多处共用

`variable (x : T)` 声明一个参数，之后**凡是用到 `x` 的定义**都会自动把它
加进自己的参数表。省得每条定义都重写一遍同样的参数。

它受 `section` / `namespace` 的范围限制，出了范围就失效。
@@@ -/

section
variable (base : Nat)

-- 下面两条都没写 (base : Nat)，但 variable 帮它们加上了
def addBase (m : Nat) : Nat := base + m
def mulBase (m : Nat) : Nat := base * m

end

#check (addBase)          -- Nat → Nat → Nat —— base 真的在参数表里
#eval addBase 10 5        -- 15

/- @@@
注意 `addBase` 的类型是 `Nat → Nat → Nat`：`variable` 声明的 `base`
排在**前面**，成了第一个参数。

## 6.9 auto-bound implicit：Lean 替你猜的隐式参数

E 文件里有一个现象必须认识，否则会一脸困惑：
类型里出现一个**从来没声明过**的标识符，代码却能编译。
@@@ -/

def myId (a : α) : α := a

#check @myId              -- {α : Sort u_1} → α → α —— α 是 Lean 自动加的

/- @@@
`α` 没有在任何地方声明。Lean 看见一个没定义过的标识符出现在类型里，
会**自动替你补一个隐式参数**。这叫 **auto-bound implicit（自动绑定隐式参数）**。

所以两件事要分清：

- `variable` 是你**明写**的共享参数（§6.8）；
- auto-bound implicit 是 Lean **替你猜**的隐式参数。

看到类型里有来历不明的单个字母（`α`、`β`、`P`、`Q`），先想到后者。
E 文件里的 `theorem use_left (h : P ∧ Q) : P := h.left` 就是这样——
`P` 和 `Q` 都是 Lean 自动补的。

## 6.10 本节练习

**[6.1]（判）** `abbrev MyNum := Nat` 和 `def MyNum' := Nat`
有什么实际区别？写 `def x : MyNum' := 3` 为什么会出问题？

**[6.2]（读）** 把下面这条定义的槽位指出来，并说出 `α` 和 `β` 是显式还是隐式、
`p` 的类型是什么、`(p.2, p.1)` 的类型是什么。

```lean
def swap {α β : Type u} (p : α × β) : β × α := (p.2, p.1)
```

**[6.3]（判）** 下面哪一条能编译？为什么？

```lean
#eval idImp Nat 3
#eval @idImp Nat 3
#eval idImp 3
```

**[6.4]（写）** 用 `let` 写一个 `def hypotLike (p : Nat × Nat) : Nat`，
先用 `let` 把两个分量分别命名为 `a`、`b`，再返回 `a * a + b * b`。

**[6.5]（写）** 定义一个 namespace `Demo`，里面放 `def seven : Nat := 7`，
然后在 namespace 外面用两种方式（全名、`open ... in`）各 `#eval` 一次。

---

**先自己做，再往下看。**

---
@@@ -/

namespace Answers_6

/- @@@
**[6.1]** `abbrev` 定义的名字是 reducible 的，Lean 会自动展开它；
`def` 不会（§6.1）。差别在 Lean 需要**看穿**这个名字去找东西的时候显出来。

`def x : MyNum' := 3` 出问题，是因为数字字面量 `3` 要按**类型**去查
「这个类型怎么表示 3」。Lean 看到的类型是 `MyNum'`，
它不肯展开成 `Nat`，于是查不到，报 `failed to synthesize instance ... OfNat MyNum' 3`。
`abbrev` 版本不会，因为 Lean 直接就把它当 `Nat` 看。
@@@ -/

abbrev MyNum  := Nat
def    MyNum' := Nat

def n1 : MyNum := 3
#eval n1 + 1              -- 4：透明，加法找得到

-- def n2 : MyNum' := 3   -- 报错：OfNat MyNum' 3
def n2 : MyNum' := (3 : Nat)   -- 要手动告诉 Lean 按 Nat 来读这个 3

-- #eval n2 + 1           -- 还是报错：HAdd MyNum' Nat ?m
#eval Nat.add n2 1        -- 4：直接点名用 Nat 的加法函数就行

/- @@@
**[6.2]** `def swap {α β : Type u} (p : α × β) : β × α := (p.2, p.1)`

| 槽位 | 内容 |
|---|---|
| 关键字 | `def` |
| 名字 | `swap` |
| 参数表 | `{α β : Type u}` 和 `(p : α × β)` |
| 返回类型 | `β × α` |
| 体 | `(p.2, p.1)` |

`α` 和 `β` 用**花括号**，所以是**隐式**参数（§6.4）；`p` 是显式的。
`p` 的类型是 `α × β`；`(p.2, p.1)` 的类型是 `β × α`——
因为 `p.2 : β` 排在前，`p.1 : α` 排在后（§5.5）。

**[6.3]** 只有第二和第三条能编译（§6.4）。

- `idImp Nat 3` **不行**：`α` 是隐式参数，不许显式传。
- `@idImp Nat 3` **行**：`@` 关闭隐式推断，所有参数变显式。
- `idImp 3` **行**：这是隐式参数的正常用法，Lean 从 `3` 推出 `α = Nat`。

（第一条那个报错长什么样，见 §9.4。）

**[6.4]** 思路：`let` 给中间结果起名字（§6.2）。
@@@ -/

def hypotLike (p : Nat × Nat) : Nat :=
  let a := p.1
  let b := p.2
  a * a + b * b

#eval hypotLike (3, 4)    -- 25

/- @@@
**[6.5]** 思路：namespace 里的名字真名带前缀（§6.6），`open` 省掉前缀（§6.7）。
@@@ -/

namespace Demo
def seven : Nat := 7
end Demo

#eval Demo.seven          -- 方式一：全名
open Demo in
#eval seven               -- 方式二：open ... in，只对这一条命令生效

end Answers_6
end S6

/- @@@
---

# 7. 命题与证明

这一节是前面所有东西的汇合点。关键在于：**没有新机制**。

证明就是 term，命题就是类型，所以第 2 节到第 6 节的每一条语法在这里照用。
`fun` 还是 `fun`，`match` 还是 `match`，`⟨ ⟩` 还是 `⟨ ⟩`。
唯一要学的是「哪个符号对应哪条规则」。

每讲完一个连接词，末尾有一句「以后看到……就写……」。
这些句子在 §12 汇总成速查表。
@@@ -/

namespace S7

/- @@@
## 7.1 `theorem`、`example`、`def` 的区别

三个关键字，**语法完全一样**，差别在用途：

| 关键字 | 用途 | 要名字吗 |
|---|---|---|
| `def` | 定义**数据**或函数（`Type` 这一侧） | 要 |
| `theorem` | 定义**证明**（`Prop` 这一侧） | 要 |
| `example` | 定义一个**不需要名字**的东西，当场用完就扔 | **不要** |

技术上 `def` 也能证明命题，但 `theorem` 向读者宣告「这是一条定理」，
而且 Lean 对它的处理稍有不同（标记为 irreducible，不会在别处被展开）。
证命题就用 `theorem`。

`example` 用在「我只想演示这件事可证，不打算以后引用它」的时候，
所以 E 文件里满篇都是 `example`。
@@@ -/

def     aNumber : Nat       := 42        -- 数据，用 def
theorem aProof  : 2 + 2 = 4 := rfl       -- 证明，用 theorem，有名字
example         : 2 + 2 = 4 := rfl       -- 证明，不要名字

#check aProof

/- @@@
`example` 还可以**省掉类型**，只写 `:=` 和体，让 Lean 推断：
@@@ -/

example := (3, true)                     -- 类型是 Nat × Bool
example := Nat.add 3 4

/- @@@
## 7.2 每个符号怎么读

这张表是本节的目录。

| 符号 | 名称 | 中文读法 | 它的证明是什么 | 小节 |
|---|---|---|---|---|
| `=` | equality（等式） | 「……等于……」 | `rfl`（两边同一范式） | §7.3 |
| `→` | implication（蕴含） | 「如果……那么……」 | 一个**函数** | §7.4 |
| `∀` | universal quantifier（全称量词） | 「对任意……都有……」 | 一个**函数** | §7.5 |
| `∧` | conjunction（合取） | 「……**并且**……」 | 一个**对**（pair） | §7.6 |
| `∨` | disjunction（析取） | 「……**或者**……」 | 一个**带标签的选择** | §7.7 |
| `∃` | existential quantifier（存在量词） | 「**存在**一个……使得……」 | 一个**见证 + 证据** | §7.8 |
| `¬` | negation（否定） | 「并非……」 | 一个到 `False` 的**函数** | §7.9 |
| `↔` | biconditional（双条件） | 「……**当且仅当**……」 | 一**对**函数 | §7.11 |

每个连接词都配一条 **introduction rule（引入规则）**（怎么**造**它的证明）
和一条 **elimination rule（消去规则）**（怎么**用**它的证明）。
整门课的骨架就是这两列。

## 7.3 `=`：等式和 `rfl`

先讲这个，因为后面每一节都要用它举例。

`a = b` 只是 `Eq a b` 的**记法**。`Eq` 的定义是：

```lean
inductive Eq : α → α → Prop where
  | refl (a : α) : Eq a a
```

这是一个索引族（§4.2）：`Eq` 不是一个命题，它是一个函数，
吃两个同类型的值，还你一个命题。

**只有一个构造子** `Eq.refl`，而且它只能造 `a = a` 形状的证明。
所以：任何值都可证等于它自己，而且**没有别的等式证明**。
这就是等式的引入规则。
@@@ -/

#check (@Eq)
#check (Eq 1 1)
#check (Eq 1 2)           -- 这是一个合法的命题，只是没有值（没有证明）

example : Eq 1 1 := Eq.refl 1
example : 1 = 1 := Eq.refl 1
example : 1 = 1 := rfl

/- @@@
`rfl` 是 `Eq.refl` 的方便写法，它的那个参数是隐式的，Lean 从目标里推出来：
@@@ -/

#check @Eq.refl           -- ∀ {α : Sort u} (a : α), a = a —— 参数显式
#check @rfl               -- ∀ {α : Sort u} {a : α}, a = a —— 参数隐式

/- @@@
**关键一点**：`rfl` 能证 `a = b`，条件是 `a` 和 `b` **归约到同一个范式**
（§2.2 的 normal form）。**不要求它们字面一样。**
@@@ -/

example : 1 + 1 = 2 := rfl          -- 1 + 1 归约到 2，两边同一范式
example : 2 + 2 = 4 := rfl
example : Nat.succ 7 = 8 := rfl
example : (3 - 10 : Nat) = 0 := rfl

/- @@@
这叫 **definitional equality（定义等式）**：等式由**计算**来认证。

这也解释了一个一开始会困惑的显示结果：
@@@ -/

#check (rfl : 1 + 1 = 2)  -- 显示成 rfl : 1 + 1 = 1 + 1

/- @@@
Lean 按 `rfl` 自己的类型（`a = a`）去显示，它取 `a := 1 + 1`。
而 `1 + 1` 和 `2` 是同一个范式，所以 `1 + 1 = 1 + 1` 和 `1 + 1 = 2`
指的是同一个命题。

`.symm` 是等式最常用的一个方法，把 `a = b` 翻成 `b = a`：
@@@ -/

theorem addZeroComm (n : Nat) : n + 0 = n → n = n + 0 :=
  fun h => h.symm

/- @@@
### 补充：`Prop` 里的证明彼此相等

这里顺手把一件会让人吃惊的事说清楚，因为它只用到 `rfl`。

`Prop` 有一条特殊规则叫 **proof irrelevance（证明无关性）**：
**同一个命题的任何两个证明都被视为相等。** 看下面——
这个类型有三个不同的构造子，但两个不同构造子造出来的值居然 `rfl` 可证相等：
@@@ -/

inductive JorgIsFromToronto : Prop where
| driversLicense
| utilityBill
| healthCard

example :
  JorgIsFromToronto.driversLicense = JorgIsFromToronto.healthCard :=
rfl

/- @@@
把 `Prop` 换成 `Type`，这个 `rfl` 立刻就不成立了：
@@@ -/

inductive Cat : Type where
| siamese
| tabby

-- example : Cat.tabby = Cat.siamese := rfl   -- 报错：造不出这个等式

/- @@@
**同一份代码形状，换一个宇宙，结论相反。** 原因回到 §4.1 那张表：
`Type` 的值是**数据**，`3` 和 `4` 就是不同的；
`Prop` 的值是**证明**，而我们只关心「有没有证明」，不关心是哪一个。

`Cat.tabby ≠ Cat.siamese` 怎么**证**出来，见 §7.10。

> **看到目标是 `a = b`，先试 `rfl`（两边算一算是不是同一个东西）。
> 看到假设是 `h : a = b`，可以 `h.symm` 翻方向。**

## 7.4 `→`：蕴含

### 引入：写一个 `fun`

要证 `P → Q`，就假设有一个 `P` 的证明，去造一个 `Q` 的证明。
也就是**写一个函数**。语法和 §3.1 一模一样。
@@@ -/

theorem pImpP (P : Prop) (h : P) : P := h              -- 恒等函数，就是 P → P

example {P Q : Prop} (hq : Q) : P → Q := fun _ => hq   -- 用不到前提就写 _

/- @@@
### 消去：函数应用

有了 `h : P → Q` 和 `p : P`，写 `h p` 就得到 `Q`。就是函数应用（§3.3）。

下面这条同时是「蕴含的传递性」和「函数复合」——一份代码，两种读法：
@@@ -/

theorem impliesTrans (P Q R : Prop)
    (hpq : P → Q) (hqr : Q → R) : P → R :=
  fun hp => hqr (hpq hp)

/- @@@
**三层拆法**：

1. **整体**：给定 `P → Q` 和 `Q → R`，造一个 `P → R`。
2. **逐 token**：`fun hp => ...` 引入前提 `hp : P`；
   `hpq hp` 是函数应用，类型 `Q`；`hqr (hpq hp)` 又一次应用，类型 `R`。
   括号是必须的——不加会读成 `(hqr hpq) hp`（§3.3）。
3. **逻辑对应**：`→ introduction`（假设 `hp`）→ `→ elimination`（应用 `hpq`）
   → `→ elimination`（应用 `hqr`）。目标从 `P → R` 变成 `R`，
   再被 `hqr (hpq hp)` 关闭。
4. **迁移**：换成三段 `P → Q`、`Q → R`、`R → S`，证 `P → S`？
   多一层应用：`fun hp => hrs (hqr (hpq hp))`。形状不变，只是嵌套深一层。

> **看到目标是 `P → Q` 就写 `fun h => ?`，目标变成 `Q`，手里多了 `h : P`。
> 看到假设是 `h : P → Q`，想用它就得先弄到一个 `P`，然后写 `h p`。**

## 7.5 `∀`：全称量词

### `∀` 和 `→` 其实是一回事

`∀ (n : Nat), P n` 就是函数类型 `(n : Nat) → P n`。
区别只在于：`∀` 绑定的那个名字可以在**返回类型里出现**（这就是依值类型，§6.4）。
而 `P → Q` 里 `Q` 不依赖前提，所以不需要给前提起名字。

一句话：**一个 `∀` 命题的证明永远就是一个函数。**

所以 §6.4 的 `swapForall` 能把 `∀` 当函数类型写，
而 §7.4 的 `fun` 语法在这里完全照用。
@@@ -/

-- 用 ∀ 写出来：fun 绑定的 n 在返回类型 `n + 0 = n` 里用到了
theorem addZeroAll : ∀ n : Nat, n + 0 = n := fun n => Nat.add_zero n

-- 把 ∀ 的变量提到冒号左边，完全等价
theorem addZeroAll' (n : Nat) : n + 0 = n := Nat.add_zero n

#check @addZeroAll
#check @addZeroAll'

/- @@@
**关于 `Nat.add_zero` 这个名字**：它是 Lean 标准库里一条已经证好的定理，
类型是 `∀ (n : Nat), n + 0 = n`。你不可能自己猜到这个名字，
也不需要记——E 文件用到库定理时同样是直接抄名字。
查名字的办法是 `exact?` 之类的 tactic 或者翻文档，L00 不展开。
这份文档里凡是出现 `Nat.某某` 的地方，都属于这一类。

### 引入：假设一个任意的，推出结果

这叫 **universal generalization（全称概括）**，写法就是 `fun`。

### 消去：应用到具体的

这叫 **universal specialization（全称特化）**，写法就是函数应用。

下面这条定理和它的使用，是这件事最干净的演示：
@@@ -/

def swap {α β : Type u} (p : α × β) : β × α := (p.2, p.1)

theorem swapInvolutive {α β : Type u} (x : α) (y : β) :
    swap (swap (x, y)) = (x, y) :=
  rfl

#check (swapInvolutive 0 true)       -- ∀ elimination：特化到 0 和 true

/- @@@
**三层拆法**：

1. **整体**：对任意类型 `α β`、任意 `x : α`、`y : β`，
   `swap` 作用两次等于没作用。
2. **逐 token**：`{α β : Type u}` 是隐式参数（§6.4）；
   `(x : α) (y : β)` 是显式参数；体是 `rfl`——
   因为 `swap (swap (x, y))` 归约之后**正好**就是 `(x, y)`，
   两边同一范式，所以 `rfl` 够了（§7.3）。
3. **逻辑对应**：`∀ introduction` 四次（四个参数）→ `Eq introduction`（`rfl`）。
4. **迁移**：换成三元组？`swap` 的类型接不了三元组，得先改 `swap`；
   但证明的形状（一个 `rfl`）一个字不变。

`#check (swapInvolutive 0 true)` 这一行值得停一下：
一般的定理**就是**那个函数，而证明本身是函数，所以你可以像平常一样**应用**它，
得到特例。这就是为什么要证一般性的定理——
以后直接用，不用把整个推导重做一遍。

> **看到目标是 `∀ x, P x` 就写 `fun x => ?`，目标变成 `P x`。
> 看到假设是 `h : ∀ x, P x`，想用它就写 `h a`，得到 `P a`。**

## 7.6 `∧`：合取

`And` 的定义（§4.3 预告过）：

```lean
structure And (a b : Prop) : Prop where
  intro :: (left : a) (right : b)
```

一个 `structure`，两个字段。所以它和 `Prod` 是**同一个结构**（§4.6），
只差一个宇宙。这对东西叫 **Curry-Howard twins（Curry-Howard 孪生）**。

| | 引入 | 消去 |
|---|---|---|
| `Prod` | `Prod.mk a b` / `(a, b)` / `⟨a, b⟩` | `.1` `.2` / `.fst` `.snd` |
| `And` | `And.intro p q` / `⟨p, q⟩` | `.1` `.2` / `.left` `.right` |

左右两行的语法是同一套，§5.4 的 `⟨ ⟩` 和 §5.5 的投影在这里原样照用。
@@@ -/

example : (7 > 0) ∧ (7 ≤ 10) :=
  And.intro         -- And introduction 应用到两个证明上
    (by decide)     -- 判定过程，给出 7 > 0 的证明（§8.8、§11.1）
    (by decide)     -- 判定过程，给出 7 ≤ 10 的证明

/- @@@
一般化到任意命题。这是**全文最该背下来的一段**，
因为它把「拆一个 ∧、装一个 ∧」的完整流程写在四行里：
@@@ -/

theorem andCommA {P Q : Prop} : P ∧ Q → Q ∧ P :=
  fun pq =>         -- → introduction（§7.4）
    And.intro       -- And introduction
      pq.right      -- And elimination，取右
      pq.left       -- And elimination，取左

/- @@@
三种等价写法，一路简化：
@@@ -/

theorem andCommB {P Q : Prop} : P ∧ Q → Q ∧ P :=
  fun ⟨p, q⟩ => ⟨q, p⟩          -- 左边拆，右边装，都用 ⟨ ⟩（§5.4）

theorem andCommC {P Q : Prop} : P ∧ Q → Q ∧ P
  | ⟨p, q⟩ => ⟨q, p⟩            -- 再省掉 fun 和 :=（§5.2 的等式形式）

/- @@@
**逐 token 拆 `fun ⟨p, q⟩ => ⟨q, p⟩`**：

- `=>` **左边**的 `⟨p, q⟩` 是**模式**：把传进来的 `P ∧ Q` 的证明拆开，
  左半边绑定到名字 `p`（类型 `P`），右半边绑定到 `q`（类型 `Q`）。
  这一步是 **And 的 elimination rule**。
- `=>` **右边**的 `⟨q, p⟩` 是**构造**：把 `q` 和 `p` 按相反顺序装进一个
  `Q ∧ P` 的证明。这一步是 **And 的 introduction rule**（`And.intro`）。

和 §5.4 拆 `Prod` 的那段对比一下：**一个字都没变**，只是类型住到 `Prop` 里了。

**迁移演示**。同样的形状用在「∧ 结合律」上，变的只是括号位置：
@@@ -/

example {P Q R : Prop} : P ∧ (Q ∧ R) → (P ∧ Q) ∧ R :=
  fun ⟨p, q, r⟩ => ⟨⟨p, q⟩, r⟩

example {P Q R : Prop} : (P ∧ Q) ∧ R → P ∧ (Q ∧ R) :=
  fun ⟨⟨p, q⟩, r⟩ => ⟨p, q, r⟩

/- @@@
注意 `⟨p, q, r⟩` 在左边是「拆嵌套的 ∧」，在右边是「装嵌套的 ∧」，
而且两层可以拍平成一层。但 `⟨⟨p, q⟩, r⟩` 的括号**不能**拍平——
`(P ∧ Q) ∧ R` 是**左**嵌套，拍平只对**右**嵌套有效。
这就是 §5.4 讲过的那条规则，在 `∧` 上一模一样。

> **看到目标是 `P ∧ Q` 就写 `⟨?, ?⟩`，变成两个目标 `P` 和 `Q`。
> 看到假设是 `h : P ∧ Q`，就用 `h.left` 和 `h.right` 把两半都拿到手。**

## 7.7 `∨`：析取

`Or` 的定义：

```lean
inductive Or (a b : Prop) : Prop where
  | inl (h : a) : Or a b
  | inr (h : b) : Or a b
```

一个 `inductive`，两个构造子。所以它和 `Sum`（§4.6）是同一个结构。

| | 引入 | 消去 |
|---|---|---|
| `Sum` | `Sum.inl a` / `Sum.inr b` | `match s with \| Sum.inl a => ? \| Sum.inr b => ?` |
| `Or` | `Or.inl p` / `Or.inr q` | `match h with \| Or.inl p => ? \| Or.inr q => ?` |

**引入和消去是不对称的**，这一点和 `∧` 完全相反：

- 造一个 `∨` 的证明：**挑一边**，证那一边就行。
- 用一个 `∨` 的证明：**两边都得处理**，因为你不知道手里是哪一边。
@@@ -/

example : 1 = 1 ∨ 1 = 2 := Or.inl rfl
example : 1 = 2 ∨ 1 = 1 := Or.inr rfl

theorem orComm {P Q : Prop} (h : P ∨ Q) : Q ∨ P :=
  match h with
  | Or.inl hp => Or.inr hp        -- 手里是 P，装到右边
  | Or.inr hq => Or.inl hq        -- 手里是 Q，装到左边

/- @@@
**三层拆法**：

1. **整体**：∨ 的交换律。
2. **逐 token**：`match h with` 对 `h` 做 case analysis（§5.1）；
   `Or.inl hp` 是**模式**，它说「假设 `h` 是用 `Or.inl` 造的」，
   并把装在里面的证明绑定到 `hp`（类型 `P`）；
   `=>` 右边的 `Or.inr hp` 是**构造**，把 `hp` 装进 `Q ∨ P` 的右边。
3. **逻辑对应**：`Or elimination`（分两种情况）→ 每支各用一次 `Or introduction`。
4. **迁移**：`(P ∨ Q) ∨ R → P ∨ (Q ∨ R)` 呢？外层两支，左支还要再分两支，
   一共三个分支，每支装到新结构里对应的位置。模式嵌套，构造也嵌套。

下面这条把 `∨` 消去和 `∧` 消去放在同一个证明里，是个好的综合例子
（`_Q` 前面的下划线表示那个参数没用上，§3.1）：
@@@ -/

theorem deMorganOrNot : ∀ (P Q : Prop), ¬P ∨ ¬Q → ¬(P ∧ Q) :=
  fun P _Q =>                           -- ∀ intro（两次）
    fun h =>                            -- → intro
      fun pandq =>                      -- → intro（¬X 就是 X → False，§7.9）
        let p : P := And.left pandq     -- And elim，取左
        let q := pandq.right            -- And elim，取右
        match h with                    -- Or elim（分情况）
        | Or.inl np => np p             -- → elim（函数应用）
        | Or.inr nq => nq q             -- → elim（函数应用）

/- @@@
> **看到目标是 `P ∨ Q` 就挑一边：`Or.inl ?`（目标变 `P`）或 `Or.inr ?`（目标变 `Q`）。
> 看到假设是 `h : P ∨ Q` 就 `match h with`，写两个分支，每支里你知道自己有哪一边。**

## 7.8 `∃`：存在量词

`Exists` 的定义（抄一份改名，免得和库里冲突）：
@@@ -/

inductive MyExists {α : Sort u} (p : α → Prop) : Prop where
| intro (w : α) (h : p w) : MyExists p

#check @Exists
#check @Exists.intro

/- @@@
**怎么读这个定义**：

- `MyExists` 的参数是一个**谓词** `p : α → Prop`（§4.2），不是一个值。
  正因如此它表达的是「关于**某个** `α` 值」的断言，而不是关于某个特定值的断言。
- 唯一的构造子 `intro` 要两个参数：一个 **witness（见证）** `w : α`，
  和一个 `h : p w`，即「`p` 对**那个** `w` 成立」的证据。
- **第二个参数的类型依赖第一个参数的值**。又是依值类型（§6.4）。

所以：**一个存在命题的证明永远就是一个「值 + 关于那个值的证据」的对。**

### 引入：举出一个见证

要证「存在」，就**把它造出来**，然后证明它符合要求。
用 §4.2 的狗来演示（那份定义在 `S4` 的 namespace 里，这里在本节再定义一份）：
@@@ -/

inductive Dog : Type where
| Iris
| Fido
| Sargent

open Dog

inductive Friendly : Dog → Prop where
| irisFriendly : Friendly Iris
| fidoFriendly : Friendly Fido

open Friendly

example : ∃ (d : Dog), Friendly d :=
  Exists.intro Iris irisFriendly          -- 完整写法

example : ∃ (d : Dog), Friendly d :=
  ⟨Iris, irisFriendly⟩                    -- 匿名构造子（§5.4）

/- @@@
为什么 `⟨_, _⟩` 能用在 `∃` 上？因为 `Exists` 只有一个构造子，没有歧义（§5.4）。
`⟨w, pf⟩` 就是 `Exists.intro w pf`。

证据可以是任意复合的东西，因为 `h` 的要求只是「证明 `p w`」，
`p w` 具体是什么命题无所谓：
@@@ -/

inductive Furry : Dog → Prop where
| irisFurry : Furry Iris
| sargentFurry : Furry Sargent

open Furry

def Suitable (d : Dog) : Prop := Friendly d ∧ Furry d

example : ∃ (d : Dog), Suitable d :=
  ⟨Iris, And.intro irisFriendly irisFurry⟩

/- @@@
在 `Nat` 上也一样，见证是个数、证据是关于那个数的证明：
@@@ -/

example : ∃ n : Nat, n = 3 := Exists.intro 3 rfl
example : ∃ n : Nat, n + 1 = 4 := ⟨3, rfl⟩
example : ∃ n : Nat, n > 3 := ⟨4, by decide⟩
example : ∃ a : Nat, ∃ b : Nat, a + b = 5 := ⟨2, 3, rfl⟩

/- @@@
最后一行的 `⟨2, 3, rfl⟩` 是嵌套的两层 `∃` 拍平成一层（§5.4）。

有一个观察必须记住：**命题本身不记录用了哪个见证。**
下面两个证明用了不同的见证，但证的是**同一个命题**：
@@@ -/

example : ∃ n : Nat, n < 10 := ⟨0, by decide⟩
example : ∃ n : Nat, n < 10 := ⟨9, by decide⟩

/- @@@
记住这一点，它正是消去规则要带一条限制的原因。

### 消去：把见证拆出来

因为只有一个构造子，任何证明一定是 `Exists.intro w pf` 的形状，
所以可以模式匹配，拿到一个见证的名字 `w` 和一个 `pf : p w`。

有两条约束：

1. `w` 是一个**局部**名字，只在那个分支里有效；
2. 因此，**要证的目标里不能出现 `w`**——
   不管藏在里面的是哪个值，你证的都是同一个固定的结论。

一般规则长这样：
@@@ -/

example {α : Type} (R : α → Prop) (S : Prop) :
    (∃ x : α, R x) → (∀ x : α, R x → S) → S :=
  fun existsRx =>
    fun useWitness =>
      match existsRx with
      | Exists.intro w pf => useWitness w pf

/- @@@
这条规则库里打包好了，就是 `Exists.elim`：
@@@ -/

#check @Exists.elim

/- @@@
把它的签名逐行读一遍：

```text
Exists.elim.{u}                 -- 如果 u 是任意宇宙层级
  {α : Sort u}                  -- 如果 α 是 u 里的任意类型
  {p : α → Prop}                -- 如果 p 是 α 值的任意性质
  {b : Prop}                    -- 如果 b 是任意想要的结论

  (h₁ : ∃ x, p x)               -- 如果至少有一个 x 满足 p
  (h₂ : ∀ (a : α), p a → b)     -- 如果任意 a 满足 p 就能得到 b
  :                             -- 那么
  b                             -- b
```

### 坑：`→` 比 `∀` 结合得紧

第二个假设 `(h₂ : ∀ (a : α), p a → b)` 是最容易读错的地方。
`→` 比 `∀` **结合得紧**，所以它应该读成

```text
∀ (a : α), (p a → b)
```

也就是「**给定任意一个 `a`，如果 `a` 有性质 `p`，那么 `b`**」。

**不是** `(∀ (a : α), p a) → b`，也就是
「如果每个 `a` 都有性质 `p`，那么 `b`」。

两者意思差很远。`→` 会先抓住 `p a` 和 `b`，`∀` 才作用到整个结果上。
（§3.4 讲过 `→` 在**类型**里右结合；这是它在**命题**里的另一面。）

实际写证明时，term 模式下的惯用法是 `fun ⟨w, pf⟩ => ...`
（`⟨ ⟩` 用在模式位置，§5.4）：
@@@ -/

example
    {α : Type}
    (P Q : α → Prop)
    (imp : ∀ x : α, P x → Q x) :
    (∃ x : α, P x) → (∃ x : α, Q x) :=
  fun ⟨w, pw⟩ => ⟨w, imp w pw⟩

/- @@@
**三层拆法**：

1. **整体**：如果每个 `x` 的 `P x` 都能升级成 `Q x`，
   那么「存在满足 `P` 的」就能推出「存在满足 `Q` 的」。
2. **逐 token**：`fun ⟨w, pw⟩ =>` 一次做两件事——引入前提（`→ intro`）
   并当场把它拆开（`∃ elim`），得到 `w : α` 和 `pw : P w`；
   右边 `⟨w, imp w pw⟩` 是 `∃ intro`：见证还用 `w`，
   证据是 `imp w pw`（`∀ elim` 特化到 `w`，再 `→ elim` 应用到 `pw`）。
3. **逻辑对应**：`→ intro` → `∃ elim` → `∀ elim` → `→ elim` → `∃ intro`，
   五步在一行里。
4. **迁移**：换成 `(∃ x, P x ∧ Q x) → (∃ x, Q x ∧ P x)`？
   模式再嵌一层：`fun ⟨w, pw, qw⟩ => ⟨w, qw, pw⟩`。见证不变，只换证据的顺序。
@@@ -/

example {α : Type} (P Q : α → Prop) :
    (∃ x : α, P x ∧ Q x) → (∃ x : α, Q x ∧ P x) :=
  fun ⟨w, pw, qw⟩ => ⟨w, qw, pw⟩

/- @@@
> **看到目标是 `∃ x, P x` 就写 `⟨w, ?⟩`，自己挑一个 `w`，目标变成 `P w`。
> 看到假设是 `h : ∃ x, P x` 就 `fun ⟨w, pf⟩ => ...` 或
> `match h with | ⟨w, pf⟩ => ...`，但记住结论里不能提 `w`。**
@@@ -/

/- @@@
## 7.9 `True`、`False`、`¬`

### `True`：恰好一个证明

`True` 恰好有一个证明，叫 `True.intro`（对应 `Unit` 的 `Unit.unit`，§4.5）。
@@@ -/

example : True := True.intro
#check @True.intro

/- @@@
### `False`：没有证明

`False` **没有**构造子，所以没有证明（对应 `Empty`，§4.5）。

但是你可以写一个**从 `False` 出发**的函数：`False.elim`。
它的意思是「从矛盾可以推出任何东西」，拉丁文叫 *ex falso quodlibet*。
@@@ -/

#check @False.elim        -- {C : Sort u} → False → C

theorem exFalso {P : Prop} (h : False) : P := False.elim h

/- @@@
注意 `False.elim` 的返回类型是 `Sort u`（§6.4）而不是 `Prop`——
所以它既能推出命题，也能推出数据类型。

还有一个方便函数 `absurd`：给它一个 `P` 和一个 `¬P`，它还你任何东西。
@@@ -/

#check @absurd            -- {a : Prop} → {b : Sort u} → a → ¬a → b

/- @@@
### `¬`：否定就是「到 `False` 的函数」

这是整门课最该亲手验证一次的一件事。
`¬P` **不是**一个新的原始概念，它是**定义**出来的（`#print` 见 §9.1）：

```lean
def Not (a : Prop) : Prop := a → False
```

所以 `¬P` 就是 `P → False`，**完全一样的东西**。后果是：

- 要**证** `¬P`：写一个 `fun h => ...`，`h : P`，目标是造出 `False`。
  这就是 §7.4 的 `→` 引入，一个字不用改。
- 要**用** `h : ¬P`：手里有一个 `p : P` 时，写 `h p`，得到 `False`。
  这就是 §7.4 的 `→` 消去。

自己定义一个 `neg` 就能看清这件事——两个 `example` 的证明一字不差，
因为 `neg MyFalse` 和 `¬MyFalse` 是**同一个类型**：
@@@ -/

def neg (a : Prop) : Prop := a → False

inductive MyFalse : Prop where      -- 没有构造子，和 False 一样

example : neg MyFalse
| m => nomatch m

example : ¬MyFalse
| m => nomatch m

/- @@@
（这里的 `nomatch` 就是 §5.7 那个零分支匹配：`MyFalse` 没有构造子，
所以需要写的分支数是零。§7.10 细讲它在证明里的用法。）

下面是「证 `¬`」的标准模式，E 文件里反复出现：
@@@ -/

theorem noContradiction {P : Prop} : ¬(P ∧ ¬P) :=
  fun pandnotp =>                     -- 引入 P ∧ ¬P，目标变成 False
    let p  : P  := pandnotp.left      -- ∧ elim（§7.6）
    let np : ¬P := pandnotp.right     -- ∧ elim；np 的类型是 P → False
    np p                              -- → elim：得到 False

example {P : Prop} : ¬(P ∧ ¬P) :=
  fun pnp => pnp.right pnp.left       -- 同一件事，一行写完

/- @@@
**三层拆法**（第一个版本）：

1. **整体**：没有命题能和它的否定同时成立。
2. **逐 token**：目标 `¬(P ∧ ¬P)` 展开就是 `(P ∧ ¬P) → False`，
   所以 `fun pandnotp =>` 是 `→ intro`，之后目标是 `False`；
   `.left` 和 `.right` 是 `∧ elim`；
   `np` 的类型是 `¬P` 也就是 `P → False`，
   所以 `np p` 是函数应用，类型正好是 `False`。
3. **逻辑对应**：`→ intro` → `∧ elim` 两次 → `→ elim`。
   **这个策略叫 proof by negation（证否）**，它是构造性的、随时可用。
   它**不是** proof by contradiction（归谬法），尽管关键步骤都是推出矛盾。
   区别见 §11.3。
4. **迁移**：在有 `¬P` 的情况下证 `¬(P ∧ Q)`？
   `fun h => fun pq => h pq.left`。形状一样：引入、取分量、应用。

再看一条，它把「证 `¬`」和「用 `¬`」摆在一起
（DeMorgan 定律的一个方向，完整的四条留给 E05 文档）：
@@@ -/

theorem deMorganNotOr (P Q : Prop) : ¬(P ∨ Q) → (¬P ∧ ¬Q) :=
  fun notPorQ =>                      -- 引入 ¬(P ∨ Q)
    And.intro                         -- 目标是 ∧，所以装一个对（§7.6）
      (fun p => notPorQ (Or.inl p))   -- 证 ¬P：假设 p，造 P ∨ Q，喂给 notPorQ
      (fun q => notPorQ (Or.inr q))   -- 证 ¬Q：同理，换 Or.inr

/- @@@
> **看到目标是 `¬P` 就写 `fun h => ?`，`h : P`，目标变成 `False`。
> 看到假设是 `h : ¬P`，去找一个 `P` 的证明 `p`，`h p` 就是 `False`。
> 拿到 `False` 之后用 `False.elim` 推出你想要的任何东西。**

## 7.10 `nomatch` 在证明里

§5.7 讲了 `nomatch` 的机制：对一个**造不出来的**值做匹配，分支数是零。
在证明里它特别有用，因为这里经常出现「构造子存在、但一个都对不上形状」的情况。

### 用 `nomatch` 证两个值不相等

§7.3 留了个尾巴：`Cat.tabby = Cat.siamese` 怎么**证伪**？
（`Cat` 就是 §7.3 定义的那个两构造子类型。）
@@@ -/

example : ¬ (Cat.tabby = Cat.siamese)
| m => nomatch m

/- @@@
**读法**：目标 `¬(Cat.tabby = Cat.siamese)` 就是
`(Cat.tabby = Cat.siamese) → False`（§7.9），所以写一个函数，
假设拿到一个证明 `m`。

`Eq` 唯一的构造子是 `Eq.refl`（§7.3），它只能造 `a = a` 形状的证明，
造不出两个**不同构造子**之间的等式。所以 `m` 没有任何可能的形状，
零个分支，`nomatch` 直接结案。

注意对比 §7.3 的 `JorgIsFromToronto`：那个在 `Prop` 里，
两个构造子造的证明 `rfl` 可证相等；`Cat` 在 `Type` 里，
两个构造子造的值 `nomatch` 可证不等。

### 用 `nomatch` 反驳一个全称命题

这是全文最值得记住的一段代码。直接用 §7.8 定义的 `Dog` 和 `Friendly`
（它们在本节的 namespace 里，而且已经 `open` 过，所以能直接写 `Sargent`）：
@@@ -/

example : ¬(∀ (d : Dog), Friendly d) :=
  fun allDogsFriendly =>
    let sf := allDogsFriendly Sargent   -- ∀ elimination：特化到 Sargent
    nomatch sf                          -- 造不出 Friendly Sargent

/- @@@
**三层拆法**：

1. **整体**：在证明「并非每只狗都 friendly」。
2. **逐 token**：`fun allDogsFriendly => ...` 引入假设
   （`¬X` 就是 `X → False`，所以证 `¬X` 就是写一个从 `X` 出发的函数，§7.9）；
   `allDogsFriendly` 的类型是 `∀ (d : Dog), Friendly d`，它**是个函数**，
   所以 `allDogsFriendly Sargent` 是函数应用，类型是 `Friendly Sargent`；
   `let sf := ...` 给这个结果起名字（§6.2）；`nomatch sf` 结案。
3. **逻辑对应**：`→ introduction`（假设前提）→ `∀ elimination`（特化到 Sargent，§7.5）
   → 对 `Friendly Sargent` 做 case analysis，发现零个分支，得到 `False`。
   为什么零个分支？回到 §4.2：`Friendly` 的构造子列表里**没有**
   任何一个的类型是 `Friendly Sargent`。
4. **迁移**：换成「并非每只狗都 Furry」？要换见证——
   `Furry` 有 `Iris` 和 `Sargent` 的证据、没有 `Fido` 的，所以应该特化到 `Fido`。
   其他一个字都不用改。

## 7.11 `↔`：双条件

`Iff` 是一个 `structure`，两个字段，各是一个方向的蕴含。
所以它和 `(P → Q) × (Q → P)` 同构。

| | 引入 | 消去 |
|---|---|---|
| 写法 | `Iff.intro 正向 反向`，或 `⟨正向, 反向⟩` | `h.mp`（正向）、`h.mpr`（反向） |

`mp` 是 *modus ponens* 的缩写，`mpr` 是 *modus ponens reverse*。
@@@ -/

#check @Iff.intro
#check @Iff.mp            -- (a ↔ b) → a → b
#check @Iff.mpr           -- (a ↔ b) → b → a

example : (1 + 1 = 2) ↔ (2 = 1 + 1) :=
  Iff.intro (fun h => h.symm) (fun h => h.symm)

theorem andCommIff {P Q : Prop} : (P ∧ Q) ↔ (Q ∧ P) :=
  Iff.intro
    (fun ⟨p, q⟩ => ⟨q, p⟩)
    (fun ⟨q, p⟩ => ⟨p, q⟩)

-- 用它：取出需要的那个方向
example {P Q : Prop} (h : P ∧ Q) : Q ∧ P := andCommIff.mp h

/- @@@
> **看到目标是 `P ↔ Q` 就写 `Iff.intro ? ?`，变成两个目标 `P → Q` 和 `Q → P`。
> 看到假设是 `h : P ↔ Q`，用 `h.mp` 或 `h.mpr` 取出需要的那个方向。**

## 7.12 `sorry` 和 `_`

这两个长得都像「洞」，但作用完全相反，别搞混。

### `sorry`：先占个位

`sorry` 可以当**任何类型**的值用。它让文件编译通过，但产生一条
`declaration uses 'sorry'` 的警告，告诉你这里还有个洞。

写证明时的标准用法：先把骨架搭好，洞用 `sorry` 填上，然后一个一个填实。
E 文件的练习题就是这样留白的。
@@@ -/

example : 1 = 1 := sorry

example {P Q : Prop} : P ∧ Q → Q ∧ P :=
  fun h => ⟨sorry, sorry⟩        -- 骨架先搭好，两个洞待填

/- @@@
### `_`：让 Lean 告诉你缺什么

`_` 的意思是「这里的东西你能推出来，你填」。推不出来就**报错**，
而那个报错**就是答案**——它会告诉你当前上下文里有什么、还缺什么。

| | 作用 | 推不出来时 |
|---|---|---|
| `sorry` | 「我知道这里缺东西，先让它过」 | 编译通过，一条警告 |
| `_` | 「这个你能推出来，你填」 | **报错**，并打印出它想要什么 |

E05 和 E07 大量利用 `_` 的这个性质：故意写一个 `_`，
让 Lean 报出「我需要什么」，那个报错信息就是「这里卡住了，缺的正是这个」的证据。
比如下面这段（注释掉的，取消注释能看到报错）：

```lean
-- example (P : Prop) : ¬¬P → P :=
--   fun notNotP => False.elim (notNotP _)
```

报的错是：

```text
error: don't know how to synthesize placeholder
context:
P : Prop
notNotP : ¬¬P
⊢ ¬P
```

最后那行 `⊢ ¬P` 就是答案：卡住的地方正是「缺一个 `¬P` 的证明」。
（这个具体例子为什么卡住，见 §11.2；
怎么把这样的报错**钉进源码**里让它不破坏编译，见 §9.4。）

## 7.13 本节练习

**[7.1]（读）** 把下面每一步用的规则名写出来（哪个类型的 introduction
还是 elimination），以及每一步之后目标是什么。

```lean
theorem t {P Q : Prop} : P ∧ Q → Q ∨ P :=
  fun h => Or.inl h.right
```

**[7.2]（写）** 证 `example {P Q : Prop} : P → (Q → P)`。

**[7.3]（写）** 证 `example {P Q R : Prop} : P ∧ (Q ∨ R) → (P ∧ Q) ∨ (P ∧ R)`。

**[7.4]（写）** 证 `example : ∃ n : Nat, n * n = 49`。

**[7.5]（写）** 证 `example {α : Type} (P : α → Prop) (a : α) : P a → ∃ x, P x`。

**[7.6]（判）** 下面两个说法，哪个对？
(a)「要证 `P ∨ Q`，必须两边都证。」
(b)「要用 `h : P ∨ Q`，必须两种情况都处理。」

**[7.7]（判）** 下面两个类型是不是同一个？说明理由。

```text
∀ (a : Nat), a > 0 → a > 0
(∀ (a : Nat), a > 0) → a > 0
```

**[7.8]（写）** 用 `nomatch` 证
`example : ¬ (Cat.siamese = Cat.tabby)`（注意和 §7.10 里的方向相反）。

---

**先自己做，再往下看。**

---
@@@ -/

namespace Answers_7

/- @@@
**[7.1]** `theorem t {P Q : Prop} : P ∧ Q → Q ∨ P := fun h => Or.inl h.right`

| 步 | 代码 | 规则 | 这一步之后目标 |
|---|---|---|---|
| 1 | `fun h => ?` | → introduction（§7.4） | `Q ∨ P`，手里 `h : P ∧ Q` |
| 2 | `Or.inl ?` | ∨ introduction，选左（§7.7） | `Q` |
| 3 | `h.right` | ∧ elimination，取右（§7.6） | 关闭 |
@@@ -/

theorem t {P Q : Prop} : P ∧ Q → Q ∨ P :=
  fun h => Or.inl h.right

/- @@@
**[7.2]** 思路：目标是 `P → (Q → P)`，两层 `→`，所以两次 `fun`（§7.4）。
第二个前提用不上，所以用 `_`。
@@@ -/

example {P Q : Prop} : P → (Q → P) := fun p => fun _ => p

/- @@@
**[7.3]** 思路：先 `→ intro` 拿到 `h : P ∧ (Q ∨ R)`。
目标是 `∨`，但该选哪边**取决于** `h` 的右半边是哪一边，
所以不能先选——**先消去那个 `∨`**，再在每支里 `∨ intro`。

这是一条通用经验：**目标是 `∨` 但该选哪边取决于输入时，先消去假设。**
@@@ -/

example {P Q R : Prop} : P ∧ (Q ∨ R) → (P ∧ Q) ∨ (P ∧ R) :=
  fun ⟨p, qor⟩ =>
    match qor with
    | Or.inl q => Or.inl ⟨p, q⟩
    | Or.inr r => Or.inr ⟨p, r⟩

/- @@@
**[7.4]** 思路：`∃` 的引入就是举见证（§7.8）。
`7 * 7` 归约到 `49`，所以 `rfl` 够了（§7.3）。
@@@ -/

example : ∃ n : Nat, n * n = 49 := ⟨7, rfl⟩

/- @@@
**[7.5]** 思路：见证就是手里的 `a`，证据就是手里的 `P a`（§7.8）。
@@@ -/

example {α : Type} (P : α → Prop) (a : α) : P a → ∃ x, P x :=
  fun pa => ⟨a, pa⟩

/- @@@
**[7.6]** **(b) 对，(a) 错。**

`∨` 的引入和消去是**不对称**的（§7.7）：

- 要**证** `P ∨ Q`，**挑一边**证就够了（`Or.inl` 或 `Or.inr`）。
- 要**用** `h : P ∨ Q`，**两种情况都得处理**，因为你不知道手里是哪一边。

说法 (a) 把 `∨` 和 `∧` 搞混了——两边都要证的是 `∧`。

**[7.7]** **不是**同一个。`→` 比 `∀` 结合得紧（§7.8）：

- `∀ (a : Nat), a > 0 → a > 0` 读成 `∀ (a : Nat), (a > 0 → a > 0)`，
  意思是「对任意 `a`，如果 `a > 0` 那么 `a > 0`」。这是真的，就是恒等函数。
- `(∀ (a : Nat), a > 0) → a > 0` 的前提是「每个 `a` 都 > 0」（假的），
  而且结论里那个 `a` 已经跑到 `∀` 的作用域外面，成了自由变量。

第一个是可证的：
@@@ -/

example : ∀ (a : Nat), a > 0 → a > 0 := fun _ h => h

/- @@@
**[7.8]** 思路：和 §7.10 一字不差，方向反过来也一样——
`Eq.refl` 造不出两个不同构造子之间的等式，所以分支数还是零。
@@@ -/

inductive Cat : Type where
| siamese
| tabby

example : ¬ (Cat.siamese = Cat.tabby)
| m => nomatch m

end Answers_7
end S7

/- @@@
---

# 8. term 模式和 tactic 模式

到目前为止，每个证明都是**直接写出一个 term**。这叫 **term mode（term 模式）**。

Lean 还提供另一种写法：**tactic mode（tactic 模式 / 策略模式）**。
你不直接写 term，而是发一串指令，让 Lean 一步步**替你构造**那个 term。
入口是关键字 `by`。

ClassNotes 的 E 文件**绝大部分是 term 模式**，tactic 只用到 `by decide`。
但 tactic 模式是读 Mathlib 和做大证明的必备，
而且理解它的最好办法就是**知道每个 tactic 对应 term 模式的什么**。
这一节就是那张对照表。
@@@ -/

namespace S8

/- @@@
## 8.1 `by`：进入 tactic 模式

`by` 后面跟 tactic。多个 tactic 用换行或分号 `;` 隔开。

tactic 模式里有一个核心概念：**goal（目标）**。goal 的显示形式是

```text
P Q : Prop
h : P ∧ Q
⊢ Q ∧ P
```

`⊢` 上面是 **local context（局部上下文）**，就是你手里有的东西；
`⊢` 下面是**还要证的东西**。每个 tactic 的作用就是**改变 goal**。

term 模式里对应 goal 的是 `_`（§7.12）：写一个 `_`，
Lean 就把当前的期望类型和上下文报给你。**一个 `_` 就是 Lean 在打印 goal。**

## 8.2 对照表

| tactic | 它做什么 | term 模式的对应物 |
|---|---|---|
| `intro h` | 把 `⊢ P → Q` 变成 `h : P ⊢ Q` | `fun h => ?` |
| `exact e` | 用 `e` 关闭当前 goal | 直接把 `e` 写出来 |
| `apply f` | goal 是 `Q`，`f : P → Q`，goal 变成 `P` | `f ?` |
| `constructor` | 对单构造子类型，goal 拆成各字段 | `⟨?, ?⟩` / `And.intro ? ?` |
| `cases h` | 对 `h` 做分情况，每个构造子一个 goal | `match h with \| ... => ?` |
| `decide` | 跑判定过程，自动造出证明 | 没有对应物，是自动化 |
| `simp` | 用一堆改写规则化简 goal | 没有对应物，是自动化 |

前五个是**机械对应**的：tactic 只是 term 的另一种敲法。
后两个是**自动化**：它们替你找 term，term 模式写不出等价物。

## 8.3 `intro`：对应 `fun h => ?`
@@@ -/

-- term 模式
example {P Q : Prop} (hq : Q) : P → Q := fun _ => hq

-- tactic 模式，同一个证明
example {P Q : Prop} (hq : Q) : P → Q := by
  intro _h              -- goal 从 ⊢ P → Q 变成 _h : P ⊢ Q
  exact hq              -- 用手里的 hq 关闭 goal

/- @@@
`intro` 可以一次引入多个：`intro a b c` 等于三次 `fun`。
`∀` 和 `→` 都用 `intro`，因为它们是一回事（§7.5）。
@@@ -/

example : ∀ (P : Prop), P → P := by
  intro P p
  exact p

/- @@@
## 8.4 `exact`：对应「直接写出那个 term」

`exact e` 要求 `e` 的类型**正好**是当前 goal。写对了就关闭 goal。
@@@ -/

example {P Q : Prop} (h : P ∧ Q) : P := by
  exact h.left          -- term 模式就是 `h.left`

/- @@@
## 8.5 `apply`：对应「写出函数，参数留洞」

`apply f`：如果 goal 是 `Q`，而 `f : P → Q`，那 `apply f` 把 goal 变成 `P`。
也就是「我打算用 `f` 来收尾，现在差 `f` 的参数」。

term 模式里对应的是 `f ?`（或者 `f _`，让那个 `_` 报出剩下的 goal）。
@@@ -/

-- term 模式
example {P Q : Prop} (hpq : P → Q) (hp : P) : Q := hpq hp

-- tactic 模式
example {P Q : Prop} (hpq : P → Q) (hp : P) : Q := by
  apply hpq             -- goal 从 ⊢ Q 变成 ⊢ P
  exact hp

/- @@@
`exact` 和 `apply` 的区别：`exact` 要求**完全对上**，
`apply` 允许**差几个参数**，把那几个参数变成新的 goal。

## 8.6 `constructor`：对应 `⟨?, ?⟩`

`constructor` 找到 goal 类型的构造子并应用它，把每个参数变成一个新 goal。
对 `And`（单构造子）就是 `And.intro ? ?`。
@@@ -/

-- term 模式
example {P Q : Prop} (hp : P) (hq : Q) : P ∧ Q := ⟨hp, hq⟩

-- tactic 模式
example {P Q : Prop} (hp : P) (hq : Q) : P ∧ Q := by
  constructor           -- goal 拆成 ⊢ P 和 ⊢ Q 两个
  · exact hp            -- `·` 聚焦到第一个 goal
  · exact hq            -- 第二个

/- @@@
`·`（中间点）叫 focus dot（聚焦点）：它把后面的 tactic 只用在一个 goal 上。
goal 多于一个时推荐用它，不然顺序会很难读。

对**多构造子**的类型（比如 `Or`），`constructor` 会选第一个构造子，
这通常不是你想要的。证 `Or` 应该明说 `exact Or.inl ?`，或者用 `left` / `right`。

## 8.7 `cases`：对应 `match ... with`

`cases h` 对 `h` 做分情况分析，每个构造子得到一个 goal。
语法是 `cases h with | 构造子 参数 => tactic...`。
@@@ -/

-- term 模式
example {P Q : Prop} (h : P ∨ Q) : Q ∨ P :=
  match h with
  | Or.inl hp => Or.inr hp
  | Or.inr hq => Or.inl hq

-- tactic 模式
example {P Q : Prop} (h : P ∨ Q) : Q ∨ P := by
  cases h with
  | inl hp => exact Or.inr hp
  | inr hq => exact Or.inl hq

/- @@@
注意 tactic 模式里构造子名可以省掉类型前缀（写 `inl` 不写 `Or.inl`）。

对 `And` 用 `cases` 就是把那个对拆开，相当于 `match h with | ⟨p, q⟩ => ...`：
@@@ -/

example {P Q : Prop} (h : P ∧ Q) : Q ∧ P := by
  cases h with
  | intro p q => exact ⟨q, p⟩

/- @@@
## 8.8 `decide`：跑判定过程

`decide` 是**自动化**，不是语法糖。它要求 goal 是一个 **decidable（可判定的）**
命题，然后**真的去算**那个判定过程；算出 `true` 就造出证明，
算出 `false` 就编译失败。细节见 §11.1。
@@@ -/

example : (7 > 0) ∧ (7 ≤ 10) := And.intro (by decide) (by decide)
example : 7 * 6 = 42 := by decide
example : ¬ (1 = 2) := by decide
example : 2 + 2 ≠ 5 := by decide

/- @@@
注意 `by decide` 可以**嵌在 term 模式里**，当成一个 term 用。
上面第一行就是这样：外层是 term 模式的 `And.intro`，
两个参数各用一个 `by decide` 填上。E 文件里全是这种混用。

`decide` 的限制：它只能处理**判定过程会终止**的命题。
具体的算术可以，`Nat` 上的无界 `∀` 不行。

## 8.9 `simp`：用改写规则化简

`simp` 也是自动化。它拿一堆已知的改写规则（库里标了 `@[simp]` 的定理）
反复改写 goal，希望把它化简到 `True` 或者一个明显的形式。
@@@ -/

example : 2 + 2 = 4 := by simp
example (n : Nat) : n + 0 = n := by simp
example (p : Prop) (h : p) : p ∧ True := by simp [h]

/- @@@
`simp [h]` 的方括号表示「额外把 `h` 也当成改写规则用」。

`simp` 和 `decide` 的分工：`decide` 处理**具体的、能算的**命题，
`simp` 处理**带变量的、靠改写的**命题。上面第二行 `n + 0 = n` 对任意 `n` 成立，
`decide` 办不到（无界 `∀`），`simp` 可以（它知道 `Nat.add_zero` 这条规则）。

## 8.10 什么时候用哪种模式

这门课的 ClassNotes 刻意**坚持 term 模式**，理由是：
term 模式下每一步写的就是「哪条规则应用到什么上」，推导结构**明摆在代码里**；
tactic 模式把结构藏进了 Lean 的内部状态。

所以：**学规则的时候用 term 模式，干活的时候用 tactic 模式。**
遇到 tactic 写的证明读不懂时，办法是问「这个 tactic 对应的 term 是什么」，
回到 §8.2 那张表。

## 8.11 本节练习

**[8.1]（写）** 把下面这个 term 模式证明改写成 tactic 模式。

```lean
example {P Q R : Prop} (h : P ∧ Q) (f : Q → R) : R := f h.right
```

**[8.2]（写）** 把下面这个 tactic 模式证明改写成 term 模式。

```lean
example {P Q : Prop} (h : P ∨ Q) : Q ∨ P := by
  cases h with
  | inl hp => exact Or.inr hp
  | inr hq => exact Or.inl hq
```

**[8.3]（判）** `exact` 和 `apply` 有什么区别？什么时候 `apply` 之后会有
多于一个新 goal？

**[8.4]（判）** 为什么 `example : ∀ n : Nat, n + 0 = n := by decide` 不行，
而 `by simp` 行？

---

**先自己做，再往下看。**

---
@@@ -/

namespace Answers_8

/- @@@
**[8.1]** 思路：函数应用变 `apply` + `exact`（§8.5），
或者干脆一步 `exact`（§8.4）。两种都对。
@@@ -/

-- 原来的 term 模式
example {P Q R : Prop} (h : P ∧ Q) (f : Q → R) : R := f h.right

-- tactic 写法一：apply 之后目标变成 Q
example {P Q R : Prop} (h : P ∧ Q) (f : Q → R) : R := by
  apply f
  exact h.right

-- tactic 写法二：一步到底
example {P Q R : Prop} (h : P ∧ Q) (f : Q → R) : R := by
  exact f h.right

/- @@@
**[8.2]** 思路：`cases` 变 `match`，`exact e` 变「直接写 `e`」（§8.7、§8.4）。
注意 tactic 模式里构造子可以省前缀（`inl`），term 模式里要写全（`Or.inl`）。
@@@ -/

example {P Q : Prop} (h : P ∨ Q) : Q ∨ P :=
  match h with
  | Or.inl hp => Or.inr hp
  | Or.inr hq => Or.inl hq

/- @@@
**[8.3]** `exact e` 要求 `e` 的类型**正好**是当前目标，一步关闭。
`apply f` 允许 `f` 的**结论**匹配目标但**还差参数**，
那些参数变成新的目标（§8.5）。

`apply f` 之后有多于一个新目标，就是当 `f` 差**多于一个**参数的时候。
比如目标是 `P ∧ Q`，`apply And.intro` 之后会有两个目标 `P` 和 `Q`——
这也正是 `constructor` 在做的事（§8.6）。
@@@ -/

example {P Q : Prop} (hp : P) (hq : Q) : P ∧ Q := by
  apply And.intro       -- 两个新目标
  · exact hp
  · exact hq

/- @@@
**[8.4]** `decide` 要真的**跑**那个判定过程（§8.8、§11.1）。
`∀ n : Nat, n + 0 = n` 是对**无穷多个** `n` 的断言，
判定过程不会终止，所以没有 `Decidable` 实例，`decide` 办不到。

`simp` 走的是另一条路：它用**改写规则**（这里是 `Nat.add_zero`）
把 `n + 0` 改写成 `n`，然后两边一样，结束。
改写是对**符号**做的，不需要枚举 `n`（§8.9）。
@@@ -/

example : ∀ n : Nat, n + 0 = n := by simp
-- example : ∀ n : Nat, n + 0 = n := by decide    -- 不行：无界 ∀ 不可判定

end Answers_8
end S8

/- @@@
---

# 9. 命令补遗

`#check` 和 `#eval` 在 §2 讲过了。还剩四条命令，都是读 E 文件必需的。
放到这里是因为它们的典型例子要用到前面几节的东西。
@@@ -/

namespace S9

/- @@@
## 9.1 `#print`：问「这个名字的定义到底是什么」

`#check` 给类型，`#print` 给**定义本身**。想知道某个库函数是怎么写的就用它。

最值得亲手跑一次的是这一行——它验证了 §7.9 说的「`¬P` 就是 `P → False`」：
@@@ -/

#print Not

/- @@@
输出是 `@[implicit_reducible] def Not : Prop → Prop := fun a => a → False`
（前面那个方括号是 Lean 给它打的一个属性标签，可以忽略）。
`¬` 不是原始概念，就是一个普通的 `def`，体字面上就是 `fun a => a → False`。

`#print` 对自己写的定义也有用：
@@@ -/

def double (n : Nat) : Nat := n * 2

#print double

/- @@@
## 9.2 `#print axioms`：问「这个证明依赖哪些公理」

`#print axioms f` 报告 `f` 的证明最终依赖哪些**公理**。

为什么要关心这个？因为 Lean 的核心逻辑是构造性的，
而「排中律」这类经典原理是**额外加进来的公理**（§11.2）。
一条定理用没用到它们，`#print axioms` 一问就知道。
@@@ -/

theorem twoPlusTwo : 2 + 2 = 4 := rfl

#print axioms twoPlusTwo          -- 不依赖任何公理
#print axioms Classical.em        -- 依赖 propext、Classical.choice、Quot.sound

/- @@@
第一行输出「does not depend on any axioms」——这个证明是纯构造性的。
第二行列出三条公理，其中 `Classical.choice` 就是经典逻辑的来源（§11.2）。

## 9.3 `#guard`：让编译器当测试跑手

`#guard e` 要求 `e` 是一个能算出 `true` 的布尔表达式（或可判定的命题，§11.1）。
成功时**一声不响**，失败时**报错**。
所以它就是一行写进源码的测试，每次编译都会跑一遍。
@@@ -/

#guard 2 + 3 = 5
#guard (3 - 10 : Nat) = 0
#guard "lean".length = 4
#guard double 21 = 42

/- @@@
`#guard` 和 `#eval` 的分工：`#eval` 把答案**打给你看**，
`#guard` 是你把答案**先写下来、让 Lean 核对**。
写讲解时用 `#eval`，写测试时用 `#guard`。

养成习惯：每写一个函数，后面跟一两条 `#guard`，
一条覆盖普通情况、一条覆盖边界情况。它们只花一行，每次构建都会跑。

## 9.4 `#guard_msgs`：把「预期的输出」钉在源码里

这一条是 E05、E07、E08 都在用的关键技巧，不懂它就读不下去那几份文件。

问题是：课堂笔记里**故意**要展示一段编译不过的代码（「看，这里卡住了」）。
但一个报错的文件会让整个课程库构建失败。

`#guard_msgs in` 解决这个问题。用法是三件东西叠在一起：

1. 一个 docstring（文档串）`/-- ... -/`，里面写**你预期的全部输出文本**；
2. 一行 `#guard_msgs in`；
3. 紧跟着**一条**命令（`def`、`example`、`#eval`，都可以）。

Lean 跑那条命令，收集它产生的所有消息（error、warning、`#eval` 的输出都算），
和 docstring 里的文本逐字比对。**对上了就把消息吃掉**，Lean 什么也不报，
编译通过；**对不上**，`#guard_msgs` 自己报错，并打出「预期」和「实际」的差异。

所以报错不是被藏起来了，而是被**断言**了。如果哪天 Lean 改了措辞，
或者这段代码突然合法了，编译就会在这里失败并告诉你。

`/-- ... -/`（两个减号）是 **docstring**，和 `/- ... -/`（一个减号）的
块注释不同：docstring 必须紧贴在它所描述的那一条命令之前，Lean 会把它记进文档。

下面是一个完整的例子，用的正是 §6.4 那个「隐式参数不许显式传」的报错：
@@@ -/

def idImp {α : Type u} : α → α := fun n => n

/--
error: Function expected at
  idImp Nat
but this term has type
  Type

Note: Expected a function because this term is being applied to the argument
  3
-/
#guard_msgs in
#eval idImp Nat 3

/- @@@
**怎么读这个报错**：`α` 是隐式的，所以 Lean 不会把 `Nat` 当成 `α`，
而是当成「`idImp` 的第一个显式参数」。但 `idImp` 的第一个显式参数类型是 `α`，
于是 Lean 推出 `α := Type`、`idImp Nat : Type`，
然后发现你还想把这个 `Type` 应用到 `3` 上——`Type` 不是函数，报错。

正确写法是 `@idImp Nat 3`（§6.4）。

`#guard_msgs` 也可以钉住**正确的**输出，不止是报错。
注意 docstring 第一行的 `info:`——消息分三级，
`info:`、`warning:`、`error:`，写预期文本时要带上对应的前缀：
@@@ -/

/-- info: 42 -/
#guard_msgs in
#eval double 21

/-- info: 84 -/
#guard_msgs in
#eval double 42

/- @@@
**一个坑**：如果报错文本里含 `?m.3` 这样的 **metavariable（元变量）**编号，
这个编号会随 Lean 版本和代码在文件里的位置变化，钉不住。
遇到这种报错，就把代码注释掉、在正文里把报错抄出来描述，别用 `#guard_msgs`。
§5.2 和 §7.12 那两处注释掉的代码就是这个原因。

## 9.5 本节练习

**[9.1]（写）** 用 `#print` 看看 `Not` 的定义，并用一句话说出
「`¬P` 就是 `P → False`」这件事为什么不是比喻。

**[9.2]（写）** 写一个 `def square (n : Nat) : Nat := n * n`，
然后用 `#guard` 断言 `square 7 = 49`，再用 `#guard_msgs` + `#eval`
钉住 `square 7` 的输出。

**[9.3]（判）** 下面这段为什么能通过编译，尽管它显然有类型错误？
`#guard_msgs` 做了什么？

```lean
/--
error: Type mismatch
  "hi"
has type
  String
but is expected to have type
  Nat
-/
#guard_msgs in
example : Nat := "hi"
```

**[9.4]（判）** `#guard` 和 `#eval` 各适合什么场合？
`#guard` 成功的时候输出什么？

---

**先自己做，再往下看。**

---
@@@ -/

namespace Answers_9

/- @@@
**[9.1]** 思路：`#print` 给的是**定义本身**（§9.1）。
@@@ -/

#print Not

/- @@@
输出的核心是 `def Not : Prop → Prop := fun a => a → False`。
这不是比喻，因为 `Not` 就是一个普通的 `def`，
它的体字面上就是 `fun a => a → False`。
所以 `¬P` 和 `P → False` 是**同一个 term**，
在任何需要其中一个的地方可以直接写另一个（§7.9）。

**[9.2]** 思路：`#guard` 要一个算得出 `true` 的命题（§9.3）；
`#guard_msgs` 的 docstring 要带 `info:` 前缀（§9.4）。
@@@ -/

def square (n : Nat) : Nat := n * n

#guard square 7 = 49

/-- info: 49 -/
#guard_msgs in
#eval square 7

/- @@@
**[9.3]** `example : Nat := "hi"` 确实是类型错误。
但 `#guard_msgs in` 把它产生的那条错误消息和上面 docstring 里的文本逐字比对，
对上了就**把消息吃掉**，Lean 什么也不报，编译通过（§9.4）。

报错没有被藏起来，而是被**断言**了：
如果哪天 Lean 改了措辞，或者这段代码突然合法了，这里就会失败。
@@@ -/

/--
error: Type mismatch
  "hi"
has type
  String
but is expected to have type
  Nat
-/
#guard_msgs in
example : Nat := "hi"

/- @@@
**[9.4]** `#eval` 把答案**打给你看**，适合探索和讲解；
`#guard` 是你把答案**先写下来让 Lean 核对**，适合写测试（§9.3）。

`#guard` 成功时**什么都不输出**。它只在失败时说话——
这正是它适合当测试的原因：构建日志里没有它的声音，就说明全过了。
@@@ -/

end Answers_9
end S9

/- @@@
---

# 10. 自定义记法

**这一节可以先跳过，读 E02 之前再回来看。** 前面九节没有一处依赖它。

E02 自己定义了一门小语言的记法。这一节讲三件事：怎么声明、
优先级和结合性是什么意思、以及怎么**验证**自己声明对了。

先把两个词分清楚。像 `PropLogicSyntax.And (PropLogicSyntax.Not X) Y` 这样
直接写构造子应用，叫 **abstract syntax（抽象语法）**。
逻辑学家写的 `¬X ∧ Y` 叫 **concrete syntax（具体语法）**。
**语言本身一个字没变**，记法只是给语言加了一层表面形式，
解析器会把它翻译回那些构造子应用。
@@@ -/

namespace S10

/- @@@
## 10.1 四个声明关键字

一条记法声明要定下三件事：

1. **token（记号）**，以及操作数坐在哪里；
2. **precedence（优先级）**，一个数字，表示它抓操作数抓得多紧——
   数字越大抓得越先，所以 `∧` 在 35 就胜过 `∨` 在 30；
3. **associativity（结合性）**，表示它和自己怎么组合。

四个关键字：

| 关键字 | 形状 | 结合性 |
|---|---|---|
| `notation:n ...` | 任意形状，自己摆 token 和操作数的位置 | 自己指定 |
| `prefix:n "t" => f` | `t a` | 前缀，无结合性问题 |
| `infixl:n " t " => f` | `a t b` | **左**结合 |
| `infixr:n " t " => f` | `a t b` | **右**结合 |
| `infix:n " t " => f` | `a t b` | **不结合**——`a t b t c` 是**解析错误** |

`:n` 是优先级。`=>` 右边是这个记法要展开成的那个函数或构造子。
中缀记法的 token 两边要留空格（`" ∧ "`），不然解析器分不清词。

下面给一个自定义的布尔类型配三个记法。注意都写在 `namespace` 里加 `scoped`，
这样不会污染文件其余部分（§10.4）：
@@@ -/

namespace MyBoolDemo

inductive MyBool where
| true
| false
deriving Repr

def myAnd : MyBool → MyBool → MyBool
| MyBool.true, MyBool.true => MyBool.true
| _, _ => MyBool.false

def myOr : MyBool → MyBool → MyBool
| MyBool.false, MyBool.false => MyBool.false
| _, _ => MyBool.true

def myNot : MyBool → MyBool
| MyBool.true => MyBool.false
| MyBool.false => MyBool.true

-- 两个中缀、一个前缀，各带一个优先级，各展开成刚定义的函数
scoped infixl:35 " &&& " => myAnd
scoped infixl:30 " ||| " => myOr
scoped notation:max "!!" b:40 => myNot b

def b1 : MyBool := MyBool.true
def b2 : MyBool := MyBool.false

#eval b1 &&& b2           -- 用记法
#eval myAnd b1 b2         -- 不用记法，同一个东西
#eval b1 ||| b2
#eval !!b1

end MyBoolDemo

/- @@@
（token 写成 `&&&`、`|||`、`!!` 而不是 `&&`、`||`、`!`，
是为了不覆盖 Lean 自带的那三个。E00 里能直接用 `&&` 是因为它整段都包在
一个 namespace 里。这是 §10.4 的话题。）

**逐 token 拆 `scoped notation:max "!!" b:40 => myNot b`**：

| 部分 | 意思 |
|---|---|
| `scoped` | 只在这个 namespace 被 open 时生效（§10.4） |
| `notation` | 用通用形式，而不是 `prefix` |
| `:max` | **这条记法整体**的优先级是 `max`（最高） |
| `"!!"` | 字面 token |
| `b:40` | 一个操作数，名字叫 `b`，它**要求**在优先级 40 上解析 |
| `=> myNot b` | 展开成 `myNot b` |

两个数字为什么不一样？这正是让前缀运算符**比每个二元连接词结合得紧、
同时又不会吞掉一个二元连接词**的办法。
所以 `!!X &&& Y` 是 `(!!X) &&& Y`，永远不是 `!!(X &&& Y)`。

## 10.2 优先级和结合性：E02 的那张表

E02 给自己的语言选的优先级，**刻意和 Lean 自己给 `Prop` 上那些连接词
用的优先级一致**，这样「读我们的语言」和「读 Lean 自己的逻辑」是同一项技能。

| 记法 | 声明 | 优先级 | 结合性 |
|---|---|---|---|
| `⊤`、`⊥` | `notation:max` | max | 无（原子） |
| `¬p` | `notation:max ... p:40` | max，参数在 40 | 无（前缀） |
| `p ∧ q` | `infixr:35` | 35 | 右 |
| `p ∨ q` | `infixr:30` | 30 | 右 |
| `p ⇒ q` | `infixr:25` | 25 | 右 |
| `p ⇔ q` | `infix:20` | 20 | **无** |

所以 `¬X ∧ Y ∨ Z` 读成 `((¬X) ∧ Y) ∨ Z`。

最后一行是个设计决定，值得单独记：`⇔` 用的是 `infix` 而不是 `infixr`，
所以 `X ⇔ Y ⇔ Z` 是**解析错误**，不是某个被悄悄选中的分组。
这是一个 feature——双条件在通常的数学用法里不结合，
所以让解析器**要求**你加括号。

为什么写 `⇒` 和 `⇔` 而不直接用 `→` 和 `↔`？
`→` 是 Lean 自己的函数类型箭头，内建在 term 语法里，重载它会真的产生歧义。
而 `∧`、`∨`、`¬` 可以安全重载——Lean 已经在 `Prop` 上用了这几个，
但因为我们的操作数类型不是 `Prop`，elaboration 能从类型上选出正确的读法。

## 10.3 怎么验证自己声明对了

这是全节最漂亮的一招：
**「解析器到底建了哪个 term」这件事是一个可以证明的命题**，
所以可以用 `rfl` 来核对（§7.3）。

每条定理都说「某个带记法的表达式**字面上就是**我想要的那个构造子应用」，
`rfl` 就够了。如果优先级错了，证明就过不去。
@@@ -/

namespace Syn

inductive E where
| T
| F
| And (left right : E) : E
| Or (left right : E) : E
| Not (p : E)
deriving Repr

-- 要写全名 E.Or / E.Not：裸写 `Or`、`Not` 会和 Lean 在 Prop 上的那个冲突（§6.7）
def Imp (p q : E) : E := E.Or (E.Not p) q
def Iff (p q : E) : E := E.And (Imp p q) (Imp q p)

scoped notation:max "⊤" => E.T
scoped notation:max "⊥" => E.F
scoped notation:max "¬" p:40 => E.Not p
scoped infixr:35 " ∧ " => E.And
scoped infixr:30 " ∨ " => E.Or
scoped infixr:25 " ⇒ " => Imp
scoped infix:20 " ⇔ " => Iff

end Syn

-- 用 section 把 open 的影响圈起来，免得泄露到本节后面（§6.6、§6.7）
section
open Syn

def X : E := E.T          -- 拿三个具体表达式当「变量」用
def Y : E := E.F
def Z : E := E.T

-- ¬ 比 ∧ 紧
example : (¬X ∧ Y) = E.And (E.Not X) Y := rfl

-- ∧ 比 ∨ 紧
example : (X ∧ Y ∨ Z) = E.Or (E.And X Y) Z := rfl
example : (X ∨ Y ∧ Z) = E.Or X (E.And Y Z) := rfl

-- ∧ 和 ∨ 都右结合
example : (X ∧ Y ∧ Z) = E.And X (E.And Y Z) := rfl
example : (X ∨ Y ∨ Z) = E.Or X (E.Or Y Z) := rfl

-- ∨ 比 ⇒ 紧，而且 ⇒ 右结合
example : (X ∨ Y ⇒ Z) = Syn.Imp (E.Or X Y) Z := rfl
example : (X ⇒ Y ⇒ Z) = Syn.Imp X (Syn.Imp Y Z) := rfl

-- ⇒ 比 ⇔ 紧
example : (X ⇒ Y ⇔ Z) = Syn.Iff (Syn.Imp X Y) Z := rfl
example : (X ⇔ Y ⇒ Z) = Syn.Iff X (Syn.Imp Y Z) := rfl

-- 取消注释可以看到 ⇔ 的不结合性报成解析错误：
-- #check X ⇔ Y ⇔ Z

#check ¬X ∧ Y
#check X ∧ Y ∨ Z

end

/- @@@
注意 `Imp` 和 `Iff` 这两个**不是新的构造子**，而是普通函数，
叫 **derived connective（派生连接词）**：
`p ⇒ q` 是 `¬p ∨ q` 的缩写，`p ⇔ q` 是 `(p ⇒ q) ∧ (q ⇒ p)` 的缩写。
因为类型没变，所以像 §5.3 的 `eval` 那样的函数**不需要加新分支**，仍然是穷尽的。

记法是双向的：Lean 既用它**解析**，也用它**打印**结果。
所以上面最后两个 `#check` 会把具体语法原样回显给你。

## 10.4 `scoped`：别让记法漏出去

`scoped` 的意思是：这条记法**只在它所属的 namespace 被 `open` 时生效**，
不会泄露到仅仅 import 了这个文件的别的文件里。

不加 `scoped` 的记法是全局的。另一种隔离手段是把整段连记法带定义
都包进一个 `namespace ... end`（§6.6），E00 用的就是这招。

重载已有记法要小心。重载 `∧`、`∨`、`¬` 是安全的，因为操作数类型不同，
elaboration 能区分。但有一个坑值得知道：
**如果给同一个构造子声明了两条记法，Lean 打印时会挑一条**，
挑的那条不一定是你写代码时用的那条，读 `#check` 的输出会很困惑。
所以一个构造子配一条记法就好。

## 10.5 本节练习

**[10.1]（读）** 说出 `scoped infixr:30 " ∨ " => E.Or` 每一部分的作用，
以及如果把 `infixr` 改成 `infixl`，`X ∨ Y ∨ Z` 会解析成什么。

**[10.2]（写）** 给 §10.3 的 `E` 加一个 exclusive or（异或）的派生连接词
`Xor (p q : E) : E`（用已有的三个原始构造子定义），选一个 token 和优先级
（它该比 `∨` 紧还是松？），决定结合性，然后写出确认你的选择的 `rfl` 定理。

**[10.3]（判）** 为什么 E02 用 `⇒` 而不是直接重载 `→`？

**[10.4]（判）** `notation:max "¬" p:40 => E.Not p` 里有两个数字。
如果把 `p:40` 改成 `p:max`，`¬X ∧ Y` 会怎么解析？

---

**先自己做，再往下看。**

---
@@@ -/

namespace Answers_10

/- @@@
**[10.1]** `scoped infixr:30 " ∨ " => E.Or`

| 部分 | 作用 |
|---|---|
| `scoped` | 只在这个 namespace 被 `open` 时生效（§10.4） |
| `infixr` | 中缀、**右**结合 |
| `:30` | 优先级 30 |
| `" ∨ "` | token，两边留空格 |
| `=> E.Or` | 展开成构造子 `E.Or` |

改成 `infixl` 之后，`X ∨ Y ∨ Z` 会解析成 `E.Or (E.Or X Y) Z`（左嵌套），
而 `infixr` 解析成 `E.Or X (E.Or Y Z)`（右嵌套）。
`∨` 在逻辑上满足结合律，所以两种分组「等价」，
但它们是**不同的 term**，`rfl` 能把差别测出来（§10.3）。

**[10.2]** 思路：`Xor` 是**派生连接词**，用已有的三个原始构造子定义，
不是新构造子（§10.3）。

优先级怎么选：异或语义上是一种「或」，放在 `∨` 附近合理。
这里选 **32**——比 `∧`（35）松、比 `∨`（30）紧，
这样 `X ∧ Y ⊻ Z` 读成 `(X ∧ Y) ⊻ Z`，而 `X ⊻ Y ∨ Z` 读成 `(X ⊻ Y) ∨ Z`。
异或满足结合律，所以 `infixr` 或 `infixl` 都可以，这里选 `infixr`
和 `∧`、`∨` 保持一致。
@@@ -/

namespace Syn2

inductive E where
| T
| F
| And (left right : E) : E
| Or (left right : E) : E
| Not (p : E)
deriving Repr

-- p ⊻ q 定义为 (p ∧ ¬q) ∨ (¬p ∧ q)
def Xor (p q : E) : E :=
  E.Or (E.And p (E.Not q)) (E.And (E.Not p) q)

scoped notation:max "¬" p:40 => E.Not p
scoped infixr:35 " ∧ " => E.And
scoped infixr:30 " ∨ " => E.Or
scoped infixr:32 " ⊻ " => Xor

end Syn2

open Syn2

def X : E := E.T
def Y : E := E.F
def Z : E := E.T

-- ⊻ 展开成什么
example : (X ⊻ Y) = E.Or (E.And X (E.Not Y)) (E.And (E.Not X) Y) := rfl

-- ∧ 比 ⊻ 紧
example : (X ∧ Y ⊻ Z) = Syn2.Xor (E.And X Y) Z := rfl

-- ⊻ 比 ∨ 紧
example : (X ⊻ Y ∨ Z) = E.Or (Syn2.Xor X Y) Z := rfl

-- ⊻ 右结合
example : (X ⊻ Y ⊻ Z) = Syn2.Xor X (Syn2.Xor Y Z) := rfl

-- ¬ 还是比 ⊻ 紧
example : (¬X ⊻ Y) = Syn2.Xor (E.Not X) Y := rfl

/- @@@
**[10.3]** 因为 `→` 是 Lean **自己的函数类型箭头**，内建在 term 语法里，
重载它会产生真正的歧义（§10.2）。

而 `∧`、`∨`、`¬` 可以安全重载：Lean 已经在 `Prop` 上用了这几个，
但我们的操作数类型是 `E` 而不是 `Prop`，
所以 elaboration 能从**类型**上选出正确的读法。

**[10.4]** 如果把 `p:40` 改成 `p:max`，`¬` 的参数就要求在最高优先级上解析，
那它只能吃下一个**原子**，绝不会吃下任何二元连接词表达式。

对 `¬X ∧ Y` 这个具体例子，解析结果**不变**，还是 `(¬X) ∧ Y`——
因为 `X` 本来就是原子。

真正的差别在于：`p:40` 让 `¬` 能吃下优先级 ≥ 40 的表达式，
`p:max` 只让它吃优先级为 max 的。选 40 是为了让 `¬` 比每个二元连接词
（最高的 `∧` 在 35）结合得紧，同时**不**把别的东西吞进来。
这是一个「留出余地」的选择，不是为了改变现有例子的解析结果。
@@@ -/

end Answers_10
end S10

/- @@@
---

# 11. `Decidable` 与 `Classical`

最后三件事，都是读 E05 和 E07 的前提。
@@@ -/

namespace S11

/- @@@
## 11.1 `Bool` 和 `Prop` 的分界，以及 `Decidable`

§4.1 提过这个区分，这里说透。一句话：

- **`Bool` 是数据**。它是一个你能**跑**的测试的结果，两个值。
- **`Prop` 是命题**。它的值是**证明**。它不是两值的——
  有的命题没有证明（为假），有的有很多证明。

同一个「是不是零」，两种写法：
@@@ -/

def IsZero (n : Nat) : Prop := n = 0       -- 谓词：返回一个命题
def isZeroBool (n : Nat) : Bool := n == 0  -- 判定过程：返回数据

#check @IsZero            -- Nat → Prop
#check @isZeroBool        -- Nat → Bool

#eval isZeroBool 1        -- false：一个算出来的值
#check IsZero 1           -- Prop：一个断言，不会「算出」什么

example : IsZero 0 := rfl
example : ¬IsZero 1 := fun h => nomatch h

/- @@@
`isZeroBool 1` 求值成 `false`；`IsZero 1` **不求值成任何东西**，
它是一个我们可以反驳的断言。
**命题是我们推理的对象，布尔值是我们计算的对象。**

### `Decidable`：把两边连起来

`Decidable P` 是一个类型，它的值是「判定 `P` 的算法」——
这个算法要么给出 `P` 的证明，要么给出 `¬P` 的证明。
@@@ -/

#check @Decidable         -- Prop → Type
#check @decide            -- (p : Prop) → [Decidable p] → Bool

/- @@@
注意 `Decidable` 的返回类型是 `Type` 而不是 `Prop`——
因为它的值是**算法**（数据），不是证明。

`decide p` 是「跑那个算法，返回布尔答案」。
方括号 `[Decidable p]` 是 **instance implicit（实例隐式参数）**：
Lean 会自己去实例库里找合适的，找不到就报错。
这是第四种括号，和 §6.4 的 `( )`、`{ }`、`_` 并列。
@@@ -/

#eval decide (7 * 6 = 42)     -- true
#eval decide (2 + 2 = 5)      -- false
#eval decide (¬ (1 = 2))      -- true
#eval decide ((2 < 3 ∧ 3 < 4) ∨ ¬(1 = 1))

/- @@@
而 tactic `decide`（§8.8）就是：跑这个算法，如果得到 `true`，
就从那个事实构造出 `P` 的证明。得到 `false` 就编译失败。

连接词会**传递**可判定性：如果 `P` 和 `Q` 各自可判定，
那 `P ∧ Q`、`P ∨ Q`、`¬P`、`P → Q`、`P ↔ Q` 都可判定。
所以 `decide` 能处理相当复杂的具体命题。有界的量词也可以：
@@@ -/

example : ∀ x ∈ ([1, 2, 3] : List Nat), x < 10 := by decide
example : ∃ x ∈ ([1, 2, 3] : List Nat), x > 2  := by decide

/- @@@
但 `Nat` 上的**无界** `∀` 不可判定——判定过程不会终止（§8.9）。

`deriving DecidableEq`（§4.4）就是给自定义类型提供 `Decidable (a = b)` 的实例，
这样 `=` 才能在 `#guard` 和 `decide` 里用。

最后一个提醒，和 §6.1 的 `abbrev` 对上了：`decide` 需要**看穿**名字
去找 `Decidable` 实例。所以命题起短名字要用 `abbrev`，用 `def` 会挡住它：
@@@ -/

abbrev sGtZ  : Prop := 7 > 0
def    sGtZ' : Prop := 7 > 0

example : sGtZ := by decide              -- 能：abbrev 透明
-- example : sGtZ' := by decide          -- 不能：failed to synthesize Decidable sGtZ'
example : sGtZ' := show 7 > 0 by decide  -- 要手动把它展开

/- @@@
## 11.2 `Classical.em`：排中律

**构造性逻辑（constructive logic）要求证据。** 它**不**免费提供
「对任意命题 `P`，`P ∨ ¬P`」——因为要给出一个 `∨` 的证明，
你得挑一边并证明那一边（§7.7），而对一个任意的 `P` 你挑不出来。

**经典逻辑（classical logic）** 多加一条：**excluded middle（排中律）**，
`∀ P : Prop, P ∨ ¬P`。Lean 库里就有，叫 `Classical.em`：
@@@ -/

open Classical

#check (em : ∀ (P : Prop), P ∨ ¬P)

/- @@@
把 `em` 想成一台**机器**：给它任何命题 `P`，`em P` 就白送你一个
`P ∨ ¬P` 的证明，你**不需要提供关于 `P` 的任何证据**。

有了它，§7.12 那个卡住的 `¬¬P → P` 就能证了：
@@@ -/

example (P : Prop) : ¬¬P → P :=
  fun notNotP =>
    match em P with
    | Or.inl p => p
    | Or.inr notP => False.elim (notNotP notP)

/- @@@
**三层拆法**：

1. **整体**：从「`P` 不可能为假」推出「`P`」。
2. **逐 token**：`fun notNotP =>` 是 `→ intro`，目标变成 `P`；
   `match em P with` 是对那个 `∨` 做消去（§7.7）；
   `Or.inl p` 那支里 `p : P` 正是要的东西；
   `Or.inr notP` 那支里 `notP : ¬P`，而手里的 `notNotP : ¬¬P` 就是 `¬P → False`，
   所以 `notNotP notP : False`，再 `False.elim` 推出 `P`（§7.9）。
3. **逻辑对应**：`→ intro` → `∀ elim`（`em P`）→ `Or elim` →
   左支直接用假设；右支 `→ elim` 得 `False`，再 `False elim`。
4. **迁移**：把 `P` 换成 `∃ x, R x`，一个字不改，
   就得到「非构造性地证明存在」——E07 用的就是这一招。

对比 §7.12：那里卡住的地方是「缺一个 `¬P` 的证明」，
而 `Or.inr notP` 这一支里的 `notP` 正是那个缺的东西。
**`em` 补上的就是这一个洞。**

两点提醒：

- `open Classical` 本身**不会**让任何证明变成经典的，它只是让
  `Classical.em` 这个名字能写成 `em`。真正用上非构造性力量的是你
  **应用** `em` 的那一刻。不 `open` 直接写 `Classical.em P` 也一样。
- 虽然我们习惯把排中律叫「经典逻辑的公理」，Lean 的 `Classical.em` 其实是
  一条**用底层公理推出来的定理**，其中包括 classical choice（经典选择公理）。
  §9.2 的 `#print axioms Classical.em` 能看到这一点。

## 11.3 「证否」和「归谬」的区别，以及 `Classical.byContradiction`

这是最容易混的一对，值得单独说。

**proof by negation（证否）** ——**构造性的，随时可用**：
要证 `¬P`，假设 `P`，推出 `False`。这**就是** `P → False` 的证明（§7.9）。
§7.9 的 `noContradiction` 用的就是这个策略。

**proof by contradiction（归谬法）** ——**需要经典逻辑**：
要证 `P`，假设 `¬P`，推出 `False`。你构造出来的是 `(¬P → False)`，也就是 `¬¬P`。
构造性逻辑**不允许**你把它变成 `P` 的证明。
这一步叫 **double-negation elimination（双重否定消去）**。

两者的关键步骤都是「推出矛盾」，区别在于**你在证什么**：
证 `¬P` 用证否，证 `P` 用归谬。

Lean 库把归谬法打包成了 `Classical.byContradiction`：
@@@ -/

#check @Classical.byContradiction      -- ∀ {p : Prop}, (¬p → False) → p

example (Q : Prop) (h : ¬Q → False) : Q := Classical.byContradiction h

example (P : Prop) : ¬¬P → P :=
  fun notNotP => Classical.byContradiction (fun notP => notNotP notP)

/- @@@
它的类型读出来就是「如果假设 `¬p` 能推出 `False`，那么 `p`」。
它和 `em` 是**等价**的：§11.2 刚刚从 `em` 推出了 `¬¬P → P`，
而 `byContradiction` 就是那条定理的库版本。

## 11.4 `noncomputable`：经典逻辑的代价

经典逻辑白送你命题，但不送你**代码**。这件事在语法上的表现是一个修饰符。

`open Classical` 会把 `Classical.propDecidable` 带进作用域，
它让**每个**命题都算 `Decidable`（§11.1）。
于是下面这个 `if` 能通过**类型检查**——
Lean 接受它是一个「根据 `P` 真假来分支」的良构程序。
然后代码生成阶段失败了，报错指名了缺的是什么：
@@@ -/

/--
error: failed to compile definition, consider marking it as 'noncomputable' because it depends on 'propDecidable', which is 'noncomputable'
-/
#guard_msgs in
def answerFor (P : Prop) : String := if P then "yes" else "no"

/- @@@
（这个报错用 §9.4 的 `#guard_msgs` 钉住了，所以文件照样编译。）

**`noncomputable` 这个修饰符的意思是：诚实地声明「这个定义不会产生代码」。**
加上它，定义就被接受了，但 `#eval` 还是跑不了：
@@@ -/

noncomputable def answerFor' (P : Prop) : String := if P then "yes" else "no"

/--
error: failed to compile definition, consider marking it as 'noncomputable' because it depends on 'answerFor'', which is 'noncomputable'
-/
#guard_msgs in
#eval answerFor' (2 + 2 = 4)

/- @@@
为什么 `propDecidable` 没有代码？因为它背后是 `em`，
而 `em` 读作「对**每个** `P` 都能回答」的机器——这样的机器**不可能**有可执行代码。
所以 `em` 背后没有代码不是 Lean 实现上的欠缺，而是一条关于计算的定理。

E07 用「奇完全数存不存在」这个两千年未解的问题把这件事演示得很具体：
一行 `em` 就证明了「这个问题有答案」，但你拿不到那个答案，
也没有任何东西可以运行。那一段留给 E07 的文档讲。

## 11.5 本节练习

**[11.1]（判）** `IsZero 1` 和 `isZeroBool 1` 有什么本质区别？
哪一个能 `#eval`？哪一个能当 `example` 的类型？

**[11.2]（写）** 用 `#eval decide` 判断 `(3 < 4) ∧ ¬(4 < 3)`，
再用 `by decide` 把它证成一条 `example`。

**[11.3]（判）** 下面哪个是「证否」、哪个是「归谬」？哪个需要经典逻辑？

(a) 要证 `¬(P ∧ ¬P)`，假设 `P ∧ ¬P`，推出 `False`。
(b) 要证 `P`，假设 `¬P`，推出 `False`。

**[11.4]（写）** 证 `example (P Q : Prop) (h : ¬(P ∨ Q)) : ¬P ∧ ¬Q`。
先用构造性方法写一遍，再说说为什么这里用不上 `byContradiction`。

**[11.5]（判）** `def answerFor (P : Prop) : String := if P then "yes" else "no"`
为什么编译不过？加上 `noncomputable` 之后变了什么、没变什么？

---

**先自己做，再往下看。**

---
@@@ -/

namespace Answers_11

/- @@@
**[11.1]** `IsZero 1` 是一个 **`Prop`**：一个命题，它的值是证明。
它**不求值成任何东西**，它是一个断言（恰好是假的，所以我们可以证它的否定）。
`isZeroBool 1` 是一个 **`Bool`**：一个算出来的数据值，等于 `false`（§11.1）。

- 能 `#eval` 的是 `isZeroBool 1`（`Prop` 里的东西没有可执行内容）。
- 能当 `example` 类型的是 `IsZero 1`（`example` 的类型得是个**类型**；
  `isZeroBool 1` 是个值，不是类型）。
@@@ -/

def IsZero (n : Nat) : Prop := n = 0
def isZeroBool (n : Nat) : Bool := n == 0

#eval isZeroBool 1            -- false
#check IsZero 1               -- Prop
example : ¬IsZero 1 := fun h => nomatch h

/- @@@
**[11.2]** 思路：`decide p` 返回布尔答案，tactic `decide` 构造证明（§8.8、§11.1）。
@@@ -/

#eval decide ((3 < 4) ∧ ¬(4 < 3))
example : (3 < 4) ∧ ¬(4 < 3) := by decide

/- @@@
**[11.3]**

- **(a) 是 proof by negation（证否）**，**构造性的**。
  要证的是 `¬(P ∧ ¬P)`，而 `¬X` 就是 `X → False`，
  所以「假设 `X`、推出 `False`」**正好就是**在写那个函数。
  不需要任何额外假设（§11.3）。
- **(b) 是 proof by contradiction（归谬法）**，**需要经典逻辑**。
  要证的是 `P`，而你构造出来的是 `¬P → False`，也就是 `¬¬P`。
  构造性逻辑不让你把 `¬¬P` 变成 `P`（§11.3）。

两者的关键步骤都是「推出矛盾」，但**要证的东西不同**，所需的逻辑力量也不同。

**[11.4]** 构造性写法就是 §7.9 的 `deMorganNotOr`：
@@@ -/

example (P Q : Prop) (h : ¬(P ∨ Q)) : ¬P ∧ ¬Q :=
  And.intro
    (fun p => h (Or.inl p))
    (fun q => h (Or.inr q))

/- @@@
为什么用不上 `byContradiction`：目标是 `¬P ∧ ¬Q`，拆成两个目标 `¬P` 和 `¬Q`，
而这**两个目标都是否定形式**。证一个 `¬X` 只需要 **proof by negation**：
假设 `X`、推出 `False`，这是构造性的（§11.3）。

具体地：要证 `¬P`，假设 `p : P`，那 `Or.inl p : P ∨ Q`，
把它喂给 `h : ¬(P ∨ Q)` 就得到 `False`。
全程没有「从 `¬¬X` 得到 `X`」这一步，所以不需要经典逻辑。

对照：DeMorgan 的四个方向里，只有 `¬(P ∧ Q) → (¬P ∨ ¬Q)` 需要排中律——
因为那一条的**目标是 `∨`**，要挑一边，
而「知道两者不能同时成立」并不告诉你该反驳哪一个（§7.7、§11.2）。

**[11.5]** 编译不过，是因为它不是在证明一个命题，而是在**定义一个程序**：
`if P then ... else ...` 要在运行时真的分支，就需要一个能判定 `P` 的**算法**。

`open Classical` 带进来的 `Classical.propDecidable` 让这个 `if`
通过了**类型检查**（它提供了 `Decidable` 实例），
但那个实例本身是 `noncomputable` 的——背后没有代码。
所以代码生成阶段失败（§11.4）。

加上 `noncomputable` 之后：

- **变了**：定义被接受了，它存在于环境里，别的**证明**可以引用它。
- **没变**：还是没有代码。`#eval` 依然跑不了，
  而且任何引用它的定义也会跟着变成 `noncomputable`。
@@@ -/

end Answers_11
end S11

/- @@@
---

# 12. 速查表

## 12.1 看到目标是这个形状，就写什么

这张表是前面每一节末尾那句话的汇总。**写证明时从这里查。**

| 目标（`⊢` 后面） | 写什么 | 之后目标变成 | 规则 | 小节 |
|---|---|---|---|---|
| `a = b` | 先试 `rfl` | 关闭（如果两边同范式） | Eq intro | §7.3 |
| `P → Q` | `fun h => ?` | `Q`（手里多了 `h : P`） | → intro | §7.4 |
| `∀ x, P x` | `fun x => ?` | `P x` | ∀ intro | §7.5 |
| `P ∧ Q` | `⟨?, ?⟩` | 两个目标 `P` 和 `Q` | ∧ intro | §7.6 |
| `P ∨ Q` | `Or.inl ?` 或 `Or.inr ?` | `P` 或 `Q`（**自己挑**） | ∨ intro | §7.7 |
| `∃ x, P x` | `⟨w, ?⟩`（自己挑 `w`） | `P w` | ∃ intro | §7.8 |
| `True` | `True.intro` | 关闭 | True intro | §7.9 |
| `¬P` | `fun h => ?` | `False`（手里多了 `h : P`） | → intro | §7.9 |
| `P ↔ Q` | `Iff.intro ? ?` | 两个目标 `P → Q` 和 `Q → P` | ↔ intro | §7.11 |
| 具体的算术命题 | `by decide` | 关闭（算得出来的话） | 自动化 | §11.1 |
| 带变量的等式 | `by simp` | 关闭（化简得掉的话） | 自动化 | §8.9 |
| 任何（先占位） | `sorry` | 关闭，留一条警告 | —— | §7.12 |
| 不知道缺什么 | `_` | **报错**，报错里写着缺什么 | —— | §7.12 |

## 12.2 看到假设是这个形状，就怎么用

| 假设 | 怎么用 | 得到 | 规则 | 小节 |
|---|---|---|---|---|
| `h : a = b` | `h.symm` 翻方向 | `b = a` | —— | §7.3 |
| `h : P → Q` | `h p`（得先有 `p : P`） | `Q` | → elim | §7.4 |
| `h : ∀ x, P x` | `h a` | `P a` | ∀ elim | §7.5 |
| `h : P ∧ Q` | `h.left` / `h.right`（或 `.1` / `.2`） | `P` / `Q` | ∧ elim | §7.6 |
| `h : P ∨ Q` | `match h with \| Or.inl p => ? \| Or.inr q => ?` | 两个分支，各知道自己有哪边 | ∨ elim | §7.7 |
| `h : ∃ x, P x` | `fun ⟨w, pf⟩ => ?` 或 `match h with \| ⟨w, pf⟩ => ?` | `w` 和 `pf : P w`（结论里不能提 `w`） | ∃ elim | §7.8 |
| `h : ¬P` | `h p`（得先有 `p : P`） | `False` | → elim | §7.9 |
| `h : False` | `False.elim h` | 任何东西 | False elim | §7.9 |
| `h : X`（`X` 造不出来） | `nomatch h` | 任何东西 | 零分支匹配 | §5.7、§7.10 |
| `h : P ↔ Q` | `h.mp` / `h.mpr` | `P → Q` / `Q → P` | ↔ elim | §7.11 |
| 想假设 `P ∨ ¬P` | `em P`（需 `open Classical`） | `P ∨ ¬P` | 排中律 | §11.2 |

## 12.3 计算侧和逻辑侧的对照

**左右两列的构造子是共用的**——只是住在不同的宇宙里。
左边学会的语法，右边原样照用。

| 构造方式 | 计算侧（`Type`） | 逻辑侧（`Prop`） |
|---|---|---|
| 原子 | `Nat`、`Bool`、`String` | 原子命题 |
| 函数 | `α → β` | `P → Q`（蕴含） |
| 两个都要 | `α × β`（`Prod`） | `P ∧ Q`（`And`） |
| 要其中一个 | `α ⊕ β`（`Sum`） | `P ∨ Q`（`Or`） |
| 没有值 | `Empty` | `False` |
| 恰好一个值 | `Unit` | `True` |
| 到空类型的函数 | `α → Empty` | `¬P`（即 `P → False`） |

| 这一侧的名字 | 另一侧的名字 | 小节 |
|---|---|---|
| `Prod.mk` / `(a, b)` / `⟨a, b⟩` | `And.intro` / `⟨p, q⟩` | §4.6、§7.6 |
| `Prod.fst` / `.1` | `And.left` / `.left` | §5.5、§7.6 |
| `Prod.snd` / `.2` | `And.right` / `.right` | §5.5、§7.6 |
| `Sum.inl` / `Sum.inr` | `Or.inl` / `Or.inr` | §4.6、§7.7 |
| `nomatch`（对 `Empty`） | `False.elim` | §5.7、§7.9 |

## 12.4 符号索引

按符号查，不按概念查。

| 符号 | 读法 / 作用 | 小节 |
|---|---|---|
| `--`、`/- -/` | 注释 | §1.4 |
| `/-- -/` | docstring，`#guard_msgs` 用它写预期输出 | §9.4 |
| `#check`、`#eval` | 问类型 / 问值 | §2.1、§2.2 |
| `#print`、`#print axioms` | 问定义 / 问依赖哪些公理 | §9.1、§9.2 |
| `#guard`、`#guard_msgs` | 断言值 / 断言输出 | §9.3、§9.4 |
| `:` | 「的类型是」，或读成「是……的一个证明」 | §2.1 |
| `:=` | 「定义为」 | §2.3 |
| `(e : T)` | type ascription（类型标注） | §2.1 |
| `(x : T)` | 显式参数 | §6.4 |
| `{x : T}` | 隐式参数 | §6.4 |
| `[Inst]` | 实例隐式参数 | §11.1 |
| `_` | 让 Lean 推断 / 通配符模式 / 打印 goal | §6.4、§5.3、§7.12 |
| `@f` | 关闭 `f` 的隐式推断 | §6.4 |
| `fun x => e` | 匿名函数 / `→` 和 `∀` 的引入 | §3.1、§7.4 |
| 空格 | 函数应用，结合得最紧 | §3.3 |
| `→` | 函数类型 / 蕴含，**右结合** | §3.2、§7.4 |
| `match ... with` | 模式匹配 | §5.1 |
| `\| 模式 => e` | 一个分支（`def` 里可省掉 `match`） | §5.2 |
| `⟨a, b⟩` | 匿名构造子（造或拆单构造子类型） | §4.3、§5.4 |
| `.1`、`.2`、`.fst`、`.字段名` | 字段投影 | §5.5 |
| `.构造子名` | 点记法，期望类型已知时省掉类型名 | §4.2 |
| `if then else` | 条件表达式，两支同类型 | §5.6 |
| `nomatch e` | 零分支的模式匹配 | §5.7、§7.10 |
| `×`（`Prod`）、`⊕`（`Sum`） | 积类型、和类型，都**右结合** | §4.6 |
| `Type`、`Prop`、`Sort u` | 计算类型的类型、命题的类型、两者的统称 | §4.1、§6.4 |
| `=`（`Eq`）、`rfl` | 等式、自反性证明 | §7.3 |
| `∧`、`∨`、`¬`、`↔` | 合取、析取、否定、双条件 | §7.6、§7.7、§7.9、§7.11 |
| `∀`、`∃` | 全称量词、存在量词 | §7.5、§7.8 |
| `sorry` | 占位，编译通过加警告 | §7.12 |
| `by` | 进入 tactic 模式 | §8.1 |
| `·` | tactic 模式里的聚焦点 | §8.6 |
| `notation`、`infixl`、`infixr`、`infix`、`prefix` | 声明记法 | §10.1 |
| `noncomputable` | 声明「这个定义不产生代码」 | §11.4 |

## 12.5 关键字索引

| 关键字 | 作用 | 小节 |
|---|---|---|
| `def` | 定义数据或函数 | §2.3、§2.4 |
| `abbrev` | 定义一个会自动展开的缩写 | §6.1 |
| `let` | 在表达式内部起名字 | §6.2 |
| `where` | 挂辅助定义（§6.3）/ 引出构造子或字段表（§4.2、§4.3） | §6.3 |
| `namespace` / `end` | 给名字加前缀 | §6.6 |
| `section` / `end` | 限定 `variable` 和 `open` 的范围 | §6.8 |
| `open`、`open ... in` | 省掉前缀 | §6.7 |
| `variable` | 一次声明、多处共用的参数 | §6.8 |
| `inductive` | 造一个新类型，构造子即引入规则 | §4.2 |
| `structure` | 造一个单构造子、字段有名字的类型 | §4.3 |
| `deriving` | 自动生成 `Repr` / `BEq` / `DecidableEq` | §4.4 |
| `theorem` | 定义一个证明 | §7.1 |
| `example` | 定义一个不要名字的东西 | §7.1 |
| `scoped` | 让记法只在 namespace 被 open 时生效 | §10.4 |
@@@ -/

/- @@@
---

# 13. 术语表

| English | 中文 | 一句话解释 |
|---|---|---|
| abbreviation (`abbrev`) | 缩写 | 一个会被类型检查器自动展开的定义（§6.1） |
| anonymous constructor | 匿名构造子 | `⟨a, b⟩`，意思是「把期望类型的唯一构造子应用到这些参数上」（§5.4） |
| associativity | 结合性 | 一个运算符和自己怎么组合：左结合、右结合、或不结合（§10.1） |
| auto-bound implicit | 自动绑定隐式参数 | Lean 替你给类型里来历不明的标识符补上的隐式参数（§6.9） |
| case analysis | 分情况分析 | 按一个值是用哪个构造子造的来分支，就是模式匹配（§5.1） |
| classical logic | 经典逻辑 | 加上排中律（或等价原理）的逻辑（§11.2） |
| concrete syntax | 具体语法 | 记法提供的表面形式，解析器会翻译回抽象语法（§10） |
| constructive logic | 构造性逻辑 | 要求提供证据的逻辑，不免费给 `P ∨ ¬P`（§11.2） |
| constructor | 构造子 | 一个 inductive 类型的引入规则，造出它的值的唯一办法（§4.2） |
| currying | 柯里化 | 多参数函数其实是「接受一参数、返回函数」的函数（§3.2） |
| decidable | 可判定的 | 存在一个总能给出证明或反证的算法（§11.1） |
| definitional equality | 定义等式 | 两边归约到同一范式，所以 `rfl` 可证（§7.3） |
| dependent type | 依值类型 | 一个东西的**类型**由另一个东西的**值**决定（§6.4、§7.8） |
| derived connective | 派生连接词 | 用已有连接词定义出来的连接词，不是新构造子（§10.3） |
| docstring | 文档串 | `/-- ... -/`，紧贴在一条命令前，Lean 记进文档（§9.4） |
| dot notation | 点记法 | 期望类型已知时把类型名省成一个点，如 `.green`（§4.2） |
| elaboration | （保留英文） | Lean 把表面语法补全成完整 term 的过程：填隐式参数、选记法、找实例（§10.2） |
| elimination rule | 消去规则 | **使用**一个类型的值的办法（§7.2） |
| excluded middle | 排中律 | `∀ P, P ∨ ¬P`，经典逻辑的那条额外假设（§11.2） |
| exhaustiveness | 穷尽性 | 模式匹配必须覆盖所有构造子，Lean 会检查（§5.1） |
| existential quantifier | 存在量词 | `∃`，它的证明是「见证 + 关于见证的证据」（§7.8） |
| explicit argument | 显式参数 | 用 `( )` 声明，调用时必须写出来（§6.4） |
| goal | 目标 | tactic 模式里「还要证的东西」，显示在 `⊢` 后面（§8.1） |
| higher-order function | 高阶函数 | 参数本身是函数的函数（§3.4） |
| implicit argument | 隐式参数 | 用 `{ }` 声明，Lean 自动推断（§6.4） |
| inductive type | 归纳类型 | 用 `inductive` 定义、由构造子列表完全确定的类型（§4.2） |
| inhabited | 有值的 | 这个类型至少有一个值；命题为真就是它有值（§1.3） |
| instance implicit | 实例隐式参数 | 用 `[ ]` 声明，Lean 去实例库里找（§11.1） |
| introduction rule | 引入规则 | **造出**一个类型的值的办法（§7.2） |
| literate Lean | 文学化 Lean | 散文在注释块里、代码裸写在块外的写法（§1.4） |
| local context | 局部上下文 | tactic 模式里「手里有的东西」，显示在 `⊢` 上面（§8.1） |
| metavariable | 元变量 | Lean 还没确定下来的那个洞，显示成 `?m.3`（§9.4） |
| namespace | 命名空间 | 给一组名字加统一前缀（§6.6） |
| normal form | 范式 | 一个表达式归约到不能再归约的结果（§2.2） |
| noncomputable | 不可计算的 | 一个诚实声明「不会产生可执行代码」的定义（§11.4） |
| parametric polymorphism | 参数多态 | 把类型本身作为参数，实现不依赖具体类型（§6.4） |
| parametricity | 参数性 | 多态实现必须把类型参数当不透明黑盒的性质（§6.5） |
| partial application | 偏应用 | 只给一部分参数，得到一个函数（§3.2） |
| pattern | 模式 | `=>` 左边那个东西，它既匹配也绑定名字（§5.1） |
| precedence | 优先级 | 一个数字，表示运算符抓操作数抓得多紧（§10.1） |
| predicate | 谓词 | 一个 `α → Prop` 的函数，一族命题（§4.2、§11.1） |
| product type | 积类型 | `α × β`，值的个数是两边之积（§4.5、§4.6） |
| proof by contradiction | 归谬法 | 要证 `P`，假设 `¬P` 推出 `False`。**需要经典逻辑**（§11.3） |
| proof by negation | 证否 | 要证 `¬P`，假设 `P` 推出 `False`。**构造性的**（§11.3） |
| proof irrelevance | 证明无关性 | 同一命题的任两个证明被视为相等（§7.3） |
| projection | 投影 | 从单构造子类型取出一个字段，如 `.1`、`.left`（§5.5） |
| proposition | 命题 | 一个 `Prop` 里的类型，它的值是它的证明（§4.1） |
| reduction | 归约 | 按规则把表达式改写一步（§2.2） |
| scrutinee | 被匹配者 | `match` 后面那个被分情况分析的 term（§5.1） |
| sum type | 和类型 | `α ⊕ β`，值的个数是两边之和（§4.5、§4.6） |
| tactic | 策略 | `by` 之后的指令，让 Lean 替你构造 term（§8） |
| term | 项 | Lean 里的一个表达式，它有一个类型（§1.3） |
| type ascription | 类型标注 | `(e : T)`，声明 `e` 的类型并让 Lean 检查（§2.1） |
| universal quantifier | 全称量词 | `∀`，它的证明是一个函数（§7.5） |
| universe | 宇宙 | 类型的层级：`Prop`、`Type`、`Type 1` ……（§6.4） |
| wildcard | 通配符 | `_` 作为模式时匹配任何东西且不起名字（§5.3） |
| witness | 见证 | 存在命题的证明里那个具体的值（§7.8） |
@@@ -/

/- @@@
---

# 结语

用法建议：

1. 读 E 文件时遇到不认识的写法，按 §12.4 的符号索引查到小节号。
2. 写证明卡住时，看 §12.1（目标是什么形状）和 §12.2（假设是什么形状）。
3. 术语对不上时查 §13。

这份文档只管语法。证明的内容、每条定理为什么这么证、
那些开放问题和哲学讨论，都在 E 系列的详解文档里。
那些文档出现的语法都会回指到这份 L00。
@@@ -/
