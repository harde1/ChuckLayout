//
//  UIView+FALayout.m
//  MyLayoutParserDemo
//
//  Created by 梁慧聪 on 2018/3/17.
//  Copyright © 2018年 youngsoft. All rights reserved.
//
#import "UIView+FALayout.h"
#import <objc/runtime.h>

@implementation FALayout

@end

@implementation UIView (FALayout)
-(void)setLayout_id:(NSString *)layout_id{
    objc_setAssociatedObject(self, @selector(layout_id), layout_id, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
-(NSString *)layout_id{
    return objc_getAssociatedObject(self, _cmd);
}

-(FALayout *)layout_top{
    FALayout * layout = objc_getAssociatedObject(self, _cmd);
    if (!layout) {
        layout = [[FALayout alloc]init];
        layout.attribute = NSLayoutAttributeTop;
        layout.multiplier = 1.0;
        layout.item = self;
    }
    return layout;
}
-(void)setLayout_top:(FALayout *)layout_top{
    objc_setAssociatedObject(self, @selector(layout_top), layout_top, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(FALayout *)layout_bottom{
    FALayout * layout = objc_getAssociatedObject(self, _cmd);
    if (!layout) {
        layout = [[FALayout alloc]init];
        layout.attribute = NSLayoutAttributeBottom;
        layout.multiplier = 1.0;
        layout.item = self;
    }
    return layout;
}
-(void)setLayout_bottom:(FALayout *)layout_bottom{
    objc_setAssociatedObject(self, @selector(layout_bottom), layout_bottom, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(FALayout *)layout_left{
    FALayout * layout = objc_getAssociatedObject(self, _cmd);
    if (!layout) {
        layout = [[FALayout alloc]init];
        layout.attribute = NSLayoutAttributeLeft;
        layout.multiplier = 1.0;
        layout.item = self;
    }
    return layout;
}
-(void)setLayout_left:(FALayout *)layout_left{
    objc_setAssociatedObject(self, @selector(layout_left), layout_left, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(FALayout *)layout_right{
    FALayout * layout = objc_getAssociatedObject(self, _cmd);
    if (!layout) {
        layout = [[FALayout alloc]init];
        layout.attribute = NSLayoutAttributeRight;
        layout.multiplier = 1.0;
        layout.item = self;
    }
    return layout;
}
-(void)setLayout_right:(FALayout *)layout_right{
    objc_setAssociatedObject(self, @selector(layout_right), layout_right, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(FALayout *)layout_height{
    FALayout * layout = objc_getAssociatedObject(self, _cmd);
    if (!layout) {
        layout = [[FALayout alloc]init];
        layout.attribute = NSLayoutAttributeHeight;
        layout.multiplier = 1.0;
        layout.item = self;
    }
    return layout;
}
-(void)setLayout_height:(FALayout *)layout_height{
    objc_setAssociatedObject(self, @selector(layout_height), layout_height, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(FALayout *)layout_width{
    FALayout * layout = objc_getAssociatedObject(self, _cmd);
    if (!layout) {
        layout = [[FALayout alloc]init];
        layout.attribute = NSLayoutAttributeWidth;
        layout.multiplier = 1.0;
        layout.item = self;
    }
    return layout;
}
-(void)setLayout_width:(FALayout *)layout_width{
    objc_setAssociatedObject(self, @selector(layout_width), layout_width, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
