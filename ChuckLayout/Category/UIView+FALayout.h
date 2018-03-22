//
//  UIView+FALayout.h
//  MyLayoutParserDemo
//
//  Created by 梁慧聪 on 2018/3/17.
//  Copyright © 2018年 youngsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface FALayout :NSObject
@property (nonatomic, assign) NSLayoutAttribute attribute;
@property (nonatomic, strong) UIView * item;
@property (nonatomic, assign) CGFloat multiplier;
@property (nonatomic, assign) CGFloat constant;
@end
@interface UIView (FALayout)
@property (nonatomic, copy) NSString * layout_id;

@property (nonatomic, strong) FALayout * layout_top;
@property (nonatomic, strong) FALayout * layout_bottom;
@property (nonatomic, strong) FALayout * layout_left;
@property (nonatomic, strong) FALayout * layout_right;
@property (nonatomic, strong) FALayout * layout_width;
@property (nonatomic, strong) FALayout * layout_height;
@end
