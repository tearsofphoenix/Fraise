//
//  VASyntaxDefinition.m
//  Fraise
//
//  Created by Lei on 14-6-8.
//
//

#import "VASyntaxDefinition.h"

@implementation VASyntaxDefinition

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

+ (NSArray *)allDefinitions
{
    return gsAllDefinitions;
}

@end
