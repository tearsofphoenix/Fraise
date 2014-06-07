//
//  VISyntaxColouring+TextDelegate.m
//  VADevUIKit
//
//  Created by Lei on 14-6-7.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import "VISyntaxColouring+TextDelegate.h"
#import "VISyntaxColouring.h"
#import "VITextView.h"

@implementation VISyntaxColouring (TextDelegate)

#pragma mark -
#pragma mark Delegates

- (void)textDidChange:(NSNotification *)notification
{
	if ([self reactToChanges] == NO)
    {
		return;
	}
	
	if ([completeString length] < 2)
    {
        //TODO
        //		[FRAInterface updateStatusBar]; // One needs to call this from here as well because otherwise it won't update the status bar if one writes one character and deletes it in an empty document, because the textViewDidChangeSelection delegate method won't be called.
	}
	
	VITextView *textView = (VITextView *)[notification object];
	BOOL isEdited = YES;
    BOOL isSyntaxColoured = YES;
    
	if (!isEdited)
    {
        //		[FRAVarious hasChangedDocument:document];
	}
	
	if ([self highlightCurrentLine])
    {
		[self highlightLineRange:[completeString lineRangeForRange:[textView selectedRange]]];
        
	} else if (isSyntaxColoured)
    {
		[self pageRecolourTextView: textView];
	}
	
	if (autocompleteWordsTimer != nil)
    {
		[autocompleteWordsTimer setFireDate: [NSDate dateWithTimeIntervalSinceNow: [self autocompleteAfterDelay]]];
        
	} else if ([self autocompleteSuggestAutomatically])
    {
		autocompleteWordsTimer = [NSTimer scheduledTimerWithTimeInterval: [self autocompleteAfterDelay]
                                                                  target: self
                                                                selector: @selector(autocompleteWordsTimerSelector:)
                                                                userInfo: textView
                                                                 repeats: NO];
	}
	
	if (liveUpdatePreviewTimer != nil)
    {
		[liveUpdatePreviewTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow: [self liveUpdatePreviewDelay]]];
        
	} else if ([self liveUpdatePreview])
    {
		liveUpdatePreviewTimer = [NSTimer scheduledTimerWithTimeInterval: [self liveUpdatePreviewDelay]
                                                                  target: self
                                                                selector: @selector(liveUpdatePreviewTimerSelector:)
                                                                userInfo: textView
                                                                 repeats: NO];
	}
	
    //TODO
//	[[document valueForKey:@"lineNumbers"] updateLineNumbersCheckWidth: NO];
}


