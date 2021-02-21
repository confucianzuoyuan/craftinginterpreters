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

现在是时候澄清一些<span name="define">术语</span>了。很多人觉得"parameter"和"argument"是可以互换的术语，在很多情况下，它们确实指的是相同的意思。接下来我们会花很多的时间来细致的区分一些术语的语义，把我们对术语的运用打磨的精细一些。从现在就开始吧：

*   一个**参数（argument）**是当我们调用函数时，传给函数的实际存在的参数。所以一个函数*调用*一个*参数*列表。我们经常听到叫这种参数是**实在参数（actual parameter）**。（“实在参数”这里，我使用了龙书里的翻译。）

*   一个**参数（parameter）**是一个变量，这个变量负责在函数体中保存实际参数（argument）的值。所以，一个函数*声明*中会有一个*参数*列表。我们经常听到叫这种参数是**形式参数（formal parameters）**或者**形参（formals）**。

<aside name="define">

说到术语，一些像C语言这样的静态类型语言，会在函数的*声明*和*定义*之间作区分。一个声明将函数的类型和函数的名字绑定在了一起。这样当我们调用这个函数的时候，不需要定义好函数体就可以进行类型检查。一个定义是指不仅仅声明了函数的类型（输入参数类型和返回值类型就是一个函数的类型），还定义了函数体。所以这个函数就可以进行编译了。

由于Lox是动态类型语言，所以这个区分就没什么意义了。在动态类型语言中，一个函数的定义会完整的包含函数体的代码。

</aside>

函数体通常是一个**块**（也就是花括号括起来的）。在函数体中，你可以使用`return`语句来返回值。

```lox
fun returnSum(a, b) {
  return a + b;
}
```

如果程序执行到了块的末尾都没碰到`return`语句，那么函数体将会<span name="sneaky">隐式的</span>返回`nil`值。

<aside name="sneaky">

看，我和你说过吧，`nil`不知道什么时候就会在我们看不见的地方冒出来。

</aside>

### 闭包

在Lox中，函数是*一等公民*，意思是函数是真正的值，我们可以获取函数的引用，可以将函数作为值存在变量中，还可以当作实在参数传入函数。看一下下面的例子：

```lox
fun addPair(a, b) {
  return a + b;
}

fun identity(a) {
  return a;
}

print identity(addPair)(1, 2); // Prints "3".
```

因为函数声明是语句，所以我们可以在函数体内部来声明另一个函数。

```lox
fun outerFunction() {
  fun localFunction() {
    print "I'm local!";
  }

  localFunction();
}
```

如果我们将局部函数（函数里面的定义的函数），作为一等公民的函数，以及块作用域结合起来使用，我们会得到以下有趣的代码：

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

在这里，`inner()`可以访问`inner()`函数体外包围着`inner()`的函数中声明的局部变量，也就是`inner()`可以访问`returnFunction()`中定义的局部变量`outside`。这是合法的吗？当然是合法的，因为很多语言都从Lisp语言中借鉴了这一特性（内层函数可以访问外层作用域）。

为了使这个特性能够工作，`inner()`函数必须“持有”外部变量的引用，那么即使外部函数返回以后，内部函数还是可以使用外部变量。我们把内部函数使用外部变量的这种特性叫做<span name="closure">**闭包（closures）**</span>。现在，这个术语一般用来指*任意*的作为一等公民的函数，尽管这些一等公民函数并没有持有任何外部作用域的变量。

<aside name="closure">

皮特·兰丁发明了术语“闭包”。他不止发明了闭包，编程语言中有一半的术语都是他发明的。大部分术语来自那篇他写的不可思议的论文，"[The Next 700 Programming Languages][svh]"。

[svh]: https://homepages.inf.ed.ac.uk/wadler/papers/papers-we-love/landin-next-700.pdf

为了实现这样的函数，你必须创建一种数据结构，这种数据结构将函数的代码以及需要持有的外部变量打包在了一起。他把这种特性叫做“闭包”是因为内层函数持有外部变量还把外部变量*包*了起来。

</aside>

可以想像的到，实现闭包特性将会增加复杂性。因为我们无法像以前那样假定变量的作用域严格按照栈这种数据结构来工作，也就是当函数返回时，局部变量直接弹出栈然后不存在了。我们需要花一些时间学习来使闭包能够正确并且高效的工作。

## 类

由于Lox是动态类型，拥有词法作用域（lexical scope）或者叫块作用域（block scope），以及闭包等特性。所以到现在看起来Lox是一个函数式编程语言。但是你将会看到，Lox也将会是一门面向对象编程语言。这两种编程范式都需要很多工作量来实现，所以我觉得很值得都实现一下。

由于类（或者说面向对象特性）深受抨击，所以我先来解释一下为什么我要把面向对象特性做进Lox语言中。实际上就是需要回答两个问题：

### 为什么任何语言都想成为一门面向对象语言？

现在像Java这样的面向对象语言已经太稀松平常了，再去热爱Java这样的语言就显得不是很酷了。那我们为什么要把Lox做成一门*新的*面向对象语言？这不是像在八音轨的磁带上发行音乐吗？

