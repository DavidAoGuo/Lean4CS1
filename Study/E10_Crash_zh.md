# E10 速成：从零到老师的作业（3 小时版）

- **写作日期**：2026-10-21，基于 upstream `ec7a8f5` 的 `FPCourse/ClassNotes/E10_Arith.lean`。
- **读者**：没学过 Lean、没学过函数式语言、只有大约 3 小时的人。
- **目标**：读完能看懂 E10 全文，能解释老师布置的每一道题要做什么、为什么这么做，
  并且有能力自己把代码补出来。
- **编译**：本文件不 `import` 任何东西。容器内 `lean Study/E10_Crash_zh.lean` 几秒验证。
- **预览**：`python3 scripts/convert.py Study/E10_Crash_zh.lean Study/E10_Crash_zh.md`

## 0. 怎么用这 3 小时

两个窗口并排。左边开 `Study/E10_Crash_zh.md` 的 Markdown 预览（`Ctrl+Shift+V`）当书读；
右边开这个 `.lean` 文件，**把光标放到任何一行 `#eval` 或 `#check` 上**，
右侧的 Lean Infoview 面板会显示结果（装了 Lean 4 扩展后 VS Code 右侧自动出现的那个面板）。
看输出比读文字快得多。

两个会让你以为自己错了的显示现象，先打预防针：
Infoview 里的名字会带 `Part1.` 或 `KNat.` 这样的前缀，那是 namespace 加的（§1.6）；
`#check f` 和 `#check (f)` 显示格式不一样，§1.3 讲。

**时间不够怎么办**：前四部分读了两小时还没完，就直接跳到第 5 部分。
第 5 部分每道题开头都写了要回看哪一节。写代码和调报错的时间不算在三小时里，
目标是「看懂、能解释、知道该写什么」，真写可以放到之后。

| 部分 | 内容 | 时间 |
|---|---|---|
| 1 | 最少量的 Lean 语法，只讲 E10 用到的 | 40 分钟 |
| 2 | 递归：数是怎么被算出来的 | 35 分钟 |
| 3 | typeclass：让 `+` 认识你自己定义的类型 | 40 分钟 |
| 4 | 把一门小语言嵌进 Lean | 25 分钟 |
| 5 | 作业逐题拆解 | 40 分钟 |

读的时候只需要记住一句话：**Lean 里每个东西都是一个 term（项），每个 term 有一个
type（类型）。写 `e : T` 读作「`e` 的类型是 `T`」。** 整份文档都在用这一句话。

老师的要求是作业自己做。所以第 5 部分**不给答案**，只把每道题拆到「你知道该写什么」为止，
留一两个空让你填。填不出来就回到对应的小节再看一遍，或者把你写的贴给我。
---

# 1. 最少量的 Lean 语法

只讲 E10 文件里出现的东西，一个不多。

下面这一整部分包在 `namespace Part1` 里（§1.6 解释它是什么），所以 Infoview 显示的名字
会多一个 `Part1.` 前缀，比如 `Part1.KNat.zero`。这不是错，忽略前缀读就行。
```lean
namespace Part1
```

## 1.1 问类型，问值：`#check` 和 `#eval`

`#check e` 报告 `e` 的类型，`#eval e` 把 `e` 算出来。两个命令都不是程序的一部分，
是你当场问 Lean 的问题。光标放上去看 infoview 的回答。
```lean
#check 42                 -- 42 : Nat        读作「42 的类型是 Nat」
#check "hello"            -- "hello" : String
#check true               -- Bool.true : Bool

#eval 2 + 3               -- 5
#eval 2 + 3 * 4           -- 14：乘法优先级比加法高，先算乘法，和数学一样
```

`Nat` 是自然数：0, 1, 2, ……**没有负数**。这一点在作业里会直接用到：
```lean
#eval 3 - 10              -- 0，不是 -7。减不下去就停在 0，叫「截断」
```

## 1.2 起名字：`def`

`def 名字 : 类型 := 值`。名字一旦绑定永不改变，这门语言里没有「赋值」。
```lean
def answer : Nat := 42

#eval answer
#eval answer * 2
```

加上参数就是函数。参数写在名字和冒号之间，**调用时用空格隔开，不写括号**：
```lean
def double (n : Nat) : Nat := n * 2
def add (a b : Nat) : Nat := a + b     -- (a b : Nat) 一次声明两个同类型参数

#eval double 21           -- 42
#eval add 3 4             -- 7
```

**逐 token 拆 `def add (a b : Nat) : Nat := a + b`**：

| token | 角色 |
|---|---|
| `def` | 关键字 |
| `add` | 新名字 |
| `(a b : Nat)` | 参数表：两个参数，都是 `Nat` |
| `: Nat` | 返回类型 |
| `:=` | 「定义为」 |
| `a + b` | 函数体 |

## 1.3 函数的类型：`→`

一个函数本身也有类型，写法用箭头。`Nat → Nat` 读作「从 `Nat` 到 `Nat` 的函数」。
```lean
#check (double)           -- Nat → Nat
#check (add)              -- Nat → Nat → Nat
```

先说括号。`#check double` 不加括号，显示的是**声明签名** `double (n : Nat) : Nat`，
参数照原样列出来；`#check (double)` 加了括号，才显示它作为一个值的**类型** `Nat → Nat`。
以后想看箭头形式就加括号。

第二行要停一下。`Nat → Nat → Nat` 不是「两个 Nat 进、一个 Nat 出」的意思，
而是 `Nat → (Nat → Nat)`：**给它一个 `Nat`，它还你一个「还差一个 `Nat` 的函数」**。
所以 `add 3 4` 其实是 `(add 3) 4`，先喂 3 得到一个函数，再喂 4。
这叫 currying（柯里化）。E10 里所有两参数函数的类型都长这样，
看到 `KNat → KNat → KNat` 就按这个读。

定义函数还有第二种写法，把参数放到类型里、体里用 `fun` 绑定名字：
```lean
def double' : Nat → Nat := fun n => n * 2   -- fun n => ... 读作「给我一个 n，我还你 ...」

#eval double' 21
```

两种写法定义的是同一个函数。E10 两种都用，所以两种都得认得。

## 1.4 自己造类型：`inductive`

`inductive` 列出一个类型**全部**的造法，每一种造法叫一个 constructor（构造子）。
除了这些构造子，没有别的办法造出这个类型的值。
```lean
inductive Light where
| red
| yellow
| green
deriving Repr             -- 告诉 #eval 怎么打印这个类型。老师的文件没写它，因为新版 Lean 的
                          -- #eval 会自动补上；这里写上只是保险，以后照抄即可

#check Light.red          -- Light.red : Light
#eval Light.yellow
```

读作：一个 `Light` 是 `red`，**或者** `yellow`，**或者** `green`。一共三个值。
构造子的全名带类型前缀：`Light.red`。

**构造子可以带参数，而且参数的类型可以就是正在定义的这个类型。**
这是 E10 的第一个定义，整份文件都建立在它上面：
```lean
inductive KNat where
| zero
| succ (n : KNat)
deriving Repr
```

读作：一个 `KNat` 要么是 `zero`，要么是「某个 `KNat` 的 `succ`（后继）」。
所以这个类型的值长这样：
```lean
#check KNat.zero                          -- Part1.KNat.zero : KNat（前缀见 §1.6）
#check (KNat.succ)                        -- KNat → KNat：它是个函数，给一个 KNat，还你下一个
                                          -- （加括号才显示箭头形式，§1.3）
#check KNat.succ KNat.zero                -- KNat.zero.succ : KNat，这就是「1」
#eval  KNat.succ (KNat.succ KNat.zero)    -- 这就是「2」
```

**`KNat` 就是从零开始用「加一」造出来的自然数**，没有别的构造办法。
`0` 是 `zero`，`1` 是 `succ zero`，`2` 是 `succ (succ zero)`，以此类推。
这个表示法看起来笨，但它让「对数做递归」变得非常直接，第 2 部分你会看到。

给常用的值起名字：
```lean
def kzero := KNat.zero                    -- 类型标注省略了，Lean 推得出来
def kone  := KNat.succ kzero
def ktwo  := KNat.succ kone

#eval ktwo
```

**点记法**。`n.succ` 和 `KNat.succ n` 是同一个东西：当 `n` 的类型是 `KNat` 时，
`n.succ` 会被读成「在 `KNat` 这个命名空间里找 `succ`，把 `n` 当第一个参数」。
E10 的 `inc` 用的就是这个写法。
```lean
#eval ktwo.succ           -- 和 KNat.succ ktwo 一样
```

## 1.5 拆开一个值：模式匹配

