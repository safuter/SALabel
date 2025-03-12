//
/**
 * Copyright (c) 2012 Sarfuter Zhang
 * Created by hangchen on 24/7/12.
 * @author         Sarfuter Zhang <sarfuter@gmail.com>
 * @copyright    2024    Sarfuter Zhang
 * @version
 *
 */

#import "SALabel.h"
#include <UIKit/UIKit.h>

#import <objc/runtime.h>


#import "MTMathUILabel.h"
#import "MTFontManager.h"
#import "NSString+Util.h"

//#import "CaiDianTong-Swift.h"

#define LINK_PADDING 2
#define IMAGE_PADDING 2
#define IMAGE_USER_WIDTH ((WINDOW_WIDTH*2.0)/3-10)
#define IMAGE_MAX_WIDTH ((IMAGE_USER_WIDTH) - 4 *(IMAGE_PADDING))
#define IMAGE_USER_HEIGHT (((WINDOW_WIDTH*2.0)/3)*80.0)/180
#define IMAGE_LINK_BOUND_MIN_HEIGHT 30
#define IMAGE_USER_DESCENT ((IMAGE_USER_HEIGHT) / 20.0)
#define IMAGE_MAX_HEIGHT ((IMAGE_USER_HEIGHT + IMAGE_USER_DESCENT) - 2 * (IMAGE_PADDING))

#define BG_COLOR 0xDDDDDD
#define IMAGE_MIN_WIDTH 5
#define IMAGE_MIN_HEIGHT 5


#define KEYWINWOW ({ \
    UIWindow *keyWindow = nil; \
    if (@available(iOS 13.0, *)) { \
        NSSet<UIScene *> *scenes = UIApplication.sharedApplication.connectedScenes; \
        for (UIScene *scene in scenes) { \
            if ([scene isKindOfClass:[UIWindowScene class]] && \
                scene.activationState == UISceneActivationStateForegroundActive) { \
                UIWindowScene *windowScene = (UIWindowScene *)scene; \
                keyWindow = windowScene.keyWindow; \
                break; \
            } \
        } \
    } else { \
         \
    } \
    keyWindow; \
})

#define MAppDelegate ((AppDelegate*)([[UIApplication sharedApplication] delegate]))

#define WINDOW_WIDTH KEYWINWOW.frame.size.width
#define WINDOW_HEIGHT KEYWINWOW.frame.size.height

// block 用的
#define  weak_block_self  __weak typeof(self) weakSelf = self


NSString * const kSABackgroundFillColorAttributeName         = @"kSABackgroundFillColor";
NSString * const kSABackgroundStrokeColorAttributeName       = @"kSABackgroundStrokeColor";
NSString * const kSABackgroundLineWidthAttributeName         = @"kSABackgroundLineWidth";
NSString * const kSABackgroundLineCornerRadiusAttributeName  = @"kSABackgroundLineCornerRadius";
NSString * const kSAActiveBackgroundFillColorAttributeName   = @"kSAActiveBackgroundFillColor";
NSString * const kSAActiveBackgroundStrokeColorAttributeName = @"kSAActiveBackgroundStrokeColor";
NSString * const kSAStrikethroughStyleAttributeName          = @"kSAStrikethroughStyleAttributeName";
NSString * const kSAStrikethroughColorAttributeName          = @"kSAStrikethroughColorAttributeName";

NSString * const kSALinkStringIdentifierAttributesName       = @"kSALinkStringIdentifierAttributesName";


static NSMutableDictionary *imgSizeDict = NULL;

static NSMutableDictionary *itbViewDict = NULL;

@implementation RTLabelComponent

@synthesize text = _text;
@synthesize tagLabel = _tagLabel;
@synthesize attributes = _attributes;
@synthesize position = _position;
@synthesize componentIndex = _componentIndex;
@synthesize isClosure = _isClosure;
@synthesize img = img_;

+ (void)load
{
    itbViewDict = [NSMutableDictionary dictionary];
}

- (id)initWithString:(NSString*)aText tag:(NSString*)aTagLabel attributes:(NSMutableDictionary*)theAttributes;
{
    self = [super init];
    if (self) {
        self.text = aText;
        self.tagLabel = aTagLabel;
        self.attributes = theAttributes;
        self.isClosure = NO;
        
    }
    return self;
}

+ (id)componentWithString:(NSString*)aText tag:(NSString*)aTagLabel attributes:(NSMutableDictionary*)theAttributes
{
    return [[self alloc] initWithString:aText tag:aTagLabel attributes:theAttributes];
}

- (id)initWithTag:(NSString*)aTagLabel position:(int)aPosition attributes:(NSMutableDictionary*)theAttributes
{
    self = [super init];
    if (self) {
        self.tagLabel = aTagLabel;
        self.position = aPosition;
        self.attributes = theAttributes;
        self.isClosure = NO;
    }
    return self;
}

+(id)componentWithTag:(NSString*)aTagLabel position:(int)aPosition attributes:(NSMutableDictionary*)theAttributes
{
    return [[self alloc] initWithTag:aTagLabel position:aPosition attributes:theAttributes];
}


- (NSString*)description
{
    NSMutableString *desc = [NSMutableString string];
    [desc appendFormat:@"text: %@", self.text];
    [desc appendFormat:@", position: %i", self.position];
    if (self.tagLabel) [desc appendFormat:@", tag: %@", self.tagLabel];
    if (self.attributes) [desc appendFormat:@", attributes: %@", self.attributes];
    return desc;
}

@end

@implementation RTLabelComponentsStructure

@synthesize components = components_;
@synthesize plainTextData = plainTextData_;
@synthesize linkComponents = linkComponents_;
@synthesize imgComponents = imgComponents_;

@end

#import "CJLabelConfigure.h"

@interface SACTRunUrl: NSURL
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) NSValue *rangeValue;
@end

@implementation SACTRunUrl


@end


@interface SALabel() <UIGestureRecognizerDelegate>


@property (nonatomic, assign) CGSize optimumSize;

// =================  复制功能处理 beg =================
/**
 是否需要计算支持复制的每个字符的frame大小
 */
@property (nonatomic, assign) BOOL caculateCopySize;

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;//长按手势
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGes;//双击手势

// =================  复制功能处理 end =================


//- (NSArray *)components;
//- (void)parse:(NSString *)data valid_tags:(NSArray *)valid_tags;
- (NSArray*) colorForHex:(NSString *)hexColor;
- (void)render;
- (CGRect)BoundingRectForLink:(RTLabelComponent*)linkComponent withRun:(CTRunRef)run;
- (CGRect)BoundingRectFroImage:(RTLabelComponent*)imgComponent withRun:(CTRunRef)run;

- (void)genAttributedString;

- (CGPathRef)newPathForRoundedRect:(CGRect)rect radius:(CGFloat)radius;

- (void)dismissBoundRectForTouch;
#pragma mark -
#pragma mark styling

- (void)applyItalicStyleToText:(CFMutableAttributedStringRef)text atPosition:(int)position withLength:(int)length;
- (void)applyBoldStyleToText:(CFMutableAttributedStringRef)text atPosition:(int)position withLength:(int)length;
- (void)applyColor:(NSString*)value toText:(CFMutableAttributedStringRef)text atPosition:(int)position withLength:(int)length;
- (void)applySingleUnderlineText:(CFMutableAttributedStringRef)text atPosition:(int)position withLength:(int)length;
- (void)applyDoubleUnderlineText:(CFMutableAttributedStringRef)text atPosition:(int)position withLength:(int)length;
- (void)applyUnderlineColor:(NSString*)value toText:(CFMutableAttributedStringRef)text atPosition:(int)position withLength:(int)length;
- (void)applyFontAttributes:(NSDictionary*)attributes toText:(CFMutableAttributedStringRef)text atPosition:(int)position withLength:(int)length;
- (void)applyParagraphStyleToText:(CFMutableAttributedStringRef)text attributes:(NSMutableDictionary*)attributes atPosition:(int)position withLength:(int)length;
- (void)applyImageAttributes:(CFMutableAttributedStringRef)text attributes:(NSMutableDictionary*)attributes atPosition:(int)position withLength:(int)length;
@end

@implementation SALabel {
    BOOL _needsFramesetter;
    
    NSAttributedString *_attributedText;
    
    CJGlyphRunStrokeItem *_lastGlyphRunStrokeItem;//计算StrokeItem的中间变量
    CJGlyphRunStrokeItem *_currentClickRunStrokeItem;//当前点击选中的StrokeItem
    

    NSArray <CJCTLineLayoutModel *>*_CTLineVerticalLayoutArray;//记录 所有CTLine在垂直方向的对齐方式的数组
    
    NSMutableArray <CJGlyphRunStrokeItem *>*_allRunItemArray;//enableCopy=YES时，包含所有CTRun信息的数组
    
    NSInteger _textNumberOfLines;
    CGFloat _lineVerticalMaxWidth;//每一行文字中的最大宽度
    
    CGFloat _translateCTMty;//坐标系统反转后的偏移量
    CGRect _insetRect;//实际绘制文本区域大小
    
    BOOL _needRedrawn;//是否需要重新计算_CTLineVerticalLayoutArray以及_linkStrokeItemArray数组
    BOOL _longPress;//判断是否长按;
    BOOL _afterLongPressEnd;//用于判断长按复制判断
}

@synthesize optimumSize = _optimumSize;
@synthesize sizeDelegate = _sizeDelegate;
@synthesize delegate = _delegate;
@synthesize paragraphReplacement = _paragraphReplacement;
@synthesize currentImgComponent = _currentImgComponent;
@synthesize currentLinkComponent = _currentLinkComponent;


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
        [self setBackgroundColor:[UIColor clearColor]];
        self.font = [UIFont systemFontOfSize:14];
        self.textColor = [UIColor darkTextColor];
        self.currentLinkComponent = nil;
        self.currentImgComponent = nil;
        
        self.showSourceColor = true;
        
        //[self setText:@""];
        _textAlignment = RTTextAlignmentLeft;
        _lineBreakMode = RTTextLineBreakModeWordWrapping;//换行模式
        //_lineBreakMode = kCTLineBreakByTruncatingTail;
        _attrString = NULL;
        _ctFrame = NULL;
        _framesetter = NULL;
        _optimumSize = frame.size;
        _paragraphReplacement = @"\n";
        
        // cjlabel beg
        _textNumberOfLines = -1;
        _textInsets = UIEdgeInsetsZero;
        _allRunItemArray = [NSMutableArray array];
        _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureDidFire:)];
        _longPressGestureRecognizer.delegate = self;
//        _longPressGestureRecognizer.cancelsTouchesInView = YES;
        [self addGestureRecognizer:_longPressGestureRecognizer];
        // cjlabel end
        
        if (_thisFont) {
            CFRelease(_thisFont);
        }
        _thisFont = CTFontCreateWithName ((CFStringRef)[self.font fontName], [self.font pointSize], NULL);
        [self setMultipleTouchEnabled:YES];
       
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    if(CGRectEqualToRect(frame, self.frame)) { return; }
    [super setFrame:frame];
    [self setNeedsDisplay];
}

- (void)setTextAlignment:(RTTextAlignment)textAlignment
{
    _textAlignment = textAlignment;
    [self genAttributedString];
    [self setNeedsDisplay];
}

- (RTTextAlignment)textAlignment
{
    return _textAlignment;
}

- (void)setLineBreakMode:(RTTextLineBreakMode)lineBreakMode
{
    _lineBreakMode = lineBreakMode;
    [self genAttributedString];
    [self setNeedsDisplay];
}

- (RTTextLineBreakMode)lineBreakMode
{
    return _lineBreakMode;
}

- (void)setTextColor:(UIColor*)textColor
{
    if (_textColor) {
        if (_textColor != textColor) {
            _textColor = nil;
        }
        else {
            return;
        }
    }
    _textColor = textColor;
    [self genAttributedString];
    [self setNeedsDisplay];
}

- (UIColor*)textColor
{
    return _textColor;
}

- (void)setFont:(UIFont*)font
{
    _font = font;
    if (font) {
        if (_thisFont) {
            CFRelease(_thisFont);
        }
        _thisFont = CTFontCreateWithName ((CFStringRef)[self.font fontName], [self.font pointSize], NULL);
    }
}


- (void)setComponentsAndPlainText:(RTLabelComponentsStructure*)componnetsDS {
    if (componentsAndPlainText_) {
        if (componentsAndPlainText_ != componnetsDS) {
            componentsAndPlainText_ = nil;
        }
        else {
            return;
        }
        
    }
    
    componentsAndPlainText_ = componnetsDS;
    
    [self genAttributedString];
    
    [self setNeedsDisplay];
}

- (RTLabelComponentsStructure*)componentsAndPlainText {
    return componentsAndPlainText_;
}

