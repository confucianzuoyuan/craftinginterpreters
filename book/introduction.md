> 童话故事超越了真实：不是因为童话故事告诉我们恶龙是存在的，而是因为童话故事告诉了我们恶龙是可以被击败的。
>
> <cite>G.K.切斯特顿</cite>

能够和大家一起踏上旅程，我非常激动。这是一本有关为编程语言实现解释器的书。同时也是一本有关如何设计一门有价值的编程语言的书。我非常希望在我投入到编程语言这个领域的初期就能碰到这样一本书。而这本书在我的<span
name="head">大脑中</span>中已经写了将近十年了。

<aside name="head">

这里要和我的家人和朋友们说声抱歉，抱歉这些年我是如此的不着调，如此的心不在焉（脑子里一直在写书）！

</aside>

在本书中，我们将会一步一步的为一门具有诸多特性的编程语言实现两个完整的解释器。这里我会假设本书的读者是初次涉猎编程语言这个领域。所以，构建一个完整的，可用的，运行速度快的编程语言所需要的每一个概念和每一行代码，本书都会详细讲解。

为了覆盖两个完整的解释器的实现，同时不会把读者劝退，书里面的内容相对于其他同类型的书籍，理论方面会偏弱一些。由于我们要构建解释器的每一个模块，所以我在构建每一个模块的时候，都会相对应的介绍模块背后的历史以及所涉及的概念。我会尽量让读者朋友熟悉所涉及的每一个术语，这样当你身处于一堆编程语言专家参加的<span name="party">鸡尾酒会</span>时，能够很好的融入进去。

<aside name="party">

有意思的是，这种场景我经历过很多次。他们中的一些人很能喝呢！

</aside>

我们主要的精力会花在将语言实现出来，跑起来。这并不是说理论是不重要的。对于编程语言理论这个领域，能够对编程语言的语法和语义进行严谨的且<span name="formal">形式化</span>的推理是非常重要的技能。但就我个人而言，通过实现一门语言来学习是一种最好的方式（learn by doing）。对我来说，读一本充满了抽象概念的书，很难真正的吸收它们（内涵龙书？哈哈）。但如果我能写一些代码，跑起来，调试一下，我就能真正*学会*这些知识。

<aside name="formal">

静态类型系统（Haskell，OCaml之类的语言）尤其需要严格的形式化推理。摆弄（hacking，我翻译成了摆弄）一个类型系统就好像是在做数学中的定理证明题。

类型系统和定理证明的相似性并不是巧合。在上个世纪的前半页，Haskell Curry和William Alvin Howard这两个人展示了类型系统和定理证明是一枚硬币的两面。[Curry-Howard同构][]。

[Curry-Howard同构]: https://en.wikipedia.org/wiki/Curry%E2%80%93Howard_correspondence

</aside>

下面是我对读者朋友的一点期望。读完这本书以后，希望你们对真正的编程语言是如何工作的有强烈的直觉力。希望你们后面再读其他更加理论的书籍时，很多概念已经深深的扎根在你们的大脑中了，深深的印在了你们的脑海里。

## 为什么要学习这些东西？

每一本介绍编译器的书都会有这一部分。我不太明白这些书为什么总是怀疑自己存在的必要性。比如鸟类学的书就不需要写“为什么要学习鸟类学”这种内容。它们通常假设读者是喜欢鸟儿的，然后就开始讲解了。

但是有关编程语言的书（编译器、编程语言理论）有一些不同。作为程序员，创建一门成功的、通用性的编程语言这个需求是非常罕见的。那些用的最多的编程语言（C、Java、Python等）既可以用在敞篷露营车，也可以用在大众公共汽车。这样的编程语言的设计者是最最顶尖的程序员。如果说想要进入这些人的行列是学习编程语言相关知识的*唯一*理由的话，那的确是没必要学的。幸好不是这样的，也就是是说每一个程序员都需要学习编程语言方面的知识。

### 小型编程语言到处都是

