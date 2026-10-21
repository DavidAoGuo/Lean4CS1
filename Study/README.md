# Study：课堂笔记中文详解计划（总控文件）

这个目录是我自己的学习材料，不属于课程仓库。课程仓库的更新来自 upstream（kevinsullivan/Lean4CS1），本目录只存在于我的 fork。

## 1. 这个文件怎么用

- **主对话**负责整体流程：决定做哪份、更新下面的进度表、处理 upstream 更新后哪份要重做。
- **每份文档开一个新对话**。新对话第一句话让 AI 读本文件，然后按第 6 节的启动提示词开工。
- 一份文档写完、答疑完、口试通过后，回到主对话说一句「某某完成」，主对话更新进度表。

## 2. 进度表

| 文档 | 讲解对象 | 基于 upstream | 状态 | 口试 |
|---|---|---|---|---|
| `Study/L00_Syntax_zh.lean` | Lean 语法解剖。范围见第 5 节 | e39df37 (2026-10-07) | **修订完成，主对话 2026-10-21 二次通读验收通过**（4423 行，编译通过，`.md` 已生成）。已写完待答疑 | |
| `Study/E00_Types_zh.lean` | `FPCourse/ClassNotes/E00_Types.lean` | e39df37 | 未开始 | |
| `Study/E01_Derivations_zh.lean` | `FPCourse/ClassNotes/E01_Derivations.lean` | e39df37 | 未开始 | |
| `Study/E02_PropLogic_zh.lean` | `FPCourse/ClassNotes/E02_PropLogic.lean` | e39df37 | 未开始 | |
| `Study/E05_ClassicalVsConstructive_zh.lean` | `FPCourse/ClassNotes/E05_ClassicalVsConstructive.lean` | e39df37 | 未开始 | |
| `Study/E06_Negation_zh.lean` | `FPCourse/ClassNotes/E06_Negation.lean`，内容简略，需从 W00 §0.6、W10 §10.1 补 | e39df37 | 未开始 | |
| `Study/E07_Exists_zh.lean` | `FPCourse/ClassNotes/E07_Exists.lean`。upstream 2026-10-14 到 10-16 大改过（+460/−45 行），写时以 ec7a8f5 版为准 | ec7a8f5 | 未开始 | |
| `Study/E08_MoreAboutTypes_zh.lean` | `FPCourse/ClassNotes/E08_MoreAboutTypes.lean` | e39df37 | 未开始 | |
| `Study/E09_Induction_zh.lean` | `FPCourse/ClassNotes/E09_induction.lean`，423 行。归纳即 inductive 类型的消去：Empty/Unit/Bool/Nat/String 的 recursor | ec7a8f5 (2026-10-20) | 未开始 | |
| `Study/E10_Crash_zh.lean` | **3 小时速成**：从零到 E10 作业，主对话 2026-10-21 直接写的。子 agent 以学生视角审读后按报告修订（去掉泄露的作业代码、补放置表、字面量只到 1、`tet` 参数顺序、`HAdd`/`OfNat`、改正一处事实错误）；按用户要求保留了 Mathlib `hyperoperation` 定义原文和逐行讲解，因为那是老师指定的内容。编译通过，`.md` 已生成。时间紧时先读这份 | ec7a8f5 | 已写完并审校，待用户阅读 | |
| `Study/E10_Prereq_zh.lean` | E10 的前置知识，L00 没覆盖的三块：递归 inductive 上的结构递归与迭代视角、typeclass、语言深嵌入的三件套。范围见第 6 节的提示词 | ec7a8f5 | 未开始 | |
| `Study/E10_Arith_zh.lean` | `FPCourse/ClassNotes/E10_Arith.lean`，320 行。Typeclass、KNat 语义域、算术表达式的语法与操作语义。**含老师布置的作业，文档不给答案** | ec7a8f5 | 未开始 | |
| `Study/E11_AbstractAlgebra_zh.lean` | `FPCourse/ClassNotes/E11_abstractAlgebra.lean`，430 行。map、reduce、monoid 定律 | ec7a8f5 | 未开始 | |

顺序：L00 → E00 → E01 → E02 → E05 → E06 → E07 → E08 → E09 → E10 → E11。教材 W 章节不单独做；某份 E 讲不清时，从对应 W 章节取材补进那份 E 文档里。

