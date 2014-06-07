//
//  VISyntaxColouring+TextDelegate.h
//  VADevUIKit
//
//  Created by Lei on 14-6-7.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import "VISyntaxColouring.h"
#import <VAFoundation/VAFoundation.h>


@interface VISyntaxColouring ()
{
	NSUndoManager *undoManager;
	VILayoutManager *firstLayoutManager;
	
	NSTimer *autocompleteWordsTimer;
	NSInteger currentYOfSelectedCharacter, lastYOfSelectedCharacter, currentYOfLastCharacterInLine, lastYOfLastCharacterInLine, currentYOfLastCharacter, lastYOfLastCharacter, lastCursorLocation;
	
	NSCharacterSet *letterCharacterSet, *keywordStartCharacterSet, *keywordEndCharacterSet;
	
	NSDictionary *commandsColour, *commentsColour, *instructionsColour, *keywordsColour, *autocompleteWordsColour, *stringsColour, *variablesColour, *attributesColour, *lineHighlightColour;
	
	NSEnumerator *wordEnumerator;
	NSSet *keywords;
	NSSet *autocompleteWords;
	NSArray *keywordsAndAutocompleteWords;
	BOOL keywordsCaseSensitive;
	BOOL recolourKeywordIfAlreadyColoured;
	NSString *beginCommand;
	NSString *endCommand;
	NSString *beginInstruction;
	NSString *endInstruction;
	NSCharacterSet *beginVariable;
	NSCharacterSet *endVariable;
	NSString *firstString;
	unichar firstStringUnichar;
	NSString *secondString;
	unichar secondStringUnichar;
	NSString *firstSingleLineComment, *secondSingleLineComment, *beginFirstMultiLineComment, *endFirstMultiLineComment, *beginSecondMultiLineComment, *endSecondMultiLineComment;
	
	NSString *completeString;
	NSString *searchString;
	NSScanner *scanner;
	NSScanner *completeDocumentScanner;
	NSInteger beginning, end, endOfLine, index, length, searchStringLength, commandLocation, skipEndCommand, beginLocationInMultiLine, endLocationInMultiLine, searchSyntaxLength, rangeLocation;
	NSRange rangeOfLine;
	NSString *keyword;
	BOOL shouldOnlyColourTillTheEndOfLine;
	unichar commandCharacterTest;
	unichar beginCommandCharacter;
	unichar endCommandCharacter;
	BOOL shouldColourMultiLineStrings;
	BOOL foundMatch;
	NSInteger completeStringLength;
	unichar characterToCheck;
	NSRange editedRange;
	NSInteger cursorLocation;
	NSInteger differenceBetweenLastAndPresent;
	NSInteger skipMatchingBrace;
	NSRect visibleRect;
	NSRange visibleRange;
	NSInteger beginningOfFirstVisibleLine;
	NSInteger endOfLastVisibleLine;
	NSRange selectedRange;;
	NSInteger stringLength;
	NSString *keywordTestString;
	NSString *autocompleteTestString;
	NSRange searchRange;
	NSInteger maxRange;
	
	NSTextContainer *textContainer;
    
	NSCharacterSet *attributesCharacterSet;
	
	ICUPattern *firstStringPattern;
	ICUPattern *secondStringPattern;
	
	ICUMatcher *firstStringMatcher;
	ICUMatcher *secondStringMatcher;
	
	NSRange foundRange;
	
	NSTimer *liveUpdatePreviewTimer;
	
	NSRange lastLineHighlightRange;
}

@property (nonatomic, strong) NSMutableArray *textViews;

@end

@interface VISyntaxColouring (TextDelegate) <NSTextStorageDelegate>

@end