造值用构造子，**用值就要问「它是哪个构造子造的」**，然后分情况处理。
这叫 pattern matching（模式匹配）。
```lean
def description : Light → String
| Light.red    => "stop"
| Light.yellow => "slow down"
| Light.green  => "go"

#eval description Light.green
```

**逐 token 拆**：

- `def description : Light → String`：名字和类型。注意参数没有名字，
  只写了函数类型 `Light → String`。
- `| Light.red => "stop"`：一个分支。`|` 开头，`=>` 左边是**模式**（问「是不是用
  `Light.red` 造的」），右边是这一支的结果。
- 三个分支把三个构造子**全部**覆盖。漏一个，Lean 会报错并告诉你漏了哪个。

这种「类型后面直接列分支」的写法 E10 用得最多。
一条写法上的约定：要这样写，参数就**不能**在冒号左边起名字。
`def f (x : Light) : String | ...` 会报错；参数留在类型里，才能用 `|` 匹配它。

参数已经起了名字时，另一种办法是在函数体里写 `match`。下面和 `description` 完全等价：
```lean
def description' (l : Light) : String :=
  match l with
  | Light.red    => "stop"
  | Light.yellow => "slow down"
  | Light.green  => "go"

#eval description' Light.red
```

`match l with` 后面接的分支表和 `|` 写法一模一样。E02 和 E10 两种都有。

构造子带参数时，模式里给那个参数**起名字**，右边就能用：
```lean
def isZero : KNat → Bool
| KNat.zero   => true
| KNat.succ _ => false    -- `_` 表示「这里有个东西，但我不关心它叫什么」

def pred : KNat → KNat
| KNat.zero    => KNat.zero   -- 0 的前一个还是 0（截断）
| KNat.succ n' => n'          -- 「比 n' 大一的数」的前一个就是 n'

#eval isZero kzero
#eval isZero ktwo
#eval pred ktwo           -- 1
```

看 `pred` 的第二支：模式 `KNat.succ n'` 的意思是「如果输入是用 `succ` 造的，
把它里面装的那个 `KNat` 叫做 `n'`」。然后右边直接返回 `n'`。
**模式既检查形状，也把里面的东西拆出来起名字。** 这是整份 E10 的核心动作。

**多个参数一起匹配**：用逗号隔开。
```lean
def bothZero : KNat → KNat → Bool
| KNat.zero, KNat.zero => true
| _, _                 => false     -- 其余任何组合

#eval bothZero kzero kzero
#eval bothZero kzero ktwo
```

## 1.6 名字的前缀：`namespace` 和 `open`

`namespace N` 到 `end N` 之间定义的名字，真名都是 `N.名字`。
E10 把所有东西包在 `namespace KNat` 里，所以 `add` 的真名是 `KNat.add`。
```lean
namespace Zoo
def count : Nat := 3
end Zoo

#eval Zoo.count           -- 出了 namespace 要用全名

open Zoo in
#eval count               -- open 之后可以省前缀；`open ... in` 只管下面这一条命令
```

`open KNat` 写在一行里不带 `in`，就对后面所有命令都生效。E10 的 `Arith` 部分这么用。

第 1 部分结束。到这里你已经认识 E10 用到的全部语法，除了 typeclass（第 3 部分）。
```lean
end Part1
```

---

# 2. 递归：数是怎么被算出来的

从这里开始，定义和老师文件里的相同，只多了 `deriving Repr`、注释和两个辅助函数。
我们像老师一样把一切包在 `namespace KNat` 里。

两件事先说清，免得疑惑：

- 第 1 部分那个 `KNat` 是 `Part1.KNat`，和这里的是**两个互不相干的类型**。从现在起只用这里的。
- 在 `namespace KNat` 里定义 `inductive KNat`，这个类型的真名是 `KNat.KNat`，
  Infoview 里会看到 `KNat.KNat.succ` 这样的名字。老师的文件也是这样，不是错。
```lean
namespace KNat

inductive KNat where
| zero
| succ (n : KNat)
deriving Repr

def kzero  := KNat.zero
def kone   := KNat.succ kzero
def ktwo   := KNat.succ kone
def kthree := KNat.succ ktwo
```

## 2.1 不需要拆参数的函数，和需要拆的

`inc` 是「加一」，直接套一层 `succ` 就行，不需要看输入长什么样，
所以参数可以放在冒号左边起名字：
```lean
def inc (n : KNat) := n.succ        -- n.succ 就是 KNat.succ n（§1.4 的点记法）
```

`dec` 是「减一」，必须看输入是 `zero` 还是 `succ 什么`，所以要模式匹配，
参数就得留在类型里（§1.5 的那条约定；或者给参数起名再用 `match`）：
```lean
def dec : KNat → KNat
| KNat.zero    => kzero      -- 0 减 1 还是 0：截断
| KNat.succ n' => n'         -- 「比 n' 大一」减 1 就是 n'

#eval inc ktwo
#eval dec ktwo
#eval dec kzero             -- 截断
```

E10 原文的注释「Decrement: must destructure (pattern match) argument, so the argument
must be to the right of the colon」说的就是这件事。

## 2.2 一个看输出的小工具

`#eval` 打印 `KNat` 会打出 `KNat.succ (KNat.succ KNat.zero)` 这种一长串，数不清。
写一个把 `KNat` 换算成普通 `Nat` 的函数，以后测试都用它看结果。
这也是你的第一个递归函数：
```lean
def toNat : KNat → Nat
| KNat.zero    => 0                 -- 基值：0 换算成 0
| KNat.succ n' => toNat n' + 1      -- 步进：「比 n' 大一」换算成「n' 的换算结果 加一」

#eval toNat kthree          -- 3
```

**逐 token 拆第二支** `| KNat.succ n' => toNat n' + 1`：

- 模式 `KNat.succ n'`：输入是 `succ` 造的，里面那个叫 `n'`。
- 右边 `toNat n'`：**对更小的那个数递归调用自己**。
- `+ 1`：把结果加一。

**递归能停下来，是因为每次调用的参数都比上一次「少一层 `succ`」**，最后一定撞到
`KNat.zero` 那一支。Lean 会检查这一点，检查不过就拒绝编译。
这叫 structural recursion（结构递归）：沿着构造子的结构往下拆。

把它复制到你的作业文件里，测试时 `#eval toNat (...)`。

反方向也写一个，把普通 `Nat` 换算成 `KNat`。它顺便展示**对库里的 `Nat` 做模式匹配**的写法：
模式 `0` 就是零，模式 `n + 1` 就是「比 `n` 大一」，和 `KNat.succ n` 一个意思，
模式 `_ + 3` 就是「3 或更大」。作业里 `hyperop` 的层级参数是 `Nat`，会用到这三种模式。
```lean
def ofNat : Nat → KNat
| 0     => KNat.zero
| n + 1 => KNat.succ (ofNat n)

#eval toNat (ofNat 5)       -- 5

def atLeastThree : Nat → Bool
| _ + 3 => true             -- 匹配 3、4、5、……
| _     => false            -- 其余：0、1、2

#eval atLeastThree 2
#eval atLeastThree 7
```

`ofNat` 以后也有用：`KNat` 的数字字面量只有 `0` 和 `1` 能写（§3.3 解释），
想要 5 就写 `ofNat 5`。

**两个 E10 原文里会碰到的词**。E10 第 79–81 行和第 97–101 行提到 recursor（递归子）
和 total function（全函数）。全函数指「对每个输入都必须有定义」，Lean 要求所有函数都是全函数，
这就是 `dec` 对 `KNat.zero` 也必须给个值的原因。recursor 是每个 `inductive` 自动附带的
「按构造子分情况、对递归部分递归」的通用工具，也叫归纳原理；
你写的模式匹配加结构递归，最终就是在用它。E09 整份笔记讲这个，现在知道这个词就够。

## 2.3 加法：对第二个参数递归

这是 E10 最重要的三个定义里的第一个。先看代码，再手工算一遍。
```lean
def add : KNat → KNat → KNat                -- 两个参数，都留在类型里
  | a, KNat.zero   => a                     -- 基值：a 加 0 等于 a
  | a, KNat.succ b => inc (add a b)         -- 步进：a 加「b 加一」等于「a 加 b」再加一

#eval toNat (add ktwo kthree)   -- 5
```

**三层拆法**：

1. **整体**：`add a b` 算 a 加 b。对**第二个参数** `b` 做模式匹配，第一个参数 `a` 原样带着。
2. **逐 token**：
   - `| a, KNat.zero => a`：第二个参数是 0，答案就是 `a`。
   - `| a, KNat.succ b => inc (add a b)`：第二个参数是「`b` 加一」。
     先递归算 `add a b`（第二个参数少了一层，所以会停），再 `inc` 一下。
