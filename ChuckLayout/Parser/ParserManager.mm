//
//  ParserManager.m
//  MyLayoutParserDemo
//
//  Created by 梁慧聪 on 2017/6/20.
//  Copyright © 2017年 youngsoft. All rights reserved.
//
#define SRCROOT @"/Users/chuckliang/Documents/gitProject/ChuckLayout/ChuckLayout/xmls"

#import "ParserManager.h"
#import "YSResourceManager.h"
#import "NSString+Property.h"
#import "UIView+FALayout.h"
#import <objc/runtime.h>
#import "FALiveConstraintHelper.h"
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
    
    [FALiveConstraintHelper formats:self.formats views:self.views];
    
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

- (void)configProperty:(NSString *)property value:(NSString *)value view:(UIView *)view{
    YSResourceManager *mgr = [YSResourceManager loadFromMainBundle];
    value = [value stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (view.superview.layout_id) {
        value = [value stringByReplacingOccurrencesOfString:@"parent" withString:view.superview.layout_id];
    }
    if ([property hasPrefix:@"layouts"]) {
        NSArray * formats = [value componentsSeparatedByString:@","];
        for (NSString *format in formats) {
            NSString *tmp = view.layout_id;
            if ([format rangeOfString:@"="].location == NSNotFound) {
                tmp = [[tmp stringByAppendingString:@"="] stringByAppendingString:format];
            }else{
                tmp = [[tmp stringByAppendingString:@"."] stringByAppendingString:format];
            }
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
                else if([FALiveConstraintHelper isPureNum:value]){
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

+ (BOOL)isLayoutAttribute:(NSLayoutAttribute)attribute{
    return ((attribute & (NSLayoutAttributeLeft|NSLayoutAttributeRight|NSLayoutAttributeTop|NSLayoutAttributeBottom|NSLayoutAttributeLeading|NSLayoutAttributeTrailing|NSLayoutAttributeWidth|NSLayoutAttributeHeight|NSLayoutAttributeCenterX|NSLayoutAttributeCenterY|NSLayoutAttributeLastBaseline|NSLayoutAttributeBaseline|
                          NSLayoutAttributeFirstBaseline|NSLayoutAttributeLeftMargin|NSLayoutAttributeRightMargin|NSLayoutAttributeTopMargin|NSLayoutAttributeBottomMargin|NSLayoutAttributeLeadingMargin|NSLayoutAttributeTrailingMargin|NSLayoutAttributeCenterXWithinMargins|NSLayoutAttributeCenterYWithinMargins|NSLayoutAttributeNotAnAttribute)) == attribute);
}
@end
