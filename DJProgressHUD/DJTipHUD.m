//
//  CPProgressView.m
//  Cloud Play OSX
//
//  Created by Daniel Jackson on 4/22/14.
//  Copyright (c) 2014 Daniel Jackson. All rights reserved.
//

#import "DJTipHUD.h"

typedef void (^CompletionHander)(void);

@interface DJTipHUD ()
{
    NSView* parentView;
    
    CGSize pSize; //This is set automatically based on the content
    NSTextField* label;
}

@end

@implementation DJTipHUD

#pragma mark -
#pragma mark Class Methods

+ (void)showStatus:(NSString*)status FromView:(NSView*)view
{
    [[self instance] showStatus:status FromView:view];
}

#pragma mark -
#pragma mark Master Methods

- (void)showStatus:(NSString*)status FromView:(NSView*)view
{
    parentView = view;
    
    label.stringValue = status;
    
    if(![self displaying])
        [self showViewAnimated];
    else
        [self replaceViewQuick];
    
    [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(hideViewAnimated) userInfo:nil repeats:NO];
}

#pragma mark -
#pragma mark Instance Methods

-(void)replaceViewQuick
{
    [self beginShowView];
    [self.layer setOpacity:_pAlpha];
}

- (void)beginShowView
{
    [self updateLayout];
    NSRect size = [self getCenterWithinRect:parentView.frame scale:1.0];
    
    if(!self.superview) [parentView addSubview:self];
    [self.layer setFrame:size];
    
    _displaying = true;
    
    [label.layer setOpacity:1.0];
}

-(void)finishHideView
{
    [self removeFromSuperview];
    parentView = nil;
    _displaying = false;
    
}

- (void)showViewAnimated
{
    if(![parentView wantsLayer])
    {
        [parentView setWantsLayer:TRUE];
        [parentView setLayer:[CALayer layer]];
    }
    
    [self beginShowView];
    
    self.layer.opacity = 0.0;
    [self.layer setFrame:[self getCenterWithinRect:parentView.frame scale:0.25]];
    
    
    [CATransaction flush];
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithFloat:0.5f]
                     forKey:kCATransactionAnimationDuration];
    [CATransaction setCompletionBlock:^{
        
    }];

    [self.layer setFrame:[self getCenterWithinRect:parentView.frame scale:1]];
    [self.layer setOpacity:_pAlpha];
    [CATransaction commit];

    [self setNeedsDisplay:TRUE];
}

- (void)hideViewAnimated
{
    if(![parentView wantsLayer])
    {
        [parentView setWantsLayer:TRUE];
        [parentView setLayer:[CALayer layer]];
    }
    
    NSRect newSize = [self getCenterWithinRect:parentView.frame scale:0.25];
    
    [CATransaction flush];
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithFloat:0.5f] forKey:kCATransactionAnimationDuration];
    [CATransaction setCompletionBlock:^{
        if(self.layer.opacity == 0.0)
        {
            [self finishHideView];
        }
    }];
    [label.layer setOpacity:0.0];
    [self.layer setFrame:newSize];
    [self.layer setOpacity:0.0];
    [CATransaction commit];

    [self setNeedsDisplay:TRUE];
}

#pragma mark -
#pragma mark Laying It Out

