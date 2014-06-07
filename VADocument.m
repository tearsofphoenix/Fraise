//
//  VADocument.m
//  Fraise
//
//  Created by Lei on 14-6-7.
//
//
#import "FRAStandardHeader.h"
#import "VADocument.h"
#import "FRAProject.h"
#import <VADevUIKit/VADevUIKit.h>

@implementation VADocument

static NSMutableArray *gsAllDocuments = nil;

+ (void)initialize
{
    gsAllDocuments = [[NSMutableArray alloc] initWithCapacity: 16];
}

- (id)init
{
    if ((self = [super init]))
    {
        id defaults = FRADefaults;
        
        _isSyntaxColoured = [[defaults valueForKey:@"SyntaxColourNewDocuments"] boolValue];
        _lineWrapped = [[defaults valueForKey:@"LineWrapNewDocuments"] boolValue];
        _showInvisibleCharacters = [[defaults valueForKey:@"ShowInvisibleCharacters"] boolValue];
        _showLineNumberGutter = [[defaults valueForKey:@"ShowLineNumberGutter"] boolValue];
        _gutterWidth = [[defaults valueForKey:@"GutterWidth"] integerValue];
        _encoding = [[defaults valueForKey:@"EncodingsPopUp"] integerValue];
        
        [gsAllDocuments addObject: self];
    }
    
    return self;
}


+ (NSArray *)allDocuments
{
    return gsAllDocuments;
}

@end
