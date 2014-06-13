//
//  VAEncoding.m
//  Fraise
//
//  Created by Lei on 14-6-7.
//
//
#import "FRAStandardHeader.h"

#import "VFEncoding.h"
#import "FRAApplicationDelegate.h"
#import "FRATextMenuController.h"
#import "FRAPreferencesController.h"

@interface VFEncoding ()
{
    NSString *_name;
}
@end

@implementation VFEncoding

static NSMutableArray * gsAllDefinitions = nil;

+ (void)initialize
{
    gsAllDefinitions = [[NSMutableArray alloc] init];
}

- (instancetype)init
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

- (void)didChangeValueForKey:(NSString *)key
{
	[super didChangeValueForKey:key];
	
	if ([[FRAApplicationDelegate sharedInstance] hasFinishedLaunching] == NO) {
		return;
	}
	
	NSMutableArray *activeEncodings = [NSMutableArray arrayWithArray:[FRADefaults valueForKey:@"ActiveEncodings"]];
	if ([self active])
    {
		[activeEncodings addObject: @([self encoding])];
	} else
    {
		[activeEncodings removeObject: @([self encoding])];
	}
	[FRADefaults setValue: activeEncodings
                   forKey: @"ActiveEncodings"];
    
	[[FRATextMenuController sharedInstance] buildEncodingsMenus];
	NSUInteger selectedTag = [[[[FRAPreferencesController sharedInstance] encodingsPopUp] selectedItem] tag];
	[[FRAPreferencesController sharedInstance] buildEncodingsMenu];
	[[[FRAPreferencesController sharedInstance] encodingsPopUp] selectItemWithTag:selectedTag];
}

- (NSString *)name
{
    if (!_name)
    {
        _name = [NSString localizedNameOfStringEncoding: _encoding];
    }
    
    return _name;
}

- (void)setEncoding: (NSInteger)encoding
{
    if (_encoding != encoding)
    {
        _encoding = encoding;
        
        //invalidate name;
        //
        _name = nil;
    }
}

@end
