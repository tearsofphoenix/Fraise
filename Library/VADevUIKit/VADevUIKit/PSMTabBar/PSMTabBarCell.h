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
- (id)initWithControlView:(PSMTabBarControl *)controlView;
- (id)initPlaceholderWithFrame:(NSRect)frame expanded:(BOOL)value inControlView:(PSMTabBarControl *)controlView;

// accessors
- (id)controlView;
- (void)setControlView:(id)view;

@property  NSTrackingRectTag closeButtonTrackingTag; // left side tracking, if dragging
@property  NSTrackingRectTag cellTrackingTag; // right side tracking, if dragging

- (CGFloat)width;

@property NSRect frame;

- (void)setStringValue:(NSString *)aString;
- (NSSize)stringSize;
- (NSAttributedString *)attributedStringValue;

@property NSInteger tabState;

- (NSProgressIndicator *)indicator;

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
- (CGFloat)minimumWidthOfCell;
- (CGFloat)desiredWidthOfCell;

// drawing
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;

// tracking the mouse
- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;

// drag support
- (NSImage*)dragImageForRect:(NSRect)cellFrame;

// archiving
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

@end
