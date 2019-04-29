//
//  NSObject+KVOExtension.m
//  KVOTestProj
//
//  Created by anjubao on 2019/4/28.
//  Copyright © 2019年 cz. All rights reserved.
//

#import "NSObject+KVOExtension.h"
#import "CZKVOItem.h"
#import <objc/runtime.h>
#import <objc/message.h>

//a method to create a unique pointer at compile time.在编译的时候创建一个唯一的指针
static void *cz_KVOObserverAssociatedKey = &cz_KVOObserverAssociatedKey;
static NSString *cz_KVOClassPrefix = @"cz_KVONotifying_";//系统自动中间类的类名前缀 NSKVONotifying_


@implementation NSObject (KVOExtension)

#pragma mark -- 字符串裁剪
static NSString * cz_getterForSetter(SEL setter) {
    NSString *setterString = NSStringFromSelector(setter);
    if (![setterString hasPrefix:@"set"]) {
        return nil;
    }
    
    return getterString(setterString);
}

static NSString * cz_setterForGetter(SEL getter) {
    NSString *getterString = NSStringFromSelector(getter);
    return setterString(getterString);
}

//从getter字符串拼接成setter字符串
static NSString * setterString(NSString *getterString){
    NSString *firstString = [getterString substringToIndex:1];
    firstString = [firstString uppercaseString];
    
    NSString *setterString = [getterString substringFromIndex:1];
    setterString = [NSString stringWithFormat:@"set%@%@:", firstString, setterString];
    return setterString;
}
//从setter字符串拼接成getter字符串
static NSString * getterString(NSString *setterString){
    NSString *getterString = [setterString substringWithRange:NSMakeRange(4, setterString.length - 5)];
    NSString *firstString = [setterString substringWithRange:NSMakeRange(3, 1)];
    firstString = [firstString lowercaseString];
    getterString = [NSString stringWithFormat:@"%@%@", firstString, getterString];
    return getterString;
}

#pragma mark -- 判断执行条件
- (Class)cz_makeKVOClassWithName:(NSString *)name {
    // 1.判断是否存在KVO类，如果存在则返回。
    NSString *className = [NSString stringWithFormat:@"%@%@", cz_KVOClassPrefix, name];
    Class kvoClass = objc_getClass(className.UTF8String);
    if (kvoClass) {
        return kvoClass;
    }
    // 2.如果不存在，则创建KVO类。
    kvoClass = objc_allocateClassPair(object_getClass(self), className.UTF8String, 0);
    objc_registerClassPair(kvoClass);
    // 3.重写KVO类的class方法，指向自定义的IMP。
    Method method = class_getInstanceMethod(object_getClass(self), @selector(class));
    const char *types = method_getTypeEncoding(method);
    class_addMethod(kvoClass, @selector(class), (IMP)cz_kvoClass, types);
    return kvoClass;
}

//静态函数（作用类似于类方法）
static Class cz_kvoClass(id self, SEL selector) {
    return class_getSuperclass(object_getClass(self));
}

- (BOOL)cz_hasMethodWithSEL:(SEL)sel {
    NSString *setterName = NSStringFromSelector(sel);
    unsigned int count;
    Method *methodList = class_copyMethodList(object_getClass(self), &count);
    for (NSInteger i = 0; i < count; i++) {
        Method method = methodList[i];
        NSString *methodName = NSStringFromSelector(method_getName(method));
        if ([methodName isEqualToString:setterName]) {
            free(methodList);
            return YES;
        }
    }
    //c开辟的空间必须手动释放
    free(methodList);
    return NO;
}

static void cz_kvoSetter(id self, SEL selector, id value) {
    //被观察对象调用setter，执行回调
    // 1.获取旧值。
    id (*getterMsgSend) (id, SEL) = (void *)objc_msgSend;
    NSString *getterString = cz_getterForSetter(selector);
    SEL getterSelector = NSSelectorFromString(getterString);
    id oldValue = getterMsgSend(self, getterSelector);
    
    // 2.创建super的结构体，并向super发送属性的消息。
    id (*msgSendSuper) (void *, SEL, id) = (void *)objc_msgSendSuper;
    struct objc_super objcSuper = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    msgSendSuper(&objcSuper, selector, value);
    // 3.遍历调用block。
    NSMutableArray <CZKVOItem *>* observers = objc_getAssociatedObject(self, cz_KVOObserverAssociatedKey);
    [observers enumerateObjectsUsingBlock:^(CZKVOItem * _Nonnull mapTable, NSUInteger idx, BOOL * _Nonnull stop) {
        
        id observer = mapTable.observer;
        if (observer) {
            if ([mapTable.key isEqualToString:getterString] && mapTable.block) {
                mapTable.block(self, NSStringFromSelector(selector), oldValue, value);
            }
            else if ([mapTable.key isEqualToString:getterString] && mapTable.action) {
                //屏蔽内存警告
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                //系统方法，只能返回1到2个参数
//                    [observer performSelector:mapTable.action withObject:oldValue withObject:value];
                //自定义的返回多个参数的performSelector
                [observer performSelector:mapTable.action withObjects:@[oldValue,value,mapTable.key]];
#pragma clang diagnostic pop
            }
        }
    }];
}

