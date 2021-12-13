//
//  FRGCDFactory.m
//  FRObjcInterview
//
//  Created by wuleslie on 2021/12/7.
//

#import "FRGCDFactory.h"

static dispatch_once_t onceToken;

@interface FRGCDFactory ()

@property (nonatomic, strong) dispatch_queue_t serialQueue;

@end

@implementation FRGCDFactory

// MARK: Public

+ (void)enterGCDTest {
    //[self syncExecuteConcurrentQueue];
    //[self testDispatchOnce];
    [self useGCDTimer];
}

+ (void)testSerialQueue {
    //[self syncExecuteSerialQueue];
    //[self asyncExecuteSerialQueue];
    FRGCDFactory *gcdFactory = [[FRGCDFactory alloc] init];
    [gcdFactory asyncExecuteSerialQueueOnMultiThread];
}

// MARK: Private

+ (void)testDispatchOnce {
    NSLog(@"%@--%@", [self sharedInstance], @(onceToken));
    onceToken = 0;
    NSLog(@"%@--%@", [self sharedInstance], @(onceToken));
    onceToken = 0;
    NSLog(@"%@--%@", [self sharedInstance], @(onceToken));
}

+ (id)sharedInstance {
    static FRGCDFactory *instance = nil;
    NSLog(@"before dispatch_once onceToken:%ld", onceToken);
    dispatch_once(&onceToken, ^{
        instance = [[FRGCDFactory alloc] init];
        NSLog(@"during dispatch_once onceToken:%ld", onceToken);
    });
    NSLog(@"after dispatch_once onceToken:%ld", onceToken);
    return instance;
}

// MARK: 串行队列同步执行
+ (void)syncExecuteSerialQueue {
    // 创建同步队列
    dispatch_queue_t serialDispatchQueue = dispatch_queue_create("com.example.gcd.serial1", NULL);
    // 同步执行任务，实际开发中尽量别用
    dispatch_sync(serialDispatchQueue, ^{
        [self executeTaskOnCurrentThread:1];
    });
    dispatch_sync(serialDispatchQueue, ^{
        [self executeTaskOnCurrentThread:2];
    });
    dispatch_sync(serialDispatchQueue, ^{
        [self executeTaskOnCurrentThread:3];
    });
    [self executeTaskOnCurrentThread:4];
}

// MARK: 并行队列异步执行
+ (void)asyncExecuteSerialQueue {
    // 创建同步队列
    dispatch_queue_t serialDispatchQueue = dispatch_queue_create("com.example.gcd.serial2", DISPATCH_QUEUE_SERIAL);
    dispatch_async(serialDispatchQueue, ^{
        [self executeTaskOnCurrentThread:1];
    });
    dispatch_async(serialDispatchQueue, ^{
        [self executeTaskOnCurrentThread:2];
    });
    dispatch_async(serialDispatchQueue, ^{
        [self executeTaskOnCurrentThread:3];
    });
    [self executeTaskOnCurrentThread:4];
}

+ (void)executeTaskOnCurrentThread:(NSInteger)taskTag {
    NSLog(@"===Execute task %@ on thread:%@", @(taskTag), [NSThread currentThread]);
}

// MARK: 测试同一个串行队列在不同线程中异步/同步执行任务
- (void)asyncExecuteSerialQueueOnMultiThread {
    dispatch_async(self.serialQueue, ^{
        [[self class] executeTaskOnCurrentThread:1];
    });
    dispatch_async(self.serialQueue, ^{
        [[self class] executeTaskOnCurrentThread:2];
    });
    [[self class] executeTaskOnCurrentThread:3];

    [NSThread detachNewThreadSelector:@selector(syncExecuteOnGlobalSerialQueue) toTarget:self withObject:nil];
}

- (void)syncExecuteOnGlobalSerialQueue {
    dispatch_sync(self.serialQueue, ^{
        [[self class] executeTaskOnCurrentThread:4];
    });
    dispatch_sync(self.serialQueue, ^{
        [[self class] executeTaskOnCurrentThread:5];
    });
    [[self class] executeTaskOnCurrentThread:6];
}