CGSize MyGetSize(void* refCon) {
    //    CGSize size11111 = CGSizeMake(kScreenWidth / 3, kScreenWidth /3);
    //    return size11111;
    NSString *src = (__bridge NSString*)refCon;
    CGSize size = CGSizeMake((WINDOW_WIDTH*2.0)/3,IMAGE_MAX_HEIGHT);
    
    if (src) {
        
        if (!imgSizeDict) {
            imgSizeDict = [NSMutableDictionary dictionary];
        }
        
        NSValue* nsv = [imgSizeDict objectForKey:src];
        if (nsv) {
            [nsv getValue:&size];
            return size;
        }
        
        UIImage* image = [UIImage imageNamed:src];
        
        if (image) {
            CGSize imageSize = image.size;
            CGFloat ratio = imageSize.width / imageSize.height;
            
            
            if (imageSize.width > IMAGE_MAX_WIDTH) {
                size.width = IMAGE_MAX_WIDTH;
                size.height = IMAGE_MAX_WIDTH / ratio;
            }
            else {
                size.width = imageSize.width;
                size.height = imageSize.height;
            }
            
            if (size.height > IMAGE_MAX_HEIGHT) {
                size.height = IMAGE_MAX_HEIGHT;
                size.width = size.height * ratio;
            }
            
            if (size.height < 1.0) {
                size.height = 1.0;
            }
            if (size.width < 1.0) {
                size.width = 1.0;
            }
            
            nsv = [NSValue valueWithBytes:&size objCType:@encode(CGSize)];
            [imgSizeDict setObject:nsv forKey:src];
            return size;
            
        } else{
            CGFloat totleWidth = WINDOW_WIDTH - 30;
            CGFloat totle1_2Width = totleWidth / 3 - 20;
//            CGFloat totle2_3Width = (totleWidth * 0.67) - 20;
            CGFloat totle2_3Width = (totleWidth * 0.75);
            
            // 改变这个width
//            totle1_2Width = totleWidth / 3 - 20;
            if ([src rangeOfString:@".table"].location != NSNotFound) { // 表格的特殊处理
                totle2_3Width = WINDOW_WIDTH - 50; //
                totle1_2Width = WINDOW_WIDTH - 50;
            }
            
            NSString *tempstring = [src stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            CGSize imageSize;
            
            
            if ([src rangeOfString:@"localhost"].location != NSNotFound && ![src containsString:@".table"]) {
               
                NSString *fileName = tempstring.lastPathComponent;
                NSString *filePath = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Library/%@",fileName]];
                UIImage *img = [UIImage imageWithContentsOfFile:filePath];
                imageSize = img.size;
                
                totle2_3Width = totleWidth - 100;
                imageSize.width = imageSize.width / [UIScreen mainScreen].scale;
                imageSize.height = imageSize.height / [UIScreen mainScreen].scale;
            } else {
                imageSize = [SALabel getImageSizeWithURL:tempstring];
            }
            
            CGFloat ratio = imageSize.width / imageSize.height;
            if (ratio == 1.0) {
                //宽高比1:1,正方形
                if (imageSize.width > totle1_2Width) {
                    size.width = size.height = totle1_2Width;
                }else if(imageSize.width < totle1_2Width){
                    size.width = size.height = imageSize.width;
                }
            }else if (ratio > 1.0) {
                //宽高比大1.0,横向,长方形
                if (imageSize.width > totle2_3Width) {
                    size.width = totle2_3Width;
                    size.height = totle2_3Width / ratio;
                }else{
                    size.width = imageSize.width;
                    size.height = imageSize.height;
                }
            }else if (ratio < 1.0 && ratio > 0){
                //竖型长方形
                if (imageSize.width > totle1_2Width) {
                    size.width = totle1_2Width;
                    size.height = totle1_2Width;
                }else{
                    size.width = imageSize.width;
                    size.height = imageSize.height;
                }
            }else{
                //图片没获取到
                size.width = size.height = 1.0;
            }
            nsv = [NSValue valueWithBytes:&size objCType:@encode(CGSize)];
            [imgSizeDict setObject:nsv forKey:src];
            //            BLLog(@"--------%@", NSStringFromCGSize(imageSize));
        }
    }
    return size;
}

void MyDeallocationCallback( void* refCon ){
    
    
}
CGFloat MyGetAscentCallback( void *refCon ){
    NSString *imgParameter = (__bridge NSString*)refCon;
    
    if (imgParameter) {
        return MyGetSize((__bridge void *)(imgParameter)).height;
    }
    
    return IMAGE_USER_HEIGHT;
}
CGFloat MyGetDescentCallback( void *refCon ){
    NSString *imgParameter = (__bridge NSString*)refCon;
    
    if (imgParameter) {
        return 0;
    }
    return IMAGE_USER_DESCENT;
}
CGFloat MyGetWidthCallback( void* refCon ){
    
    CGSize size = MyGetSize(refCon);
    return size.width;
}

CGFloat MyTableGetAscentCallback( void *refCon ){
    NSString *tbParameter = (__bridge NSString*)refCon;
    
    if (tbParameter) {
        tbParameter = [tbParameter stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        UIView *view = [itbViewDict objectForKey:tbParameter];
        return view.frame.size.height;
    }
    
    return IMAGE_USER_HEIGHT;
}
CGFloat MyTableGetDescentCallback( void *refCon ){
    NSString *tbParameter = (__bridge NSString*)refCon;
    
    if (tbParameter) {
        return 0;
    }
    return IMAGE_USER_DESCENT;
}
CGFloat MyTableGetWidthCallback( void* refCon ){
    NSString *tbParameter = (__bridge NSString*)refCon;
    tbParameter = [tbParameter stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    UIView *view = [itbViewDict objectForKey:tbParameter];
    return view.frame.size.width;
}

- (void)drawRect:(CGRect)rect
{
    [self render];
}

- (CGPathRef)newPathForRoundedRect:(CGRect)rect radius:(CGFloat)radius
{
    CGMutablePathRef retPath = CGPathCreateMutable();
    
    CGRect innerRect = CGRectInset(rect, radius, radius);
    
    CGFloat inside_right = innerRect.origin.x + innerRect.size.width;
    CGFloat outside_right = rect.origin.x + rect.size.width;
    CGFloat inside_bottom = innerRect.origin.y + innerRect.size.height;
    CGFloat outside_bottom = rect.origin.y + rect.size.height;
    
    CGFloat inside_top = innerRect.origin.y;
    CGFloat outside_top = rect.origin.y;
    CGFloat outside_left = rect.origin.x;
    
    CGPathMoveToPoint(retPath, NULL, innerRect.origin.x, outside_top);
    
    CGPathAddLineToPoint(retPath, NULL, inside_right, outside_top);
    CGPathAddArcToPoint(retPath, NULL, outside_right, outside_top, outside_right, inside_top, radius);
    CGPathAddLineToPoint(retPath, NULL, outside_right, inside_bottom);
    CGPathAddArcToPoint(retPath, NULL,  outside_right, outside_bottom, inside_right, outside_bottom, radius);
    
    CGPathAddLineToPoint(retPath, NULL, innerRect.origin.x, outside_bottom);
    CGPathAddArcToPoint(retPath, NULL,  outside_left, outside_bottom, outside_left, inside_bottom, radius);
    CGPathAddLineToPoint(retPath, NULL, outside_left, inside_top);
    CGPathAddArcToPoint(retPath, NULL,  outside_left, outside_top, innerRect.origin.x, outside_top, radius);
    
    CGPathCloseSubpath(retPath);
    
    return retPath;
}

- (CGRect)BoundingRectForLink:(RTLabelComponent*)linkComponent withRun:(CTRunRef)run {
    CGRect runBounds = CGRectZero;
    CFRange runRange = CTRunGetStringRange(run);
    BOOL runStartAfterLink = ((runRange.location >= linkComponent.position) && (runRange.location < linkComponent.position + [linkComponent.text length]));
    BOOL runStartBeforeLink = ((runRange.location < linkComponent.position) && (runRange.location + runRange.length) > linkComponent.position );
    
    // if the range of the glyph run falls within the range of the link to be highlighted
    if (runStartAfterLink || runStartBeforeLink) {
        //runRange is within the link range
        CFIndex rangePosition;
        CFIndex rangeLength;
        NSString *linkComponentString;
        if (runStartAfterLink) {
            rangePosition = 0;
            
            if (linkComponent.position + [linkComponent.text length] > runRange.location + runRange.length) {
                rangeLength = runRange.length;
            }
            else {
                rangeLength = linkComponent.position + [linkComponent.text length] - runRange.location;
            }
            linkComponentString = [self.componentsAndPlainText.plainTextData substringWithRange:NSMakeRange(runRange.location, rangeLength)];
            
        }
        else {
            rangePosition = linkComponent.position - runRange.location;
            if (linkComponent.position + [linkComponent.text length] > runRange.location + runRange.length) {
                rangeLength = runRange.location + runRange.length - linkComponent.position;
            }
            else {
                
                rangeLength = [linkComponent.text length];
            }
            linkComponentString = [self.componentsAndPlainText.plainTextData substringWithRange:NSMakeRange(linkComponent.position, rangeLength)];
        }
        //        BLLog(@"%@",linkComponentString);
        if ([[linkComponentString substringToIndex:1] isEqualToString:@"\n"]) {
            rangePosition+=1;
        }
        if ([[linkComponentString substringFromIndex:[linkComponentString length] - 1] isEqualToString:@"\n"]) {
            rangeLength -= 1;
        }
        if (rangeLength <= 0 ) {
            return runBounds;
        }
        
        CFIndex glyphCount = CTRunGetGlyphCount (run);
        if (rangePosition >= glyphCount) {
            rangePosition = 0;
        }
        if (rangeLength == runRange.length) {
            rangeLength = 0;
        }
        // work out the bounding rect for the glyph run (this doesn't include the origin)
        CGFloat ascent, descent, leading;
        CGFloat width = CTRunGetTypographicBounds(run, CFRangeMake(rangePosition, rangeLength), &ascent, &descent, &leading);
        /*if (![[linkComponentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] && ascent != MyGetAscentCallback(NULL)) {
         return runBounds;
         }*/
        
        runBounds.size.width = width;
        runBounds.size.height = ascent + fabs(descent) + leading;
        
        // get the origin of the glyph run (this is relative to the origin of the line)
        const CGPoint *positions = CTRunGetPositionsPtr(run);
        runBounds.origin.x = positions[rangePosition].x;
        runBounds.origin.y -= ascent;
    }
    return runBounds;
}

- (CGRect)BoundingRectFroImage:(RTLabelComponent*)imgComponent withRun:(CTRunRef)run {
    CGRect runBounds = CGRectZero;
    CFRange runRange = CTRunGetStringRange(run);
    if (runRange.location <= imgComponent.position && runRange.location + runRange.length >= imgComponent.position + [imgComponent.text length]) {
        // work out the bounding rect for the glyph run (this doesn't include the origin)
        NSInteger index = imgComponent.position - runRange.location;
        
        CGSize imageSize = MyGetSize((__bridge void *)([imgComponent.attributes objectForKey:@"src"]));
        
        runBounds.size.width = imageSize.width;
        runBounds.size.height = imageSize.height;
        
        // get the origin of the glyph run (this is relative to the origin of the line)
        
        const CGPoint *positions = CTRunGetPositionsPtr(run);
        
        runBounds.origin.x = positions[index].x;
    }
    return runBounds;
}

- (CGRect)BoundingRectFroTbComponent:(RTLabelComponent*)tbComponent withRun:(CTRunRef)run {
    CGRect runBounds = CGRectZero;
    CFRange runRange = CTRunGetStringRange(run);
    if (runRange.location <= tbComponent.position && runRange.location + runRange.length >= tbComponent.position + [tbComponent.text length]) {
        // work out the bounding rect for the glyph run (this doesn't include the origin)
        NSInteger index = tbComponent.position - runRange.location;
        NSString *keyId = [tbComponent.attributes objectForKey:@"id"];
        keyId = [keyId stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        UIView *view = [itbViewDict valueForKey:keyId];
        CGSize viewSize = view.frame.size;
        
        runBounds.size.width = viewSize.width < self.frame.size.width ? viewSize.width : self.frame.size.width;
        
        runBounds.size.height = viewSize.height;
        
        // get the origin of the glyph run (this is relative to the origin of the line)
        
        const CGPoint *positions = CTRunGetPositionsPtr(run);
        
        runBounds.origin.x = positions[index].x;
    }
    return runBounds;
}

#pragma CJLabel

//处理最后一行CTLine
- (CTLineRef)handleLastCTLine:(CTLineRef)line textRange:(CFRange)textRange attributedString:(NSAttributedString *)attributedString rect:(CGRect)rect context:(CGContextRef)c {
    // 判断最后一行是否占满整行
    CFRange lastLineRange = CTLineGetStringRange(line);
    
    BOOL needTruncation = (!(lastLineRange.length == 0 && lastLineRange.location == 0) && lastLineRange.location + lastLineRange.length < textRange.location + textRange.length);
    
    if (needTruncation) {
        
        CTLineTruncationType truncationType;
        CFIndex truncationAttributePosition = lastLineRange.location;
#warning 暂时加入，未真实处理lastline情况
        NSLineBreakMode lineBreakMode = self.lineBreakMode;
        
        switch (lineBreakMode) {
            case NSLineBreakByTruncatingHead:
                truncationType = kCTLineTruncationStart;
                break;
            case NSLineBreakByTruncatingMiddle:
                truncationType = kCTLineTruncationMiddle;
                truncationAttributePosition += (lastLineRange.length / 2);
                break;
            case NSLineBreakByTruncatingTail:
            default:
                truncationType = kCTLineTruncationEnd;
                truncationAttributePosition += (lastLineRange.length - 1);
                break;
        }
        
        NSDictionary *truncationTokenStringAttributes = [attributedString attributesAtIndex:(NSUInteger)truncationAttributePosition effectiveRange:NULL];
        
        NSMutableAttributedString *attributedTruncationString = [[NSMutableAttributedString alloc]init];
        if (!self.attributedTruncationToken) {
            NSString *truncationTokenString = @"\u2026"; // \u2026 对应"…"的Unicode编码
            attributedTruncationString = [[NSMutableAttributedString alloc] initWithString:truncationTokenString attributes:truncationTokenStringAttributes];
        }else{
            NSDictionary *attributedTruncationTokenAttributes = [self.attributedTruncationToken attributesAtIndex:(NSUInteger)0 effectiveRange:NULL];
            [attributedTruncationString appendAttributedString:self.attributedTruncationToken];
            if (attributedTruncationTokenAttributes.count == 0) {
                [attributedTruncationString addAttributes:truncationTokenStringAttributes range:NSMakeRange(0, attributedTruncationString.length)];
            }
        }
        
        CTLineRef truncationToken = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)attributedTruncationString);
        
        NSUInteger lenght = lastLineRange.length;
        if (lineBreakMode == NSLineBreakByTruncatingHead || lineBreakMode == NSLineBreakByTruncatingMiddle) {
            lenght = attributedString.length - lastLineRange.location;
        }
        NSAttributedString *lastStr = [attributedString attributedSubstringFromRange:NSMakeRange((NSUInteger)lastLineRange.location,MIN(attributedString.length-lastLineRange.location, lenght))];
        // 获取最后一行的NSAttributedString
        NSMutableAttributedString *truncationString = [[NSMutableAttributedString alloc] initWithAttributedString:lastStr];
        if (lastLineRange.length > 0) {
            // 判断最后一行的最后是不是完整单词，避免出现 "…" 前面是一个不完整单词的情况
            unichar lastCharacter = [[truncationString string] characterAtIndex:(NSUInteger)(MIN(lastLineRange.length - 1, truncationString.length -1))];
            if ([[NSCharacterSet newlineCharacterSet] characterIsMember:lastCharacter]) {
                [truncationString deleteCharactersInRange:NSMakeRange((NSUInteger)(lastLineRange.length - 1), 1)];
            }
        }
        
        NSInteger lastLineLength = truncationString.length;
        switch (lineBreakMode) {
            case NSLineBreakByTruncatingHead:
                [truncationString insertAttributedString:attributedTruncationString atIndex:0];
                break;
            case NSLineBreakByTruncatingMiddle:
                [truncationString insertAttributedString:attributedTruncationString atIndex:lastLineLength/2.0];
                break;
            case NSLineBreakByTruncatingTail:
            default:
                [truncationString appendAttributedString:attributedTruncationString];
                break;
        }
        
        CTLineRef truncationLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)truncationString);
        
        // 截取CTLine，以防其过长
        CTLineRef truncatedLine = CTLineCreateTruncatedLine(truncationLine, rect.size.width, truncationType, truncationToken);
        if (!truncatedLine) {
            // 不存在，则取truncationToken
            truncatedLine = CFRetain(truncationToken);
        }
        
        CTLineRef lastLine = CFRetain(truncatedLine);
        
        CFRelease(truncatedLine);
        CFRelease(truncationLine);
        CFRelease(truncationToken);
        
        return lastLine;
    }
    else{
        CTLineRef lastLine = CFRetain(line);
        return lastLine;
    }
}

- (CJCTLineVerticalLayout)CJCTLineVerticalLayoutFromLine:(CTLineRef)line
                                               lineIndex:(CFIndex)lineIndex
                                                  origin:(CGPoint)origin
                                                 context:(CGContextRef)c
                                              lineAscent:(CGFloat)lineAscent
                                             lineDescent:(CGFloat)lineDescent
                                             lineLeading:(CGFloat)lineLeading
{
    //上下行高
    CGFloat lineAscentAndDescent = lineAscent + fabs(lineDescent);
    //默认底部对齐
    CJLabelVerticalAlignment verticalAlignment = CJVerticalAlignmentBottom;
    
    CFArrayRef runs = CTLineGetGlyphRuns(line);
    CGFloat maxRunHeight = 0;
    CGFloat maxRunAscent = 0;
    CGFloat maxImageHeight = 0;
    CGFloat maxImageAscent = 0;
    for (CFIndex j = 0; j < CFArrayGetCount(runs); ++j) {
        CTRunRef run = CFArrayGetValueAtIndex(runs, j);
        CGFloat runAscent = 0.0f, runDescent = 0.0f, runLeading = 0.0f;
        CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &runAscent, &runDescent, &runLeading);
        NSDictionary *attDic = (__bridge NSDictionary *)CTRunGetAttributes(run);
        NSDictionary *imgInfoDic = attDic[kCJImageAttributeName];
        if (CJLabelIsNull(imgInfoDic)) {
            if (maxRunHeight < runAscent + fabs(runDescent)) {
                maxRunHeight = runAscent + fabs(runDescent);
                maxRunAscent = runAscent;
            }
        }else{
            if (maxImageHeight < runAscent + fabs(runDescent)) {
                maxImageHeight = runAscent + fabs(runDescent);
                maxImageAscent = runAscent;
                verticalAlignment = [imgInfoDic[kCJImageLineVerticalAlignment] integerValue];
            }
        }
    }
    
    CGRect lineBounds = CTLineGetImageBounds(line, c);
    //每一行的起始点（相对于context）加上相对于本身基线原点的偏移量
    lineBounds.origin.x += origin.x;
    lineBounds.origin.y += origin.y;
    lineBounds.origin.y = _insetRect.size.height - lineBounds.origin.y - lineBounds.size.height - _translateCTMty;
    
    
    
//ori    lineBounds.size.width = lineBounds.size.width + self.textInsets.left + self.textInsets.right;
    lineBounds.size.width = lineBounds.size.width;
    
    CJCTLineVerticalLayout lineVerticalLayout;
    lineVerticalLayout.line = lineIndex;
    lineVerticalLayout.lineAscentAndDescent = lineAscentAndDescent;
    lineVerticalLayout.lineRect = lineBounds;
    lineVerticalLayout.verticalAlignment = verticalAlignment;
    lineVerticalLayout.maxRunHeight = maxRunHeight;
    lineVerticalLayout.maxRunAscent = maxRunAscent;
    lineVerticalLayout.maxImageHeight = maxImageHeight;
    lineVerticalLayout.maxImageAscent = maxImageAscent;
    
    return lineVerticalLayout;
}

//记录 所有CTLine在垂直方向的对齐方式的数组
- (NSArray <CJCTLineLayoutModel *>*)allCTLineVerticalLayoutArray:(CFArrayRef)lines
                                                         origins:(CGPoint[])origins
                                                          inRect:(CGRect)rect
                                                         context:(CGContextRef)c
                                                       textRange:(CFRange)textRange
                                                attributedString:(NSAttributedString *)attributedString
                                                truncateLastLine:(BOOL)truncateLastLine
{
    NSMutableArray *verticalLayoutArray = [NSMutableArray arrayWithCapacity:3];
    
    // 遍历所有行
    for (CFIndex lineIndex = 0; lineIndex < MIN(_textNumberOfLines, CFArrayGetCount(lines)); lineIndex ++ ) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        
        CGFloat lineAscent = 0.0f, lineDescent = 0.0f, lineLeading = 0.0f;
        CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
        
        if (lineIndex == _textNumberOfLines - 1 && truncateLastLine) {
            
            CTLineRef lastLine = [self handleLastCTLine:line textRange:textRange attributedString:attributedString rect:rect context:c];
            CTLineGetTypographicBounds(lastLine, &lineAscent, &lineDescent, &lineLeading);
            
            CJCTLineVerticalLayout lineVerticalLayout = [self CJCTLineVerticalLayoutFromLine:lastLine lineIndex:lineIndex origin:origins[lineIndex] context:c lineAscent:lineAscent lineDescent:lineDescent lineLeading:lineLeading];
            
            CJCTLineLayoutModel *lineLayoutModel = [[CJCTLineLayoutModel alloc]init];
            lineLayoutModel.lineVerticalLayout = lineVerticalLayout;
            lineLayoutModel.lineIndex = lineIndex;
            [verticalLayoutArray addObject:lineLayoutModel];
            
            CFRelease(lastLine);
        }else{
            CJCTLineVerticalLayout lineVerticalLayout = [self CJCTLineVerticalLayoutFromLine:line lineIndex:lineIndex origin:origins[lineIndex] context:c lineAscent:lineAscent lineDescent:lineDescent lineLeading:lineLeading];
            
            CJCTLineLayoutModel *lineLayoutModel = [[CJCTLineLayoutModel alloc]init];
            lineLayoutModel.lineVerticalLayout = lineVerticalLayout;
            lineLayoutModel.lineIndex = lineIndex;
            [verticalLayoutArray addObject:lineLayoutModel];
        }
    }
    _lineVerticalMaxWidth = self.bounds.size.width;
    
    return verticalLayoutArray;
}

//获取CTLineRef行所对应的CJGlyphRunStrokeItem数组
- (NSMutableArray <CJGlyphRunStrokeItem *>*)lineRunItemsFromCTLineRef:(CTLineRef)line
                                                            lineIndex:(CFIndex)lineIndex
                                                           lineOrigin:(CGPoint)lineOrigin
                                                               inRect:(CGRect)rect
                                                              context:(CGContextRef)c
                                                           lineAscent:(CGFloat)lineAscent
                                                          lineDescent:(CGFloat)lineDescent
                                                          lineLeading:(CGFloat)lineLeading
                                                            lineWidth:(CGFloat)lineWidth
                                                   lineVerticalLayout:(CJCTLineVerticalLayout)lineVerticalLayout
{
    // 先获取每一行所有的runStrokeItems数组
    NSMutableArray *lineRunItems = [NSMutableArray arrayWithCapacity:3];
    
    //遍历每一行的所有glyphRun
    CFArrayRef runArray = CTLineGetGlyphRuns(line);
    for (NSInteger j = 0; j < CFArrayGetCount(runArray); j ++) {
        
        CTRunRef run = CFArrayGetValueAtIndex(runArray, j);
        CJGlyphRunStrokeItem *item = [self CJGlyphRunStrokeItemFromCTRunRef:run origin:lineOrigin line:line lineIndex:lineIndex lineAscent:lineAscent lineDescent:lineDescent lineLeading:lineLeading lineWidth:lineWidth lineVerticalLayout:lineVerticalLayout inRect:rect context:c];
        
        [lineRunItems addObject:item];
    }
    return lineRunItems;
}

