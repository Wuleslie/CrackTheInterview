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

#### 练习题