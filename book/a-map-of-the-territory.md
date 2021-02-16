> 你必须拥有一幅地图，无论这幅地图多么粗糙。否则你可能得把整个地方都走一遍。在*指环王*中，我不会让任何一个人走的距离超过他一天之内能走到的地方。
> 
> <cite>托尔金</cite>

我们不想把所有地方都走一遍，所以在出发之前，我们先来看一下扫描一下，看看曾经的语言实现者们都去过哪些地方。这样将会帮助我们认识我们将要去的地方，以及其他人所选择的路线是什么。

首先，让我来做一个速记。本书大部分内容是关于编程语言的*实现*，在某种程度上与*语言本身*不同，*语言本身*有点像柏拉图的理想形式这一概念。诸如“堆栈”，“字节码”和“递归下降”之类的东西，是一种特定实现可能使用的一些基本要素。从用户的角度来看，只要我们解释器的实现忠实地遵循语言的规范，那么所有的基本要素，全部是实现细节。

我们将会在细节上面花费大量的时间，所以如果每次我在提到这些细节时，都必须提到“语言*实现*”这个词，那我的手指头会抽筋儿。所以，我会使用“语言”这个词来表达一门语言或者这门语言的实现这两种含义，除非上下文要求我做出这两种意思的区别。

## 语言的各个部分

工程师从计算的暗黑时代就开始构建编程语言了。当我们能和计算机对话时，我们会发现和计算机对话是一件非常困难的事情，所以我们需要借助编程语言来和计算机对话。我发现一件很有意思的事情，就是虽然当今的计算机比最开始的计算机已经快了几百万倍，存储空间也大了很多很多，但我们构建编程语言的方式几乎没有改变。

尽管编程语言设计者们所探索的领域非常的庞大，但他们走过的路线却<span name="dead">非常少</span>。虽然不是每一个编程语言的实现都遵循着完全一样的路径——一些语言可能会走一些捷径——但这些路径是非常非常相似的。从霍普实现的第一个COBOL语言的编译器到现在很多将一门语言直接编译到JavaScript的编译器（可能非常的简陋，整个文档只是一个简单编写的Github上的README），所遵循的路径都是差不多的。

<aside name="dead">

有些路径已经走到了死胡同，比如那些零引用的论文，那些只在内存只有几百个字节情况下才有意义的优化。这些成果现在已经都被遗忘了。

</aside>

可以打个比方，这些路径都是每一个编程语言的实现所选择的登上山顶的路线而已。在山脚下从山的左边开始登山时，我们写的代码可能仅仅是字符串所构成的原始文本（比如`helloworld.java`），慢慢的往上爬，我们分析写的代码然后将这些代码转化成更高层次的表示（抽象语法树AST之类的），随着爬的越来越高，语义——也就是程序员想让计算机做的事情——变得越来越明显和清晰。

我们终于爬到了山顶。这时我们可以鸟瞰我们编写的整个程序，也能看到这些代码的真正*含义*。接下来我们从山的右边开始下山。我们将代码的高层次表示转换成底层表示形式，到了最底层我们终于可以看到CPU是如何执行这些代码的。

<img src="image/a-map-of-the-territory/mountain.png" alt="The branching paths a language may take over the mountain." class="wide" />

让我们来跟踪一下感兴趣的路径以及路径上有意思的每一个点。我们的旅程从山的左侧开始往山上爬，也就是从用户写的源程序的文本开始。

<img src="image/a-map-of-the-territory/string.png" alt="var average = (min + max) / 2;" />

### 扫描

第一步是进行**扫描（scan）**，如果你想装叉，也可以叫**词法分析（lexing）**。它们的意思都差不多。我喜欢“词法分析”这个词，因为这个就像是超级恶棍才会去做的事情。但这里我会使用“扫描”这个词，因为这个词会显得普通一些。

一个**扫描器（scanner）**（或者**词法分析器（lexer）**）会把源程序的文本当成字符流一个字符一个字符的读进来。然后，将字符流转换成一系列的<span name="word">单词</span>。在编程语言里，每一个单词都叫做一个**token**。某一些token是单个字符，例如`(`和`,`。另一些token会由多个字符组成，例如数字（`123`），字符串的字面量（`"hi!"`），以及标识符（变量名，函数名等等都是标识符，比如`min`）等等。

