//
//  CZTestViewController.m
//  KVOTestProj
//
//  Created by anjubao on 2019/4/29.
//  Copyright © 2019年 cz. All rights reserved.
//

#import "CZTestViewController.h"
#import "CZTestKVOObject.h"
#import "KVOBlockAndTargetAction/NSObject+KVOExtension.h"

@interface CZTestViewController ()
@property (nonatomic, strong) CZTestKVOObject *object1;
@property (nonatomic, strong) CZTestKVOObject *object2;
@end

@implementation CZTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    button.center = self.view.center;
    button.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:button];
    [button addTarget:self action:@selector(popVC) forControlEvents:UIControlEventTouchUpInside];
    
    self.object1 = [[CZTestKVOObject alloc] init];
    self.object2 = [[CZTestKVOObject alloc] init];
    [self.object1 description];
    [self.object2 description];
    
    [self.object1 cz_addObserver:self propertyKey:@"data" action:@selector(valueChange:new:key:)];
    
    [self.object1 cz_addObserver:self propertyKey:@"data" callback:^(NSString * _Nonnull observedKey, id  _Nonnull oldValue, id  _Nonnull newValue) {
        NSLog(@"old: %@, new: %@ key: %@", oldValue, newValue, observedKey);
        
    }];
    
    //    [self.object1 cz_addObserver:self originalSelector:@selector(data) callback:^(NSString *observedKey, id oldValue, id newValue) {
    //        NSLog(@"old: %@, new: %@ key: %@", oldValue, newValue, observedKey);
    //    }];
    
    [self.object1 description];
    [self.object2 description];
    
    self.object1.data = @"cz";
    self.object1.length = 10;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
//    [self.object1 cz_removeObserver:self originalSelector:@selector(data)];
}

- (void)valueChange:(id)oldValue new:(id)newValue key:(id)key {
    NSLog(@"old:%@ new:%@ key:%@", oldValue, newValue, key);
}

- (void)popVC {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
    //可以不手动调用cz_removeObserver
    NSLog(@"1:%@,2:%@", _object1,_object2);
    NSLog(@"退出并释放");
}

@end