**2026-10-21 起的插队**：课堂进度已到 E10，E10 的练习是老师布置的作业，下周有一对一摸底。所以先做 E10_Prereq → E10，再回头从 E00 按原顺序补。

状态取值：未开始 / 写作中 / 已写完待答疑 / 完成。口试列填日期。

upstream 更新后：`git log --oneline <记录的commit>..upstream/main -- FPCourse/ClassNotes/<文件>` 有输出，就把那份标成「需重看」。

## 3. 运行环境（子对话必读）

Lean **只装在 devcontainer 里**，Windows 本机没有 elan、lake、lean。

- 在 VS Code 里用 Dev Containers「Reopen in Container」打开本仓库，容器内工作目录是 `/workspaces/Lean4CS1`。镜像 2026-09-08 已构建好，重开不会重新构建。容器会被 VS Code 重建，名字随机变（曾叫 `sad_tharp`，2026-10-20 叫 `hopeful_tharp`），主对话从宿主机验证时先用 `docker ps -a` 查当前名字。
- 写讲解文档的子对话**必须在容器内开**，否则没法编译验证。
- 不要用 `lake env lean` 验证无 import 的文件。在这台机器的 Windows 绑定挂载上它要 1 到 4 分钟，2026-10-13 实测过。只有文件 import Mathlib 时才用它。
- 编译验证命令，在容器内仓库根目录执行，无 import 时 0.3 秒出结果：

```bash
lean Study/E01_Derivations_zh.lean
```

- ClassNotes 的 E 文件不 import 任何东西，是纯核心 Lean。讲解文档也不要 `import Mathlib`，几秒就能编译完。只有从 W 章节搬来的例子需要 Mathlib 时才加 import，并在文档里注明。
- 顶层 `Study/` 不在 `lakefile.lean` 的 `FPCourse` 范围内，`lake build` 不会编译它，不影响课程构建。但 VS Code 打开其中的 `.lean` 文件时 Lean 扩展和 infoview 正常工作。

**Markdown 预览**（2026-10-20 加）。`.lean` 源码视图里标题和表格不渲染，层次看不出来。所以每份 `Study/X.lean` 配一份用课程脚本生成的 `Study/X.md`，读的时候开 `.md` 的预览（`Ctrl+Shift+V`）当书看，侧边 Outline 面板就是目录；`.lean` 在旁边开着做交互。`.md` 是生成物，不要手改；改完 `.lean` 立刻重新生成。

容器内：

```bash
python3 scripts/convert.py Study/X.lean Study/X.md
```

宿主机（没有 `python`，用 `py` 启动器）：

```bash
py -3 -I scripts/convert.py Study/X.lean Study/X.md
```

生成的 `.md` 末尾会带一个「Report an issue」小框，是课程脚本加的，不用管。

## 4. 写作约定（子对话必须遵守）

**格式**

- 文件是 literate Lean：中文讲解放在 `/- @@@ ... @@@ -/` 块里，Lean 代码裸写在块外，和课程文件一样。
- 文件开头第一个块写明：讲解对象、基于的 upstream commit 和日期、写作日期。
- 文件必须通过 `lean` 编译。练习留空用 `sorry`，警告允许，错误不允许。故意展示报错的例子用 `#guard_msgs` 包住，和 E08 的做法一样。
- 文档里的每段代码都要是能跑的。讲解中引用代码时用行内代码或代码块，不要只用文字描述。

**语言**

- 正文中文。
- Lean 标识符、关键字、术语保留英文，首次出现写成「English（中文）」，比如 introduction rule（引入规则）、constructor（构造子）。之后可以只写英文。
- 文档末尾放一张术语表：英文、中文、一句话解释。
- 不用 Java 或其他语言做类比。把概念本身讲清楚。

**结构：跟着源文件走，不另立模板**

- 讲解顺序严格跟源 E 文件的小节顺序，源文件的每个小节、每段代码、每道练习都要覆盖，不跳过。
- 每个小节内部的自然流程：先讲这节要解决什么问题和核心概念，再逐段拆代码，最后是这节的练习。
- 某个语法形式**第一次出现时就地解释**，之后不再重复，只说「见 L00 第几节」。
- 源文件简略的地方（尤其 E06 是原始课堂速记）要补全，材料从教材 W 章节取。补的内容注明来自哪一章哪一节。

**拆代码的方式**（这是整个计划的核心）

每段代码按下面三层讲，目的是让我看到同类代码能读懂、看到同类题能写出来：