<aside name="word">

“Lexical”这个词来自希腊语词根“lex”，意思是“单词”。

</aside>

源程序文件中有一些字符是没有任何含义的。比如空格通常情况下完全不重要（除了Python这种强制缩进的语言），而注释也会被语言彻底忽略掉。所以扫描器一般会将空格和注释都丢弃掉，然后剩下一个干净的有意义的token序列。

<img src="image/a-map-of-the-territory/tokens.png" alt="[var] [average] [=] [(] [min] [+] [max] [)] [/] [2] [;]" />

### 解析

接下来的这一步是**解析（parsing）**。这里是我们的句法（syntax）得到一个**语法（grammar）**——从较小的部分构建更大的表达式和语句的能力就是语法——的地方。你在英语课堂上给一个句子标过语法成分（主语、谓语、宾语）吗？如果你标过，那你已经做过解析器要做的事情了。只不过英文中有着成千上万个“关键字”，而且语言的歧义已经爆表。编程语言相对于自然语言来说要简单得多（也不允许有歧义）。

一个**解析器**会接收一个token序列，然后构造一个树形结构，这个树形结构反映了语法的嵌套本质。这些树形结构有各种不同的名字——**解析树**或者**抽象语法树**——具体叫什么取决于树形结构和源程序所使用的语言的语法结构的相近程度。在实践中，编程语言黑客们通常叫这些树形结构为**语法树**，**抽象语法树（AST）**或者就叫它们**树**。

<img src="image/a-map-of-the-territory/ast.png" alt="An abstract syntax tree." />

在计算机科学的历史上，解析技术有着长长的丰富的历史。并且解析技术和人工智能社区有着非常紧密的联系。今天所使用的用来解析编程语言的很多解析技术，最开始都是AI研究者为了解析*自然语言*而发明的。这些AI研究者想让计算机和我们进行对话。

结果发现人类所使用的自然语言太过于复杂和混乱，而解析器的技术只能处理严格的语法。但这些解析器技术却非常适合用来解析编程语言的语法，因为编程语言有着非常严格的无歧义的语法定义。编程语言的语法虽然比自然语言简单多了，但我们这些容易犯错的人类在写代码时还是不断的犯各种错误，所以解析器的任务还包括报告我们编写的代码里面的**语法错误**。

### 静态分析

所有编程语言的实现的前两个阶段（扫描和解析）都是非常相似的。接下来，每个编程语言的实现的独特特点就开始展现了。在现在这个节点（做完扫描和解析之后），我们仅仅知道代码的语法结构——比如表达式是如何嵌套的这样一些信息——除此以外，我们一无所知。

在表达式`a + b`中，我们知道我们要对`a`和`b`进行相加，但我们并不知道`a`和`b`具体指的是什么。它们是局部变量吗？还是全局变量？它们在哪里定义的？

对于多数编程语言来说，我们要分析的第一点就是**绑定（binding）**或者**决议（resolution）**。对于每一个**标识符（identifier）**，我们需要找出这个标识符在哪里定义的，然后将这个标识符和它所定义的地方连接起来。这里就是**作用域（scope）**要玩耍的地方——每一个确定的名字（变量名，函数名之类的）在代码中都会有相应的明确的定义，这个定义所谓于的源程序中的那个区域就是作用域。

如果一个语言是<span name="type">静态类型的</span>，那当我们在做类型检查的时候就是在做静态分析。一旦我们知道`a`和`b`在哪里定义的，我们很容易就可以确定它们的类型。如果`a`和`b`的类型是无法相加的（整型和字符串型就不可以相加），那么我们就可以报告一个**类型错误**。

<aside name="type">

我们要构建的语言Lox是一个动态类型的语言，所以我们会在后面的步骤中做类型检查，也就是在运行时（runtime）才做类型检查。

</aside>

深呼吸一下。我们已经到达了山顶，并对我们写的代码有了一个全景式的俯瞰。在静态分析中所得到的对程序语义的洞见，需要保存起来。我们可以将这些东西保存在下面列出的这些地方：

* 通常情况下，我们会把这些语义信息作为语法树本身的**属性**保存起来——也就是说我们在使用解析器构建语法树时，为语法树的每一个节点都留了一些空位（把后面要用到的属性赋值为null），然后在静态分析这一步，把语义信息添加到这些空位中去。