- (CJGlyphRunStrokeItem *)CJGlyphRunStrokeItemFromCTRunRef:(CTRunRef)glyphRun origin:(CGPoint)origin line:(CTLineRef)line lineIndex:(CFIndex)lineIndex lineAscent:(CGFloat)lineAscent lineDescent:(CGFloat)lineDescent lineLeading:(CGFloat)lineLeading lineWidth:(CGFloat)lineWidth lineVerticalLayout:(CJCTLineVerticalLayout)lineVerticalLayout inRect:(CGRect)rect context:(CGContextRef)c
{
    
    NSDictionary *attributes = (__bridge NSDictionary *)CTRunGetAttributes(glyphRun);
    
    NSMutableAttributedString *labelAttStr = attributes[kSALinkAttributesName][kCJNonLineWrapAttributesName];
    NSMutableAttributedString *labelLinkAttStr = attributes[kSAActiveLinkAttributesName][kCJNonLineWrapAttributesName];
    
    BOOL isNonLineWrap = NO;
    if ((labelAttStr && labelAttStr.length > 0) || (labelLinkAttStr && labelLinkAttStr.length > 0)) {
        isNonLineWrap = YES;
    }
    
    //背景色以及描边属性
    UIColor *strokeColor = colorWithAttributeName(attributes, kSABackgroundStrokeColorAttributeName);
    if (!CJLabelIsNull(attributes[kSALinkAttributesName]) && !isNotClearColor(strokeColor)) {
        strokeColor = colorWithAttributeName(attributes[kSALinkAttributesName], kSABackgroundStrokeColorAttributeName);
    }
    UIColor *fillColor = colorWithAttributeName(attributes, kSABackgroundFillColorAttributeName);
    if (!CJLabelIsNull(attributes[kSALinkAttributesName]) && !isNotClearColor(fillColor)) {
        fillColor = colorWithAttributeName(attributes[kSALinkAttributesName], kSABackgroundFillColorAttributeName);
    }
    //点击高亮背景色以及描边属性
    UIColor *activeStrokeColor = colorWithAttributeName(attributes, kSAActiveBackgroundStrokeColorAttributeName);
    if (!CJLabelIsNull(attributes[kSAActiveLinkAttributesName]) && !isNotClearColor(activeStrokeColor)) {
        activeStrokeColor = colorWithAttributeName(attributes[kSAActiveLinkAttributesName], kSAActiveBackgroundStrokeColorAttributeName);
    }
    if (strokeColor && !activeStrokeColor) {
        activeStrokeColor = strokeColor;
    }
    
    UIColor *activeFillColor = colorWithAttributeName(attributes, kSAActiveBackgroundFillColorAttributeName);
    if (!CJLabelIsNull(attributes[kSAActiveLinkAttributesName]) && !isNotClearColor(activeFillColor)) {
        activeFillColor = colorWithAttributeName(attributes[kSAActiveLinkAttributesName], kSAActiveBackgroundFillColorAttributeName);
    }
    if (fillColor && !activeFillColor) {
        activeFillColor = fillColor;
    }
    //描边边线宽度
    CGFloat strokeLineWidth = [[attributes objectForKey:kSABackgroundLineWidthAttributeName] floatValue];
    if (!CJLabelIsNull(attributes[kSAActiveLinkAttributesName]) && strokeLineWidth == 0) {
        strokeLineWidth = [[attributes[kSAActiveLinkAttributesName] objectForKey:kSABackgroundLineWidthAttributeName] floatValue];
    }
    
    //是否有设置圆角
    BOOL haveCornerRadius = NO;
    if (attributes[kSABackgroundLineCornerRadiusAttributeName] || attributes[kSAActiveLinkAttributesName][kSABackgroundLineCornerRadiusAttributeName]) {
        haveCornerRadius = YES;
    }
    //填充背景色圆角
    CGFloat cornerRadius = [[attributes objectForKey:kSABackgroundLineCornerRadiusAttributeName] floatValue];
    if (!CJLabelIsNull(attributes[kSAActiveLinkAttributesName]) && cornerRadius == 0) {
        cornerRadius = [[attributes[kSAActiveLinkAttributesName] objectForKey:kSABackgroundLineCornerRadiusAttributeName] floatValue];
    }
    strokeLineWidth = strokeLineWidth == 0?1:strokeLineWidth;
    if (!haveCornerRadius) {
        cornerRadius = cornerRadius == 0?5:cornerRadius;
    }
    
    //删除线
    CGFloat strikethroughStyle = [[attributes objectForKey:kSAStrikethroughStyleAttributeName] floatValue];
    if (strikethroughStyle == 0) {
        strikethroughStyle = [[attributes[kSALinkAttributesName]objectForKey:kSAStrikethroughStyleAttributeName] floatValue];
    }
    if (strikethroughStyle == 0) {
        strikethroughStyle = [[attributes[kSAActiveLinkAttributesName]objectForKey:kSAStrikethroughStyleAttributeName] floatValue];
    }
    //删除线颜色
    UIColor *strikethroughColor = nil;
    if (strikethroughStyle != 0) {
        strikethroughColor = colorWithAttributeName(attributes, kSAStrikethroughColorAttributeName);
        if (!CJLabelIsNull(attributes[kSALinkAttributesName]) && !isNotClearColor(strikethroughColor)) {
            strikethroughColor = colorWithAttributeName(attributes[kSALinkAttributesName], kSAStrikethroughColorAttributeName);
        }
        if (!CJLabelIsNull(attributes[kSAActiveLinkAttributesName]) && !isNotClearColor(strikethroughColor)) {
            strikethroughColor = colorWithAttributeName(attributes[kSAActiveLinkAttributesName], kSAStrikethroughColorAttributeName);
        }
        if (!isNotClearColor(strikethroughColor)) {
            strikethroughColor = [UIColor blackColor];
        }
    }
    
    BOOL isLink = [attributes[kCJIsLinkAttributesName] boolValue];
    
    //点击链点的range（当isLink == YES才存在）
    NSString *linkRangeStr = [attributes objectForKey:kSALinkRangeAttributesName];
    //点击链点是否需要重绘
    BOOL needRedrawn = [attributes[kSALinkNeedRedrawnAttributesName] boolValue];
    
    BOOL isImage = NO;
    NSDictionary *imgInfoDic = attributes[kCJImageAttributeName];
    CJLabelVerticalAlignment imageVerticalAlignment = CJVerticalAlignmentBottom;
    if (!CJLabelIsNull(imgInfoDic)) {
        imageVerticalAlignment = [imgInfoDic[kCJImageLineVerticalAlignment] integerValue];
        isImage = YES;
    }
    
    NSInteger characterIndex = 0;
    NSRange substringRange = NSMakeRange(0, 0);
//    if (self.caculateCopySize) {
        SACTRunUrl *runUrl = attributes[NSLinkAttributeName];
        if ([runUrl isKindOfClass:[SACTRunUrl class]]) {
            characterIndex = runUrl.index;
            substringRange = [runUrl.rangeValue rangeValue];
        }
//    }
    
    CGRect runBounds = CGRectZero;
    CGFloat runAscent = 0.0f, runDescent = 0.0f, runLeading = 0.0f;
    runBounds.size.width = (CGFloat)CTRunGetTypographicBounds(glyphRun, CFRangeMake(0, 0), &runAscent, &runDescent, &runLeading);
    CGFloat runHeight = runAscent + fabs(runDescent);
    runBounds.size.height = runHeight;
    
    //当前run相对于self的CGRect
    runBounds = [self getRunStrokeItemlocRunBoundsFromGlyphRun:glyphRun line:line origin:origin lineIndex:lineIndex inRect:rect width:lineWidth lineVerticalLayout:lineVerticalLayout isImage:isImage imageVerticalAlignment:imageVerticalAlignment lineDescent:lineDescent lineLeading:lineLeading runBounds:runBounds runAscent:runAscent];
    
    //转换为UIKit坐标系统
    CGRect locBounds = [self convertRectFromLoc:runBounds];
    
    CJGlyphRunStrokeItem *runStrokeItem = [[CJGlyphRunStrokeItem alloc]init];
    runStrokeItem.runBounds = runBounds;
    runStrokeItem.locBounds = locBounds;
    CGFloat withOutMergeBoundsY = lineVerticalLayout.lineRect.origin.y - (MAX(lineVerticalLayout.maxRunAscent, lineVerticalLayout.maxImageAscent) - lineVerticalLayout.lineRect.size.height);
    //    CGFloat withOutMergeBoundsY = locBounds.origin.y;
    runStrokeItem.withOutMergeBounds =
    CGRectMake(locBounds.origin.x,
               withOutMergeBoundsY,
               locBounds.size.width,
               //               locBounds.size.height);
               MAX(lineVerticalLayout.maxRunHeight, lineVerticalLayout.maxImageHeight));
    runStrokeItem.lineVerticalLayout = lineVerticalLayout;
    runStrokeItem.characterIndex = characterIndex;
    runStrokeItem.characterRange = substringRange;
    runStrokeItem.runDescent = fabs(runDescent);
    runStrokeItem.runRef = glyphRun;
    runStrokeItem.isNonLineWrap = isNonLineWrap;
    
    // 当前glyphRun是一个可点击链点
    if (isLink) {
        runStrokeItem.strokeColor = strokeColor;
        runStrokeItem.fillColor = fillColor;
        runStrokeItem.strokeLineWidth = strokeLineWidth;
        runStrokeItem.cornerRadius = cornerRadius;
        runStrokeItem.activeStrokeColor = activeStrokeColor;
        runStrokeItem.activeFillColor = activeFillColor;
        runStrokeItem.range = NSRangeFromString(linkRangeStr);
        runStrokeItem.isLink = YES;
        runStrokeItem.needRedrawn = needRedrawn;
        runStrokeItem.strikethroughStyle = strikethroughStyle;
        runStrokeItem.strikethroughColor = strikethroughColor;
        
        if (imgInfoDic[kCJImage]) {
            runStrokeItem.insertView = imgInfoDic[kCJImage];
            runStrokeItem.isInsertView = YES;
        }
        if (!CJLabelIsNull(attributes[kSALinkParameterAttributesName])) {
            runStrokeItem.parameter = attributes[kSALinkParameterAttributesName];
        }
        if (!CJLabelIsNull(attributes[kCJClickLinkBlockAttributesName])) {
            runStrokeItem.linkBlock = attributes[kCJClickLinkBlockAttributesName];
        }
        if (!CJLabelIsNull(attributes[kCJLongPressBlockAttributesName])) {
            runStrokeItem.longPressBlock = attributes[kCJLongPressBlockAttributesName];
        }
    }
    else{
        //不是可点击链点。但存在自定义边框线或背景色
        if (isNotClearColor(strokeColor) || isNotClearColor(fillColor) || isNotClearColor(activeStrokeColor) || isNotClearColor(activeFillColor) || strikethroughStyle != 0) {
            runStrokeItem.strokeColor = strokeColor;
            runStrokeItem.fillColor = fillColor;
            runStrokeItem.strokeLineWidth = strokeLineWidth;
            runStrokeItem.cornerRadius = cornerRadius;
            runStrokeItem.activeStrokeColor = activeStrokeColor;
            runStrokeItem.activeFillColor = activeFillColor;
            runStrokeItem.strikethroughStyle = strikethroughStyle;
            runStrokeItem.strikethroughColor = strikethroughColor;
        }
        runStrokeItem.isLink = NO;
        if (imgInfoDic[kCJImage]) {
            runStrokeItem.insertView = imgInfoDic[kCJImage];
            runStrokeItem.isInsertView = YES;
        }
    }
    return runStrokeItem;
}

//当前run相对于self的CGRect
- (CGRect)getRunStrokeItemlocRunBoundsFromGlyphRun:(CTRunRef)glyphRun line:(CTLineRef)line origin:(CGPoint)origin lineIndex:(CFIndex)lineIndex inRect:(CGRect)rect width:(CGFloat)width lineVerticalLayout:(CJCTLineVerticalLayout)lineVerticalLayout isImage:(BOOL)isImage imageVerticalAlignment:(CJLabelVerticalAlignment)imageVerticalAlignment lineDescent:(CGFloat)lineDescent lineLeading:(CGFloat)lineLeading runBounds:(CGRect)runBounds runAscent:(CGFloat)runAscent
{
    CGFloat xOffset = 0.0f;
    CFRange glyphRange = CTRunGetStringRange(glyphRun);
    switch (CTRunGetStatus(glyphRun)) {
        case kCTRunStatusRightToLeft:
            xOffset = CTLineGetOffsetForStringIndex(line, glyphRange.location + glyphRange.length, NULL);
            break;
        default:
            xOffset = CTLineGetOffsetForStringIndex(line, glyphRange.location, NULL);
            break;
    }
    
    runBounds.origin.x = origin.x + rect.origin.x + xOffset;
    CGFloat y = origin.y;
    
    CGFloat yy = [self yOffset:y lineVerticalLayout:lineVerticalLayout isImage:isImage runHeight:runBounds.size.height imageVerticalAlignment:imageVerticalAlignment lineLeading:lineLeading runAscent:runAscent];
    
    // 这里的runBounds是用于背景色填充以及计算点击位置
    // 此时应该将每个文字CTRun的下行高（runDescent）加上，而图片的runBounds = 0,所以忽略了
    runBounds.origin.y = isImage?yy:(yy - (runBounds.size.height - runAscent));
    
    if (CGRectGetWidth(runBounds) > width) {
        runBounds.size.width = width;
    }
    
    return runBounds;
}

//调整CTRun在Y轴方向的坐标
- (CGFloat)yOffset:(CGFloat)y lineVerticalLayout:(CJCTLineVerticalLayout)lineVerticalLayout isImage:(BOOL)isImage runHeight:(CGFloat)runHeight imageVerticalAlignment:(CJLabelVerticalAlignment)imageVerticalAlignment lineLeading:(CGFloat)lineLeading runAscent:(CGFloat)runAscent
{
    CJLabelVerticalAlignment verticalAlignment = lineVerticalLayout.verticalAlignment;
    if (isImage) {
        verticalAlignment = imageVerticalAlignment;
    }
    
    //底对齐不用调整
    if (verticalAlignment == CJVerticalAlignmentBottom) {
        if (isImage) {
            y = y + self.font.descender/2 - lineLeading;
        }
        return y;
    }
    
    CGFloat maxRunHeight = lineVerticalLayout.maxRunHeight;
    CGFloat maxRunAscent = lineVerticalLayout.maxRunAscent;
    CGFloat maxImageHeight = lineVerticalLayout.maxImageHeight;
    CGFloat maxImageAscent = lineVerticalLayout.maxImageAscent;
    CGFloat maxHeight = MAX(maxRunHeight, maxImageHeight);
    CGFloat ascentY = maxRunAscent - runAscent;
    if (maxRunHeight > maxImageHeight) {
        if (isImage) {
            ascentY = maxRunAscent - runAscent + self.font.descender/2 - lineLeading;
        }
    }else{
        ascentY = maxImageAscent - runAscent;
    }
    
    CGFloat yy = y;
    
    //这是当前行最大高度的CTRun
    if (runHeight >= maxHeight) {
        if (isImage) {
            yy = yy + self.font.descender - lineLeading;
        }
        return yy;
    }
    
    if (verticalAlignment == CJVerticalAlignmentCenter) {
        yy = y + ascentY/2.0;
        if (isImage) {
            yy = y + self.font.descender/2.0 - lineLeading + ascentY/2.0;
        }
    }else if (verticalAlignment == CJVerticalAlignmentTop) {
        yy = y + self.font.descender - lineLeading + ascentY;
    }
    return yy;
}

- (CJGlyphRunStrokeItem *)adjustItemHeight:(CJGlyphRunStrokeItem *)item height:(CGFloat)ascentAndDescent {
    // runBounds小于 ascent + Descent 时，rect高度上下扩大 1
    if (item.runBounds.size.height < ascentAndDescent) {
//        item.runBounds = CGRectInset(item.runBounds,-1,-1);
        CGRect runBounds = item.runBounds;
        item.runBounds = CGRectMake(runBounds.origin.x+1, runBounds.origin.y-1, runBounds.size.width-2, runBounds.size.height+2);
    }
    return item;
}

//判断是否有需要合并的runStrokeItems
- (NSMutableArray <CJGlyphRunStrokeItem *>*)mergeLineSameStrokePathItems:(NSArray <CJGlyphRunStrokeItem *>*)lineStrokePathItems ascentAndDescent:(CGFloat)ascentAndDescent {
    
    NSMutableArray *mergeLineStrokePathItems = [[NSMutableArray alloc] initWithCapacity:3];
    
    if (lineStrokePathItems.count > 1) {
        
        NSMutableArray *strokePathTempItems = [NSMutableArray arrayWithCapacity:3];
        for (NSInteger i = 0; i < lineStrokePathItems.count; i ++) {
            CJGlyphRunStrokeItem *item = lineStrokePathItems[i];
            
            //第一个item无需判断
            if (i == 0) {
                _lastGlyphRunStrokeItem = item;
            }else{
                
                CGRect runBounds = item.runBounds;
                CGRect locBounds = item.locBounds;
                UIColor *strokeColor = item.strokeColor;
                UIColor *fillColor = item.fillColor;
                UIColor *activeStrokeColor = item.activeStrokeColor;
                UIColor *activeFillColor = item.activeFillColor;
                CGFloat lineWidth = item.strokeLineWidth;
                CGFloat cornerRadius = item.cornerRadius;
                //删除线
                CGFloat strikethroughStyle = item.strikethroughStyle;
                UIColor *strikethroughColor = item.strikethroughColor;
                
                CGRect lastRunBounds = _lastGlyphRunStrokeItem.runBounds;
                CGRect lastLocBounds = _lastGlyphRunStrokeItem.locBounds;
                UIColor *lastStrokeColor = _lastGlyphRunStrokeItem.strokeColor;
                UIColor *lastFillColor = _lastGlyphRunStrokeItem.fillColor;
                UIColor *lastActiveStrokeColor = _lastGlyphRunStrokeItem.activeStrokeColor;
                UIColor *lastActiveFillColor = _lastGlyphRunStrokeItem.activeFillColor;
                CGFloat lastLineWidth = _lastGlyphRunStrokeItem.strokeLineWidth;
                CGFloat lastCornerRadius = _lastGlyphRunStrokeItem.cornerRadius;
                //删除线
                CGFloat lastStrikethroughStyle = _lastGlyphRunStrokeItem.strikethroughStyle;
                UIColor *lastStrikethroughColor = _lastGlyphRunStrokeItem.strikethroughColor;
                
                BOOL needMerge = NO;
                //可点击链点
                if (item.isLink && _lastGlyphRunStrokeItem.isLink) {
                    NSRange range = item.range;
                    NSRange lastRange = _lastGlyphRunStrokeItem.range;
                    //需要合并的点击链点
                    if (NSEqualRanges(range,lastRange)) {
                        needMerge = YES;
                        lastRunBounds = CGRectMake(compareMaxNum(lastRunBounds.origin.x,runBounds.origin.x,NO),
                                                   compareMaxNum(lastRunBounds.origin.y,runBounds.origin.y,YES),
                                                   lastRunBounds.size.width + runBounds.size.width,
                                                   compareMaxNum(lastRunBounds.size.height,runBounds.size.height,YES));
                        _lastGlyphRunStrokeItem.runBounds = lastRunBounds;
                        _lastGlyphRunStrokeItem.locBounds =
                        CGRectMake(compareMaxNum(lastLocBounds.origin.x,locBounds.origin.x,NO),
                                   compareMaxNum(lastLocBounds.origin.y,locBounds.origin.y,NO),
                                   lastLocBounds.size.width + locBounds.size.width,
                                   compareMaxNum(lastLocBounds.size.height,locBounds.size.height,YES));
                    }
                }else if (!item.isLink && !_lastGlyphRunStrokeItem.isLink){
                    
                    BOOL sameColor = ({
                        BOOL same = NO;
                        
                        if (!strokeColor && !fillColor && !activeStrokeColor && !activeFillColor) {
                            same = NO;
                        }else{
                            if (strokeColor) {
                                same = isSameColor(strokeColor,lastStrokeColor);
                            }
                            if (fillColor) {
                                same = isSameColor(fillColor,lastFillColor);
                            }
                            if (same && activeStrokeColor) {
                                same = isSameColor(activeStrokeColor,lastActiveStrokeColor);
                            }
                            if (same && activeFillColor) {
                                same = isSameColor(activeFillColor,lastActiveFillColor);
                            }
                        }
                        same;
                    });
                    
                    //浮点数判断
                    BOOL nextItem = (fabs((lastRunBounds.origin.x + lastRunBounds.size.width) - runBounds.origin.x)<=1e-6)?YES:NO;
                    //非点击链点，但是是需要合并的连续run
                    if (sameColor && lineWidth == lastLineWidth && cornerRadius == lastCornerRadius && nextItem
                        ) {
                        
                        needMerge = YES;
                        lastRunBounds = CGRectMake(compareMaxNum(lastRunBounds.origin.x,runBounds.origin.x,NO),
                                                   compareMaxNum(lastRunBounds.origin.y,runBounds.origin.y,YES),
                                                   lastRunBounds.size.width + runBounds.size.width,
                                                   compareMaxNum(lastRunBounds.size.height,runBounds.size.height,YES));
                        _lastGlyphRunStrokeItem.runBounds = lastRunBounds;
                        _lastGlyphRunStrokeItem.locBounds =
                        CGRectMake(compareMaxNum(lastLocBounds.origin.x,locBounds.origin.x,NO),
                                   compareMaxNum(lastLocBounds.origin.y,locBounds.origin.y,NO),
                                   lastLocBounds.size.width + locBounds.size.width,
                                   compareMaxNum(lastLocBounds.size.height,locBounds.size.height,YES));
                    }
                }
                
                
                //没有发生合并
                if (!needMerge) {
                    
                    _lastGlyphRunStrokeItem = [self adjustItemHeight:_lastGlyphRunStrokeItem height:ascentAndDescent];
                    [strokePathTempItems addObject:[_lastGlyphRunStrokeItem copy]];
                    
                    _lastGlyphRunStrokeItem = item;
                    
                    //已经是最后一个run
                    if (i == lineStrokePathItems.count - 1) {
                        _lastGlyphRunStrokeItem = [self adjustItemHeight:_lastGlyphRunStrokeItem height:ascentAndDescent];
                        [strokePathTempItems addObject:[_lastGlyphRunStrokeItem copy]];
                    }
                }
                //有合并
                else{
                    _lastGlyphRunStrokeItem.strikethroughStyle = MAX(strikethroughStyle, lastStrikethroughStyle);
                    if (_lastGlyphRunStrokeItem.strikethroughStyle != 0) {
                        if (lastStrikethroughColor) {
                            _lastGlyphRunStrokeItem.strikethroughColor = lastStrikethroughColor;
                        }
                        if (strikethroughColor) {
                            _lastGlyphRunStrokeItem.strikethroughColor = strikethroughColor;
                        }
                        if (!_lastGlyphRunStrokeItem.strikethroughColor) {
                            _lastGlyphRunStrokeItem.strikethroughColor = [UIColor blackColor];
                        }
                    }
                    //已经是最后一个run
                    if (i == lineStrokePathItems.count - 1) {
                        _lastGlyphRunStrokeItem = [self adjustItemHeight:_lastGlyphRunStrokeItem height:ascentAndDescent];
                        [strokePathTempItems addObject:[_lastGlyphRunStrokeItem copy]];
                    }
                }
            }
        }
        [mergeLineStrokePathItems addObjectsFromArray:strokePathTempItems];
    }
    else{
        if (lineStrokePathItems.count == 1) {
            CJGlyphRunStrokeItem *item = lineStrokePathItems[0];
            item = [self adjustItemHeight:item height:ascentAndDescent];
            [mergeLineStrokePathItems addObject:item];
        }
        
    }
    return mergeLineStrokePathItems;
}