1. 整体：这段在定义什么或证明什么，类型签名用中文读出来。
2. 逐 token：标出每个符号的角色。哪个是被绑定的变量名、它的类型是什么、哪个是 constructor、哪个是函数应用、哪个是模式匹配的分支、`=>` 左右各是什么、隐式参数在哪里被自动填上了。
3. 逻辑对应：每一步用的是哪条规则（哪个类型的 introduction 还是 elimination），这一步之后目标变成了什么。
4. 迁移：换成一道类似的题，哪些地方会变、哪些地方不变。用一两个变式实际演示。

每讲完一个类型或连接词，顺手总结一句「以后看到目标是这个形状就写什么，看到假设是这个形状就怎么用」。文档末尾把这些句子汇总成一张速查表。

**练习与答案**

- 源文件的练习保留并翻译，再为每个重要例子出两到三道变式题。
- 练习放在它所属小节的末尾。
- 答案**紧跟在该小节的练习之后**（2026-10-20 改：之前是集中放文末，用户看了觉得来回翻不方便）。练习和答案之间放一条醒目的分隔线和一行「先自己做，再往下看」，让人有机会先动手。答案给完整代码并简短说明思路。
- 答案里的代码也要能编译。为了和练习不重名，答案包在 `namespace Answers_N` 里（N 为节号）或改名。

**回指 L00，不重讲**（2026-10-21 加）

- L00 已经定稿，章节编号稳定：§2 值和类型、§3 函数、§4 类型、§5 模式匹配、§6 定义进阶和作用域、§7 命题与证明、§8 tactic、§9 命令补遗、§10 记法、§11 Decidable 与 Classical、§12 速查表、§13 术语表。写任何后续文档前先读 L00 的 §1.5 目录和 §12 速查表。
- L00 讲过的语法在后续文档里**不重讲**，只写「见 L00 §x.y」。只有本文档新出现的语法才就地解释。
- 后续文档之间同理：E10 文档引用 E10_Prereq 时写「见 Prereq §x.y」。

**老师布置的作业题不给答案**（2026-10-21 加）

- 源文件里标了 EXERCISE / EXERCISES、或老师公告里指定为作业的题，老师明确要求学生自己做、不许让 agent 代写。
- 对这类题，文档只做四件事：翻译并解释题意；指出要用的概念并回指到讲过的小节；列出容易踩的坑；讨论老师给的提示。**不写出任何一题的代码**，也不出「改个名字就是答案」的变式题。
- 例外（2026-10-21 用户定）：老师在公告或笔记里**明确指向的库定义和定理**（比如 Mathlib 的 `hyperoperation`）属于课程内容，可以原文引用并逐行讲解。学生要做的是把它翻译到作业的类型上，那一步仍然留给学生。
- 例外二（2026-10-21 用户因时间紧要求）：E10 速成版末尾加了第 6 节「参考解答与逐题讲解」，含全部作业代码和原因。课程大纲规定用了 AI 的作业必须附使用说明，主对话拒绝生成抹掉这一点的交稿文件；交什么、怎么写说明由用户决定。
- 不是作业的练习（E 文件正文里的 checkpoint、文档自己出的变式题）照常给答案。
- 用户的作业写在 `Study/HW_<E编号>.lean`，自己建、自己写，子对话只在用户贴出代码后帮忙看错在哪。

**不要做的事**

- 不改 `Study/` 以外的任何文件。
- 不 commit、不 push，除非我明确要求。
- 不碰 upstream。

## 5. L00 语法解剖的范围

L00 不是另一本教材，是一份「看到符号知道它是什么」的对照手册。按下面的清单覆盖，每一项给最小可运行的例子，例子尽量直接取自 ClassNotes 的 E 文件，这样读 E 时能认出来。

这份清单是统计 E00 到 E08 实际用到的语法得出的，不要超出去讲。