* 还有一些情况下，我们可以把这些语义信息存放在查找表（lookup table）中，查找表可以用Hashmap来实现。查找表中的key是标识符——变量名或者函数声明。这种情况下，我们叫这个查找表为**符号表（symbol table）**，而查找表中的key所对应的value告诉了我们key具体的定义是什么。

* 最为强大的语义信息的记录工具，则是将抽象语法树转换为一个全新的数据结构，这个数据结构可以更加直接的表示代码的语义信息。下一部分就是讲这个内容。

到目前为止（词法分析，语法分析，语义分析），这三个阶段通常叫做解释器实现的**前端**。你可能觉得后面的阶段都是**后端**，不是这样的。回到过去那种只有“前端”和“后端”这两种概念的日子时，编译器比现在简单多了。后来的研究者在“前端”和“后端”的中间又发明了新的阶段。威廉·伍尔夫和他的公司并没有抛弃掉那些旧的术语，而是将他们发明的那些新的阶段统称为**中端**。

### 中间表示

你可以把编译器想像成一条流水线，流水线的每一个阶段的工作就是将用户写的代码组织成某种数据表示，这种数据表示使得流水线的下一个阶段更加容易实现。流水线的前端主要关心编写程序所用的编程语言。流水线的后端则更加关心程序最终将要运行在的那个体系结构。

在中端，代码可能会以<span name="ir">**中间表示（intermediate representation）**</span>（**IR**）的形式来存储。这种形式既不贴近源语言，也不贴近像汇编语言这样的最终形式（所以叫中间表示）。实际上，IR相当于两种语言（源语言和汇编语言）中间的接口。

<aside name="ir">

前人已经构建过很多种IR。你可以搜索一下“控制流图（control flow graph）”、“静态单赋值（static single-assignment）”、“CPS（continuation-passing style）”以及“三地址码（three-address code）”等等，都是很著名的IR。

</aside>

有了IR，我们不用费太多力气，就可以支持很多的编程语言以及很多的目标平台。比如你现在想实现Pascal，C和Fortran编译器，你可能想把这些语言编译到x86，ARM或许还有SPARC这种罕见的平台。这意味着你需要写*9*个完整的编译器：Pascal&rarr;x86, C&rarr;ARM, 以及其他排列组合。

而一个<span name="gcc">共享的</span>中间表示（IR），将会大幅度减小我们的工作量。你只需要为每一门编程语言写*一个*前端，这个前端用来把源程序编译成IR。然后再为每一个目标体系结构写*一个*后端就可以了，这个后端将IR编译成目标机器的汇编语言。这样我们就可以实现上述那么多排列组合了。

<aside name="gcc">

你现在应该知道为什么[GCC][]支持这么多疯狂的语言和体系结构了吧，比如像摩托罗拉68k上面的Modula-3语言的编译器（语言和体系结构都很冷门）。编程语言的前端可以选择编译成众多的IR，通常会选[GIMPLE][]和[RTL][]这两种IR。然后可以选择一个目标为68k体系结构的后端，这样就可以把IR转换成平台相关的机器代码了。

[gcc]: https://en.wikipedia.org/wiki/GNU_Compiler_Collection
[gimple]: https://gcc.gnu.org/onlinedocs/gccint/GIMPLE.html
[rtl]: https://gcc.gnu.org/onlinedocs/gccint/RTL.html

</aside>

还有一个重要的原因使得我们想把代码转换成IR，就是IR会使程序的语义变得更加清晰和明显。

### 优化

一旦我们理解了用户编写的程序的真正的含义，我们就可以将程序转换为一个不同的程序，这个程序和转换之前的程序拥有*相同的语义*，但是执行起来更有效率——也就是说，我们可以**优化**程序。

一个简单的例子就是**常数折叠**：如果一些表达式的求值结果总是同样的结果，那么我们就可以在编译期进行求值，然后将表达式的代码用求值结果进行替换。例如，如果用户键入以下代码：

```java
pennyArea = 3.14159 * (0.75 / 2) * (0.75 / 2);
```

我们可以在编译期就完成所有的计算，然后将代码转换成：

```java
pennyArea = 0.4417860938;
```

