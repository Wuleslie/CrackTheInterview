//
//  FRMultiThread.h
//  FRObjcInterview
//
//  Created by wuleslie on 2021/12/12.
//

/**
 iOS中实现多线程的方式有：pthread、NSThread、GCD、NSOperation/NSOperationQueue.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FRMultiThread : NSObject

+ (void)enterMultiThreadTest;

@end

NS_ASSUME_NONNULL_END
