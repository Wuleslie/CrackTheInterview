# iOS内存管理

[TOC]

### iOS内存管理的思考方式

1、自己生成的对象，自己持有。（alloc、new、copy、mutableCopy）
2、非自己生成的对象，自己也能持有。
3、不再需要自己持有的对象时释放。
4、非自己持有的对象无法释放。

#### 自己生成的对象，自己持有

使用以下名称开头的方法名意味着自己生成的对象只有自己持有：

- alloc
- new
- copy
- mutableCopy

所以，开发中要注意命名规范，使用这些名称开头的方法须返回对象。

#### 非自己生成的对象，自己也能持有

用alloc/new/copy/mutableCopy以外的方法取得的对象，因为非自己生成并持有，所以不是该对象的持有者。使用retain方法可以持有对象。

```objective-c
// 取得非自己生成并持有的对象
id obj = [NSMutableArray array];
// 取得的对象存在，但自己不持有对象
[obj retain];
// 自己持有了对象
```

#### 不再需要自己持有的对象时释放

```objective-c
id obj = [[NSObject alloc] init];
[obj release];
 
id array = [NSArray array];
[array retain];
[array release];
```

另外，autorelease方法，可以使取得的对象存在，但自己不持有，对象在超出指定的生存范围时能够自动并正确地释放。

```objective-c
- (id)object 
{
    id obj = [[NSObject alloc] init];
    [obj autorelease];
    return obj;
}
```

#### 无法释放非自己持有的对象

```objective-c
id obj = [[NSObject alloc] init];
[obj release];
// 释放之后再次释放已非自己持有的对象，会导致crash
[obj release];
```

### alloc/retain/release/dealloc 实现

包含NSObject的Foundation框架并没有公开，但作为Cocoa框架的互换框架，GNUstep的实现可以帮助我们理解苹果Cocoa的实现。

> GNUstep/modules/core/base/Source/NSObject.m alloc

```objective-c
+ (id)alloc 
{
    return [self allocWithZone: NSDefaultMallocZone()];
}

+ (id)allocWithZone: (NSZone *)z
{
    return NSAllocateObject(self, 0, z);
}
```

通过allocWithZone: 类方法调用NSAllocateObject函数分配了对象。下面看看NSAllocateObject函数。

> GNUstep/modules/core/base/Source/NSObject.m NSAllocateObject

```objective-c
struct obj_layout {
    NSUInteger retained;
};

inline id NSAllocateObject(Class aClass, NSUInteger extraBytes, NSZone *zone)
{
    int zise = 计算容纳对象所需内存大小;
    id new = NSZoneMalloc(zone, size);
    memset(new, 0, size);
    new = (id)&((struct objc_layout *)new)[1];
}
```

NSAllocateObject函数通过调用NSZoneMalloc函数来分配存放对象所需的内存空间，之后将该内存空间置0，最后返回作为对象而使用的指针。

> NSDefaultMallocZone, NSZoneMalloc等名称中包含的NSZone是什么呢？它是为防止内存碎片而引入的结构。对内存分配的区域本身进行多重化管理，根据使用对象的目的、对象的大小分配内存，从而提高了内存管理的效率。

alloc类方法用struct obj_layout中的retained整数来保存引用计数，并将其写入对象内存头部，该对象内存块全部置0后返回。调用retain方法即是将retainCount加1；而调用release则将retainCount减1，并判断当前retainCount是否为0，为0就调用dealloc方法销毁对象。

**GNUstep将引用计数保存在对象占用内存块头部的变量中，而苹果的实现，则是保存在引用计数表的记录中**。

通过内存块头部管理引用计数的好处如下：

- 少量代码即可完成
- 能够统一管理引用计数所用内存块与对象所用内存块

通过引用计数表管理引用计数的好处如下：

- 对象用内存块的分配无需考虑内存块头部。
- **引用计数表各记录中存在内存块地址，可从各个记录追溯到各对象的内存块。**

这里的第二个好处在调试时举足轻重，即使出现故障导致对象占用的内存块损坏，但只要引用计数表没有被破坏，就能够确认各内存块的位置。另外，在利用工具检测内存泄漏时，引用计数表的各记录也有助于检测各对象的持有者是否存在。

### autorelease 实现

顾名思义，autorelease就是自动释放。这看上去很像ARC，但实际上它是更类似于C语言中自动变量（局部变量）的特性。

```objective-c
NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
id obj = [[NSObject alloc] init];
[obj autorelease];
[pool drain];
```

上述代码里的“[pool drain]”等同于"[obj release]".

在Cocoa框架中，相当于程序主循环的NSRunLoop或者在其他程序可运行的地方，对NSAutoreleasePool对象进行生成、持有和废弃处理。因此，应用程序开发者不一定非得使用NSAutoreleasePool对象进行开发工作。