在编程语言这一摊子事情里面，优化占据了非常大的一块领地。很多编程语言黑客将他们的整个职业生涯都花在了优化这个方向，他们想要榨出编译器的每一滴性能，来使得编译器的性能基准测试能提高1个百分点。有点像强迫症一样。

在本书中，我们基本上会<span name="rathole">忽略掉优化这一部分</span>。令人惊奇的是，很多成功的编程语言基本没有做编译期优化。例如，Lua和CPython会直接生成未经优化的代码。这些语言基本都把努力投入到了提升运行时的性能这一方面。

<aside name="rathole">

如果你对这方面很有好奇心，可以搜索如下关键词：“常量传播”，“消除公共子表达式”，“循环不变代码外提”，“全局值编号“，“强度削弱”，“标量替换”，“死代码删除”，“循环展开”，等等。

</aside>

### 代码生成

当我们针对用户编写的程序做了所有的优化之后，最后一步就是要将程序转换成机器可以运行的东东。换句话说，**代码生成**，这里的“代码”通常指的是CPU可以执行的很原始的类似于汇编的指令，而不是程序员可以阅读的那种“源代码”。

最后，我们终于来到了**后端**，从山的右侧开始下山。从这里一直到走出去，我们的代码的表示形式变得越来越原始，代码的表示越来越接近机器能理解的代码，就像按照进化方向的相反方向前进一样。

我们需要做一个决定。我们是产生一枚真正的CPU可以执行的指令？还是产生一个虚拟CPU可以执行的指令？如果我们产生真正的机器代码，我们将会获得一个可执行的文件，操作系统可以将可执行文件直接加载到芯片上执行。机器代码执行的像闪电一样快，但是生成机器代码需要大量的工作。当今的体系结构有着大量的指令，复杂的流水线，以及沉重的<span name="aad">历史包袱</span>（例如x86，为了兼容以前的指令）。

如果编译器最终产生的是机器代码，那么意味着这个编译器会和特定的体系结构绑定起来。如果你的编译器的目标机器是[x86][]机器代码，那么编译出来的机器代码是无法运行在[ARM][]体系结构的设备上的。回到上世纪60年代，在那个体系结构大爆炸（出现了很多指令集）的时代，程序缺乏便携性（可以在很多平台上运行），是个巨大的障碍。

<aside name="aad">

举个例子，[AAD][] ("ASCII Adjust AX Before Division")指令可以让我们做除法操作，听起来很有用。只是这条指令，因为是操作符，所以需要将两个二进制编码的十进制数字存进16位的寄存器中。上一次*你*需要在一台16位的机器上操作二进制编码的十进制数字是什么时候？

[aad]: http://www.felixcloutier.com/x86/AAD.html

</aside>

[x86]: https://en.wikipedia.org/wiki/X86
[arm]: https://en.wikipedia.org/wiki/ARM_architecture

为了解决这个问题，像马丁·理查兹（BCPL的发明者）和尼古拉斯·沃斯（Pascal的发明者）这样的黑客分别将他们创造的语言编译成*虚拟*机器代码。他们并没有将编程语言编译成真实芯片上所能执行的指令，而是将编程语言编译成了假想中的理想的机器代码。沃斯叫这种虚拟的机器代码位**p-code**，*p*代表便携性（portable）。而在今天，我们叫这种虚拟的机器代码为**字节码**，因为每一条指令通常占用一个字节（8位）的存储空间。

这些综合的指令（字节码）被设计为比机器语言更加的接近程序语言的语义，并且不贴近任何计算机体系结构的指令集，也就没有各种指令集的历史包袱了。你可以认为字节码是编程语言底层操作的一种紧密的二进制编码的表示方式。

### 虚拟机

If your compiler produces bytecode, your work isn't over once that's done. Since
there is no chip that speaks that bytecode, it's your job to translate. Again,
you have two options. You can write a little mini-compiler for each target
architecture that converts the bytecode to native code for that machine. You
still have to do work for <span name="shared">each</span> chip you support, but
this last stage is pretty simple and you get to reuse the rest of the compiler
pipeline across all of the machines you support. You're basically using your
bytecode as an intermediate representation.

<aside name="shared" class="bottom">

The basic principle here is that the farther down the pipeline you push the
architecture-specific work, the more of the earlier phases you can share across
architectures.

