# L00_Syntax_zh.lean 审读意见

- 审读日期：2026-10-20
- 审读对象：`Study/L00_Syntax_zh.lean` 初稿，4363 行，编译通过
- 审读方式：主对话以「没学过函数式语言、没学过逻辑、只会一般编程」的学生身份从第 1 行顺读到第 4363 行
- 用途：修订 L00 的子对话按本文件逐条处理。处理完一条就在该条前打 `[x]`

## 0. 总评

内容本身质量高：三层拆法、逐 token 表格、每个连接词末尾那句「看到什么就写什么」、§6 的流程、§7 的对照表、速查表、术语表，这些都对，都要保留。

问题不在讲解方式，在**顺序**和**取舍**。顺着读会在前 1400 行反复卡壳，原因是三件事：

1. **前置依赖倒置**。§1「命令」用了全文最难的例子来演示命令；§4 模式匹配在 §5 类型之前，而匹配的对象就是 §5 才定义的 inductive；`=` 和 `rfl` 到 §6.8 才讲，但 §1.3、§5.1、§5.3 已经在用。
2. **混入了大量本该属于 E 文档的证明内容**。noContradiction、DeMorgan 四条、Exists.elim 签名、Friendly 狗、奇完全数、停机问题、parametricity、带证明的 structure，这些是 E05、E07、E08 的正文，E 文档还会再讲一遍。它们占了全文约三分之一，也是「看着长」的主因。
3. **阅读载体**。答案集中在文末要来回翻；`.lean` 源码视图里 Markdown 标题和表格不渲染，层次看不出来。

修订目标：顺着读不卡壳；长度降到 2500 到 3000 行；答案跟在每节练习后；配一份 Markdown 预览。

## 1. 卡壳点清单（按行号）

每一条写明：在哪里、用了什么没讲过的东西、学生会怎么想。

