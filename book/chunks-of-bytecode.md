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

One of the first bytecode formats was [p-code][], developed for Niklaus Wirth's
Pascal language. You might think a PDP-11 running at 15MHz couldn't afford the
overhead of emulating a virtual machine. But back then, computers were in their
Cambrian explosion and new architectures appeared every day. Keeping up with the
latest chips was worth more than squeezing the maximum performance from each
one. That's why the "p" in "p-code" doesn't stand for "Pascal", but "portable".

[p-code]: https://en.wikipedia.org/wiki/P-code_machine

</aside>

This is the path we'll take with our new interpreter, clox. We'll follow in the
footsteps of the main implementations of Python, Ruby, Lua, OCaml, Erlang, and
others. In many ways, our VM's design will parallel the structure of our
previous interpreter:

<img src="image/chunks-of-bytecode/phases.png" alt="Phases of the two
implementations. jlox is Parser to Syntax Trees to Interpreter. clox is Compiler
to Bytecode to Virtual Machine." />

Of course, we won't implement the phases strictly in order. Like our previous
interpreter, we'll bounce around, building up the implementation one language
feature at a time. In this chapter, we'll get the skeleton of the application in
place and the data structures needed to store and represent a chunk of bytecode.

## 开始吧！

Where else to begin, but at `main()`? <span name="ready">Fire</span> up your
trusty text editor and start typing.

<aside name="ready">

Now is a good time to stretch, maybe crack your knuckles. A little montage music
wouldn't hurt either.

</aside>

^code main-c

From this tiny seed, we will grow our entire VM. Since C provides us with so
little, we first need to spend some time amending the soil. Some of that goes
into this header:

^code common-h

There are a handful of types and constants we'll use throughout the interpreter,
and this is a convenient place to put them. For now, it's the venerable `NULL`,
`size_t`, the nice C99 Boolean `bool`, and explicit-sized integer types --
`uint8_t` and friends.

## 指令的块（chunk）

Next, we need a module to define our code representation. I've been using
"chunk" to refer to sequences of bytecode, so let's make that the official name
for that module.

^code chunk-h

In our bytecode format, each instruction has a one-byte **operation code**
(universally shortened to **opcode**). That number controls what kind of
instruction we're dealing with -- add, subtract, look up variable, etc. We
define those here:

^code op-enum (1 before, 2 after)

For now, we start with a single instruction, `OP_RETURN`. When we have a
full-featured VM, this instruction will mean "return from the current function".
I admit this isn't exactly useful yet, but we have to start somewhere, and this
is a particularly simple instruction, for reasons we'll get to later.

### 存储指令的动态数组

Bytecode is a series of instructions. Eventually, we'll store some other data
along with the instructions, so let's go ahead and create a struct to hold it
all.

^code chunk-struct (1 before, 2 after)

At the moment, this is simply a wrapper around an array of bytes. Since we don't
know how big the array needs to be before we start compiling a chunk, it must be
dynamic. Dynamic arrays are one of my favorite data structures. That sounds like
claiming vanilla is my favorite ice cream <span name="flavor">flavor</span>, but
hear me out. Dynamic arrays provide:

<aside name="flavor">

Butter pecan is actually my favorite.

</aside>

* Cache-friendly, dense storage.

* Constant-time indexed element lookup.

* Constant-time appending to the end of the array.

Those features are exactly why we used dynamic arrays all the time in jlox under
the guise of Java's ArrayList class. Now that we're in C, we get to roll our
own. If you're rusty on dynamic arrays, the idea is pretty simple. In addition
to the array itself, we keep two numbers: the number of elements in the array we
have allocated ("capacity") and how many of those allocated entries are actually
in use ("count").

^code count-and-capacity (1 before, 2 after)

When we add an element, if the count is less than the capacity, then there is
already available space in the array. We store the new element right in there
and bump the count:

<img src="image/chunks-of-bytecode/insert.png" alt="Storing an element in an
array that has enough capacity." />

If we have no spare capacity, then the process is a little more involved:

<img src="image/chunks-of-bytecode/grow.png" alt="Growing the dynamic array
before storing an element." class="wide" />

1.  <span name="amortized">Allocate</span> a new array with more capacity.
2.  Copy the existing elements from the old array to the new one.
3.  Store the new `capacity`.
4.  Delete the old array.
5.  Update `code` to point to the new array.
6.  Store the element in the new array now that there is room.
7.  Update the `count`.

<aside name="amortized">

Copying the existing elements when you grow the array makes it seem like
appending an element is *O(n)*, not *O(1)* like I said above. However, you only
need to do this copy step on *some* of the appends. Most of the time, there is
already extra capacity, so you don't need to copy.