//绘制CTLine
- (void)drawCTLine:(CTLineRef)line
         lineIndex:(CFIndex)lineIndex
            origin:(CGPoint)lineOrigin
           context:(CGContextRef)c
        lineAscent:(CGFloat)lineAscent
       lineDescent:(CGFloat)lineDescent
       lineLeading:(CGFloat)lineLeading
         lineWidth:(CGFloat)lineWidth
              rect:(CGRect)rect
        penOffsetX:(CGFloat)penOffsetX
   lineLayoutModel:(CJCTLineLayoutModel *)lineLayoutModel
{
    //计算当前行的CJCTLineVerticalLayout 结构体
    CJCTLineVerticalLayout lineVerticalLayout = lineLayoutModel.lineVerticalLayout;
    
    CGFloat selectCopyBackY = lineVerticalLayout.lineRect.origin.y;
    CGFloat selectCopyBackHeight = lineVerticalLayout.lineRect.size.height;
    CGFloat selectCopyHeightDif = 0;
    
    //当前行的所有CTRunItem数组
    NSMutableArray *lineRunItems = [self lineRunItemsFromCTLineRef:line lineIndex:lineIndex lineOrigin:lineOrigin inRect:rect context:c lineAscent:lineAscent lineDescent:lineDescent lineLeading:lineLeading lineWidth:lineWidth lineVerticalLayout:lineVerticalLayout];
    
    
    NSArray *lineStrokrArray = [self mergeLineSameStrokePathItems:lineRunItems ascentAndDescent:(lineAscent + fabs(lineDescent))];
    
    
    for (CJGlyphRunStrokeItem *runItem in lineRunItems) {
        CGRect runBounds = runItem.runBounds;
        if (!runItem.isInsertView) {
            runBounds.origin.y = runItem.runBounds.origin.y + runItem.runDescent;
        }
        
        selectCopyBackY = MIN(selectCopyBackY, runItem.locBounds.origin.y);
        
        CGFloat heightDif = (runItem.locBounds.size.height + runItem.locBounds.origin.y) - (lineVerticalLayout.lineRect.size.height + lineVerticalLayout.lineRect.origin.y);
        selectCopyHeightDif = MAX(selectCopyHeightDif, heightDif);
    }
    
    //填充背景色
    [self drawBackgroundColor:c runStrokeItems:lineStrokrArray isStrokeColor:NO];
    
    //需要计算复制数组，则添加
//    if (self.enableCopy && self.caculateCopySize) {
    
    
    [_allRunItemArray addObjectsFromArray:lineRunItems];
    
    
    lineLayoutModel.selectCopyBackY = selectCopyBackY;
    lineLayoutModel.selectCopyBackHeight = (selectCopyBackHeight + selectCopyHeightDif + lineVerticalLayout.lineRect.origin.y) - selectCopyBackY;
//    }
}

//isStrokeColor 是否填充描边
- (void)drawBackgroundColor:(CGContextRef)c
             runStrokeItems:(NSArray <CJGlyphRunStrokeItem *>*)runStrokeItems
              isStrokeColor:(BOOL)isStrokeColor
{
    if (runStrokeItems.count > 0) {
        for (CJGlyphRunStrokeItem *item in runStrokeItems) {
            [self drawBackgroundColor:c runItem:item isStrokeColor:isStrokeColor];
        }
    }
}

- (void)drawBackgroundColor:(CGContextRef)c
                    runItem:(CJGlyphRunStrokeItem *)runItem
              isStrokeColor:(BOOL)isStrokeColor
{
    if (runItem) {
        if (_currentClickRunStrokeItem && NSEqualRanges(_currentClickRunStrokeItem.range,runItem.range)) {
            [self drawBackgroundColor:c runStrokeItem:runItem isStrokeColor:isStrokeColor active:YES isStrikethrough:NO];
        }
        else{
            [self drawBackgroundColor:c runStrokeItem:runItem isStrokeColor:isStrokeColor active:NO isStrikethrough:NO];
        }
    }
}

//isStrokeColor 是否填充描边
- (void)drawBackgroundColor:(CGContextRef)c
              runStrokeItem:(CJGlyphRunStrokeItem *)runStrokeItem
              isStrokeColor:(BOOL)isStrokeColor
                     active:(BOOL)active
            isStrikethrough:(BOOL)isStrikethrough
{
    CGContextSetLineJoin(c, kCGLineJoinRound);
    CGFloat x = runStrokeItem.runBounds.origin.x-self.textInsets.left;
    CGFloat y = runStrokeItem.runBounds.origin.y;
    
    CGRect roundedRect = CGRectMake(x,y,runStrokeItem.runBounds.size.width,runStrokeItem.runBounds.size.height);
    if (isStrokeColor) {
        CGFloat lineWidth = runStrokeItem.strokeLineWidth/2;
        CGFloat width = runStrokeItem.runBounds.size.width + ((runStrokeItem.isInsertView)?3*lineWidth:2*lineWidth);
        roundedRect = CGRectMake(x-lineWidth,
                                 y-lineWidth,
                                 width,
                                 runStrokeItem.runBounds.size.height + 2*lineWidth);
    }
    
    //画删除线
    if (isStrikethrough) {
        if (runStrokeItem.strikethroughStyle != 0) {
            CGFloat strikethroughY = roundedRect.origin.y + runStrokeItem.runBounds.size.height/2 + runStrokeItem.strikethroughStyle/2;
//            CGFloat strikethroughX = x + runStrokeItem.strikethroughStyle/2;
//            CGFloat strikethroughEndX = x + roundedRect.size.width - runStrokeItem.strikethroughStyle/2;
            
            CGFloat strikethroughX = x;
            CGFloat strikethroughEndX = x + roundedRect.size.width;
            
            CGContextSetLineCap(c, kCGLineCapSquare);
            CGContextSetLineWidth(c, runStrokeItem.strikethroughStyle);
            CGContextSetStrokeColorWithColor(c, CGColorRefFromColor(runStrokeItem.strikethroughColor));
            CGContextBeginPath(c);
            CGContextMoveToPoint(c, strikethroughX, strikethroughY);
            CGContextAddLineToPoint(c, strikethroughEndX, strikethroughY);
            CGContextStrokePath(c);
        }
        return;
    }
    
    CGFloat cornerRadius = runStrokeItem.cornerRadius;
    if (!isStrokeColor && runStrokeItem.strokeLineWidth > 1) {
        if (active) {
            cornerRadius = (isNotClearColor(runStrokeItem.activeFillColor) && isNotClearColor(runStrokeItem.activeStrokeColor))?0:cornerRadius;
        }else{
            cornerRadius = (isNotClearColor(runStrokeItem.fillColor) && isNotClearColor(runStrokeItem.strokeColor))?0:cornerRadius;
        }
    }
    
    CGPathRef glyphRunpath = [[UIBezierPath bezierPathWithRoundedRect:roundedRect cornerRadius:cornerRadius] CGPath];
    CGContextAddPath(c, glyphRunpath);
    
    //边框线
    if (isStrokeColor) {
        UIColor *color = (active?runStrokeItem.activeStrokeColor:runStrokeItem.strokeColor);
        if (CJLabelIsNull(color)) {
            color = [UIColor clearColor];
        }
        CGContextSetStrokeColorWithColor(c, CGColorRefFromColor(color));
        CGContextSetLineWidth(c, runStrokeItem.strokeLineWidth);
        CGContextStrokePath(c);
    }
    //背景色
    else {
        if (runStrokeItem.isInsertView) {
            if (runStrokeItem.isNonLineWrap) {
                return;
            }
        }
        roundedRect.size.width += 0.5;
        glyphRunpath = [[UIBezierPath bezierPathWithRoundedRect:roundedRect cornerRadius:cornerRadius] CGPath];
        CGContextAddPath(c, glyphRunpath);
        UIColor *color = (active?runStrokeItem.activeFillColor:runStrokeItem.fillColor);
        if (CJLabelIsNull(color)) {
            color = [UIColor clearColor];
        }
        CGContextSetFillColorWithColor(c, CGColorRefFromColor(color));
        CGContextFillPath(c);
    }
}

#pragma mark - 将系统坐标转换为屏幕坐标
/**
 将系统坐标转换为屏幕坐标
 
 @param rect 坐标原点在左下角的 rect
 @return 坐标原点在左上角的 rect
 */
- (CGRect)convertRectFromLoc:(CGRect)rect {
    
    CGRect resultRect = CGRectZero;
    CGFloat labelRectHeight = self.bounds.size.height - self.textInsets.top - self.textInsets.bottom - _translateCTMty;
    CGFloat y = labelRectHeight - rect.origin.y - rect.size.height;
    
    resultRect = CGRectMake(rect.origin.x, y, rect.size.width, rect.size.height);
    return resultRect;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)containslinkAtPoint:(CGPoint)point {
    return [self linkAtPoint:point extendsLinkTouchArea:NO] != nil;
}

- (CJGlyphRunStrokeItem *)linkAtPoint:(CGPoint)point extendsLinkTouchArea:(BOOL)extendsLinkTouchArea {
    return nil;
}

- (CJGlyphRunStrokeItem *)clickLinkItemAtRadius:(CGFloat)radius aroundPoint:(CGPoint)point {
    CJGlyphRunStrokeItem *resultItem = nil;
    return resultItem;
}

- (void)setNeedsFramesetter {
    self.renderedAttributedText = nil;
    _needsFramesetter = YES;
    
    _CTLineVerticalLayoutArray = nil;
    _textNumberOfLines = -1;
    _needRedrawn = YES;
    [[CJSelectCopyManagerView instance] hideView];
}