There is a tension, though. Many optimizations, like register allocation and
instruction selection, work best when they know the strengths and capabilities
of a specific chip. Figuring out which parts of your compiler can be shared and
which should be target-specific is an art.

</aside>

Or you can write a <span name="vm">**virtual machine**</span> (**VM**), a
program that emulates a hypothetical chip supporting your virtual architecture
at runtime. Running bytecode in a VM is slower than translating it to native
code ahead of time because every instruction must be simulated at runtime each
time it executes. In return, you get simplicity and portability. Implement your
VM in, say, C, and you can run your language on any platform that has a C
compiler. This is how the second interpreter we build in this book works.

<aside name="vm">

The term "virtual machine" also refers to a different kind of abstraction. A
**system virtual machine** emulates an entire hardware platform and operating
system in software. This is how you can play Windows games on your Linux
machine, and how cloud providers give customers the user experience of
controlling their own "server" without needing to physically allocate separate
computers for each user.

The kind of VMs we'll talk about in this book are **language virtual machines**
or **process virtual machines** if you want to be unambiguous.

</aside>

### 运行时

We have finally hammered the user's program into a form that we can execute. The
last step is running it. If we compiled it to machine code, we simply tell the
operating system to load the executable and off it goes. If we compiled it to
bytecode, we need to start up the VM and load the program into that.

In both cases, for all but the basest of low-level languages, we usually need
some services that our language provides while the program is running. For
example, if the language automatically manages memory, we need a garbage
collector going in order to reclaim unused bits. If our language supports
"instance of" tests so you can see what kind of object you have, then we need
some representation to keep track of the type of each object during execution.

All of this stuff is going at runtime, so it's called, appropriately, the
**runtime**. In a fully compiled language, the code implementing the runtime
gets inserted directly into the resulting executable. In, say, [Go][], each
compiled application has its own copy of Go's runtime directly embedded in it.
If the language is run inside an interpreter or VM, then the runtime lives
there. This is how most implementations of languages like Java, Python, and
JavaScript work.

[go]: https://golang.org/

## Shortcuts and Alternate Routes

That's the long path covering every possible phase you might implement. Many
languages do walk the entire route, but there are a few shortcuts and alternate
paths.

### 单趟编译器

Some simple compilers interleave parsing, analysis, and code generation so that
they produce output code directly in the parser, without ever allocating any
syntax trees or other IRs. These <span name="sdt">**single-pass
compilers**</span> restrict the design of the language. You have no intermediate
data structures to store global information about the program, and you don't
revisit any previously parsed part of the code. That means as soon as you see
some expression, you need to know enough to correctly compile it.

<aside name="sdt">

[**Syntax-directed translation**][pass] is a structured technique for building
these all-at-once compilers. You associate an *action* with each piece of the
grammar, usually one that generates output code. Then, whenever the parser
matches that chunk of syntax, it executes the action, building up the target
code one rule at a time.

[pass]: https://en.wikipedia.org/wiki/Syntax-directed_translation

</aside>

Pascal and C were designed around this limitation. At the time, memory was so
precious that a compiler might not even be able to hold an entire *source file*
in memory, much less the whole program. This is why Pascal's grammar requires
type declarations to appear first in a block. It's why in C you can't call a
function above the code that defines it unless you have an explicit forward
declaration that tells the compiler what it needs to know to generate code for a
call to the later function.

### 树遍历解释器

Some programming languages begin executing code right after parsing it to an AST
(with maybe a bit of static analysis applied). To run the program, the
interpreter traverses the syntax tree one branch and leaf at a time, evaluating
each node as it goes.

This implementation style is common for student projects and little languages,
but is not widely used for <span name="ruby">general-purpose</span> languages
since it tends to be slow. Some people use "interpreter" to mean only these
kinds of implementations, but others define that word more generally, so I'll
use the inarguably explicit **"tree-walk interpreter"** to refer to these. Our
first interpreter rolls this way.

<aside name="ruby">

A notable exception is early versions of Ruby, which were tree walkers. At 1.9,
the canonical implementation of Ruby switched from the original MRI (Matz's Ruby
Interpreter) to Koichi Sasada's YARV (Yet Another Ruby VM). YARV is a
bytecode virtual machine.

