### 理解“属性”--property

**@property = ivar + getter + setter;**

“属性” (property)有两大概念：ivar（实例变量）、存取方法（access method ＝ getter + setter）。

“属性“（property）是Objective-C的一项特性，用于封装对象中的数据。 Objective-C 对象通常会把其所需要的数据保存为各种实例变量。实例变量一般通过“存取方法”(access method)来访问。其中，“获取方法” (getter)用于读取变量值，而“设置方法” (setter)用于写入变量值。这个概念已经定型，并且经由“属性”这一特性而成为Objective-C 2.0的一部分。 ***开发者可以令编译器自动编写与属性有关的存取方法。此特性引入了新的“点语法”（dot syntax）***，使开发者可以更为容易地依照类对象来访问存放于其中的数据。而在正规的 Objective-C 编码风格中，存取方法有着严格的命名规范。 正因为有了这种严格的命名规范，所以 Objective-C 这门语言才能根据名称自动创建出存取方法。

#### **@synthesize和@dynamic**

1）@property有两个对应的词，一个是@synthesize，一个是@dynamic。如果@synthesize和@dynamic都没写，那么默认的就是@syntheszie var = _var;

2）@synthesize的语义是如果你没有手动实现setter方法和getter方法，那么编译器会自动为你加上这两个方法。 

3）@dynamic告诉编译器：属性的setter与getter方法由用户自己实现，不自动生成。（当然对于readonly的属性只需提供getter即可）。假如一个属性被声明为@dynamic var，然后你没有提供@setter方法和@getter方法，编译的时候没问题，但是当程序运行到instance.var = someVar，由于缺setter方法会导致程序崩溃；或者当运行到 someVar = var时，由于缺getter方法同样会导致崩溃。编译时没问题，运行时才执行相应的方法，这就是所谓的动态绑定。

在有了自动合成属性实例变量之后，@synthesize还有哪些使用场景？

回答这个问题前，我们要搞清楚一个问题，什么情况下不会autosynthesis（自动合成）？

- 同时重写了setter和getter时
- 重写了只读属性的getter时
- 使用了@dynamic时
- 在 @protocol 中定义的所有属性
- 在 category 中定义的所有属性
- 重载的属性

当你在子类中重载了父类中的属性，你必须使用@synthesize来手动合成ivar。

除了后三条，对其他几个我们可以总结出一个规律：当你想手动管理@property的所有内容时，你就会尝试通过实现@property的所有“存取方法”（the accessor methods）或者使用@dynamic来达到这个目的，这时编译器就会认为你打算手动管理@property，于是编译器就禁用了autosynthesis（自动合成）。

####  属性的各种特质（attribute）

分为四个方面：**原子性、读/写权限、内存管理语义/所有权修饰符、存取方法名**

**原子性**：默认情况下，在编译器所合成的方法会通过锁定机制确保其原子性（atomicity）。如果属性具备nonatomic特质，则不使用同步锁。尽管没有名为“atomic”的特质（如果某属性不具备nonatomic特质，那它就是atomic），但是仍可在属性特质中写明这一点，编译器不会报错。**默认是atomic。**

**读写权限**：readwrite/readonly，默认readwrite。

**存取方法名**：用来指定存取方法的方法名。

**内存管理语义**: assign/strong/weak/unsafe_unretained/copy。

assign只会执行针对“标量类型”（scalar type，例如NSInteger、CGFloat等）的简单赋值操作，不更改所赋新值的引用计数，也不改变旧值的引用计数。unsafe_unretained语义和assign相同，但是它适用于对象类型（object type），当它修饰的对象遭到销毁时，属性值不会自动清空（unsafe）。unsafe_unretained只能修饰对象，不能修饰标量类型，而assign两者皆可修饰（但可能会有问题）。

ARC下，不显式指定任何属性特质时：

- 对应基本数据类型默认是（atomic, readwrite, assign）

- 对于普通的OC对象默认是（atomic, readwrite, strong）

Q1: 如果OC对象使用assign修饰会怎样？

首先，用assign修饰OC对象，编译不会报错，但会有警告*Assigning retained object to unsafe property; object will be released after assignment.* assign是指针赋值，被assign修饰的对象, 在释放之后，指针的地址还是存在的，也就是说指针并没有被置为nil，造成野指针。而基本数据类型一般分配在栈上，栈的内存会由系统自己自动处理，不会造成野指针。

Q2：@property(nonatomatic, copy) NSMutableArray *array; 有什么问题 ？

用copy修饰，NSMutableArray浅拷贝，将会变成NSArray，对其进行可变操作将会崩溃。