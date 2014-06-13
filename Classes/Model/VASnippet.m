//
//  VACommand.m
//  Fraise
//
//  Created by Lei on 14-6-7.
//
//
#import "FRAStandardHeader.h"

#import "VASnippet.h"

#import "FRAApplicationDelegate.h"
#import "FRAToolsMenuController.h"
#import "FRABasicPerformer.h"

#import <VAFoundation/VAFoundation.h>

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
		[[FRAToolsMenuController sharedInstance] buildInsertSnippetMenu];
	}
	
}


- (NSComparisonResult)localizedCaseInsensitiveCompare:(id)object
{
	NSComparisonResult result = NSOrderedSame;
	
	if ([object isKindOfClass:[self class]])
    {
		result = [[object name] localizedCaseInsensitiveCompare: _name];
	}
	
	return result;
}


@end
