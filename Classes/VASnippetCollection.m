//
//  VACommandCollection.m
//  Fraise
//
//  Created by Lei on 14-6-7.
//
//

#import "FRAStandardHeader.h"
#import "VASnippetCollection.h"

#import "FRAApplicationDelegate.h"
#import "FRAToolsMenuController.h"
#import "FRABasicPerformer.h"

#import <VAFoundation/VAFoundation.h>

@implementation VASnippetCollection

static NSMutableArray * gsAllDefinitions = nil;

+ (void)initialize
{
    gsAllDefinitions = [[NSMutableArray alloc] init];
}

- (id)init
{
    if ((self = [super init]))
    {
        _uuid = [NSString UUIDString];
        
        [gsAllDefinitions addObject: self];
    }
    
    return self;
}

+ (NSArray *)allSnippetCollections
{
    return gsAllDefinitions;
}

- (void)didChangeValueForKey:(NSString *)key
{
	[super didChangeValueForKey:key];
	
	if ([[FRAApplicationDelegate sharedInstance] hasFinishedLaunching] == NO) {
		return;
	}
	
	if (![key isEqualToString:@"uuid"])
    {
		[[FRAToolsMenuController sharedInstance] buildInsertSnippetMenu];
	}
}

@end
