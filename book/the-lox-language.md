> 为某个人做的事情中，有比为这个人做早餐更好的事情吗？
>
> <cite>安东尼·波登</cite>

我们将用本书的剩余部分来阐述Lox语言的每一个边边角角。但马上就开始写实现解释器的代码，似乎显得有点残忍。我们至少得熟悉一下我们要实现的语言的语法吧。

但同时，我也不想在你还没开始用文本<span name="home">编辑器</span>写Lox的实现代码时，就把Lox语言的各种细节和规范介绍一遍。所以本章将是对Lox的一个比较温和友好的介绍。很多语言的细节和边界条件将不会在本章介绍。后面我们有的是时间。

<aside name="home">

如果你不能自己尝试编写代码并运行，那么教程就不会很有趣。哦对了，你还没有Lox解释器，因为你还没有开始写呢！

没关系，先用[我的][repo]。

[repo]: https://github.com/confucianzuoyuan/craftinginterpreters

</aside>

## 你好, Lox

我们先来简单尝试一下<span name="salmon">Lox</span>：

<aside name="salmon">

我们现在想要尝鲜的是Lox，这是一门语言。我不知道你吃过腌制的冷熏鲑鱼没有，如果没吃过，也可以试一下。

</aside>

```lox
// 你的第一个Lox程序！
print "Hello, world!";
```

`//`行注释和语句末尾的分号说明了Lox的语法是C家族的成员。（"Hello, world!"字符串的两边没有括号是因为`print`是一个内建的语句，而不是一个库函数。）

我不想说<span name="c">C</span>拥有着*伟大的*语法。如果我们想要优雅的语法，那么Lox可能会采用Pascal或者Smalltalk的语法风格。如果我们想要更加简洁的语法风格，我们可能会选择Scheme那样的语法。这些语言都有各自的价值。

<aside name="c">

我肯定对Lox有偏爱，但我觉得Lox的语法非常的干净。C语言语法最大的问题是有关类型的。丹尼斯·里奇把这个有关类型的想法叫做“[声明反映使用][use]”，也就是说变量的声明反映了如果你想要获取基本类型的值，你需要对变量进行什么样的操作。伟大的创意，但在实践中很多变量声明非常难以理解。

[use]: http://softwareengineering.stackexchange.com/questions/117024/why-was-the-c-syntax-for-arrays-pointers-and-functions-designed-this-way

Lox不是静态类型语言，所以我们避免了上面的这个大问题。

</aside>

那么类C语言的语法有什么优点呢？优点就是：*熟悉感*。因为我们已经假设过读者对我们将要用来*实现*Lox的两门语言——Java和C——很熟悉了。那么Lox的语法显然读者也会很容易上手。Lox使用和Java、C相似的语法，可以让我们少学一些语法特性。

## 一门高级语言

写完这本书时，书的厚度超出了我所期望的厚度。但这本书还没有厚到能够容纳讲解类似于Java这样的语言的实现的厚度。为了在本书中包含Lox语言的两个实现，Lox的语法必须非常紧凑。

当我在想有哪些语言是小而有用的编程语言时，映入我脑海的是高级“脚本”语言，例如<span name="js">JavaScript</span>，Scheme和Lua。在这三种语言中，Lox最像JavaScript，因为类C语言的语法都像JavaScript。而Lox在作用域方面很接近Scheme。在[第三部分][]中，我们将使用C语言实现Lox解释器，实现方式大量的参考了Lua清晰而高效的实现。

[第三部分]: a-bytecode-virtual-machine.html

<aside name="js">

现在JavaScript这门语言已经统治了世界，并构建了很多超大型应用。所以再叫它“小型脚本语言”已经不太合适了。在最开始，布兰登·艾奇花了*十天*就写出了第一个JS解释器并运行在了网景浏览器上，还让网页上的按钮动了起来。在那时，JS确实是一个小型脚本语言。但随着JavaScript的发展，它已经变得很庞大了。

大概艾奇在设计JS时花的时间太少了，所以留下了很多坑。例如变量提升，`this`的动态绑定，数组中的空洞，以及隐式类型转换。

我花了很多的时间在Lox上面，所以Lox比JS应该会更加干净一些。

</aside>

Lox和上面提到的三门语言还有两点相似之处：

### 动态类型

Lox是动态类型语言。变量可以存储任意类型的值。一个相同的变量甚至可以在不同的时间存储不同类型的值。如果你想要在错误的类型的值上面做一些运算——例如，整型和字符串进行相除——那么这个错误将在运行时发现和报告。

