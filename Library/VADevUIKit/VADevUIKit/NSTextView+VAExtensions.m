//
//  NSTextView+VAExtensions.m
//  VADevUIKit
//
//  Created by Lei on 14-6-7.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import "NSTextView+VAExtensions.h"

@implementation NSTextView (VAExtensions)

- (NSInteger)lineHeight
{
    return [[[self textContainer] layoutManager] defaultLineHeightForFont: [self font]];
}

@end