1. 文件和命令：`--` 和 `/- -/` 注释、`/- @@@ @@@ -/` 文学化块、`#check`、`#eval`、`#print`、`#guard`、`#guard_msgs`、`namespace` / `end`、`open`、`variable`。
2. 定义：`def 名 (参数 : 类型) : 返回类型 := 体`、`abbrev`、`let`、`where`、显式参数 `( )`、隐式参数 `{ }`、`_` 让 Lean 推断、`@` 关闭隐式。
3. 函数：`fun x => ...`、多参数是柯里化、函数类型 `α → β`、应用就是空格、`→` 右结合。
4. 模式匹配：`match ... with | 模式 => ...`、`def` 直接写 `| 模式 => ...`、匿名构造 `⟨a, b⟩`、投影 `.1` `.2` `.left` `.right`、`if then else`。
5. 类型：`Type` 和 `Prop` 的区别、`inductive` 的构造子和参数、`structure` 和字段、`deriving Repr`、基本类型 `Empty` `Unit` `Bool` `Nat`、`Prod`（`×`）、`Sum`（`⊕`）、多态类型参数。
6. 命题与证明：`theorem` 和 `example` 的区别、`∀` `∃` `¬` `∧` `∨` `→` `↔` `=` 各自怎么读、`And.intro` `And.left` `And.right`、`Or.inl` `Or.inr`、`Exists.intro` `Exists.elim`、`rfl`、`sorry`、`True.intro`、`False.elim`。
7. term 模式和 tactic 模式：同一个证明两种写法并排，`by`、`intro`、`exact`、`apply`、`constructor`、`cases`、`decide`、`simp`，每个 tactic 对应 term 模式的什么。
8. 自定义记法：`notation`、`infix`、`prefix`，E02 用到。
9. 其他：`Decidable`、`Classical.em`、`Classical.byContradiction`。

取材来源：`FPCourse/T01_ExpressionsFunctionsRecursion/W00` 到 `W02`、`ProgrammingWithTypes/C01` 到 `C05`、`FPCourse/ClassNotes/` 全部文件。

## 6. 子对话启动提示词

在容器内的 VS Code 里打开新的 Claude Code 对话，粘贴下面一段，把文件名换掉。

写 L00：

```text
请先完整读取 Study/README.md，严格遵守其中第 3、4、5 节。然后按第 5 节的范围，读取 FPCourse/T01_ExpressionsFunctionsRecursion/W00 到 W02、ProgrammingWithTypes/C01 到 C05、以及 FPCourse/ClassNotes/ 下全部文件，写出 Study/L00_Syntax_zh.lean。写完后在容器内运行 lean Study/L00_Syntax_zh.lean 验证，报告结果，然后等我提问。
```

修订 L00（2026-10-20 审读后）：

```text
请先完整读取 Study/README.md，严格遵守其中第 3、4 节。然后完整读取 Study/L00_review.md 和现有的 Study/L00_Syntax_zh.lean。按 L00_review.md 第 2 节的新顺序重写 Study/L00_Syntax_zh.lean：第 1 节的卡壳点逐条消除，第 3 节列的内容删掉或移到指定位置，第 4 节的小错误改掉，答案改为紧跟在每节练习之后。review 第 6 节说保留的部分整段搬过去。每处理完 review 里的一条就在那条前打 [x]。写完后在容器内运行 lean Study/L00_Syntax_zh.lean 验证，再用 python3 scripts/convert.py Study/L00_Syntax_zh.lean Study/L00_Syntax_zh.md 生成预览，报告行数和编译结果，然后等我提问。
```

写 E10 前置知识（2026-10-21）：

