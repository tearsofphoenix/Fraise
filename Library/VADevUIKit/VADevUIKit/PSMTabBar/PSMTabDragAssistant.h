//
//  PSMTabDragAssistant.h
//  PSMTabBarControl
//
//  Created by John Pannell on 4/10/06.
//  Copyright 2006 Positive Spin Media. All rights reserved.
//

/*
 This class is a sigleton that manages the details of a tab drag and drop.  The details were beginning to overwhelm me when keeping all of this in the control and cells :-)
 */

#import <Cocoa/Cocoa.h>
#import "PSMTabBarControl.h"
@class PSMTabBarCell;
@class PSMTabDragWindow;

#define kPSMTabDragAnimationSteps 8

@interface PSMTabDragAssistant : NSObject
{
    NSMutableSet                *_participatingTabBars;
    
    // Animation
    NSTimer                     *_animationTimer;
    NSMutableArray              *_sineCurveWidths;
}

// Creation/destruction
+ (PSMTabDragAssistant *)sharedDragAssistant;

// Accessors

@property (strong) PSMTabBarControl *sourceTabBar;
@property (strong) PSMTabBarControl *destinationTabBar;
@property (strong) PSMTabBarCell *draggedCell;
@property NSInteger draggedCellIndex; // for snap back
@property BOOL isDragging;
@property NSPoint currentMouseLoc;
@property (strong) PSMTabBarCell *targetCell;

// Functionality
- (void)startDraggingCell:(PSMTabBarCell *)cell fromTabBar:(PSMTabBarControl *)control withMouseDownEvent:(NSEvent *)event;
- (void)draggingEnteredTabBar:(PSMTabBarControl *)control atPoint:(NSPoint)mouseLoc;
- (void)draggingUpdatedInTabBar:(PSMTabBarControl *)control atPoint:(NSPoint)mouseLoc;
- (void)draggingExitedTabBar:(PSMTabBarControl *)control;
- (void)performDragOperation;
- (void)draggedImageEndedAt:(NSPoint)aPoint operation:(NSDragOperation)operation;
- (void)finishDrag;

// Animation
- (void)animateDrag:(NSTimer *)timer;
- (void)calculateDragAnimationForTabBar:(PSMTabBarControl *)control;

// Placeholder
- (void)distributePlaceholdersInTabBar:(PSMTabBarControl *)control withDraggedCell:(PSMTabBarCell *)cell;
- (void)distributePlaceholdersInTabBar:(PSMTabBarControl *)control;
- (void)removeAllPlaceholdersFromTabBar:(PSMTabBarControl *)control;

@end

@interface PSMTabBarControl (DragAccessors)

- (id<PSMTabStyle>)style;
- (NSMutableArray *)cells;
- (void)setControlView:(id)view;
- (id)cellForPoint:(NSPoint)point cellFrame:(NSRectPointer)outFrame;
- (PSMTabBarCell *)lastVisibleTab;
- (NSInteger)numberOfVisibleTabs;

@end