- (NSAttributedString *)renderedAttributedText {
    if (!_renderedAttributedText) {
        NSMutableAttributedString *fullString = [[NSMutableAttributedString alloc] initWithAttributedString:_attributedText];
        
        [fullString enumerateAttributesInRange:NSMakeRange(0, fullString.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary<NSString *, id> *attrs, NSRange range, BOOL *stop){
            //如果有设置linkAttributes，则读取并设置
            NSDictionary *linkAttributes = attrs[kSALinkAttributesName];
            if (!CJLabelIsNull(linkAttributes)) {
                [fullString addAttributes:linkAttributes range:range];
            }
            
            //如果只需要计算label的size，就不用再判断activeLinkAttributes属性了
//            if (!self.caculateSizeOnly) {
                //如果有设置activeLinkAttributes，且正在点击当前链点，则读取并设置
                NSDictionary *activeLinkAttributes = attrs[kSAActiveLinkAttributesName];
                if (!CJLabelIsNull(activeLinkAttributes)) {
                    //设置当前点击链点的activeLinkAttributes属性
                    if (_currentClickRunStrokeItem) {
                        NSInteger clickRunItemRange = _currentClickRunStrokeItem.range.location + _currentClickRunStrokeItem.range.length;
                        if (range.location >= _currentClickRunStrokeItem.range.location && (range.location+range.length) <= clickRunItemRange) {
                            [fullString addAttributes:activeLinkAttributes range:range];
                        }
                    }else{
                        for (NSString *key in activeLinkAttributes) {
                            [fullString removeAttribute:key range:range];
                        }
                        //防止将linkAttributes中的属性也删除了
                        if (!CJLabelIsNull(linkAttributes)) {
                            [fullString addAttributes:linkAttributes range:range];
                        }
                    }
                }
//            }
            
        }];
        
        NSAttributedString *string = [[NSAttributedString alloc] initWithAttributedString:fullString];
        self.renderedAttributedText = string;
    }
    
    return _renderedAttributedText;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    _currentClickRunStrokeItem = nil;
    CJGlyphRunStrokeItem *item = [self linkAtPoint:[touch locationInView:self] extendsLinkTouchArea:NO];
    if (item) {
        _currentClickRunStrokeItem = item;
        _needRedrawn = _currentClickRunStrokeItem.needRedrawn;
        [self setNeedsFramesetter];
        [self setNeedsDisplay];
        //立即刷新界面
        [CATransaction flush];
    }
    
    if (!item) {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
}

- (NSAttributedString *)attributedText {
    return _attributedText;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_longPress) {
        [super touchesEnded:touches withEvent:event];
    }else{
        if (_currentClickRunStrokeItem) {
            
            NSAttributedString *attributedString = [self.attributedText attributedSubstringFromRange:_currentClickRunStrokeItem.range];
            __weak typeof(self)wSelf = self;
            CJLabelLinkModel *linkModel =
            [[CJLabelLinkModel alloc]initWithAttributedString:attributedString
                                                   insertView:_currentClickRunStrokeItem.insertView
                                               insertViewRect:_currentClickRunStrokeItem.locBounds
                                                    parameter:_currentClickRunStrokeItem.parameter
                                                    linkRange:_currentClickRunStrokeItem.range
                                                        label:wSelf];
            
            if (_currentClickRunStrokeItem.linkBlock) {
                _currentClickRunStrokeItem.linkBlock(linkModel);
            }
            if (self.delegate && [self.delegate respondsToSelector:@selector(CJLable:didClickLink:)]) {
//                [self.delegate CJLable:self didClickLink:linkModel];
            }
            
            _needRedrawn = _currentClickRunStrokeItem.needRedrawn;
            _currentClickRunStrokeItem = nil;
            [self setNeedsFramesetter];
            [self setNeedsDisplay];
        }
        else {
            [super touchesEnded:touches withEvent:event];
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_longPress) {
        [super touchesCancelled:touches withEvent:event];
    }else{
        if (_currentClickRunStrokeItem) {
            _needRedrawn = NO;
            _currentClickRunStrokeItem = nil;
        } else {
            [super touchesCancelled:touches withEvent:event];
        }
    }
}

- (void)caculateCTRunCopySizeBlock:(void(^)(void))block {
    if (_allRunItemArray.count > 0) {
        block();
        return;
    }
    self.caculateCopySize = YES;
    self.caculateCTRunSizeBlock = block;
    self.attributedText = self.attributedText;
}

static char menuItemsKey;
- (void)setMenuItems:(NSMutableArray *)menuItems {
    objc_setAssociatedObject(self, &menuItemsKey, menuItems, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//    objc_setAssociatedObject(self, &menuItemsKey, menuItems, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSMutableArray *)menuItems {
    return objc_getAssociatedObject(self, &menuItemsKey);
}

#pragma mark - UIGestureRecognizerDelegate
//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
//    return YES;
//}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer == self.longPressGestureRecognizer) {
        objc_setAssociatedObject(self.longPressGestureRecognizer, &kAssociatedUITouchKey, touch, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    else if (gestureRecognizer == self.doubleTapGes) {
        objc_setAssociatedObject(self.doubleTapGes, &kAssociatedUITouchKey, touch, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return YES;
}

- (void)longPressGestureDidFire:(UILongPressGestureRecognizer *)sender {
    
    UITouch *touch = objc_getAssociatedObject(self.longPressGestureRecognizer, &kAssociatedUITouchKey);
    CGPoint point = [touch locationInView:self];
    BOOL isLinkItem = false;
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            if (isLinkItem) {
                
            }
            else{
                if (true) {
                    _afterLongPressEnd = NO;
                    weak_block_self;
                    [self caculateCTRunCopySizeBlock:^(){
                        if (!self->_afterLongPressEnd) {
                            //发生长按，显示放大镜
                            CJGlyphRunStrokeItem *currentItem = [CJSelectCopyManagerView currentItem:point allRunItemArray:self->_allRunItemArray inset:0.5];
                            if (currentItem) {
                                [[CJSelectCopyManagerView instance] showMagnifyInCJLabel:weakSelf magnifyPoint:point runItem:currentItem];
                            }else{
                                if (CGRectContainsPoint(weakSelf.bounds, point)) {
                                    [[CJSelectCopyManagerView instance] showMagnifyInCJLabel:weakSelf magnifyPoint:point runItem:nil];
                                }
                            }
                        }
                    }];
                }
                //长按全选文本后弹出的UIMenu菜单（类似微信朋友圈全选复制功能）
                if (self.menuItems) {
                    
                    CJCTLineLayoutModel *firstLine = nil;
                    CJCTLineLayoutModel *lastLine = nil;
                    CGFloat minX = 0;
                    CGFloat maxLineWidth = 0;
                    for (CJCTLineLayoutModel *lineModel in self->_CTLineVerticalLayoutArray) {
                        minX = MIN(minX, lineModel.lineVerticalLayout.lineRect.origin.x);
                        maxLineWidth = MAX(maxLineWidth, lineModel.lineVerticalLayout.lineRect.size.width);
                        if (lineModel.lineIndex == 0) {
                            firstLine = lineModel;
                        }
                        if (lineModel.lineIndex == self->_CTLineVerticalLayoutArray.count-1) {
                            lastLine = lineModel;
                        }
                    }
                    minX = minX + self.textInsets.left;
                    maxLineWidth = maxLineWidth - self.textInsets.left - self.textInsets.right;
                    
                    CGFloat firstLineY = firstLine.lineVerticalLayout.lineRect.origin.y;
                    CGFloat allTextRectHeight = lastLine.lineVerticalLayout.lineRect.origin.y + lastLine.lineVerticalLayout.lineRect.size.height - firstLineY;
                    CGRect menuRect = CGRectMake(0, firstLineY, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
                    CGRect allTextRect = CGRectMake(minX-1, firstLineY-2, maxLineWidth+4, allTextRectHeight+4);
                    
                    UIView *allTextSelectBackView = [[UIView alloc]initWithFrame:allTextRect];
                    allTextSelectBackView.tag = [@"allTextSelectBackView" hash];
                    allTextSelectBackView.backgroundColor = CJUIRGBColor(0,84,166,0.2);
                    [self addSubview:allTextSelectBackView];
                    
                    [self becomeFirstResponder];
                    [UIMenuController sharedMenuController].menuItems = self.menuItems;
                    [[UIMenuController sharedMenuController] setTargetRect:menuRect inView:self];
                    [[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
                }
            }
            
            break;
        }
        case UIGestureRecognizerStateEnded:{
            _afterLongPressEnd = YES;
            if (!self.menuItems || self.menuItems.count == 0) {
                [[CJSelectCopyManagerView instance] hideView];
            }
            if (isLinkItem) {
                _longPress = NO;
                if (_currentClickRunStrokeItem) {
                    _needRedrawn = _currentClickRunStrokeItem.needRedrawn;
                    _currentClickRunStrokeItem = nil;
                    [self setNeedsFramesetter];
                    [self setNeedsDisplay];
                    [CATransaction flush];
                }
            }
            //发生选择复制
            if (YES) {
                CJGlyphRunStrokeItem *currentItem = [CJSelectCopyManagerView currentItem:point allRunItemArray:_allRunItemArray inset:1];
                if (currentItem) {
                    
                                    
                    //唤起 选择复制视图
                    [[CJSelectCopyManagerView instance]showSelectViewInCJLabel:self atPoint:point runItem:[currentItem copy] maxLineWidth:_lineVerticalMaxWidth allCTLineVerticalArray:_CTLineVerticalLayoutArray allRunItemArray:_allRunItemArray hideViewBlock:^(){
                        self.caculateCopySize = NO;
                        
                    }];
                }else{
                    [[CJSelectCopyManagerView instance] hideView];
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            //只移动放大镜
            if (![CJSelectCopyManagerView instance].magnifierView.hidden) {
                //发生长按，显示放大镜
                CJGlyphRunStrokeItem *currentItem = [CJSelectCopyManagerView currentItem:point allRunItemArray:_allRunItemArray inset:1];
                if (currentItem) {
                    [[CJSelectCopyManagerView instance] showMagnifyInCJLabel:self magnifyPoint:point runItem:currentItem];
                }else{
                    if (CGRectContainsPoint(self.bounds, point)) {
                        [[CJSelectCopyManagerView instance] showMagnifyInCJLabel:self magnifyPoint:point runItem:nil];
                    }
                }
            }
        }
        default:
            break;
    }
}

- (void)render
{
    if (!self.componentsAndPlainText || !self.componentsAndPlainText.plainTextData) return;
    
    //context will be nil if we are not in the call stack of drawRect, however we can calculate the height without the context
    CGContextRef context = UIGraphicsGetCurrentContext();
    // Create the framesetter with the attributed string.
    if (_framesetter) {
        CFRelease(_framesetter);
        _framesetter = NULL;
    }
    _framesetter = CTFramesetterCreateWithAttributedString(_attrString);
    
    // Initialize a rectangular path.
    CGMutablePathRef path = CGPathCreateMutable();
    CGRect bounds = CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height);
    CGPathAddRect(path, NULL, bounds);
    // Create the frame and draw it into the graphics context
    if (_ctFrame) {
        CFRelease(_ctFrame);
        _ctFrame = NULL;
    }
    _ctFrame = CTFramesetterCreateFrame(_framesetter,CFRangeMake(0, 0), path, NULL);
    
    CFRange range;
    CGSize constraint = CGSizeMake(self.frame.size.width, 1000000);
    CGSize sizeBeforeRender = _optimumSize;
    // 计算富文本size
//    CGSize sizeAfterRender = CTFramesetterSuggestFrameSizeWithConstraints(_framesetter, CFRangeMake(0, [self.componentsAndPlainText.plainTextData length]), nil, constraint, &range);
    NSMutableAttributedString *attrM = (__bridge NSMutableAttributedString *)_attrString;
    CGSize sizeAfterRender = CTFramesetterSuggestFrameSizeWithConstraints(_framesetter, CFRangeMake(0, attrM.length), nil, constraint, &range);
    self.optimumSize = sizeAfterRender;
    
    if (context) {
        for (UIView *subView in self.subviews) {
            if ([subView isKindOfClass:[UITextView class]] || [subView isKindOfClass:[UIImageView class]]) {
                [subView removeFromSuperview];
            }
        }
        
        CFArrayRef lines = CTFrameGetLines(_ctFrame);
        CGPoint lineOrigins[CFArrayGetCount(lines)];
        CTFrameGetLineOrigins(_ctFrame, CFRangeMake(0, 0), lineOrigins);
        
        // =================  复制功能处理 beg =================
        _attributedText = attrM;
//        if (_textNumberOfLines == -1) {
//            _textNumberOfLines = self.numberOfLines > 0 ? MIN(self.numberOfLines, CFArrayGetCount(lines)) : CFArrayGetCount(lines);
            _textNumberOfLines = CFArrayGetCount(lines);
//        }
        CGRect rect = CGRectMake(0, 0, sizeAfterRender.width, sizeAfterRender.height);
        _insetRect = rect;
        //记录 所有CTLine在垂直方向的对齐方式的数组
        _CTLineVerticalLayoutArray = [self allCTLineVerticalLayoutArray:lines origins:lineOrigins inRect:rect context:context textRange:CFRangeMake(0, (CFIndex)attrM.length) attributedString:attrM truncateLastLine:false];
        
        // 根据水平对齐方式调整偏移量
        CGFloat flushFactor = 0;
        CFIndex count =  CFArrayGetCount(lines);
        _allRunItemArray = [NSMutableArray array];
        for (CFIndex lineIndex = 0; lineIndex < MIN(_textNumberOfLines,count); lineIndex++) {
            CGPoint lineOrigin = lineOrigins[lineIndex];
            CGContextSetTextPosition(context, lineOrigin.x, lineOrigin.y);
            CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
            
            CGFloat lineAscent = 0.0f, lineDescent = 0.0f, lineLeading = 0.0f;
            CGFloat lineWidth = CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
            CJCTLineLayoutModel *lineLayoutModel = _CTLineVerticalLayoutArray[lineIndex];
            CGFloat penOffset = (CGFloat)CTLineGetPenOffsetForFlush(line, flushFactor, rect.size.width);
            
            [self drawCTLine:line lineIndex:lineIndex origin:lineOrigin context:context lineAscent:lineAscent lineDescent:lineDescent lineLeading:lineLeading lineWidth:lineWidth rect:rect penOffsetX:penOffset lineLayoutModel:lineLayoutModel];
        }
        
        // =================  复制功能处理 end =================
        
        //Calculate the bounding rect for link
        if (self.currentLinkComponent) {
            // get the lines
            
            CGContextSetTextMatrix(context, CGAffineTransformIdentity);
            
            CGRect rect = CGPathGetBoundingBox(path);
            // for each line
            for (int i = 0; i < CFArrayGetCount(lines); i++) {
                CTLineRef line = CFArrayGetValueAtIndex(lines, i);
                CFArrayRef runs = CTLineGetGlyphRuns(line);
                CGFloat lineAscent;
                CGFloat lineDescent;
                CGFloat lineLeading;
                CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
                CGPoint origin = lineOrigins[i];
                // fo each glyph run in the line
                for (int j = 0; j < CFArrayGetCount(runs); j++) {
                    CTRunRef run = CFArrayGetValueAtIndex(runs, j);
                    if (!self.currentLinkComponent) {
                        return;
                    }
                    CGRect runBounds = [self BoundingRectForLink:self.currentLinkComponent withRun:run];
                    if (runBounds.size.width != 0 && runBounds.size.height != 0) {
                        
                        //runBounds.size.height = lineAscent + fabsf(lineDescent) + lineLeading;
                        CGFloat lineHeight = lineAscent + fabsf(lineDescent) + lineLeading;
                        runBounds.origin.x += origin.x;
                        
                        // this is more favourable
                        if (runBounds.size.height > IMAGE_LINK_BOUND_MIN_HEIGHT) {
                            runBounds.origin.x -= LINK_PADDING;
                            runBounds.size.width += LINK_PADDING * 2;
                            runBounds.origin.y -= LINK_PADDING;
                            runBounds.size.height += LINK_PADDING * 2;
                        } else {
                            if (ABS((runBounds.size.height - lineHeight)) <= LINK_PADDING * 6) {
                                runBounds.origin.x -= LINK_PADDING * 2;
                                runBounds.size.width += LINK_PADDING * 4;
                                runBounds.size.height = lineHeight;
                                
                                runBounds.origin.y = (0 - lineHeight / 8 - lineAscent);
                                runBounds.size.height += lineHeight / 4;
                            } else {
                                NSLog(@"%@",@"Run will use its original height!");
                                runBounds.origin.y -= runBounds.size.height / 8;
                                runBounds.size.height += runBounds.size.height / 4;
                            }
                        }
                        
                        
                        CGFloat y = rect.origin.y + rect.size.height - origin.y;
                        runBounds.origin.y += y ;
                        //Adjust the runBounds according to the line original position
                        
                        // Finally, create a rounded rect with a nice shadow and fill.
                        
                        CGContextSetFillColorWithColor(context, [[UIColor grayColor] CGColor]);
                        CGPathRef highlightPath = [self newPathForRoundedRect:runBounds radius:(runBounds.size.height / 10.0)];
                        CGContextSetShadow(context, CGSizeMake(2, 2), 1.0);
                        CGContextAddPath(context, highlightPath);
                        CGContextFillPath(context);
                        CGPathRelease(highlightPath);
                        CGContextSetShadowWithColor(context, CGSizeZero, 0.0, NULL);
                    }
                }
            }
        }
        
        
        CGAffineTransform flipVertical = CGAffineTransformMake(1,0,0,-1,0,self.frame.size.height);
        CGContextConcatCTM(context, flipVertical);
        CTFrameDraw(_ctFrame, context);
        
        for (RTLabelComponent *component in self.componentsAndPlainText.components) {
            
            if ([component.tagLabel isEqualToString:@"hr"]) {
                for (int i = 0; i < CFArrayGetCount(lines); i++) {
                    CTLineRef line = CFArrayGetValueAtIndex(lines, i);
                    CGFloat lineAscent;
                    CGFloat lineDescent;
                    CGFloat lineLeading;
                    CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
                    CGFloat lineHeight = lineAscent + fabs(lineDescent) + lineLeading;
                    CFRange lineRange = CTLineGetStringRange(line);
                    if (lineRange.location <= component.position && lineRange.location + lineRange.length > component.position + [component.text length]) {
                        CGPoint point = lineOrigins[i];
                        CGFloat sizeHeight = 1;
                        CGFloat diff = lineHeight - sizeHeight;
                        point.y += diff / 2.0;
                        CGContextMoveToPoint(context, point.x, point.y + 1);
                        CGContextAddLineToPoint(context, point.x + self.frame.size.width - point.x * 2, point.y + 1);
                        CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
                        CGContextSetLineWidth(context, sizeHeight); // 设置分隔线宽度
                        CGContextStrokePath(context); //绘制分隔线
                    }
                }
            }
        }
        
        //Calculate the bounding for image
        
        for (RTLabelComponent *component in self.componentsAndPlainText.imgComponents)
        {
            for (int i = 0; i < CFArrayGetCount(lines); i++) {
                CTLineRef line = CFArrayGetValueAtIndex(lines, i);
                CGFloat lineAscent;
                CGFloat lineDescent;
                CGFloat lineLeading;
                CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
                CGFloat lineHeight = lineAscent + fabsf(lineDescent) + lineLeading;
                CFRange lineRange = CTLineGetStringRange(line);
                if (lineRange.location <= component.position && lineRange.location + lineRange.length >= component.position + [component.text length]) {
                    CFArrayRef runs = CTLineGetGlyphRuns(line);
                    for (int j = 0; j < CFArrayGetCount(runs); j++) {
                        CTRunRef run = CFArrayGetValueAtIndex(runs, j);
                        CGRect runBounds = [self BoundingRectFroImage:component withRun:run];
                        if (runBounds.size.width != 0 && runBounds.size.height != 0) {
                            CGPoint origin = lineOrigins[i];
                            runBounds.origin.x += origin.x;
                            runBounds.origin.y = origin.y;
                            
//                            runBounds.origin.y -= 2 * IMAGE_PADDING;
                            runBounds.origin.y -= 1;
                            
                            if ([component.attributes objectForKey:@"src"]) {
                                NSString *url =  [component.attributes objectForKey:@"src"];
                                
                                if (component.img) {
//                                    if ([url rangeOfString:@"2fdc20.png"].location != NSNotFound) {
//                                        NSLog(@"df");
//                                    }
                                    runBounds.size = MyGetSize((__bridge void *)(url));
//                                    runBounds.size = CGSizeMake(runBounds.size.width *2, runBounds.size.height * 2);
                                    CGFloat diff = lineHeight - runBounds.size.height;
                                    runBounds.origin.y += diff / 2.0;
                                    CGContextDrawImage(context, runBounds, component.img.CGImage);
                                } else {
                                    CGFloat diff = lineHeight - runBounds.size.height;
                                    
                                    runBounds.origin.y += diff / 2.0;
                                    CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:(BG_COLOR&0xFF0000>>16)/255.f green:(BG_COLOR&0x00FF00>>8)/255.f blue:(BG_COLOR&0x0000FF)/255.f alpha:1.0f] CGColor]);
                                    
                                    CGContextFillRect(context, runBounds);
                                    
                                    
                                    /*if (component.isDownloadFail) {
                                     
                                     [[component.attributes objectForKey:@"src"] drawInRect:runBounds withFont:self.font lineBreakMode:UILineBreakModeTailTruncation];
                                     }*/
                                }
                            } else {
                                CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:(BG_COLOR&0xFF0000>>16)/255.f green:(BG_COLOR&0x00FF00>>8)/255.f blue:(BG_COLOR&0x0000FF)/255.f alpha:1.0f] CGColor]);
                                
                                CGContextFillRect(context, runBounds);
                            }
                        }
                    }
                }
            }
        }
        if (self.componentsAndPlainText.imgComponents.count) {
            if (fabs(sizeAfterRender.height - sizeBeforeRender.height) > 10) {
                if (self.sizeDelegate && [self.sizeDelegate respondsToSelector:@selector(rtLabel:didChangedSize:)]) {
                    [self.sizeDelegate rtLabel:self didChangedSize:sizeAfterRender];
                }
                //                BLLog(@"size changed!!");
            }
        }
        
        for (RTLabelComponent *component in self.componentsAndPlainText.tbComponents)
        {
            for (int i = 0; i < CFArrayGetCount(lines); i++) {
                CTLineRef line = CFArrayGetValueAtIndex(lines, i);
                CGFloat lineAscent;
                CGFloat lineDescent;
                CGFloat lineLeading;
                CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
                CGFloat lineHeight = lineAscent + fabsf(lineDescent) + lineLeading;
                CFRange lineRange = CTLineGetStringRange(line);
                if (lineRange.location <= component.position && lineRange.location + lineRange.length >= component.position + [component.text length]) {
                    CFArrayRef runs = CTLineGetGlyphRuns(line);
                    for (int j = 0; j < CFArrayGetCount(runs); j++) {
                        CTRunRef run = CFArrayGetValueAtIndex(runs, j);
                        CGRect runBounds = [self BoundingRectFroTbComponent:component withRun:run];
                        if (runBounds.size.width != 0 && runBounds.size.height != 0) {
                            CGPoint origin = lineOrigins[i];
//                            runBounds.origin.x += origin.x;
                            runBounds.origin.y = self.frame.size.height - origin.y - runBounds.size.height;
                            
//                            runBounds.origin.y -= 2 * IMAGE_PADDING;
//                            runBounds.origin.y -= 1;
                            
                            if ([component.attributes objectForKey:@"id"]) {
                                
                                if (component.attachView) {
                                    component.attachView.frame = runBounds;
                                    component.attachView.backgroundColor = [UIColor clearColor];
                                   
                                    UIGraphicsBeginImageContextWithOptions(runBounds.size, NO, [UIScreen mainScreen].scale);
                                    
                                    CGContextRef context = UIGraphicsGetCurrentContext();
                                    
                                    [component.attachView.layer renderInContext:context];
                                    UIImage*image = UIGraphicsGetImageFromCurrentImageContext();
                                    
                                    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
                                    UIGraphicsEndImageContext();
                                    
                                    UIView *imgView = [[UIImageView alloc] initWithImage:image];
                                    imgView.frame = runBounds;
                                    [self addSubview:imgView];
                                    [component.attachView setNeedsDisplay];
                                    
                                    [self.superview setNeedsDisplay];
                                }
                            } else {
                                CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:(BG_COLOR&0xFF0000>>16)/255.f green:(BG_COLOR&0x00FF00>>8)/255.f blue:(BG_COLOR&0x0000FF)/255.f alpha:1.0f] CGColor]);
                                
                                CGContextFillRect(context, runBounds);
                            }
                        }
                    }
                }
            }
        }
        
    }
    _visibleRange = CTFrameGetVisibleStringRange(_ctFrame);
    
    CGPathRelease(path);
}

#pragma mark -
#pragma mark styling

- (void)applyParagraphStyleToText:(CFMutableAttributedStringRef)text attributes:(NSMutableDictionary*)attributes atPosition:(int)position withLength:(int)length
{
    //BLLog(@"%@", attributes);
    
    CFMutableDictionaryRef styleDict = ( CFDictionaryCreateMutable( (0), 0, (0), (0) ) );
    
    // direction
    CTWritingDirection direction = kCTWritingDirectionLeftToRight;
    // leading
    CGFloat firstLineIndent = 5.0;
    CGFloat headIndent = 5.0;
    CGFloat tailIndent = 0.0;
    CGFloat lineHeightMultiple = 1.0;
    CGFloat maxLineHeight = 0;
    CGFloat minLineHeight = 0;
//    CGFloat paragraphSpacing = 2.0;
    CGFloat paragraphSpacing = 2.0;
//    CGFloat paragraphSpacingBefore = 8.0;
    CGFloat paragraphSpacingBefore = 0.0;
    int textAlignment = _textAlignment;
    int lineBreakMode = _lineBreakMode;
    CGFloat lineSpacing = 0.0;
    
    // 添加style的解析
    if (attributes[@"style"] != nil) {
        id value = [attributes objectForKey:@"style"];
        if ([value isKindOfClass:[NSString class]]) {
            // "text-align: right;" 可能是带 "和;的
            value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@""];
//            value = [value stringByReplacingOccurrencesOfString:@";" withString:@""];
            
            NSCharacterSet *removeSet = [NSCharacterSet whitespaceAndNewlineCharacterSet]; // 定义要去除的空格和换行符字符集
            value = [[value componentsSeparatedByCharactersInSet:removeSet] componentsJoinedByString:@""];
            
            // 8.22 处理 style = "\"text-wrap: wrap; text-align: center;\"";
            NSArray<NSString *> *styles = [value componentsSeparatedByString:@";"];
            for(int i = 0; i < styles.count; i++) {
                NSString *styleValue = [styles objectAtIndex:i];
                NSArray *arr = [styleValue componentsSeparatedByString:@":"];
                if (arr.count == 2) {
                    NSString *key = arr[0];
                    NSString *value = arr[1];
                    if ([key isEqualToString:@"text-align"] || [key isEqualToString:@"align"]) {
                        value = [value stringByTrim];
                        if ([value isEqualToString:@"left"])
                        {
                            textAlignment = kCTTextAlignmentLeft;
                        }
                        else if ([value isEqualToString:@"right"])
                        {
                            textAlignment = kCTTextAlignmentRight;
                        }
                        else if ([value isEqualToString:@"justify"])
                        {
                            textAlignment = kCTTextAlignmentJustified;
                        }
                        else if ([value isEqualToString:@"center"])
                        {
                            textAlignment = kCTTextAlignmentCenter;
                        }
                    }
                    else if ([key isEqualToString:@"indent"])
                    {
                        firstLineIndent = [value floatValue];
                    }
                }
            }
        }
    }
    
    for (NSString *key in attributes)
    {
        
        id value = [attributes objectForKey:key];
        if ([key isEqualToString:@"align"])
        {
            if ([value isEqualToString:@"left"])
            {
                textAlignment = kCTTextAlignmentLeft;
            }
            else if ([value isEqualToString:@"right"])
            {
                textAlignment = kCTTextAlignmentRight;
            }
            else if ([value isEqualToString:@"justify"])
            {
                textAlignment = kCTTextAlignmentJustified;
            }
            else if ([value isEqualToString:@"center"])
            {
                textAlignment = kCTTextAlignmentCenter;
            }
        }
        else if ([key isEqualToString:@"indent"])
        {
            firstLineIndent = [value floatValue];
        }
        else if ([key isEqualToString:@"linebreakmode"])
        {
            if ([value isEqualToString:@"wordwrap"])
            {
                lineBreakMode = kCTLineBreakByWordWrapping;
            }
            else if ([value isEqualToString:@"charwrap"])
            {
                lineBreakMode = kCTLineBreakByCharWrapping;
            }
            else if ([value isEqualToString:@"clipping"])
            {
                lineBreakMode = kCTLineBreakByClipping;
            }
            else if ([value isEqualToString:@"truncatinghead"])
            {
                lineBreakMode = kCTLineBreakByTruncatingHead;
            }
            else if ([value isEqualToString:@"truncatingtail"])
            {
                lineBreakMode = kCTLineBreakByTruncatingTail;
            }
            else if ([value isEqualToString:@"truncatingmiddle"])
            {
                lineBreakMode = kCTLineBreakByTruncatingMiddle;
            }
        }
    }
    
    CTParagraphStyleSetting theSettings[] =
    {
        { kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &textAlignment },
        { kCTParagraphStyleSpecifierLineBreakMode, sizeof(CTLineBreakMode), &lineBreakMode  },
        { kCTParagraphStyleSpecifierBaseWritingDirection, sizeof(CTWritingDirection), &direction },
        { kCTParagraphStyleSpecifierLineSpacing, sizeof(CGFloat), &lineSpacing },
        { kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(CGFloat), &firstLineIndent },
        { kCTParagraphStyleSpecifierHeadIndent, sizeof(CGFloat), &headIndent },
        { kCTParagraphStyleSpecifierTailIndent, sizeof(CGFloat), &tailIndent },
        { kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(CGFloat), &lineHeightMultiple },
        { kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(CGFloat), &maxLineHeight },
        { kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(CGFloat), &minLineHeight },
        { kCTParagraphStyleSpecifierParagraphSpacing, sizeof(CGFloat), &paragraphSpacing },
        { kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(CGFloat), &paragraphSpacingBefore }
    };
    
    CTParagraphStyleRef theParagraphRef = CTParagraphStyleCreate(theSettings, sizeof(theSettings) / sizeof(CTParagraphStyleSetting));
    CFDictionaryAddValue( styleDict, kCTParagraphStyleAttributeName, theParagraphRef );
    if (CFAttributedStringGetLength(text) > position) {
        CFAttributedStringSetAttributes( text, CFRangeMake(position, length), styleDict, 0 );
    }
    CFRelease(theParagraphRef);
    CFRelease(styleDict);
}

