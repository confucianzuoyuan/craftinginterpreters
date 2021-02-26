> 如果你发现自己几乎把所有时间都花在了理论上面，那么把你的注意力转向实践吧，这会提升你的理论水平。如果你发现自己几乎把所有的时间都花在了实践上，那么把你的注意力转向理论吧，这会提升你的实践水平。
>
> <cite>高德纳</cite>

我们已经完成了一个Lox的解释器jlox，那为什么这本书还没有结束呢？部分原因是因为jlox的实现严重的依赖了<span name="metal">JVM虚拟机</span>。如果我们想要从根儿上透彻理解解释器的工作原理，我们就需要一点一滴的构建一个解释器出来，而不是依赖别的工具（例如JVM）。

<aside name="metal">

当然了，我们的第二个解释器依赖于C标准库，来完成像内存分配这样的基础工作。C编译器把我们从底层的机器语言中解放了出来（程序最后都会转换成机器语言执行）。而机器语言又是由芯片上的编程语言实现的（例如Verilog）。而C语言的运行时依赖于操作系统进行内存分配（可以参考《深入理解计算机系统》来学习虚拟内存的机制）。但我们必须*停下来*，也就是说我们向底层深挖只能停留在C语言这一步了，要不然你整个书架都放不下这本书了。

</aside>

一个更加基本的原因是，jlox的运行速度实在是太慢了。树遍历解释器对于某些高层的声明式的语言（例如SQL）来说足够了，但对于一门通用的命令式的编程语言来说——即使是像Lox这样的脚本语言，也是完全不够用的。例如下面的这段小脚本程序：

```lox
fun fib(n) {
  if (n < 2) return n;
  return fib(n - 1) + fib(n - 2); // [fib]
}

var before = clock();
print fib(40);
var after = clock();
print after - before;
```

<aside name="fib">

上面的程序是一种非常低效的计算斐波那契数列的方法。我们的目标是用上面的程序来测试*解释器*的运行速度，而不是写一个高效的斐波那契数列的计算程序。一个做了很多事情的很慢的程序——可能毫无意义——但却是解释器运行速度的一个很好的测试用例。

</aside>

在我的笔记本电脑上，使用jlox来运行这段程序，需要72秒。而同样逻辑的C程序，只需要0.5秒。我们构建的动态类型脚本语言从来没想过和手动管理内存的静态类型语言C的运行速度一样快。但是也不能慢出*两个数量级*去啊。

我们可以使用性能分析器（profiler）来分析我们写的jlox解释器，然后开始调优，比如找出热点（频繁运行的代码）代码进行优化，但即使这样，我们也走不远。因为执行模型——遍历抽象语法树——从根儿上就是个错误的设计。我们在这个模型之上进行优化，无论再怎么优化，性能都不会很好。就好比无论如何，我们也不可能将一台轿车优化成一辆战斗机。

我们需要重新思考一下核心模型。本章将介绍一个新执行模型以及字节码，然后开始编写我们的新解释器：clox。

## 字节码？

在工程中，很少有选择是不做妥协（trade-off）的。想要理解我们为什么要选择字节码虚拟机这种实现方式，让我们来看一下其他选项。

### 为什么不采用遍历抽象语法树的方式？

我们之前写的解释器已经做了这样的事情：

*   首先，我们已经采用遍历抽象语法树的方式写了一个解释器。所以到此为止吧，别再用这种方法再来一遍了。不想再来一遍的最主要的原因是，这种风格的解释器**实现起来非常简单**。代码的运行时表示可以直接的映射到语法。从解析器（parser）获得运行时需要的数据结构几乎不费任何力气。

*   其实，我们之前写的解释器是**便携的**。我们使用了Java来开发，所以可以运行在Java支持的任意平台上。而我们可以用同样的手段来用C实现一个解释器。然后在任意平台上运行我们写的程序（C语言也可以跨平台）。

上面两点都是之前写的解释器的优点（容易实现、跨平台）。但另一方面，**这个解释器对内存的运用是低效的。**每一个语法片段都会转换成抽象语法树（AST）节点。一个很迷你的Lox表达式，例如`1 + 2`，都会被转换成一堆Java对象，这些对象之间还有一堆指针互相指向，就像下面这样：

<span name="header"></span>

<aside name="header">

"(header)"部分是Java虚拟机针对每一个对象记录的一些信息，这样方便做内存管理和跟踪对象的类型。这些也占空间啊！

</aside>

<img src="image/chunks-of-bytecode/ast.png" alt="The tree of Java objects created to represent '1 + 2'." />

上图中的每一个指针都会给对象再附加32位或者64位的存储空间。更糟糕的是，堆里面的数据是一些松散链接的对象，这对于<span name="locality">*空间的局部性*</span>是非常不好的消息。

<aside name="locality">

有关数据的局部性，我在我写的第一本书《游戏编程模式》中，花了[一整章][gpp locality]来写这个话题。如果想深入了解一下，可以参考。

[gpp locality]: http://gameprogrammingpatterns.com/data-locality.html

</aside>

现代CPU处理数据的速度要比CPU从RAM中取数据的速度快的多得多。为了补救这一点，CPU中都会有多级缓存。如果内存中的一些数据已经在缓存中了，那么这些数据会被更快的加载到CPU中（比从内存中取快）。而且至少要快*100倍*。

那么数据是如何进入缓存的？机器采用一种启发式的方法（就是直觉上能想出来的）来把这些事情搞定。这个启发式方法非常简单。当CPU需要读取RAM中的某一条数据时，CPU会把这条数据以及这条数据在内存中附近的数据（通常是内存中包含这条数据的一段数据）都读取到缓存中。