- [x] **L116–117** `#check Nat.add -- Nat → Nat → Nat`。箭头类型和柯里化到 §3.2 才讲。学生的第一反应：「Nat + Nat + Nat 是什么？为什么三个 Nat？」这是 §1.3 的第 4 个例子，一上来就卡。
- [x] **L125–142** `#check (rfl : 1 + 1 = 2)`、`#check (7 > 0)`、`#check And`、`#check @And`。一段里用了 rfl、命题、Prop、And、签名形式、`@`，全是 §6 和 §2.7 的内容。后面三条「值得当场消化的细节」谈范式和 `@`，学生当场消化不了。
- [x] **L170–172** `#eval` 不能算证明，引用 E07 的 `oddPerfectAnswer'`。学生不知道证明是什么，更不知道 E07。
- [x] **L185** `#print Not -- fun a => a → False`。`fun`、`→`、`False` 都没讲。
- [x] **L193** `#print axioms Classical.em`。学生完全不知道这行在干什么，也不知道为什么要看。
- [x] **L212–274** `#guard_msgs` 整节。它本身讲得很清楚，但例子是隐式参数报错（§2.6 的内容）和 `sumProperDivisors`（`List.range`、`foldl`、lambda、`if`，全没讲）。学生看懂了机制，看不懂例子为什么报错。
- [x] **L322–357** `variable` 和 auto-bound implicit，例子是 `theorem andLeft (h : P ∧ Q) : P := h.left`。theorem、∧、`.left` 都是 §6。auto-bound implicit 本身是个进阶话题，放在 §1 太早。
- [x] **L371–385、L387** 练习 [1.3] 用了 `example`（§6.1 才讲），[1.2] 用了 `sumProperDivisors`。
- [x] **L462–465** §2.2 用 `{α : Sort u}` 演示「参数在冒号左右」。隐式参数和 `Sort u` 是 §2.6 和 §5.1。这个点用 `Nat` 就能讲清。
- [x] **L489–498** §2.3 abbrev 的例子是 `theorem sGtZ_pf : sGtZ := (by decide)`。theorem、by decide、Decidable 实例全没讲。学生：「abbrev 和 def 的区别我懂了，但这个例子在证明什么？」
- [x] **L523–535** §2.4 let 的第二个例子是 E05 的 `noContradiction`，一个完整的 ¬(P ∧ ¬P) 证明。学生在 §2 读不了证明。`swap_nat_bool` 那个例子就够了。
- [x] **L549–561** E08 的 `provedTheorem.mk (let ...)`，把 let 放在参数位置。例子本身依赖 E08，学生不认识 `provedTheorem`。
- [x] **L699–735** §2.8 parametricity 和 `branchOnType`。用了 `match`（§4）和 `#guard_msgs`。内容是 E08 的核心，E08 文档会讲。
- [x] **L904–918** §3.4 后半段讲 `Exists.elim` 第二个参数的读法。学生在 §3 不知道 ∃ 和 ∀。这段应该出现在 §6.7 讲 Exists.elim 的地方。
- [x] **L938–943** 练习 [3.4] 要求比较两个带 ∀ 的命题，需要 §6.4。
- [x] **L971–976** §4.1 第一个例子就 `inductive Variable where ...`。`inductive` 是 §5.2。模式匹配的对象就是 inductive 的构造子，所以 §4 整节都建立在 §5 上。
- [x] **L1164–1190** §4.4 `⟨⟩` 用 `theorem impEx2'' ... P ∧ Q → Q ∧ P` 和两个 ∃ 的例子。`⟨⟩` 的语法用 `Prod` 就能讲完，∧ 和 ∃ 的用法等 §6.5、§6.7 回指即可。
- [x] **L1222–1233** §4.5 投影用 `aConjPf : sGtZ ∧ sLe10 := ⟨sGtZ_pf, sLe10_pf⟩`。同上，用 `Prod` 和 `structure` 讲投影，`And.left` 留给 §6.5。
- [x] **L1277–1284** §4.6 `isPerfect` 用了 `List.range`、`foldl`、`where`。`where` 是 §2.5 讲过的，但 `foldl` 全文没讲。换一个不用 fold 的 `if` 例子。
- [x] **L1291–1377** §4.7 nomatch。依次用了 `Sort u`、空 `inductive`（§5.2）、`inductive ... : Prop`（§5.1）、`theorem`、`¬`（§6.9）、`Cat.tabby = Cat.siamese`（§6.8）、`inductive Friendly : Dog → Prop`（§5.2 最难的索引族）、`¬(∀ ...)`（§6.4）。这是全文前置依赖最多的一节。学生在这里会彻底放弃。`nomatch` 在 §4 只需讲 `Empty` 那一个例子；Cat 和 Friendly 的例子放到 §6 讲完 `=` 和 `¬` 之后。
- [x] **L1402–1406** 练习 [4.4] 需要 ∧，[4.5] 需要 `Eq`。
- [x] **L1449–1473** §5.1 proof irrelevance 的 `JorgIsFromToronto ... := rfl`，以及 `Exists.casesOn` 报错。rfl 还没讲，∃ 还没讲。proof irrelevance 是进阶内容，建议移到 §6.8 讲完 rfl 之后作为补充，或者移到 E06 文档。
- [x] **L1741–1798** §5.3 依值 structure：`typedContainer`、`provedTheorem`、`SquarePair ... rfl`、`squareChecker 3 9 rfl`。这是 E08 后半份的内容，而且用了 rfl。建议移到 §6 之后或留给 E08 文档，§5.3 只保留普通 structure。
- [x] **L2133、L2384、L2392–2393、L3261** 库引理名 `Nat.add_zero`、`Nat.le.refl`、`Nat.zero_lt_succ 9`、`Nat.one_ne_zero` 直接出现，没说这些名字从哪来。学生会想「我怎么可能知道这个名字」。要么换成 `by decide`，要么加一句「这是库里的定理名，E 文件也是直接抄的，不用记」。
- [x] **L2159–2162** `Eq (swap (swap (x, y))) (x, y)` 前缀形式的 `Eq` 出现在 §6.4，而 `Eq` 到 §6.8 才讲。