3. **手工展开** `add 2 2`，看它到底在干什么（用 `s` 代表 `succ`，`z` 代表 `zero`）：

```text
add (s (s z)) (s (s z))
= inc (add (s (s z)) (s z))          -- 第二个参数是 s (s z)，走第二支
= inc (inc (add (s (s z)) z))        -- 第二个参数是 s z，再走第二支
= inc (inc (s (s z)))                -- 第二个参数是 z，走第一支，返回 a
= s (s (s (s z)))                    -- 两次 inc
= 4
```

4. **结论**：`add a b` 就是**对 `a` 做 `b` 次 `inc`**。E10 原文：「the add function increments
   the first argument `a`, `b` times」。记住这个说法，它是整份文件的主线。

## 2.4 乘法和乘方：同一个形状

把 `add` 的定义和下面两个并排看：
```lean
def mul : KNat → KNat → KNat
| _a, KNat.zero   => KNat.zero          -- 基值：a 乘 0 等于 0（_a 表示这支用不到 a）
| a,  KNat.succ b => add a (mul a b)    -- 步进：a 乘「b 加一」等于「a 乘 b」再加 a

def exp : KNat → KNat → KNat
| _, KNat.zero    => kone               -- 基值：a 的 0 次方等于 1
| a, KNat.succ b' => mul (exp a b') a   -- 步进：a 的「b' 加一」次方等于「a 的 b' 次方」再乘 a

#eval toNat (mul ktwo kthree)   -- 6
#eval toNat (exp ktwo kthree)   -- 8
```

三个定义放进一张表，**这张表就是老师公告（10 月 20 日 Canvas 上那条）里说的「无穷塔」**：

| 函数 | 对哪个参数递归 | 基值（第二个参数是 0 时） | 步进用的是**低一级**的哪个运算 |
|---|---|---|---|
| `add a b` | 第二个 | `a` | 「再加一」：做 `b` 次 |
| `mul a b` | 第二个 | `zero` | 「再加 `a`」：做 `b` 次 |
| `exp a b` | 第二个 | `kone` | 「再乘 `a`」：做 `b` 次 |

每一行都是「**把低一级的运算作用 `b` 次**」：

- 加法是重复加一；
- 乘法是重复加 `a`；
- 乘方是重复乘 `a`。

那么第四级显然是「重复乘方」，叫 tetration（迭代幂）。这就是作业第一题。
注意三行的基值**不一样**：`a`、`0`、`1`。这不是随意选的，
是「把低一级运算做 0 次该得到什么」：加一做 0 次还是 `a`，加 `a` 做 0 次是 0，乘 `a` 做 0 次是 1。
第四级的基值是多少？先自己想，§5.1 给出数学定义时再核对。

**递归为什么一定停**：三个定义的步进里，递归调用的第二个参数都是 `b`，比模式里的
`succ b` 少一层。Lean 看到这一点就放行。

## 2.5 小结：E10 第一段你现在能解释了

如果老师问「`mul a b` 怎么算的」，你的回答应该是：
「对第二个参数做模式匹配。`b` 是零就返回零；`b` 是 `succ b'` 就先递归算 `mul a b'`，
再把 `a` 加上去。也就是把 `a` 加到自己身上 `b` 次。递归能停，是因为每次第二个参数
少一层 `succ`。」

能说出这段话，第 2 部分就过了。
---

# 3. typeclass：让 `+` 认识你自己定义的类型

## 3.1 问题

现在 `add ktwo kthree` 能算，但你不能写 `ktwo + kthree`。
试一下（取消注释会报错）：

```lean
-- #eval ktwo + kthree
-- 报错：failed to synthesize instance of type class
--       HAdd KNat KNat ?m.4
```

报错的意思是：「我不知道两个 `KNat` 之间的 `+` 是什么」。
两个细节先解释掉：报错里写的是 `HAdd` 不是 `Add`，因为 `+` 真正查的是 `HAdd`
（允许两边类型不同的加法），库里有一条规则「有 `Add α` 就自动有 `HAdd α α α`」，
所以你只需要填 `Add`；`?m.4` 是 Lean 还没定下来的类型占位符，读成「某个待定的类型」。

`+` 对 `Nat` 能用，对 `KNat` 不能，因为**没人告诉 Lean `KNat` 怎么加**。
typeclass 就是「告诉它」的机制。

## 3.2 `class` 是一张接口表

库里 `Add` 的定义是这样的（抄出来看，不要在本文件里重新定义）：

```lean
class Add (α : Type u) where
  add : α → α → α
```

读法：「一个类型 `α` 想支持加法，就得提供一个函数 `add : α → α → α`」。
`class` 只是宣布**要填什么**，它自己不加任何东西。

两个符号：`α` 是**类型变量**，相当于泛型里的 `T`，用希腊字母只是 Lean 的习惯；
`Type u` 里的 `u` 叫宇宙层级，这门课里一律当 `Type` 读，Infoview 里显示成 `u_1` 也一样。

E10 用到的几个类，库里的定义都是这个形状：

| 类 | 它要求你提供的字段 | 对应的记法 |
|---|---|---|
| `Zero α` | `zero : α` | 字面量 `0` |
| `One α` | `one : α` | 字面量 `1` |
| `Add α` | `add : α → α → α` | `a + b` |
| `Mul α` | `mul : α → α → α` | `a * b` |
| `Pow α β` | `pow : α → β → α` | `a ^ b`（底数类型 `α`，指数类型 `β`） |

可以让 Lean 把定义打出来看：
```lean
#print Add
#check @Add.add             -- {α : Type u_1} → [self : Add α] → α → α → α
                            -- @ 让隐藏的参数显示出来；花括号和方括号 §3.5 讲
```

## 3.3 `instance` 是给具体类型填表

E10 的这几行就是在填表。逐 token 拆第一条：
```lean
instance : Zero KNat where
  zero := KNat.zero
```

| token | 角色 |
|---|---|
| `instance` | 关键字：「我要给某个类填一张表」 |
| `: Zero KNat` | 填的是哪张表、给哪个类型：`Zero` 这张表，`KNat` 这个类型 |
| `where` | 下面是字段 |
| `zero := KNat.zero` | 字段名在左（必须和 class 里的一样），你的实现在右 |

填完之后，`0` 这个**字面量**就能当 `KNat` 用了：
```lean
#check (0 : KNat)           -- 0 : KNat
#eval  toNat (0 : KNat)
```

**一个必踩的坑**：填了 `Zero` 和 `One` 之后，`KNat` 的数字字面量**只有 `0` 和 `1` 能写**。
`(2 : KNat)`、`(3 : KNat)` 都会报错：

```text
failed to synthesize instance of type class
  OfNat KNat 3
numerals are polymorphic in Lean, but ...
```

因为字面量走的是 `OfNat` 这张表，库里只从 `Zero` 推出 `OfNat _ 0`、从 `One` 推出 `OfNat _ 1`。
要 2、3 就写 `ktwo`、`kthree`，或者用 §2.2 的 `ofNat 3`。作业第三题老师原话是「X plus 3」，
到时候别写 `lit 3`。

顺带一句：E10 第 184 行把 `Zero` 的字段写成 `Add.zero`，是老师的笔误，字段真名是 `Zero.zero`。

其余几张表同样填法。注意 `Add` 那条右边写的是 `KNat.add`，就是第 2 部分定义的函数：
```lean
instance : One KNat where
  one := kone

instance : Add KNat where
  add := KNat.add            -- 字段名 add 在左，我们的函数 KNat.add 在右

instance : Mul KNat where
  mul := mul                 -- 在 namespace KNat 里面，mul 就是 KNat.mul

instance : Pow KNat KNat where
  pow := exp                 -- 底数 KNat，指数 KNat
```

现在记法全部活了：
```lean
#eval toNat (1 + 1 : KNat)     -- 2
#eval toNat (ktwo * kthree)    -- 6
#eval toNat (ktwo ^ kthree)    -- 8
```

**`(1 + 1 : KNat)` 这一行到底发生了什么**，这是能拿来解释给老师听的一段：

1. 最外层的 `: KNat` 告诉 Lean 期望类型是 `KNat`。
2. `+` 于是去找「`KNat` 的 `Add` 实例」，找到了我们填的那张表，于是 `+` 就是 `KNat.add`。
3. 两个 `1` 要当 `KNat` 用，Lean 去找「`KNat` 的 `One` 实例」，找到了，于是 `1` 就是 `kone`。
4. 最后算 `KNat.add kone kone`。

