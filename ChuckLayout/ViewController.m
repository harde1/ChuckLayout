//
//  ViewController.m
//  ChuckLayout
//
//  Created by 梁慧聪 on 2018/3/19.
//  Copyright © 2018年 梁慧聪. All rights reserved.
//

#import "ViewController.h"
#import "ParserManager.h"
@interface ViewController ()
@property (nonatomic, strong) ParserManager *parserManager;
@property (nonatomic, strong) UIView * viewRed;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    __weak typeof(self) weakSelf = self;
    NSString * path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"xml"];
    NSXMLParser * parser = [self.parserManager parserFilePath:path withBlock:^(ParserManager *parser, NSMutableDictionary *xmlDictionary, NSString *jsonString, UIView *view, NSError *error) {
        if (error) {
            NSLog(@"error:%@",error);
            return;
        }
    } superView:self.view];
    [parser parse];
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (ParserManager *)parserManager{
    if (!_parserManager) {
        _parserManager = [[ParserManager alloc] init];
    }
    return _parserManager;
}
- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    [self.parserManager parserAgain];
}
@end
