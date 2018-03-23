//
//  FALiveConstraintHelper.m
//  FALiveCommon
//
//  Created by 梁慧聪 on 2018/3/20.
//  Copyright © 2018年 kugou. All rights reserved.
//

#import "FALiveConstraintHelper.h"
#import "FALiveFormulaStringUtility.h"

@interface FALiveConstraintHelper()
@property (nonatomic, strong) NSArray * layoutAttributeArr;
@end
@implementation FALiveConstraintHelper
+ (instancetype)shareInstance
{
    static id _instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}
-(NSArray *)layoutAttributeArr{
    if (!_layoutAttributeArr) {
        _layoutAttributeArr = [[NSArray alloc] initWithObjects:
                               @"notAnAttribute",
                               @"left",
                               @"right",
                               @"top",
                               @"bottom",
                               @"leading",
                               @"trailing",
                               @"width",
                               @"height",
                               @"centerX",
                               @"centerY",
                               @"baseline",
                               @"firstBaseline",
                               @"marginLeft",
                               @"marginRight",
                               @"marginTop",
                               @"marginBottom",
                               @"leadingMargin",
                               @"trailingMargin",
                               @"centerXWithinMargins",
                               @"centerYWithinMargins", nil];
    }
    return _layoutAttributeArr;
}
+ (BOOL)isPureNum:(NSString*)string{
    NSScanner* scan = [NSScanner scannerWithString:string];
    float fval;
    int val;
    return (([scan scanFloat:&fval] && [scan isAtEnd]) || ([scan scanInt:&val] && [scan isAtEnd]));
}

