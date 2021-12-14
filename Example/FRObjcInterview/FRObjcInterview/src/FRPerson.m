//
//  FRPerson.m
//  FRObjcInterview
//
//  Created by wuleslie on 2021/12/14.
//

#import "FRPerson.h"

@interface FRPerson () <NSCopying>

@end

@implementation FRPerson

- (id)copyWithZone:(NSZone *)zone {
    FRPerson *person = [[[self class] allocWithZone:zone] init];
    person.name = self.name;
    person.age = self.age;
    return person;
}

@end
