//
//  SALabel.m
//  SALabelProject
//
/**
 * Copyright (c) 2012 Sarfuter Zhang
 * Created by hangchen on 24/7/12.
 * @author         Sarfuter Zhang <sarfuter@gmail.com>
 * @copyright    2024    Sarfuter Zhang
 * @version
 *
 */

#import "NSString+Util.h"

#define KSALabelImageVar @"`"
#define KSALabelTableVar @"の"


extern NSString * const kSABackgroundFillColorAttributeName;


extern NSString * const kSABackgroundStrokeColorAttributeName;

extern NSString * const kSABackgroundLineWidthAttributeName;


extern NSString * const kSABackgroundLineCornerRadiusAttributeName;

extern NSString * const kSAActiveBackgroundFillColorAttributeName;


extern NSString * const kSAActiveBackgroundStrokeColorAttributeName;


extern NSString * const kSAStrikethroughStyleAttributeName;

extern NSString * const kSAStrikethroughColorAttributeName;

extern NSString * const kSALinkStringIdentifierAttributesName;


#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
typedef enum
{
    RTTextAlignmentRight = kCTTextAlignmentRight,
    RTTextAlignmentLeft = kCTTextAlignmentLeft,
    RTTextAlignmentCenter = kCTTextAlignmentCenter,
    RTTextAlignmentJustify = kCTTextAlignmentJustified
} RTTextAlignment;

typedef enum
{
    RTTextLineBreakModeWordWrapping = kCTLineBreakByWordWrapping,
    RTTextLineBreakModeCharWrapping = kCTLineBreakByCharWrapping,
    RTTextLineBreakModeClip = kCTLineBreakByClipping,
}RTTextLineBreakMode;


@class RTLabelComponentsStructure;

@class SALabel;
@class RTLabelComponent;
NS_ASSUME_NONNULL_BEGIN
typedef void(^RTLableImageBlock)(SALabel *label, NSString *data);

@protocol RTLableImageDelegate <NSObject>

@optional
-(void)SJRTLabelImageSuccess:(SALabel *)label textString:(NSString *)data;

@end

@protocol RTLabelDelegate <NSObject>

@optional

- (void)rtLabel:(id)rtLabel didSelectLinkWithURL:(NSString*)url clickPoint:(CGPoint)point;

@end

@protocol RTLabelSizeDelegate <NSObject>

@optional
- (void)rtLabel:(id)rtLabel didChangedSize:(CGSize)size;

@end



@interface SALabel : UIView  {
    //NSString *_text;
    UIColor *_textColor;
   
    RTTextAlignment _textAlignment;
    RTTextLineBreakMode _lineBreakMode;
    
    CGSize _optimumSize;
    
//    __weak id<RTLabelDelegate> _delegate;
//    __weak id<RTLabelSizeDelegate> _sizeDelegate;
    CTFramesetterRef _framesetter;
    CTFrameRef _ctFrame;
    CFRange _visibleRange;
    NSString *_paragraphReplacement;
    CTFontRef _thisFont;
    CFMutableAttributedStringRef _attrString;
    RTLabelComponent * _currentLinkComponent;
    RTLabelComponent * _currentImgComponent;
    RTLabelComponentsStructure *componentsAndPlainText_;
}

@property (nonatomic, strong) UIFont *font;


@property (nonatomic, weak) id<RTLabelDelegate> delegate;
@property (nonatomic, weak) id<RTLabelSizeDelegate> sizeDelegate;

@property (nonatomic, copy) RTLableImageBlock imageBlock;

@property (nonatomic, weak) id<RTLableImageDelegate> imageDelegate;

@property (nonatomic, copy) NSString *paragraphReplacement;
@property (nonatomic,retain, nullable)RTLabelComponent * currentLinkComponent;
@property (nonatomic,retain, nullable)RTLabelComponent * currentImgComponent;

/**
 * 最大行数
 * 需要先给SALabel准确设置好宽度，否则计算会有偏差(!)
 */
