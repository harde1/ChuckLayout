//
//  ParserManager.m
//  MyLayoutParserDemo
//
//  Created by 梁慧聪 on 2017/6/20.
//  Copyright © 2017年 youngsoft. All rights reserved.
//

#import "ParserManager.h"
#import "YSResourceManager.h"
#import "NSString+Property.h"
#import "UIView+FALayout.h"
#import <objc/runtime.h>
#import "FormulaStringCalcUtility.h"
const NSArray *___NSLayoutAttributeArr;
// 创建初始化函数。等于用宏创建一个getter函数
#define NSLayoutAttributeGet (___NSLayoutAttributeArr == nil ? ___NSLayoutAttributeArr = [[NSArray alloc] initWithObjects:\
@"NotAnAttribute",\
@"left",\
@"right",\
@"top",\
@"bottom",\
@"leading",\
@"trailing",\
@"width",\
@"height",\
@"centerX",\
@"centerY",\
@"baseline",\
@"firstBaseline",\
@"marginLeft",\
@"marginRight",\
@"marginTop",\
@"marginBottom",\
@"leadingMargin",\
@"trailingMargin",\
@"centerXWithinMargins",\
@"centerYWithinMargins", nil] : ___NSLayoutAttributeArr)

// 枚举 to 字串
#define NSLayoutAttributeString(type) ([NSLayoutAttributeGet objectAtIndex:type])
// 字串 to 枚举
#define NSLayoutAttributeEnum(string) ([NSLayoutAttributeGet indexOfObject:string])

#define SRCROOT @"/Users/chuckliang/Documents/gitProject/ChuckLayout/ChuckLayout/xmls"
@interface ParserManager()<NSXMLParserDelegate>
@property (nonatomic, strong) NSMutableArray * formats;
@property (nonatomic, strong) NSMutableDictionary * views;
@end
@implementation ParserManager
- (NSXMLParser *)parserFilePath:(NSString *)path withBlock:(XMLParserBlock)block{
    return [self parserFilePath:path withBlock:block superView:nil];
}
- (NSXMLParser *)parserFilePath:(NSString *)path withBlock:(XMLParserBlock)block superView:(UIView *)superView{
    if (_parser) {
        [_parser abortParsing];
        _parser = nil;
    }
#if TARGET_IPHONE_SIMULATOR
    NSString * origfile = [path lastPathComponent];
    origfile = [NSString stringWithFormat:@"%@/%@",SRCROOT,origfile];
    path = origfile;
//    NSLog(@"当前文件路径是:%@",path);
#endif
    NSURL * url = [NSURL fileURLWithPath:path];
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    xmlParser.superView = superView;
    xmlParser.xmlUrl = url;
    xmlParser.delegate = self;
    xmlParser.xmlParserBlock = block;
    self.parser = xmlParser;
    return xmlParser;
}
- (void)parserAgain{
    [self parserFilePath:[self.parser.xmlUrl absoluteString] withBlock:self.parser.xmlParserBlock superView:self.parser.superView];
    [self.parser parse];
}