有很多对<span name="static">静态</span>类型偏爱的理由。但因为一些实践方面的原因，我们的Lox还是选择了动态类型。一个静态类型系统需要学习大量的东西以及写大量的代码才能实现。忽略掉静态类型系统采用动态类型系统，会让我们的语言更加简单，书也会薄一些。我们在运行时才会做一些类型检查。这样我们构建解释器的速度会快一些。

<aside name="static">

最后，我们用来*实现*Lox解释器的两种语言——C和Java——都是静态类型语言。

</aside>

### 自动内存管理

高级语言存在的一个目的就是消除容易出错和操作底层的繁琐工作，尤其是还有什么工作比手动管理内存的分配和释放更加烦人的事情呢？没有人会早晨起床然后互相打招呼说：“我已经迫不及待的想为我今天分配的每一块内存调用`free()`函数了！”

有两种主要的<span name="gc">技术</span>用来管理内存：**引用计数（reference counting）**和**跟踪垃圾回收（tracing garbage collection）**（通常简称为**垃圾收集（garbage collection）**或者**GC**）。引用计数器更加容易实现——我想这就是Perl、PHP和Python最开始都使用引用计数的原因。但是随着语言的发展，引用计数的局限性越来越大。所以这些语言到最后都添加了一个完整的跟踪GC实现，来管理对象的生命周期。

<aside name="gc">

在实践中，引用计数和跟踪这两种技术更像是连续谱上的两个点，而不是完全相反的两个极端。大部分引用计数系统最终都会使用一些跟踪技术来管理对象的生命周期。而分代垃圾回收机制更像是一种在引用计数搞不定的情况下才会使用的技术。

有关这方面的技术, 可以参考 "[A Unified Theory of Garbage Collection][gc]" (PDF).

[gc]: https://researcher.watson.ibm.com/researcher/files/us-bacon/Bacon04Unified.pdf

</aside>

跟踪垃圾回收技术有着非常恐怖的名声。因为，这种技术会在内存这个级别上工作。调试GC可能会让你做噩梦，梦里都是16进制的转储（dump）信息。但是，请记住，本书就是来消除魔法并杀死怪兽的，所以我们将编写自己的垃圾回收器。你会发现GC算法很简单，而且实现起来很有趣。

## 数据类型

在Lox语言这个小小的宇宙中，构建起整个宇宙的原子其实就是内建的数据类型。下面是一些数据类型：

*   **<span name="bool">布尔类型（Booleans）</span>.** 没有逻辑我们无法编程，而没有布尔值，那么连逻辑都将不存在。“真（true）”和“假（false）”就是软件的阴和阳。不像很多古老的语言，使用一些已经存在的类型来表示真和假，Lox专门实现了布尔类型。我们可能实现的较为粗糙，但我们也不是*野蛮人*。

    <aside name="bool">

    在Lox中，布尔值是唯一一种用人名来命名的数据类型。他就是George Boole，这就是为了"Boolean"首字母大写的原因。他死于1864年，过了一个世纪，他所发明的布尔代数才真正变成了数字计算机。我很好奇如果他看到Java代码里有着成千上万他的名字是一种什么感觉。

    </aside>

    布尔类型有两个值，true和false。

    ```lox
    true;  // Not false.
    false; // Not *not* false.
    ```

*   **数（Numbers）.** Lox只有一种数：双精度浮点数。因为浮点数还可以表示一个很大范围的整数。所以只有一种数会让实现更加简单。

    功能齐全的编程语言有着很多数的语法——十六进制，科学计数法，八进制，以及各种有趣的东西。我们这里只有整数和十进制数。

    ```lox
    1234;  // An integer.
    12.34; // A decimal number.
    ```

*   **字符串（Strings）.** 我们已经在第一个例子中看到了一个字符串字面量。像大多数编程语言一样，字符串被包含在双引号当中。

    ```lox
    "I am a string";
    "";    // The empty string.
    "123"; // This is a string, not a number.
    ```

    正如我们在实现字符串这一特性时所能看到的，有很多的复杂性隐藏在<span name="char">一堆字符</span>人畜无害的表面之下。

    <aside name="char">

    即使是“字符”这个词也很具有欺骗性。字符是ASCII？还是Unicode？是代码点还是“字素簇”？字符是如何编码的？每个字符的大小是固定的还是可变的？

    </aside>

