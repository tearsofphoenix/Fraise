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

@end
