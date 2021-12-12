//
//  ViewController.m
//  FRObjcInterview
//
//  Created by wuleslie on 2021/12/7.
//

#import "ViewController.h"
#import "FRGCDFactory.h"
#import "FRMultiThread.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [FRGCDFactory enterGCDTest];
    [FRMultiThread enterMultiThreadTest];
}


@end