*   **Nil.** 最后一种内建类型是Nil，我们并没有邀请它参加聚会，但它总是自己出现。Nil表示“没有值”。在很多语言中我们使用单词“null”来表示没有值。在Lox中，我们使用`nil`这个词。（当我们实现这个类型的时候，我们将会对比一下Lox的`nil`和Java、C语言中的`null`。）

    有很多种理由不在一门语言中引入null值，因为空指针异常（null pointer errors）在工业界造成了很大的损失。如果我们实现的是一门静态类型语言，那么不引入null值是值得的。但在一门动态类型语言中，消除null比引入null更加烦人。

## 表达式

如果说内建数据类型和它们的字面量是原子的话，那么**表达式**就是分子了。大部分表达式大家应该都很熟悉。

### 算术表达式

Lox的基本算术表达式和其他类C语言一样：

```lox
add + me;
subtract - me;
multiply * me;
divide / me;
```

操作符两边的子表达式叫做**操作数（operands）**。因为以上操作符有*两个*操作数，所以这些操作符一般叫做**二元（binary）**操作符。（这里的binary和二进制0-1的binary没关系。）因为这些操作符是<span name="fixity">固定</span>*在*两个操作数中间的，所以它们又叫**中缀（infix）**操作符（和出现在操作数前面的**前缀（prefix）**操作符以及出现在操作数后面的**后缀（postfix）**操作符相对应）。

<aside name="fixity">

有些操作符会有多于两个的操作数，而操作符会在这些操作数之间放置。只有一个大量使用的这种操作符，就是“条件操作符”或者叫做“三元操作符”（C中这么叫）：

```c
condition ? thenArm : elseArm;
```

有些人叫这种操作符为**mixfix**操作符。有很少的一部分编程语言（Haskell、OCaml）允许你定义自己的操作符，以及控制这些操作符的摆放位置——也就是它们的“fixity”。

</aside>

有一个算术操作符既是中缀操作符也是前缀操作符。那就是`-`，当`-`操作符放在数的前面是，表示负号。

```lox
-negateMe;
```

以上所有这些操作符都是作用在数上面的，所以不能使用这些操作符来操作其他类型。`+`操作符是一个例外——你可以使用`+`来拼接两个字符串。

### 比较和判断相等表达式

让我们继续，我们有一些比较操作符会返回布尔类型的结果。

```lox
less < than;
lessThan <= orEqual;
greater > than;
greaterThan >= orEqual;
```

我们可以测试任意类型的两个值是否相等。

```lox
1 == 2;         // false.
"cat" != "dog"; // true.
```

甚至比较不同的类型的两个值。

```lox
314 == "pi"; // false.
```

当然，不同类型的两个值*永远*不会相等。

```lox
123 == "123"; // false.
```

因为在Lox中我们不会做隐式类型转换（我极其反对隐式类型转换）。

### 逻辑运算符

非操作符，是一个前缀`!`，如果操作数为真，返回`false`，操作数为假，返回`true`。

```lox
!true;  // false.
!false; // true.
```

剩下两个逻辑运算符其实是伪装成表达式的控制流。<span name="and">`and`</span>表达式只有当两个值都为true时才会返回true。如果`and`操作符的左边的值是false的话，那么表达式将返回左边的操作数。如果左边的操作数为true，则返回右边操作数的值。

```lox
true and false; // false.
true and true;  // true.
```

`or`表达式只要两个值中有至少一个true，就会返回true。如果左边的操作数为true，则返回左边操作数。如果左边操作数为false，则返回右边操作数。

```lox
false or false; // false.
true or false;  // true.
```

<aside name="and">

我使用`and`和`or`来代替`&&`和`||`是因为Lox不需要`&`和`|`来作为位运算操作符。如果引进了两个相同字符的操作符，却没有单个字符的操作符的话，会显得很奇怪。

我自己也喜欢使用单词而不是负号，因为上面两个操作符实际上是控制流结构，而非简单的操作符。

</aside>

`and`和`or`是控制流结构的原因在于它们是**短路求值（short-circuit）**。当`and`运算符左边的操作数是false时，会直接返回左边的操作数，`and`表达式甚至不会对右侧的操作数进行*求值*。相对应的，如果`or`左侧的操作数为true，那么右侧的操作数也就被直接忽略掉了。

### 优先级和分组