说得更准确一点（老师追问时用）：`+` 直接查的是 `HAdd KNat KNat ?`，字面量 `1` 直接查的是
`OfNat KNat 1`；库里有现成规则从 `Add` 推出 `HAdd`、从 `One` 推出 `OfNat _ 1`，
所以你填 `Add` 和 `One` 就够。报错信息里出现的会是 `HAdd` 和 `OfNat` 这两个名字，不要慌。
这也解释了为什么 `(2 : KNat)` 不行：没有任何规则推出 `OfNat KNat 2`。

**记法不是函数的别名，是「谁填了表谁就能用」。** 这就是老师说的 operator overloading
（运算符重载）、ad hoc polymorphism（特设多态）：同一个 `+`，对 `Nat` 是一个函数，
对 `KNat` 是另一个函数，靠实例分派。

## 3.4 优先级和结合性是白送的

记法本身是 Lean 定义好的：`*` 的优先级比 `+` 高（后面说「紧」就是「优先级高、先算」的意思），
`-` 左结合（`a - b - c` 读成 `(a - b) - c`），这些规则跟着记法来，你填表时不用管。
E10 用四行验证了这一点：
```lean
#eval toNat (ktwo *  ktwo + ktwo)    -- 6：先乘后加
#eval toNat (ktwo * (ktwo + ktwo))   -- 8：括号改变顺序
#eval toNat (ktwo +  ktwo * ktwo)    -- 6
#eval toNat (ktwo + (ktwo * ktwo))   -- 6
```

作业第四题要你对减法、负号、变量做同样的验证，形状就是这四行。

## 3.5 `[Add α]`：把 typeclass 当门卫用

E10 第二个关于 typeclass 的用法。逐 token 拆：
```lean
def addAnyTypeAsLongItsAddable {α : Type} [Add α] : α → α → α
| a, b => a + b
```

| token | 角色 |
|---|---|
| `{α : Type}` | 花括号：一个**隐式**参数，叫 `α`，是任意类型。调用时不用写，Lean 自己推 |
| `[Add α]` | 方括号：**要求 `α` 必须有一张填好的 `Add` 表**。调用时也不用写，Lean 去找 |
| `: α → α → α` | 吃两个 `α` 还一个 `α` |
| `\| a, b => a + b` | 体里的 `+` 用的就是方括号里找到的那张表 |

所以这个函数「对任何类型都能用，**只要那个类型能加**」。这叫 type guard（类型门卫），
老师公告里专门点了这个词。
```lean
#eval addAnyTypeAsLongItsAddable 3 4                     -- Nat 有 Add 实例（库里给的）
#eval toNat (addAnyTypeAsLongItsAddable (1 : KNat) 1)    -- KNat 有，我们刚填的
#eval (3/4 : Rat) + 1/2                                  -- 老师这行只是说明有理数也有 Add 实例，
                                                         -- 并没有调用上面那个函数；输出显示成 (5 : Rat)/4

-- #eval addAnyTypeAsLongItsAddable "Hi" "There"
-- 取消注释会报错：failed to synthesize Add String
-- 字符串没有 Add 实例，门卫把它拦在外面。（字符串拼接用的是 ++，另一张表）
```

## 3.6 作业要用的两张表：`Sub` 和 `Neg`

老师说类名可以查。这就是查的办法，把库里的定义打出来：
```lean
#print Sub                  -- 字段 sub : α → α → α，对应记法 a - b
#print Neg                  -- 字段 neg : α → α，对应记法 -a

#check @Sub.sub
#check @Neg.neg
```

所以作业第一题要填的两张表长这样（字段名已经告诉你了，右边的函数是你要写的）：

```lean
instance : Sub KNat where
  sub := ???                -- 一个 KNat → KNat → KNat 的函数

instance : Neg KNat where
  neg := ???                -- 一个 KNat → KNat 的函数
```

## 3.7 小结：E10 第二段你现在能解释了

老师问「`instance : Add KNat where add := KNat.add` 是什么意思」，回答：
「`Add` 是库里的一个 class，相当于接口，要求一个 `add` 函数。这一行给 `KNat` 实现这个接口，
用的是我们自己写的 `KNat.add`。填了之后，`+` 记法就能用在 `KNat` 上，
因为 `+` 会按操作数的类型去查实例。」

老师问「`[Add α]` 是什么」，回答：
「实例隐式参数。意思是 `α` 可以是任何类型，但必须存在它的 `Add` 实例，不然调用就报错。
它是一个类型层面的门卫。」
```lean
end KNat
```

---

# 4. 把一门小语言嵌进 Lean

E10 的最后一段，也是作业第二、三题的底子。老师的 E10 开头列了三件套：

- **syntax（语法）**：哪些是合法的句子。用一个 `inductive` 定义，每种句子一个构造子。
- **semantic domain（语义域）**：句子的「意思」是什么类型的东西。这里是数。
- **semantics（语义）**：一个函数，把每个句子映射到它的意思。用模式匹配定义，每个构造子一支。

## 4.1 E10 里的算术语言（原文）

这段和老师的一字不差，语义域是库里的 `Nat`。作业第二题要你把它换成 `KNat`。
```lean
namespace Arith
open KNat                   -- 以后能直接写 kone 而不用写 KNat.kone
```

**语法**：两种句子，数字字面量和加法。
```lean
inductive Expr where
| lit (n : Nat) : Expr            -- 一个数字字面量，带着那个数
| add (e1 e2 : Expr) : Expr       -- 两个子表达式相加；注意子表达式的类型就是 Expr 本身
open Expr
```

`add (e1 e2 : Expr)` 里的参数类型是 `Expr` 自己，所以表达式可以无限嵌套，
这就是「语法树」。构造子后面多出来的 `: Expr` 是返回类型标注，可写可不写，
§1.4 的 `KNat` 就没写，E10 里两种写法都有。

**语义**：一个函数，每个构造子一支。
```lean
def arithEval : Expr → Nat
| Expr.lit n     => n                                       -- 字面量的意思就是那个数
| Expr.add e1 e2 => Nat.add (arithEval e1) (arithEval e2)   -- 加法的意思：先算两边，再相加
```

**逐 token 拆第二支**：模式 `Expr.add e1 e2` 把两个子表达式拆出来叫 `e1`、`e2`；
右边**递归**算出它们各自的意思，再用语义域上的加法 `Nat.add` 合起来。
递归能停，因为 `e1`、`e2` 都比 `add e1 e2` 小一层。

注意老师写的是 `Nat.add` 全名而不是 `+`，也不是裸的 `add`。原因：`open KNat` 和 `open Expr`
之后，`add` 这个名字有两个候选 `KNat.add` 和 `Expr.add`，在这个 `Nat` 版本里两个都不接受 `Nat`，
裸写 `add` 会报 `overloaded, errors`。作业把语义域换成 `KNat` 之后裸写虽然能编译
（Lean 按类型挑中 `KNat.add`），但读的人分不清。**语义函数体里一律写全名。**

**例子**：用构造子一层层搭出句子，再求值。
```lean
def e1 : Expr := lit 1
def e7 : Expr := lit 7
def e3 : Expr := add e1 e7
def e4 : Expr :=            -- 7 + (6 + 9)
  add
    (lit 7)
    (add
      (lit 6)
      (lit 9)
    )

#eval arithEval e4          -- 22
```

`e4` 画成树就是：

```text
      add
     /   \
   lit 7  add
         /   \
      lit 6  lit 9
```

`arithEval` 从根往下走：根是 `add`，递归算左边得 7，递归算右边（又是一个 `add`，再递归）得 15，
合起来 22。
```lean
end Arith
```

## 4.2 变量和解释：E02 的模式

作业第三题说「照我们处理命题逻辑变量的办法」。那个办法在 E02 里，精简版抄在这里。
语言换成命题逻辑，语义域是 `Bool`，但**模式一模一样**。

问题：句子里想出现变量 `X`，可 `X` 的值是多少？语法本身不知道。
办法：**求值时额外传一个「解释」进来**，解释是一个函数，告诉你每个变量的值。
```lean
namespace Logic
```

第一步：变量名本身是一个类型，有几个变量就几个构造子。
```lean
inductive Variable where
| Xvar
| Yvar
| Zvar
```

第二步：语法里加一个 `Var` 构造子，带一个变量名。
```lean
inductive PropLogicSyntax where
| T
| F
| And (left right : PropLogicSyntax) : PropLogicSyntax
| Not (p : PropLogicSyntax)
| Var (v : Variable)              -- 变量句子：就是一个变量名
```