```text
请先完整读取 Study/README.md，严格遵守其中第 3、4 节。然后读取 Study/L00_Syntax_zh.lean 的 §1.5 目录和 §12 速查表；引用 L00 时用「L00 §x.y」，L00 讲过的语法不重讲，只回指。再读取 FPCourse/ClassNotes/E10_Arith.lean 全文、FPCourse/ClassNotes/E09_induction.lean 全文、FPCourse/ClassNotes/E02_PropLogic.lean 前 100 行，以及 FPCourse/T05_AbstractTypesAndTypeClasses/W12_TypeClassesDecidable.lean 的开头 25 行和 §12.5（第 189 到 240 行）。

写 Study/E10_Prereq_zh.lean：读 E10 之前需要、而 L00 没有覆盖的三块前置知识。读者已学完 L00，没学过函数式语言，也没学过逻辑。严格按下面三块的顺序写，每块先讲概念再逐行拆代码，语法第一次出现时回指 L00。

一、递归 inductive 上的结构递归。以库里的 Nat 和 List 为例讲：基值加步进、对哪个参数递归、为什么 Lean 要求递归调用的参数在结构上变小、用 #eval 和手工展开看几步计算过程。然后讲「把低一级的函数作用 y 次」这种迭代视角：后继、加法、乘法、乘方是同一个模式的四层，只用库里的 Nat 自己定义 myAdd、myMul、myPow 来演示，不碰 KNat，不定义 tet，不定义 hyperop。最后用一小段说明 Nat.rec 是什么、match 和等式形式最终编译成 recursor，这是 E09 的要点，点到为止。

二、typeclass。class 是一张接口表、instance 是给某个具体类型填表、+ 这类记法怎么靠实例解析、[C α] 写在参数表里是 type guard、数字字面量 0 和 1 靠 Zero、One、OfNat 实例、怎么找库里的类名和字段名（#check @Add.add、#print Add）、failed to synthesize 这个报错怎么读。用一个和算术无关的自定义类型（比如二维向量 Vec2）写 Add 和 Mul 的实例做演示。不写 Neg 或 Sub 的实例，那是作业。

三、把一门语言深嵌入 Lean 的三件套：语法是一个 inductive、语义域是一个类型、语义是一个求值函数；变量表达式和解释函数。先回指 L00 §5.3 已有的命题逻辑例子，再用一个和算术无关的小语言（比如字符串拼接语言）从头演示三件套加变量加解释。不写算术语言，不写减法、负号，那是作业。

每块末尾有练习和紧跟的答案。练习必须是变式题，不能是 E10 的作业题，也不能是改个名字就得到作业答案的题。写完后在容器内运行 lean Study/E10_Prereq_zh.lean 验证，再用 python3 scripts/convert.py Study/E10_Prereq_zh.lean Study/E10_Prereq_zh.md 生成预览，报告行数和编译结果，然后等我提问。
```

写 E10（2026-10-21，含作业，注意第 4 节「作业题不给答案」）：

```text
请先完整读取 Study/README.md，严格遵守其中第 3、4 节，特别是「作业题不给答案」和「回指 L00，不重讲」两条。然后读取 Study/L00_Syntax_zh.lean 的 §1.5 目录和 §12 速查表，以及 Study/E10_Prereq_zh.lean 的目录和各节标题；引用时写「L00 §x.y」或「Prereq §x.y」。再完整读取 FPCourse/ClassNotes/E10_Arith.lean，为它写中文详解 Study/E10_Arith_zh.lean。

要求：严格跟源文件的小节顺序，源文件每一段散文、每一段代码都要覆盖。每段代码按三层拆法讲。inc、dec、add、mul、exp 五个定义要并排比较出共同形状，说清楚每个是对哪个参数递归、基值是什么、步进用的是哪个低一级的函数。Classes 一节要逐 token 拆每一条 instance，并解释 #eval (1 + 1 : KNat) 里的 1 和 + 各自是怎么被解析成 KNat 上的东西的。addAnyTypeAsLongItsAddable 要讲清 [Add α] 为什么放行了 Nat、Rat、KNat 却挡住了 String。Arith 命名空间那段照常讲，它不是作业。

源文件有两处老师布置的作业：第 164 到 175 行的 tet 和 hyperop，第 248 到 274 行的四道题。对这两处只做四件事：把题意翻译清楚；指出每题要用的概念并回指（递归模式回指本文档前面和 Prereq 第一块，类名回指 Prereq 第二块，变量模式回指 L00 §5.3 和 Prereq 第三块）；列出容易踩的坑，至少包括基值随层级变化、Nat 减法在零处截断所以负号和减法只能截断、Sub 和 Neg 的类名与字段名、Arith 里 open KNat 之后名字怎么解析；讨论老师公告里「Mathlib 把第 0 级 hyperoperation 定成后继」这个提示意味着两种编号都可以但必须自洽。不写出任何一题的代码，不出改名就能得到答案的变式题。

文末加一节「做作业前的自检清单」，列出做每一题之前应该能回答的问题。写完后在容器内运行 lean Study/E10_Arith_zh.lean 验证，再用 python3 scripts/convert.py Study/E10_Arith_zh.lean Study/E10_Arith_zh.md 生成预览，报告行数和编译结果，然后等我提问。
```

写 E11（2026-10-21 当天上课要用，优先）：