但是，大量产生autorelease的对象时，只要不废弃NSAutoreleasePool对象，那么生成的对象就不能被释放，因此有时会产生内存不足的现象。典型的例子就是读入大量图像的同时改变其尺寸。此种情况下，有必要在适当的地方生成、持有或废弃NSAutoreleasePool对象。

```objective-c
for (int i = 0; i < imageCount; ++i) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    /**
     读入图像，大量产生autorelease对象
    */
    [pool drain]; // autorelease的对象被一起release
}
```

那么，autorelese是怎样实现的呢？同样，参考下GNUstep的源代码实现：

> GNUstep/modules/core/base/Source/NSObject.m autorelease

```objective-c
- (id)autorelease
{
    [NSAutoreleasePool addObject:self];
}
```

autorelease实例方法的本质就是调用NSAutoreleasePool对象的addObject类方法。而在苹果的实现中，NSAutoreleasePool的本质是一个AutoreleasePoolPage结构体对象，是一个栈结构存储的页，每一个AutoreleasePoolPage都是以双向链表的形式连接。

### weak 实现

__weak修饰符提供的功能：

- 若附有__weak修饰符的变量所引用的对象被废弃，则将nil赋值给该变量；
- 使用附有__weak修饰符的变量，即是使用注册到autoreleasepool中的对象。

下面先来看看第一条的实现。

```objective-c
{
    id __weak obj1 = obj;
}
```

假设变量obj附加__strong修饰符且对象被赋值。

```objective-c
/* 编译器的模拟代码*/
id obj1;
objc_initWeak(&obj1, obj);
objc_destroyWeak(&obj1);
```

通过objc_initWeak函数初始化附有__weak修饰符的变量，在变量作用域结束时通过objc_destroyWeak函数释放该变量。

objc_initWeak函数将附有__weak修饰符的变量初始化为0后，会将赋值的对象作为参数调用objc_storeWeak函数。

```objc
obj1 = 0;
objc_storeWeak(&obj1, obj);
```

objc_destroyWeak函数则将0作为参数调用objc_storeWeak函数。即前面的代码等同于如下代码：

```objc
/* 编译器的模拟代码*/
id obj1;
obj1 = 0;
objc_storeWeak(&obj1, obj);
objc_storeWeak(&obj1, 0);
```

objc_storeWeak函数将第二参数的赋值对象的地址作为键值，将第一参数的附有__weak修饰符的变量的地址注册中。如果第二参数为0，则把变量的地址从weak表中删除。

weak表与引用计数表相同，作为散列表被实现。如果使用weak表，将废弃对象的地址作为键值进行检索，就能高速地获取对应的附有__weak修饰符的变量的地址。另外，由于一个对象可同时赋值给多个附有weak修饰符的变量中，所以对于一个键值，可注册多个变量的地址。

释放对象时，废弃谁都不持有的对象的同时，程序的动作是怎样的呢？下面我们来跟踪观察。对象将通过objc_release函数释放。

1. objc_release
2. 因为引用计数为0所以执行dealloc
3. _objc_rootDealloc
4. object_dispose
5. objc_destructInstance
6. objc_clear_deallocating

对像被废弃时最后调用的objc_clear_deallocating函数的动作如下：

1. 从weak表中获取废弃对象的地址作为键值的记录。
2. 将包含在记录中的所有附有__weak修饰符的变量的地址，赋值为nil。
3. 从weak表中删除该记录。
4. 从引用计数表中删除废弃对象的地址为键值的记录。

从此可见，如果大量使用附有__weak修饰符的变量，则会消耗相应的CPU资源。良策是只在需要避免循环引用时使用weak修饰符。

接着我们来看看第二条---*使用附有__weak修饰符的变量，即是使用注册到autoreleasepool中的对象*的实现。

```objective-c
{
    id __weak obj1 = obj;
    NSLog(@"%@", obj1);
}
```

该源代码可转换为如下形式：

```objective-c
/* 编译器的模拟代码*/
id obj1;
objc_initWeak(&obj1, obj);
id temp = objc_loadWeakRetained(&obj1);
objc_autorelease(tmp);
NSLog(@"%@", tmp);
objc_destroyWeak(&obj1);
```

与被赋值时相比，在使用附有__weak修饰符变量的情形下，增加了对objc_loadWeakRetained函数和objc_autorelease函数的调用。这些函数的动作如下：

1. objc_loadWeakRetained函数取出附有__weak修饰符变量所引用的对象并retain。
2. objc_autorelease函数将对象注册到autoreleasepool中。