第三步：**解释**就是「从变量名到值」的函数。§0 说过类型本身也是 term，
所以可以用 `def` 给一个类型起名字：下面这行之后，`varInterp` 和 `Variable → Bool` 完全等价。
```lean
def varInterp : Type := Variable → Bool
```

写一个具体的解释：它是一个函数，所以用 `fun v => ...`（§1.3）；
参数 `v` 已经有名字了，所以在函数体里用 `match`（§1.5 末尾那种写法）按变量分情况。
```lean
-- 一个具体的解释：X 真，Y 假，Z 真
def i1 : varInterp :=
  fun v =>
    match v with
    | Variable.Xvar => true
    | Variable.Yvar => false
    | Variable.Zvar => true
```

第四步：语义函数**多接一个参数** `i`，遇到 `Var v` 就去问 `i`。
```lean
def eval : PropLogicSyntax → varInterp → Bool
| PropLogicSyntax.T,       _ => true
| PropLogicSyntax.F,       _ => false
| PropLogicSyntax.And p q, i => (eval p i) && (eval q i)   -- && 是布尔「与」；递归时把 i 原样传下去
| PropLogicSyntax.Not p,   i => !(eval p i)                 -- ! 是布尔「非」
| PropLogicSyntax.Var v,   i => i v                        -- 变量的意思：问解释

#eval eval (PropLogicSyntax.And (PropLogicSyntax.Var Variable.Xvar)
                                (PropLogicSyntax.Var Variable.Yvar)) i1   -- true && false = false

end Logic
```

**四步模式**，作业第三题就是把它搬到算术语言上：

1. 一个 `Variable` 类型；
2. 语法里加 `var (v : Variable)` 构造子；
3. 一个解释类型 `Variable → 语义域`；
4. 语义函数多接一个解释参数，`var` 那一支返回 `i v`，其他支把 `i` 原样传给递归调用。

到这里，E10 全文你都能读了。下面逐题拆作业。
---

# 5. 作业逐题拆解

**先建文件。** 在容器终端里：

```bash
cp FPCourse/ClassNotes/E10_Arith.lean Study/HW_E10.lean
```

以后都在 `Study/HW_E10.lean` 里改，不动老师的原文件（老师的文件 upstream 会更新，
改了会合并冲突）。验证用 `lean Study/HW_E10.lean`。

**先复制两个工具**：把 §2.2 的 `toNat` 和 `ofNat` 复制进去，放在 `dec` 后面。
测试用 `toNat` 看普通数字，造大于 1 的数用 `ofNat`（字面量只到 1，§3.3）。

**每题放在文件的哪里**，放错位置名字就找不到：

| 题 | 放在哪 | 位置 |
|---|---|---|
| A1 `tet`、A2 `hyperop` | `namespace KNat` 里 | `exp` 之后、`end KNat` 之前 |
| B1 `sub`、`neg` 两个函数 | `namespace KNat` 里 | `exp` 之后 |
| B1 两条 `instance` | `namespace KNat` 里 | `instance : Pow KNat KNat` 之后 |
| B2、B3 的 `Variable`、`Expr`、`Interp`、`arithEval` | `namespace Arith` 里 | 替换老师原来的 `Expr` 和 `arithEval` |
| B4 的 `#eval` 例子 | 对应定义之后 | |

**提前知道两件会报错的事**：老师原来 `Arith` 里的例子 `e1`、`e7`、`e3`、`e4` 和
`#eval arithEval e4`，在你改完 B2、B3 之后会报错（装的还是 `Nat`、参数个数变了），要跟着改或删；
`lit 3` 这种写法报 `OfNat KNat 3`，要写 `lit kthree` 或 `lit (ofNat 3)`。

老师的原话：作业不多，自己做会学到很多。所以下面每题只拆到「你知道该写什么」：
给数学定义、给要回答的问题、给测试值，**不给代码**。洞用 `???` 标出来让你填。

## 5.1 作业 A1：`tet`（E10 第 164–175 行）

**题意**：照 `add`、`mul`、`exp` 的模式写第四级运算 tetration（迭代幂）。
`tet a b` 读作「`a` 的 `b` 层幂塔」，数学上记作 a↑↑b。

**数学定义**（这是公开的数学常识，不是答案；作业是把它翻译成 Lean）：

```text
a↑↑0       = 1              -- 零层幂塔规定为 1，和 a^0 = 1 同一个道理
a↑↑(b + 1) = a ^ (a↑↑b)     -- 多一层：以 a 为底，以「b 层的结果」为指数
```

**用到的概念**：§2.4 那张表。第四级就是表里再加一行，三个格子自己填：

| 函数 | 对哪个参数递归 | 基值 | 步进用的低一级运算 |
|---|---|---|---|
| `tet a b` | ??? | ??? | ??? |

**一个和前三级不同的地方，最容易写错**：`add`、`mul` 的两个参数交换不影响结果，`exp` 不行。
`exp` 的步进写的是 `mul (exp a b') a`，递归结果在前、`a` 在后，交换也没事，因为乘法可交换。
但乘方不可交换：看数学定义，`a↑↑(b+1)` 的**底数是 `a`，指数是递归结果**。
如果照 `exp` 的样子把递归结果放到底数的位置，算出来会永远是 1。想想为什么（1 的任何次方是多少？）。

**骨架**（只给左边，右边自己翻译数学定义）：

```lean
def tet : KNat → KNat → KNat
| _, KNat.zero    => ???
| a, KNat.succ b' => ???
```

**测试**：`#eval toNat (tet ktwo ktwo)` 应该是 4（2 的 2 次方），
`#eval toNat (tet ktwo kthree)` 应该是 16（2 的 4 次方）。如果得到 1，就是上面说的参数位置放反了。

**如果老师问**：「`tet` 和 `exp` 的关系？」答：「和 `exp` 对 `mul` 的关系一样，是塔的下一层：
对第二个参数递归，基值是 1，步进用 `exp`。唯一要小心的是乘方不可交换，底数必须是 `a`。」

## 5.2 作业 A2：`hyperop`（同一段，老师标了「harder」）

**题意**：写一个三参数函数 `hyperop n a b`，`n` 是「层级」，使得 `tet a b` 就是某一层的 `hyperop`。
也就是把整座塔写成**一个**函数。

**先定编号**。E10 原文说：恒等是第 0 层、`inc` 第 1 层、`add` 第 2 层、`mul` 第 3、`tet` 第 4。
注意这个列表**漏了 `exp`**：补上之后要么 `tet` 变成第 5 层，要么就得换一种编号。
老师公告（10 月 19 日 Canvas）里贴了 Mathlib 的一条定理：

```text
theorem hyperoperation_zero (m k : ℕ) : hyperoperation 0 m k = k + 1
```

（`ℕ` 是 Mathlib 里 `Nat` 的写法。）意思是 Mathlib 把**第 0 层定成 `succ`**，
于是 `add` 是第 1 层、`mul` 第 2、`exp` 第 3、`tet` 第 4，正好和老师说的 `tet a b = hyperop 4 a b` 对上。
老师说「或许第 0 层是 `inc`？自己搞清楚」。结论：**两种编号都行，但必须自洽**；
用 Mathlib 的编号最省事，下面按它来。

**难点一：基值随层级变**。看 §2.4 的表：每一层的基值不一样（`add` 是 `a`，`mul` 是 `0`，
`exp` 和更高都是 `1`）。所以 `hyperop` 不能只有一个基值，要**按层级分情况**：

| 层级 `n` | `hyperop n a 0` 应该是 | 原因 |
|---|---|---|
| 0 | 不需要基值：第 0 层就是「`b` 加一」，对 `b` 不递归 | |
| 1（加法） | `a` | `a + 0 = a` |
| 2（乘法） | `zero` | `a * 0 = 0` |
| 3 及以上 | `kone` | `a ^ 0 = 1`，往上都是 1 |

匹配「3 及以上」用 §2.2 演示过的模式 `_ + 3`；匹配 0、1、2 直接写字面量。

**难点二：步进只有一条，要想清楚它说的是什么**。回到 §2.4 的三行：
`add a (succ k)` 是「对 `add a k` 的结果再加一」；`mul a (succ k)` 是「把 `a` 加到 `mul a k` 的结果上」；
`exp a (succ k)` 是「把 `exp a k` 的结果再乘 `a`」。三行是**同一句话**：
「第 n+1 层在 `succ k` 处的值，等于用第 n 层的运算，把 `a` 和『第 n+1 层在 `k` 处的值』合起来」。
`hyperop` 的步进就是把这句话里的「第 n 层的运算」写成对 `hyperop n` 的递归调用。
所以步进里有两处递归：一处层级降一（变成 `n`），一处同层但第二个参数降一（变成 `k`）。