- (void)textViewDidChangeSelection:(NSNotification *)aNotification
{
	if ([self reactToChanges] == NO)
    {
		return;
	}
	
	completeStringLength = [completeString length];
	if (completeStringLength == 0) {
		return;
	}
	
	VITextView *textView = [aNotification object];
    
    //TODO
    //	[FRACurrentProject setLastTextViewInFocus:textView];
    //
    //	[FRAInterface updateStatusBar];
	
	editedRange = [textView selectedRange];
	
	if ([self highlightCurrentLine])
    {
		[self highlightLineRange:[completeString lineRangeForRange:editedRange]];
	}
	
	if ([self showMatchingBraces] == NO)
    {
		return;
	}
    
	
	cursorLocation = editedRange.location;
	differenceBetweenLastAndPresent = cursorLocation - lastCursorLocation;
	lastCursorLocation = cursorLocation;
	if (differenceBetweenLastAndPresent != 1 && differenceBetweenLastAndPresent != -1) {
		return; // If the difference is more than one, they've moved the cursor with the mouse or it has been moved by resetSelectedRange below and we shouldn't check for matching braces then
	}
	
	if (differenceBetweenLastAndPresent == 1) { // Check if the cursor has moved forward
		cursorLocation--;
	}
	
	if (cursorLocation == completeStringLength) {
		return;
	}
	
	characterToCheck = [completeString characterAtIndex:cursorLocation];
	skipMatchingBrace = 0;
	
	if (characterToCheck == ')') {
		while (cursorLocation--) {
			characterToCheck = [completeString characterAtIndex:cursorLocation];
			if (characterToCheck == '(') {
				if (!skipMatchingBrace) {
					[textView showFindIndicatorForRange:NSMakeRange(cursorLocation, 1)];
					return;
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == ')') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == ']') {
		while (cursorLocation--) {
			characterToCheck = [completeString characterAtIndex:cursorLocation];
			if (characterToCheck == '[') {
				if (!skipMatchingBrace) {
					[textView showFindIndicatorForRange:NSMakeRange(cursorLocation, 1)];
					return;
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == ']') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == '}') {
		while (cursorLocation--) {
			characterToCheck = [completeString characterAtIndex:cursorLocation];
			if (characterToCheck == '{') {
				if (!skipMatchingBrace) {
					[textView showFindIndicatorForRange:NSMakeRange(cursorLocation, 1)];
					return;
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '}') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == '>') {
		while (cursorLocation--) {
			characterToCheck = [completeString characterAtIndex:cursorLocation];
			if (characterToCheck == '<') {
				if (!skipMatchingBrace) {
					[textView showFindIndicatorForRange:NSMakeRange(cursorLocation, 1)];
					return;
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '>') {
				skipMatchingBrace++;
			}
		}
	}
}


- (NSArray *)textView: theTextView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
{
	if ([keywordsAndAutocompleteWords count] == 0)
    {
		if ([self autocompleteIncludeStandardWords] == NO)
        {
			return @[];
		} else {
			return words;
		}
	}
	
	NSString *matchString = [[theTextView string] substringWithRange:charRange];
	NSMutableArray *finalWordsArray = [NSMutableArray arrayWithArray:keywordsAndAutocompleteWords];
	
    if ([self autocompleteIncludeStandardWords])
    {
		[finalWordsArray addObjectsFromArray:words];
	}
	
	NSMutableArray *matchArray = [NSMutableArray array];
	NSString *item;
	for (item in finalWordsArray) {
		if ([item rangeOfString:matchString options:NSCaseInsensitiveSearch range:NSMakeRange(0, [item length])].location == 0) {
			[matchArray addObject:item];
		}
	}
	
	if ([self autocompleteIncludeStandardWords])
    { // If no standard words are added there's no need to sort it again as it has already been sorted
		return [matchArray sortedArrayUsingSelector:@selector(compare:)];
	} else
    {
		return matchArray;
	}
}

- (void)autocompleteWordsTimerSelector:(NSTimer *)theTimer
{
	VITextView *textView = [theTimer userInfo];
	selectedRange = [textView selectedRange];
	stringLength = [completeString length];
    
	if (selectedRange.location <= stringLength && selectedRange.length == 0 && stringLength != 0)
    {
		if (selectedRange.location == stringLength) { // If we're at the very end of the document
			[textView complete:nil];
		} else {
			unichar characterAfterSelection = [completeString characterAtIndex:selectedRange.location];
			if ([[NSCharacterSet symbolCharacterSet] characterIsMember:characterAfterSelection] || [[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:characterAfterSelection] || [[NSCharacterSet punctuationCharacterSet] characterIsMember:characterAfterSelection] || selectedRange.location == stringLength) { // Don't autocomplete if we're in the middle of a word
				[textView complete:nil];
			}
		}
	}
	
	if (autocompleteWordsTimer) {
		[autocompleteWordsTimer invalidate];
		autocompleteWordsTimer = nil;
	}
}


- (void)liveUpdatePreviewTimerSelector:(NSTimer *)theTimer
{
	if ([self liveUpdatePreview])
    {
        //		[[FRAPreviewController sharedInstance] liveUpdate];
	}
	
	if (liveUpdatePreviewTimer)
    {
		[liveUpdatePreviewTimer invalidate];
		liveUpdatePreviewTimer = nil;
	}
}

@end