如果我们的程序接下来需要请求的数据是上一段话提到的那条数据附近的数据，由于那条数据附近的数据都在缓存中，我们的CPU就会像工厂里加满油的传送带一样，开足马力工作。我们*确实*很希望能够利用这点特性（空间局部性）。为了高效的使用缓存，我们在内存中表示代码的方式必须非常紧密而且有序，方便利用空间局部性。

现在让我们看一下上面图中的那个树形结构。那些树形结构中的子类可以存储在JVM堆中的<span name="anywhere">任何一个地方</span>。遍历树时走的每一步都会跟着孩子节点对象的引用走。而孩子节点是很可能存储在缓存之外的（因为不在父节点的附近），这样就会使CPU必须在RAM中寻址，然后从RAM中再加载一块数据到CPU中。这些树中的节点，由于在内存中的位置并不挨着，因为节点的连接是通过引用（指针）相连的，所以这些节点你进入到缓存中，就把别的节点挤出去了，这样来回互相挤，会有很多缓存和内存之间的IO，效率很低下。

<aside name="anywhere">

即使在解析器（parser）第一次产生这些树的节点时，这些节点在内存中碰巧挨在了一起（按顺序存储，像数组一样），经过好几轮的垃圾收集——这会引起对象在内存中的移动——这些节点也不会存放在一起了。

</aside>

还有就是我们在遍历抽象语法树时，大量的使用了访问者模式，这些都不利于对空间的局部性的使用。所以空间的局部性这一存储结构的优良特性，值得我们选择一种更好的代码表示（也就是字节码）。

### 为什么不直接编译到机器码？

如果你*真的*想让你写的代码运行的很快，那么你需要把所有的中间层都去掉。而是直接生成机器码。*“机器码”*。念起来就很快，有没有！

直接编译到芯片支持的指令集是那些运行最快的语言做的事情。编译到机器码大概是最快的一种执行方式了，当然可能比不上很久以前工程师们<span name="hand">手写</span>机器语言程序的时候写出来的程序执行的快。

<aside name="hand">

是的，他们真的是手写机器码。在打孔卡上手写机器码。他们或许会用*拳头*在纸带上打孔。

</aside>

如果你从来没写过任何机器语言，或者可读性更加好一些的汇编语言，我来给你大概介绍一下吧。机器码是一系列操作的非常紧密的序列，是直接编码成二进制的。每一条指令占用一个到多个字节的长度，底层到令人麻木（一堆0101）。“将一个值从这个地址移动到这个寄存器。”“将这两个寄存器中的整数相加。”就是类似于这些东西。

CPU会一条一条的执行指令，也就是从内存中读取指令，然后对指令进行解码并执行每一条指令。没有像AST（抽象语法树）这样的树结构，控制流结构的实现是从代码中的一个点直接跳转到另一点。没有中间层，没有不必要的开销，没有不必要的代码的跳过或者指针的操作。

运行速度快如闪电，但获得这样的高性能却要付出代价。首先，编译成机器码并不容易。当今大多数被广泛使用的芯片都有着数十年来积累的大量指令，芯片架构如拜占庭式建筑般复杂。他们需要复杂的寄存器分配算法，流水线技术以及指令的调度。

而且，如果将代码编译成机器码，那我们显然就已经放弃了<span name ="back">可移植性</span>。花几年的时间掌握一些复杂的芯片架构，你可能只能把代码编译成某一种芯片指令集的能力。如果想让你的语言运行在所有的芯片架构上，我们需要把这些芯片的指令集都学习一遍，然后为每一个芯片架构写一个编译器的后端。

<aside name="back">

当然情况也不是那么糟糕。一个拥有良好架构的编译器允许你共享编译器的前端，以及大部分的中间层优化。这些都可以在你需要支持的不同体系结构之间共享。所以主要工作就是代码生成，以及有关指令选择方面的一些细节。你可能需要对每个指令集都编写一下这些内容。

[LLVM][]项目使得你连代码生成和指令选择的程序都不需要编写了。如果你的编译器输出的是LLVM提供的中间表示语言，LLVM会直接将你编译好的中间表示编译成某一个体系结构的机器码。

[llvm]: https://llvm.org/

</aside>

### 什么是字节码？

想一想如何解决上面提到的两个问题？一方面，树遍历解释器实现起来简单，可移植性强，但运行的很慢。另一方面，直接编译到机器码实现起来很复杂，而且严重平台相关，可移植性非常差，但运行的很快。而字节码正好处于两者之间。它保留了树遍历解释器的可移植性——我们不需要在本书写汇编语言。不过它也牺牲了实现上面的简单性，为了获取性能的提升，这是值得的。当然性能再好，也比不上原生机器码。

从结构上看，字节码和机器码非常相似。字节码是紧密的，线性的二进制指令的序列。这降低了开销，并且高速缓存友好。当然，字节码比起任何真正的芯片指令集都要简单的多，也就是说，是比汇编指令集更加高层次的指令集。（在很多字节码的表示形式中，每一条指令只占用一个字节的长度，所以叫“字节码”）。

假设你在编写一个源语言的编译器，直接编译到机器码。而你正好有权力来设计你要编译到的机器码的体系结构。你会怎么设计呢？你肯定会设计出一种最容易生成的机器码。字节码就是这样的设计。字节码是一种理想的指令集，让你的编译器编写工作更加轻松。

理想的体系结构所存在的问题是什么呢？问题就是它是现实中不存在的体系结构。我们需要编写*模拟器（emulator）*来解决这个问题。模拟器是一个仿真芯片，也就是说它是一个软件。模拟器会解释执行字节码，也就是每次执行一条字节码。你也可以把模拟器叫做**虚拟机（virtual machine）**。

模拟器这一层增加了一些<span name="p-code">开销</span>，这个中间层是字节码比原生机器码执行起来更加慢的关键原因。作为回报，字节码给了我们强大的可移植性。使用C语言来编写我们的虚拟机，可以让我们的虚拟机（模拟器）运行在所有的硬件上面。因为几乎所有的硬件都有C语言的编译器。

