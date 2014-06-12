//
//  VACommand.m
//  Fraise
//
//  Created by Lei on 14-6-7.
//
//

#import "VACommand.h"

@implementation VACommand


static NSMutableArray *gsAll;

+ (void)initialize
{
    gsAll = [[NSMutableArray alloc] init];
}

+ (NSArray *)allCommands
{
    return gsAll;
}

@end