- (void)applySuperAndSubscriptWithText:(CFMutableAttributedStringRef)text isSubscript:(BOOL)isSubscript atPosition:(int)position withLength:(int)length {
    // 创建CTParagraphStyleRef段落样式对象
    CGFloat lineSpacing = -10.0;

    CTParagraphStyleSetting paragraphSettings[1] = { { kCTParagraphStyleSpecifierLineSpacingAdjustment,sizeof(CGFloat),&lineSpacing } };
    
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(paragraphSettings, 1);

    // 设置字体
    CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)@"Helvetica", 10.0, NULL);
    
    int superscriptType = 1;
    int baseline = 5;
    if (isSubscript) {
        superscriptType = 0; // 下标为0
        baseline = -5; // 下标-5
    }
    
    NSDictionary *superscriptAttributes = @{(id)kCTFontAttributeName: (__bridge id)fontRef,
                                            (id)kCTSuperscriptAttributeName:@(superscriptType),
                                            (id)kCTBaselineOffsetAttributeName:@(baseline)};

    
    
    CFRange range = CFRangeMake(position, length);
    CFAttributedStringSetAttributes(text, range, (__bridge CFDictionaryRef)superscriptAttributes, 0);
    
    CFRelease(fontRef);
    CFRelease(paragraphStyle);
}

/// 设置h1-h3标题
- (void)applyHeaderTitleStyleWithText:(CFMutableAttributedStringRef)text hn:(int)hn atPosition:(int)position withLength:(int)length {
    
    // 创建CTFontRef字体对象
    CTFontRef font;
    if (hn == 1) {
        font = CTFontCreateWithName(CFSTR("Helvetica-Bold"), 24.0, NULL);
    } else if (hn == 2) {
        font = CTFontCreateWithName(CFSTR("Helvetica-Bold"), 18.0, NULL);
    } else {
        font = CTFontCreateWithName(CFSTR("Helvetica-BoldOblique"), 16.0, NULL);
    }
    
  
    
    // 设置标题的样式
    CFRange range = CFRangeMake(position, length);
    CFMutableDictionaryRef attributes = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionaryAddValue(attributes, kCTFontAttributeName, font);
    CFAttributedStringSetAttributes(text, range, attributes, 0);
    
    CFRelease(font);
    CFRelease(attributes);
}

- (void)applySingleUnderlineText:(CFMutableAttributedStringRef)text atPosition:(int)position withLength:(int)length
{
    CFStringRef keys[] = { kCTUnderlineStyleAttributeName };
    CFTypeRef values[] = { (__bridge CFNumberRef)[NSNumber numberWithInt:kCTUnderlineStyleSingle] };
    
    CFDictionaryRef fontDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
    
    CFAttributedStringSetAttributes(text, CFRangeMake(position, length), fontDict, 0);
    CFRelease(fontDict);
    
}

- (void)applyDoubleUnderlineText:(CFMutableAttributedStringRef)text atPosition:(int)position withLength:(int)length
{
    
    CFStringRef keys[] = { kCTUnderlineStyleAttributeName };
    CFTypeRef values[] = { (__bridge CFNumberRef)[NSNumber numberWithInt:kCTUnderlineStyleDouble] };
    
    CFDictionaryRef fontDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
    
    CFAttributedStringSetAttributes(text, CFRangeMake(position, length), fontDict, 0);
    CFRelease(fontDict);
}

- (void)applyItalicStyleToText:(CFMutableAttributedStringRef)text atPosition:(int)position withLength:(int)length
{
    UIFont *font = [UIFont italicSystemFontOfSize:self.font.pointSize];
    CTFontRef italicFont = CTFontCreateWithName ((CFStringRef)[font fontName], [font pointSize], NULL);
    
    
    CFStringRef keys[] = { kCTFontAttributeName };
    CFTypeRef values[] = { italicFont };
    
    CFDictionaryRef fontDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
    
    CFAttributedStringSetAttributes(text, CFRangeMake(position, length), fontDict, 0);
    
    
    CFRelease(italicFont);
    CFRelease(fontDict);
}

- (void)applyFontAttributes:(NSDictionary*)attributes toText:(CFMutableAttributedStringRef)text atPosition:(int)position withLength:(int)length
{
    for (NSString *key in attributes)
    {
        NSString *value = [attributes objectForKey:key];
        value = [value stringByReplacingOccurrencesOfString:@"'" withString:@""];
        
        if ([key isEqualToString:@"color"])
        {
            [self applyColor:value toText:text atPosition:position withLength:length];
        }
        else if ([key isEqualToString:@"stroke"])
        {
            
            CFStringRef keys[] = { kCTStrokeWidthAttributeName };
            CFTypeRef values[] = { (__bridge CFTypeRef)([NSNumber numberWithFloat:[[attributes objectForKey:@"stroke"] intValue]]) };
            
            CFDictionaryRef fontDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
            
            CFAttributedStringSetAttributes(text, CFRangeMake(position, length), fontDict, 0);
            
            
            CFRelease(fontDict);
            
        }
        else if ([key isEqualToString:@"kern"])
        {
            CFStringRef keys[] = { kCTKernAttributeName };
            CFTypeRef values[] = { (__bridge CFTypeRef)([NSNumber numberWithFloat:[[attributes objectForKey:@"kern"] intValue]]) };
            
            CFDictionaryRef fontDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
            
            CFAttributedStringSetAttributes(text, CFRangeMake(position, length), fontDict, 0);
            CFRelease(fontDict);
        }
        else if ([key isEqualToString:@"underline"])
        {
            int numberOfLines = [value intValue];
            if (numberOfLines==1)
            {
                [self applySingleUnderlineText:text atPosition:position withLength:length];
            }
            else if (numberOfLines==2)
            {
                [self applyDoubleUnderlineText:text atPosition:position withLength:length];
            }
        }
        else if ([key isEqualToString:@"style"])
        {
            if ([value isEqualToString:@"bold"])
            {
                [self applyBoldStyleToText:text atPosition:position withLength:length];
            }
            else if ([value isEqualToString:@"italic"])
            {
                [self applyItalicStyleToText:text atPosition:position withLength:length];
            }
        }
    }
    
    UIFont *font = nil;
    if ([attributes objectForKey:@"face"] && [attributes objectForKey:@"size"])
    {
        NSString *fontName = [attributes objectForKey:@"face"];
        fontName = [fontName stringByReplacingOccurrencesOfString:@"'" withString:@""];
        font = [UIFont fontWithName:fontName size:[[attributes objectForKey:@"size"] intValue]];
    }
    else if ([attributes objectForKey:@"face"] && ![attributes objectForKey:@"size"])
    {
        NSString *fontName = [attributes objectForKey:@"face"];
        fontName = [fontName stringByReplacingOccurrencesOfString:@"'" withString:@""];
        font = [UIFont fontWithName:fontName size:self.font.pointSize];
    }
    else if (![attributes objectForKey:@"face"] && [attributes objectForKey:@"size"])
    {
        font = [UIFont fontWithName:[self.font fontName] size:[[attributes objectForKey:@"size"] intValue]];
    }
    if (font)
    {
        CTFontRef customFont = CTFontCreateWithName ((CFStringRef)[font fontName], [font pointSize], NULL);
        
        CFStringRef keys[] = { kCTFontAttributeName };
        CFTypeRef values[] = { customFont };
        
        CFDictionaryRef fontDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
        
        CFAttributedStringSetAttributes(text, CFRangeMake(position, length), fontDict, 0);
        
        CFRelease(customFont);
        CFRelease(fontDict);
    }
}

//This method will be called when parsing a link
- (void)applyBoldStyleToText:(CFMutableAttributedStringRef)text atPosition:(int)position withLength:(int)length
{
    
    //If the font size is very large(bigger than 30), core text will invoke a memory
    //warning, and may cause crash.
    
    /**
     3.7日修改  原来的有bug  boldFont不会生效生成粗体
     */
//    UIFont *font = [UIFont boldSystemFontOfSize:self.font.pointSize + 1];
////    UIFont *font = [UIFont systemFontOfSize:self.font.pointSize + 1 weight:UIFontWeightLight];
//    CTFontRef boldFont = CTFontCreateWithName ((CFStringRef)[font fontName], [font pointSize], NULL);
    
    //
    NSDictionary *fontAttributes =
                      [NSDictionary dictionaryWithObjectsAndKeys:
                              @"Courier", (NSString *)kCTFontFamilyNameAttribute,
                              @"Bold", (NSString *)kCTFontStyleNameAttribute,
                              [NSNumber numberWithFloat:self.font.pointSize + 1],
                              (NSString *)kCTFontSizeAttribute,
                              nil];
    // Create a descriptor.
    CTFontDescriptorRef descriptor =
              CTFontDescriptorCreateWithAttributes((CFDictionaryRef)fontAttributes);
     
    // Create a font using the descriptor.
    CTFontRef newfont = CTFontCreateWithFontDescriptor(descriptor, 0.0, NULL);
    CFRelease(descriptor);
    
    CFStringRef keys[] = { kCTFontAttributeName };
    CFTypeRef values[] = { newfont };
    
    CFDictionaryRef fontDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
    
    CFAttributedStringSetAttributes(text, CFRangeMake(position, length), fontDict, 0);
    
    //CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTFontAttributeName, boldFont);
    
    //CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTFontAttributeName, _thisFont);
    CFRelease(newfont);
    CFRelease(fontDict);
}

- (void)applyColor:(NSString*)value toText:(CFMutableAttributedStringRef)text atPosition:(int)position withLength:(int)length
{
    if(!value) {
        
        CGColorRef color = [self.textColor CGColor];
        CFStringRef keys[] = { kCTForegroundColorAttributeName };
        CFTypeRef values[] = { color };
        
        CFDictionaryRef colorDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
        
        CFAttributedStringSetAttributes(text, CFRangeMake(position, length), colorDict, 0);
        CFRelease(colorDict);
    }
    else if ([value rangeOfString:@"#"].location == 0) {
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        value = [value stringByReplacingOccurrencesOfString:@"#" withString:@""];
        NSArray *colorComponents = [self colorForHex:value];
        CGFloat components[] = { [[colorComponents objectAtIndex:0] floatValue] , [[colorComponents objectAtIndex:1] floatValue] , [[colorComponents objectAtIndex:2] floatValue] , [[colorComponents objectAtIndex:3] floatValue] };
        CGColorRef color = CGColorCreate(rgbColorSpace, components);
        
//        CFStringRef keys[] = { kCTForegroundColorAttributeName };
        CFStringRef keys[] = { kCTForegroundColorAttributeName };
        CFTypeRef values[] = { color };
        
        CFDictionaryRef colorDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
        
        CFAttributedStringSetAttributes(text, CFRangeMake(position, length), colorDict, 0);
        
        CGColorRelease(color);
        CFRelease(colorDict);
        CGColorSpaceRelease(rgbColorSpace);
    } else {
        value = [value stringByAppendingString:@"Color"];
        SEL colorSel = NSSelectorFromString(value);
        UIColor *_color = nil;
        if ([UIColor respondsToSelector:colorSel]) {
            _color = [UIColor performSelector:colorSel];
            CGColorRef color = [_color CGColor];
            
            CFStringRef keys[] = { kCTForegroundColorAttributeName };
            CFTypeRef values[] = { color };
            
            CFDictionaryRef colorDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
            
            CFAttributedStringSetAttributes(text, CFRangeMake(position, length), colorDict, 0);
            
            CFRelease(colorDict);
            
        }
    }
}

/// key:0 代表前景色  1 代表背景色
- (void)applyColor:(NSString*)value attrKey:(int)attrKey toText:(CFMutableAttributedStringRef)text atPosition:(int)position withLength:(int)length
{
    if(!value) {
        
        CGColorRef color = [self.textColor CGColor];
        CFStringRef attrName = kCTForegroundColorAttributeName;
        if (attrKey == 1) {
            attrName = kCTBackgroundColorAttributeName;
        }
        
        CFStringRef keys[] = { attrName  };
        
        CFTypeRef values[] = { color };
        
//        CFStringRef keys[] = { kCTFontAttributeName };
//        CFTypeRef values[] = { boldFont };
        
        CFDictionaryRef colorDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
        
        CFAttributedStringSetAttributes(text, CFRangeMake(position, length), colorDict, 0);
        CFRelease(colorDict);
    }
    else if ([value rangeOfString:@"#"].location == 0) {
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        value = [value stringByReplacingOccurrencesOfString:@"#" withString:@""];

        
        NSArray *colorComponents = [self colorForHex:value];
        CGFloat components[] = { [[colorComponents objectAtIndex:0] floatValue] , [[colorComponents objectAtIndex:1] floatValue] , [[colorComponents objectAtIndex:2] floatValue] , [[colorComponents objectAtIndex:3] floatValue] };
        CGColorRef color = CGColorCreate(rgbColorSpace, components);
        
        CFStringRef attrName = kCTForegroundColorAttributeName;
        if (attrKey == 1) {
            attrName = kCTBackgroundColorAttributeName;
        }
        CFStringRef keys[] = { attrName };
        
        CFTypeRef values[] = { color };
        
        CFDictionaryRef colorDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
        
        CFAttributedStringSetAttributes(text, CFRangeMake(position, length), colorDict, 0);
        
        CGColorRelease(color);
        CFRelease(colorDict);
        CGColorSpaceRelease(rgbColorSpace);
    } else {
        value = [value stringByAppendingString:@"Color"];
        SEL colorSel = NSSelectorFromString(value);
        UIColor *_color = nil;
        if ([UIColor respondsToSelector:colorSel]) {
            _color = [UIColor performSelector:colorSel];
            CGColorRef color = [_color CGColor];
            
            CFStringRef attrName = kCTForegroundColorAttributeName;
            if (attrKey == 1) {
                attrName = kCTBackgroundColorAttributeName;
            }
            CFStringRef keys[] = { attrName };
            
            CFTypeRef values[] = { color };
            
            CFDictionaryRef colorDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
            
            CFAttributedStringSetAttributes(text, CFRangeMake(position, length), colorDict, 0);
            
            CFRelease(colorDict);
            
        }
    }
}


- (void)applyUnderlineColor:(NSString*)value toText:(CFMutableAttributedStringRef)text atPosition:(int)position withLength:(int)length
{
    value = [value stringByReplacingOccurrencesOfString:@"'" withString:@""];
    if ([value rangeOfString:@"#"].location==0) {
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        value = [value stringByReplacingOccurrencesOfString:@"#" withString:@""];
        NSArray *colorComponents = [self colorForHex:value];
        CGFloat components[] = { [[colorComponents objectAtIndex:0] floatValue] , [[colorComponents objectAtIndex:1] floatValue] , [[colorComponents objectAtIndex:2] floatValue] , [[colorComponents objectAtIndex:3] floatValue] };
        CGColorRef color = CGColorCreate(rgbColorSpace, components);
        
        CFStringRef keys[] = { kCTUnderlineColorAttributeName };
        CFTypeRef values[] = { color };
        
        CFDictionaryRef colorDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
        
        CFAttributedStringSetAttributes(text, CFRangeMake(position, length), colorDict, 0);
        
        
        
        CGColorRelease(color);
        CFRelease(colorDict);
        CGColorSpaceRelease(rgbColorSpace);
    } else {
        value = [value stringByAppendingString:@"Color"];
        SEL colorSel = NSSelectorFromString(value);
        UIColor *_color = nil;
        if ([UIColor respondsToSelector:colorSel]) {
            _color = [UIColor performSelector:colorSel];
            CGColorRef color = [_color CGColor];
            
            
            CFStringRef keys[] = { kCTUnderlineColorAttributeName };
            CFTypeRef values[] = { color };
            
            CFDictionaryRef colorDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
            
            CFAttributedStringSetAttributes(text, CFRangeMake(position, length), colorDict, 0);
            
            CFRelease(colorDict);
        }
    }
}

- (void)applyBottomLine:(CFMutableAttributedStringRef)text attributes:(NSMutableDictionary*)attributes atPosition:(int)position withLength:(int)length {
    CFStringRef keys[] = { kCTUnderlineStyleAttributeName };
    CFTypeRef values[] = { (__bridge CFTypeRef)([NSNumber numberWithInt:kCTUnderlineStyleSingle]) };
    CFDictionaryRef underlineStyleDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
    
    CFAttributedStringSetAttributes(text, CFRangeMake(position, length), underlineStyleDict, 0);
    
    CFRelease(underlineStyleDict);
}

/// 添加中划线
- (void)applyThroughLine:(CFMutableAttributedStringRef)text attributes:(NSMutableDictionary*)attributesDict atPosition:(int)position withLength:(int)length {
    NSMutableAttributedString *attrString = (__bridge NSMutableAttributedString *)text;
    [attrString addAttribute:NSStrikethroughStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(position, length)];
}

- (void)applyImageAttributes:(CFMutableAttributedStringRef)text attributes:(NSMutableDictionary*)attributes atPosition:(int)position withLength:(int)length
{
    // create the delegate
    CTRunDelegateCallbacks callbacks;
    callbacks.version = kCTRunDelegateVersion1;
    callbacks.dealloc = MyDeallocationCallback;
    callbacks.getAscent = MyGetAscentCallback;
    callbacks.getDescent = MyGetDescentCallback;
    callbacks.getWidth = MyGetWidthCallback;
    
    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, (__bridge void * _Nullable)([attributes objectForKey:@"src"]));
    
    CFStringRef keys[] = { kCTRunDelegateAttributeName };
    CFTypeRef values[] = { delegate };
    
    CFDictionaryRef imgDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
    
    CFAttributedStringSetAttributes(text, CFRangeMake(position, length), imgDict, 0);
    
    CGColorRef color = [UIColor clearColor].CGColor;
    
    CFStringRef keyss[] = { kCTForegroundColorAttributeName };
    CFTypeRef valuess[] = { color };
    
    CFDictionaryRef colorDict = CFDictionaryCreate(NULL, (const void **)&keyss, (const void **)&valuess, sizeof(keyss) / sizeof(keyss[0]), NULL, NULL);
    CFAttributedStringSetAttributes(text, CFRangeMake(position, length), colorDict, 0);
    
    CFRelease(colorDict);
    CFRelease(delegate);
    CFRelease(imgDict);
}

