//
//  FRMultiThread.m
//  FRObjcInterview
//
//  Created by wuleslie on 2021/12/12.
//

#import "FRMultiThread.h"
#import <pthread/pthread.h>

@implementation FRMultiThread

+ (void)enterMultiThreadTest {
    //[self usePthread];
}

// MARK: NSOperation/NSOperationQueue
/**NSOperation 是个抽象类，不能用来封装操作。我们只有使用它的子类来封装操作。我们有两种方式来封装操作。
   子类 NSInvocationOperation
   子类 NSBlockOperation
*/
+ (void)userNSOperation {
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 5;
    
    NSInvocationOperation *operation1 = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(operationQueue) object:nil];
    //[operation1 start];
    
    NSBlockOperation *operation2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"block operation on thread: %@", [NSThread currentThread]);
    }];
    [operation2 addExecutionBlock:^{
        NSLog(@"block operation extra task");
    }];
    //[operation2 start];
    [operation2 addDependency:operation1];
    [operation2 setCompletionBlock:^{
        NSLog(@"operation 2 done!");
    }];
    
    [queue addOperation:operation1];
    [queue addOperation:operation2];
    [queue addOperationWithBlock:^{
        NSLog(@"add operation with block directly");
    }];
}

+ (void)operationAction {
    NSLog(@"operation action done");
}

// MARK: NSThread
// OC对象，位于Foundation框架中，封装程度最小、最轻量级，开销较大。
+ (void)useNSThread {
    // 使用方式1
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(threadAction) object:nil];
    [thread start];
    // 使用方式2
    [NSThread detachNewThreadSelector:@selector(threadAction) toTarget:self withObject:nil];
    // 使用方式3
    [self performSelector:@selector(threadAction)];
}

+ (void)threadAction {
    NSLog(@"%@", [NSThread currentThread]);
}

// MARK: pthread的使用方法
// C语言通用的多线程API，跨平台，需手动管理线程生命周期，使用难度大
// POSIX Threads Programming：https://hpc-tutorials.llnl.gov/posix/#Abstract
+ (void)usePthread {
    pthread_t pthread;
    pthread_create(&pthread, NULL, start, NULL);
}

void * start(void *param) {
    NSLog(@"---Thread:%@", [NSThread currentThread]);
    return NULL;
}
/**
 数据类型
 pthread_t：线程ID(线程标识符,用于声明线程ID)
 pthread_attr_t：线程属性1

 操纵函数
 pthread_create()：创建一个线程
 pthread_exit()：终止当前线程
 pthread_cancel()：中断另外一个线程的运行
 pthread_join()：阻塞当前的线程，直到另外一个线程运行结束
 pthread_attr_init()：初始化线程的属性
 pthread_attr_setdetachstate()：设置脱离状态的属性（决定这个线程在终止时是否可以被结合）
 pthread_attr_getdetachstate()：获取脱离状态的属性
 pthread_attr_destroy()：删除线程的属性
 pthread_kill()：向线程发送一个信号

 同步函数
 用于 mutex 和条件变量
 pthread_mutex_init() 初始化互斥锁
 pthread_mutex_destroy() 删除互斥锁
 pthread_mutex_lock()：占有互斥锁（阻塞操作）
 pthread_mutex_trylock()：试图占有互斥锁（不阻塞操作）。即，当互斥锁空闲时，将占有该锁；否则，立即返回。
 pthread_mutex_unlock(): 释放互斥锁
 pthread_cond_init()：初始化条件变量
 pthread_cond_destroy()：销毁条件变量
 pthread_cond_signal(): 唤醒第一个调用pthread_cond_wait()而进入睡眠的线程
 pthread_cond_wait(): 等待条件变量的特殊条件发生
 Thread-local storage（或者以Pthreads术语，称作线程特有数据）：
 pthread_key_create(): 分配用于标识进程中线程特定数据的键
 pthread_setspecific(): 为指定线程特定数据键设置线程特定绑定
 pthread_getspecific(): 获取调用线程的键绑定，并将该绑定存储在 value 指向的位置中
 pthread_key_delete(): 销毁现有线程特定数据键
 pthread_attr_getschedparam();获取线程优先级
 pthread_attr_setschedparam();设置线程优先级

 工具函数
 pthread_equal(): 对两个线程的线程标识号进行比较
 （int pthread_equal ( pthread_t t1 , pthread_t t2); 比较两个线程ID是否相同）
 pthread_detach(): 分离线程
 pthread_self(): 查询线程自身线程标识号

 ————————————————
 版权声明：本文为CSDN博主「Smtsec」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
 原文链接：https://blog.csdn.net/qq_40638006/article/details/88621150
 */

@end
