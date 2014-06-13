//
//  VATMSyntax.m
//  VAFoundation
//
//  Created by Mac003 on 14-6-13.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import "VATMSyntax.h"

@implementation VATMSyntax

- (id)initWithDictionary: (NSDictionary *)dict
{
    if ((self = [super initWithDictionary: dict]))
    {
        [self setComment: dict[@"comment"]];
        [self setFileTypes: dict[@"fileTypes"]];
        [self setFirstLineMatch: dict[@"firstLineMatch"]];
        [self setKeyEquivalent: dict[@"keyEquivalent"]];
        [self setPatterns: dict[@"patterns"]];
    }
    
    return self;
}

- (NSString *)scopeName
{
    return [self scope];
}

- (void)setScopeName: (NSString *)scopeName
{
    [self setScope: scopeName];
}

@end