- (void)applyTableAttributes:(CFMutableAttributedStringRef)text attributes:(NSMutableDictionary*)attributes atPosition:(int)position withLength:(int)length
{
    // create the delegate
    CTRunDelegateCallbacks callbacks;
    callbacks.version = kCTRunDelegateVersion1;
    callbacks.dealloc = MyDeallocationCallback;
    callbacks.getAscent = MyTableGetAscentCallback;
    callbacks.getDescent = MyTableGetDescentCallback;
    callbacks.getWidth = MyTableGetWidthCallback;
    
    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, (__bridge void * _Nullable)([attributes objectForKey:@"id"]));
    
    CFStringRef keys[] = { kCTRunDelegateAttributeName };
    CFTypeRef values[] = { delegate };
    
    CFDictionaryRef imgDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
    
    if (CFAttributedStringGetLength(text) > position) {
        CFAttributedStringSetAttributes(text, CFRangeMake(position, length), imgDict, 0);
    }
    
    CGColorRef color = [UIColor clearColor].CGColor;
    
    CFStringRef keyss[] = { kCTForegroundColorAttributeName };
    CFTypeRef valuess[] = { color };
    
    CFDictionaryRef colorDict = CFDictionaryCreate(NULL, (const void **)&keyss, (const void **)&valuess, sizeof(keyss) / sizeof(keyss[0]), NULL, NULL);
    if (CFAttributedStringGetLength(text) > position) {
        CFAttributedStringSetAttributes(text, CFRangeMake(position, length), colorDict, 0);
    }
    
    CFRelease(colorDict);
    CFRelease(delegate);
    CFRelease(imgDict);
}


- (CGSize)optimumSize
{
    [self render];
    return _optimumSize;
}

- (void)dealloc
{
    self.currentLinkComponent = nil;
    self.currentImgComponent = nil;
    
    CFRelease(_thisFont);
    _thisFont = NULL;
    if (_ctFrame) {
        CFRelease(_ctFrame);
        _ctFrame = NULL;
    }
    if (_framesetter) {
        CFRelease(_framesetter);
        _framesetter = NULL;
    }
    if (_attrString) {
        CFRelease(_attrString);
        _attrString = NULL;
    }
}

+ (RTLabelComponentsStructure *)extractTextStyle:(NSString *)data {
    
    return [self extractTextStyle:data IsLocation:NO withSALabel:nil whetherOrNotNewline:NO];
}

+ (RTLabelComponentsStructure*)extractTextStyle:(NSString*)data IsLocation:(BOOL)location withSALabel:(SALabel *)label whetherOrNotNewline:(BOOL)newLine
{
//    data = @"<span style=\"line-height: 130%;\">年年末<span style=\"color:rgb(255,0,0);\" >红色稳投资</span></span>"; // 测试span嵌套
    NSScanner *scanner = nil;
    NSString *text = nil;
    NSString *tag = nil;
    //These two variable are used to handle the unclosed tags.
    BOOL isBeginTag = NO;
    NSInteger beginTagCount = 0;
    
    //plainData is used to store the current plain result during the parse process,
    //such as <a>link to yahoo!</a> </font> (the start tag <font size=30> has
    //been parsed)
    if (!data) {
        data = @"";
    }
    NSMutableString *str1 = [NSMutableString stringWithString:data];
    if (!newLine) {
        for (int i = 0; i < str1.length; i++) {
            unichar c = [str1 characterAtIndex:i];
            NSRange range = NSMakeRange(i, 1);
            
            //  在这里添加要过滤的特殊符号
            if ( c == '\r' || c == '\n' || c == '\t' ) {
                [str1 deleteCharactersInRange:range];
                --i;
            }
        }
    }
    if ([str1 containsString:@"&nbsp;"]) {
        str1 = [str1 stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "].mutableCopy;
    }
  
    NSString *plainData  = [NSString stringWithString:str1];
    
    NSMutableArray *components = [NSMutableArray array];
    NSMutableArray *linkComponents = [NSMutableArray array];
    NSMutableArray *imgComponents = [NSMutableArray array];
    NSMutableArray *tbComponents = [NSMutableArray array];
    
    int last_position = 0;
    scanner = [NSScanner scannerWithString:str1];
    while (![scanner isAtEnd])
    {
        //Begin element(such as <font size=30>) or end element(such as </font>)
        [scanner scanUpToString:@"<" intoString:&text];
        // <span style=\"line-height: 130%;\">年年末<span lang=\"EN-US\"><o:p></o:p></span></span>
        if(beginTagCount <= 0 && !isBeginTag && text) { //This words even can handle the unclosed tags elegancely
            
            NSRange subRange;
            //Decipher
            do {
                subRange = [plainData rangeOfString:@"&lt;" options:NSCaseInsensitiveSearch range:NSMakeRange(last_position, [text length])];
                if (subRange.location == NSNotFound) {
                    break;
                }
                
                plainData = [plainData stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<" options:NSCaseInsensitiveSearch range:subRange];
                text = [text stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<" options:NSCaseInsensitiveSearch range:NSMakeRange(subRange.location - last_position,subRange.length)];
                
                
            }
            while (true);
            do {
                subRange = [plainData rangeOfString:@"&gt;" options:NSCaseInsensitiveSearch range:NSMakeRange(last_position, [text length])];
                if (subRange.location == NSNotFound) {
                    break;
                }
                
                plainData = [plainData stringByReplacingOccurrencesOfString:@"&gt;" withString:@">" options:NSCaseInsensitiveSearch range:subRange];
                text = [text stringByReplacingOccurrencesOfString:@"&gt;" withString:@">" options:NSCaseInsensitiveSearch range:NSMakeRange(subRange.location - last_position,subRange.length)];
            }
            while (true);
            RTLabelComponent *component = [RTLabelComponent componentWithString:text tag:@"rawText" attributes:nil];
            component.isClosure = YES;
            component.position = last_position;
            [components addObject:component];
        }
        text = nil;
        
        [scanner scanUpToString:@">" intoString:&text];
        if (!text || [scanner isAtEnd]) {
            
            if (text) {
                plainData = [plainData stringByReplacingOccurrencesOfString:text withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange([plainData length] - [text length], [text length])];
                //BLLog(@"%@",plainData);
            }
            break;
        }
        else {
            
            [scanner setScanLocation:[scanner scanLocation] + 1];
        }
        //delimiter now equals to a start tag(such as <font size=30>) or end tag(such as </font>)
        
        // <font size=30>类型,或</font>类型
        NSString *delimiter = [NSString stringWithFormat:@"%@>", text];
        
        int position = (int)[plainData rangeOfString:delimiter options:NSCaseInsensitiveSearch range:NSMakeRange(last_position, [plainData length] - last_position)].location;
        
        if (position != NSNotFound && position >= last_position)
        {
            isBeginTag = YES;
            beginTagCount++;
            //Only replace the string behind the position, so no need to
            //recalculate the position
            plainData = [plainData stringByReplacingOccurrencesOfString:delimiter withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(position, delimiter.length)];
        }
        else {//NOTE:This will never happen!
            //BLLog(@"Some Error happen in parsing");
            break;
            
        }
        
        //Strip the white space in both end
        NSString *tempString = [text substringFromIndex:1];
        text = [tempString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        
        //That means a end tag, we should store the plain text after parsing the tag
        if ([text rangeOfString:@"/"].location==0)
        {
            isBeginTag = NO;
            beginTagCount --;
            // tag name
            
            //This can handle the awful white space too
            NSArray *textComponents = [[text substringFromIndex:1]componentsSeparatedByString:@" "];
            
            
            tag = [textComponents objectAtIndex:0];
            
            //BLLog(@"end of tag: %@", tag);
            
            NSRange subRange;
            //Decipher
            do {
                subRange = [plainData rangeOfString:@"&lt;" options:NSCaseInsensitiveSearch range:NSMakeRange(last_position, position - last_position)];
                if (subRange.location == NSNotFound) {
                    break;
                }
                plainData = [plainData stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<" options:NSCaseInsensitiveSearch range:subRange];
                //Length of @"&lt;" substract length of @"<"
                position -= 3;
            }
            while (true);
            do {
                subRange = [plainData rangeOfString:@"&gt;" options:NSCaseInsensitiveSearch range:NSMakeRange(last_position, position - last_position)];
                if (subRange.location == NSNotFound) {
                    break;
                }
                plainData = [plainData stringByReplacingOccurrencesOfString:@"&gt;" withString:@">" options:NSCaseInsensitiveSearch range:subRange];
                //Length of @"&gt;" substract length of @">"
                position -= 3;
            }
            while (true);
            
            //Find the latest tag
            //Do not use stack, because the overlapping tags are meaningful
            //This algrithm can handle the overlapping tags
            for (NSInteger i = [components count]-1; i>=0; i--)
            {
                RTLabelComponent *component = [components objectAtIndex:i];
                if (!component.isClosure && [component.tagLabel isEqualToString:tag])
                {
                    NSString *text2 = [plainData substringWithRange:NSMakeRange(component.position, position - component.position)];
                    component.text = text2;
                    component.isClosure = YES;
                    break;
                }
            }
        }
        else // start tag
        {
            //tag name and tag attributes
            //These words can handle if the tag is a self-closed one
            BOOL isClosure = NO;
            NSRange range = [text rangeOfString:@"/" options:NSBackwardsSearch];
            
            if (range.location == [text length] - 1) {
                isClosure = YES;
                text = [text substringToIndex:[text length] - 1];
            }
            RTLabelComponent *component = nil;
            //These words can handle if the attribute string are concacted with awful white space
            NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
            NSRange subRange;
            //You can not simply use text = [text stringByReplacingOccurrencesOfString:@"= " withString:@"="]; instead,
            //since this function can not execute incursively
            do{
                subRange = [text rangeOfString:@"= "];
                if (subRange.location == NSNotFound) {
                    break;
                }
                text = [text stringByReplacingOccurrencesOfString:@"= " withString:@"=" options:NSCaseInsensitiveSearch range:subRange];
                
            }while(true);
            
            do{
                subRange = [text rangeOfString:@" ="];
                if (subRange.location == NSNotFound) {
                    break;
                }
                text = [text stringByReplacingOccurrencesOfString:@" =" withString:@"=" options:NSCaseInsensitiveSearch range:subRange];
                
            }while(true);
            
            
            
            NSArray *textComponents = [text componentsSeparatedByString:@" "];
            tag = [textComponents objectAtIndex:0];
            
//            NSArray *textComponents = [text componentsSeparatedByString:@" "];
            // 3.7日修改  处理不识别span标记问题 <p>此外，如果监盘日不在资产<span style="color: rgb(255, 192, 0);">负债表日</span></p> 按空格分会产生5个字符串，将color: 和rgb中的空格都考虑进去了
            if (textComponents.count >= 2 && ([tag isEqualToString:@"span"] || [tag isEqualToString:@"p"] || [tag isEqualToString:@"h1"] || [tag isEqualToString:@"h2"] || [tag isEqualToString:@"h3"])) {
                NSRange replaceRange = [text rangeOfString:@" "];
                if (replaceRange.location != NSNotFound) {
                    text = [text stringByReplacingCharactersInRange:replaceRange withString:@"$#"];
        //            text = [text stringByReplacingOccurrencesOfString:@" " withString:@"$#" options:0 range:NSMakeRange(0, replaceRange.location + 1)];
                    
                    textComponents = [text componentsSeparatedByString:@"$#"];
                }
            }
            
            if (tag != nil && [tag length]) { //That means the tag starts with a white space, ignore it, treat it as a raw text
                for (int i=1; i<[textComponents count]; i++)
                {
                    //BLLog(@"textComponents %d:%@",i,[textComponents objectAtIndex:i]);
                    
                    NSArray *pair = [[textComponents objectAtIndex:i] componentsSeparatedByString:@"="];
                    if ([pair count]>=2)
                    {
                        [attributes setObject:[[pair subarrayWithRange:NSMakeRange(1, [pair count] - 1)] componentsJoinedByString:@"="] forKey:[pair objectAtIndex:0]];
                    }
                }
                
                component = [RTLabelComponent componentWithString:nil tag:tag attributes:attributes];
            }
            else {
                component = [RTLabelComponent componentWithString:nil tag:@"rawText" attributes:attributes];
            }
            
            ///Store the start position, which will be used to calculate
            ///the plain text inside of a tag
            component.position = position;
            component.isClosure = isClosure;
            BOOL isSizeTooSmall = NO;
            if ([component.tagLabel isEqualToString:@"img"]) {
                
                
                NSString *url =  [component.attributes objectForKey:@"src"];
                /*NSString *inlineStyleWidth = [component.attributes objectForKey:@"width"];
                 NSString *inlineStyleHeight = [component.attributes objectForKey:@"height"];
                 */
                
                NSString *tempURL = [SALabel stripURL:url];
                
                
                if (location) {
                    ///本地图片的渲染
                    if (tempURL) {
                        [component.attributes setObject:tempURL forKey:@"src"];
                        UIImage  *tempImg = [UIImage imageNamed:tempURL];
                        
                        component.img = tempImg;
                    }
                }else{///这里做远程图片数据的处理
                    
                    if ([tempURL hasPrefix:@"http://localhost/Library"]) { //  本地图片
                        NSString *fileName = tempURL.lastPathComponent;
                        NSString *filePath = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Library/%@",fileName]];
                        UIImage *img = [UIImage imageWithContentsOfFile:filePath];
                        component.img = img;
                    } else {
                        
                        [self downloadImageWithURL:[NSURL URLWithString:tempURL] completion:^(UIImage * _Nullable image, NSError * _Nullable error) {
                            if (image) {
                                // 处理下载的图片
                                component.img = image;
                                // 通知视图重新排版
                                if ([label.imageDelegate respondsToSelector:@selector(SJRTLabelImageSuccess:textString:)]) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [[label imageDelegate] SJRTLabelImageSuccess:label textString:data];
                                    });
                                }
                            } else {
                                NSLog(@"Error downloading image: %@", error.localizedDescription);
                            }
                        }];
                    }
                }
                
                if (!isSizeTooSmall) {
                     
                    NSMutableString *tempString = [NSMutableString stringWithString:plainData];
                    [tempString insertString:KSALabelImageVar atIndex:position];

                    plainData = [NSString stringWithString:tempString];

                    component.text = [plainData substringWithRange:NSMakeRange(component.position, 1)];
                    component.isClosure = YES;
                    
                    [components addObject:component];
                }
            } else if ([component.tagLabel isEqualToString:@"itb"]) {
                NSString *keyId = [component.attributes objectForKey:@"id"];
                keyId = [keyId stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                UIView *view = [itbViewDict objectForKey:keyId];
                component.attachView = view;
               
                NSMutableString *tempString = [NSMutableString stringWithString:plainData];
                [tempString insertString:KSALabelTableVar atIndex:position];

                plainData = [NSString stringWithString:tempString];

                component.text = [plainData substringWithRange:NSMakeRange(component.position, 1)];
                component.isClosure = YES;
                
                [components addObject:component];
            }
            else {
                [components addObject:component];
            }
            
            if ([component.tagLabel isEqualToString:@"a"]) {
                [linkComponents addObject:component];
            }
            
            if ([component.tagLabel isEqualToString:@"img"]) {
                [imgComponents addObject:component];
            }
            
            if ([component.tagLabel isEqualToString:@"itb"]) {
                [tbComponents addObject:component];
            }
            
        }
        last_position = position;
        text = nil;
    }
    for (RTLabelComponent *item in components) {
        if (!item.isClosure) {
            
            NSString *text2 = [plainData substringWithRange:NSMakeRange(item.position, [plainData length] - item.position)];
            item.text = text2;
        }
        
    }

    
    RTLabelComponentsStructure *componentsDS = [[RTLabelComponentsStructure alloc] init];
    componentsDS.components = components;
    componentsDS.linkComponents = linkComponents;
    componentsDS.imgComponents = imgComponents;
    componentsDS.plainTextData = plainData;
    componentsDS.tbComponents = tbComponents;
    return componentsDS;
}

- (void)genAttributedString
{
    if (!self.componentsAndPlainText || !self.componentsAndPlainText.plainTextData || !self.componentsAndPlainText.components) {
        return;
    }
    
    CFStringRef string = (__bridge CFStringRef)self.componentsAndPlainText.plainTextData;
    
    // Initialize a rectangular path.
    CGMutablePathRef path = CGPathCreateMutable();
    CGRect bounds = CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height);
    CGPathAddRect(path, NULL, bounds);
    // Create the frame and draw it into the graphics context
    if (_ctFrame) {
        CFRelease(_ctFrame);
        _ctFrame = NULL;
    }
    
    if (_attrString) {
        CFRelease(_attrString);
        _attrString = NULL;
    }
    _attrString = CFAttributedStringCreateMutable(NULL, 0);
    
    CFAttributedStringReplaceString (_attrString, CFRangeMake(0, 0), string);
    
    NSMutableAttributedString *attrString = (__bridge NSMutableAttributedString *)_attrString;
    // =================  复制功能处理 beg =================
    //给每一个字符设置index值，enableCopy=YES时用到
    __block NSInteger index = 0;
    [attrString.string enumerateSubstringsInRange:NSMakeRange(0, attrString.string.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        SACTRunUrl *runUrl = nil;
        if (!runUrl) {
            NSString *urlStr = [NSString stringWithFormat:@"https://www.CJLabel%@",@(index)];
            runUrl = [SACTRunUrl URLWithString:urlStr];
        }
        runUrl.index = index;
        runUrl.rangeValue = [NSValue valueWithRange:substringRange];
        [attrString addAttribute:NSLinkAttributeName
                        value:runUrl
                        range:substringRange];
        index++;
    }];
    // =================  复制功能处理 end =================
    
    _framesetter = CTFramesetterCreateWithAttributedString(_attrString);
    _ctFrame = CTFramesetterCreateFrame(_framesetter,CFRangeMake(0, 0), path, NULL);
    

    CFMutableDictionaryRef styleDict = CFDictionaryCreateMutable(NULL, 0, 0, 0);
    
    CFDictionaryAddValue( styleDict, kCTForegroundColorAttributeName, [self.textColor CGColor] );
    CFAttributedStringSetAttributes( _attrString, CFRangeMake( 0, CFAttributedStringGetLength(_attrString) ), styleDict, 0 );
    
    [self applyParagraphStyleToText:_attrString attributes:nil atPosition:0 withLength:(int)CFAttributedStringGetLength(_attrString)];
     
    CFStringRef keys[] = { kCTFontAttributeName };
    CFTypeRef values[] = { _thisFont };
    
    CFDictionaryRef fontDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values, sizeof(keys) / sizeof(keys[0]), NULL, NULL);
    
    CFAttributedStringSetAttributes(_attrString, CFRangeMake(0, CFAttributedStringGetLength(_attrString)), fontDict, 0);
    
    CFRelease(fontDict);
    
    for (RTLabelComponent *component in self.componentsAndPlainText.components)
    {
        NSInteger index = [self.componentsAndPlainText.components indexOfObject:component];
        component.componentIndex = (int)index;
        
        if ([component.tagLabel isEqualToString:@"i"])
        {
            // make font italic
            [self applyItalicStyleToText:_attrString atPosition:component.position withLength:(int)[component.text length]];
            [self applyColor:nil toText:_attrString atPosition:component.position withLength:(int)[component.text length]];
            //[self applyColor:@"#2e2e2e" toText:_attrString atPosition:component.position withLength:(int)[component.text length]];
        }
        else if ([component.tagLabel isEqualToString:@"h1"] || [component.tagLabel isEqualToString:@"h2"] || [component.tagLabel isEqualToString:@"h3"]) {
            [self applyHeaderTitleStyleWithText:_attrString hn:[component.tagLabel substringFromIndex:1].intValue atPosition:component.position withLength:(int)[component.text length]];
            [self applyParagraphStyleToText:_attrString attributes:component.attributes atPosition:component.position withLength:(int)[component.text length]];
        }
        else if ([component.tagLabel isEqualToString:@"b"])
        {
            // make font bold
            [self applyBoldStyleToText:_attrString atPosition:component.position withLength:(int)[component.text length]];
            [self applyColor:nil toText:_attrString atPosition:component.position withLength:(int)[component.text length]];
            //[self applyColor:@"#2e2e2e" toText:_attrString atPosition:component.position withLength:(int)[component.text length]];
        }
        else if ([component.tagLabel isEqualToString:@"sup"] || [component.tagLabel isEqualToString:@"sub"]) {
            BOOL sub = [component.tagLabel isEqualToString:@"sub"];
            [self applySuperAndSubscriptWithText:_attrString isSubscript:sub atPosition:component.position withLength:(int)[component.text length]];
        }
        else if ([component.tagLabel isEqualToString:@"a"])
        {
            
            [self applyBoldStyleToText:_attrString atPosition:component.position withLength:(int)[component.text length]];
            if(![self.textColor isEqual:[UIColor whiteColor]]) {
                [self applyColor:@"#16387C" toText:_attrString atPosition:component.position withLength:(int)[component.text length]];
            }
            else {
                [self applyColor:nil toText:_attrString atPosition:component.position withLength:(int)[component.text length]];
                
            }
            
            //[self applySingleUnderlineText:_attrString atPosition:component.position withLength:(int)[component.text length]];
            
            
            
            NSString *value = [component.attributes objectForKey:@"href"];
            //value = [value stringByReplacingOccurrencesOfString:@"'" withString:@""];
            if (value) {
                [component.attributes setObject:value forKey:@"href"];
                
            }
        }
        else if ([component.tagLabel isEqualToString:@"u"] || [component.tagLabel isEqualToString:@"underlined"])
        {
            // underline
            if ([component.tagLabel isEqualToString:@"u"])
            {
                [self applySingleUnderlineText:_attrString atPosition:component.position withLength:(int)[component.text length]];
            }
            
            
            if ([component.attributes objectForKey:@"color"])
            {
                NSString *value = [component.attributes objectForKey:@"color"];
                [self applyUnderlineColor:value toText:_attrString atPosition:component.position withLength:(int)[component.text length]];
            }
        }
        else if ([component.tagLabel isEqualToString:@"font"])
        {
            [self applyFontAttributes:component.attributes toText:_attrString atPosition:component.position withLength:(int)[component.text length]];
        }
        else if ([component.tagLabel isEqualToString:@"p"])
        {
            [self applyParagraphStyleToText:_attrString attributes:component.attributes atPosition:component.position withLength:(int)[component.text length]];
        }
        else if([component.tagLabel isEqualToString:@"img"])
        {
            [self applyImageAttributes:_attrString attributes:component.attributes atPosition:component.position withLength:(int)[component.text length]];
        }
        else if ([component.tagLabel isEqualToString:@"itb"])
        {
            [self applyTableAttributes:_attrString attributes:component.attributes atPosition:component.position withLength:(int)[component.text length]];
        }
        else if ([component.tagLabel isEqualToString:@"strong"]) {
//            [self applyTableAttributes:_attrString attributes:component.attributes atPosition:component.position withLength:(int)[component.text length]];
            [self applyBoldStyleToText:_attrString atPosition:component.position withLength:(int)[component.text length]];
        }
        else if ([component.tagLabel isEqualToString:@"span"])
        {
//            [self applyTableAttributes:_attrString attributes:component.attributes atPosition:component.position withLength:(int)[component.text length]];
//            "background-color: rgb(255, 0, 0);"
            // "color: rgb(0, 0, 0); font-size: 14px; font-family: arial, helvetica, sans-serif;"
            // 可能包含多个属性 先解析color和backgroundcolor
            NSString *style = [component.attributes objectForKey:@"style"];
            NSArray *attrs = [style componentsSeparatedByString:@";"];
            
            if (attrs.count > 1) {
                for (int i = 0; i < attrs.count; i++) {
                    NSString *attr = [attrs objectAtIndex:i];
                    if ([attr containsString:@"color"] || [attr containsString:@"background-color"]) {
                        NSArray *arr = [attr componentsSeparatedByString:@":"];
                        if (arr.count >= 2) {
                            NSString *key = [arr.firstObject stringByTrim];
                            NSString *value = arr[1];
                            value = [value stringByTrim];
                            if ([key isEqualToString:@"\"background-color"] || [key isEqualToString:@"\"color"] || [key isEqualToString:@"background-color"] || [key isEqualToString:@"color"]) {
                                
                                if (!self.showSourceColor) { // 不显示自带颜色
                                    continue;
                                }
                                
                                NSString *hex;
                                if ([value rangeOfString:@"#"].location != NSNotFound && value.length == 7) {
                                    hex = value;
                                } else {
                                    
                                    NSRange rangeStart = [value rangeOfString:@"("];
                                    NSRange rangeEnd = [value rangeOfString:@")"];
                                    if (rangeStart.location != NSNotFound && rangeEnd.location != NSNotFound) {
                                        value = [value substringWithRange:NSMakeRange(rangeStart.location + 1, rangeEnd.location - rangeStart.location - 1)];
                                    }
                                    NSArray *rgbArr = [value componentsSeparatedByString:@","];
                                    if (rgbArr.count < 3) { // 默认黑色
                                        rgbArr = @[@0,@0,@0];
                                    }
                                    
                                    //                    UIColor *color = RGBA([rgbArr[0] floatValue], [rgbArr[1] floatValue], [rgbArr[1] floatValue], 1.0);
                                    float r = [rgbArr[0] floatValue] / 255;
                                    float g = [rgbArr[1] floatValue] / 255;
                                    float b = [rgbArr[2] floatValue] / 255;
                                    
                                    hex = [NSString stringWithFormat:@"#%02lX%02lX%02lX",
                                                     lroundf(r * 255),
                                                     lroundf(g * 255),
                                                     lroundf(b * 255)];
                                }
                                
                                int attrKey = 1;
                                if ([key isEqualToString:@"\"color"] || [key isEqualToString:@"color"]) {
                                    attrKey = 0;
                                }
                                
                                [self applyColor:hex attrKey:attrKey toText:_attrString atPosition:component.position withLength:(int)[component.text length]];
                            }
                        }
                    } else if ([attr containsString:@"text-decoration"]) {
                        NSArray *arr = [attr componentsSeparatedByString:@":"];
                        if (arr.count >= 2) {
                            NSString *value = arr[1];
                            value = [value stringByTrim];
                            if ([value isEqualToString:@"underline"]) {
                                [self applyBottomLine:_attrString attributes:nil atPosition:component.position withLength:(int)[component.text length]];
                            } else if ([value isEqualToString:@"line-through"]) {
                                [self applyThroughLine:_attrString attributes:nil atPosition:component.position withLength:(int)[component.text length]];
                            }
                        }
                    } else if ([attr containsString:@"font-weight"]) {
                        NSArray *arr = [attr componentsSeparatedByString:@":"];
                        if (arr.count >= 2) {
                            NSString *value = arr[1];
                            value = [value stringByTrim];
                            if ([value isEqualToString:@"bolder"]) {
                                [self applyBoldStyleToText:_attrString atPosition:component.position withLength:(int)[component.text length]];
                            }
                        }
                    }
                }
            }
        }
    }
    CFRelease(styleDict);
    CFRelease(path);
    
    // ------------ 设置最大行数
    if (self.maxNumLine > 0) {
        NSMutableAttributedString *attrString = (__bridge NSMutableAttributedString *)_attrString;
        
        CGMutablePathRef paths = CGPathCreateMutable();
        CGRect boundss = CGRectMake(0.0, 0.0, self.frame.size.width, CGFLOAT_MAX);
        CGPathAddRect(paths, NULL, boundss);
        CTFramesetterRef ctFramesetter = CTFramesetterCreateWithAttributedString(_attrString);
        CTFrameRef ctFrame = CTFramesetterCreateFrame(ctFramesetter, CFRangeMake(0, attrString.length), paths, NULL);
        CFRelease(ctFramesetter);
        
        CFIndex count = CFArrayGetCount(CTFrameGetLines(ctFrame));
       
        if (self.maxNumLine >= count) {
            CFRelease(paths);
            CFRelease(ctFrame);
            return;
        }
        
        CFIndex numberOfLinesToDraw = MIN(self.maxNumLine, count);
        CGPoint lineOrigins[numberOfLinesToDraw];
        NSArray *lines = (NSArray *)CTFrameGetLines(ctFrame);
        CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, numberOfLinesToDraw), lineOrigins);
        
        for (int lineIndex = 0; lineIndex < numberOfLinesToDraw; lineIndex ++) {
            CTLineRef line = (__bridge CTLineRef)(lines[lineIndex]);
            CFRange range = CTLineGetStringRange(line);
            
            NSInteger length = attrString.length;
            if ( lineIndex == numberOfLinesToDraw - 1
                && range.location + range.length < length) {
                NSAttributedString *tokenString;
                
                tokenString = [[NSAttributedString alloc] initWithString:@"\u2026" attributes:nil];
                CGSize tokenSize = [tokenString boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin context:NULL].size;
                CGFloat tokenWidth = tokenSize.width;
                CTLineRef truncationTokenLine = CTLineCreateWithAttributedString((CFAttributedStringRef)tokenString);
                
                CFIndex truncationEndIndex = CTLineGetStringIndexForPosition(line, CGPointMake(bounds.size.width - tokenWidth, 0));
                CGFloat lengths = range.location + range.length - truncationEndIndex;
                NSMutableAttributedString *truncationString = [[attrString attributedSubstringFromRange:NSMakeRange(range.location, range.length)] mutableCopy];
                if (lengths < truncationString.length) {
                    [truncationString deleteCharactersInRange:NSMakeRange(truncationString.length - lengths, lengths)];
                    [truncationString appendAttributedString:tokenString];
                }
                
                [attrString deleteCharactersInRange:NSMakeRange(range.location + range.length - 1, attrString.length - range.location - range.length + 1)];
                NSString *dotStr = @"...";
                
//                [attrString replaceCharactersInRange:NSMakeRange(attrString.length - dotStr.length, 3) withString:dotStr];
                
                NSInteger start = attrString.length - dotStr.length + 1;
                NSInteger length = 2;
                
                if (attrString.length > start + length) {
                    [attrString replaceCharactersInRange:NSMakeRange(start, length) withString:dotStr]; // + 2和替换1个字符，调整...的位置
                }
                NSMutableAttributedString *newStr = [[NSMutableAttributedString alloc] initWithAttributedString:attrString];
                
                _attrString = (__bridge_retained CFMutableAttributedStringRef)newStr;
                CFRelease(truncationTokenLine);
            }
        }
        
        CFRelease(ctFrame);
    }
}