// MARK: 并行队列同步执行
+ (void)syncExecuteConcurrentQueue {
    dispatch_queue_t concurrentQueue = dispatch_queue_create("com.example.concurrent", DISPATCH_QUEUE_CONCURRENT);
    dispatch_sync(concurrentQueue, ^{
        [self executeTaskOnCurrentThread:10];
    });
    dispatch_sync(concurrentQueue, ^{
        [self executeTaskOnCurrentThread:11];
    });
    dispatch_sync(concurrentQueue, ^{
        [self executeTaskOnCurrentThread:12];
    });
    [self executeTaskOnCurrentThread:13];
}

// MARK：dispatch_set_target_queue
- (void)setBackgroundTargetQueue {
    dispatch_queue_t serialQueue = dispatch_queue_create("com.example.bgSerial", NULL);
    dispatch_queue_t globalBackgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    // 第一个参数为要修改优先级的队列
    dispatch_set_target_queue(serialQueue, globalBackgroundQueue);
}

// MARK: dispatch_after
- (void)dispatchAfter {
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 3ull * NSEC_PER_SEC);
    dispatch_after(time, dispatch_get_main_queue(), ^{
        NSLog(@"Waited at least three seconds.");
    });
}

// MARK: dispatch_group
- (void)dispatchGroupNotify {
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
}

- (void)dispatchGroupWait {
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
}

// MARK: dispatch semaphore
- (void)dispatchSemaphore {
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
}

// MARK: 执行顺序验证
+ (void)asyncOnMainQueue {
    NSLog(@"begin---%@", [NSDate date]);
    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            sleep(2);
            NSLog(@"1---%@", [NSDate date]);
        });
        NSLog(@"2---%@", [NSDate date]);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"3---%@", [NSDate date]);
        });
    });
    sleep(1);
}

+ (void)asyncOnGlobalQueue {
    NSLog(@"begin---%@", [NSDate date]);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            //sleep(2);
            NSLog(@"1---%@", [NSDate date]);
        });
        NSLog(@"2---%@", [NSDate date]);
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSLog(@"3---%@", [NSDate date]);
        });
    });
    sleep(1);
}

+ (void)onOperationQueue {
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1; // 最大并发数为1，等同于串行队列咯
    NSLog(@"begin---%@", [NSDate date]);
    [queue addOperationWithBlock:^{
        [queue addOperationWithBlock:^{
            sleep(2);
            NSLog(@"1---%@", [NSDate date]);
        }];
        NSLog(@"2---%@", [NSDate date]);
        [queue addOperationWithBlock:^{
            NSLog(@"3---%@", [NSDate date]);
        }];
    }];
    sleep(1);
}

// 有A、B、C、D四个异步任务，AB执行结束才能执行C，A执行完成才能执行D
// 这种任务间的依赖关系，NSOperation更容易表达
+ (void)doTaskByOrder {
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t concurrentQueue = dispatch_queue_create("concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_group_async(group, concurrentQueue, ^{
        sleep(2);
        NSLog(@"taskA");
        dispatch_semaphore_signal(semaphore);
    });

    dispatch_group_async(group, concurrentQueue, ^{
        NSLog(@"taskB");
    });
    
    dispatch_group_notify(group, concurrentQueue, ^{
        NSLog(@"taskC");
    });
    
    dispatch_async(concurrentQueue, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        //sleep(2);
        NSLog(@"taskD");
    });
}

// MARK: gcd timer

+ (void)useGCDTimer {
    NSLog(@"Create gcd timer");
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    /**
     将定时器设定为5秒触发
     不重复
     允许延迟一秒
     */
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, 5ull * NSEC_PER_SEC), DISPATCH_TIME_FOREVER, 1);
    /**
     指定定时器指定时间内执行的处理
     */
    dispatch_source_set_event_handler(timer, ^{
        NSLog(@"wake up!");
        /**
         取消Dispatch source
         */
        dispatch_source_cancel(timer);
    });
    /**
     指定取消Dispatch Source时的处理
     */
    dispatch_source_set_cancel_handler(timer, ^{
        NSLog(@"canneled");
    });
    /**
     启动Dispatch Source
     */
    dispatch_resume(timer);
}

// MARK: Getters

- (dispatch_queue_t)serialQueue {
    if (!_serialQueue) {
        _serialQueue = dispatch_queue_create("com.global.serial", NULL);
    }
    return _serialQueue;
}

@end
