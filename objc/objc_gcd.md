### Grand Central Dispatch

#### 什么是GCD？

从OS X Snow Leopard和iOS4开始引入的多线程编程功能，Grand Central Dispatch(GCD)是异步执行任务的技术之一。一般将应用程序中记述的线程管理用的代码在系统级中实现。开发者**只需要定义想执行的任务并追加到适当的Dispatch Queue中**，GCD就能生成必要的线程并计划执行任务。由于**线程管理是作为系统的一部分来实现的，因此可以统一管理**，也可执行任务，这样就比以前的线程更有效率。

#### GCD中的队列与执行

| Dispatch Queue的种类      | 说明                     | 线程使用      |
| ------------------------- | ------------------------ | ------------- |
| Serial Dispatch Queue     | 等待现在执行中处理结束   | 使用一个线程* |
| Concurrent Dispatch Queue | 不等待现在执行中处理结束 | 使用多个线程  |

*注：同一个串行队列在不同线程中异步执行，使用的线程是同一个；而在不同线程中同步执行，则会跟执行时的当前线程保持一致，即串行队列执行任务的线程会变化。

队列分为两种：
**串行队列**中的任务会顺序执行。
**并行队列**中的任务一般会并发执行，并且没法肯定任务的执行顺序。

执行方式也分两种：同步执行、异步执行。 

队列与执行方式两两组合的情况为：
1).串行队列同步执行：任务都在当前线程执行（同步），并且顺序执行（串行）
2).串行队列异步执行：任务都在开辟的新的子线程中执行（异步），并且顺序执行（串行）
3).并发队列同步执行：任务都在当前线程执行（同步），但是是顺序执行的（并没有体现并发的特性）
4).并发队列异步执行：任务在开辟的多个子线程中执行（异步），并且是同时执行的（并发）

队列的获取：
1.dispatch_queue_create;
2.Main Dispatch Queue/Global Dispatch Queue.

```objective-c
// 创建串行队列
dispatch_queue_t serialDispatchQueue = dispatch_queue_create("com.example.serial", NULL);
// 创建并行队列
dispatch_queue_t concurrentQueue = dispatch_queue_create("com.example.concurrent", DISPATCH_QUEUE_CONCURRENT);
```

串行队列使用一个线程，并行队列使用多个线程。iOS和OS X基于Dispatch Queue中的处理数、CPU核数以及CPU负荷等当前系统的状态来决定并行队列中并行执行的处理数。所谓“并行执行”，就是使用多个线程同时执行多个处理。

iOS和OS X的核心—XNU内核决定应当使用的线程数，并只生成所需的线程执行处理。另外，当处理结束，应当执行的处理数减少时，XNU内核会结束不需要的线程。

虽然串行队列、并行队列收到系统资源的限制，但用dispatch_queue_create函数可生成任意多个Dispatch Queue。一个串行队列对应一个线程，而创建2000个串行队列则会有2000个线程，要注意创建的个数，过多反而会大幅降低系统的响应性能。一般，我们只在多个线程更新相同资源导致数据竞争时使用串行队列。

#### Main Dispatch Queue/Global Dispatch Queue

主线程只有一个，所以Main Dispatch Queue自然是Serial Dispatch Queue。

```objective-c
dispatch_async(dispatch_get_main_queue(), ^{
    // do your work
});
```

Global Dispatch Queue有四个执行优先级，分别是高优先级、默认优先级、低优先级以及后台优先级。通过XNU内核管理的用于Global Dispatch Queue的线程，将各自使用的Global Dispatch Queue的执行优先级作为线程的执行优先级使用。但是通过XNU内核用于Global Dispatch Queue的线程并不能保证实时性，因此执行优先级只是大致判断。

```objective-c
// 在默认优先级的global dispatch queue中执行block
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    /**
     可并行执行的处理
     */
    dispatch_async(dispatch_get_main_queue(), ^{
        /**
         只能在主线程中执行的处理
         */
    });
});
```

#### dispatch_set_target_queue

通过dispatch_queue_create函数创建的串行队列和并行队列，都是用与默认优先级Global Dispatch Queue相同执行优先级的线程。而想要变更生成的Dispatch Queue的执行优先级，则要使用dispatch_set_target_queue函数。例如，在后台执行的Serial Dispatch Queue的生成代码如下：