## 2. 结构问题的根源和修订顺序

根源一句话：**现在的章节顺序是「按语法分类」，不是「按学生能读懂的顺序」**。「命令」「定义」「函数」「模式匹配」「类型」这五个标签把本该顺着走的内容切开了。

建议的新顺序如下。编号是新编号，括号里是旧内容的来源。

1. **导读**（旧 §0，保留三层拆法和主线）。新增一小段「怎么读本文档」：`.lean` 在 VS Code 里开着看 infoview，`.md` 用预览当书读。
2. **值和类型**（旧 §1.3–1.4 的基础部分 + 旧 §2.1）。`#check`、`#eval` 只用数字、字符串、Bool；`e : T` 的读法；`def` 无参和有参；六个槽位；type ascription。**不出现任何箭头类型、命题、证明。**
3. **函数**（旧 §3，去掉 §3.4 后半的 Exists.elim 段和练习 [3.4]）。`fun`、柯里化、应用是空格、`→` 右结合。到这里 `Nat → Nat → Nat` 才第一次出现，并当场解释。
4. **类型**（旧 §5，去掉 proof irrelevance 和依值 structure）。`Type` 和 `Prop` 只讲到「`Nat : Type`，`7 > 0 : Prop`，两种读法」；`inductive`、`structure`、`deriving`、`Empty`/`Unit`/`Bool`/`Nat`、`Prod`/`Sum`、计数。索引族 `Friendly : Dog → Prop` 保留在这里，因为它是 inductive 语法的一部分。
5. **模式匹配**（旧 §4）。`match`、等式形式、多参数和通配符、`⟨⟩` 只用 `Prod`、投影只用 `Prod` 和 `structure`、`if`、`nomatch` 只用 `Empty`。
6. **定义进阶和作用域**（旧 §2.3–2.7 + 旧 §1.8–1.10）。`abbrev` 用类型别名举例、`let`、`where`、隐式参数 `{ }` `_` `@`、`namespace`/`open`/`variable`。auto-bound implicit 放这里的末尾。
7. **命题与证明**（旧 §6，加上从别处移来的内容）。顺序：`theorem`/`example`；**`=` 和 `rfl` 提到最前面**，因为后面每一节都用；`→`；`∀`；`∧`（回指 `⟨⟩` 和投影）；`∨`；`∃`（Exists.elim 的读法和 `→` 比 `∀` 紧的坑放这里）；`True`/`False`/`¬`；`nomatch` 在证明里（Cat、Friendly 的例子从旧 §4.7 移来）；`↔`；`sorry` 与 `_`。
8. **term 模式和 tactic 模式**（旧 §7，不动）。
9. **命令补遗**（旧 §1.5–1.7、旧 §1.10 后半）。`#print`、`#print axioms`、`#guard`、`#guard_msgs`。到这里学生已经能看懂隐式参数报错的例子了。
10. **自定义记法**（旧 §8，不动，开头加一句「读 E02 之前再看这一节」）。
11. **Decidable 与 Classical**（旧 §9，压缩，见第 3 节）。
12. **速查表**、**术语表**（旧 §10、§11）。

答案不再单独成节，跟在每节练习后面，见 README 第 4 节的新约定。

## 3. 建议删减或移出的内容

目标是把 E 文档会讲的东西从 L00 拿掉，只留语法和最小例子。每条标了去向。