```text
请先完整读取 Study/README.md，严格遵守其中第 3、4 节，特别是「作业题不给答案」「回指不重讲」两条。然后完整读取 Study/E10_Crash_zh.lean（读者刚读完它，它是本文档的主要回指对象，引用写「Crash §x.y」），再读取 Study/L00_Syntax_zh.lean 的 §1.5 目录和 §12 速查表（引用写「L00 §x.y」）。然后完整读取 FPCourse/ClassNotes/E11_abstractAlgebra.lean，为它写中文详解 Study/E11_AbstractAlgebra_zh.lean。读者情况：没学过 Lean，只读过 Crash，没读过 L00 第 7 节的证明部分，今天下午就要上这节课。

先写第 1 节「课前 20 分钟速览」并保存一次文件，再写其余部分。速览要用一页讲清这节课的主线：productNat 的基值为什么只能是 1 → reduce 把 op 和 id 抽成参数 → 类型对了但 (· * ·) 配 0 算出来全是 0 → 需要两条性质：id 是单位元、op 满足结合律 → 把 op、id 和这两条性质的证明捆在一起叫 monoid → mfold 用 [Monoid α] 做门卫，就不可能传错。再给一张「课上会听到的词」表：monoid、carrier、identity element、associativity、foldr/foldl、map、instance 与 value 的区别、Multiplicative Nat，每个一句话。

然后严格跟源文件小节顺序，源文件每一段散文、每一段代码都要覆盖，每段代码按三层拆法讲。E11 新出现、Crash 没讲的语法要就地解释：List 和 List.nil/List.cons、[] 和 :: 记法、列表字面量；(· * ·) 这种点占位的匿名函数写法；List.foldr 和 List.foldl 的区别并手工展开一次；类型变量 α β 不声明就能用（auto-bound）；(α := Nat) 具名参数写法；Int 和负数；set_option ... in；用 Monoid.op、Monoid.id 这种方式调用类字段。

证明部分按下面的深度讲，不多不少：isIdentityFor 的类型是 Prop，一个返回命题的函数；∀ a, P a 的证明是一个 fun a => ...；P ∧ Q 的证明写成 ⟨p, q⟩，两半各一个证明；¬P 是 P → False，证它就是写一个 fun h => ...；absurd 吃一个 P 和一个 ¬P 还你任何东西；by decide 让 Lean 对具体数字自己算。Nat.one_mul、Nat.add_assoc、String.append_assoc 这些是库里现成的定理名，说明「你不需要会证，只需要知道它们是证明，名字是查出来的」，并回指 L00 §7 说深入的证明写法在那里。class Monoid 的五个字段要逐个说清哪两个是数据、哪三个是命题，instance 里对应填的是值还是证明。natMulMonoid 为什么是 def 不是 instance，以及老师说的「一个类型默认只能戴一顶 Monoid 帽子」要讲透。

第 398 到 428 行的五道 EXERCISES 按第 4 节规则处理：只翻译题意、指出每题要用的概念并回指、列出坑（第 1 题要镜像哪个证明、第 2 题 instance 和 value 的区别、第 3 题显式参数和 [ ] 的区别、第 4 题 Nat 除法截断、第 5 题 List α 的 α 怎么处理），不写任何一题的代码。

文末加「上课时可以问老师的三个问题」。写完后在容器内运行 lean Study/E11_AbstractAlgebra_zh.lean 验证（这个文件和 E11 一样不 import 任何东西），再用 python3 scripts/convert.py Study/E11_AbstractAlgebra_zh.lean Study/E11_AbstractAlgebra_zh.md 生成预览，报告行数和编译结果，然后等我提问。
```

写某份 E，以 E01 为例：

```text
请先完整读取 Study/README.md，严格遵守其中第 3、4 节。然后读取 FPCourse/ClassNotes/E01_Derivations.lean，为它写中文详解 Study/E01_Derivations_zh.lean。源文件简略处从教材 W 章节补。写完后在容器内运行 lean Study/E01_Derivations_zh.lean 验证，再用 python3 scripts/convert.py 生成 Study/E01_Derivations_zh.md，报告结果，然后等我提问。
```

答疑结束后，口试：

```text
考我。按 Study/README.md 第 7 节出题。
```

## 7. 口试规则

文档学完、问题问完后，在同一个子对话里口试。AI 出三道题，题型固定：

1. **读**：给一段本章没出现过但同类的 Lean 代码，让我说出每个符号的角色和它证明或定义了什么。
2. **写**：给一个本章同类的命题或类型，让我写出证明或定义。
3. **判**：给一个说法或一段代码，让我判断对错并说明为什么。

我作答后 AI 批改。批改要指出我错在模式的哪一步，而不是只给正确答案。三题都过，回主对话报告完成。有不过的，AI 再出同类题直到过。