所有的这些操作符拥有和C语言里面同样的优先级和结合性。（当我们到了解析这个阶段，我们会理解的更加精准。）如果想要改变优先级，可以使用`()`括号来进行分组。

```lox
var average = (min + max) / 2;
```

我去掉了一些典型的操作符，例如位运算操作符、移位运算符、求余运算符以及条件运算符。因为这些从技术上实现来说，意思不大。当然我希望你能够自己实现这些运算符，这样会锻炼你的编程能力。

以上就是我们要介绍的Lox中的表达式，接下来，让我们再往上走一层。

## 语句

现在我们来到了语句。表达式的主要任务是求值，或者说产生一个*值*。而语句的任务是产生一个*作用*。因为根据定义，语句并不会进行求值，语句的用处在于在某种程度上改变世界——通常情况下会修改一些状态，读取输出，以及产生输出。

你已经见过很多种类型的语句了。第一个就是：

```lox
print "Hello, world!";
```

<span name="print">`print`语句</span>先对一个字符串进行求值，然后将求值结果显示给用户。你已经看到过一些像下面一样的表达式：

<aside name="print">

将`print`直接做进语言里，而不是把`print`做进标准库里，是一种简单粗暴的方法。但对我们来说很有用：它意味着在我们构建解释器的过程中，就可以不断的产生输出了。否则我们还需要先实现定义函数，使用函数名查找，以及调用函数这些功能。

</aside>

```lox
"some expression";
```

一个表达式结尾跟上一个分号（`;`)，就将表达式提升为语句了。通常叫这样的语句为**表达式语句**。

如果你想将多个语句打包成一个语句，你可以使用花括号将多个语句包起来，放在一个**块**中。

```lox
{
  print "One statement.";
  print "Two statements.";
}
```

块会影响作用域，下一节我们就会讲解这个概念...

## 变量

我们使用`var`这个关键字来定义变量。如果变量<span name="omit">没有</span>初始值，那么变量的默认值是`nil`。

<aside name="omit">

如果在编程语言中去掉`nil`值，然后强制要求每一个变量必须被初始化成某一个值，比有`nil`这个值，会让人处理起来更加头痛。

</aside>

```lox
var imAVariable = "here is my value";
var iAmNil;
```

变量一旦声明，我们就可以使用变量名来访问变量的值，也可以对变量名进行赋值了。

<span name="breakfast"></span>

```lox
var breakfast = "bagels";
print breakfast; // "bagels".
breakfast = "beignets";
print breakfast; // "beignets".
```

<aside name="breakfast">

你知道我为什么倾向于在吃早餐之前写书吗？

</aside>

我这里不打算讨论有关变量的作用域的问题，因为后面我们会花大量的时间来研究变量作用域的各种规则。在大多数情况下，Lox的变量作用域规则和C还有Java都差不多。

## 控制流

如果我们无法跳过一些代码，也无法多次执行一段代码，那么我们很难写出<span name="flow">有用的</span>程序。跳过代码和多次执行代码指的就是控制流结构。除了我们上边说的逻辑运算符以外，Lox还有三种控制流结构，这些控制流结构直接来自C语言。

<aside name="flow">

我们已经有了`and`和`or`来实现分支结构，然后我们*可以*使用递归来重复执行代码，所以从理论上来说我们想要的控制流结构已经都能够实现了。只是使用命令式风格的语言来通过`and`、`or`和递归来实现控制流结构，会显得非常别扭（说白了就是在用命令式语言进行函数式编程）。

Scheme这门语言就是没有内建的循环结构。它依赖于递归来实现代码的重复执行。Smalltalk这门语言没有内建的分支结构，它通过动态分派机制来选择性的执行代码。

</aside>

`if`语句基于某些条件来选择执行两个语句中的一个。

```lox
if (condition) {
  print "yes";
} else {
  print "no";
}
```

`while`<span name="do">循环</span>会重复的执行循环体，只要循环条件表达式一直求值为true。

```lox
var a = 1;
while (a < 10) {
  print a;
  a = a + 1;
}
```

<aside name="do">

我没有在Lox实现`do while`循环这种语法，因为这种语法用的很少。而且我们已经实现了`while`循环语句，再去实现`do while`循环语句，也不会让我们学会任何新的东西。如果你想的话，可以自己实现一下。

</aside>

最后，我们实现了`for`循环。

```lox
for (var a = 1; a < 10; a = a + 1) {
  print a;
}
```