</aside>

### 转译器

<span name="gary">Writing</span> a complete back end for a language can be a lot
of work. If you have some existing generic IR to target, you could bolt your
front end onto that. Otherwise, it seems like you're stuck. But what if you
treated some other *source language* as if it were an intermediate
representation?

You write a front end for your language. Then, in the back end, instead of doing
all the work to *lower* the semantics to some primitive target language, you
produce a string of valid source code for some other language that's about as
high level as yours. Then, you use the existing compilation tools for *that*
language as your escape route off the mountain and down to something you can
execute.

They used to call this a **source-to-source compiler** or a **transcompiler**.
After the rise of languages that compile to JavaScript in order to run in the
browser, they've affected the hipster sobriquet **transpiler**.

<aside name="gary">

The first transcompiler, XLT86, translated 8080 assembly into 8086 assembly.
That might seem straightforward, but keep in mind the 8080 was an 8-bit chip and
the 8086 a 16-bit chip that could use each register as a pair of 8-bit ones.
XLT86 did data flow analysis to track register usage in the source program and
then efficiently map it to the register set of the 8086.

It was written by Gary Kildall, a tragic hero of computer science if there
ever was one. One of the first people to recognize the promise of
microcomputers, he created PL/M and CP/M, the first high-level language and OS
for them.

He was a sea captain, business owner, licensed pilot, and motorcyclist. A TV
host with the Kris Kristofferson-esque look sported by dashing bearded dudes in
the '80s. He took on Bill Gates and, like many, lost, before meeting his end in
a biker bar under mysterious circumstances. He died too young, but sure as hell
lived before he did.

</aside>

While the first transcompiler translated one assembly language to another,
today, most transpilers work on higher-level languages. After the viral spread
of UNIX to machines various and sundry, there began a long tradition of
compilers that produced C as their output language. C compilers were available
everywhere UNIX was and produced efficient code, so targeting C was a good way
to get your language running on a lot of architectures.

Web browsers are the "machines" of today, and their "machine code" is
JavaScript, so these days it seems [almost every language out there][js] has a
compiler that targets JS since that's the <span name="js">main</span> way to get
your code running in a browser.

[js]: https://github.com/jashkenas/coffeescript/wiki/list-of-languages-that-compile-to-js

<aside name="js">

JS used to be the *only* way to execute code in a browser. Thanks to
[WebAssembly][], compilers now have a second, lower-level language they can
target that runs on the web.

[webassembly]: https://github.com/webassembly/

</aside>

The front end -- scanner and parser -- of a transpiler looks like other
compilers. Then, if the source language is only a simple syntactic skin over the
target language, it may skip analysis entirely and go straight to outputting the
analogous syntax in the destination language.

If the two languages are more semantically different, you'll see more of the
typical phases of a full compiler including analysis and possibly even
optimization. Then, when it comes to code generation, instead of outputting some
binary language like machine code, you produce a string of grammatically correct
source (well, destination) code in the target language.

Either way, you then run that resulting code through the output language's
existing compilation pipeline, and you're good to go.

### 及时编译

This last one is less a shortcut and more a dangerous alpine scramble best
reserved for experts. The fastest way to execute code is by compiling it to
machine code, but you might not know what architecture your end user's machine
supports. What to do?

You can do the same thing that the HotSpot Java Virtual Machine (JVM),
Microsoft's Common Language Runtime (CLR), and most JavaScript interpreters do.
On the end user's machine, when the program is loaded -- either from source in
the case of JS, or platform-independent bytecode for the JVM and CLR -- you
compile it to native for the architecture their computer supports. Naturally
enough, this is called **just-in-time compilation**. Most hackers just say
"JIT", pronounced like it rhymes with "fit".

The most sophisticated JITs insert profiling hooks into the generated code to
see which regions are most performance critical and what kind of data is flowing
through them. Then, over time, they will automatically recompile those <span
name="hot">hot spots</span> with more advanced optimizations.

<aside name="hot">

This is, of course, exactly where the HotSpot JVM gets its name.

</aside>

## 编译器和解释器

Now that I've stuffed your head with a dictionary's worth of programming
language jargon, we can finally address a question that's plagued coders since
time immemorial: What's the difference between a compiler and an interpreter?

