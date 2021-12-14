//
//  FRMemoryCheck.m
//  FRObjcInterview
//
//  Created by wuleslie on 2021/12/12.
//

#import "FRMemoryCheck.h"
#import "FRPerson.h"

@implementation FRMemoryCheck

+ (void)enterMemoryTest {
    [self testMyObjectCopy];
}

// MARK: 浅拷贝、深拷贝
+ (void)reviewCopyMatter {
}

// MARK: 自定义对象的拷贝
+ (void)testMyObjectCopy {
    // NSString *name = @"Joey";
    NSMutableString *name = [[NSMutableString alloc] initWithString:@"Joey"];
    NSLog(@"name store at: %p", name);
    FRPerson *person1 = [[FRPerson alloc] init];
    person1.name = name;
    person1.age = 20;
    
    FRPerson *personCopy = [person1 copy];
    // copy修饰，name的修改不会影响属性的值
    [name appendString:@" Jobs"];
    NSLog(@"Original person: %@, name: %@ store at: %p", person1, person1.name, person1.name);
    NSLog(@"Copied person: %@, name: %@ store at: %p", personCopy, personCopy.name, personCopy.name);
    
    NSArray *personArray = @[person1, personCopy];
    // 当copyItems为YES时，copy后的数组元素是不同的
    NSArray *personArrayCopy = [[NSArray alloc] initWithArray:personArray copyItems:YES];
    NSLog(@"%@", personArray);
    NSLog(@"%@", personArrayCopy);
}

@end
