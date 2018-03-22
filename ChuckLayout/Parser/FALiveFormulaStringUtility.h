//
//  FALiveFormulaStringUtility.h
//  FALiveCommon
//
//  Created by 梁慧聪 on 2018/3/20.
//  Copyright © 2018年 kugou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FALiveFormulaStringUtility : NSObject
+ (NSString *)calcComplexFormulaString:(NSString *)formula;
//所有括号里面的公式，优先求解
+ (NSString *)firstCalcComplexFormulaString:(NSString *)formula;
@end
