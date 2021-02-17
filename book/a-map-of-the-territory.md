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

如果你制作的编译器产生的是字节码的话，那么你的工作还没有结束呢。因为并没有一种芯片能够执行你的编译器产生的字节码，这些字节码需要你自己去翻译。所以这里有两种选择。第一种就是你可以为每一种目标机器的体系结构写一个迷你编译器，将字节码转换成目标机器的机器代码。当然这样的话，你需要为你想要支持的<span name="shared">每一种</span>芯片都编写一个迷你编译器。当然你写的编译器的其他部分（从词法分析到编译成字节码）可以在所有的机器上面复用。这样，你的字节码相当于你写的整个编译器的中间表示。

<aside name="shared" class="bottom">

这里的基本原理就是：在整个编译器的流水线上，如果你将体系结构相关的工作推的越往后，那么就有更多的流水线上前面的阶段可以在不同的体系结构上共享。

有一点需要注意一下。很多的优化，例如寄存器分配和指令选择，只有在了解目标机器的指令集的情况下，才能发挥出最大的威力。所以，编译器中哪一部分可以在体系结构间共享，哪一部分应该针对特定的体系结构来编写，不好权衡啊，是一门艺术。

</aside>

第二种选择就是你可以写一个<span name="vm">**虚拟机**</span>（**VM**）。虚拟机是这样一种程序，它可以在运行时（runtime）模拟执行你所假想中的芯片所支持的虚拟指令集（也就是字节码）。使用虚拟机运行字节码当然要比将字节码翻译成机器语言再执行要慢，因为我们每次执行编译成字节码的程序时，都需要在运行时去模拟执行字节码程序中的每一条字节码指令。当然这样做的回报是我们获得了编译器编写的简单性以及便携性。例如，我们可以使用C语言编写虚拟机，这样只要这个平台支持C语言（所有体系结构都有C语言的编译器），就可以运行我们制作的编程语言所写的代码。本书使用的就是第二种选择，也就是写一个虚拟机。

<aside name="vm">

“虚拟机”这个术语其实指的是一种不一样的抽象。**系统虚拟机**会在软件中模拟执行整个硬件平台的指令集，自然也就能模拟执行这个硬件平台上的操作系统了（例如qemu，vmware这样的虚拟机）。这就是为什么你能在Linux上面运行Windows系统。也是云服务商可以为你提供属于你自己的服务器（无需提供给你真实的机器，也就是容器技术）的原因。

本书所讨论的虚拟机是**编程语言虚拟机（language virtual machines）**或者叫做**处理虚拟机（process virtual machines）**，这样或许就没有歧义了。

</aside>

### 运行时

我们终于可以把用户写的Lox程序转换成一种可以执行的形式了。最后一步就是运行这个*可以执行的形式*。如果这个可以执行的形式是机器代码，那么我们可以让操作系统直接加载这个可执行程序（编译成机器语言，然后通过链接操作，操作系统就可以加载了），然后就运行起来了。如果这个可以执行的形式是字节码，我们就需要启动我们写的虚拟机，然后把字节码程序加载到里面去。

在这两种情况下，除了最底层的机器语言，对于其他可执行的形式，我们制作的语言都需要在用户编写的Lox程序运行的时候提供某些服务。例如，如果语言需要自动管理内存，我们需要一个垃圾收集器来回收不再使用的内存。如果我们的语言需要支持类似于“instance of”这样的操作（其实就是反射），我们需要知道对象是哪种类型。也就是说，在程序执行的过程中，我们需要某些表示方式来跟踪每一个对象的类型。

所有这些事情都是在运行时发生的，所以我们把这些事情起一个名字**运行时（runtime）**。对于一个编译成机器码的编程语言来说，编译器会把运行时直接插入到可执行程序中。例如[Go][]语言，每一个编译好的程序，都有一份Go的运行时嵌入在里面。如果语言是运行在解释器或者虚拟机上的话，那么运行时天生就有了。这也是大部分像Java，Python和JavaScript这样的语言所使用的实现方式。

[go]: https://golang.org/

## 捷径和其他可选择的路径

实现编译器的每一个可能的阶段所组成的路径是很长的。很多语言都把这条长长的路径完全走了一遍。但也有捷径和其他可以选择的路径存在。

### 单趟编译器

一些简单的编译器将解析（parsing），静态分析（analysis）和代码生成糅合在了一起。所谓糅合在一起就是直接在解析器（parser）中产生要输出的代码，既没有生成任何语法树也没有生成任何IR。这些<span name="sdt">**单趟编译器（single-pass compilers）**</span>制约了语言的设计。因为没有任何中间数据结构可以用来存储程序的全局信息，我们也没有办法再去访问之前解析过的代码（毕竟没有留下AST这样的数据结构）。这就意味着当我们碰到一些表达式，我们必须掌握足够的知识才能正确的编译这些表达式。

<aside name="sdt">

[**语法制导翻译（Syntax-directed translation）**][pass]是一种用来构建单趟编译器的结构化技术。我们会将某一个*动作（action）*和语法的一个片段相关联，这个动作可以直接产生输出的代码。也就是说，每当解析器遇到语法的一个片段时，就会执行相应的动作，一次性产生这个语法片段对应的目标代码。

[pass]: https://en.wikipedia.org/wiki/Syntax-directed_translation

</aside>

