//
//  VAEncoding.m
//  Fraise
//
//  Created by Lei on 14-6-7.
//
//

#import "VAEncoding.h"

@implementation VAEncoding

static NSMutableArray * gsAllDefinitions = nil;

+ (void)initialize
{
    gsAllDefinitions = [[NSMutableArray alloc] init];
}

- (id)init
{
    if ((self = [super init]))
    {
        [gsAllDefinitions addObject: self];
    }
    
    return self;
}

+ (NSArray *)allEncodings
{
    return gsAllDefinitions;
}

@end