**Mathlib 的定义就是这个结构**。老师公告指的就是它，读懂它是这节课的内容。
文件在容器里的 `.lake/packages/mathlib/Mathlib/Data/Nat/Hyperoperation.lean`，定义原文：

```lean
def hyperoperation : ℕ → ℕ → ℕ → ℕ
  | 0, _, k => k + 1
  | 1, m, 0 => m
  | 2, _, 0 => 0
  | _ + 3, _, 0 => 1
  | n + 1, m, k + 1 => hyperoperation n m (hyperoperation (n + 1) m k)
```

五个分支逐行对照上面两个难点读（`m` 是我们的 `a`，`k` 是我们的 `b`）：

| 行 | 模式 | 说的是 |
|---|---|---|
| 1 | `0, _, k` | 第 0 层：不管 `m` 是什么，结果是 `k` 加一。对 `k` 不递归 |
| 2 | `1, m, 0` | 第 1 层（加法）的基值：`m` |
| 3 | `2, _, 0` | 第 2 层（乘法）的基值：0 |
| 4 | `_ + 3, _, 0` | 第 3 层及以上的基值：1。`_ + 3` 匹配「3 或更大」（§2.2） |
| 5 | `n + 1, m, k + 1` | 统一步进：层级至少 1、`k` 至少 1 时，用第 `n` 层把 `m` 和「第 `n+1` 层在 `k` 处的值」合起来 |

第 5 行就是难点二那句话的代码形式：外层 `hyperoperation n m (...)` 是「用低一级运算」，
里层 `hyperoperation (n + 1) m k` 是「本级在 `k` 处的值」。两处递归，一处层级降一，一处 `k` 降一。

前四行为什么能这么排：Lean 的分支**按顺序**尝试，`k + 1` 这个模式只匹配非零的 `k`，
所以第 5 行永远碰不到 `k = 0`，`k = 0` 全被前四行接走了；
第 5 行的 `n + 1` 要求层级非零，层级为 0 的全被第 1 行接走了。五行合起来覆盖所有输入，没有遗漏。

同一个文件里还有几条定理，Mathlib 用它们**证明**了这个编号确实对应我们熟悉的运算。
老师让你去看的那条 `hyperoperation_zero` 就是第一条：

```text
hyperoperation_zero  (m k : ℕ) : hyperoperation 0 m k = k + 1
hyperoperation_one   (m k : ℕ) : hyperoperation 1 m k = m + k
hyperoperation_two   (m k : ℕ) : hyperoperation 2 m k = m * k
hyperoperation_three (m k : ℕ) : hyperoperation 3 m k = m ^ k
```

所以「第 0 层后继、1 加、2 乘、3 幂、4 迭代幂」不是约定俗成，是被证明了的。

**翻译成 KNat 时注意**：层级 `n` 用库里的 `Nat`（模式 `0`、`1`、`2`、`_ + 3`、`n + 1` 都能直接用，§2.2）；
后两个参数是 `KNat`，所以「零」写 `KNat.zero`，「`k` 加一」在模式里写 `KNat.succ k`、
在右边写 `inc k`。函数类型是 `Nat → KNat → KNat → KNat`。

**骨架**（左边已按 Mathlib 翻译好，右边自己写）：

```lean
def hyperop : Nat → KNat → KNat → KNat
| 0,     _, k           => ???
| 1,     m, KNat.zero   => ???
| 2,     _, KNat.zero   => ???
| _ + 3, _, KNat.zero   => ???
| n + 1, m, KNat.succ k => ???
```

**关于终止**：这个递归不是沿着单个参数变小的（层级降一的那处递归，`k` 的位置没变小；
`k` 降一的那处，层级没变小）。Lean 4.33 能自动发现「先看 `n`、再看 `k`」的顺序，
**不需要你加任何标注**就能编译。如果报 `failed to prove termination`，
说明某处递归调用既没降层级也没降 `k`，回去对照难点二那句话。

**测试**：`toNat (hyperop 1 ktwo kthree)` 应为 5，`hyperop 2 ktwo kthree` 应为 6，
`hyperop 3 ktwo kthree` 应为 8，`hyperop 4 ktwo ktwo` 应为 4。

**如果老师问**：「为什么基值要分三种？」答：「因为『把低一级运算做 0 次』在每一层得到的东西不同：
加法得 `a`，乘法得 0，乘方及以上得 1。Mathlib 的定义也是这么分的。」

## 5.3 作业 B1：`Neg`、`Sub` 和它们的实例（E10 第 251–255 行）

**题意**：给 `KNat` 加一元负号和减法两个运算，并填 `Neg`、`Sub` 两张表，让 `-a` 和 `a - b` 能写。
两个函数和两条 instance 都放在 `namespace KNat` 里（§5.0 的放置表）。

**先想语义**。`KNat` 是自然数，没有负数（§1.1、§2.1 的 `dec`）。所以：

- `a - b`：减不下去就停在 0。这叫截断减法，和 `Nat` 的 `3 - 10 = 0` 一样。
- `-a`：自然数没有负数，但 `neg` 的类型必须是 `KNat → KNat`，总得返回点什么。
  有几种选择：返回 0（和减法的截断一致）、返回 `a` 本身（什么都不做）、或者别的。
  哪一种最说得通？这道题的一部分就是让你做这个决定，并在文件里写一行注释说明理由。

**减法的形状**：对照 `add`，先回答两个问题：
`a - 0` 是多少？`a - (b + 1)` 和 `a - b` 差多少，§2.1 里哪个函数能做出这个「差」？
答完这两个问题，减法的两个分支就有了。

```lean
def sub : KNat → KNat → KNat
| a, KNat.zero   => ???
| a, KNat.succ b => ???
```

**负号**：输入是什么都返回你决定的那个值，一个分支就够。

**填表**：字段名在 §3.6 已经查出来了：`Sub` 的字段叫 `sub`，`Neg` 的字段叫 `neg`。
照 `instance : Add KNat where add := KNat.add` 的样子写两条。

**测试**：`toNat (kthree - kone)` 应为 2，`toNat (kone - kthree)` 应为 0；
`toNat (-kthree)` 的期望值取决于你对 `neg` 的决定。

**如果老师问**：「你的 `neg` 为什么这么定？」答案要说出三点：自然数没有负数；
返回类型又必须是 `KNat`，所以这是一个设计选择；你选的是什么、为什么它和减法的截断语义一致
（或者你有别的理由）。

## 5.4 作业 B2：把 `Arith` 换成 `KNat`，加减法和负号（E10 第 257–261 行）

**题意**：§4.1 那段语言的语义域从 `Nat` 换成 `KNat`，再加两种句子：减法和负号。
改动都在 `namespace Arith` 里。

**改哪里**，按三件套逐个看：

1. **语法**：`lit (n : Nat)` 改成 `lit (n : KNat)`；加两个构造子，
   一个带两个子表达式（减法），一个带一个子表达式（负号）。照 `add` 那行的样子写。
2. **语义域**：`arithEval : Expr → Nat` 改成 `Expr → KNat`。
3. **语义**：`Nat.add` 改成 `KNat.add`；新构造子各加一支，用你 B1 写的那两个函数，**写全名** `KNat.xxx`。
   每一支的形状都和 `add` 那支一样：先递归算子表达式，再用语义域上的运算合起来。

**三个坑**：

- **老师原来的例子会坏**。E10 第 305–316 行的 `lit 1`、`lit 7`、`lit 6`、`lit 9` 装的是 `Nat`，
  改完之后全部报错。要么删掉，要么改成 `lit kone`、`lit (ofNat 7)` 这种（§3.3 讲过字面量只到 1）。
- **重名**。`Arith` 开头有 `open KNat`，`Expr` 定义后又 `open Expr`，于是 `add`、`sub`、`neg`
  这三个名字各自同时指 `KNat.xxx` 和 `Expr.xxx`。在 `KNat` 语义下 Lean 能按类型挑对，
  但读的人分不清，而且 `Expr.neg (lit kone)` 和 `-kone` 是两回事（一个是句子，一个是数）。
  **语义函数体里一律写全名。**
- **`lit` 装什么**。`lit` 现在装 `KNat`，所以写 `lit kone`、`lit (ofNat 7)`，不能写 `lit 7`。

用 `#eval toNat (arithEval ...)` 看结果。

## 5.5 作业 B3：变量表达式（E10 第 263–268 行）

**题意**：让句子里能出现变量，比如「X 加 3」。老师明说照 E02 的模式，也就是 §4.2 的四步。
改动在 `namespace Arith` 里，变量类型要定义在 `Expr` 之前。

**四步搬过来**：