- [x] 旧 §2.4 的 `noContradiction`：删，留 `swap_nat_bool`。去向：E05 文档。
- [x] 旧 §2.4 的 `provedTheorem.mk (let ...)`：删。去向：E08 文档。
- [x] 旧 §2.8 parametricity 和 `branchOnType`：压缩成三句话放在新 §6 隐式参数末尾，`#guard_msgs` 例子删。去向：E08 文档。
- [x] 旧 §3.4 后半 Exists.elim 读法：移到新 §7 的 ∃ 小节。
- [x] 旧 §4.7 的 Cat、MyFalse、Friendly、`¬(∀ d, Friendly d)`：移到新 §7「nomatch 在证明里」，只保留一个 Friendly 的例子。
- [x] 旧 §5.1 proof irrelevance 的 Jorg 例子和 `Exists.casesOn` 报错：移到新 §7 讲完 `rfl` 后作为一小段补充，或留给 E06 文档。
- [x] 旧 §5.3 依值 structure 三个例子和 `squareChecker`：留给 E08 文档。新 §4 的 structure 只讲普通 structure 和 `mk ::`。
- [x] 旧 §6.9 DeMorgan 四条：只留 `deMorganNotOr` 一条作为「证 ¬ 的模式」的例子。去向：E05 文档。
- [x] 旧 §6.4 `swap_involutive`：可以留，但把 `Eq (...) (...)` 改成 `... = ...`，并在 rfl 小节之后。
- [x] 旧 §9.2–9.3 的三个 `em` 证明：留一个 `¬¬P → P` 的即可。E06 那个两层 `em` 的 DeMorgan 例子删。去向：E05 文档。
- [x] 旧 §9.4 奇完全数全套和停机问题：删到只剩「`noncomputable` 是什么意思」加一个五行的最小例子。去向：E07 文档。
- [x] 全文的 `sumProperDivisors` 出现三次：全删，换不用 `foldl` 的例子。
- [x] 全文「E05 原话」「C02 §2.6」「W00 §0.3」这类来源标注：对学生没有意义，只在确实要让学生回去看原文时保留，其余删掉。
- [x] 旧 §10.3 对照表里的 `Σ`、`Subtype`、`and_comm`、`swapSum`：全文没出现过，删。

预计删完后 2500 到 3000 行。

## 4. 小错误

- [x] L134「见 §6.7」应为 §6.8（rfl 和范式）。
- [x] L663「`∀` 和 `→` 的关系见 §6.5」应为 §6.4。
- [x] L918「在 §6.5 和 §6.6 还会再碰到」应为 §6.4 和 §6.7。
- [x] L1369「见 §6.8」应为 §6.9（¬ 是到 False 的函数）。
- [x] 术语表 inhabited 和 term 两条引用「§0 主线」，全文没有 §0 这个标号。
- [x] 术语表 elaboration 译作「繹化」，这不是通行译法。建议保留英文，解释写「Lean 把表面语法补全成完整 term 的过程」。
- [x] L435「README 里说过的理由」：学生不知道指哪个 README。删掉这个引用，直接说理由。
- [x] 修订后所有 §x.y 交叉引用要按新编号全部重查一遍。

## 5. 阅读载体

- [x] **Markdown 预览**。课程自带的 `scripts/convert.py` 能把任意 literate `.lean` 转成 `.md`，已在 L00 上验证可用。约定：每份 `Study/X.lean` 配一份生成的 `Study/X.md`，改完 `.lean` 就重新生成。读的时候 `.md` 开预览（`Ctrl+Shift+V`）当书看，有标题、表格、代码高亮，侧边 Outline 面板就是目录；`.lean` 在旁边开着做交互。命令见 README 第 3 节。
- [x] **答案位置**。每节练习后紧跟答案，中间一条分隔线加一句「先自己做，再往下看」。
- [x] **不拆文件**。有了 `.md` 预览和 Outline，一个文件可以导航。先不拆，修订后如果还觉得长再议。

## 6. 保留不动的部分

这些部分审读时没有发现问题，修订时整段搬过去即可：§3 前半、§5.2、§5.4–5.6、§6.3、§6.5–6.8、§6.10–6.11、§7 全部、§8 全部、§10.1–10.2、§11 绝大部分、所有答案的内容。