由此可知，因为附有__weak修饰符变量所引用的对象像这样被注册到autoreleasepool中，所以在@autorelesepool块结束之前都可以放心使用。但是，如果大量地使用附有weak修饰符的变量，注册到autoreleasepool的对象也会大量地增加，因此在使用附有weak修饰符的变量时，最好先暂时赋值给附有strong修饰符的变量后再使用。

比如，以下源代码使用了5次附有__weak修饰符的变量o。

```objective-c
{
    id __weak o = obj;
    NSLog(@"1 %@", o);
    NSLog(@"2 %@", o);
    NSLog(@"3 %@", o);
    NSLog(@"4 %@", o);
    NSLog(@"5 %@", o);
}
```

相应地，变量o所赋值的对象也就注册到autoreleasepool5次。将附有__weak修饰符的变量o赋值给附有strong修饰符的变量后再使用可以避免此类问题。

```objective-c
{
    id __weak o = obj;
    id tmp = o;
    NSLog(@"1 %@", o);
    NSLog(@"2 %@", o);
    NSLog(@"3 %@", o);
    NSLog(@"4 %@", o);
    NSLog(@"5 %@", o);
}
```

在“id tmp = o;”时对象仅登录到autoreleasepool中1次。

> 在iOS4和OS X Snow Leopard中是不能使用__weak修饰符的，另外也存在不能使用的情况。
>
> 一个是存在不支持__weak修饰符的类，比如NSMachPort类。这些类重写了retain/release并实现该类独自的引用计数机制。不支持weak修饰符的类，在Cocoa框架中极为少见，其类声明中附加了"attribute (( objc_arc_weak_reference_unavailable ))"这一属性。
>
> 此外，就是当allowsWeakReference/retainWeakReference实例方法返回NO的情况。即对于所有allowsWeakReference方法返回NO的类，都绝对不能使用__weak修饰符，否则程序将异常终止。同样地，在使用weak修饰符的变量时，当被赋值对象的retainWeakReference方法返回NO的情况下，该变量将使用nil。

### 内存泄漏

内存泄漏（Memory Leak）是指程序中已动态分配的堆内存由于某种原因程序未释放或无法释放，造成系统内存的浪费，导致程序运行速度减慢甚至系统崩溃等严重后果。

ARC下，iOS中常见的内存泄漏主要集中在循环引用，另外还有Core Foundation框架的对象忘记手动释放、图片ImageIO未释放、数据库忘记关闭等。循环引用的问题将在后面详细探讨。

#### 内存泄漏的检测

1. Xcode Analyze 静态分析
2. Instruments Leak 动态分析
3. 第三方框架：MLeaksFinder、FBRetainCycleDetector

MLeaksFinder对代码没有侵入性，而且其使用非常简单，只需要引入项目中，如果有内存泄漏，3秒后自动弹出 alert 来显示捕捉的信息。它默认只检测应用里 UIViewController 和 UIView 对象的泄漏情况。因为一般应用里内存泄漏影响最严重的就是这两种内存占用比较高的对象，它也可以在代码里设置扩展以检测其他类型的对象泄漏情况。

MLeaksFinder的实现原理大致是，一般情况下，当一个 UIViewController 被 pop 或者 dismiss 掉后，它的 view 和 view 的subview等也会很快地被释放掉，除非我们把它设置为单例或者还有强引用指向它。MLeaksFinder 的做法就是根据这种基本情况，在一个 UIViewController 被 pop 或者 dismiss 掉3秒后，看看它的 view 和 view 的 subview 等是否还存在，如果还存在，就意味着有可能有内存泄漏发生，便弹框提醒用户。

```objective-c
- (BOOL)willDealloc {
    __weak id weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf assertNotDealloc];
    });
    return YES;
}

- (void)assertNotDealloc {
     NSAssert(NO, @“”);
}
```

FBRetainCycleDetector这个工具可以传入应用内存里的任意一个 Objective-C 对象，FBRetainCycleDetector 会查找以该对象为根节点的强引用树中有没有循环引用。

```objective-c
#import <FBRetainCycleDetector/FBRetainCycleDetector.h>

{
   FBRetainCycleDetector *detector = [FBRetainCycleDetector new];
   [detector addCandidate:self];
   NSSet *retainCycles = [detector findRetainCycles];
   NSLog(@"%@", retainCycles);
}
```

这两个工具一起搭配使用真是如虎添翼，很容易排查出内存的问题。先用 MLeaksFinder 找出泄漏的对象，然后再用 FBRetainCycleDetector 检测该对象有没有循环引用，如果有，根据找出来的循环引用链条去查看修改代码就方便很多了。

#### 循环引用