@property (nonatomic, assign)  NSInteger maxNumLine;

/**
 *  是否显示默认自带的颜色样式
 */
@property (nonatomic, assign) BOOL showSourceColor;



/**
 设置`self.lineBreakMode`时候的自定义字符，默认值为"…"
 只针对`self.lineBreakMode`的以下三种值有效
 NSLineBreakByTruncatingHead,    // Truncate at head of line: "…wxyz"
 NSLineBreakByTruncatingTail,    // Truncate at tail of line: "abcd…"
 NSLineBreakByTruncatingMiddle   // Truncate middle of line:  "ab…yz"
 */
@property (readwrite, nonatomic, strong) NSAttributedString *attributedTruncationToken;

//当前显示的AttributedText
@property (nonatomic, copy) NSAttributedString *renderedAttributedText;

/**
 * 绘制文本的内边距，默认UIEdgeInsetsZero
 */
@property (readwrite, nonatomic, assign) UIEdgeInsets textInsets;

@property (nonatomic, copy) void(^caculateCTRunSizeBlock)(void);
@property (readwrite, nonatomic, copy) NSAttributedString *attributedText;

+ (RTLabelComponentsStructure*)extractTextStyle:(NSString*)data IsLocation:(BOOL)location withSALabel:(SALabel *)SALabel whetherOrNotNewline:(BOOL)newLine;

+ (RTLabelComponentsStructure*)extractTextStyle:(NSString*)data;
+ (NSString*)stripURL:(NSString*)url;
- (instancetype)initWithFrame:(CGRect)frame;
- (void)setTextAlignment:(RTTextAlignment)textAlignment;
- (RTTextAlignment)textAlignment;

- (void)setLineBreakMode:(RTTextLineBreakMode)lineBreakMode;
- (RTTextLineBreakMode)lineBreakMode;

- (void)setTextColor:(UIColor*)textColor;
- (UIColor*)textColor;

- (void)setFont:(UIFont*)font;
- (UIFont*)font;

- (void)setComponentsAndPlainText:(RTLabelComponentsStructure*)componnetsDS;
- (RTLabelComponentsStructure*)componentsAndPlainText;

- (CGSize)optimumSize;
- (NSString*)visibleText;


+ (NSString *)formulaReplaceString:(NSString *)originStr;
@end

@interface RTLabelComponent : NSObject
{
    NSString *_text;
    NSString *_tagLabel;
    NSMutableDictionary *_attributes;
    int _position;
    int _componentIndex;
    BOOL _isClosure;
    UIImage *img_;
}

@property (nonatomic, assign) int componentIndex;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *tagLabel;
@property (nonatomic, retain) NSMutableDictionary *attributes;
@property (nonatomic, assign) int position;
@property (nonatomic, assign) BOOL isClosure;
@property (nonatomic, retain) UIImage *img;

@property (nonatomic, strong) UIView *attachView;


- (id)initWithString:(NSString*)aText tag:(NSString*)aTagLabel attributes:(NSMutableDictionary*)theAttributes;
+ (id)componentWithString:(nullable NSString*)aText tag:(nullable NSString*)aTagLabel attributes:(nullable NSMutableDictionary*)theAttributes;
- (id)initWithTag:(NSString*)aTagLabel position:(int)_position attributes:(NSMutableDictionary*)_attributes;
+ (id)componentWithTag:(NSString*)aTagLabel position:(int)aPosition attributes:(NSMutableDictionary*)theAttributes;

@end


@interface RTLabelComponentsStructure :NSObject {
    NSArray *components_;
    NSString *plainTextData_;
    NSArray *linkComponents_;
    NSArray *imgComponents_;
}
@property(nonatomic,retain) NSArray *components;
@property(nonatomic,retain) NSArray *linkComponents;
@property(nonatomic,retain) NSArray *imgComponents;
@property(nonatomic, copy) NSString *plainTextData;

@property(nonatomic, retain) NSArray *tbComponents;
@end

NS_ASSUME_NONNULL_END