相对于每一门成功的通用型编程语言，都有数以千计的成功的“小语言”。我们以前叫它们“小语言”，随着术语的“通货膨胀”，我们越来越倾向于叫它们“领域特定语言”（DSL，Domain-Specific Languages）。这些小小的语言都是为了特定的任务准备的。比如应用程序的脚本语言，模板引擎（Jinja2之类的），标记语言（Markdown，Asciidoc之类的），以及配置文件等等。

<span name="little"></span><img src="image/introduction/little-languages.png" alt="A random selection of little languages." />

<aside name="little">

上面的图列举了一些你可能碰到过的小小语言。

</aside>

几乎每一个大型软件项目都需要很多种这样的小语言。正常情况来讲，我们最好去使用已有的编程语言，而不是自己造一个。自己造轮子要考虑的东西太多了：文档，调试器，对编辑器的支持，语法高亮，还有很多其他的坑。所以自己造轮子还是很费劲的。

但在一些非正常的情况下，你会发现你可能需要自己写一个解析器（parser）或者其他的工具。因为你想用的工具并不存在，只能自己写。即使你正在使用一些已有的工具，你可能也无法避免去调试这些工具，给这些工具修复错误（已有的工具所存在的bug很多！）。

### 构建编程语言是一种伟大的练习方式

长跑运动员有时候会在他们的脚踝上负重，或者去高海拔而空气稀薄的地方进行训练。当他们卸下脚踝上的负重，并且来到海拔低的地方长跑时，轻松的脚踝和丰富的含氧量会让他们跑的更快，跑的更远。

实现一门编程语言是对编程水平的一种很真实的测验（比做算法题好，哈哈）。因为需要写的代码非常复杂，性能也至关重要。你必须熟练掌握递归，动态数组，树，图和哈希表。你可能每天都在用哈希表，但你*真的*彻底理解哈希表吗？好办，在亲手制作了我们自己的编程语言之后，我保证你会彻底理解哈希表。

我会向你展示实现一个解释器并不像你想象的那样是一件非常恐怖的事情。尽管如此，这件事依然是一个很大的挑战。克服了这个大的挑战，你将会成为一个更加强大的程序员，也能在你每天的工作中，更加聪明的去使用那些数据结构和算法。

### 最后一个原因

最后一个原因对于我个人而言有点难以承认，因为这个原因隐藏在我的心底。当我还是个孩子的时候，我开始学习编程，编程语言有一些我觉得很神奇的东西。当我一个字母一个字母的敲出了一些BASIC程序时，我搞不明白BASIC*本身*是怎么实现出来的。

再后来，当我的大学朋友们谈起他们的编译器课程时，脸上浮现出的那种敬畏和恐惧，足以使我相信编程语言黑客是一种人类中的特殊物种——他们是一群魔术师，拥有操控某种密法的特权。

那是一幅诱人的<span name="image">图画</span>，但它也有黑暗的一面。*我*并没有自己是魔术师的感觉，所以我觉得我天生缺少一种特质，而只有拥有这种特质，才能进入魔术师的行列。尽管从我在学校的笔记本上写编程语言的关键字的时候开始，我就被编程语言深深的吸引。但过了很多年，我才能鼓起勇气去真正的尝试去学习它们。那种“魔术般”的特质，那种排他性，将*我*排除在外。

<aside name="image">

而编程语言领域的从业者们，也毫不犹豫的构建了这样一幅图画。两本有关编程语言的著名课本(SICP和龙书)将[恶龙][]和[魔术师][]作为了它们的封面。

[恶龙]: https://en.wikipedia.org/wiki/Compilers:_Principles,_Techniques,_and_Tools
[魔术师]: https://mitpress.mit.edu/sites/default/files/sicp/index.html

</aside>

而当我开始拼凑自己的小小的解释器时，我很快就发现，根本没有任何魔法。都是代码而已，而那些摆弄编程语言的人也都是人。

这里面*是*有一些你在编程语言这个领域之外没有碰到过的技术，也有一些部分有点难。但并不会比你碰到的其他困难更难解决。如果你被编程语言方面的东西所震慑，觉得这些东西很困难，我的这本书可以帮助你克服这种恐惧。希望你读完本书以后，能够比以前更加勇敢。

