//
//  NSObject+ConvertToDic.m
//  LRObjc2Dict
//
//  Created by 甘立荣 on 13-6-27.
//  Copyright (c) 2013年 甘立荣. All rights reserved.
//

#import "NSObject+Objc2Dict.h"
#import <objc/runtime.h>

@implementation NSObject (Objc2Dict)

/**
 *  对象转字典
 *
 *  @return
 */
- (NSDictionary *)convertDictionary {
    
    NSMutableDictionary *resultDic = [NSMutableDictionary dictionary];
    unsigned int i;
    
    //此数组用于存放object中的所有属性
    NSMutableArray *propertyArray = [NSMutableArray array];
    NSArray *propertyList = [self getPropertyList:[self class] propertyArray:propertyArray];
    
    //objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for (i = 0; i < propertyList.count; i++) {
        
        NSMutableDictionary *dic = propertyList[i];
        NSString *propertyName = dic[@"propertyName"]; //属性名称
        id propertyValue = dic[@"propertyValue"];      //属性的值
        NSArray *tempArray = dic[@"tempArray"];       //属性类型数组格式例如Integer类型:{Ti,N,V_...}
        NSString *nameForClass = nil;
        
        @try {
            nameForClass = tempArray[1];             //属性类型对于的class
            if ([@"N" isEqual:nameForClass]) {                      //N代表其为基础数据类型
                nameForClass = tempArray[0];
                if ([nameForClass isEqual:@"Tc"] && propertyValue) {//Tc表示其为char类型,bool类型可以算特殊的char类型
                    if ( [propertyValue integerValue] == 0) {       //这里转换成java中相对应的true或者false;
                        resultDic[propertyName] = @"false";
                    } else if ( [propertyValue integerValue] == 1){
                        resultDic[propertyName] = @"true";
                    } else {
                        //NSLog(@"没有这个选项%s",__FUNCTION__);
                    }
                } else {
                    resultDic[propertyName] = propertyValue;
                }
                continue;
            }
        } @catch (NSException *exception) {
            //NSLog(@"Exception:%@",exception.description);
            continue;
        } @finally {}
        Class myClass = NSClassFromString(nameForClass);  //当前属性的类型名称
        //如果数据类型属于UIImage,UIView,UIViewController,UIControl.不处理
        if (propertyValue) {
            
            if ([myClass isSubclassOfClass:[NSString class]] ||
                [myClass isSubclassOfClass:[NSNull class]] ||
                [myClass isSubclassOfClass:[NSNumber class]]) {
                resultDic[propertyName] = propertyValue;
            } else if ([myClass isSubclassOfClass:[NSArray class]] ||
                     [myClass isSubclassOfClass:[NSDictionary class]]){//如果是字典或者数组的话
                id subArray = [self getDataFormArrayOrDic:propertyValue];
                if (tempArray && subArray) {
                    resultDic[propertyName] = subArray;
                }
            } else { //如果是对象的话递归
                NSDictionary * proDictionary = [propertyValue convertDictionary];
                if (proDictionary) {
                    resultDic[propertyName] = proDictionary;
                }
            }
            
        }
        
    }
    
    return resultDic;
    
}

/**
 *  获取model对象中所有的属性
 *
 *  @param clazz         类
 *  @param propertyArray 用于存放属性
 *
 *  @return 返回属性列表
 */
- (NSArray *)getPropertyList: (Class)clazz
               propertyArray:(NSMutableArray *)propertyArray {
    u_int count; //用于存储属性的个数
    objc_property_t *properties  = class_copyPropertyList(clazz, &count);

    propertyArray = [self getArray:propertyArray count:count properties:properties];
    
    Class superclass = class_getSuperclass(clazz); //获取他的父类
    NSString *className =  NSStringFromClass(superclass);
    
    if (![@"NSObject" isEqual:className]) { //如果父类不是NSObject的话,说明其还有父类,递归获取
        //递归获取父类的信息
        [self getPropertyList:superclass propertyArray:propertyArray];
    }
    
    free(properties);
    
    return propertyArray;
}

/**
 *  获取对象中所有属性的属性名,属性值,还有属性类型返回一个数组
 *
 *  @param array      结果数组
 *  @param count      对象属性个数
 *  @param properties 属性数组列表
 *
 *  @return <#return value description#>
 */
- (NSMutableArray *)getArray: (NSMutableArray *)array
                       count:(u_int )count
                  properties:(objc_property_t *)properties {
    
    for (int i = 0; i < count ; i++){
        
        objc_property_t  property = properties[i];  //获取一个OC的属性声明(结构体)
        const char* propertyName_c = property_getName(property);//属性名称
        const char *propertyType_c = property_getAttributes(property);   //属性的类型
        NSString *propertyType = [NSString stringWithUTF8String:propertyType_c];//将char类型的值转换成NSString
        NSString *propertyName = [NSString stringWithUTF8String: propertyName_c]; //属性类型的NSString值
        id propertyValue = [self valueForKey:propertyName]; //属性的值
        
        NSArray * tempArray = nil;
        
        if ([propertyType rangeOfString:@"\""].location != NSNotFound) {
            tempArray = [propertyType componentsSeparatedByString:@"\""];
        } else {
            tempArray = [propertyType componentsSeparatedByString:@","];
        }
        
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        if (propertyName) {
            dic[@"propertyName"] = propertyName;
        }
        
        if (tempArray) {
            dic[@"tempArray"] = tempArray;
        }
        
        if (propertyValue) {
            dic[@"propertyValue"]  = propertyValue;
        }
        
        [array addObject: dic];
        
    }
    
    return array;
}


- (id)getDataFormArrayOrDic:(id)object {
    
    NSString *className = NSStringFromClass([object class]);
    
    if ([className isEqual:@"__NSCFConstantString"] ||
        [className isEqual:@"__NSCFNumber"] ||
        [className isEqual:@"NSNull"] ||
        [className isEqual:@"NSString"] ||
        [className isEqual:@"__NSCFString"]) {
        
        return object;
        
    } else if ([className isEqual:@"__NSArrayI"] ||
              [className isEqual:@"__NSArrayM"]){
        
        NSMutableArray *resultArray = [NSMutableArray array];
        for (id value in object) {
            id subValue = [self getDataFormArrayOrDic:value];
            if (subValue != nil) {
                [resultArray addObject:subValue];
            }
        }
        
        if (resultArray.count > 0) {
            return resultArray;
        }
        
        return nil;
        
    } else if ([className isEqual:@"__NSDictionaryI"] ||
             [className isEqual:@"__NSDictionaryM"]){
        
        NSDictionary *valueDic = object;
        NSMutableDictionary  *resultDic = [NSMutableDictionary dictionary];
        NSArray *allKeys = [valueDic allKeys];
        
        for (NSString *key in allKeys) {
            id dicValue=[valueDic objectForKey:key];
            id result=[self getDataFormArrayOrDic:dicValue];
            if (result != nil) {
                resultDic[key] = result;
            }
        }
        
        if (resultDic.count > 0) {
            return resultDic;
        }
        return nil;
    } else {
        return [object convertDictionary];
    }
    
}

@end