`for`循环做的事情和`while`循环是一样的。很多现代语言里面还有类似于<span name="foreach">`for-in`</span>或者`foreach`循环这样的语法，为了能够明确的去迭代不同类型的序列。在一门真正的编程语言中，这些都比C风格的`for`循环更加好用。Lox只实现了C风格的`for`循环。

<aside name="foreach">

我之所以做出这样的让步，是因为解释器的实现被划分成了多个章节。`for-in`循环需要在迭代器协议中进行某种动态分配来处理不同种类的序列，但是直到在完成控制流的实现之后。我们才能回来并添加`for-in`循环。但我认为这样做不会教给你任何超级有趣的东西。

</aside>

## 函数

函数调用表达式看起来和C语言是一样的。

```lox
makeBreakfast(bacon, eggs, toast);
```

你也可以不给函数传任何参数，然后直接调用函数。

```lox
makeBreakfast();
```

不像在Ruby里面，在这里，函数调用的括号是强制必须写的。如果没有写括号，只有一个函数名，那么就不是再*调用*函数，而只是函数的引用而已。

如果无法定义自己的函数，一门语言写起来会很无聊。在Lox中，我们可以使用<span name="fun">`fun`</span>关键字来定义函数。

<aside name="fun">

我见过很多语言使用`fn`，`fun`，`func`以及`function`这样的关键字来定义函数。我有点希望见到某些语言中，使用`funct`，`functi`和`functio`这样诡异的关键字来定义函数。

</aside>

```lox
fun printSum(a, b) {
  print a + b;
}
```

Now's a good time to clarify some <span name="define">terminology</span>. Some
people throw around "parameter" and "argument" like they are interchangeable
and, to many, they are. We're going to spend a lot of time splitting the finest
of downy hairs around semantics, so let's sharpen our words. From here on out:

*   An **argument** is an actual value you pass to a function when you call it.
    So a function *call* has an *argument* list. Sometimes you hear **actual
    parameter** used for these.

*   A **parameter** is a variable that holds the value of the argument inside
    the body of the function. Thus, a function *declaration* has a *parameter*
    list. Others call these **formal parameters** or simply **formals**.

<aside name="define">

Speaking of terminology, some statically typed languages like C make a
distinction between *declaring* a function and *defining* it. A declaration
binds the function's type to its name so that calls can be type-checked but does
not provide a body. A definition declares the function and also fills in the
body so that the function can be compiled.

Since Lox is dynamically typed, this distinction isn't meaningful. A function
declaration fully specifies the function including its body.

</aside>

The body of a function is always a block. Inside it, you can return a value
using a `return` statement.

```lox
fun returnSum(a, b) {
  return a + b;
}
```

If execution reaches the end of the block without hitting a `return`, it
<span name="sneaky">implicitly</span> returns `nil`.

<aside name="sneaky">

See, I told you `nil` would sneak in when we weren't looking.

</aside>

### 闭包

Functions are *first class* in Lox, which just means they are real values that
you can get a reference to, store in variables, pass around, etc. This works:

```lox
fun addPair(a, b) {
  return a + b;
}

fun identity(a) {
  return a;
}

print identity(addPair)(1, 2); // Prints "3".
```

Since function declarations are statements, you can declare local functions
inside another function.

```lox
fun outerFunction() {
  fun localFunction() {
    print "I'm local!";
  }

  localFunction();
}
```

If you combine local functions, first-class functions, and block scope, you run
into this interesting situation:

```lox
fun returnFunction() {
  var outside = "outside";

  fun inner() {
    print outside;
  }

  return inner;
}

var fn = returnFunction();
fn();
```

Here, `inner()` accesses a local variable declared outside of its body in the
surrounding function. Is this kosher? Now that lots of languages have borrowed
this feature from Lisp, you probably know the answer is yes.

For that to work, `inner()` has to "hold on" to references to any surrounding
variables that it uses so that they stay around even after the outer function
has returned. We call functions that do this <span
name="closure">**closures**</span>. These days, the term is often used for *any*
first-class function, though it's sort of a misnomer if the function doesn't
happen to close over any variables.

<aside name="closure">

Peter J. Landin coined the term "closure". Yes, he invented damn near half the
terms in programming languages. Most of them came out of one incredible paper,
"[The Next 700 Programming Languages][svh]".

[svh]: https://homepages.inf.ed.ac.uk/wadler/papers/papers-we-love/landin-next-700.pdf