而且，谁知道呢？或许你就是下一门伟大的编程语言的创造者。毕竟需要有人做这样的事情。

## 这本书是如何组织的

这本书由三部分组成。你现在正在阅读的是第一部分。第一部分的章节，会为你做一个全书导览，然后教会大家一些编程语言从业者所常用的行话（术语），最后给大家介绍Lox这门语言，也就是我们即将实现的编程语言。

剩下的两部分，每一部分都会实现一个完整的Lox解释器。这两部分的章节安排的思路都是一样的。每一章负责讲解一个单独的语言特性，会教大家语言特性背后的概念，然后把这个语言特性实现出来。

通过大量的尝试和试错，我终于可以做到把这两个解释器的实现切分成合适长度的章节，并且做到了每一章的学习只依赖于前面的章节，而不需要后面章节的知识。从第一章开始，你就能跑起你所编写的程序。随着一章接一章的学习，你写的代码将会迅速成长为一门具有很多功能的完整的编程语言。

除了丰富，闪耀的英文文章外，各章还有其他一些令人愉快的内容：

### 代码

我们要做的事情是*制作*解释器，所以本书会包含真正的代码。书里面包含了每一行需要写的代码。我会告诉你每一个代码片段应该插入到你已经编写的代码中的具体位置。

很多其他有关编程语言和编程语言实现的书都会使用[Lex][]和<span name="yacc">[Yacc][]</span>，即所谓的**编译器的编译器（compiler-compilers）**，这样的工具。我们可以只写一些高层次的描述（比如词法和语法描述文件），这些工具就可以帮助我们产生一些源文件（词法分析器和语法分析器）。这些工具既有优点也有缺点，优点和缺点这两边都有很充分的理由——甚至有点宗教信仰的味道。

<aside name="yacc">

Yacc这个工具的输入是一个语法文件，输出是为编译器产生的源文件。所以Yacc有点像一个输出编译器的“编译器”，所以我们叫这类工具“编译器的编译器（compiler-compilers）”。

Yacc并非此类工具的首创，所以它的名字叫做“Yacc”——*Yet Another* Compiler-Compiler。后来又出现了一个相似的工具叫做[Bison][]。

<img src="image/introduction/yak.png" alt="A yak.">

[bison]: https://en.wikipedia.org/wiki/GNU_bison

</aside>

在本书中我们将不使用这类工具。我要保证任何魔术和困惑都没有藏身之处，所以我们会手写所有的功能。你会发现，其实手写所有功能并没有想象的那么难，而且这样做可以保证我们能够理解解释器实现中的每一行代码，彻底理解解释器的运行机制。

[lex]: https://en.wikipedia.org/wiki/Lex_(software)
[yacc]: https://en.wikipedia.org/wiki/Yacc

编写教学代码和“真实世界”的代码是有所不同的。所以书里面的代码风格并不是编写可维护的生产软件所采用的最佳实践。说的更明白一些，就是，我可能会删除`private`变量或者定义一个全局变量，这样做是为了代码更容易理解（设计模式用的越多，代码越难理解）。毕竟书本的大小比你平常用的IDE差远了，而且设计模式用的越多，代码量就越大，书也就越厚。

还有，书中的代码不会有很多注释。因为每一个代码片段都会有好几段文字去解释它。如果你要配合你的代码写一本书，那么建议你删去代码中的注释。否则的话，你可能会用很多很多`//`（排版也不好看，国内很多书都是这样）。

虽然本书包含了解释器实现的每一行代码，并详细讲解了每行代码的作用，但我并没有写如何编译和运行我们所写的解释器。我假设你有能力攒一个makefile文件来运行代码，或者用IDE来运行代码（毕竟我们现在都在写解释器了，这些能力还是要有的）。类似于makefile或者使用IDE的那种手把手的教程很快就会过时（因为IDE不断的升级，用法会改变），而我希望我的书像人头马XO一样能够长久保存。

### 代码片段