#pragma mark xmlparser
//step 1 :准备解析
- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    /*
     * 开始解析XML文档时 设定一些解析状态
     *     设置isProcessing为true，表示XML正在被解析
     *     设置justProcessStartElement为true，表示刚刚没有处理过 startElement事件
     */
    [parser configProcess:YES];
    [parser configJustProcessStartElement:YES];
    //清空字符
    parser.jsonString = @"";
    for (UIView * sub in [self.views allValues]) {
        if (![sub isEqual:self.parser.superView]) {
            [sub removeFromSuperview];
        }
    }
    [self.formats removeAllObjects];
    [self.views removeAllObjects];
}
//step 5：解析结束
- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    [parser configProcess:NO];
    //转化为字典
    NSError * error = nil;
    parser.xmlDictionary = [NSJSONSerialization JSONObjectWithData:[parser.jsonString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
    if (!error) {
        [self drawView:parser error:error];
    }
}
//step 2：准备解析节点
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    /*
     * 是否刚刚处理完一个startElement事件
     *     如果是 则表示这个元素是父元素的第一个元素 。
     *     如果不是 则表示刚刚处理完一个endElement事件，即这个元素不是父元素的第一个元素
     */
    BOOL justProcessStartElement = [parser checkJustProcessStartElement];
    if(!justProcessStartElement){//节点解析完毕
        parser.jsonString = [parser.jsonString stringByAppendingString:@","];
        [parser configJustProcessStartElement:YES];
    }
    parser.jsonString = [parser.jsonString stringByAppendingString:@"{"];
    parser.jsonString = [parser.jsonString stringByAppendingFormat:@"\"elementName\":\"%@\"",elementName];
    parser.jsonString = [parser.jsonString stringByAppendingString:@","];
    //将解析出来的元素属性添加到JSON字符串中
    
    parser.jsonString = [parser.jsonString stringByAppendingString:@"\"attrs\":{"];
    NSString * attribute = @"";
    if ([attributeDict isKindOfClass:[NSDictionary class]]) {
        __block NSMutableArray * attriMut = [NSMutableArray array];
        [attributeDict enumerateKeysAndObjectsUsingBlock:^(NSString * key, NSString * obj, BOOL * _Nonnull stop) {
            NSString * keyStr = [[key componentsSeparatedByString:@":"] lastObject];
            [attriMut addObject:[NSString stringWithFormat:@"\"%@\":\"%@\"",keyStr,obj]];
        }];
        attribute = [attriMut componentsJoinedByString:@","];
        parser.jsonString = [parser.jsonString stringByAppendingString:attribute];
    }
    parser.jsonString = [parser.jsonString stringByAppendingString:@"}"];
    parser.jsonString = [parser.jsonString stringByAppendingString:@","];
    //将解析出来的元素的子元素列表添加到JSON字符串中
    parser.jsonString = [parser.jsonString stringByAppendingString:@"\"childElements\":["];
}
//step 4 ：解析完当前节点
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    [parser configJustProcessStartElement:NO];
    parser.jsonString = [parser.jsonString stringByAppendingString:@"]}"];
    
}
//error
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError{
    if (parser.xmlParserBlock) {
        parser.xmlParserBlock(self,parser.xmlDictionary, parser.jsonString,parser.xmlView ,parseError);
    }
}
- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError{
    if (parser.xmlParserBlock) {
        parser.xmlParserBlock(self,parser.xmlDictionary, parser.jsonString,parser.xmlView, validationError);
    }
}
//step 3:获取首尾节点间内容
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{}
//step 6：获取cdata块数据
- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock{}

