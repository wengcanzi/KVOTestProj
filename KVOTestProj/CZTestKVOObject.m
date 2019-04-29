//
//  CZTestKVOObject.m
//  KVOTestProj
//
//  Created by anjubao on 2019/4/28.
//  Copyright © 2019年 cz. All rights reserved.
//

#import "CZTestKVOObject.h"
#import <objc/runtime.h>

@implementation CZTestKVOObject

//重新description方便查看对象信息

- (instancetype)init {
    self = [super init];
    if (self) {
        self.data = @"aaa";
        self.length = 3;
    }
    return self;
}

- (NSString *)description {
    NSLog(@"object address : %p \n", self);
    
    IMP dataIMP = class_getMethodImplementation(object_getClass(self), @selector(setData:));
    IMP lengthIMP = class_getMethodImplementation(object_getClass(self), @selector(setLength:));
    NSLog(@"object setData: IMP %p object setLength: IMP %p \n", dataIMP, lengthIMP);
    
    Class objectMethodClass = [self class];
    Class objectRuntimeClass = object_getClass(self);
    Class superClass = class_getSuperclass(objectRuntimeClass);
    NSLog(@"objectMethodClass : %@, ObjectRuntimeClass : %@, superClass : %@ \n", objectMethodClass, objectRuntimeClass, superClass);
    
    NSLog(@"object method list \n");
    unsigned int count;
    Method *methodList = class_copyMethodList(objectRuntimeClass, &count);
    for (NSInteger i = 0; i < count; i++) {
        Method method = methodList[i];
        NSString *methodName = NSStringFromSelector(method_getName(method));
        NSLog(@"method Name = %@\n", methodName);
    }
    free(methodList);
    return @"";
}
- (void)dealloc {
    NSLog(@"object释放了");
}
@end