的确，在上世纪90年代，那种“无时不在的继承”诞生了很多怪物般的类层次结构，但是**面向对象编程（object-oriented programming）** （**OOP**）仍然是非常漂亮的编程范式。无数的成功代码都是使用OOP语言编写的，也诞生了无数成功的应用。当今大部分的程序员都在使用面向对象语言。所以面向对象语言不可能*那么*差劲。

特别是对于动态类型语言来说，**对象**是一种非常方便好用的特性。我们需要*某些*方式来定义一些复杂的数据结构来将一些东西捆绑到一起。

如果我们能在对象里面再挂上一些方法，那我们就不用为了区分各种函数，而在函数的前面加上前缀了。如果没有对象把函数包起来，那么如果使用相似的函数来操纵不同的数据结构时，我们就需要为函数加前缀。举个例子，在Racket语言中，我们需要这样来命名，例如`hash-copy`用来拷贝一个哈希表，`vector-copy`用来拷贝一个向量，由于加了前缀，所以这两个方法虽然都是拷贝作用，但不会互相踩踏。而如果我们把`copy`方法放进不同的对象之内，那么互相踩踏的问题就迎刃而解了。说白了，就是不用费尽心思为函数起名字了。

### 为什么Lox是一门面向对象语言？

我可以论述对象这一特性是很好的特性，但这些论述超出了本书的范围。大部分的编程语言理论方面的书籍，尤其是那些试图去实现一门完整语言的书，都把对象这一特性排除在外了。对我来说，这其实意味着这个编程语言这一主题并没有得到很好的讲解和覆盖。这些书忽略掉一个如此广泛使用的编程范式，让我很伤心。

鉴于我们中的大部分程序员几乎整天都在*使用*OOP语言，所以看起来应该有一些文档来教我们如何去*制作*一门面向对象编程语言。你将会看到，面向对象特性的实现非常有趣。不像你想的那么难，当然也没有那么简单。

### 类还是原型

当我们要实现对象这种特性时，有两种方法来实现，[类（classes）][]和[原型（prototypes）][]。我们首选类这种实现方式，这大概归功于C++、Java、C#以及类似的语言都是使用的类这种实现方式。而原型这种实现方式几乎被遗忘在了历史的角落，直到JavaScript统治世界以后，原型才又回到了人们的视野。

[类（classes）]: https://en.wikipedia.org/wiki/Class-based_programming
[原型（prototypes）]: https://en.wikipedia.org/wiki/Prototype-based_programming

在基于类的语言中，有两个核心概念：实例（instances）和类（classes）。实例会存储每个对象的状态，并拥有一个指向本实例的引用。类包含了方法以及继承链。想要在一个实例上面调用一个方法，我们首先需要查找实例所属的类，然后在所属的类中发现需要调用的方法：

<img src="image/the-lox-language/class-lookup.png" alt="How fields and methods are looked up on classes and instances" />

基于原型的语言将这两种概念<span name="blurry">融合</span>了起来。也就是只有对象——没有类——每一个单独的对象都可以拥有自己的状态和方法。一个对象可以继承自另一个对象（在基于原型的语言中一般把“继承”叫做“代理到（delegate to）”）。

<aside name="blurry">

在实践中，基于类和基于原型的边界有点模糊。JavaScript的“构造器函数（constructor function）”的概念可以用来构造类式（class-like）的对象，但会[让你很难受][js new]。同时，基于类的Ruby语言，也可以轻松加愉快的在单个的实例中添加方法。

[js new]: http://gameprogrammingpatterns.com/prototype.html#what-about-javascript

</aside>

<img src="image/the-lox-language/prototype-lookup.png" alt="How fields and methods are looked up in a prototypal system" />

这就意味着在某种程度上，基于原型的语言其实比基于类的语言更加的底层。基于原型的语言比基于类的语言更加容易实现对象特性，因为基于原型很简单。同时，基于原型的语言可以实现很多种不常见的模式，而基于类要实现这些不常见的模式就比较困难了。

我研究过*很多*基于原型的语言——包括[我自己的一些设计][finch]。既然原型是如此强大的特性，那你知道人们用它来干啥吗？...人们用原型来实现类。

[finch]: http://finch.stuffwithstuff.com/

我不知道这是*为什么*，但人们的确更加喜欢基于类的特性（而不是基于原型的特性）。原型在语言里更加简单，更加容易使用，但他们存在的目的似乎是将问题的复杂性<span name="waterbed">推</span>给了用户。所以，在Lox中我们直接把这个复杂的问题给解决掉。

<aside name="waterbed">

拉里·沃尔，Perl语言的发明人把这个现象叫做“[水床理论][]”。也就是说一些复杂性是基本的，无法被消除的，它就在那里。按下葫芦起了瓢。

[水床理论]: http://wiki.c2.com/?WaterbedTheory

基于原型的语言并没有将类要解决的问题的复杂性消除，原型只是将复杂性问题的解决推给了用户而已，也就是说用户还得需要基于原型来开发出一套基于类的元编程库。比如JavaScript的ES5版本向ES6版本的升级，就加入了类的机制。

