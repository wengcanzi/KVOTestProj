//
//  ViewController.m
//  KVOTestProj
//
//  Created by anjubao on 2019/4/28.
//  Copyright © 2019年 cz. All rights reserved.
//

#import "ViewController.h"
#import "CZTestViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    button.center = self.view.center;
    button.backgroundColor = [UIColor blueColor];
    [self.view addSubview:button];
    [button addTarget:self action:@selector(pushToNext) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)pushToNext {
    [self presentViewController:[[CZTestViewController alloc] init] animated:YES completion:nil];
}

@end
