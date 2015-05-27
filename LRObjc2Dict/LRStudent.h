//
//  LRStudent.h
//  LRObjc2Dict
//
//  Created by 甘立荣 on 15/5/26.
//  Copyright (c) 2015年 甘立荣. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LRStudent : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSUInteger age;
@property (nonatomic, copy) NSString *stuClass;
@property (nonatomic, strong) NSArray *teacherArray;
@property (nonatomic, strong) NSDictionary *scoreDict;

@end
