//
//  VACommand.m
//  Fraise
//
//  Created by Lei on 14-6-7.
//
//

#import "VACommand.h"
#import "FRAApplicationDelegate.h"
#import "FRAToolsMenuController.h"
#import <VAFoundation/VAFoundation.h>

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

- (instancetype)init
{
    if ((self = [super init]))
    {
        _uuid = [NSString UUIDString];
    }
    return self;
}

- (void)didChangeValueForKey:(NSString *)key
{
    [super didChangeValueForKey:key];
    
    if ([[FRAApplicationDelegate sharedInstance] hasFinishedLaunching] == NO)
    {
        return;
    }
    
    if (![key isEqualToString: @"uuid"])
    {
        [[FRAToolsMenuController sharedInstance] buildRunCommandMenu];
    }
}


- (NSComparisonResult)localizedCaseInsensitiveCompare:(id)object
{
    NSComparisonResult result = NSOrderedSame;
    
    if ([object isKindOfClass:[self class]])
    {
        result = [[object name] localizedCaseInsensitiveCompare: [self name]];
    }
    
    return result;
}

@end
