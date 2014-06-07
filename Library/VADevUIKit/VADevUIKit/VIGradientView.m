//
//  VAGradientView.m
//  VADevUIKit
//
//  Created by Lei on 14-6-6.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import "VIGradientView.h"

static 	NSGradient *gradient = nil;
static CGFloat scaleFactor = 1;

@implementation VIGradientView

+ (void)initialize
{
    scaleFactor = [[NSScreen mainScreen] userSpaceScaleFactor];
    gradient = [[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceRed:0.812 green:0.812 blue:0.812 alpha:1.0]
                                             endingColor: [NSColor colorWithDeviceRed:0.914 green:0.914 blue:0.914 alpha:1.0]];
}
 
- (void)drawRect:(NSRect)rect
{
	NSRect gradientRect = [self bounds];
	
	NSDrawGroove(gradientRect, gradientRect);
    
	[gradient drawInRect: NSMakeRect(gradientRect.origin.x * scaleFactor,
                                     gradientRect.origin.y * scaleFactor,
                                     gradientRect.size.width * scaleFactor,
                                     gradientRect.size.height - 1.0 * scaleFactor)
                   angle: 90];
}

- (BOOL)isOpaque
{
	return YES;
}

@end