- (NSArray*)colorForHex:(NSString *)hexColor
{
    hexColor = [[hexColor stringByTrimmingCharactersInSet:
                 [NSCharacterSet whitespaceAndNewlineCharacterSet]
                 ] uppercaseString];
    
    NSRange range;
    range.location = 0;
    range.length = 2;
    
    NSString *rString = [hexColor substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [hexColor substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [hexColor substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    NSArray *components = [NSArray arrayWithObjects:[NSNumber numberWithFloat:((float) r / 255.0f)],[NSNumber numberWithFloat:((float) g / 255.0f)],[NSNumber numberWithFloat:((float) b / 255.0f)],[NSNumber numberWithFloat:1.0],nil];
    return components;
}

+ (NSString*)stripURL:(NSString*)url {
    NSString *tempURL = [url stringByReplacingOccurrencesOfRegex:@"^\\\\?[\"\']" withString:@""];
    
    tempURL = [tempURL stringByReplacingOccurrencesOfRegex:@"\\\\?[\"\']$" withString:@""];
    
    return tempURL;

}

+ (NSString *)formulaReplaceString:(NSString *)originStr {
    originStr = [originStr stringByReplacingOccurrencesOfString:@"dfrac" withString:@"frac"];
    originStr = [originStr stringByReplacingOccurrencesOfString:@"tfrac" withString:@"frac"];
    originStr = [originStr stringByReplacingOccurrencesOfString:@"cfrac" withString:@"frac"];
    // 连续两个p解析为换行
    originStr = [originStr stringByReplacingOccurrencesOfString:@"<p></p>" withString:@"\n"];

    originStr = [originStr gtm_stringByUnescapingFromHTML];
    __block NSString *toString = originStr;
    
    [originStr enumerateRegexMatches:@"\\$\\$[^\\$\\$]+\\$\\$" options:0 usingBlock:^(NSString * _Nonnull match, NSRange matchRange, BOOL * _Nonnull stop) {
//        NSLog(@"%@ ---- %@",match,NSStringFromRange(matchRange));
        NSString *latexStr = [match substringWithRange:NSMakeRange(2, match.length - 4)];
//        latexStr = [latexStr stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        NSString *latexStrMd5 = [NSString stringWithFormat:@"%@",latexStr].md5String;
        
        NSString *libraryPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library"];
        latexStrMd5 = [latexStrMd5 stringByAppendingString:@".png"];
        NSString *imgPath = [libraryPath stringByAppendingPathComponent:latexStrMd5];
//        if (![[NSFileManager defaultManager] fileExistsAtPath:imgPath]) {
            MTMathUILabel *label1 = [MTMathUILabel createMathLabel:latexStr withFont:20];
        
        label1.textColor = [UIColor blackColor];
        
        
        CGSize size = [label1 sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
        if (size.width == 0 && size.height == 0) {
            size = CGSizeMake(10, 10); // 默认10
        }
        label1.frame = CGRectMake(0, 0, size.width, size.height + 2);
        
        UIImage *img = [self convertViewToImage:label1];
        NSData *data = UIImagePNGRepresentation(img);
        [data writeToFile:imgPath atomically:YES];
//        }
        int width = [UIImage imageWithContentsOfFile:imgPath].size.width * 2 / [UIScreen mainScreen].scale;
        
        //http://localhost/Library/
        latexStr = [@"http://localhost/Library/" stringByAppendingString:latexStrMd5];
        if (width > 500) {
            width = width / 3.5;
            latexStr = [NSString stringWithFormat:@"<img src=\"%@\" width=\"%d\"/>",latexStr,width];
        } else {
            latexStr = [NSString stringWithFormat:@"<img src=\"%@\" />",latexStr];
        }
        toString = [toString stringByReplacingOccurrencesOfString:match withString:latexStr];
    }];
    
    originStr = toString;
    NSString *regexMatch = @"<table.*?>[\\s\\S]*?<\\/table>";
//    NSString *regexMatch = @"\\<table>[^\\$\\$]+\\</table>";
    
    [originStr enumerateRegexMatches:regexMatch options:0 usingBlock:^(NSString * _Nonnull match, NSRange matchRange, BOOL * _Nonnull stop) {
        
        NSString *tableStr = match;
        NSString *tableStrMd5 = tableStr.md5String;
        UITextView *txtView = [[UITextView alloc] init];
        txtView.font = [UIFont systemFontOfSize:15];
        txtView.editable = NO;
        
            txtView.frame = CGRectMake(0, 0, WINDOW_WIDTH - 30, 1);
        
        
        txtView.textColor = [UIColor darkTextColor];
        txtView.scrollEnabled = YES; // 这个属性必须是yes 否则会导致textview的内容延迟显示
        NSMutableAttributedString *attri;
//        CGFloat tableFont = 14 * ExamScale;
//        NSString *css = [NSString stringWithFormat:@"<style> table { font-size: %fpx;} </style> \n",tableFont];
//        NSString *attrStr = [css stringByAppendingString:match];
        
        attri = [[NSMutableAttributedString alloc] initWithData:[match dataUsingEncoding:NSUnicodeStringEncoding] options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType} documentAttributes:nil error:nil];
        
        [attri addAttribute:NSForegroundColorAttributeName value:[UIColor darkTextColor] range:NSMakeRange(0,attri.string.length)];
        txtView.attributedText = attri;
        CGSize sizeThatShouldFitTheContent = [txtView sizeThatFits:txtView.frame.size];
        
        txtView.frame = CGRectMake(txtView.frame.origin.x, txtView.frame.origin.y, txtView.frame.size.width, sizeThatShouldFitTheContent.height);
        txtView.tag = 111;
        
        [itbViewDict setValue:txtView forKey:tableStrMd5];
        
        tableStr = [NSString stringWithFormat:@"<itb id=\"%@\" />",tableStrMd5];
        
        toString = [toString stringByReplacingOccurrencesOfString:match withString:tableStr];
    }];
    
    // 使用正则表达式替换所有 <br> 变体为换行符
    toString = [toString stringByReplacingOccurrencesOfString:@"<br\\s*/?>"
                                                  withString:@"\n"
                                                     options:NSRegularExpressionSearch
                                                       range:NSMakeRange(0, toString.length)];
    
    // 规范化所有指定标签的换行
    NSArray *tags = @[@"p", @"div", @"h1", @"h2", @"h3"];
    for (NSString *tag in tags) {
        NSString *pattern = [NSString stringWithFormat:@"</%@>\\s*\\n?", tag];
        toString = [toString stringByReplacingOccurrencesOfString:pattern
                                                       withString:[NSString stringWithFormat:@"</%@>\n", tag]
                                                          options:NSRegularExpressionSearch
                                                            range:NSMakeRange(0, toString.length)];
    }
    
    return toString;
}


- (void)dismissBoundRectForTouch
{
    self.currentImgComponent = nil;
    self.currentLinkComponent = nil;
    [self setNeedsDisplay];
}

- (NSString*)visibleText
{
    [self render];
    NSString *text = [self.componentsAndPlainText.plainTextData substringWithRange:NSMakeRange(_visibleRange.location, _visibleRange.length)];
    return text;
}

+ (void)downloadImageWithURL:(NSURL *)url completion:(void (^)(UIImage * _Nullable image, NSError * _Nullable error))completion {
    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        
        if (data) {
            UIImage *image = [UIImage imageWithData:data];
            if (completion) {
                completion(image, nil);
            }
        } else {
            if (completion) {
                completion(nil, [NSError errorWithDomain:@"ImageDownloadError" code:0 userInfo:@{NSLocalizedDescriptionKey: @"No data received"}]);
            }
        }
    }];
    
    [downloadTask resume];
}

+ (UIImage*)convertViewToImage:(UIView*)v {
    v.backgroundColor = [UIColor clearColor];
    CGSize s = v.bounds.size;
    
    CGFloat w = s.width;
    CGFloat h = s.height;
    if (s.width == 0) {
        w = 1; // 解决iOS17 bug
    }
    
    if (s.height == 0) {
        h = 1; // d
    }
    s = CGSizeMake(w, h);
    UIGraphicsBeginImageContextWithOptions(s, NO, [UIScreen mainScreen].scale);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    
    CGAffineTransform flipVertical = CGAffineTransformMake(
                                                           1, 0, 0, -1, 0, s.height
                                                           );
    CGContextConcatCTM(context, flipVertical);
    
    [v.layer renderInContext:context];
    UIImage*image = UIGraphicsGetImageFromCurrentImageContext();
    
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    UIGraphicsEndImageContext();
    
    return image;
}

/**
 *  根据图片url获取网络图片尺寸
 */
+ (CGSize)getImageSizeWithURL:(id)URL{
    NSURL * url = nil;
    if ([URL isKindOfClass:[NSURL class]]) {
        url = URL;
    }
    if ([URL isKindOfClass:[NSString class]]) {
        URL = [(NSString *)URL stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
        url = [NSURL URLWithString:URL];
    }
    if (!URL) {
        return CGSizeZero;
    }
    CGImageSourceRef imageSourceRef = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
    CGFloat width = 0, height = 0;
    if (imageSourceRef) {
        CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSourceRef, 0, NULL);
        //以下是对手机32位、64位的处理（由网友评论区拿到的：小怪兽饲养猿）
        if (imageProperties != NULL) {
            CFNumberRef widthNumberRef = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
#if defined(__LP64__) && __LP64__
            if (widthNumberRef != NULL) {
                CFNumberGetValue(widthNumberRef, kCFNumberFloat64Type, &width);
            }
            CFNumberRef heightNumberRef = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
            if (heightNumberRef != NULL) {
                CFNumberGetValue(heightNumberRef, kCFNumberFloat64Type, &height);
            }
#else
            if (widthNumberRef != NULL) {
                CFNumberGetValue(widthNumberRef, kCFNumberFloat32Type, &width);
            }
            CFNumberRef heightNumberRef = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
            if (heightNumberRef != NULL) {
                CFNumberGetValue(heightNumberRef, kCFNumberFloat32Type, &height);
            }
#endif
            CFRelease(imageProperties);
        }
        
        CFRelease(imageSourceRef);
    }
    return CGSizeMake(width, height);
}


@end