由于本书包含了实现解释器所要写的每一行代码，所以代码片段必须非常精确。还有，由于我想让我们写的程序即使在缺乏一些主要功能的情况下，依然能够跑起来，所以有时候我会编写一些临时代码保证程序能够运行，这些临时代码会在后面被其他代码片段替换。

下面是一个包含了所有要素的精确的代码片段的示例：

<div class="codehilite"><pre class="insert-before">
      default:
</pre><div class="source-file"><em>lox/Scanner.java</em><br>
in <em>scanToken</em>()<br>
replace 1 line</div>
<pre class="insert">
        <span class="k">if</span> (<span class="i">isDigit</span>(<span class="i">c</span>)) {
          <span class="i">number</span>();
        } <span class="k">else</span> {
          <span class="t">Lox</span>.<span class="i">error</span>(<span class="i">line</span>, <span class="s">&quot;Unexpected character.&quot;</span>);
        }
</pre><pre class="insert-after">
        break;
</pre></div>
<div class="source-file-narrow"><em>lox/Scanner.java</em>, in <em>scanToken</em>(), replace 1 line</div>

上面代码片段的中间，是我们要添加的新代码。新代码的上面和下面的阴影部分中的代码是我们之前编写的已经存在的代码。代码片段的附近还有一段文本来告诉你这段代码在哪个文件里面，以及在文件中的哪个位置去添加这段代码。如果这段文本写了“替换 _ 某些行”，意思就是你需要删除阴影中的之前写过的代码，然后替换成新的代码片段。

### 旁注

<span name="joke">旁注</span>包含了一些传记素描，历史背景的介绍，相关话题的链接以及探索其他相关领域的一些建议。旁注中的内容对于你理解书中的内容*不是必须的*，所以你不想看可以忽略掉它们。不过你要是真的忽略了它们，我可能会有点小伤心，哈哈。

<aside name="joke">

旁注中的大部分都是一些冷笑话和我业余画的一些小画。

</aside>

### 挑战

每一章的结尾部分都会留一些练习。不过不像平常我们读的课本，练习是为了复习和巩固你已经学习过的内容。我所留的练习题，是为了帮助你学习*更多*在我的书里没有的内容。这些练习会逼迫你走出我写的书所划定的范围，探索你自己的知识。会让你去研究其他的编程语言，去研究如何实现这些语言的特性。目的就是为了让你跳出舒适区。

<span name="warning">征服</span>了这些挑战，你会对编程语言这个领域有更加广泛的了解，也可能会有一点坑需要踩。你也可以忽略掉这些练习，待在舒适区里，这些都无所谓。

<aside name="warning">

一点提醒：这些挑战练习可能会要求你修改你写的代码。你最好复制一份到别的地方去修改。因为后面的章节都是假设你的代码是跟着章节正文内容走的，也就是没有做挑战练习的状态。

</aside>

### 语言设计笔记

大部分“编程语言”书籍都是编程语言的*实现*书籍。它们很少去讨论要实现的语言特性背后的*设计思路*，也就是为什么要设计这个语言特性。实现语言很有意思，因为语言是经过<span name="benchmark">严格定义</span>的。我们做程序员这一行的似乎都喜欢非黑即白的东西，所以可能会喜欢计算机这样由0和1组成的东西。

<aside name="benchmark">

很多从事编程语言这一领域的程序员都是像上面我说的那样工作的。首先浏览一下语言规范，然后过一段时间，这个语言的实现就完成了，性能基准测试结果也出炉了。

</aside>

从我个人的角度来看，这个世界只需要现在留下的这些<span name="fortran">FORTRAN 77</span>的各种实现了，不再需要新的实现了（因为各种实现已经够多了）。如果有一天，你发现自己正在设计一门*新的*语言。一旦你开始玩*这个*游戏，那么人的因素就会凸显出来。什么是人的因素呢？比如这门新语言好学不好学，这门语言应该有很多创新（例如Rust），还是应该让人们看上去觉得这门语言似曾相识（例如Golang），语言的语法是否需要注重可读性（例如Python），以及这门语言的使用者主要是哪一个群体。

<aside name="fortran">

希望你设计的新语言不要把打孔卡的孔的大小写进语法。

</aside>

