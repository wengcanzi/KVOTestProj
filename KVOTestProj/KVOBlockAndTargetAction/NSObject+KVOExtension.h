//
//  NSObject+KVOExtension.h
//  KVOTestProj
//
//  Created by anjubao on 2019/4/28.
//  Copyright © 2019年 cz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CZKVOItem.h"

NS_ASSUME_NONNULL_BEGIN


@interface NSObject (KVOExtension)

- (void)cz_addObserver:(NSObject *)observer
       originalSelector:(SEL)originalSelector
               callback:(cz_KVOObserveBlock)callback;

- (void)cz_addObserver:(NSObject *)observer
      propertyKey:(NSString *)propertyKey
              callback:(cz_KVOObserveBlock)callback;

- (void)cz_addObserver:(NSObject *)observer
           propertyKey:(NSString *)propertyKey
              action:(SEL)action;

//缺少一个观察selecor回调action的放法，可以自行添加

//根据关键信息移除观察者
- (void)cz_removeObserver:(NSObject *)observer
          originalSelector:(SEL)originalSelector;

- (void)cz_removeObserver:(NSObject *)observer
          propertyKey:(NSString *)propertyKey;

- (void)cz_removeObserver:(NSObject *)observer;
@end

NS_ASSUME_NONNULL_END
