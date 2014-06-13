//
//  VATMSnippet.m
//  VAFoundation
//
//  Created by Mac003 on 14-6-13.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import "VATMSnippet.h"

@implementation VATMSnippet

- (id)initWithDictionary: (NSDictionary *)dict
{
    if ((self = [super initWithDictionary: dict]))
    {
        [self setTabTrigger: dict[@"tabTrigger"]];
    }
    
    return self;
}

@end
