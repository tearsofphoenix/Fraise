//
//  VIScrollView.m
//  VADevUIKit
//
//  Created by Lei on 14-6-7.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import "VIScrollView.h"

@implementation VIScrollView

- (id)initWithFrame: (NSRect)frameRect
{
    if ((self = [super initWithFrame: frameRect]))
    {
        [self setBorderType:NSNoBorder];
        [self setHasVerticalScroller:YES];
        [self setAutohidesScrollers:YES];
        [self setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [[self contentView] setAutoresizesSubviews:YES];
    }
    
    return self;
}
@end
