//
//  VASyntaxDefinition.m
//  Fraise
//
//  Created by Lei on 14-6-8.
//
//
#import "FRAStandardHeader.h"
#import "VFSyntaxDefinition.h"
#import "FRAApplicationDelegate.h"
#import "FRAVariousPerformer.h"

@implementation VFSyntaxDefinition

static NSMutableArray * gsAllDefinitions = nil;
static NSMutableDictionary *gsMap = nil;

+ (void)initialize
{
    gsAllDefinitions = [[NSMutableArray alloc] init];
    gsMap = [[NSMutableDictionary alloc] init];
}

- (id)init
{
    if ((self = [super init]))
    {
        [gsAllDefinitions addObject: self];
    }
    
    return self;
}

- (void)setName: (NSString *)name
{
    if (_name != name)
    {
        _name = name;
        
        gsMap[_name] = self;
    }
}

+ (NSArray *)allDefinitions
{
    return gsAllDefinitions;
}

+ (VFSyntaxDefinition *)definitionForName: (NSString *)name
{
    return gsMap[name];
}

- (void)didChangeValueForKey:(NSString *)key
{
	[super didChangeValueForKey:key];
	
	if ([[FRAApplicationDelegate sharedInstance] hasFinishedLaunching] == NO) {
		return;
	}
	
	if ([FRAVarious isChangingSyntaxDefinitionsProgrammatically] == YES) {
		return;
	}
    
	NSDictionary *changedObject = (@{
                                     @"name": [self name],
                                     @"extensions": [self extensions]
                                    });
    
	if ([FRADefaults valueForKey:@"ChangedSyntaxDefinitions"])
    {
		NSMutableArray *changedSyntaxDefinitionsArray = [NSMutableArray arrayWithArray: [FRADefaults valueForKey:@"ChangedSyntaxDefinitions"]];
		NSArray *array = [NSArray arrayWithArray: changedSyntaxDefinitionsArray];
		for (NSDictionary *item in array)
        {
			if ([item[@"name"] isEqualToString: [self name]])
            {
				[changedSyntaxDefinitionsArray removeObject: item];
			}
		}
        
		[changedSyntaxDefinitionsArray addObject: changedObject];
		[FRADefaults setValue: changedSyntaxDefinitionsArray
                       forKey: @"ChangedSyntaxDefinitions"];
	} else
    {
		[FRADefaults setValue: @[changedObject]
                       forKey: @"ChangedSyntaxDefinitions"];
	}
}

@end