- (void)judgeClass:(Class)kvoClass setterSel:(SEL)originalSetter type:(const char * _Nullable)type observer:(NSObject *)observer originalSel:(SEL)originalSelector action:(SEL)action {
    //判断当前类是否是KVO子类，如果不是则创建，并设置其isa指针。
    /*
     通过self调用的步骤，需要在这里执行完
     因为object_setClass会交换sisa指针，此时的selfb已经不是原先的self，分开执行会因为使用同一个self指向的类型而失效
     */
    NSString *kvoClassName = NSStringFromClass(kvoClass);
    if (![kvoClassName hasPrefix:cz_KVOClassPrefix]) {
        kvoClass = [self cz_makeKVOClassWithName:kvoClassName];
        object_setClass(self, kvoClass);
    }
    
    //如果没有实现，则添加Key对应的setter方法。
    if (![self cz_hasMethodWithSEL:originalSetter]) {
        class_addMethod(kvoClass, originalSetter, (IMP)cz_kvoSetter, type);
    }
    //创建观察者item，并动态添加到当前类的容器中    
    CZKVOItem *item = [[CZKVOItem alloc] initWithObserver:observer key:NSStringFromSelector(originalSelector) action:action];

    NSMutableArray<CZKVOItem *> *observers = objc_getAssociatedObject(self, cz_KVOObserverAssociatedKey);
    if (observers == nil) {
        observers = [NSMutableArray array];
    }
    [observers addObject:item];
    objc_setAssociatedObject(self, cz_KVOObserverAssociatedKey, observers, OBJC_ASSOCIATION_RETAIN);
}

- (void)judgeClass:(Class)kvoClass setterSel:(SEL)originalSetter type:(const char * _Nullable)type observer:(NSObject *)observer originalSel:(SEL)originalSelector callback:(cz_KVOObserveBlock)callback {
    //判断当前类是否是KVO子类，如果不是则创建，并设置其isa指针。
    /*
     通过self调用的步骤，需要在这里执行完
     因为object_setClass会交换sisa指针，此时的selfb已经不是原先的self，分开执行会因为使用同一个self指向的类型而失效
     */
    NSString *kvoClassName = NSStringFromClass(kvoClass);
    if (![kvoClassName hasPrefix:cz_KVOClassPrefix]) {
        kvoClass = [self cz_makeKVOClassWithName:kvoClassName];
        object_setClass(self, kvoClass);
    }
    
    //如果没有实现，则添加Key对应的setter方法。
    if (![self cz_hasMethodWithSEL:originalSetter]) {
        class_addMethod(kvoClass, originalSetter, (IMP)cz_kvoSetter, type);
    }
    //创建观察者item，并动态添加到当前类的容器中
    CZKVOItem *item = [[CZKVOItem alloc] initWithObserver:observer key:NSStringFromSelector(originalSelector) block:callback];
    NSMutableArray<CZKVOItem *> *observers = objc_getAssociatedObject(self, cz_KVOObserverAssociatedKey);
    if (observers == nil) {
        observers = [NSMutableArray array];
    }
    [observers addObject:item];
    objc_setAssociatedObject(self, cz_KVOObserverAssociatedKey, observers, OBJC_ASSOCIATION_RETAIN);
}

- (void)cz_addObserver:(NSObject *)observer originalSelector:(SEL)originalSelector callback:(cz_KVOObserveBlock)callback {
    SEL originalSetter = NSSelectorFromString(cz_setterForGetter(originalSelector));
    Class kvoClass = object_getClass(self);

    Method originalMethod = class_getInstanceMethod(kvoClass, originalSetter);
    if (!originalMethod) {
        //找不到方法时，提示报错
        NSLog(@"%@", [NSString stringWithFormat:@"%@ Class %@ setter SEL not found.", NSStringFromClass([self class]), NSStringFromSelector(originalSelector)]);
        return ;
    }
    //添加中间量CZKVOItem
    [self judgeClass:kvoClass setterSel:originalSetter type:method_getTypeEncoding(originalMethod) observer:observer originalSel:originalSelector callback:callback];
}