1. 一个变量类型，几个变量几个构造子（照 §4.2 第一步）。
2. `Expr` 加一个带变量名的构造子（照 §4.2 第二步）。
3. 解释类型：从变量名到语义域的函数，语义域现在是 `KNat`（照 §4.2 第三步，把 `Bool` 换掉）。
4. `arithEval` 多接一个解释参数：类型变成 `Expr → Interp → KNat`，每一支的模式多一个 `, i`，
   递归调用把 `i` 原样传下去，变量那一支去问 `i`（照 §4.2 第四步的 `eval`）。

**老师原来的例子又会坏一次**：`arithEval` 变成两个参数后，`#eval arithEval e4` 少一个参数，报错。
给它补一个解释，或者删掉。

**怎么测**。写一两个具体的解释（照 §4.2 的 `i1`，右边的值换成 `KNat`），比如 X 是 2、Y 是 1。
然后拼一个句子求值。括号会有三层，变量要写全名，大概长这样
（`add`、`var`、`lit`、`X`、`i1` 按你自己起的名字改）：

```lean
#eval toNat (arithEval (Expr.add (Expr.var Variable.X) (Expr.lit kthree)) i1)   -- X 是 2 时应为 5
```

换一个解释再求一次，看结果跟着变。

**如果老师问**：「为什么求值要多一个参数？」答：「语法里的变量只是一个名字，它的值不在句子里。
解释是从名字到值的函数，求值时带着它，碰到变量就去查。同一个句子在不同解释下可以有不同的值。」

## 5.6 作业 B4：例子（E10 第 270–273 行）

**题意**：仿照 §3.4 那四行，写几个 `#eval`，展示减法、负号、变量在通常的优先级和结合性下工作。

**在 `KNat` 值上测**。这是优先级真正发挥作用的地方，因为记法是 Lean 给的。
好的测试要满足「解析对了得一个值、解析错了得另一个值」，每条都写上两种结果：

- 减法左结合：`kthree - kone - kone`。正确解析 `(3 - 1) - 1 = 1`；如果错成 `3 - (1 - 1)` 会得 3。
- 乘法比减法紧：`kthree - kone * ktwo`。正确解析 `3 - (1 * 2) = 1`；如果错成 `(3 - 1) * 2` 会得 4。
  （不要用 `kthree - ktwo * kone` 这种，两种解析都得 1，测不出东西。）
- 负号比加法紧：`-ktwo + kthree`。正确解析 `(-2) + 3`，若 `neg` 截断为零就是 `0 + 3 = 3`；
  如果错成 `-(2 + 3)` 会得 0。

**在 `Expr` 句子上测**：搭两三个带减法、负号、变量的树，在两个不同的解释下求值，
看变量的值变了结果也跟着变。句子是用构造子一层层搭的，没有优先级问题，
括号的嵌套就是树的结构。

## 5.7 做完之后的自检

能回答下面每一个问题，就说明你不只是抄对了：

1. `add a b` 对哪个参数递归？为什么递归一定会停？
2. `mul`、`exp`、`tet` 的基值分别是什么？为什么不一样？
3. `hyperop` 为什么基值要按层级分情况？步进为什么只要一条？
4. `instance : Add KNat where add := KNat.add` 这一行里，`Add`、`add`、`KNat.add` 三个名字各是什么？
5. `(1 + 1 : KNat)` 里的 `1` 和 `+` 分别是怎么被解析的？
6. `[Add α]` 和 `{α : Type}` 的区别是什么？为什么 `String` 进不去那个函数？
7. 一门语言嵌进 Lean 的三件套是什么？`Expr` 和 `arithEval` 各对应哪一件？
8. 变量为什么需要「解释」？解释的类型是什么？
9. 你的 `neg` 为什么选择那个返回值？还有别的选择吗，为什么不选？

第 5 部分的九道题，加上 §2.5、§3.7 的那几句「如果老师问」，就是下周一对一的底气。
---

# 6. 作业参考解答与逐题讲解

这一节是参考解答。先按 §5 自己试过再看，看的时候对照 §5 的拆解找「为什么这么写」。
每段代码都是活的，光标放上去能看结果。

课程大纲的规定：作业可以用 AI 工具辅助，但**必须在作业末尾附一段说明你怎么用了它**。
这一节的代码和讲解是 AI 生成的，你交作业时把这件事写进那段说明里。

下面的代码为了能在这个文件里编译，重新打开了 `namespace KNat`（namespace 可以反复打开，
后加的定义和之前的在同一个前缀下），算术语言换了个名字叫 `ArithK`，以免和 §4.1 的 `Nat` 版重名。
放进你自己的作业文件时按 §5.0 的放置表放。
```lean
namespace KNat
```

## 6.1 作业 A1：`tet`
```lean
def tet : KNat → KNat → KNat
| _, KNat.zero    => kone                 -- 基值：a↑↑0 = 1
| a, KNat.succ b' => exp a (tet a b')     -- 步进：a↑↑(b'+1) = a ^ (a↑↑b')

#eval toNat (tet ktwo ktwo)     -- 4
#eval toNat (tet ktwo kthree)   -- 16
```

**为什么这么写**：

- 形状照 `exp`：两个参数都留在类型里，对第二个参数分 `zero` 和 `succ b'` 两种情况（§2.4 的表）。
- 基值 `kone`：数学定义 a↑↑0 = 1，和 `exp` 的基值同一个道理：「做 0 次乘方」什么都没做，
  而乘方的「什么都没做」是 1（§5.1）。