It turns out this is like asking the difference between a fruit and a vegetable.
That seems like a binary either-or choice, but actually "fruit" is a *botanical*
term and "vegetable" is *culinary*. One does not strictly imply the negation of
the other. There are fruits that aren't vegetables (apples) and vegetables that
aren't fruits (carrots), but also edible plants that are both fruits *and*
vegetables, like tomatoes.

<span name="veg"></span></span>

<img src="image/a-map-of-the-territory/plants.png" alt="A Venn diagram of edible plants" />

<aside name="veg">

Peanuts (which are not even nuts) and cereals like wheat are actually fruit, but
I got this drawing wrong. What can I say, I'm a software engineer, not a
botanist. I should probably erase the little peanut guy, but he's so cute that I
can't bear to.

Now *pine nuts*, on the other hand, are plant-based foods that are neither
fruits nor vegetables. At least as far as I can tell.

</aside>

So, back to languages:

* **Compiling** is an *implementation technique* that involves translating a
  source language to some other -- usually lower-level -- form. When you
  generate bytecode or machine code, you are compiling. When you transpile to
  another high-level language, you are compiling too.

* When we say a language implementation "is a **compiler**", we mean it
  translates source code to some other form but doesn't execute it. The user has
  to take the resulting output and run it themselves.

* Conversely, when we say an implementation "is an **interpreter**", we mean it
  takes in source code and executes it immediately. It runs programs "from
  source".

Like apples and oranges, some implementations are clearly compilers and *not*
interpreters. GCC and Clang take your C code and compile it to machine code. An
end user runs that executable directly and may never even know which tool was
used to compile it. So those are *compilers* for C.

In older versions of Matz's canonical implementation of Ruby, the user ran Ruby
from source. The implementation parsed it and executed it directly by traversing
the syntax tree. No other translation occurred, either internally or in any
user-visible form. So this was definitely an *interpreter* for Ruby.

But what of CPython? When you run your Python program using it, the code is
parsed and converted to an internal bytecode format, which is then executed
inside the VM. From the user's perspective, this is clearly an interpreter --
they run their program from source. But if you look under CPython's scaly skin,
you'll see that there is definitely some compiling going on.

The answer is that it is <span name="go">both</span>. CPython *is* an
interpreter, and it *has* a compiler. In practice, most scripting languages work
this way, as you can see:

<aside name="go">

The [Go tool][go] is even more of a horticultural curiosity. If you run `go
build`, it compiles your Go source code to machine code and stops. If you type
`go run`, it does that, then immediately executes the generated executable.

So `go` *is* a compiler (you can use it as a tool to compile code without
running it), *is* an interpreter (you can invoke it to immediately run a program
from source), and also *has* a compiler (when you use it as an interpreter, it
is still compiling internally).

[go tool]: https://golang.org/cmd/go/

</aside>

<img src="image/a-map-of-the-territory/venn.png" alt="A Venn diagram of compilers and interpreters" />

That overlapping region in the center is where our second interpreter lives too,
since it internally compiles to bytecode. So while this book is nominally about
interpreters, we'll cover some compilation too.

## 我们的旅程

That's a lot to take in all at once. Don't worry. This isn't the chapter where
you're expected to *understand* all of these pieces and parts. I just want you
to know that they are out there and roughly how they fit together.

This map should serve you well as you explore the territory beyond the guided
path we take in this book. I want to leave you yearning to strike out on your
own and wander all over that mountain.

But, for now, it's time for our own journey to begin. Tighten your bootlaces,
cinch up your pack, and come along. From <span name="here">here</span> on out,
all you need to focus on is the path in front of you.

<aside name="here">

Henceforth, I promise to tone down the whole mountain metaphor thing.

</aside>

<div class="challenges">

## 挑战

1. Pick an open source implementation of a language you like. Download the
   source code and poke around in it. Try to find the code that implements the
   scanner and parser. Are they handwritten, or generated using tools like
   Lex and Yacc? (`.l` or `.y` files usually imply the latter.)

1. Just-in-time compilation tends to be the fastest way to implement dynamically
   typed languages, but not all of them use it. What reasons are there to *not*
   JIT?

1. Most Lisp implementations that compile to C also contain an interpreter that
   lets them execute Lisp code on the fly as well. Why?

</div>
