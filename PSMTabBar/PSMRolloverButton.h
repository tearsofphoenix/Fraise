//
//  PSMOverflowPopUpButton.h
//  NetScrape
//
//  Created by John Pannell on 8/4/04.
//  Copyright 2004 Positive Spin Media. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PSMRolloverButton : NSButton
{
    NSTrackingRectTag   _myTrackingRectTag;
}

// the regular image
@property (nonatomic, strong) NSImage *usualImage;

// the rollover image
@property (strong) NSImage *rolloverImage;

// tracking rect for mouse events
- (void)addTrackingRect;
- (void)removeTrackingRect;
@end