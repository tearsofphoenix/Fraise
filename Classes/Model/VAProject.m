//
//  VAProject.m
//  Fraise
//
//  Created by Lei on 14-6-8.
//
//

#import "VAProject.h"

@implementation VAProject

- (id)init
{
    if ((self = [super init]))
    {
        _documents = [[NSMutableSet alloc] init];
    }
    
    return self;
}

@end
