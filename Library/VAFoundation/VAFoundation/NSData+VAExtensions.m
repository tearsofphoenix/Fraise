//
//  NSData+VAExtensions.m
//  VAFoundation
//
//  Created by Mac003 on 14-6-10.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import "NSData+VAExtensions.h"

@implementation NSData (VAExtensions)

- (NSStringEncoding)guessEncoding
{
	NSString *string = [[NSString alloc] initWithData: self
                                             encoding: NSISOLatin1StringEncoding];
	NSStringEncoding encoding = 0;
	BOOL foundExplicitEncoding = NO;
	
	if ([string length] > 9) { // If it's shorter than this you can't check for encoding string
		NSScanner *scannerHTML = [[NSScanner alloc] initWithString:string];
		NSInteger beginning;
		NSInteger end;
		
		[scannerHTML scanUpToString:@"charset=" intoString:nil]; // Search first for "charset=" (html) and get the string after that
		if ([scannerHTML scanLocation] < [string length] - 8) {
			beginning = [scannerHTML scanLocation] + 8; // Place it after the =
			if (beginning + 1 < [string length] && [string characterAtIndex:beginning] == '"') { // If the encoding is within quotes
				beginning++;
			}
			[scannerHTML setScanLocation:beginning];
			[scannerHTML scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"' />"] intoString:nil];
			end = [scannerHTML scanLocation];
            
			encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)[string substringWithRange:NSMakeRange(beginning, end - beginning)]));
			foundExplicitEncoding = YES;
		} else {
			NSScanner *scannerXML = [[NSScanner alloc] initWithString:string];
			[scannerXML scanUpToString:@"encoding=" intoString:nil]; // If not found, search for "encoding=" (xml) and get the string after that
			if ([scannerXML scanLocation] < [string length] - 9) {
				beginning = [scannerXML scanLocation] + 9 + 1; // After the " or '
				[scannerXML scanUpToString:@"?>" intoString:nil];
				end = [scannerXML scanLocation] - 1; // -1 to get rid of " or '
				encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)[string substringWithRange:NSMakeRange(beginning, end - beginning)]));
				foundExplicitEncoding = YES;
			}
		}
	}
	
	// If the scanner hasn't found an explicitly defined encoding, check for either EFBBBF, FEFF or FFFE and, if found, set the encoding to UTF-8 or UTF-16
	if (!foundExplicitEncoding && [self length] > 2)
    {
		NSString *lookForEncodingInBytesString = [NSString stringWithString: [self description]];
		if ([[lookForEncodingInBytesString substringWithRange:NSMakeRange(1,6)] isEqualToString:@"efbbbf"]) encoding = NSUTF8StringEncoding;
		else if ([[lookForEncodingInBytesString substringWithRange:NSMakeRange(1,4)] isEqualToString:@"feff"] || [[lookForEncodingInBytesString substringWithRange:NSMakeRange(1,4)] isEqualToString:@"fffe"]) encoding = NSUnicodeStringEncoding;
	}
    
	return encoding;
}

@end