以上所讲的这些东西都是你的语言能否成功的重要因素。我希望你设计的语言能够成功，所以在一些章节的末尾，我会写一段“语言设计笔记”，来讨论一下编程语言设计所考虑的一些人的因素。我并不是这方面的专家——我很怀疑谁真的是这方面的专家——所以就着一大撮盐吞下去吧。如果这些内容能够促进你的思考，我的目标也就达成了。

## 我们要实现的第一个解释器

我们将会编写我们的第一个解释器，jlox，使用<span name="lang">Java</span>来实现。我们这个实现主要聚焦于*概念*的理解。所以我们将会编写最简单，最干净的代码来实现Lox这门语言的各种语义。这会使得我们很容易理解一些基本的技术，也能让我们对编程语言是如何工作的有一个准确的了解。

<aside name="lang">

本书使用了Java和C语言，但是读者朋友们可以将代码用[其他语言][port]来实现。如果我用的语言正好你们不熟悉的话，可以看一下其他语言实现的版本。

[port]: https://github.com/munificent/craftinginterpreters/wiki/Lox-implementations

</aside>

Java这门语言非常适合用来实现解释器。首先，Java是一门高层语言，也就是说我们不需要关注很多底层的细节。但同时，Java这门语言写起来非常的清晰。Java可以隐藏底层复杂的各种细节。同时，由于Java是静态类型语言，所以我们能够清楚的看到我们使用的数据结构是什么，是数组，还是哈希表，还是链表等等（这点脚本语言做不到）。

我选择Java的另一个原因是Java是一门面向对象语言。这种编程范式兴趣于上世纪90年代，到现在已经成为了统治级的编程范式（每一个程序员都很了解）。所以阅读本书的读者朋友对代码组织成类和方法这种编程范式，应该已经很熟悉了。所以在编程范式上，我们就待在舒适区吧。

虽然很多学院派的编程语言研究人员有点看不上面向对象语言（他们更喜欢Haskell，Agda这种语言），但事实上，即使在编程语言这个领域，面向对象语言都有着非常广泛的使用。GCC和LLVM是用C++写的，大部分的JavaScript虚拟机也是用C++写的（例如V8）。面向对象语言是无处不在的，而通常某一门语言的编译器和各种编译工具都是由<span name="host">自己本身这门语言</span>编写的，比如X语言的编译器通常是由X语言编写的。

<aside name="host">

编译器的作用是读取由某一门语言编写的程序，然后将这些程序翻译成另一门语言并输出。所以我们可以使用任意一门编程语言来实现编译器，包括这个编译器本身要编译的语言，比如可以使用Java来编写Java的编译器，这个过程叫做**自举**。

举个例子，如果我们使用C语言编写了一个Go语言的编译器，那么首先，我们需要使用别的C语言编译器先编译我们写的代码（例如使用GCC来编译你写的C编译器代码），然后我们写的编译器代码被编译成了一个Go语言编译器，这时，我们就拥有了一个GCC编译出来的Go语言编译器。由于我们有了一个Go语言编译器，我们就可以使用Go语言来开发Go语言本身的编译器了，也可以不断的添加新特性了。而之前使用C语言写的编译器代码就可以抛弃掉了。这就叫做**自举**，就像一个人把自己提了起来。

<img src="image/introduction/bootstrap.png" alt="Fact: This is the primary mode of transportation of the American cowboy.">

</aside>

最后一个原因，Java实在是太流行了。这意味着读者朋友们大概率已经会写Java代码了，所以在阅读本书之前，你不需要太多的前置知识（不需要为了阅读本书而重新学习一门编程语言）。如果你对Java不是很熟悉，也不要着急。因为我会使用一个Java语言的最小子集（不会使用Java的所有特性）。为了使代码更紧凑，我会使用Java 7引入的钻石操作符特性，但这个特性也就是我使用的最高级的Java特性了。如果你学过其他面向对象编程语言，例如C#或者C++，那么阅读本书也会非常容易。

