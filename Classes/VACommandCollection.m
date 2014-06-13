//
//  VACommandCollection.m
//  Fraise
//
//  Created by Lei on 14-6-7.
//
//

#import "VACommandCollection.h"
#import "FRAApplicationDelegate.h"
#import "FRAToolsMenuController.h"

#import <VAFoundation/VAFoundation.h>

@implementation VACommandCollection


static NSMutableArray * gsAllDefinitions = nil;

+ (void)initialize
{
    gsAllDefinitions = [[NSMutableArray alloc] init];
}

- (instancetype)init
{
    if ((self = [super init]))
    {
        _uuid = [NSString UUIDString];
        _commands = [[NSMutableArray alloc] init];
        
        [gsAllDefinitions addObject: self];
    }
    
    return self;
}


+ (NSArray *)allCommandCollections
{
    return gsAllDefinitions;
}

- (void)didChangeValueForKey:(NSString *)key
{
    [super didChangeValueForKey:key];
    
    if ([[FRAApplicationDelegate sharedInstance] hasFinishedLaunching] == NO)
    {
        return;
    }
    
    if (![key isEqualToString:@"uuid"])
    {
        [[FRAToolsMenuController sharedInstance] buildRunCommandMenu];
    }
}

+ (void)removeCollection: (id)collection
{
    [gsAllDefinitions removeObject: collection];
}

@end
