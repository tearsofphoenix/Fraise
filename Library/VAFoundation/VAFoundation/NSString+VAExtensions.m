//
//  NSString+VAExtensions.m
//  VAFoundation
//
//  Created by Mac003 on 14-6-5.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import "NSString+VAExtensions.h"

@implementation NSString (VAExtensions)


- (NSArray *)divideCommandIntoArray
{
	if ([self rangeOfString:@"\""].location == NSNotFound && [self rangeOfString:@"'"].location == NSNotFound)
    {
		return [self componentsSeparatedByString:@" "];
	} else
    {
		NSMutableArray *returnArray = [NSMutableArray array];
		NSScanner *scanner = [NSScanner scannerWithString:self];
		NSInteger location = 0;
		NSInteger commandLength = [self length];
		NSInteger beginning;
		NSInteger savedBeginning = -1;
		NSString *characterToScanFor;
		
		while (location < commandLength)
        {
			if (savedBeginning == -1)
            {
				beginning = location;
			} else {
				beginning = savedBeginning;
				savedBeginning = -1;
			}
			if ([self characterAtIndex:location] == '"') {
				characterToScanFor = @"\"";
				beginning++;
				location++;
			} else if ([self characterAtIndex:location] == '\'') {
				characterToScanFor = @"'";
				beginning++;
				location++;
			} else {
				characterToScanFor = @" ";
			}
			
			[scanner setScanLocation:location];
			if ([scanner scanUpToString:characterToScanFor intoString:nil]) {
				if (![characterToScanFor isEqualToString:@" "] && [self characterAtIndex:([scanner scanLocation] - 1)] == '\\') {
					location = [scanner scanLocation];
					savedBeginning = beginning - 1;
					continue;
				}
				location = [scanner scanLocation];
			} else {
				location = commandLength - 1;
			}
			
			[returnArray addObject:[self substringWithRange:NSMakeRange(beginning, location - beginning)]];
			location++;
		}
		return (NSArray *)returnArray;
	}
}


+ (NSString *)UUIDString
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
    
    return (__bridge NSString *)uuidString;
}


static NSString *darkSideLineEnding = nil;
static NSString *macLineEnding = nil;
static NSString *unixLineEnding = nil;
static NSString *newLineSymbolString = nil;
static BOOL __initialized = NO;

static void __initializeIfNeeded(void)
{
    if (!__initialized)
    {
        darkSideLineEnding = [[NSString alloc] initWithFormat:@"%C%C", 0x000D, 0x000A];
        macLineEnding = [[NSString alloc] initWithFormat:@"%C", 0x000D];
        unixLineEnding = [[NSString alloc] initWithFormat:@"%C", 0x000A];
        
        newLineSymbolString = [[NSString alloc] initWithFormat:@"%C", 0x23CE];
        
        __initialized = YES;
    }
}

- (NSString *)stringByConvertToLineEndings: (VALineEndingType)lineEndings
{
    __initializeIfNeeded();
    
	if (lineEndings == VALeaveLineEndingsUnchanged)
    {
		return self;
	}
	
	NSMutableString *returnString = [NSMutableString stringWithString: self];
	
	if (lineEndings == VADarkSideLineEndings) { // CRLF
		[returnString replaceOccurrencesOfString:darkSideLineEnding withString:unixLineEnding options:NSLiteralSearch range:NSMakeRange(0, [returnString length])]; // So that it doesn't change macLineEnding part of darkSideLineEnding
		[returnString replaceOccurrencesOfString:macLineEnding withString:unixLineEnding options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
		[returnString replaceOccurrencesOfString:unixLineEnding withString:darkSideLineEnding options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
		
	} else if (lineEndings == VAMacLineEndings) { // CR
		[returnString replaceOccurrencesOfString:darkSideLineEnding withString:macLineEnding options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
		[returnString replaceOccurrencesOfString:unixLineEnding withString:macLineEnding options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
		
	} else { // LF
		[returnString replaceOccurrencesOfString:darkSideLineEnding withString:unixLineEnding options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
		[returnString replaceOccurrencesOfString:macLineEnding withString:unixLineEnding options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
	}
	
	return (NSString *)returnString;
}


- (NSString *)stringByReplaceAllNewLineCharactersWithSymbol
{
    __initializeIfNeeded();

	// To remove all newline characters in textString and replace it with a symbol, use NSMakeRange every time as the length changes
	NSMutableString *returnString = [NSMutableString stringWithString: self];
	
	[returnString replaceOccurrencesOfString:darkSideLineEnding withString:newLineSymbolString options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
	[returnString replaceOccurrencesOfString:macLineEnding withString:newLineSymbolString options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
	[returnString replaceOccurrencesOfString:unixLineEnding withString:newLineSymbolString options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
	
	return returnString;
}


- (NSString *)stringByRemoveAllLineEndings
{
    __initializeIfNeeded();

	NSMutableString *returnString = [NSMutableString stringWithString: self];
	[returnString replaceOccurrencesOfString:darkSideLineEnding withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
	[returnString replaceOccurrencesOfString:macLineEnding withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
	[returnString replaceOccurrencesOfString:unixLineEnding withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
	
	return returnString;
}

+ (NSString *)darkSideLineEnding
{
    __initializeIfNeeded();
    return darkSideLineEnding;
}

+ (NSString *)macLineEnding
{
    __initializeIfNeeded();
    return macLineEnding;
}
+ (NSString *)unixLineEnding
{
    __initializeIfNeeded();
    return unixLineEnding;
}
+ (NSString *)newLineSymbolString
{
    __initializeIfNeeded();
    return newLineSymbolString;
}


@end
