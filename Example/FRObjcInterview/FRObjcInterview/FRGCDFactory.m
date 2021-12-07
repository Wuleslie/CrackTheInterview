//
//  FRGCDFactory.m
//  FRObjcInterview
//
//  Created by wuleslie on 2021/12/7.
//

#import "FRGCDFactory.h"

@interface FRGCDFactory ()

@property (nonatomic, strong) dispatch_queue_t serialQueue;

@end

@implementation FRGCDFactory

// MARK: Public

+ (void)enterGCDTest {
    [self syncExecuteConcurrentQueue];
}

+ (void)testSerialQueue {
    //[self syncExecuteSerialQueue];
    //[self asyncExecuteSerialQueue];
    FRGCDFactory *gcdFactory = [[FRGCDFactory alloc] init];
    [gcdFactory asyncExecuteSerialQueueOnMultiThread];
}

// MARK: Private
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

// MARK: Getters

- (dispatch_queue_t)serialQueue {
    if (!_serialQueue) {
        _serialQueue = dispatch_queue_create("com.global.serial", NULL);
    }
    return _serialQueue;
}

@end
