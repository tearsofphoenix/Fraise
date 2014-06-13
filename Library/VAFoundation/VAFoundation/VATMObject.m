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
@synthesize name = _name;
@synthesize scope = _scope;

- (instancetype)initWithDictionary: (NSDictionary *)dict
{
    if ((self = [super init]))
    {
        _uuid = dict[@"uuid"];
        _name = dict[@"name"];
        _scope = dict[@"scope"];
        _version = [dict[@"version"] integerValue];
    }
    
    return self;
}

- (NSDictionary *)dictionaryRepresent
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"uuid"] = _uuid;
    dict[@"name"] = _name;
    dict[@"scope"] = _scope;
    dict[@"version"] = @(_version);
    
    return dict;
}

@end


NSString * const VATMNameKey = @"name";

NSString * const VATMUUIDKey = @"uuid";
