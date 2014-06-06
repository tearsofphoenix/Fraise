//
//  PSMTabBarControl.h
//  PSMTabBarControl
//
//  Created by John Pannell on 10/13/05.
//  Copyright 2005 Positive Spin Media. All rights reserved.
//

/*
 This view provides a control interface to manage a regular NSTabView.  It looks and works like the tabbed browsing interface of many popular browsers.
 */

#import <Cocoa/Cocoa.h>

#define kPSMTabBarControlHeight 22
// internal cell border
#define MARGIN_X        6
#define MARGIN_Y        3
// padding between objects
#define kPSMTabBarCellPadding 4
// fixed size objects
#define kPSMMinimumTitleWidth 30
#define kPSMTabBarIndicatorWidth 16.0
#define kPSMTabBarIconWidth 16.0
#define kPSMHideAnimationSteps 2.0

@class PSMOverflowPopUpButton;
@class PSMRolloverButton;
@class PSMTabBarCell;
@protocol PSMTabStyle;

enum
{
    PSMTab_SelectedMask                 = 1 << 1,
    PSMTab_LeftIsSelectedMask		= 1 << 2,
    PSMTab_RightIsSelectedMask          = 1 << 3,
    PSMTab_PositionLeftMask		= 1 << 4,
    PSMTab_PositionMiddleMask		= 1 << 5,
    PSMTab_PositionRightMask		= 1 << 6,
    PSMTab_PositionSingleMask		= 1 << 7
};

@class PSMTabBarControl;
@class PSMTabBarCell;

@protocol PSMTabBarControlDelegate <NSObject>

- (void)tabBarControl: (PSMTabBarControl *)control
concludeDragOperation: (id<NSDraggingInfo>)sender;

- (void)tabBarControl: (PSMTabBarControl *)control
performDragWithTarget: (PSMTabBarControl *)target
           dragedCell: (PSMTabBarCell *)cell;

@end

@interface PSMTabBarControl : NSControl
{
    // control basics
    NSMutableArray              *_cells;                    // the cells that draw the tabs
    PSMOverflowPopUpButton      *_overflowPopUpButton;      // for too many tabs
    PSMRolloverButton           *_addTabButton;
    
    // drawing style
    id<PSMTabStyle>             style;
    
    
    // animation for hide/show
    NSInteger                         _currentStep;
    BOOL                        _isHidden;
    BOOL                        _hideIndicators;
    BOOL                        _awakenedFromNib;    
}

// control characteristics
+ (NSBundle *)bundle;

// control configuration
@property (nonatomic) BOOL canCloseOnlyTab;

@property (nonatomic, getter = styleName, strong) NSString * styleNamed;

@property (nonatomic) BOOL hideForSingleTab;

@property (nonatomic) BOOL showAddTabButton;

@property (nonatomic) NSInteger cellMinWidth;

@property (nonatomic) NSInteger cellMaxWidth;

@property (nonatomic) NSInteger cellOptimumWidth;

@property (nonatomic) BOOL sizeCellsToFit;
@property (nonatomic) BOOL allowsDragBetweenWindows;

// the tab view being navigated
@property (assign) IBOutlet NSTabView *tabView;

@property (assign) IBOutlet id delegate;

// gets resized when hide/show
@property (assign) IBOutlet id partnerView;

// the buttons
- (PSMRolloverButton *)addTabButton;
- (PSMOverflowPopUpButton *)overflowPopUpButton;
- (NSMutableArray *)representedTabViewItems;

// special effects
- (void)hideTabBar:(BOOL)hide animate:(BOOL)animate;

@end

@interface PSMTabBarControl (StyleAccessors)

- (NSMutableArray *)cells;

@end

@interface PSMTabBarControl (CellAccessors)

- (id<PSMTabStyle>)style;

@end


@interface NSObject (TabBarControlDelegateMethods)
- (BOOL)tabView:(NSTabView *)aTabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem;
- (void)tabView:(NSTabView *)aTabView willCloseTabViewItem:(NSTabViewItem *)tabViewItem;
- (void)tabView:(NSTabView *)aTabView didCloseTabViewItem:(NSTabViewItem *)tabViewItem;
@end