Pascal和C最开始就采用了语法制导翻译这种方法。在产生C和Pascal的那个时代，内存太小了，以至于编译器都无法将整个*源代码文件*放到内存里，更别说将整个程序放进内存里了。这就是为什么Pascal的语法要求类型的声明必须在块（block）的最开始的地方。这也就是为什么在C语言中，你无法在一个位置调用在这个位置后面的地方定义的函数的原因。所以我们在写C语言代码，需要调用某个函数时，必须在调用这个函数的位置的前面，至少要有这个函数的声明或者定义，才能调用这个函数。也就是说，因为无法将一个文件都放入内存，所以可能无法解析调用位置后面的代码，所以函数的声明必须放在调用位置的前面，产生的汇编代码才知道这个函数是声明过的。

### 树遍历解释器

某些编程语言会在将代码解析成抽象语法树（AST）之后，直接执行代码，执行过程中可能会做一点静态分析。为了运行程序，解释器会遍历语法树，每次遍历一个树的分支或者叶子结点，在遍历节点的过程中对这个节点进行求值。

这种实现方式在学生的玩具项目或者小小语言中很常见，但对于<span name="ruby">通用编程语言</span>而言，很少使用，因为运行速度会很慢。某些人眼里的“解释器”其实指的就是树遍历解释器这种实现方式。但其他人会认为“解释器”一词有着更加广泛的含义。所以对于这种遍历树的解释器实现方式，我会给它一个明确的名字：**“树遍历解释器”**。我们实现的第一个解释器用的就是这种实现方式。

<aside name="ruby">

在通用编程语言中有一个著名的例外，就是Ruby的早期实现版本，采用的是遍历树的实现方式。在Ruby 1.9这个版本，Ruby的官方实现从MRI（Matz's Ruby Interpreter，树遍历解释器）转到了Koichi Sasada's YARV (Yet Another Ruby VM)。YARV是一个字节码虚拟机。

</aside>

### 转译器

对于一门语言而言，<span name="gary">编写</span>一个完整的后端需要大量的工作。如果你已经选择了一些IR作为目标代码，那么你只需要写一个将语言编译成IR的前端就可以了。否则的话，貌似我们就被卡住了，不知道该怎么办了。那如果你将某些其他的*源语言（也就是编程语言）*作为中间表示呢（例如，将C语言作为目标代码）？

你可以为你的编程语言写一个前端。然后，在后端，你并不需要产生原始的目标机器的语言，你可以产生的是其他编程语言的源代码，这个编程语言和你自己的编程语言同样是高级语言（例如将Lox写的代码编译成C语言代码）。然后你就可以使用目标语言（是一门高级语言）的编译工具了，例如将Lox编写的代码编译成C语言代码，然后使用GCC执行。这样我们节省了很多工作量，不需要自己将Lox写的代码编译成低级语言了（例如汇编）。

这种编译器他们通常称之为**源到源编译器**或者叫做**转译器**。很多编程语言为了能够在浏览器里面运行，而编写了编译到JavaScript的编译器。很多这种编译器都自称自己是**转译器**，所以转译器这个名字也就流行了起来。

<aside name="gary">

历史上第一个转译器是XLT86，可以将8080汇编转译成8086汇编。可能这个过程看起来很直接，但别忘了8080是8位的芯片，而8086是16位的芯片（可以将每个寄存器当作一对儿8位寄存器来使用）。XLT86做了数据流分析来跟踪寄存器在源程序中的使用，这样就可以将这些8080的寄存器的操作映射到8086的寄存器的操作。

XLT86是由加里·吉尔达尔所编写，如果说计算机科学史上存在悲剧英雄的话，那么他就是其中之一。他是首先看到微型计算机前景的人之一，他创造了PL/M和CP/M。PL/M是第一个高级语言，而CP/M是一个操作系统。

他是一名船长，一个企业家，一个拥有飞行执照的飞行员，一个摩托车手。他还是一个电视台主持人，拥有着克里斯·克里斯托弗森的外表，在80年代留着短发和胡须。他挑战过比尔盖茨，和所有其他人一样，也失败了。后来神秘的死在了一个自行车吧，他去世时太年轻了。

</aside>

虽然第一个转译器是将某一种汇编语言转换成另一种汇编语言，但在今天，大部分的转译器是将一门高级语言转译成另一门高级语言。在类UNIX系统病毒般的扩散之后，很多编译器都编写了转译器来转译成C语言（因为UNIX是C语言写的）。只要安装UNIX，就会有C语言的编译器同时存在，所以只要把C语言作为目标语言就可以把你的语言运行在任意一种体系结构上了。

而由于浏览器就是当今计算机的“机器”（机器上面的“机器语言”是JavaScript），所以在今天，[几乎所有编程语言][js]都有一个能够转译成JS代码的转译器。因为这是能够将编程语言运行在浏览器上的<span name="js">主要</span>方法。

[js]: https://github.com/jashkenas/coffeescript/wiki/list-of-languages-that-compile-to-js

<aside name="js">

JS曾经是*唯一*一种能够在浏览器上运行的编程语言。而现在我们有了第二种选择，那就是[WebAssembly][]，这是一种低级语言，也可以运行在浏览器上面。

[webassembly]: https://github.com/webassembly/

</aside>

转译器的前端——扫描器和解析器和其他编译器中的前端是一样的。所以，如果源语言仅仅是目标语言的一层语法皮肤的话（例如ES6是ES5的语法皮肤），我们就可以跳过静态分析这一步，然后直接在目标语言中输出类似的语法。

如果源语言和目标语言的语法相差很大，我们可能会在转译器中发现更多的编译器中才会有的阶段，例如静态分析，甚至还可能有优化。当转译器来到代码生成的阶段，转译器会生成在语法上正确的目标语言的代码，而不是生成机器代码。

然后我们就可以使用目标语言的编译器来运行转译器输出的代码了。

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