- 步进 `exp a (tet a b')`：先递归算出 b' 层的塔 `tet a b'`，再以 `a` 为底、以它为指数做一次乘方。
  注意参数顺序：`exp` 的第一个参数是底数。写成 `exp (tet a b') a` 会把递归结果当底数，
  从基值 1 开始永远是「1 的多少次方」，结果恒为 1（§5.1 的坑）。
- 递归一定停：递归调用的第二个参数 `b'` 比模式里的 `succ b'` 少一层。

## 6.2 作业 A2：`hyperop`
```lean
def hyperop : Nat → KNat → KNat → KNat
| 0,     _, k           => inc k                                   -- 第 0 层：后继
| 1,     m, KNat.zero   => m                                       -- 第 1 层基值：m + 0 = m
| 2,     _, KNat.zero   => KNat.zero                               -- 第 2 层基值：m * 0 = 0
| _ + 3, _, KNat.zero   => kone                                    -- 第 3 层及以上基值：1
| n + 1, m, KNat.succ k => hyperop n m (hyperop (n + 1) m k)       -- 统一步进

#eval toNat (hyperop 1 ktwo kthree)   -- 5   = 2 + 3
#eval toNat (hyperop 2 ktwo kthree)   -- 6   = 2 * 3
#eval toNat (hyperop 3 ktwo kthree)   -- 8   = 2 ^ 3
#eval toNat (hyperop 4 ktwo ktwo)     -- 4   = 2 ↑↑ 2，和 tet ktwo ktwo 一样
```

**为什么这么写**：

- 类型 `Nat → KNat → KNat → KNat`：层级用库里的 `Nat`，这样 `0`、`1`、`2`、`_ + 3`、`n + 1`
  这些模式能直接用（§2.2 的 `ofNat` 和 `atLeastThree` 演示过）；后两个参数是 `KNat`。
- 五行就是 Mathlib 定义的逐行翻译（§5.2）：Mathlib 里的 `0` 换成 `KNat.zero`，
  模式里的 `k + 1` 换成 `KNat.succ k`，右边的 `k + 1` 换成 `inc k`。
- 前四行接住所有「第二个参数为零」和「层级为零」的情况，第五行只处理层级非零且 `k` 非零；
  分支按顺序试，所以第五行永远碰不到前四行已经接走的输入。
- 第五行的两处递归：外层 `hyperop n m (...)` 层级降一，是「用低一级的运算」；
  内层 `hyperop (n + 1) m k` 层级不变、`k` 降一，是「本级在 k 处的值」。
  合起来正是 §2.4 每一行的共同形状：第 n+1 层在 succ k 处 = 第 n 层作用在 m 和（第 n+1 层在 k 处）上。
- 终止：没有单个参数在每次递归都变小，Lean 自动找到「先比 n、再比 k」的顺序，不需要标注。
- 编号按 Mathlib：0 后继、1 加、2 乘、3 幂、4 迭代幂，所以 `tet a b = hyperop 4 a b`，
  和老师说的一致。E10 原文那份列表漏了 `exp`，按它来会多一层。

## 6.3 作业 B1：减法、负号和实例
```lean
def sub : KNat → KNat → KNat
| a, KNat.zero   => a                 -- a - 0 = a
| a, KNat.succ b => dec (sub a b)     -- a - (b + 1) = (a - b) 再减一

def neg : KNat → KNat
| _ => KNat.zero                      -- 自然数没有负数，截断成 0

instance : Sub KNat where
  sub := sub

instance : Neg KNat where
  neg := neg

#eval toNat (kthree - kone)     -- 2
#eval toNat (kone - kthree)     -- 0：截断
#eval toNat (-kthree)           -- 0：截断
```

**为什么这么写**：

- `sub` 的形状和 `add` 完全对称（§2.3）：对第二个参数递归，基值是 `a`，步进把 `inc` 换成 `dec`。
  `a - (b+1)` 比 `a - b` 少一，而「少一」正是 §2.1 的 `dec`。`dec` 在零处截断，
  所以 `sub` 自动继承了截断语义：`1 - 3` 走到 0 之后再 `dec` 还是 0。
- `neg` 只有一个分支：无论输入是什么都返回 `KNat.zero`。这是一个设计选择，
  理由是和减法的截断保持一致。另一种选择是返回 `a` 本身，但那样 `-a` 和 `a` 没区别，
  说不出它为什么叫「负号」。在文件里写一行注释说明你选了哪种。
- 两条 instance 照 §3.3 的 `Add` 那条写：类名 `Sub`、`Neg` 是 §3.6 用 `#print` 查出来的，
  字段名 `sub`、`neg` 在左，我们的函数在右。填完之后 `-` 记法就能用在 `KNat` 上，
  `a - b` 查 `Sub` 表、`-a` 查 `Neg` 表。

## 6.4 作业 B4 的前半：在 `KNat` 值上验证优先级和结合性
```lean
#eval toNat (kthree - kone - kone)    -- 1：减法左结合，(3 - 1) - 1；若右结合会是 3
#eval toNat (kthree - kone * ktwo)    -- 1：乘法比减法紧，3 - (1 * 2)；若先减会是 4
#eval toNat (-ktwo + kthree)          -- 3：负号比加法紧，(-2) + 3 = 0 + 3；若是 -(2 + 3) 会是 0
#eval toNat (ktwo ^ kthree - kone)    -- 7：乘方比减法紧，(2 ^ 3) - 1
```

这四行和 §3.4 老师那四行是同一个意思：记法的优先级和结合性是 Lean 给的，
我们只填了表，括号规则自动正确。每行注释里写了「如果解析错了会得多少」，
所以这些测试真的能分辨对错（§5.6）。

## 6.5 作业 B2 和 B3：`KNat` 上的算术语言，带减法、负号和变量
```lean
end KNat

namespace ArithK
open KNat

-- B3 第一步：变量名是一个类型
inductive Variable where
| X
| Y
| Z

-- B2：语法换成装 KNat，加 sub 和 neg；B3 第二步：加 var
inductive Expr where
| lit (n : KNat) : Expr
| add (e1 e2 : Expr) : Expr
| sub (e1 e2 : Expr) : Expr
| neg (e : Expr) : Expr
| var (v : Variable) : Expr
open Expr

-- B3 第三步：解释是「变量名 → KNat」的函数
def Interp : Type := Variable → KNat

-- B2 + B3 第四步：语义域是 KNat，多接一个解释参数
def arithEval : Expr → Interp → KNat
| Expr.lit n,     _ => n
| Expr.add e1 e2, i => KNat.add (arithEval e1 i) (arithEval e2 i)
| Expr.sub e1 e2, i => KNat.sub (arithEval e1 i) (arithEval e2 i)
| Expr.neg e,     i => KNat.neg (arithEval e i)
| Expr.var v,     i => i v
```

**为什么这么写**：

- `Variable` 必须定义在 `Expr` 之前，因为 `var` 构造子要用它。
- `lit (n : KNat)`：语义域换成 `KNat`，字面量句子装的就是 `KNat`。以后写 `lit kthree`，
  不能写 `lit 3`（§3.3 字面量只到 1）。
- `sub`、`neg` 两个构造子照 `add` 的样子写，一个带两个子表达式，一个带一个。
- `arithEval` 的类型从 `Expr → Nat` 变成 `Expr → Interp → KNat`：第二个参数 `i` 是解释。
  每一支的模式多了 `, i`；递归调用把 `i` 原样传下去；`var v` 那一支直接问 `i`，这就是 §4.2 的四步。
- 右边一律写全名 `KNat.add`、`KNat.sub`、`KNat.neg`：`open KNat` 和 `open Expr` 之后，
  `add`、`sub`、`neg` 各有两个候选，写全名才不混（§5.4）。
- 四个递归分支的形状一样：先递归算子表达式的意思，再用 `KNat` 上对应的运算合起来。
  递归能停，因为子表达式比整棵树小一层。

B4 的后半：拼几个句子，在两个不同的解释下求值。
```lean
def i1 : Interp := fun v => match v with
  | Variable.X => ktwo
  | Variable.Y => kone
  | Variable.Z => kzero

def i2 : Interp := fun v => match v with
  | Variable.X => ofNat 7
  | Variable.Y => kthree
  | Variable.Z => kone

def s1 : Expr := add (var Variable.X) (lit kthree)               -- X + 3
def s2 : Expr := sub (var Variable.X) (var Variable.Y)           -- X - Y
def s3 : Expr := neg (var Variable.Z)                            -- -Z
def s4 : Expr := sub (lit kthree) (sub (lit kone) (lit kone))    -- 3 - (1 - 1)

#eval toNat (arithEval s1 i1)   -- 5：X 是 2
#eval toNat (arithEval s1 i2)   -- 10：X 是 7
#eval toNat (arithEval s2 i1)   -- 1
#eval toNat (arithEval s2 i2)   -- 4
#eval toNat (arithEval s3 i1)   -- 0：负号截断
#eval toNat (arithEval s4 i1)   -- 3：树的结构就是括号，3 - (1 - 1) = 3
```

- `i1`、`i2` 是两个解释，照 §4.2 的写法：`fun v => match v with ...`，右边的值是 `KNat`。
- 同一个句子 `s1` 在 `i1` 下是 5、在 `i2` 下是 10：变量的值不在句子里，在解释里。
- `s4` 说明句子层面没有优先级问题：树怎么搭的，括号就怎么算。
  `sub (lit kthree) (sub ...)` 明确是「3 减去（1 减 1）」，和 §6.4 里 `kthree - kone - kone` 的
  左结合是两回事：那是记法在解析一串字符，这里是你亲手搭的树。
```lean
end ArithK
```

---

# 附录：术语对照

| English | 中文 | 一句话 |
|---|---|---|
| term / type | 项 / 类型 | 一切都是 term，每个 term 有一个 type，写 `e : T` |
| constructor | 构造子 | `inductive` 里列出的造值办法，也是唯一的办法 |
| pattern matching | 模式匹配 | 按构造子分情况，顺便把里面的东西拆出来起名字 |
| structural recursion | 结构递归 | 递归调用的参数比当前少一层构造子，所以一定停 |
| currying | 柯里化 | `A → B → C` 是 `A → (B → C)`，多参数函数是一次吃一个 |
| typeclass / class | 类型类 | 一张接口表，列出某类型要提供的字段 |
| instance | 实例 | 给某个具体类型填那张表 |
| operator overloading | 运算符重载 | 同一个 `+` 对不同类型走不同实例 |
| instance implicit `[C α]` | 实例隐式参数 | 要求 `α` 有 `C` 的实例，否则调用报错；老师叫它 type guard |
| syntax / semantic domain / semantics | 语法 / 语义域 / 语义 | 一个 inductive / 一个类型 / 一个求值函数 |
| interpretation | 解释 | 从变量名到值的函数，求值时带着 |
| deep embedding | 深嵌入 | 把语法做成一个 inductive 数据结构、再写求值函数，而不是直接用 Lean 自己的运算 |
| operational semantics | 操作语义 | 用一个求值函数一步步算出句子的意思 |
| total function | 全函数 | 对每个输入都有定义；Lean 要求所有函数都是全函数 |
| recursor | 递归子 / 归纳原理 | 每个 inductive 自带的「分情况加递归」工具，模式匹配最终编译成它 |
| `HAdd` / `OfNat` | （保留英文） | `+` 和数字字面量真正查的表，由 `Add`、`Zero`、`One` 自动推出 |
| `ℕ` | 自然数 | Mathlib 里 `Nat` 的写法 |
| hyperoperation | 超运算 | 后继、加、乘、乘方、迭代幂……同一个模式的无穷塔 |

<div class="issue-box">📝 <a href="https://github.com/kevinsullivan/Lean4CS1/issues/new">Report an issue</a> with this section</div>

