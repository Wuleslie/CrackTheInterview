### Objective-C 消息机制

#### objc_msgSend

在Objective-C中，如果向某对象传递消息，那就会使用动态绑定机制来决定需要调用的方法。在底层，所有方法都是普通的C语言函数，然而对象收到消息之后，究竟该调用哪个方法则完全于运行期决定，甚至可以在程序运行时改变，这些特性使得Objective-C成为一门真正的动态语言。

`id result = [someObject messageName:parameter];`

在上面👆的代码中，someObject叫做“接受者”（receiver），messageName叫做selector，selector与参数合起来称为“消息”（message）。编译器看到此消息后，将其转换为一条标准的C语言函数调用，所调用的函数乃是消息传递机制中的核心函数，叫做objc_msgSend，其“原型”（prototype）如下：

`void objc_msgSend(id self, SEL cmd, ...)`

这是个“参数个数可变函数”（variadic function），能接受两个及以上的参数。编译器会把刚才那个例子中的消息转换为如下函数：

`id result = objc_msgSend(someObject, @selector(messageName:), parameter);`