```objective-c
dispatch_queue_t serialQueue = dispatch_queue_create("com.example.bgSerial", NULL);
dispatch_queue_t globalBackgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
// 第一个参数为要修改优先级的队列
dispatch_set_target_queue(serialQueue, globalBackgroundQueue);
```

dispatch_set_target_queue函数不仅可以变更Dispatch Queue的执行优先级，还可以用于设定Dispatch Queue的执行阶层。如果在多个Serial Dispatch Queue中使用dispatch_set_target_queue函数指定目标为某一个Serial Dispatch Queue，那么原本应该并行执行的多个Serial Dispatch Queue，在目标串行队列上只能同时执行一个处理。

#### dispatch_after

```objective-c
// ull是C语言的数值字面量，是显示表明类型时使用的字符串(“unsigned long long”)
dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 3ull * NSEC_PER_SEC);
dispatch_after(time, dispatch_get_main_queue(), ^{
    NSLog(@"Waited at least three seconds.");
});
```

注意，dispatch_after函数并不是在指定时间后执行处理，而只是在指定时间追加处理到Dispatch Queue。上面的代码等同于在3秒后用dispatch_async函数追加Block到Main Dispatch Queue。

因为Main Dispatch Queue在主线程的RunLoop中执行，所以在比如每隔1/60秒执行的RunLoop中，Block最快在3秒后执行，最慢在3+1/60秒后执行，并且当Main Dispatch Queue有大量处理追加或者主线程的处理本身有延迟时，这个时间会更长。

其中，dispatch_time_t函数通常用于计算相对时间，而dispatch_walltime函数用于计算绝对时间。struct timespec类型的时间可以很轻松地通过NSDate类对象转换得到。

#### dispatch_group

dispatch_group_notify函数在多有group任务完成后通知：

```objective-c
dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
dispatch_group_t group = dispatch_group_create();
dispatch_group_async(group, queue, ^{
    NSLog(@"blk0");
});
dispatch_group_async(group, queue, ^{
    NSLog(@"blk1");
});
dispatch_group_async(group, queue, ^{
    NSLog(@"blk2");
});
dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    NSLog(@"done");
});
```

dispatch_group_wait函数指定等待时间：

```objective-c
dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
dispatch_group_t group = dispatch_group_create();
dispatch_group_async(group, queue, ^{
    NSLog(@"blk0");
});
dispatch_group_async(group, queue, ^{
    NSLog(@"blk1");
});
dispatch_group_async(group, queue, ^{
    NSLog(@"blk2");
});
/**等待指定时间，可以设置为DISPATCH_TIME_FOREVER*/
dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 3ull * NSEC_PER_SEC);
long result = dispatch_group_wait(group, time);
if (result == 0) {
    /**
     属于Dispatch Group的全部处理任务执行结束
     */
} else {
    /**
     属于Dispatch Group的任务还未全部执行完成
     */
}
```

#### dispatch_barrier_async

dispatch_barrier_async函数会等待追加到concurrent dispatch queue上的并行执行的处理全部结束之后，再将指定的处理追加到该并行队列中。然后在由dispatch_barrier_async函数追加的处理执行完毕后，并行队列才恢复为一般的动作，追加到该并行队列的处理又开始并行执行。

```objective-c
dispatch_async(queue, blk0_for_reading);
dispatch_async(queue, blk1_for_reading);
dispatch_async(queue, blk2_for_reading);
dispatch_async(queue, blk3_for_reading);
dispatch_barrier_async(queue, blk_for_writing);
dispatch_async(queue, blk4_for_reading);
dispatch_async(queue, blk5_for_reading);
dispatch_async(queue, blk6_for_reading);
```

上面的代码中，会等到blk0、blk1、blk2、blk3执行完成之后，再执行blk_for_writing，然后等blk_for_writing执行完成，再恢复并行执行blk4、blk5、blk6。

#### dispatch_apply

dispatch_apply函数是dispatch_sync和Dispatch Group的关联API。该函数按指定的次数将指定的block追加到特定的Dispatch Queue中，并等待全部处理执行结束。

```objective-c
dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
dispatch_apply(10, queue, ^(size_t index) {
    NSLog(@"%zu", index);
});
```

可以用于遍历数组：

```objective-c
dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
dispatch_apply([array count], queue, ^(size_t index) {
    NSLog(@"%zu: %@", index, array[index]);
});
```

#### dispatch_semaphore

用于更细粒度的排他控制。