<aside name="p-code">

尼古拉斯·沃斯为Pascal语言所开发的字节码形式[p-code][]，是最早期的字节码之一。你可以想象一下15MHz频率的PDP-11芯片是无法负担模拟执行一个虚拟机的开销的。但在那个时候，计算机正处于爆炸发展的时期，每天都有新的体系结构和指令集冒出来。所以能够在新的芯片上执行程序比去写编译器压榨每种新的芯片的极限性能更加有价值。这也就是"p"在"p-code"中的意思并不是"Pascal"，而是“可移植的（portable）”的意思的原因。

[p-code]: https://en.wikipedia.org/wiki/P-code_machine

</aside>

而这就是我们的新解释器，clox，将要走的路径。我们将会跟随Python，Ruby，Lua，OCaml，Erlang等语言的主流实现的脚步。在很多方面，我们的虚拟机的设计和之前的树遍历解释器的实现有着平行和对应的关系。

<img src="image/chunks-of-bytecode/phases.png" alt="Phases of the two
implementations. jlox is Parser to Syntax Trees to Interpreter. clox is Compiler
to Bytecode to Virtual Machine." />

当然，我们不会严格的按顺序实现每一个阶段。就像我们的第一个解释器，我们会每次实现一个语言的特性。在本章，我们先来搭一个写clox的脚手架，以及创建一个数据结构用来存储和表示一块（chunk）字节码。

## 开始吧！

我们从`main()`函数开始吧！<span name="ready">打开</span>你的编辑器然后开始敲代码吧！

<aside name="ready">

现在是舒展肌肉摩拳擦掌的时候了，来点儿蒙太奇音乐也挺好。

</aside>

^code main-c

从上面这个小小的种子开始，我们将构建一个完整的虚拟机。由于C语言为我们提供的功能太少了，所以我们先得加点儿土。下面的头文件里就是我们要添加的：

^code common-h

在实现解释器的过程中，我们需要很多的类型和常量，这个头文件就是存放它们的好地方。现在，我们要存放的是可敬的`NULL`，`size_t`，以及C99标准引入的美妙的布尔类型`bool`，还有定长的整型类型——`uint8_t`和它的朋友们。

## 指令的块（chunk）

接下来，我们需要一个模块来定义我们的代码表示形式。我是用“块（chunk）”这个词来表示字节码序列，所以让我们给这个模块起一个名字吧。

^code chunk-h

我们的字节码，每一条指令占用一个字节，我们把字节码的指令叫做**操作码（operation code）**，经常被缩写为**opcode**。操作码的数字代表了我们要执行的指令——相加，相减，在符号表中查询变量，等等。我们在下面的代码里定义操作码：

^code op-enum (1 before, 2 after)

我们先从一条指令`OP_RETURN`开始吧。当我们完成整个虚拟机的编写之后，这条指令的意思是“从当前函数返回”。我承认这条指令现在还没什么用，但我们总得从某个地方开始啊，而这条指令是一条特别简单的指令，所以很适合从这里开始。

### 存储指令的动态数组

字节码是一个指令序列。所以，我们需要将这些指令连同其他的一些数据保存下来。让我们来创建一个数据结构来存储这些信息。

^code chunk-struct (1 before, 2 after)

现在，这个数据结构只是一个字节数组的简单包装而已。由于我们并不知道程序编译成字节码以后，有多少条字节码，也就是说我们并不知道存放这些字节码的数组的大小，所以我们需要数组是可以动态变化的。动态数组是我最喜欢的数据结构之一。听起来就像在说香草是我最喜欢的冰淇淋<span name ="flavor">口味</span>一样，但是，请听我说。动态数组提供：

<aside name="flavor">

山核桃黄油味儿实际上是我的最爱。

</aside>

* 高速缓存友好，且紧密的存储方式。

* 通过下标查找元素，只需要常数时间复杂度。

* 在数组末尾添加元素，只需要常数时间复杂度。

其实我们已经在jlox中使用过动态数组了，只不过在Java中，动态数组藏在了`ArrayList`的下面，换句话说，Java的`ArrayList`的底层实现就是动态数组。而现在，由于C语言里并没有内置动态数组特性，所以我们需要自己造一个。如果你不了解动态数组，那么其实它的思想非常简单。除了数组本身，我们还需要维护两个数：我们动态分配的数组能容纳多少个元素（“容量，capacity”），以及数组里面已经存放了多少个元素（“数量，count”）。

^code count-and-capacity (1 before, 2 after)

当我们往数组里面添加一个元素时，如果数量（count）小于容量（capacity），说明数组中还有空间可以存放新的元素。然后我们就可以存放新的元素，然后将数量（count）加一。

<img src="image/chunks-of-bytecode/insert.png" alt="Storing an element in an
array that has enough capacity." />

如果数组中已经没有空闲的容量来存放新元素，那么情况会稍微复杂一点：

<img src="image/chunks-of-bytecode/grow.png" alt="Growing the dynamic array
before storing an element." class="wide" />

1.  首先，<span name="amortized">分配</span>一个更大容量的新数组。
2.  然后将旧数组中的所有元素都拷贝到新的数组中。
3.  更新容量（`capacity`）字段，因为数组的容量变了。
4.  删除旧的数组。
5.  更新`code`字段，指向新的数组。
6.  将新元素存放在新的数组里面，因为新的数组能放下新元素了。
7.  更新`count`字段。

<aside name="amortized">

将旧数组中的所有元素都拷贝到新的更大的数组中，然后再添加新的元素，使得整个过程的时间复杂度是*O(n)*，而不是我上面所说的*O(1)*。实际上，你只有在某些情况下添加新元素的时候（旧数组已经满的情况下），才会需要做拷贝操作。大部分情况下，数组里面是有空间来存放新元素的，所以并不需要拷贝。