- (void)updateLayout
{
    [self setBackground];
    
    CGSize maxContentSize = CGSizeMake(pMaxWidth1-(_pPadding*2), pMaxHeight1-(_pPadding*2));
    CGSize minContentSize = CGSizeMake(_indicatorSize.width, _indicatorSize.height);
    
    CGFloat stringWidth = [label.stringValue sizeWithAttributes:@{ NSFontAttributeName : label.font }].width + 5;
    float stringHeight = [self heightForString:label.stringValue font:label.font width:maxContentSize.width] + 8;
    
    if(label.stringValue == nil || label.stringValue.length == 0)
        stringHeight = 0;
    
    stringWidth = (stringWidth > minContentSize.width) ? stringWidth : minContentSize.width;
    if(stringWidth > maxContentSize.width)
        stringWidth = maxContentSize.width;
    
    CGFloat maxStringHeight = maxContentSize.height-_indicatorSize.height-(_pPadding+(_pPadding/2));
    stringHeight = (stringHeight > maxStringHeight) ? maxStringHeight : stringHeight;
    
    CGFloat popupWidth = stringWidth+(_pPadding*2);
    
    CGFloat lW = stringWidth;
    CGFloat lH = stringHeight;
    CGFloat lX = _pPadding;
    CGFloat lY = (stringHeight == 0) ? 0 : _pPadding;
    [label setFrame:NSMakeRect(lX, lY, lW, lH)];
    
    CGFloat spaceBetween = (stringHeight != 0) ? _pPadding/3 : _pPadding;
    
    CGFloat iW = _indicatorSize.width;
    CGFloat iH = _indicatorSize.height;
    CGFloat iX = ((lW+(_pPadding*2))/2)-(iW/2); //center it
    CGFloat iY = lY+lH+(spaceBetween);
    
    CGFloat spaceOnTop = (stringHeight != 0) ? _pPadding/3 : 0;

    pSize.width = popupWidth;
    pSize.height = iY+iH+_pPadding+spaceOnTop;//+(_pPadding/2);
    
    [self setAutoresizesSubviews:YES];
    
    [self setNeedsDisplay:TRUE];
}

- (void)setBackground
{
    CGColorRef bgcolor = CGColorCreateGenericRGB(0.05, 0.05, 0.05, _pAlpha);
    
    if(![self layer]) {
        CALayer* bgLayer = [CALayer layer];
        [self setLayer:bgLayer];
        [self.layer setCornerRadius:15.0];
        [self setWantsLayer:TRUE];
    }

    [self.layer setBackgroundColor:bgcolor];

    [self setNeedsDisplay:TRUE];
}

#pragma mark -
#pragma mark Other

-(CGFloat) heightForString:(NSString *)myString font:(NSFont*) myFont width:(CGFloat)myWidth
{
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithString:myString];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(myWidth, FLT_MAX)];
    ;
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    [textStorage addAttribute:NSFontAttributeName value:myFont
                        range:NSMakeRange(0, [textStorage length])];
    [textContainer setLineFragmentPadding:0.0];
    
    (void) [layoutManager glyphRangeForTextContainer:textContainer];
    return [layoutManager
            usedRectForTextContainer:textContainer].size.height;
}

- (NSRect)getCenterWithinRect:(NSRect)parentFrame scale:(CGFloat)scale
{
    NSRect result;
    CGFloat newWidth = pSize.width*scale;
    CGFloat newHeight = pSize.height*scale;
    result.origin.x = parentFrame.size.width/2 - newWidth/2 + _pOffset.dx;
    result.origin.y = parentFrame.size.height/2 - newHeight/2 + _pOffset.dy;
    result.size.width = newWidth;
    result.size.height = newHeight;
    
    return result;
}

#pragma mark -

- (void)initializePopup
{
    self.autoresizingMask = NSViewMaxXMargin | NSViewMaxYMargin | NSViewMinXMargin | NSViewMinYMargin;
    
    label = [[NSTextField alloc] init];
    

    [self addSubview:label];
    
    //----DEFAULT VALUES----
    
    _pOffset = CGVectorMake(0, 0);
    _pAlpha = 0.9;
    _pPadding = 10;
    
    _indicatorSize = CGSizeMake(0, 0);
    _indicatorOffset = CGVectorMake(0, 0);
    
    [label setBezeled:NO];
    [label setDrawsBackground:NO];
    [label setEditable:NO];
    [label setSelectable:NO];
    
    label.font = [NSFont boldSystemFontOfSize:12.0];
    [label setTextColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.85]];
}

+ (DJTipHUD *) instance
{
    static dispatch_once_t once;
    static DJTipHUD *sharedView;
    dispatch_once(&once, ^ {
        sharedView = [[self alloc] init];
        [sharedView initializePopup];
    });
    
    return sharedView;
}

@end