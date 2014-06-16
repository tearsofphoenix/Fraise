/*
Fraise version 3.7 - Based on Smultron by Peter Borg
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Fraise

Copyright 2010 Jean-François Moy
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "FRAStandardHeader.h"

#import "NSString+Fraise.h"
#import "FRAInfoController.h"
#import "FRAProjectsController.h"
#import "FRABasicPerformer.h"
#import "FRAInterfacePerformer.h"
#import "FRATextView.h"
#import "FRAVariousPerformer.h"
#import "VADocument.h"


@implementation FRAInfoController

@synthesize infoWindow;

VASingletonIMPDefault(FRAInfoController)

- (void)openInfoWindow
{
	if (infoWindow == nil) {
		[NSBundle loadNibNamed:@"FRAInfo.nib" owner:self];
		
	}
	
	if ([infoWindow isVisible] == NO) {
		[self refreshInfo];
		[infoWindow makeKeyAndOrderFront:self];
	} else {
		[infoWindow orderOut:nil];
	}
}


- (void)refreshInfo
{
	VADocument *document = FRACurrentDocument;
	if (document == nil) {
		NSBeep();
		return;			
	}
	
	[titleTextField setStringValue:[document name]];
	if ([document isNewDocument] || [document path] == nil) {
		NSImage *image = [NSImage imageNamed:@"FRADocumentIcon"];
		[image setSize:NSMakeSize(64.0, 64.0)];
		NSArray *array = [image representations];
		for (id item in array) {
			[(NSImageRep *)item setSize:NSMakeSize(64.0, 64.0)];
		}
		[iconImageView setImage:image];
		
	} else {
		[iconImageView setImage:[[NSWorkspace sharedWorkspace] iconForFile:[document path]]];
	}
	
	NSDictionary *fileAttributes = [document fileAttributes];
	
	if (fileAttributes != nil) {
		[fileSizeTextField setStringValue:[NSString stringWithFormat:@"%@ %@", [FRABasic thousandFormatedStringFromNumber: @([fileAttributes fileSize])], NSLocalizedString(@"bytes", @"The name for bytes in the info window")]];
		[whereTextField setStringValue:[[document path] stringByDeletingLastPathComponent]];
		[createdTextField setStringValue:[NSString dateStringForDate:(NSCalendarDate *)[fileAttributes fileCreationDate] formatIndex:[[FRADefaults valueForKey:@"StatusBarLastSavedFormatPopUp"] integerValue]]];
		[modifiedTextField setStringValue:[NSString dateStringForDate:(NSCalendarDate *)[fileAttributes fileModificationDate] formatIndex:[[FRADefaults valueForKey:@"StatusBarLastSavedFormatPopUp"] integerValue]]];
		[creatorTextField setStringValue:NSFileTypeForHFSTypeCode([fileAttributes fileHFSCreatorCode])];
		[typeTextField setStringValue:NSFileTypeForHFSTypeCode([fileAttributes fileHFSTypeCode])];
		[ownerTextField setStringValue:[fileAttributes fileOwnerAccountName]];
		[groupTextField setStringValue:[fileAttributes fileGroupOwnerAccountName]];
		[permissionsTextField setStringValue:[self stringFromPermissions:[fileAttributes filePosixPermissions]]];
	}
	
	
	FRATextView *textView = FRACurrentTextView;
	if (textView == nil)
    {
		textView = [document firstTextView];
	}
	NSString *text = [textView string];;
	
	[lengthTextField setStringValue:[FRABasic thousandFormatedStringFromNumber:@([text length])]];
	
	NSArray *array = [textView selectedRanges];
	
	NSInteger selection = 0;
	for (id item in array) {
		selection = selection + [item rangeValue].length;
	}
	if (selection == 0) {
		[selectionTextField setStringValue:@""];
	} else {
		[selectionTextField setStringValue:[FRABasic thousandFormatedStringFromNumber:@(selection)]];
	}
	
	NSRange selectionRange;
	if (textView == nil) {
		selectionRange = NSMakeRange(0,0);
	} else {
		selectionRange = [textView selectedRange];
	}
	[positionTextField setStringValue:[NSString stringWithFormat:@"%@\\%@", [FRABasic thousandFormatedStringFromNumber: @((selectionRange.location - [text lineRangeForRange:selectionRange].location))], [FRABasic thousandFormatedStringFromNumber: @(selectionRange.location)]]];
	
	NSInteger index;
	NSInteger lineNumber;
	NSInteger lastCharacter = [text length];
	for (index = 0, lineNumber = 0; index < lastCharacter; lineNumber++) {
		index = NSMaxRange([text lineRangeForRange:NSMakeRange(index, 0)]);
	}
	if (lastCharacter > 0) {
		unichar lastGlyph = [text characterAtIndex:lastCharacter - 1];
		if (lastGlyph == '\n' || lastGlyph == '\r') {
			lineNumber++;
		}
	}


	[linesTextField setStringValue:[NSString stringWithFormat:@"%ld/%ld", [FRAInterface currentLineNumber], lineNumber]];

	NSArray *functions = [FRAInterface allFunctions];
	
	if ([functions count] == 0) {
		[functionTextField setStringValue:@""];
	} else {
		index = [FRAInterface currentFunctionIndexForFunctions:functions];
		if (index == -1) {
			[functionTextField setStringValue:@""];
		} else {
			[functionTextField setStringValue:[functions[index] valueForKey:@"name"]];
		}
	}
	
	if (selection > 1) {
		[wordsTextField setStringValue:[NSString stringWithFormat:@"%@ (%@)", [FRABasic thousandFormatedStringFromNumber:@([[NSSpellChecker sharedSpellChecker] countWordsInString:[text substringWithRange:selectionRange] language:nil])], [FRABasic thousandFormatedStringFromNumber:@([[NSSpellChecker sharedSpellChecker] countWordsInString:text language:nil])]]];
	} else {
		[wordsTextField setStringValue:[NSString stringWithFormat:@"%@", [FRABasic thousandFormatedStringFromNumber:@([[NSSpellChecker sharedSpellChecker] countWordsInString:text language:nil])]]];
	}

	[encodingTextField setStringValue:[document encodingName]];
	
	[syntaxTextField setStringValue:[document syntaxDefinition]];

	if ([document path] != nil) {
		[spotlightTextField setStringValue:[FRAVarious performCommand:[NSString stringWithFormat:@"/usr/bin/mdls '%@'", [document path]]]];
	} else {
		[spotlightTextField setStringValue:@""];
	}
}

- (NSString *)stringFromPermissions:(NSUInteger)permissions 
{
    char permissionsString[12];
	
#if __LP64__
    strmode((short)permissions, permissionsString);
#else
	strmode(permissions, permissionsString);
#endif
	
    permissionsString[11] = '\0';
    
	NSMutableString *returnString = [NSMutableString stringWithUTF8String:permissionsString];
	[returnString deleteCharactersInRange:NSMakeRange(0, 1)];
	[returnString insertString:@" " atIndex:3];
	[returnString insertString:@" " atIndex:7];
	[returnString insertString:@" " atIndex:11];
	
    return returnString;
}

@end
