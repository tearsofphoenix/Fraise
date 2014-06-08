//
//  VACommand.m
//  Fraise
//
//  Created by Lei on 14-6-7.
//
//

#import "VASnippet.h"

@interface VASnippet ()

@end

@implementation VASnippet

static NSMutableArray *gsAll;

+ (void)initialize
{
    gsAll = [[NSMutableArray alloc] init];
}

+ (NSArray *)all
{
    return gsAll;
}

@end
