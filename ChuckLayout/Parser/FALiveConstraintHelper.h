//
//  FALiveConstraintHelper.h
//  FALiveCommon
//
//  Created by 梁慧聪 on 2018/3/20.
//  Copyright © 2018年 kugou. All rights reserved.
//

#import <UIKit/UIKit.h>

#define ConstraintAdd(ITEM,ATTR1,RELATION,ITEM2,ATTR2,MULTIPLIER,CONSTANT) [FALiveConstraintHelper constraintItem:ITEM attr1:ATTR1 rel:RELATION item2:ATTR2 mul:MULTIPLIER constant:CONSTANT]

@interface FALiveConstraintHelper : NSObject
+ (BOOL)isPureNum:(NSString*)string;
+ (void)formats:(NSArray *)formats views:(NSDictionary<NSString *, id> *)views;
+ (NSArray<NSLayoutConstraint *>*)format:(NSString *)format views:(NSDictionary<NSString *, id> *)views;
+ (NSLayoutConstraint *)constraintItem:(UIView *)ITEM attr1:(NSLayoutAttribute)ATTR1 rel:(NSLayoutRelation)RELATION item2:(UIView *)ITEM2 attr2:(NSLayoutAttribute)ATTR2 mul:(CGFloat)MULTIPLIER constant:(CGFloat)CONSTANT;
//布局关系返回字符串
+ (NSString *)layoutAttributeIndex:(NSLayoutAttribute)attribute;
//字符串换回布局关系
+ (NSLayoutAttribute)layoutAttributeEnum:(NSString *)attributeEnum;
//是否是布局关系
+ (BOOL)isLayoutAttribute:(NSLayoutAttribute)attribute;
@end