</aside>

### Lox中的类

已经扯得够多了，让我们现在来看一下Lox中的类如何使用吧。但大部分语言中，类机制都会有一堆特性。我从其中调了一些最亮眼的特性加入到Lox中。我们可以像下面的代码那样定义一个类和类中的方法：

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

类的身体（花括号括着的那部分）里面包含了类的方法。这些方法看着就像函数声明一样，只是没有`fun` <span name="method">关键字</span>而已。当类的声明执行完毕，Lox将会创建一个类对象，然后将这个对象保存在一个和类名一样的变量名的变量中。就像函数一样，类在Lox中也是一等公民。

<aside name="method">

fun在英文里还有好玩儿的意思。

</aside>

```lox
// Store it in variables.
var someVariable = Breakfast;

// Pass it to functions.
someFunction(Breakfast);
```

接下来，我们需要一种方式来对类进行实例化。我们可以使用类似于`new`这样的关键字，但为了将实现简化，在Lox中，类本身就是一个产生实例的工厂函数。调用一个类就像调用一个函数一样，可以产生一个当前类的新的实例。

```lox
var breakfast = Breakfast();
print breakfast; // "Breakfast instance".
```

### 实例化和初始化

类中如果只有方法的话，就不是太有用了。面向对象编程思想的精髓在于将行为和*状态*打包在了一起。为了在类中引入状态，我们需要字段（fields）。Lox像其他动态类型语言一样，可以让我们给对象添加属性。

```lox
breakfast.meat = "sausage";
breakfast.bread = "sourdough";
```

当我们给一个对象的字段赋值时，如果不存在这个字段，会把这个字段创建出来。

如果你想在当前对象的一个方法里面访问当前对象的字段或者方法，那么可以使用`this`关键字。

```lox
class Breakfast {
  serve(who) {
    print "Enjoy your " + this.meat + " and " +
        this.bread + ", " + who + ".";
  }

  // ...
}
```

在对象里打包数据，需要保证当这个对象被创建以后，是处于一个合法存在的状态。所以我们需要一个初始化器。如果你的类里面有一个名叫`init()`的方法，那么当对象实例化的时候，会自动调用`init()`方法。任何传入类的参数，都会被推送到初始化器当中。

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

每一门面向对象编程语言都不仅仅只是能定义方法，还需要在不同的类和对象中可以复用这些方法。所以，Lox支持单继承。当你定义了一个类，你还可以指定另一个类来继承这个类，我们这里使用了小于号<span name="less">`<`</span>来表示继承关系。

```lox
class Brunch < Breakfast {
  drink() {
    print "How about a Bloody Mary?";
  }
}
```

<aside name="less">

为什么使用`<`运算符？因为我不想引入想`extends`这样的新的关键字。由于Lox并没有使用过`:`冒号，所以这里也不想使用。最终我选择了Ruby中表示继承的符号，也就是小于号`<`。

如果你懂一点类型系统理论，你会发现继承符号的选择并不是一个完全随意的事情。每一个子类的实例同时也是超类的实例。但是超类的实例不一定是子类的实例。这就意味着，在对象的世界里，子类的对象所组成的集合比超类的对象所组成的集合要小，当然，玩类型系统的黑客喜欢用`<:`表示继承关系。

</aside>

在这里，上午餐（Brunch）是**派生类（derived class）**或者**子类（subclass）**，而早餐（Breakfast）是**基类（base class）**或者**超类（superclass）**。

每一个在超类中定义的方法，同样可以在子类中使用。

```lox
var benedict = Brunch("ham", "English muffin");
benedict.serve("Noble Reader");
```

即使是`init()`方法也可以被<span name="init">继承</span>。在实践中，子类通常也会定义它自己的`init()`方法。但是超类的`init()`方法也需要调用啊，这样超类就可以维护它自己的状态。我们需要在子类实例化的时候来调用超类的`init()`方法，但又不会破坏子类的`init()`方法。

<aside name="init">

Lox不同于C++，Java和C#，这些语言并不会继承超类的构造器。Lox像Smalltalk和Ruby一样，子类会继承超类的构造器。

</aside>

在Java中，我们使用`super`关键字来初始化超类。

```lox
class Brunch < Breakfast {
  init(meat, bread, drink) {
    super.init(meat, bread);
    this.drink = drink;
  }
}
```

有关Lox的面向对象特性就已经大概说完了。我尽量让Lox的面向对象特性简单。Lox并不是一门*纯*面向对象语言。在一个真正的OOP语言中，每一个对象都是某个类的实例，即使是像数（numbers）和布尔值（Booleans）这样的原始数据类型也是某个类的实例。这就是所谓的一切皆对象。

直到我们开始实现内建类型（built-in types），我们才会去实现类这一特性。所以原始数据类型并不是真正的对象，也就是说不是某些类的实例化。所以原始数据类型没有方法也没有属性。如果我想把Lox制作成供程序员使用的工业编程语言，我会把这个问题修复掉。

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
