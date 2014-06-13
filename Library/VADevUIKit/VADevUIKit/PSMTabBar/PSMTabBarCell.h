//
//  PSMTabBarCell.h
//  PSMTabBarControl
//
//  Created by John Pannell on 10/13/05.
//  Copyright 2005 Positive Spin Media. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PSMTabBarControl;


@interface PSMTabBarCell : NSActionCell
{
    // sizing
    NSSize              _stringSize;

    NSProgressIndicator *_indicator;
}

// creation/destruction
- (instancetype)initWithControlView:(PSMTabBarControl *)controlView ;
- (instancetype)initPlaceholderWithFrame:(NSRect)frame expanded:(BOOL)value inControlView:(PSMTabBarControl *)controlView ;

// accessors
@property (NS_NONATOMIC_IOSONLY, strong) id controlView;

@property  NSTrackingRectTag closeButtonTrackingTag; // left side tracking, if dragging
@property  NSTrackingRectTag cellTrackingTag; // right side tracking, if dragging

@property (NS_NONATOMIC_IOSONLY, readonly) CGFloat width;

@property NSRect frame;

- (void)setStringValue:(NSString *)aString;
@property (NS_NONATOMIC_IOSONLY, readonly) NSSize stringSize;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSAttributedString *attributedStringValue;

@property NSInteger tabState;

@property (NS_NONATOMIC_IOSONLY, readonly, strong) NSProgressIndicator *indicator;

@property BOOL isInOverflowMenu;
@property BOOL closeButtonPressed;
@property BOOL closeButtonOver;
@property BOOL hasCloseButton;
@property (getter = isCloseButtonSuppressed) BOOL closeButtonSuppressed;

@property (nonatomic) BOOL hasIcon;
@property (nonatomic) NSInteger count;
@property BOOL isPlaceholder;
@property (nonatomic) NSInteger currentStep;

// component attributes
- (NSRect)indicatorRectForFrame:(NSRect)cellFrame;
- (NSRect)closeButtonRectForFrame:(NSRect)cellFrame;
@property (NS_NONATOMIC_IOSONLY, readonly) CGFloat minimumWidthOfCell;
@property (NS_NONATOMIC_IOSONLY, readonly) CGFloat desiredWidthOfCell;

// drawing
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;

// tracking the mouse
- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;

// drag support
- (NSImage*)dragImageForRect:(NSRect)cellFrame;

// archiving
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (instancetype)initWithCoder:(NSCoder *)aDecoder ;

@end