- (void)drawView:(NSXMLParser *)parser error:(NSError *)error{
    parser.xmlView = [self createViewByDict:parser.xmlDictionary];
    [self recurPrintPath:parser.xmlDictionary parent:parser.xmlView from:0 superView:parser.superView];
    
    [ParserManager formats:self.formats views:self.views];
    
    if (parser.xmlParserBlock) {
        parser.xmlParserBlock(self,parser.xmlDictionary, parser.jsonString,parser.xmlView, error);
    }
}
- (UIView *)createViewByDict:(NSDictionary *)dict{
    NSString * elementName = dict[@"elementName"];
    NSDictionary * attrs = dict[@"attrs"];
    UIView * view = nil;
    
    if (elementName.length>0) {
        if ([elementName isEqualToString:@"UICollectionView"]) {
            
            UICollectionViewLayout * layout = [NSClassFromString(attrs[@"layout"]) new];
            NSString *propertys = attrs[@"layout_propertys"];
            if (propertys) {
                 __autoreleasing NSError* error = nil;
                
                NSDictionary *layout_propertys = [NSJSONSerialization JSONObjectWithData:[propertys dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
                if (layout_propertys) {
                    [layout_propertys enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                        if ([key hasSuffix:@"Size"]) {
                            obj = [NSValue valueWithCGSize:CGSizeFromString(obj)];
                        }
                        [layout setValue:obj forKey:key];
                    }];
                    
                }
            }
            if (layout) {
                UICollectionView * coll = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
                view = coll;
            }
        }else{
            
        }
    }
    if (!view) {
        view = [NSClassFromString(elementName) new];
    }
    NSString * addr = [NSString stringWithFormat:@"%p", self.parser.superView];
    addr = [addr stringByReplacingOccurrencesOfString:@"0x" withString:@""];
    NSString * viewaddr = [NSString stringWithFormat:@"%p", view];
    viewaddr = [viewaddr stringByReplacingOccurrencesOfString:@"0x" withString:@""];
    NSString * layout_id = [NSString stringWithFormat:@"%@%@%@",elementName,addr,viewaddr];
    if (attrs && attrs[@"id"]) {
        layout_id = attrs[@"id"];
    }
    view.layout_id = layout_id;
    [self.views setObject:view forKey:view.layout_id];
    
    return view;
}

- (void)recurPrintPath:(NSDictionary *)dict parent:(UIView *)parant from:(int)from superView:(UIView *)superView{
    for (NSString * key in dict.allKeys) {
        if ([dict[key] isKindOfClass:[NSDictionary class]]) {//字典是面向属性的最后一关
            if (from!=0) {
                //这里面的都是子节点
                UIView * view = [self createViewByDict:dict];
                if (from==2) {
                    [parant addSubview:view];
                }
                parant = view;
            }
            
            if(!parant.superview && superView){
                superView.layout_id = @"parent";
                [self.views setObject:superView forKey:superView.layout_id];
                [superView addSubview:parant];
            }
            
            [self recurPrintPath:dict[key] parent:parant from:1 superView:superView];
            
        }else if ([dict[key] isKindOfClass:[NSArray class]]){
            for (NSDictionary * sub in dict[key]) {
                [self recurPrintPath:sub parent:parant from:2 superView:superView];
            }
        }else{
            if (![key isEqualToString:@"elementName"]) {
                [self configProperty:key value:dict[key] view:parant];
            }
        }
    }
}
+ (BOOL)isPureFloat:(NSString*)string{
    NSScanner* scan = [NSScanner scannerWithString:string];
    float val;
    return[scan scanFloat:&val] && [scan isAtEnd];
}
+ (BOOL)isPureInt:(NSString*)string{
    NSScanner* scan = [NSScanner scannerWithString:string];
    int val;
    double fval;
    return ([scan scanInt:&val] || [scan scanDouble:&fval]) && [scan isAtEnd];
}
+ (BOOL)isPureNum:(NSString*)string{
    return ([self isPureInt:string] || [self isPureFloat:string]);
}
#pragma mark - 属性映射表，这里乱写，要重新找一个方案
+ (void)formats:(NSArray *)formats views:(NSDictionary<NSString *, id> *)views{
    if ([formats isKindOfClass:[NSArray class]]&& formats.count>0) {
        [formats enumerateObjectsUsingBlock:^(NSString *  _Nonnull format, NSUInteger idx, BOOL * _Nonnull stop) {
            [ParserManager format:format views:views];
        }];
    }
}
+(NSLayoutConstraint *)constraintItem:(UIView *)ITEM attr1:(NSLayoutAttribute)ATTR1 rel:(NSLayoutRelation)RELATION item2:(UIView *)ITEM2 attr2:(NSLayoutAttribute)ATTR2 mul:(CGFloat)MULTIPLIER constant:(CGFloat)CONSTANT{
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
+ (NSLayoutConstraint *)format:(NSString *)format views:(NSDictionary<NSString *, id> *)views{
    format = [format stringByReplacingOccurrencesOfString:@" " withString:@""];
    return ({
        NSLayoutConstraint * constraint = nil;
        if ([format isKindOfClass:[NSString class]]) {
            UIView * itemView = nil;
            NSLayoutAttribute attribute = NSLayoutAttributeNotAnAttribute;
            NSLayoutRelation relation = NSLayoutRelationEqual;
            UIView * item2View = nil;
            NSLayoutAttribute attribute2 = NSLayoutAttributeNotAnAttribute;
            CGFloat multiplier = 1.0;
            CGFloat c = 0;
            
            NSString * relationStr = ([format rangeOfString:@"="].location != NSNotFound)?@"=":@"";
            if ([format rangeOfString:@">"].location != NSNotFound) {
                relationStr = [relationStr stringByAppendingString:@">"];
                relation = NSLayoutRelationGreaterThanOrEqual;
            }else if([format rangeOfString:@"<"].location != NSNotFound){
                relationStr = [relationStr stringByAppendingString:@"<"];
                relation = NSLayoutRelationLessThanOrEqual;
            }
            if (![relationStr isEqualToString:@""]) {
                NSArray * formatArr = [format componentsSeparatedByString:relationStr];
                if (formatArr.count==2) {
                    NSArray * firstFormat = [[formatArr firstObject] componentsSeparatedByString:@"."];
                    NSString * item = [firstFormat firstObject];
                    NSString * attri = [firstFormat lastObject];
                    itemView = views[item];
                    if (NSLayoutAttributeEnum(attri) != NSNotFound) {
                        attribute = NSLayoutAttributeEnum(attri);
                    }
                    NSString * sec = [formatArr lastObject];
                    if ([self isPureNum:sec]) {
                        item2View = nil;
                        attribute2 = NSLayoutAttributeNotAnAttribute;
                        multiplier = 1.0;
                        c = [sec floatValue];
                    }else{
                        NSString * obj = @"";
                        for (NSString * key in [views allKeys]) {
                            if ([sec rangeOfString:key].location!=NSNotFound) {
                                //找到item2View
                                item2View = views[key];
                                obj=key;
                                break;
                            }
                        }
                        BOOL havaAttri2 = NO;
                        for (NSString * att in ___NSLayoutAttributeArr) {
                            if ([sec rangeOfString:att].location!=NSNotFound) {
                                if ([sec rangeOfString:obj].location!=NSNotFound) {
                                    //找到attribute2
                                    attribute2 = NSLayoutAttributeEnum(att);
                                    havaAttri2 = YES;
                                    obj = [NSString stringWithFormat:@"%@.%@",obj,att];
                                    break;
                                }
                            }
                        }
                        if (!havaAttri2) {
                            attribute2 = attribute;
                        }
                        //处理倍数关系
                        //1、左右是否有*
                        NSString * constanttmp = obj;
                        NSString * replace=@"1234567891011121314151617181920";
                        NSString * result = [sec stringByReplacingOccurrencesOfString:obj withString:replace];
                        result = [FormulaStringCalcUtility firstCalcComplexFormulaString:result];
                        result = [result stringByReplacingOccurrencesOfString:replace withString:obj];
                        
                        BOOL isleft = ([sec rangeOfString:[@"*" stringByAppendingString:obj]].location!=NSNotFound);
                        BOOL isRight = ([sec rangeOfString:[obj stringByAppendingString:@"*"]].location!=NSNotFound);
                        if (isleft || isRight){
                            NSCharacterSet *doNotWant = [NSCharacterSet characterSetWithCharactersInString:@"[]{}（#%-*+=_）\\|~(＜＞$%^&*)_+ "];
                            NSArray * tmp = [result componentsSeparatedByCharactersInSet:doNotWant];
                            NSInteger index = [tmp indexOfObject:obj];
                            if (isleft && isRight) {
                                
                                NSInteger tmpIndex = index-1;
                                CGFloat muls = 1.0;
                                NSString * mulLeft = @"";
                                NSString * mulRight = @"";
                                if (tmpIndex<=tmp.count && tmpIndex>=0) {
                                    mulLeft = tmp[tmpIndex];
                                    if ([self isPureNum:mulLeft]) {
                                        muls = muls * [mulLeft floatValue];
                                    }else{
                                        //NSAssert(0, @"4、Invalid view.attribute value:%@",sec);
                                    }
                                }else{
                                    //NSAssert(0, @"5、Invalid view.attribute value:%@",sec);
                                }
                                tmpIndex = index+1;
                                if (tmpIndex<=tmp.count && tmpIndex>=0) {
                                    mulRight = tmp[tmpIndex];
                                    if ([self isPureNum:mulLeft]) {
                                        muls = muls * [mulLeft floatValue];
                                    }else{
                                        //NSAssert(0, @"4、Invalid view.attribute value:%@",sec);
                                    }
                                }else{
                                    //NSAssert(0, @"5、Invalid view.attribute value:%@",sec);
                                }
                                multiplier = muls;
                                constanttmp = [NSString stringWithFormat:@"%@*%@*%@",mulLeft,obj,mulRight];
                                
                            }else{
                                //倍数找到了
                                if (isleft) {
                                    index--;
                                }else{
                                    index++;
                                }
                                if (index<=tmp.count && index>=0) {
                                    NSString * multmp = tmp[index];
                                    if ([self isPureNum:multmp]) {
                                        multiplier = [multmp floatValue];
                                        if (isleft) {
                                            constanttmp = [NSString stringWithFormat:@"%@*%@",multmp,obj];
                                        }else{
                                            constanttmp = [NSString stringWithFormat:@"%@*%@",obj,multmp];
                                        }
                                    }else{
                                        //NSAssert(0, @"4、Invalid view.attribute value:%@",sec);
                                    }
                                }else{
                                    //NSAssert(0, @"5、Invalid view.attribute value:%@",sec);
                                }
                            }
                            
                        }else{
                            //没有倍数
                            multiplier = 1.0;
                        }
                        NSString * sectmp = [result stringByReplacingOccurrencesOfString:constanttmp withString:@"0"];
                        c = [[FormulaStringCalcUtility calcComplexFormulaString:sectmp] floatValue];
                    }
                }
            }
            constraint = [self constraintItem:itemView attr1:attribute rel:relation item2:item2View attr2:attribute2 mul:multiplier constant:c];
        }
        constraint;
    });
}
- (void)configProperty:(NSString *)property value:(NSString *)value view:(UIView *)view{
    YSResourceManager *mgr = [YSResourceManager loadFromMainBundle];
    value = [value stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (view.superview.layout_id) {
        value = [value stringByReplacingOccurrencesOfString:@"parent" withString:view.superview.layout_id];
    }
    if ([property hasPrefix:@"layouts"]) {
        NSArray * formats = [value componentsSeparatedByString:@","];
        for (NSString *format in formats) {
            NSString *tmp = [[view.layout_id stringByAppendingString:@"."] stringByAppendingString:format];
            [self.formats addObject:tmp];
            NSLog(@"%@",tmp);
        }
    }
    else{
        NSString * first = [[property substringToIndex:1] uppercaseString];
        NSString * rest = [property substringFromIndex:1];
        NSString * setMethod = [NSString stringWithFormat:@"set%@%@:", first,rest];
        //backgroundColor\textColor
        if ([view respondsToSelector:NSSelectorFromString(setMethod)]) {
            if(value){
                //颜色
                if ([property hasSuffix:@"Color"]) {
                    UIColor * color = [mgr.colorManager colorWith:value];
                    //边框大小颜色
                    if ([property isEqualToString:@"borderColor"]){
                        view.layer.borderColor = color.CGColor;
                    }else{
                        [view setValue:color forKey:property];
                    }
                }
                //字体大小
                else if([ParserManager isPureNum:value]){
                    const char * pObjCType = [((NSNumber*)value) objCType];
                    id val = value;
                    if ([property isEqualToString:@"font"] ||
                        [property isEqualToString:@"borderWidth"]){
                        if ([property isEqualToString:@"font"]) {
                            if (strcmp(pObjCType, @encode(int))  == 0) {//int
                                val = [UIFont systemFontOfSize:[value intValue]];
                            }
                            if (strcmp(pObjCType, @encode(float)) == 0) {//float
                                val = [UIFont systemFontOfSize:[value floatValue]];
                            }
                            if (strcmp(pObjCType, @encode(double))  == 0) {//double
                                val = [UIFont systemFontOfSize:[value floatValue]];
                            }
                            if (strcmp(pObjCType, @encode(BOOL)) == 0) {//bool
                                val = [UIFont systemFontOfSize:[value boolValue]];
                            }
                        }
                        else if ([property isEqualToString:@"borderWidth"]){
                            
                        }
                        [view setValue:val forKey:property];
                    }else {
                        [view setValue:value forKey:property];
                    }
                }else{
                    
                }
            }
        }
    }
}
- (UIView *)parserFindViewById:(NSString *)viewId{
    return [self.views objectForKey:viewId];
}
- (NSMutableArray *)formats{
    if (!_formats) {
        _formats = [NSMutableArray array];
    }
    return _formats;
}
- (NSMutableDictionary *)views{
    if (!_views) {
        _views = [NSMutableDictionary dictionary];
    }
    return _views;
}
@end
