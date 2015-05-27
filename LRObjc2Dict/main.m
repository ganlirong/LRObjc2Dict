//
//  main.m
//  LRObjc2Dict
//
//  Created by 甘立荣 on 15/5/26.
//  Copyright (c) 2015年 甘立荣. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LRStudent.h"
#import "NSObject+Objc2Dict.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        NSLog(@"Hello, World!");
        LRStudent *student = [[LRStudent alloc] init];
        student.name = @"xiaoming";
        student.age = 12;
        student.stuClass = @"1501";
        student.teacherArray = @[@"tom", @"lucy", @"lily"];
        student.scoreDict = @{@"math": @88, @"Chinese": @"99", @"English": @11};
        NSDictionary *stuDict = [student convertDictionary];
        NSLog(@"dict:%@", stuDict);
        
    }
    return 0;
}