In order to implement these kind of functions, you need to create a data
structure that bundles together the function's code and the surrounding
variables it needs. He called this a "closure" because it *closes over* and
holds on to the variables it needs.

</aside>

As you can imagine, implementing these adds some complexity because we can no
longer assume variable scope works strictly like a stack where local variables
evaporate the moment the function returns. We're going to have a fun time
learning how to make these work correctly and efficiently.

## 类

Since Lox has dynamic typing, lexical (roughly, "block") scope, and closures,
it's about halfway to being a functional language. But as you'll see, it's
*also* about halfway to being an object-oriented language. Both paradigms have a
lot going for them, so I thought it was worth covering some of each.

Since classes have come under fire for not living up to their hype, let me first
explain why I put them into Lox and this book. There are really two questions:

### Why might any language want to be object oriented?

Now that object-oriented languages like Java have sold out and only play arena
shows, it's not cool to like them anymore. Why would anyone make a *new*
language with objects? Isn't that like releasing music on 8-track?

It is true that the "all inheritance all the time" binge of the '90s produced
some monstrous class hierarchies, but **object-oriented programming** (**OOP**)
is still pretty rad. Billions of lines of successful code have been written in
OOP languages, shipping millions of apps to happy users. Likely a majority of
working programmers today are using an object-oriented language. They can't all
be *that* wrong.

In particular, for a dynamically typed language, objects are pretty handy. We
need *some* way of defining compound data types to bundle blobs of stuff
together.

If we can also hang methods off of those, then we avoid the need to prefix all
of our functions with the name of the data type they operate on to avoid
colliding with similar functions for different types. In, say, Racket, you end
up having to name your functions like `hash-copy` (to copy a hash table) and
`vector-copy` (to copy a vector) so that they don't step on each other. Methods
are scoped to the object, so that problem goes away.

### 为什么Lox是一门面向对象语言？

I could claim objects are groovy but still out of scope for the book. Most
programming language books, especially ones that try to implement a whole
language, leave objects out. To me, that means the topic isn't well covered.
With such a widespread paradigm, that omission makes me sad.

Given how many of us spend all day *using* OOP languages, it seems like the
world could use a little documentation on how to *make* one. As you'll see, it
turns out to be pretty interesting. Not as hard as you might fear, but not as
simple as you might presume, either.

### 类还是原型

When it comes to objects, there are actually two approaches to them, [classes][]
and [prototypes][]. Classes came first, and are more common thanks to C++, Java,
C#, and friends. Prototypes were a virtually forgotten offshoot until JavaScript
accidentally took over the world.

[classes]: https://en.wikipedia.org/wiki/Class-based_programming
[prototypes]: https://en.wikipedia.org/wiki/Prototype-based_programming

In class-based languages, there are two core concepts: instances and classes.
Instances store the state for each object and have a reference to the instance's
class. Classes contain the methods and inheritance chain. To call a method on an
instance, there is always a level of indirection. You look up the instance's
class and then you find the method *there*:

<img src="image/the-lox-language/class-lookup.png" alt="How fields and methods are looked up on classes and instances" />