#pragma mark - 布局整理
+ (NSArray<NSLayoutConstraint *> *)format:(NSString *)format views:(NSDictionary<NSString *, id> *)views{
    return [self format:format opts:0 mts:nil views:views];
}
+ (NSArray<NSLayoutConstraint *> *)format:(NSString *)format opts:(NSLayoutFormatOptions)opts mts:(nullable NSDictionary<NSString *,id> *)metrics views:(NSDictionary<NSString *, id> *)views{
    format = [format stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableArray * arr = [NSMutableArray array];
    //判断如果是符合 vfl 规则的，走 vfl 规则
    if ([format hasPrefix:@"H:"]||[format hasPrefix:@"V:"]) {
        return [NSLayoutConstraint constraintsWithVisualFormat:format options:opts metrics:metrics views:views];
    }
    NSLayoutConstraint * constraint = nil;
    if ([format isKindOfClass:[NSString class]]) {
        UIView * itemView = nil;//对象
        NSLayoutAttribute attribute = NSLayoutAttributeNotAnAttribute;//对象关系
        NSLayoutRelation relation = NSLayoutRelationEqual;//等式
        UIView * item2View = nil;//依赖对象
        NSLayoutAttribute attribute2 = NSLayoutAttributeNotAnAttribute;//依赖关系
        CGFloat multiplier = 1.0;//系数
        CGFloat c = 0;//偏移量
        NSInteger priority = UILayoutPriorityRequired;//优先级
        
        //////
        NSString * item = @"";//对象
        NSString * attri = @"";//关系
        NSString * relate = ([format rangeOfString:@"="].location != NSNotFound)?@"=":@"";//等式
        NSString * item2 = @"";//依赖对象
        NSString * attri2 = @"";//依赖关系
        NSString * multmp = @"1.0";//系数
        NSString * cFormula = @"0";//偏移量
        NSString * lPriority = @"1000";//优先级
        //////
        if ([format rangeOfString:@">"].location != NSNotFound) {
            relate = [@">" stringByAppendingString:relate];
            relation = NSLayoutRelationGreaterThanOrEqual;
        }else if([format rangeOfString:@"<"].location != NSNotFound){
            relate = [@"<" stringByAppendingString:relate];
            relation = NSLayoutRelationLessThanOrEqual;
        }
        if ([relate isEqualToString:@""]) {
            NSAssert(0, @"布局公式没有关系等式\">=、=、<=\":%@",format);
            return arr;
        }
        NSArray * formatArr = [format componentsSeparatedByString:relate];
        if (formatArr.count!=2) {
            NSAssert(0, @"布局公式没有一对一的约束对象:%@",format);
            return arr;
        }
        ////// 左边等式 /////////////
        NSString * leftFormula = [formatArr firstObject];
        for (NSString * key in [views allKeys]) {
            if ([leftFormula rangeOfString:key].location!=NSNotFound) {
                //找到item2View
                item = key;
                itemView = views[item];
                break;
            }
        }
       
        if (!itemView) {
            NSAssert(0, @"布局公式没有主要的约束对象:%@",format);
            return arr;
        }
        
        for (NSString * att in [FALiveConstraintHelper shareInstance].layoutAttributeArr) {
            if ([leftFormula rangeOfString:att].location!=NSNotFound) {
                NSString * tmp=[NSString stringWithFormat:@"%@.%@",item,att];
                if ([leftFormula isEqualToString:tmp]) {
                    //找到attribute
                    attri = att;
                    attribute = [FALiveConstraintHelper layoutAttributeEnum:att];
                    break;
                }
            }
        }
        if (![leftFormula isEqualToString:item]&&[attri isEqualToString:@""]) {
            NSAssert(0, @"左边布局公式没有对象关系:%@",format);
            return arr;
        }
         ////// 左边等式 end /////////////
        ////// 右边边等式 /////////////
        NSString * rightFormula = [formatArr lastObject];
        
        //约束优先级priority
        ///例子: _lbName.left = _ivSinger + 5 @ 750
        if ([rightFormula rangeOfString:@"@"].location!=NSNotFound) {
            NSArray * tmp = [rightFormula componentsSeparatedByString:@"@"];
            rightFormula = [tmp firstObject];
            lPriority = [tmp lastObject];
            if ([self isPureNum:lPriority]) {
                priority = [lPriority integerValue];
            }
        }
        //// 右边是否是纯数字，无依赖对象
        if ([self isPureNum:rightFormula]) {
            item2View = nil;
            attribute2 = NSLayoutAttributeNotAnAttribute;
            multiplier = 1.0;
            c = [rightFormula floatValue];
            if (attribute != NSLayoutAttributeWidth && attribute != NSLayoutAttributeHeight) {
                if ((attribute & (NSLayoutAttributeLeft|NSLayoutAttributeTop|NSLayoutAttributeBottom|NSLayoutAttributeRight|NSLayoutAttributeLeading|NSLayoutAttributeTrailing))== attribute) {
                    item2View = itemView.superview;
                    attribute2 = attribute;
                }else if ((attribute & (NSLayoutAttributeCenterX|NSLayoutAttributeCenterY))== attribute){
                    item2View = itemView.superview;
                    attribute2 = attribute;
                }
            }
        }else{
            /// 右边有依赖对象
            NSString * item2attri2=@"";
            for (NSString * key in [views allKeys]) {
                if ([rightFormula rangeOfString:key].location!=NSNotFound) {
                    //找到item2View
                    item2 = key;
                    item2View = views[item2];
                    item2attri2=item2;
                    break;
                }
            }
            if (!item2View) {
                NSAssert(0, @"布局公式没有约束的依赖对象:%@",format);
                return arr;
            }
            for (NSString * att in [FALiveConstraintHelper shareInstance].layoutAttributeArr) {
                if ([rightFormula rangeOfString:att].location!=NSNotFound) {
                    NSString * tmp=[NSString stringWithFormat:@"%@.%@",item2,att];
                    if ([rightFormula rangeOfString:tmp].location!=NSNotFound) {
                        //找到attribute2
                        attri2 = att;
                        attribute2 = [FALiveConstraintHelper layoutAttributeEnum:attri2];
                        item2attri2 = tmp;
                        break;
                    }
                }
            }
            ////右边依赖对象没有对应的依赖关系，默认与左边关系一致
            if ([attri2 isEqualToString:@""]) {
                //例子 view.left = view1
                attribute2 = attribute;
                attri2 = attri;
            }
            
            ////////// 至此右边已经找到依赖的对象，以及依赖的关系,以下部分是寻找系数以及偏移值
            
            ////右边 无系数与偏移值，左边依赖关系与右边某对象依赖关系直接绑定
            if ([rightFormula isEqualToString:item2attri2]) {
                //例子：view.left = view1  _contentView.left=self.left
                multiplier = 1.0;
                c = 0;
            } else {
                ///// 求系数关系，处理系数关系
                //例子： self.width = 2.0 * contentView.width * 2.5 + 1
                NSString * constanttmp = item2attri2;
                NSString * replace=@"1234567891011121314151617181920";
               
                //例子： self.width = 2.0 * contentView.width * 2.5 + 1 ----> self.width = (1+2.0+1) * 1234567891011121314151617181920 * 2.5 + 1
                NSString * result = [rightFormula stringByReplacingOccurrencesOfString:item2attri2 withString:replace];
                
                ///优先计算括号里面的值，去掉所有括号
                //例子： self.width = (1+2.0+1) * 1234567891011121314151617181920 * 2.5 + 1  ----> self.width = 3.0 * 1234567891011121314151617181920 * 2.5 + 1
                result = [FALiveFormulaStringUtility firstCalcComplexFormulaString:result];
                //例子： self.width = 3.0 * 1234567891011121314151617181920 * 2.5 + 1  ----> self.width = 3.0 * contentView.width * 2.5 + 1
                result = [result stringByReplacingOccurrencesOfString:replace withString:item2attri2];
                /////公式只寻找乘(*)关系，不找除(/)关系 test
                BOOL isleft = ([rightFormula rangeOfString:[@"*" stringByAppendingString:item2attri2]].location!=NSNotFound);
                BOOL isRight = ([rightFormula rangeOfString:[item2attri2 stringByAppendingString:@"*"]].location!=NSNotFound);
                
                if (!isleft && !isRight){//没有系数
                    multiplier = 1.0;
                }else{///含有系数
                    
                    
                    ///去掉符号，留下所有数字
                    NSCharacterSet *doNotWant = [NSCharacterSet characterSetWithCharactersInString:@"[]{}（#%-*+=_）\\|~(＜＞$%^&*)_+ "];
                    NSArray * tmp = [result componentsSeparatedByCharactersInSet:doNotWant];
                    ///index : 找到依赖对象以及依赖关系所在的位置
                    NSInteger index = [tmp indexOfObject:item2attri2];
                    if (isleft && isRight) {
                        //例子： self.width = 2.0 * contentView.width * 2.5 + 1
                        NSInteger tmpIndex = index-1;
                        CGFloat muls = 1.0;
                        NSString * mulLeft = @"";
                        NSString * mulRight = @"";
                        if (tmpIndex<=tmp.count && tmpIndex>=0) {
                            mulLeft = tmp[tmpIndex];
                            if ([self isPureNum:mulLeft]) {
                                muls = muls * [mulLeft floatValue];
                            }else{
                                NSAssert(0, @"布局右边公式找不到系数:%@",rightFormula);
                            }
                        }else{
                            NSAssert(0, @"布局右边公式找不到系数:%@",rightFormula);
                        }
                        tmpIndex = index+1;
                        if (tmpIndex<=tmp.count && tmpIndex>=0) {
                            mulRight = tmp[tmpIndex];
                            if ([self isPureNum:mulLeft]) {
                                muls = muls * [mulLeft floatValue];
                            }else{
                                NSAssert(0, @"布局右边公式找不到系数:%@",rightFormula);
                            }
                        }else{
                            NSAssert(0, @"布局右边公式找不到系数:%@",rightFormula);
                        }
                        multmp = [NSString stringWithFormat:@"%@*%@",mulLeft,mulRight];
                        multiplier = muls;
                        constanttmp = [NSString stringWithFormat:@"%@*%@*%@",mulLeft,item2attri2,mulRight];
                        
                    }else{
                        //例子： self.width = 2.0 * contentView.width   或者   self.width =  contentView.width * 2.0
                        //系数找到了
                        if (isleft) {
                            index--;
                        }else{
                            index++;
                        }
                        if (index<=tmp.count && index>=0) {
                            multmp = tmp[index];
                            if ([self isPureNum:multmp]) {
                                multiplier = [multmp floatValue];
                                if (isleft) {
                                    constanttmp = [NSString stringWithFormat:@"%@*%@",multmp,item2attri2];
                                }else{
                                    constanttmp = [NSString stringWithFormat:@"%@*%@",item2attri2,multmp];
                                }
                            }else{
                                NSAssert(0, @"布局右边公式找不到系数:%@",rightFormula);
                            }
                        }else{
                            NSAssert(0, @"布局右边公式找不到系数:%@",rightFormula);
                        }
                    }
                }
                /////排除依赖对象以及系数后，计算偏移量
                cFormula = [result stringByReplacingOccurrencesOfString:constanttmp withString:@"0"];
                c = [[FALiveFormulaStringUtility calcComplexFormulaString:cFormula] floatValue];
            }
        }
        BOOL leftEqualItem = ([leftFormula isEqualToString:item]);
        BOOL rightEqualItem2 = ([attri2 isEqualToString:@""]);
//        NSString * checkFormat = [NSString stringWithFormat:@"[%@]%@%@%@%@[%@]%@*%@+(%@)",item,leftEqualItem?@"":@".",attri,relate,item2,rightEqualItem2?@"":@".",attri2,multmp,cFormula];
//        NSLog(@"format:%@,————:%@",format,checkFormat);
        
        ////右边 是否是单纯关联该对象的四维属性
        if (!leftEqualItem) {
            constraint = [self constraintItem:itemView attr1:attribute rel:relation item2:item2View attr2:attribute2 mul:multiplier constant:c];
            if (priority!=UILayoutPriorityRequired) {
                constraint.priority = priority;
            }
            constraint.identifier = format;
            [arr addObject:constraint];
        }else{//四维设置 top、left、bottom、right
            //例子：view = view1     view = view1 * 2 + 10
            if (!rightEqualItem2) {
                NSAssert(0, @"四维属性设置，格式不规范:%@",format);
                return arr;
            }
            for (NSInteger attribute = NSLayoutAttributeLeft; attribute<=NSLayoutAttributeBottom; attribute++) {
                constraint = [self constraintItem:itemView attr1:attribute rel:relation item2:item2View attr2:attribute mul:multiplier constant:((attribute%2==0)?1:-1)*c];
                if (priority!=UILayoutPriorityRequired) {
                    constraint.priority = priority;
                }
                constraint.identifier = format;
                [arr addObject:constraint];
            }
        }
    }
    return arr;
}
+ (NSArray<NSLayoutConstraint *> *)formats:(NSArray *)formats views:(NSDictionary<NSString *, id> *)views{
    return [self formats:formats opts:0 mts:nil views:views];
}
+ (NSArray<NSLayoutConstraint *> *)formats:(NSArray *)formats opts:(NSLayoutFormatOptions)opts mts:(nullable NSDictionary<NSString *,id> *)metrics views:(NSDictionary<NSString *, id> *)views{
    NSMutableArray * arr = [NSMutableArray array];
    if ([formats isKindOfClass:[NSArray class]]&& formats.count>0) {
        for (NSString *  _Nonnull format in formats) {
            [arr addObjectsFromArray:[FALiveConstraintHelper format:format opts:opts mts:metrics views:views]];
        }
    }
    return arr;
}
+ (NSLayoutConstraint *)constraintItem:(UIView *)ITEM attr1:(NSLayoutAttribute)ATTR1 rel:(NSLayoutRelation)RELATION item2:(UIView *)ITEM2 attr2:(NSLayoutAttribute)ATTR2 mul:(CGFloat)MULTIPLIER constant:(CGFloat)CONSTANT{
    return ({
        UIView * SUPERVIEW = nil;
        if (!ITEM2 && ((ATTR1 == NSLayoutAttributeWidth) || (ATTR1 == NSLayoutAttributeHeight))) {
            SUPERVIEW = ITEM;
        }else{
            UIView *ITEM2_SUPER = ITEM2;
            while (!SUPERVIEW && ITEM2_SUPER) {
                UIView *ITEM_SUPER = ITEM;
                while (!SUPERVIEW && ITEM_SUPER) {
                    if (ITEM2_SUPER == ITEM_SUPER) {
                        SUPERVIEW = ITEM2_SUPER;
                    }
                    ITEM_SUPER = ITEM_SUPER.superview;
                }
                ITEM2_SUPER = ITEM2_SUPER.superview;
            }
        }
        ITEM.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint * constraint = [NSLayoutConstraint constraintWithItem:ITEM attribute:ATTR1 relatedBy:RELATION toItem:ITEM2 attribute:ATTR2 multiplier:MULTIPLIER constant:CONSTANT];
        [SUPERVIEW addConstraint:constraint];
        constraint;
    });
}
+ (NSString *)layoutAttributeIndex:(NSLayoutAttribute)attribute{
    return [[FALiveConstraintHelper shareInstance].layoutAttributeArr objectAtIndex:attribute];
}
+ (NSLayoutAttribute)layoutAttributeEnum:(NSString *)attributeEnum{
    return [[FALiveConstraintHelper shareInstance].layoutAttributeArr indexOfObject:attributeEnum];
}
+ (BOOL)isLayoutAttribute:(NSLayoutAttribute)attribute{
    return ((attribute & (NSLayoutAttributeLeft|NSLayoutAttributeRight|NSLayoutAttributeTop|NSLayoutAttributeBottom|NSLayoutAttributeLeading|NSLayoutAttributeTrailing|NSLayoutAttributeWidth|NSLayoutAttributeHeight|NSLayoutAttributeCenterX|NSLayoutAttributeCenterY|NSLayoutAttributeLastBaseline|NSLayoutAttributeBaseline|
                          NSLayoutAttributeFirstBaseline|NSLayoutAttributeLeftMargin|NSLayoutAttributeRightMargin|NSLayoutAttributeTopMargin|NSLayoutAttributeBottomMargin|NSLayoutAttributeLeadingMargin|NSLayoutAttributeTrailingMargin|NSLayoutAttributeCenterXWithinMargins|NSLayoutAttributeCenterYWithinMargins|NSLayoutAttributeNotAnAttribute)) == attribute);
}
@end
