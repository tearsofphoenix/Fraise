//
//  VATMObject.m
//  VAFoundation
//
//  Created by Lei on 14-6-13.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import "VATMObject.h"

@implementation VATMObject

@synthesize uuid = _uuid;
@synthesize version = _version;

- (id)initWithDictionary: (NSDictionary *)dict
{
    if ((self = [super init]))
    {
        _uuid = dict[@"uuid"];
        _version = [dict[@"version"] integerValue];
    }
    
    return self;
}

- (NSDictionary *)dictionaryRepresent
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject: _uuid
             forKey: @"uuid"];
    [dict setObject: @(_version)
             forKey: @"version"];
    
    return dict;
}

@end
