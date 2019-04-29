//
//  CZKVOItem.m
//  KVOTestProj
//
//  Created by anjubao on 2019/4/28.
//  Copyright © 2019年 cz. All rights reserved.
//

#import "CZKVOItem.h"

@implementation CZKVOItem

- (instancetype)initWithObserver:(NSObject *)observer
                             key:(NSString *)key
                           block:(cz_KVOObserveBlock)block {
    self = [super init];
    if (self) {
        self.observer = observer;
        self.key = key;
        self.block = block;
    }
    return self;
}

- (instancetype)initWithObserver:(NSObject *)observer
                             key:(NSString *)key
                          action:(SEL)action {
    self = [super init];
    if (self) {
        self.observer = observer;
        self.key = key;
        self.action = action;
    }
    return self;
}

- (void)dealloc {
    if (_observer && _key) {
        [self cz_removeObserver:_observer propertyKey:_key];
    }
}

@end
