//
//  CZKVOItem.h
//  KVOTestProj
//
//  Created by anjubao on 2019/4/28.
//  Copyright © 2019年 cz. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void (^cz_KVOObserveBlock) (NSString *observedKey, id oldValue, id newValue);

NS_ASSUME_NONNULL_BEGIN
//每个实例对象对应被观察者的每一个属性（相当于中间量，负责记录和返回信息）
@interface CZKVOItem : NSObject

@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy, nullable) cz_KVOObserveBlock block;
@property (nonatomic, assign, nullable) SEL action;

- (instancetype)initWithObserver:(NSObject *)observer
                             key:(NSString *)key
                           block:(cz_KVOObserveBlock)block;

- (instancetype)initWithObserver:(NSObject *)observer
                             key:(NSString *)key
                          action:(SEL)action;

@end

NS_ASSUME_NONNULL_END