Prototype-based languages <span name="blurry">merge</span> these two concepts.
There are only objects -- no classes -- and each individual object may contain
state and methods. Objects can directly inherit from each other (or "delegate
to" in prototypal lingo):

<aside name="blurry">

In practice the line between class-based and prototype-based languages blurs.
JavaScript's "constructor function" notion [pushes you pretty hard][js new]
towards defining class-like objects. Meanwhile, class-based Ruby is perfectly
happy to let you attach methods to individual instances.

[js new]: http://gameprogrammingpatterns.com/prototype.html#what-about-javascript

</aside>

<img src="image/the-lox-language/prototype-lookup.png" alt="How fields and methods are looked up in a prototypal system" />

This means that in some ways prototypal languages are more fundamental than
classes. They are really neat to implement because they're *so* simple. Also,
they can express lots of unusual patterns that classes steer you away from.

But I've looked at a *lot* of code written in prototypal languages -- including
[some of my own devising][finch]. Do you know what people generally do with all
of the power and flexibility of prototypes? ...They use them to reinvent
classes.

[finch]: http://finch.stuffwithstuff.com/

I don't know *why* that is, but people naturally seem to prefer a class-based
(Classic? Classy?) style. Prototypes *are* simpler in the language, but they
seem to accomplish that only by <span name="waterbed">pushing</span> the
complexity onto the user. So, for Lox, we'll save our users the trouble and bake
classes right in.

<aside name="waterbed">

Larry Wall, Perl's inventor/prophet calls this the "[waterbed theory][]". Some
complexity is essential and cannot be eliminated. If you push it down in one
place, it swells up in another.

[waterbed theory]: http://wiki.c2.com/?WaterbedTheory

Prototypal languages don't so much *eliminate* the complexity of classes as they
do make the *user* take that complexity by building their own class-like
metaprogramming libraries.

</aside>

### Lox中的类

Enough rationale, let's see what we actually have. Classes encompass a
constellation of features in most languages. For Lox, I've selected what I think
are the brightest stars. You declare a class and its methods like so:

```lox
class Breakfast {
  cook() {
    print "Eggs a-fryin'!";
  }

  serve(who) {
    print "Enjoy your breakfast, " + who + ".";
  }
}
```

The body of a class contains its methods. They look like function declarations
but without the `fun` <span name="method">keyword</span>. When the class
declaration is executed, Lox creates a class object and stores that in a
variable named after the class. Just like functions, classes are first class in
Lox.

<aside name="method">

They are still just as fun, though.

</aside>

```lox
// Store it in variables.
var someVariable = Breakfast;

// Pass it to functions.
someFunction(Breakfast);
```

Next, we need a way to create instances. We could add some sort of `new`
keyword, but to keep things simple, in Lox the class itself is a factory
function for instances. Call a class like a function, and it produces a new
instance of itself.

```lox
var breakfast = Breakfast();
print breakfast; // "Breakfast instance".
```

### Instantiation and initialization

Classes that only have behavior aren't super useful. The idea behind
object-oriented programming is encapsulating behavior *and state* together. To
do that, you need fields. Lox, like other dynamically typed languages, lets you
freely add properties onto objects.

```lox
breakfast.meat = "sausage";
breakfast.bread = "sourdough";
```

Assigning to a field creates it if it doesn't already exist.

If you want to access a field or method on the current object from within a
method, you use good old `this`.

```lox
class Breakfast {
  serve(who) {
    print "Enjoy your " + this.meat + " and " +
        this.bread + ", " + who + ".";
  }

  // ...
}
```

Part of encapsulating data within an object is ensuring the object is in a valid
state when it's created. To do that, you can define an initializer. If your
class has a method named `init()`, it is called automatically when the object is
constructed. Any parameters passed to the class are forwarded to its
initializer.

```lox
class Breakfast {
  init(meat, bread) {
    this.meat = meat;
    this.bread = bread;
  }

  // ...
}

var baconAndToast = Breakfast("bacon", "toast");
baconAndToast.serve("Dear Reader");
// "Enjoy your bacon and toast, Dear Reader."
```

### 继承

Every object-oriented language lets you not only define methods, but reuse them
across multiple classes or objects. For that, Lox supports single inheritance.
When you declare a class, you can specify a class that it inherits from using a less-than
<span name="less">(`<`)</span> operator.

```lox
class Brunch < Breakfast {
  drink() {
    print "How about a Bloody Mary?";
  }
}
```

<aside name="less">

Why the `<` operator? I didn't feel like introducing a new keyword like
`extends`. Lox doesn't use `:` for anything else so I didn't want to reserve
that either. Instead, I took a page from Ruby and used `<`.

If you know any type theory, you'll notice it's not a *totally* arbitrary
choice. Every instance of a subclass is an instance of its superclass too, but
there may be instances of the superclass that are not instances of the subclass.
That means, in the universe of objects, the set of subclass objects is smaller
than the superclass's set, though type nerds usually use `<:` for that relation.

</aside>

Here, Brunch is the **derived class** or **subclass**, and Breakfast is the
**base class** or **superclass**.

Every method defined in the superclass is also available to its subclasses.

```lox
var benedict = Brunch("ham", "English muffin");
benedict.serve("Noble Reader");
```

Even the `init()` method gets <span name="init">inherited</span>. In practice,
the subclass usually wants to define its own `init()` method too. But the
original one also needs to be called so that the superclass can maintain its
state. We need some way to call a method on our own *instance* without hitting
our own *methods*.

<aside name="init">

Lox is different from C++, Java, and C#, which do not inherit constructors, but
similar to Smalltalk and Ruby, which do.

</aside>

As in Java, you use `super` for that.

```lox
class Brunch < Breakfast {
  init(meat, bread, drink) {
    super.init(meat, bread);
    this.drink = drink;
  }
}
```

That's about it for object orientation. I tried to keep the feature set minimal.
The structure of the book did force one compromise. Lox is not a *pure*
object-oriented language. In a true OOP language every object is an instance of
a class, even primitive values like numbers and Booleans.

Because we don't implement classes until well after we start working with the
built-in types, that would have been hard. So values of primitive types aren't
real objects in the sense of being instances of classes. They don't have methods
or properties. If I were trying to make Lox a real language for real users, I
would fix that.

## 标准库

We're almost done. That's the whole language, so all that's left is the "core"
or "standard" library -- the set of functionality that is implemented directly
in the interpreter and that all user-defined behavior is built on top of.

This is the saddest part of Lox. Its standard library goes beyond minimalism and
veers close to outright nihilism. For the sample code in the book, we only need
to demonstrate that code is running and doing what it's supposed to do. For
that, we already have the built-in `print` statement.

Later, when we start optimizing, we'll write some benchmarks and see how long it
takes to execute code. That means we need to track time, so we'll define one
built-in function, `clock()`, that returns the number of seconds since the
program started.

And... that's it. I know, right? It's embarrassing.

If you wanted to turn Lox into an actual useful language, the very first thing
you should do is flesh this out. String manipulation, trigonometric functions,
file I/O, networking, heck, even *reading input from the user* would help. But we
don't need any of that for this book, and adding it wouldn't teach you anything
interesting, so I've left it out.

Don't worry, we'll have plenty of exciting stuff in the language itself to keep
us busy.

<div class="challenges">

## 挑战

1. Write some sample Lox programs and run them (you can use the implementations
   of Lox in [my repository][repo]). Try to come up with edge case behavior I
   didn't specify here. Does it do what you expect? Why or why not?

2. This informal introduction leaves a *lot* unspecified. List several open
   questions you have about the language's syntax and semantics. What do you
   think the answers should be?

3. Lox is a pretty tiny language. What features do you think it is missing that
   would make it annoying to use for real programs? (Aside from the standard
   library, of course.)

</div>

<div class="design-note">

## 语言设计笔记：表达式和语句

Lox has both expressions and statements. Some languages omit the latter.
Instead, they treat declarations and control flow constructs as expressions too.
These "everything is an expression" languages tend to have functional pedigrees
and include most Lisps, SML, Haskell, Ruby, and CoffeeScript.

To do that, for each "statement-like" construct in the language, you need to
decide what value it evaluates to. Some of those are easy:

*   An `if` expression evaluates to the result of whichever branch is chosen.
    Likewise, a `switch` or other multi-way branch evaluates to whichever case
    is picked.

*   A variable declaration evaluates to the value of the variable.

*   A block evaluates to the result of the last expression in the sequence.

Some get a little stranger. What should a loop evaluate to? A `while` loop in
CoffeeScript evaluates to an array containing each element that the body
evaluated to. That can be handy, or a waste of memory if you don't need the
array.

You also have to decide how these statement-like expressions compose with other
expressions -- you have to fit them into the grammar's precedence table. For
example, Ruby allows:

```ruby
puts 1 + if true then 2 else 3 end + 4
```

Is this what you'd expect? Is it what your *users* expect? How does this affect
how you design the syntax for your "statements"? Note that Ruby has an explicit
`end` to tell when the `if` expression is complete. Without it, the `+ 4` would
likely be parsed as part of the `else` clause.

Turning every statement into an expression forces you to answer a few hairy
questions like that. In return, you eliminate some redundancy. C has both blocks
for sequencing statements, and the comma operator for sequencing expressions. It
has both the `if` statement and the `?:` conditional operator. If everything was
an expression in C, you could unify each of those.

Languages that do away with statements usually also feature **implicit returns**
-- a function automatically returns whatever value its body evaluates to without
need for some explicit `return` syntax. For small functions and methods, this is
really handy. In fact, many languages that do have statements have added syntax
like `=>` to be able to define functions whose body is the result of evaluating
a single expression.

But making *all* functions work that way can be a little strange. If you aren't
careful, your function will leak a return value even if you only intend it to
produce a side effect. In practice, though, users of these languages don't find
it to be a problem.

For Lox, I gave it statements for prosaic reasons. I picked a C-like syntax for
familiarity's sake, and trying to take the existing C statement syntax and
interpret it like expressions gets weird pretty fast.

</div>
