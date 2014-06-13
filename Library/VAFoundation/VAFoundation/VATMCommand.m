//
//  VATMCommand.m
//  VAFoundation
//
//  Created by Lei on 14-6-13.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import "VATMCommand.h"

@implementation VATMCommand

- (instancetype)initWithDictionary: (NSDictionary *)dict
{
    if ((self = [super initWithDictionary: dict]))
    {
        [dict enumerateKeysAndObjectsUsingBlock: (^(id key, id obj, BOOL *stop)
                                                  {
                                                      [self setValue: obj
                                                              forKey: key];
                                                  })];
    }
    
    return self;
}

- (void)setValue: (id)value
 forUndefinedKey: (NSString *)key
{
    //ignore
}

@end

NSString * const VATMNopCommandName = @"nop";