- (void)cz_addObserver:(NSObject *)observer propertyKey:(NSString *)propertyKey callback:(cz_KVOObserveBlock)callback {
    SEL originalSetter = NSSelectorFromString(setterString(propertyKey));
    Class kvoClass = object_getClass(self);
    Method originalMethod = class_getInstanceMethod(kvoClass, originalSetter);
    if (!originalMethod) {
        //找不到方法时，提示报错
        NSLog(@"%@", [NSString stringWithFormat:@"%@ Class %@ setter SEL not found.", NSStringFromClass([self class]), propertyKey]);
        return ;
    }
    [self judgeClass:kvoClass setterSel:originalSetter type:method_getTypeEncoding(originalMethod) observer:observer originalSel:NSSelectorFromString(propertyKey) callback:callback];
}

- (void)cz_addObserver:(NSObject *)observer propertyKey:(NSString *)propertyKey action:(SEL)action {
    SEL originalSetter = NSSelectorFromString(setterString(propertyKey));
    Class kvoClass = object_getClass(self);
    Method originalMethod = class_getInstanceMethod(kvoClass, originalSetter);
    if (!originalMethod) {
        //找不到方法时，提示报错
        NSLog(@"%@", [NSString stringWithFormat:@"%@ Class %@ setter SEL not found.", NSStringFromClass([self class]), propertyKey]);
        return ;
    }
    [self judgeClass:kvoClass setterSel:originalSetter type:method_getTypeEncoding(originalMethod) observer:observer originalSel:NSSelectorFromString(propertyKey) action:action];
}

#pragma mark -- 从动态创建的数组中移除中间量
//通过SEL方法名移除
- (void)cz_removeObserver:(NSObject *)observer
          originalSelector:(SEL)originalSelector {
    NSMutableArray <CZKVOItem *>* observers = objc_getAssociatedObject(self, cz_KVOObserverAssociatedKey);
    [observers enumerateObjectsUsingBlock:^(CZKVOItem * _Nonnull mapTable, NSUInteger idx, BOOL * _Nonnull stop) {
        SEL selector = NSSelectorFromString(mapTable.key);
        if (mapTable.observer == observer && selector == originalSelector) {
            [observers removeObject:mapTable];
        }
    }];
}

//通过key属性名移除
- (void)cz_removeObserver:(NSObject *)observer propertyKey:(NSString *)propertyKey {
    NSMutableArray <CZKVOItem *>* observers = objc_getAssociatedObject(self, cz_KVOObserverAssociatedKey);
    [observers enumerateObjectsUsingBlock:^(CZKVOItem * _Nonnull mapTable, NSUInteger idx, BOOL * _Nonnull stop) {
        SEL selector = NSSelectorFromString(mapTable.key);
        if (mapTable.observer == observer && NSStringFromSelector(selector) == propertyKey) {
            [observers removeObject:mapTable];
        }
    }];
}

- (void)cz_removeObserver:(NSObject *)observer {
    NSMutableArray <CZKVOItem *>* observers = objc_getAssociatedObject(self, cz_KVOObserverAssociatedKey);
    [observers enumerateObjectsUsingBlock:^(CZKVOItem * _Nonnull mapTable, NSUInteger idx, BOOL * _Nonnull stop) {
        if (mapTable.observer == observer) {
            [observers removeObject:mapTable];
        }
    }];
}

#pragma mark -- 添加方法performSelector传递多个参数的方法方法
- (id)performSelector:(SEL)aSelector withObjects:(NSArray *)objects {
    NSMethodSignature *methodSignature = [[self class] instanceMethodSignatureForSelector:aSelector];
    if(methodSignature == nil)
    {
        //注意自定义的action，所带参数的个数，必须和objects的count相同
        @throw [NSException exceptionWithName:@"抛异常错误" reason:@"没有这个方法，或者方法名字错误" userInfo:nil];
        return nil;
    }
    else
    {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setTarget:self];
        [invocation setSelector:aSelector];
        //签名中方法参数的个数，内部包含了self和_cmd，所以参数从第3个开始
        NSInteger  signatureParamCount = methodSignature.numberOfArguments - 2;
        NSInteger requireParamCount = objects.count;
        NSInteger resultParamCount = MIN(signatureParamCount, requireParamCount);
        for (NSInteger i = 0; i < resultParamCount; i++) {
            id  obj = objects[i];
            [invocation setArgument:&obj atIndex:i+2];
        }
        [invocation retainArguments]; //retain所有参数，避免被dealloc
        [invocation invoke];
        //返回值处理
        id callBackObject = nil;
        if(methodSignature.methodReturnLength)
        {
            [invocation getReturnValue:&callBackObject];
        }
        return callBackObject;
    }
}

@end