```objective-c
dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
dispatch_async(dispatch_get_global_queue(0, 0), ^{
    /**
     耗时操作，比如网络请求
     */
    dispatch_semaphore_signal(semaphore);
});
dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
long result = dispatch_semaphore_wait(semaphore, time);
if (result == 0) {
    /**
     由于semaphore的计数值大于等于1
     可执行需要进行排他控制的处理
     */
} else {
    /**
     由于semaphore的计数值为0，因此到达指定时间为止待机
     */
}
```

#### dispatch_once

dispatch_once函数是保证在应用程序执行中只执行一次指定处理的API。常用于生成单例：

```objective-c
static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
    /**
     初始化
     */
});
```

其原型声明如下：

```objective-c
void dispatch_once(dispatch_once_t *predicate, DISPATCH_NOESCAPE dispatch_block_t block);
```

DISPATCH_NOESCAPE多用来修饰block，用于表明block在当前方法执行结束前执行。类似于Swift中的@noescape（非逃逸闭包），与之对应的是@escaping（逃逸闭包）。简单地说，闭包在函数结束前被调用的为非逃逸闭包，闭包在函数结束后被调用的为逃逸闭包。

注意，dispatch_once可能导致的死锁问题，比如两个单例对象在init方法中相互调用。

#### 练习题

一、导致dispatch_once死锁的方式？

死锁方式1：
1、某线程T1()调用单例A，且为应用生命周期内首次调用，需要使用dispatch_once(&token, block())初始化单例。
2、上述block()中的某个函数调用了dispatch_sync_safe，同步在T2线程执行代码
3、T2线程正在执行的某个函数需要调用到单例A，将会再次调用dispatch_once。
4、这样T1线程在等block执行完毕，它在等待T2线程执行完毕，而T2线程在等待T1线程的dispatch_once执行完毕，造成了相互等待，故而死锁

死锁方式2：
1、某线程T1()调用单例A，且为应用生命周期内首次调用，需要使用dispatch_once(&token, block())初始化单例；
2、block中可能掉用到了B流程，B流程又调用了C流程，C流程可能调用到了单例A，将会再次调用dispatch_once；
3、这样又造成了相互等待。

二、怎么让dispatch_once再次执行的方法？

通过dispatch_once_t的值来控制的，onceToken的初始值为0，在执行完dispatch_once的block后，onceToken的值变为-1。**当我们将onceToken的值重置为0后，调用dispatch_once函数会再次执行block。**

另外，如果将onceToken的初始值设为-1，dispatch_once将一次都不执行，返回空。而如果初始值既不是0也不是-1，随便赋一个什么数值，程序将会崩溃在dispatch_once(predicate, block)处，提示EXC_BAD_INSTRUCTION 

三、iOS多线程有哪些实现方式？

pthread, NSThread, NSOperation/NSOperationQueue, GCD. 

四、请说出以下代码的执行顺序以及每次执行前等待了多长时间？并解释下原因。

```objective-c
dispatch_async(dispatch_get_main_queue(), ^{
    dispatch_async(dispatch_get_main_queue(), ^{
        sleep(2);
        NSLog(@"1");
    });
    NSLog(@"2");
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"3");
    });
});
sleep(1);
```

首先，针对主队列的情况，因为是异步执行，所以最底下sleep(1)会让当前线程先睡眠1秒，如果当前线程为主线程，则会等待1秒，然后开始执行追加到主队列的block。block一开始就是追加异步任务1到主队列，将会在当前block执行后再执行，接着是执行任务2，然后是追加异步任务3到主队列。因为主队列是串行队列，所以任务将会顺序执行：
开始---如果当前线程为主线程，等待1秒---打印2---等待2秒---打印1---打印3

*如果全换成global dispatch queue呢？*

如果换成global dispatch queue，则最底下sleep(1)不会造成等待，并发，先打印2，然后打印3，两秒后，打印出1：开始---打印2---打印3—等待2秒----打印1.(如果1处没有sleep，则1和2的打印顺序随机)

五、说一下dispatch_group_t和dispatch_barrier_sync的区别

dispatch_group_t常用于执行完一组任务之后再做后续操作；dispatch_barrier_(a)sync则“承上启下”，保证在其之前的任务都先于自己执行，此后的任务都迟于自己执行，跟并发队列结合可实现高效率的数据库访问和文件访问。注意，dispatch_barrier_sync跟dispatch_barrier_async只在自己创建的并发队列上有效，在global dispatch queue和serial dispatch queue上无效。

六、用gcd实现比较高效的属性访问，要线程安全。