当阅读完第二部分的内容，我们就实现了一个简单的代码可读性很强的解释器了。这个解释器可能运行的不快，但绝对是正确的。尽管如此，我们的实现依赖了Java虚拟机的很多运行时特性。而我们非常想知道Java*本身*是如何实现这些运行时特性的，所以就有了第二个要实现的解释器。

## 我们要实现的第二个解释器

So in the next part, we start all over again, but this time in C. C is the
perfect language for understanding how an implementation *really* works, all the
way down to the bytes in memory and the code flowing through the CPU.

A big reason that we're using C is so I can show you things C is particularly
good at, but that *does* mean you'll need to be pretty comfortable with it. You
don't have to be the reincarnation of Dennis Ritchie, but you shouldn't be
spooked by pointers either.

If you aren't there yet, pick up an introductory book on C and chew through it,
then come back here when you're done. In return, you'll come away from this book
an even stronger C programmer. That's useful given how many language
implementations are written in C: Lua, CPython, and Ruby's MRI, to name a few.

In our C interpreter, <span name="clox">clox</span>, we are forced to implement
for ourselves all the things Java gave us for free. We'll write our own dynamic
array and hash table. We'll decide how objects are represented in memory, and
build a garbage collector to reclaim them.

<aside name="clox">

I pronounce the name like "sea-locks", but you can say it "clocks" or even
"clochs", where you pronounce the "x" like the Greeks do if it makes you happy.

</aside>

Our Java implementation was focused on being correct. Now that we have that
down, we'll turn to also being *fast*. Our C interpreter will contain a <span
name="compiler">compiler</span> that translates Lox to an efficient bytecode
representation (don't worry, I'll get into what that means soon), which it then
executes. This is the same technique used by implementations of Lua, Python,
Ruby, PHP, and many other successful languages.

<aside name="compiler">

Did you think this was just an interpreter book? It's a compiler book as well.
Two for the price of one!

</aside>

We'll even try our hand at benchmarking and optimization. By the end, we'll have
a robust, accurate, fast interpreter for our language, able to keep up with
other professional caliber implementations out there. Not bad for one book and a
few thousand lines of code.

<div class="challenges">

## Challenges

1.  There are at least six domain-specific languages used in the [little system
    I cobbled together][repo] to write and publish this book. What are they?

1.  Get a "Hello, world!" program written and running in Java. Set up whatever
    makefiles or IDE projects you need to get it working. If you have a
    debugger, get comfortable with it and step through your program as it runs.

1.  Do the same thing for C. To get some practice with pointers, define a
    [doubly linked list][] of heap-allocated strings. Write functions to insert,
    find, and delete items from it. Test them.

[repo]: https://github.com/munificent/craftinginterpreters
[doubly linked list]: https://en.wikipedia.org/wiki/Doubly_linked_list

</div>

<div class="design-note">

## Design Note: What's in a Name?

One of the hardest challenges in writing this book was coming up with a name for
the language it implements. I went through *pages* of candidates before I found
one that worked. As you'll discover on the first day you start building your own
language, naming is deviously hard. A good name satisfies a few criteria:

1.  **It isn't in use.** You can run into all sorts of trouble, legal and
    social, if you inadvertently step on someone else's name.

2.  **It's easy to pronounce.** If things go well, hordes of people will be
    saying and writing your language's name. Anything longer than a couple of
    syllables or a handful of letters will annoy them to no end.

3.  **It's distinct enough to search for.** People will Google your language's
    name to learn about it, so you want a word that's rare enough that most
    results point to your docs. Though, with the amount of AI search engines are
    packing today, that's less of an issue. Still, you won't be doing your users
    any favors if you name your language "for".

4.  **It doesn't have negative connotations across a number of cultures.** This
    is hard to be on guard for, but it's worth considering. The designer of
    Nimrod ended up renaming his language to "Nim" because too many people
    remember that Bugs Bunny used "Nimrod" as an insult. (Bugs was using it
    ironically.)

If your potential name makes it through that gauntlet, keep it. Don't get hung
up on trying to find an appellation that captures the quintessence of your
language. If the names of the world's other successful languages teach us
anything, it's that the name doesn't matter much. All you need is a reasonably
unique token.

</div>