想要理解上面所说的是如何工作的，或者说计算添加一个元素的真正的时间复杂度时，需要研究一下[**均摊分析（amortized analysis）**](https://en.wikipedia.org/wiki/Amortized_analysis)。均摊分析向我们展示了，当我们按照当前数组的倍数来扩大当前数组时，我们将所有的添加新元素的操作所花费的时间均摊一下，每个添加新元素的操作的时间复杂度是*O(1)*。

</aside>

我们的结构体已经写好了，现在让我们来实现一些函数，能够来操作动态数组的结构体。C语言没有构造器，所以我们需要声明一个函数来初始化一个新的块（chunk）。

^code init-chunk-h (1 before, 2 after)

像下面这样实现就好：

^code chunk-c

动态数组最开始完全是空的。我们甚至都没有分配一个数组出来呢。想要在数组末尾添加一个元素，我们需要一个新的函数。

^code write-chunk-h (1 before, 2 after)

这就是有趣的事情发生的地方。

^code write-chunk

我们需要做的第一件事情就是看一下当前的数组是否有可以容纳新元素的空间，也就是容量够不够。如果没空间了，那我们首先要让数组变大，这样就有空间了。（我们会在往数组里添加第一个元素的时候就碰到这个问题，因为这个时候数组是`NULL`，容量`capacity`是0。）

想要让数组变大，首先要指定新数组的容量，然后将数组变大到新的容量。这些都是针对内存的底层操作，所以需要新建一个模块来定义它们。

^code chunk-c-include-memory (1 before, 2 after)

这足以让我们开始了：

^code memory-h

这个宏（macro）根据当前的数组容量计算出了一个新的数组容量的大小。为了达到我们想要的性能，最重要的部分在于数组的*扩展*需要基于旧数组的大小。我们的数组变大的因子是2，是一个非常典型的因子。1.5&times; 是另一个常见的选择。

我们还需要处理当前容量为0的情况。在这种情况下，我们直接分配一个八个元素容量的数组，而不是一个元素的大小的数组。这样做会<span name="profile">避免</span>处理一些额外的内存，当数组很小的时候会有点麻烦。当然如果字节码的数量特别少，只有一两条，可能会浪费一点内存。

<aside name="profile">

在本书中，我随意选择了8这个数字。大部分动态数组的实现都有一个类似于8这样的最小阈值。如果想要为真实世界的编程语言选择一个动态数组的最小阈值，需要在动态数组扩张的性能和空间的浪费之间做一个权衡，看阈值选择多大性能最好，又不会太浪费空间。

</aside>

一旦我们知道了想要的数组容量，我们就可以使用`GROW_ARRAY()`方法将数组扩大到那个数组容量。

^code grow-array (2 before, 2 after)

上面的宏实际上是对`reallocate()`方法的包装，真正工作的函数是`reallocate()`方法。宏要做的事情就是确定数组中元素的类型所占用内存的大小（例如，int占用4字节）。然后对结果类型`void*`做强制类型转换，转成指向正确类型的指针。

`reallocate()`方法是我们在clox中用来做所有动态内存管理的唯一方法——分配内存，释放内存，以及改变一个已有内存的大小。通过一个方法完成所有的内存操作对于我们后面程序的编写是非常重要的，特别是当我们编写垃圾收集器时。因为垃圾收集器需要跟踪当前🈶️多少内存已经被使用了。

传入方法的两个有关大小的参数，用来控制到底做哪一种操作：

<table>
  <thead>
    <tr>
      <td>oldSize</td>
      <td>newSize</td>
      <td>Operation</td>
    </tr>
  </thead>
  <tr>
    <td>0</td>
    <td>Non&#8209;zero</td>
    <td>Allocate new block.</td>
  </tr>
  <tr>
    <td>Non&#8209;zero</td>
    <td>0</td>
    <td>Free allocation.</td>
  </tr>
  <tr>
    <td>Non&#8209;zero</td>
    <td>Smaller&nbsp;than&nbsp;<code>oldSize</code></td>
    <td>Shrink existing allocation.</td>
  </tr>
  <tr>
    <td>Non&#8209;zero</td>
    <td>Larger&nbsp;than&nbsp;<code>oldSize</code></td>
    <td>Grow existing allocation.</td>
  </tr>
</table>

这看起来需要处理很多边界情况，但下面就是我们的实现（其实并不复杂）：

^code memory-c

当`newSize`为0时，我们将会调用`free()`方法来释放内存。另外，我们也依赖了C标准库里的`realloc()`方法。这个方法将支持内存管理处理释放的其他方面的功能。当`oldSize`为0时，`realloc()`操作将等同于调用`malloc()`。

最有意思的情况就是当`oldSize`和`newSize`都不为0的时候。这意味着我们要用`realloc()`方法来改变之前分配的内存的大小。如果新的内存大小小于之前分配的内存大小，那么这个方法仅仅是<span name="shrink">更新</span>一下内存块的大小，然后返回内存块的指针（指向内存块的指针和原来一样）就可以了。如果新的内存尺寸比原来的更大，那么我们就会扩大已有内存块的大小。

只有当原来内存块的后面的内存没有在使用时，直接扩大内存块的操作才能够成功。如果没有足够的空间来直接扩大内存块，那么`realloc()`方法将会分配一个*新的*符合尺寸大小的内存块，然后将旧内存块中的数据拷贝过来，并将旧内存块释放，最后返回一个指向新内存块的指针。记住，这就是我们想要的动态数组的行为。

由于计算机的内存是有限的，它并不是计算机科学理论中完美的数学抽象（内存无限），所以当内存不足时，分配内存的操作可能会失败，也就是`realloc()`方法可能会返回`NULL`。我们需要处理一下这种情况。

^code out-of-memory (1 before, 1 after)

如果无法获取足够的内存，我们的虚拟机将无法做任何有用的事情。但现在，我们至少可以发现内存不足的情况然后终止虚拟机进程，而不是直接返回一个`NULL`指针，然后任由事情失控。

<aside name="shrink">

由于我们传入方法的参数仅仅是一个裸指针，这个指针指向了内存块的第一个字节。那“更新”内存块的大小意味着什么呢？在底层，内存分配器将会为每一个分配出来的内存块维护一个额外的簿记信息，包括内存块的尺寸大小。

给定一个指向之前分配的内存块的指针，我们会找到这个内存块的簿记信息，而这对于干净的释放这块内存来讲是非常必要的。这个尺寸大小的元数据就是`realloc()`方法将要更新的信息。

很多`malloc()`的实现都会在返回指向分配好的内存的地址前，保存已分配内存的尺寸大小。

</aside>

我们可以创建新的块（chunk），然后将指令写进去。这就完了吗？当然没有。我们现在在使用C语言，记住，我们需要自己管理内存。这意味着我们需要自己释放内存。

^code free-chunk-h (1 before, 1 after)

实现如下：

^code free-chunk

我们将所有内存释放，然后调用`initChunk()`方法来将所有块中的字段都置为空，也就是恢复到初始状态。为了释放内存，我们需要再写一个宏。

^code free-array (3 before, 2 after)

就像`GROW_ARRAY()`一样，上面这个宏也是对`reallocate()`方法的包装。当向这个宏传入的新的尺寸大小的参数是0时，就会释放掉内存。我明白，这些都是一堆烦人的底层操作。别担心，我们后面会大量的使用这些宏，然后在一个更高的层次上面编程。当然在这之前，我们需要构建一些有关存储管理的基础设施。

## 对指令的块进行反汇编

Now we have a little module for creating chunks of bytecode. Let's try it out by
hand-building a sample chunk.

^code main-chunk (1 before, 1 after)

Don't forget the include.

^code main-include-chunk (1 before, 2 after)

Run that and give it a try. Did it work? Uh... who knows? All we've done is push
some bytes around in memory. We have no human-friendly way to see what's
actually inside that chunk we made.

To fix this, we're going to create a **disassembler**. An **assembler** is an
old-school program that takes a file containing human-readable mnemonic names
for CPU instructions like "ADD" and "MULT" and translates them to their binary
machine code equivalent. A *dis*-assembler goes in the other direction -- given
a blob of machine code, it spits out a textual listing of the instructions.

We'll implement something <span name="printer">similar</span>. Given a chunk, it
will print out all of the instructions in it. A Lox *user* won't use this, but
we Lox *maintainers* will certainly benefit since it gives us a window into the
interpreter's internal representation of code.

<aside name="printer">

In jlox, our analogous tool was the [AstPrinter class][].

[astprinter class]: representing-code.html#a-(not-very)-pretty-printer

</aside>

In `main()`, after we create the chunk, we pass it to the disassembler.

^code main-disassemble-chunk (2 before, 1 after)

Again, we whip up <span name="module">yet another</span> module.

<aside name="module">

I promise you we won't be creating this many new files in later chapters.

</aside>

^code main-include-debug (1 before, 2 after)

Here's that header:

^code debug-h

In `main()`, we call `disassembleChunk()` to disassemble all of the instructions
in the entire chunk. That's implemented in terms of the other function, which
just disassembles a single instruction. It shows up here in the header because
we'll call it from the VM in later chapters.

Here's a start at the implementation file:

^code debug-c

To disassemble a chunk, we print a little header (so we can tell *which* chunk
we're looking at) and then crank through the bytecode, disassembling each
instruction. The way we iterate through the code is a little odd. Instead of
incrementing `offset` in the loop, we let `disassembleInstruction()` do it for
us. When we call that function, after disassembling the instruction at the given
offset, it returns the offset of the *next* instruction. This is because, as
we'll see later, instructions can have different sizes.

The core of the "debug" module is this function:

^code disassemble-instruction

First, it prints the byte offset of the given instruction -- that tells us where
in the chunk this instruction is. This will be a helpful signpost when we start
doing control flow and jumping around in the bytecode.

Next, it reads a single byte from the bytecode at the given offset. That's our
opcode. We <span name="switch">switch</span> on that. For each kind of
instruction, we dispatch to a little utility function for displaying it. On the
off chance that the given byte doesn't look like an instruction at all -- a bug
in our compiler -- we print that too. For the one instruction we do have,
`OP_RETURN`, the display function is:

<aside name="switch">

We only have one instruction right now, but this switch will grow throughout the
rest of the book.

</aside>

^code simple-instruction

There isn't much to a return instruction, so all it does is print the name of
the opcode, then return the next byte offset past this instruction. Other
instructions will have more going on.

If we run our nascent interpreter now, it actually prints something:

```text
== test chunk ==
0000 OP_RETURN
```

It worked! This is sort of the "Hello, world!" of our code representation. We
can create a chunk, write an instruction to it, and then extract that
instruction back out. Our encoding and decoding of the binary bytecode is
working.

## 常量

Now that we have a rudimentary chunk structure working, let's start making it
more useful. We can store *code* in chunks, but what about *data*? Many values
the interpreter works with are created at runtime as the result of operations.
In:

```lox
1 + 2;
```

The value 3 appears nowhere in the code. However, the literals `1` and `2` do.
To compile that statement to bytecode, we need some sort of instruction that
means "produce a constant" and those literal values need to get stored in the
chunk somewhere. In jlox, the Expr.Literal AST node held the value. We need a
different solution now that we don't have a syntax tree.

### 值的表示

We won't be *running* any code in this chapter, but since constants have a foot
in both the static and dynamic worlds of our interpreter, they force us to start
thinking at least a little bit about how our VM should represent values.

For now, we're going to start as simple as possible -- we'll only support
double-precision floating point numbers. This will obviously expand over time,
so we'll set up a new module to give ourselves room to grow.

^code value-h

This typedef abstracts how Lox values are concretely represented in C. That way,
we can change that representation without needing to go back and fix existing
code that passes around values.

Back to the question of where to store constants in a chunk. For small
fixed-size values like integers, many instruction sets store the value directly
in the code stream right after the opcode. These are called **immediate
instructions** because the bits for the value are immediately after the opcode.

That doesn't work well for large or variable-sized constants like strings. In a
native compiler to machine code, those bigger constants get stored in a separate
"constant data" region in the binary executable. Then, the instruction to load a
constant has an address or offset pointing to where the value is stored in that
section.

Most virtual machines do something similar. For example, the Java Virtual
Machine [associates a *constant pool*][jvm const] with each compiled class. That
sounds good enough for clox to me. Each chunk will carry with it a list of the
values that appear as literals in the program. To keep things <span
name="immediate">simpler</span>, we'll put *all* constants in there, even simple
integers.

[jvm const]: https://docs.oracle.com/javase/specs/jvms/se7/html/jvms-4.html#jvms-4.4

<aside name="immediate">

In addition to needing two kinds of constant instructions -- one for immediate
values and one for constants in the constant table -- immediates also force us
to worry about alignment, padding, and endianness. Some architectures aren't
happy if you try to say, stuff a 4-byte integer at an odd address.

</aside>

### 值的数组

The constant pool is an array of values. The instruction to load a constant
looks up the value by index in that array. As with our <span
name="generic">bytecode</span> array, the compiler doesn't know how big the
array needs to be ahead of time. So, again, we need a dynamic one. Since C
doesn't have generic data structures, we'll write another dynamic array data
structure, this time for Value.

<aside name="generic">

Defining a new struct and manipulation functions each time we need a dynamic
array of a different type is a chore. We could cobble together some preprocessor
macros to fake generics, but that's overkill for clox. We won't need many more
of these.

</aside>

^code value-array (1 before, 2 after)

As with the bytecode array in Chunk, this struct wraps a pointer to an array
along with its allocated capacity and the number of elements in use. We also
need the same three functions to work with value arrays.

^code array-fns-h (1 before, 2 after)

The implementations will probably give you déjà vu. First, to create a new one:

^code value-c

Once we have an initialized array, we can start <span name="add">adding</span>
values to it.

<aside name="add">

Fortunately, we don't need other operations like insertion and removal.

</aside>

^code write-value-array

The memory-management macros we wrote earlier do let us reuse some of the logic
from the code array, so this isn't too bad. Finally, to release all memory used
by the array:

^code free-value-array

Now that we have growable arrays of values, we can add one to Chunk to store the
chunk's constants.

^code chunk-constants (1 before, 1 after)

Don't forget the include.

^code chunk-h-include-value (1 before, 2 after)

Ah, C, and its Stone Age modularity story. Where were we? Right. When we
initialize a new chunk, we initialize its constant list too.

^code chunk-init-constant-array (1 before, 1 after)

Likewise, we <span name="circle">free</span> the constants when we free the
chunk.

<aside name="circle">

It's like the circle of life.

</aside>

^code chunk-free-constants (1 before, 1 after)

Next, we define a convenience method to add a new constant to the chunk. Our
yet-to-be-written compiler could write to the constant array inside Chunk
directly -- it's not like C has private fields or anything -- but it's a little
nicer to add an explicit function.

^code add-constant-h (1 before, 2 after)

Then we implement it.

^code add-constant

After we add the constant, we return the index where the constant was appended
so that we can locate that same constant later.

### 常量的指令

We can *store* constants in chunks, but we also need to *execute* them. In a
piece of code like:

```lox
print 1;
print 2;
```

The compiled chunk needs to not only contain the values 1 and 2, but know *when*
to produce them so that they are printed in the right order. Thus, we need an
instruction that produces a particular constant.

^code op-constant (1 before, 1 after)

When the VM executes a constant instruction, it <span name="load">"loads"</span>
the constant for use. This new instruction is a little more complex than
`OP_RETURN`. In the above example, we load two different constants. A single
bare opcode isn't enough to know *which* constant to load.

<aside name="load">

I'm being vague about what it means to "load" or "produce" a constant because we
haven't learned how the virtual machine actually executes code at runtime yet.
For that, you'll have to wait until you get to (or skip ahead to, I suppose) the
[next chapter][vm].

[vm]: a-virtual-machine.html

</aside>

To handle cases like this, our bytecode -- like most others -- allows
instructions to have <span name="operand">**operands**</span>. These are stored
as binary data immediately after the opcode in the instruction stream and let us
parameterize what the instruction does.

<img src="image/chunks-of-bytecode/format.png" alt="OP_CONSTANT is a byte for
the opcode followed by a byte for the constant index." />

Each opcode determines how many operand bytes it has and what they mean. For
example, a simple operation like "return" may have no operands, where an
instruction for "load local variable" needs an operand to identify which
variable to load. Each time we add a new opcode to clox, we specify what its
operands look like -- its **instruction format**.

<aside name="operand">

Bytecode instruction operands are *not* the same as the operands passed to an
arithmetic operator. You'll see when we get to expressions that those operand
values are tracked separately. Instruction operands are a lower-level notion
that modify how the bytecode instruction itself behaves.

</aside>

In this case, `OP_CONSTANT` takes a single byte operand that specifies which
constant to load from the chunk's constant array. Since we don't have a compiler
yet, we "hand-compile" an instruction in our test chunk.

^code main-constant (1 before, 1 after)

We add the constant value itself to the chunk's constant pool. That returns the
index of the constant in the array. Then we write the constant instruction,
starting with its opcode. After that, we write the one-byte constant index
operand. Note that `writeChunk()` can write opcodes or operands. It's all raw
bytes as far as that function is concerned.

If we try to run this now, the disassembler is going to yell at us because it
doesn't know how to decode the new instruction. Let's fix that.

^code disassemble-constant (1 before, 1 after)

This instruction has a different instruction format, so we write a new helper
function to disassemble it.

^code constant-instruction

There's more going on here. As with `OP_RETURN`, we print out the name of the
opcode. Then we pull out the constant index from the subsequent byte in the
chunk. We print that index, but that isn't super useful to us human readers. So
we also look up the actual constant value -- since constants *are* known at
compile-time after all -- and display the value itself too.

This requires some way to print a clox Value. That function will live in the
"value" module, so we include that.

^code debug-include-value (1 before, 2 after)

Over in that header, we declare:

^code print-value-h (1 before, 2 after)

And here's an implementation:

^code print-value

Magnificent, right? As you can imagine, this is going to get more complex once
we add dynamic typing to Lox and have values of different types.

Back in `constantInstruction()`, the only remaining piece is the return value.

^code return-after-operand (1 before, 1 after)

Remember that `disassembleInstruction()` also returns a number to tell the
caller the offset of the beginning of the *next* instruction. Where `OP_RETURN`
was only a single byte, `OP_CONSTANT` is two -- one for the opcode and one for
the operand.

## 行信息

Chunks contain almost all of the information that the runtime needs from the
user's source code. It's kind of crazy to think that we can reduce all of the
different AST classes that we created in jlox down to an array of bytes and an
array of constants. There's only one piece of data we're missing. We need it,
even though the user hopes to never see it.

When a runtime error occurs, we show the user the line number of the offending
source code. In jlox, those numbers live in tokens, which we in turn store in
the AST nodes. We need a different solution for clox now that we've ditched
syntax trees in favor of bytecode. Given any bytecode instruction, we need to be
able to determine the line of the user's source program that it was compiled
from.

There are a lot of clever ways we could encode this. I took the absolute <span
name="side">simplest</span> approach I could come up with, even though it's
embarrassingly inefficient with memory. In the chunk, we store a separate array
of integers that parallels the bytecode. Each number in the array is the line
number for the corresponding byte in the bytecode. When a runtime error occurs,
we look up the line number at the same index as the current instruction's offset
in the code array.

<aside name="side">

This braindead encoding does do one thing right: it keeps the line information
in a *separate* array instead of interleaving it in the bytecode itself. Since
line information is only used when a runtime error occurs, we don't want it
between the instructions, taking up precious space in the CPU cache and causing
more cache misses as the interpreter skips past it to get to the opcodes and
operands it cares about.

</aside>

To implement this, we add another array to Chunk.

^code chunk-lines (1 before, 1 after)

Since it exactly parallels the bytecode array, we don't need a separate count or
capacity. Every time we touch the code array, we make a corresponding change to
the line number array, starting with initialization.

^code chunk-null-lines (1 before, 1 after)

And likewise deallocation:

^code chunk-free-lines (1 before, 1 after)

When we write a byte of code to the chunk, we need to know what source line it
came from, so we add an extra parameter in the declaration of `writeChunk()`.

^code write-chunk-with-line-h (1 before, 1 after)

And in the implementation:

^code write-chunk-with-line (1 after)

When we allocate or grow the code array, we do the same for the line info too.

^code write-chunk-line (2 before, 1 after)

Finally, we store the line number in the array.

^code chunk-write-line (1 before, 1 after)

### 反汇编行信息

Alright, let's try this out with our little, uh, artisanal chunk. First, since
we added a new parameter to `writeChunk()`, we need to fix those calls to pass
in some -- arbitrary at this point -- line number.

^code main-chunk-line (1 before, 2 after)

Once we have a real front end, of course, the compiler will track the current
line as it parses and pass that in.

Now that we have line information for every instruction, let's put it to good
use. In our disassembler, it's helpful to show which source line each
instruction was compiled from. That gives us a way to map back to the original
code when we're trying to figure out what some blob of bytecode is supposed to
do. After printing the offset of the instruction -- the number of bytes from the
beginning of the chunk -- we show its source line.

^code show-location (2 before, 2 after)

Bytecode instructions tend to be pretty fine-grained. A single line of source
code often compiles to a whole sequence of instructions. To make that more
visually clear, we show a `|` for any instruction that comes from the same
source line as the preceding one. The resulting output for our hand-written
chunk looks like:

```text
== test chunk ==
0000  123 OP_CONSTANT         0 '1.2'
0002    | OP_RETURN
```

We have a three-byte chunk. The first two bytes are a constant instruction that
loads 1.2 from the chunk's constant pool. The first byte is the `OP_CONSTANT`
opcode and the second is the index in the constant pool. The third byte (at
offset 2) is a single-byte return instruction.

In the remaining chapters, we will flesh this out with lots more kinds of
instructions. But the basic structure is here, and we have everything we need
now to completely represent an executable piece of code at runtime in our
virtual machine. Remember that whole family of AST classes we defined in jlox?
In clox, we've reduced that down to three arrays: bytes of code, constant
values, and line information for debugging.

This reduction is a key reason why our new interpreter will be faster than jlox.
You can think of bytecode as a sort of compact serialization of the AST, highly
optimized for how the interpreter will deserialize it in the order it needs as
it executes. In the [next chapter][vm], we will see how the virtual machine does
exactly that.

<div class="challenges">

## 挑战

1.  Our encoding of line information is hilariously wasteful of memory. Given
    that a series of instructions often correspond to the same source line, a
    natural solution is something akin to [run-length encoding][rle] of the line
    numbers.

    Devise an encoding that compresses the line information for a
    series of instructions on the same line. Change `writeChunk()` to write this
    compressed form, and implement a `getLine()` function that, given the index
    of an instruction, determines the line where the instruction occurs.

    *Hint: It's not necessary for `getLine()` to be particularly efficient.
    Since it is only called when a runtime error occurs, it is well off the
    critical path where performance matters.*

2.  Because `OP_CONSTANT` only uses a single byte for its operand, a chunk may
    only contain up to 256 different constants. That's small enough that people
    writing real-world code will hit that limit. We could use two or more bytes
    to store the operand, but that makes *every* constant instruction take up
    more space. Most chunks won't need that many unique constants, so that
    wastes space and sacrifices some locality in the common case to support the
    rare case.

    To balance those two competing aims, many instruction sets feature multiple
    instructions that perform the same operation but with operands of different
    sizes. Leave our existing one-byte `OP_CONSTANT` instruction alone, and
    define a second `OP_CONSTANT_LONG` instruction. It stores the operand as a
    24-bit number, which should be plenty.

    Implement this function:

    ```c
    void writeConstant(Chunk* chunk, Value value, int line) {
      // Implement me...
    }
    ```

    It adds `value` to `chunk`'s constant array and then writes an appropriate
    instruction to load the constant. Also add support to the disassembler for
    `OP_CONSTANT_LONG` instructions.

    Defining two instructions seems to be the best of both worlds. What
    sacrifices, if any, does it force on us?

3.  Our `reallocate()` function relies on the C standard library for dynamic
    memory allocation and freeing. `malloc()` and `free()` aren't magic. Find
    a couple of open source implementations of them and explain how they work.
    How do they keep track of which bytes are allocated and which are free?
    What is required to allocate a block of memory? Free it? How do they make
    that efficient? What do they do about fragmentation?

    *Hardcore mode:* Implement `reallocate()` without calling `realloc()`,
    `malloc()`, or `free()`. You are allowed to call `malloc()` *once*, at the
    beginning of the interpreter's execution, to allocate a single big block of
    memory which your `reallocate()` function has access to. It parcels out
    blobs of memory from that single region, your own personal heap. It's your
    job to define how it does that.

</div>

[rle]: https://en.wikipedia.org/wiki/Run-length_encoding

<div class="design-note">

## 语言设计笔记: 测试你设计的语言

We're almost halfway through the book and one thing we haven't talked about is
*testing* your language implementation. That's not because testing isn't
important. I can't possibly stress enough how vital it is to have a good,
comprehensive test suite for your language.

I wrote a [test suite for Lox][tests] (which you are welcome to use on your own
Lox implementation) before I wrote a single word of this book. Those tests found
countless bugs in my implementations.

[tests]: https://github.com/munificent/craftinginterpreters/tree/master/test

Tests are important in all software, but they're even more important for a
programming language for at least a couple of reasons:

*   **Users expect their programming languages to be rock solid.** We are so
    used to mature, stable compilers and interpreters that "It's your code, not
    the compiler" is [an ingrained part of software culture][fault]. If there
    are bugs in your language implementation, users will go through the full
    five stages of grief before they can figure out what's going on, and you
    don't want to put them through all that.

*   **A language implementation is a deeply interconnected piece of software.**
    Some codebases are broad and shallow. If the file loading code is broken in
    your text editor, it -- hopefully! -- won't cause failures in the text
    rendering on screen. Language implementations are narrower and deeper,
    especially the core of the interpreter that handles the language's actual
    semantics. That makes it easy for subtle bugs to creep in caused by weird
    interactions between various parts of the system. It takes good tests to
    flush those out.

*   **The input to a language implementation is, by design, combinatorial.**
    There are an infinite number of possible programs a user could write, and
    your implementation needs to run them all correctly. You obviously can't
    test that exhaustively, but you need to work hard to cover as much of the
    input space as you can.

*   **Language implementations are often complex, constantly changing, and full
    of optimizations.** That leads to gnarly code with lots of dark corners
    where bugs can hide.

[fault]: https://blog.codinghorror.com/the-first-rule-of-programming-its-always-your-fault/

All of that means you're gonna want a lot of tests. But *what* tests? Projects
I've seen focus mostly on end-to-end "language tests". Each test is a program
written in the language along with the output or errors it is expected to
produce. Then you have a test runner that pushes the test program through your
language implementation and validates that it does what it's supposed to.
Writing your tests in the language itself has a few nice advantages:

*   The tests aren't coupled to any particular API or internal architecture
    decisions of the implementation. This frees you to reorganize or rewrite
    parts of your interpreter or compiler without needing to update a slew of
    tests.

*   You can use the same tests for multiple implementations of the language.

*   Tests can often be terse and easy to read and maintain since they are
    simply scripts in your language.

It's not all rosy, though:

*   End-to-end tests help you determine *if* there is a bug, but not *where* the
    bug is. It can be harder to figure out where the erroneous code in the
    implementation is because all the test tells you is that the right output
    didn't appear.

*   It can be a chore to craft a valid program that tickles some obscure corner
    of the implementation. This is particularly true for highly-optimized
    compilers where you may need to write convoluted code to ensure that you
    end up on just the right optimization path where a bug may be hiding.

*   The overhead can be high to fire up the interpreter, parse, compile, and
    run each test script. With a big suite of tests -- which you *do* want,
    remember -- that can mean a lot of time spent waiting for the tests to
    finish running.

我可以继续讲，但我不希望变成布道。而且我并不想假装自己是*如何*测试语言的专家。我只想要你在心里内化测试的重要性。真的。测试你的语言吧。你会感谢我的。

</div>