To understand how this works, we need [**amortized
analysis**](https://en.wikipedia.org/wiki/Amortized_analysis). That shows us
that as long as we grow the array by a multiple of its current size, when we
average out the cost of a *sequence* of appends, each append is *O(1)*.

</aside>

We have our struct ready, so let's implement the functions to work with it. C
doesn't have constructors, so we declare a function to initialize a new chunk.

^code init-chunk-h (1 before, 2 after)

And implement it thusly:

^code chunk-c

The dynamic array starts off completely empty. We don't even allocate a raw
array yet. To append a byte to the end of the chunk we use a new function.

^code write-chunk-h (1 before, 2 after)

This is where the interesting work happens.

^code write-chunk

The first thing we need to do is see if the current array already has capacity
for the new byte. If it doesn't, then we first need to grow the array to make
room. (We also hit this case on the very first write when the array is `NULL`
and `capacity` is 0.)

To grow the array, first we figure out the new capacity and grow the array to
that size. Both of those lower-level memory operations are defined in a new
module.

^code chunk-c-include-memory (1 before, 2 after)

This is enough to get us started:

^code memory-h

This macro calculates a new capacity based on a given current capacity. In order
to get the performance we want, the important part is that it *scales* based on
the old size. We grow by a factor of two, which is pretty typical. 1.5&times; is
another common choice.

We also handle when the current capacity is zero. In that case, we jump straight
to eight elements instead of starting at one. That <span
name="profile">avoids</span> a little extra memory churn when the array is very
small, at the expense of wasting a few bytes on very small chunks.

<aside name="profile">

I picked the number eight somewhat arbitrarily for the book. Most dynamic array
implementations have a minimum threshold like this. The right way to pick a
value for this is to profile against real-world usage and see which constant
makes the best performance trade-off between extra grows versus wasted space.

</aside>

Once we know the desired capacity, we create or grow the array to that size
using `GROW_ARRAY()`.

^code grow-array (2 before, 2 after)

This macro pretties up a function call to `reallocate()` where the real work
happens. The macro itself takes care of getting the size of the array's element
type and casting the resulting `void*` back to a pointer of the right type.

This `reallocate()` function is the single function we'll use for all dynamic
memory management in clox -- allocating memory, freeing it, and changing the
size of an existing allocation. Routing all of those operations through a single
function will be important later when we add a garbage collector that needs to
keep track of how much memory is in use.

The two size arguments passed to `reallocate()` control which operation to
perform:

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

That sounds like a lot of cases to handle, but here's the implementation:

^code memory-c

When `newSize` is zero, we handle the deallocation case ourselves by calling
`free()`. Otherwise, we rely on the C standard library's `realloc()` function.
That function conveniently supports the other three aspects of our policy. When
`oldSize` is zero, `realloc()` is equivalent to calling `malloc()`.

The interesting cases are when both `oldSize` and `newSize` are not zero. Those
tell `realloc()` to resize the previously-allocated block. If the new size is
smaller than the existing block of memory, it simply <span
name="shrink">updates</span> the size of the block and returns the same pointer
you gave it. If the new size is larger, it attempts to grow the existing block
of memory.

It can only do that if the memory after that block isn't already in use. If
there isn't room to grow the block, `realloc()` instead allocates a *new* block
of memory of the desired size, copies over the old bytes, frees the old block,
and then returns a pointer to the new block. Remember, that's exactly the
behavior we want for our dynamic array.

Because computers are finite lumps of matter and not the perfect mathematical
abstractions computer science theory would have us believe, allocation can fail
if there isn't enough memory and `realloc()` will return `NULL`. We should
handle that.

^code out-of-memory (1 before, 1 after)

There's not really anything *useful* that our VM can do if it can't get the
memory it needs, but we at least detect that and abort the process immediately
instead of returning a `NULL` pointer and letting it go off the rails later.

<aside name="shrink">

Since all we passed in was a bare pointer to the first byte of memory, what does
it mean to "update" the block's size? Under the hood, the memory allocator
maintains additional bookkeeping information for each block of heap-allocated
memory, including its size.

Given a pointer to some previously-allocated memory, it can find this
bookkeeping information, which is necessary to be able to cleanly free it. It's
this size metadata that `realloc()` updates.

Many implementations of `malloc()` store the allocated size in memory right
*before* the returned address.

</aside>

OK, we can create new chunks and write instructions to them. Are we done? Nope!
We're in C now, remember, we have to manage memory ourselves, like Ye Olden
Times, and that means *freeing* it too.

^code free-chunk-h (1 before, 1 after)

The implementation is:

^code free-chunk

We deallocate all of the memory and then call `initChunk()` to zero out the
fields leaving the chunk in a well-defined empty state. To free the memory, we
add one more macro.

^code free-array (3 before, 2 after)

Like `GROW_ARRAY()`, this is a wrapper around a call to `reallocate()`. This one
frees the memory by passing in zero for the new size. I know, this is a lot of
boring low-level stuff. Don't worry, we'll get a lot of use out of these in
later chapters and will get to program at a higher level. Before we can do that,
though, we gotta lay our own foundation.

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

I could go on, but I don't want this to turn into a sermon. Also, I don't
pretend to be an expert on *how* to test languages. I just want you to
internalize how important it is *that* you test yours. Seriously. Test your
language. You'll thank me for it.

</div>