循环引用是内存泄漏常见情形，其原因是两个对象直接或间接相互强持有，形成引用环，导致两者都不能正常释放。比如，两个对象A和B，A的有属性强持有了B，而B亦有属性强持有了A，那么就构成了循环引用。下面列举一些开发当中常见的循环引用。

1.**当delegate导用strong修饰导致的循环引用：**

```objective-c
@property(nonatomic, strong) id<YourDelegateName>delegate;
```

2.**block导致的循环引用：**

```objective-c
{
    self.block = ^{
        self.str = @"EnterBlock";
    };
}
```

经典的解决方法：

```objective-c
__weak __typeof(self) weakSelf = self;
self.block = ^{
    __strong __typeof(weakSelf) strongSelf = weakSelf;
    strongSelf.str = @"EnterBlock";
}; 
// 外部的weakSelf是为了打破强引用环，从而使得没有循环引用。
// 内部的strongSelf是为了在block执行完成前，self不会被释放。
// 因为strongSelf是局部变量，在block执行结束后会释放，所以不会造成循环引用。
```

3.**NSTimer引起的内存泄漏：**

```objective-c
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:2 repeats:YES block:^(NSTimer * _Nonnull timer) {
        self.str = @"timer triggered";
    }];
}
```

解决方法是dealloc方法中调用timer invalidate方法，block中涉及self时转为weak引用。

4.**通知的循环引用**，在iOS 9.0之后，一般的通知，都不再需要手动移除观察者，系统会自动在`dealloc` 的时候调用 `[[NSNotificationCenter defaultCenter] removeObserver: self]`。`iOS9` 以前的需要手动进行移除。原因是：`iOS9` 以前观察者注册时，通知中心并不会对观察者对象做 `retain` 操作，而是进行了 `unsafe_unretained` 引用，所以在观察者被回收的时候，如果不对通知进行手动移除，那么指针指向被回收的内存区域就会成为野指针，这时再发送通知，便会造成程序崩溃。从 `iOS9` 开始通知中心会对观察者进行 `weak` 弱引用，这时即使不对通知进行手动移除，指针也会在观察者被回收后自动置空，这时再发送通知，向空指针发送消息是不会有问题的。建议最好加上移除通知的操作。

5.**WKWebView**在调用addScriptMessageHandler后也会有潜在的循环引用，需要手动remove。

```objective-c
{
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = [[WKUserContentController alloc] init];
    [config.userContentController addScriptMessageHandler:self name:@"WKWebViewHandler"];
    _wkWebView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:config];
    _wkWebView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_wkWebView];
    NSURLRequest *requset = [NSURLRequest requestWithURL:[NSURL URLWithString:@"xxx"]];
    [_wkWebView loadRequest:requset];
}
```

### FAQ

#### 1、从MRC到ARC，Apple是如何实现的？

MRC、ARC的内存管理方式本质并没有改变，只是将retain、release这些操作交给编译器去做。ARC下通过所有权修饰符来实现，一共有四种：

- __strong修饰符
- __weak修饰符
- __unsafe_unretained修饰符
- __autoreleasing修饰符

其中，__strong是id类型和对象类型默认的所有权修饰符，通过它，不必再次键入retain或者release，完美地满足了“引用计数式内存管理的思考方式”。另外，weak修饰符用于解决一些重大问题，比如说引用计数式内存管理中必然会发生的“循环引用”问题。而weak不可用的时候（只能用于iOS5以上及OS X Lion以上版本），则用unsafe unretained代替。针对autorelease，则用autoreleasing修饰符实现。@autoreleasepool替代之前NSAutoreleasePool的显式创建及调用。

#### 2、autoreleasepool创建、释放的时机

App启动后，苹果在主线程 RunLoop 里注册了两个 Observer，其回调都是 _wrapRunLoopWithAutoreleasePoolHandler()。

第一个 Observer 监视的事件是 **kCFRunLoopEntry**(即将进入Loop)，其回调内会调用 _objc_autoreleasePoolPush() 创建自动释放池。其 order 是-2147483647，优先级最高，保证创建释放池发生在其他所有回调之前。

第二个 Observer 监视了两个事件：**kCFRunLoopBeforeWaiting**(准备进入休眠) 时调用_objc_autoreleasePoolPop() 和 _objc_autoreleasePoolPush() 释放旧的池并创建新池；**kCFRunLoopBeforeExit**(即将退出Loop) 时调用 _objc_autoreleasePoolPop() 来释放自动释放池。这个 Observer 的 order 是 2147483647，优先级最低，保证其释放池子发生在其他所有回调之后。

在主线程执行的代码，通常是写在诸如事件回调、Timer回调内的。这些回调会被 RunLoop 创建好的 AutoreleasePool 环绕着，所以不会出现内存泄漏，开发者也不必显示创建 Pool 了。