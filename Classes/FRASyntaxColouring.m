// FRATextView delegate

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

#import "FRASyntaxColouring.h"
#import "FRATextView.h"
#import "FRABasicPerformer.h"
#import "FRAApplicationDelegate.h"
#import "FRAInterfacePerformer.h"
#import "FRAVariousPerformer.h"
#import "FRAProjectsController.h"
#import "FRAPreviewController.h"

#import "FRAProject.h"
#import "VFSyntaxDefinition.h"
#import "VADocument.h"

#import <VAFoundation/VAFoundation.h>
#import <VADevUIKit/VADevUIKit.h>

@interface FRASyntaxColouring ()
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
    
	VADocument *document;
	
	NSCharacterSet *attributesCharacterSet;
	
	ICUPattern *firstStringPattern;
	ICUPattern *secondStringPattern;
	
	ICUMatcher *firstStringMatcher;
	ICUMatcher *secondStringMatcher;
	
	NSRange foundRange;
	
	NSTimer *liveUpdatePreviewTimer;
	
	NSRange lastLineHighlightRange;
}
@end

@implementation FRASyntaxColouring

@synthesize undoManager;

- (instancetype)init
{
    return [self initWithDocument: nil];
}


- (instancetype)initWithDocument:(id)theDocument
{
	if ((self = [super init]))
    {
		document = theDocument;
		firstLayoutManager = (VILayoutManager *)[[document firstTextView] layoutManager];
		_secondLayoutManager = nil;
		_thirdLayoutManager = nil;
		_fourthLayoutManager = nil;
        
		[self setColours];
		
		letterCharacterSet = [NSCharacterSet letterCharacterSet];
		NSMutableCharacterSet *temporaryCharacterSet = [[NSCharacterSet letterCharacterSet] mutableCopy];
		[temporaryCharacterSet addCharactersInString:@"_:@#"];
		keywordStartCharacterSet = [temporaryCharacterSet copy];
		
		temporaryCharacterSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
		[temporaryCharacterSet formUnionWithCharacterSet:[NSCharacterSet symbolCharacterSet]];
		[temporaryCharacterSet formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
		[temporaryCharacterSet removeCharactersInString:@"_"];
		keywordEndCharacterSet = [temporaryCharacterSet copy];
		
		temporaryCharacterSet = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
		[temporaryCharacterSet addCharactersInString:@" -"]; // If there are two spaces before an attribute
		attributesCharacterSet = [temporaryCharacterSet copy];
		
		[self setSyntaxDefinition];
		
		completeString = [[document firstTextView] string];
		textContainer = [[document firstTextView] textContainer];
		
		_reactToChanges = YES;
        
		[[document firstTextView] setDelegate:self];
		[[[document firstTextView] textStorage] setDelegate:self];
		undoManager = [[NSUndoManager alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkIfCanUndo) name:@"NSUndoManagerDidUndoChangeNotification" object:undoManager];
		
		lastLineHighlightRange = NSMakeRange(0, 0);
		
		NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
        
		[defaultsController addObserver:self forKeyPath:@"values.CommandsColourWell" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.CommentsColourWell" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.InstructionsColourWell" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.KeywordsColourWell" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.AutocompleteColourWell" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.VariablesColourWell" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.StringsColourWell" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.AttributesColourWell" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.ColourCommands" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.ColourComments" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.ColourInstructions" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.ColourKeywords" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.ColourAutocomplete" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.ColourVariables" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.ColourStrings" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.ColourAttributes" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.ColourMultiLineStrings" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.OnlyColourTillTheEndOfLine" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.HighlightCurrentLine" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.HighlightLineColourWell" options:NSKeyValueObservingOptionNew context:@"ColoursChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.ColourMultiLineStrings" options:NSKeyValueObservingOptionNew context:@"MultiLineChanged"];
		
	}
    return self;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([(__bridge NSString *)context isEqualToString:@"ColoursChanged"]) {
		[self setColours];
		[self pageRecolour];
		if ([[FRADefaults valueForKey:@"HighlightCurrentLine"] boolValue] == YES) {
			NSRange range = [completeString lineRangeForRange:[[document firstTextView] selectedRange]];
			[self highlightLineRange:range];
			lastLineHighlightRange = range;
		} else {
			[self highlightLineRange:NSMakeRange(0, 0)];
		}
	} else if ([(__bridge NSString *)context isEqualToString:@"MultiLineChanged"]) {
		[self prepareRegularExpressions];
		[self pageRecolour];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
	
}


- (NSUndoManager *)undoManagerForTextView:(NSTextView *)aTextView
{
	return undoManager;
}

#pragma mark -
#pragma mark Setup

- (void)setColours
{
	commandsColour = @{NSForegroundColorAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"CommandsColourWell"]]};
	
	commentsColour = @{NSForegroundColorAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"CommentsColourWell"]]};
	
	instructionsColour = @{NSForegroundColorAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"InstructionsColourWell"]]};
	
	keywordsColour = @{NSForegroundColorAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"KeywordsColourWell"]]};
	
	autocompleteWordsColour = @{NSForegroundColorAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"AutocompleteColourWell"]]};
	
	stringsColour = @{NSForegroundColorAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"StringsColourWell"]]};
	
	variablesColour = @{NSForegroundColorAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"VariablesColourWell"]]};
	
	attributesColour = @{NSForegroundColorAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"AttributesColourWell"]]};
	
	lineHighlightColour = @{NSBackgroundColorAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"HighlightLineColourWell"]]};
}


- (void)setSyntaxDefinition
{
	NSArray *syntaxDefinitions = [VFSyntaxDefinition allDefinitions];
	
    NSString *name = [FRADefaults valueForKey:@"SyntaxColouringPopUpString"];
	VFSyntaxDefinition *foundSyntaxDefinition = [VFSyntaxDefinition definitionForName: name]; //[managedObjectContext executeFetchRequest:request error:nil];
    
	NSString *fileToUse = nil;
	NSString *extension = [[document name] pathExtension];
    
	if ([document hasManuallyChangedSyntaxDefinition])
    { // Once the user has changed the syntax definition always use that one and not the one from the extension

		VFSyntaxDefinition *foundManuallyChangedSyntaxDefinition = [VFSyntaxDefinition definitionForName: [document syntaxDefinition]];

		if (foundManuallyChangedSyntaxDefinition)
        {
			fileToUse = [foundManuallyChangedSyntaxDefinition file];
		} else
        {
			fileToUse = [syntaxDefinitions[0] valueForKey:@"file"];
		}
	} else
    {
		if ([[FRADefaults valueForKey:@"SyntaxColouringMatrix"] integerValue] == 1) { // Always use...
			if (foundSyntaxDefinition)
            {
				fileToUse = [foundSyntaxDefinition file];
				[document setSyntaxDefinition: [foundSyntaxDefinition name]];
			} else
            {
				fileToUse = syntaxDefinitions[0][@"file"];
				[document setSyntaxDefinition: syntaxDefinitions[0][@"name"]];
			}
		} else {
			NSString *lowercaseExtension;
			if ([extension isEqualToString:@""]) { // If there is no extension try to guess it
				NSString *string = [[[document firstTextScrollView] documentView] string];
				NSString *firstLine = [string substringWithRange:[string lineRangeForRange:NSMakeRange(0,0)]];
				if ([firstLine hasPrefix:@"#!"] || [firstLine hasPrefix:@"%"] || [firstLine hasPrefix:@"<?"]) {
					lowercaseExtension = [self guessSyntaxDefinitionFromFirstLine:firstLine];
				} else {
					lowercaseExtension = @"";
				}
			} else {
				lowercaseExtension = [extension lowercaseString];
			}
			
			id item;
			index = 0;
			for (item in syntaxDefinitions)
            {
				NSString *name = [item valueForKey:@"name"];
				if ([name isEqualToString:@"Standard"] || [name isEqualToString:@"None"] || item[@"extensions"] == nil)
                {
					continue;
				}
				NSMutableString *extensionsString = [NSMutableString stringWithString: item[@"extensions"]];
				[extensionsString replaceOccurrencesOfString:@"." withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [extensionsString length])];
				if ([[extensionsString componentsSeparatedByString:@" "] containsObject:lowercaseExtension])
                {
					fileToUse = item[@"file"];
					[document setSyntaxDefinition: name];
					break;
				}
				index++;
			}
			if (fileToUse == nil && foundSyntaxDefinition)
            {
				fileToUse = [foundSyntaxDefinition file];
				[document setSyntaxDefinition: [foundSyntaxDefinition name]];
			}
		}
	}
	
	if (fileToUse == nil) {
		fileToUse = @"standard"; // Be sure to set it to something
		[document setValue:@"Standard" forKey:@"syntaxDefinition"];
	}
	
	NSDictionary *syntaxDictionary;
	syntaxDictionary = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:fileToUse ofType:@"plist" inDirectory:@"Syntax Definitions"]];
	
	if (!syntaxDictionary)
    { // If it can't find it in the bundle try in Application Support
		NSString *path = [[[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Fraise"] stringByAppendingPathComponent:fileToUse] stringByAppendingString:@".plist"];
		syntaxDictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
	}
	
	if (!syntaxDictionary)
    {
		syntaxDictionary = @{@"name": @"Standard", @"file": @"standard", @"extensions": @""}; // If it can't find a syntax file use Standard
	}
	
	NSMutableArray *keywordsAndAutocompleteWordsTemporary = [NSMutableArray array];
	
	// If the plist file is malformed be sure to set the values to something
	if (syntaxDictionary[@"keywords"])
    {
		keywords = [[NSSet alloc] initWithArray:syntaxDictionary[@"keywords"]];
		[keywordsAndAutocompleteWordsTemporary addObjectsFromArray:syntaxDictionary[@"keywords"]];
	}
	
	if (syntaxDictionary[@"autocompleteWords"]) {
		autocompleteWords = [[NSSet alloc] initWithArray:syntaxDictionary[@"autocompleteWords"]];
		
		[keywordsAndAutocompleteWordsTemporary addObjectsFromArray:syntaxDictionary[@"autocompleteWords"]];
	}
	
	if ([[FRADefaults valueForKey:@"ColourAutocompleteWordsAsKeywords"] boolValue] == YES)
    {
		keywords = [NSSet setWithArray:keywordsAndAutocompleteWordsTemporary];
	}
	
	keywordsAndAutocompleteWords = [keywordsAndAutocompleteWordsTemporary sortedArrayUsingSelector:@selector(compare:)];
	
	if (syntaxDictionary[@"recolourKeywordIfAlreadyColoured"])
    {
		recolourKeywordIfAlreadyColoured = [syntaxDictionary[@"recolourKeywordIfAlreadyColoured"] boolValue];
	}
	
	if (syntaxDictionary[@"keywordsCaseSensitive"])
    {
		keywordsCaseSensitive = [syntaxDictionary[@"keywordsCaseSensitive"] boolValue];
	}
	
	if (keywordsCaseSensitive == NO)
    {
		NSMutableArray *lowerCaseKeywords = [[NSMutableArray alloc] init];
		for (id item in keywords)
        {
			[lowerCaseKeywords addObject:[item lowercaseString]];
		}
		
		NSSet *lowerCaseKeywordsSet = [[NSSet alloc] initWithArray:lowerCaseKeywords];
		keywords = lowerCaseKeywordsSet;
	}
	
    beginCommand = syntaxDictionary[@"beginCommand"] ?: @"";
    endCommand = syntaxDictionary[@"endCommand"] ?: @"";
    beginInstruction = syntaxDictionary[@"beginInstruction"] ?: @"";
    endInstruction = syntaxDictionary[@"endInstruction"] ?: @"";
    
	if (syntaxDictionary[@"beginVariable"])
    {
		beginVariable = [NSCharacterSet characterSetWithCharactersInString:syntaxDictionary[@"beginVariable"]];
	}
	
	if (syntaxDictionary[@"endVariable"]) {
		endVariable = [NSCharacterSet characterSetWithCharactersInString:syntaxDictionary[@"endVariable"]];
	} else {
		endVariable = [NSCharacterSet characterSetWithCharactersInString:@""];
	}
	
	if (syntaxDictionary[@"firstString"]) {
		firstString = syntaxDictionary[@"firstString"];
		if (![syntaxDictionary[@"firstString"] isEqualToString:@""]) {
			firstStringUnichar = [syntaxDictionary[@"firstString"] characterAtIndex:0];
		}
	} else {
		firstString = @"";
	}
	
	if (syntaxDictionary[@"secondString"]) {
		secondString = syntaxDictionary[@"secondString"];
		if (![syntaxDictionary[@"secondString"] isEqualToString:@""]) {
			secondStringUnichar = [syntaxDictionary[@"secondString"] characterAtIndex:0];
		}
	} else {
		secondString = @"";
	}
	
    firstSingleLineComment = syntaxDictionary[@"firstSingleLineComment"] ?: @"";
    secondSingleLineComment = syntaxDictionary[@"secondSingleLineComment"] ?: @"";
    beginFirstMultiLineComment = syntaxDictionary[@"beginFirstMultiLineComment"] ?: @"";
	
    endFirstMultiLineComment = syntaxDictionary[@"endFirstMultiLineComment"] ?: @"";
    beginSecondMultiLineComment = syntaxDictionary[@"beginSecondMultiLineComment"] ?: @"";
    
    endSecondMultiLineComment = syntaxDictionary[@"endSecondMultiLineComment"] ?: @"";
    self.functionDefinition = syntaxDictionary[@"functionDefinition"] ?: @"";
    
    self.removeFromFunction = syntaxDictionary[@"removeFromFunction"] ?: @"";
    
	if (syntaxDictionary[@"excludeFromKeywordStartCharacterSet"])
    {
		NSMutableCharacterSet *temporaryCharacterSet = [keywordStartCharacterSet mutableCopy];
		[temporaryCharacterSet removeCharactersInString:syntaxDictionary[@"excludeFromKeywordStartCharacterSet"]];
		keywordStartCharacterSet = [temporaryCharacterSet copy];
	}
	
	if (syntaxDictionary[@"excludeFromKeywordEndCharacterSet"]) {
		NSMutableCharacterSet *temporaryCharacterSet = [keywordEndCharacterSet mutableCopy];
		[temporaryCharacterSet removeCharactersInString:syntaxDictionary[@"excludeFromKeywordEndCharacterSet"]];
		keywordEndCharacterSet = [temporaryCharacterSet copy];
	}
	
	if (syntaxDictionary[@"includeInKeywordStartCharacterSet"]) {
		NSMutableCharacterSet *temporaryCharacterSet = [keywordStartCharacterSet mutableCopy];
		[temporaryCharacterSet addCharactersInString:syntaxDictionary[@"includeInKeywordStartCharacterSet"]];
		keywordStartCharacterSet = [temporaryCharacterSet copy];
	}
	
	if (syntaxDictionary[@"includeInKeywordEndCharacterSet"]) {
		NSMutableCharacterSet *temporaryCharacterSet = [keywordEndCharacterSet mutableCopy];
		[temporaryCharacterSet addCharactersInString:syntaxDictionary[@"includeInKeywordEndCharacterSet"]];
		keywordEndCharacterSet = [temporaryCharacterSet copy];
	}
    
	[self prepareRegularExpressions];
}


- (void)prepareRegularExpressions
{
	if ([[FRADefaults valueForKey:@"ColourMultiLineStrings"] boolValue] == NO)
    {
		firstStringPattern = [[ICUPattern alloc] initWithString:[NSString stringWithFormat:@"\\W%@[^%@\\\\\\r\\n]*+(?:\\\\(?:.|$)[^%@\\\\\\r\\n]*+)*+%@", firstString, firstString, firstString, firstString]];
		
		secondStringPattern = [[ICUPattern alloc] initWithString:[NSString stringWithFormat:@"\\W%@[^%@\\\\\\r\\n]*+(?:\\\\(?:.|$)[^%@\\\\]*+)*+%@", secondString, secondString, secondString, secondString]];
        
	} else
    {
		firstStringPattern = [[ICUPattern alloc] initWithString:[NSString stringWithFormat:@"\\W%@[^%@\\\\]*+(?:\\\\(?:.|$)[^%@\\\\]*+)*+%@", firstString, firstString, firstString, firstString]];
		
		secondStringPattern = [[ICUPattern alloc] initWithString:[NSString stringWithFormat:@"\\W%@[^%@\\\\]*+(?:\\\\(?:.|$)[^%@\\\\]*+)*+%@", secondString, secondString, secondString, secondString]];
	}
}


#pragma mark -
#pragma mark Colouring

- (void)removeAllColours
{
	NSRange wholeRange = NSMakeRange(0, [completeString length]);
    
	[firstLayoutManager removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:wholeRange];
    [_secondLayoutManager removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:wholeRange];
    [_thirdLayoutManager removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:wholeRange];
    [_fourthLayoutManager removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:wholeRange];
}


- (void)removeColoursFromRange:(NSRange)range
{
	[firstLayoutManager removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:range];
    
    [_secondLayoutManager removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:range];
    [_thirdLayoutManager removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:range];
    [_fourthLayoutManager removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:range];
}


- (void)pageRecolour
{
	[self pageRecolourTextView: [document firstTextView]];
	if (_secondLayoutManager != nil)
    {
		[self pageRecolourTextView:[document secondTextView]];
	}
	if (_thirdLayoutManager != nil)
    {
		[self pageRecolourTextView:[document thirdTextView]];
	}
	if (_fourthLayoutManager != nil)
    {
		[self pageRecolourTextView:[document fourthTextView]];
	}
}


- (void)pageRecolourTextView:(FRATextView *)textView
{
	if ([document isSyntaxColoured] == NO) {
		return;
	}
	
	if (textView == nil) {
		return;
	}
	visibleRect = [[[textView enclosingScrollView] contentView] documentVisibleRect];
	visibleRange = [[textView layoutManager] glyphRangeForBoundingRect:visibleRect inTextContainer:[textView textContainer]];
	beginningOfFirstVisibleLine = [[textView string] lineRangeForRange:NSMakeRange(visibleRange.location, 0)].location;
	endOfLastVisibleLine = NSMaxRange([completeString lineRangeForRange:NSMakeRange(NSMaxRange(visibleRange), 0)]);
	
	[self recolourRange:NSMakeRange(beginningOfFirstVisibleLine, endOfLastVisibleLine - beginningOfFirstVisibleLine)];
}


- (void)recolourRange:(NSRange)range
{
	if (_reactToChanges == NO)
    {
		return;
	}
	
	shouldOnlyColourTillTheEndOfLine = [[FRADefaults valueForKey:@"OnlyColourTillTheEndOfLine"] boolValue];
	shouldColourMultiLineStrings = [[FRADefaults valueForKey:@"ColourMultiLineStrings"] boolValue];
	
	NSRange effectiveRange = range;
    
	if (shouldColourMultiLineStrings) { // When multiline strings are coloured it needs to go backwards to find where the string might have started if it's "above" the top of the screen
		NSInteger beginFirstStringInMultiLine = [completeString rangeOfString:firstString options:NSBackwardsSearch range:NSMakeRange(0, effectiveRange.location)].location;
		if (beginFirstStringInMultiLine != NSNotFound && [[firstLayoutManager temporaryAttributesAtCharacterIndex:beginFirstStringInMultiLine effectiveRange:NULL] isEqualToDictionary:stringsColour]) {
			NSInteger startOfLine = [completeString lineRangeForRange:NSMakeRange(beginFirstStringInMultiLine, 0)].location;
			effectiveRange = NSMakeRange(startOfLine, range.length + (range.location - startOfLine));
		}
	}
	
	rangeLocation = effectiveRange.location;
	maxRange = NSMaxRange(effectiveRange);
	searchString = [completeString substringWithRange:effectiveRange];
	searchStringLength = [searchString length];
	if (searchStringLength == 0) {
		return;
	}
	scanner = [[NSScanner alloc] initWithString:searchString];
	[scanner setCharactersToBeSkipped:nil];
	completeDocumentScanner = [[NSScanner alloc] initWithString:completeString];
	[completeDocumentScanner setCharactersToBeSkipped:nil];
	
	completeStringLength = [completeString length];
	
	beginLocationInMultiLine = 0;
	
	[self removeColoursFromRange:range];
	
	
	@try {
        
        // Commands
        if (![beginCommand isEqualToString:@""] && [[FRADefaults valueForKey:@"ColourCommands"] boolValue] == YES) {
            searchSyntaxLength = [endCommand length];
            beginCommandCharacter = [beginCommand characterAtIndex:0];
            endCommandCharacter = [endCommand characterAtIndex:0];
            while (![scanner isAtEnd]) {
                [scanner scanUpToString:beginCommand intoString:nil];
                beginning = [scanner scanLocation];
                endOfLine = NSMaxRange([searchString lineRangeForRange:NSMakeRange(beginning, 0)]);
                if (![scanner scanUpToString:endCommand intoString:nil] || [scanner scanLocation] >= endOfLine) {
                    [scanner setScanLocation:endOfLine];
                    continue; // Don't colour it if it hasn't got a closing tag
                } else {
                    // To avoid problems with strings like <yada <%=yada%> yada> we need to balance the number of begin- and end-tags
                    // If ever there's a beginCommand or endCommand with more than one character then do a check first
                    commandLocation = beginning + 1;
                    skipEndCommand = 0;
                    
                    while (commandLocation < endOfLine) {
                        commandCharacterTest = [searchString characterAtIndex:commandLocation];
                        if (commandCharacterTest == endCommandCharacter) {
                            if (!skipEndCommand) {
                                break;
                            } else {
                                skipEndCommand--;
                            }
                        }
                        if (commandCharacterTest == beginCommandCharacter) {
                            skipEndCommand++;
                        }
                        commandLocation++;
                    }
                    if (commandLocation < endOfLine) {
                        [scanner setScanLocation:commandLocation + searchSyntaxLength];
                    } else {
                        [scanner setScanLocation:endOfLine];
                    }
                }
                
                [self setColour:commandsColour range:NSMakeRange(beginning + rangeLocation, [scanner scanLocation] - beginning)];
            }
        }
        
        
        // Instructions
        if (![beginInstruction isEqualToString:@""] && [[FRADefaults valueForKey:@"ColourInstructions"] boolValue] == YES) {
            // It takes too long to scan the whole document if it's large, so for instructions, first multi-line comment and second multi-line comment search backwards and begin at the start of the first beginInstruction etc. that it finds from the present position and, below, break the loop if it has passed the scanned range (i.e. after the end instruction)
            
            beginLocationInMultiLine = [completeString rangeOfString:beginInstruction options:NSBackwardsSearch range:NSMakeRange(0, rangeLocation)].location;
            endLocationInMultiLine = [completeString rangeOfString:endInstruction options:NSBackwardsSearch range:NSMakeRange(0, rangeLocation)].location;
            if (beginLocationInMultiLine == NSNotFound || (endLocationInMultiLine != NSNotFound && beginLocationInMultiLine < endLocationInMultiLine)) {
                beginLocationInMultiLine = rangeLocation;
            }
            
            searchSyntaxLength = [endInstruction length];
            while (![completeDocumentScanner isAtEnd]) {
                searchRange = NSMakeRange(beginLocationInMultiLine, range.length);
                if (NSMaxRange(searchRange) > completeStringLength) {
                    searchRange = NSMakeRange(beginLocationInMultiLine, completeStringLength - beginLocationInMultiLine);
                }
                
                beginning = [completeString rangeOfString:beginInstruction options:NSLiteralSearch range:searchRange].location;
                if (beginning == NSNotFound) {
                    break;
                }
                [completeDocumentScanner setScanLocation:beginning];
                if (![completeDocumentScanner scanUpToString:endInstruction intoString:nil] || [completeDocumentScanner scanLocation] >= completeStringLength) {
                    if (shouldOnlyColourTillTheEndOfLine) {
                        [completeDocumentScanner setScanLocation:NSMaxRange([completeString lineRangeForRange:NSMakeRange(beginning, 0)])];
                    } else {
                        [completeDocumentScanner setScanLocation:completeStringLength];
                    }
                } else {
                    if ([completeDocumentScanner scanLocation] + searchSyntaxLength <= completeStringLength) {
                        [completeDocumentScanner setScanLocation:[completeDocumentScanner scanLocation] + searchSyntaxLength];
                    }
                }
                
                [self setColour:instructionsColour range:NSMakeRange(beginning, [completeDocumentScanner scanLocation] - beginning)];
                if ([completeDocumentScanner scanLocation] > maxRange) {
                    break;
                }
                beginLocationInMultiLine = [completeDocumentScanner scanLocation];
            }
        }
        
        
        // Keywords
        if ([keywords count] != 0 && [[FRADefaults valueForKey:@"ColourKeywords"] boolValue] == YES) {
            [scanner setScanLocation:0];
            while (![scanner isAtEnd]) {
                [scanner scanUpToCharactersFromSet:keywordStartCharacterSet intoString:nil];
                beginning = [scanner scanLocation];
                if ((beginning + 1) < searchStringLength) {
                    [scanner setScanLocation:(beginning + 1)];
                }
                [scanner scanUpToCharactersFromSet:keywordEndCharacterSet intoString:nil];
                
                end = [scanner scanLocation];
                if (end > searchStringLength || beginning == end) {
                    break;
                }
                
                if (!keywordsCaseSensitive) {
                    keywordTestString = [[completeString substringWithRange:NSMakeRange(beginning + rangeLocation, end - beginning)] lowercaseString];
                } else {
                    keywordTestString = [completeString substringWithRange:NSMakeRange(beginning + rangeLocation, end - beginning)];
                }
                if ([keywords containsObject:keywordTestString]) {
                    if (!recolourKeywordIfAlreadyColoured) {
                        if ([[firstLayoutManager temporaryAttributesAtCharacterIndex:beginning + rangeLocation effectiveRange:NULL] isEqualToDictionary:commandsColour]) {
                            continue;
                        }
                    }
                    [self setColour:keywordsColour range:NSMakeRange(beginning + rangeLocation, [scanner scanLocation] - beginning)];
                }
            }
        }
		
        
        // Autocomplete
        if ([autocompleteWords count] != 0 && [[FRADefaults valueForKey:@"ColourAutocomplete"] boolValue] == YES) {
            [scanner setScanLocation:0];
            while (![scanner isAtEnd]) {
                [scanner scanUpToCharactersFromSet:keywordStartCharacterSet intoString:nil];
                beginning = [scanner scanLocation];
                if ((beginning + 1) < searchStringLength) {
                    [scanner setScanLocation:(beginning + 1)];
                }
                [scanner scanUpToCharactersFromSet:keywordEndCharacterSet intoString:nil];
                
                end = [scanner scanLocation];
                if (end > searchStringLength || beginning == end) {
                    break;
                }
                
                if (!keywordsCaseSensitive) {
                    autocompleteTestString = [[completeString substringWithRange:NSMakeRange(beginning + rangeLocation, end - beginning)] lowercaseString];
                } else {
                    autocompleteTestString = [completeString substringWithRange:NSMakeRange(beginning + rangeLocation, end - beginning)];
                }
                if ([autocompleteWords containsObject:autocompleteTestString]) {
                    if (!recolourKeywordIfAlreadyColoured) {
                        if ([[firstLayoutManager temporaryAttributesAtCharacterIndex:beginning + rangeLocation effectiveRange:NULL] isEqualToDictionary:commandsColour]) {
                            continue;
                        }
                    }
                    
                    [self setColour:autocompleteWordsColour range:NSMakeRange(beginning + rangeLocation, [scanner scanLocation] - beginning)];
                }
            }
        }
        
        
        // Variables
        if (beginVariable != nil && [[FRADefaults valueForKey:@"ColourVariables"] boolValue] == YES) {
            [scanner setScanLocation:0];
            while (![scanner isAtEnd]) {
                [scanner scanUpToCharactersFromSet:beginVariable intoString:nil];
                beginning = [scanner scanLocation];
                if (beginning + 1 < searchStringLength) {
                    if ([firstSingleLineComment isEqualToString:@"%"] && [searchString characterAtIndex:beginning + 1] == '%') { // To avoid a problem in LaTex with \%
                        if ([scanner scanLocation] < searchStringLength) {
                            [scanner setScanLocation:beginning + 1];
                        }
                        continue;
                    }
                }
                endOfLine = NSMaxRange([searchString lineRangeForRange:NSMakeRange(beginning, 0)]);
                if (![scanner scanUpToCharactersFromSet:endVariable intoString:nil] || [scanner scanLocation] >= endOfLine) {
                    [scanner setScanLocation:endOfLine];
                    length = [scanner scanLocation] - beginning;
                } else {
                    length = [scanner scanLocation] - beginning;
                    if ([scanner scanLocation] < searchStringLength) {
                        [scanner setScanLocation:[scanner scanLocation] + 1];
                    }
                }
                
                [self setColour:variablesColour range:NSMakeRange(beginning + rangeLocation, length)];
            }
        }
        
        
        // Second string, first pass
        if (![secondString isEqualToString:@""] && [[FRADefaults valueForKey:@"ColourStrings"] boolValue] == YES) {
            @try {
                secondStringMatcher = [[ICUMatcher alloc] initWithPattern:secondStringPattern overString:searchString];
            }
            @catch (NSException *exception) {
                return;
            }
            
            while ([secondStringMatcher findNext]) {
                foundRange = [secondStringMatcher rangeOfMatch];
                [self setColour:stringsColour range:NSMakeRange(foundRange.location + rangeLocation + 1, foundRange.length - 1)];
            }
        }
        
        
        // First string
        if (![firstString isEqualToString:@""] && [[FRADefaults valueForKey:@"ColourStrings"] boolValue] == YES) {
            @try {
                firstStringMatcher = [[ICUMatcher alloc] initWithPattern:firstStringPattern overString:searchString];
            }
            @catch (NSException *exception) {
                return;
            }
            
            while ([firstStringMatcher findNext]) {
                foundRange = [firstStringMatcher rangeOfMatch];
                if ([[firstLayoutManager temporaryAttributesAtCharacterIndex:foundRange.location + rangeLocation effectiveRange:NULL] isEqualToDictionary:stringsColour]) {
                    continue;
                }
                [self setColour:stringsColour range:NSMakeRange(foundRange.location + rangeLocation + 1, foundRange.length - 1)];
            }
        }
        
        
        // Attributes
        if ([[FRADefaults valueForKey:@"ColourAttributes"] boolValue] == YES) {
            [scanner setScanLocation:0];
            while (![scanner isAtEnd]) {
                [scanner scanUpToString:@" " intoString:nil];
                beginning = [scanner scanLocation];
                if (beginning + 1 < searchStringLength) {
                    [scanner setScanLocation:beginning + 1];
                } else {
                    break;
                }
                if (![[firstLayoutManager temporaryAttributesAtCharacterIndex:(beginning + rangeLocation) effectiveRange:NULL] isEqualToDictionary:commandsColour]) {
                    continue;
                }
                
                [scanner scanCharactersFromSet:attributesCharacterSet intoString:nil];
                end = [scanner scanLocation];
                
                if (end + 1 < searchStringLength) {
                    [scanner setScanLocation:[scanner scanLocation] + 1];
                }
                
                if ([completeString characterAtIndex:end + rangeLocation] == '=') {
                    [self setColour:attributesColour range:NSMakeRange(beginning + rangeLocation, end - beginning)];
                }
            }
        }
        
        
        // First single-line comment
        if (![firstSingleLineComment isEqualToString:@""] && [[FRADefaults valueForKey:@"ColourComments"] boolValue] == YES) {
            [scanner setScanLocation:0];
            searchSyntaxLength = [firstSingleLineComment length];
            while (![scanner isAtEnd]) {
                [scanner scanUpToString:firstSingleLineComment intoString:nil];
                beginning = [scanner scanLocation];
                if ([firstSingleLineComment isEqualToString:@"//"]) {
                    if (beginning > 0 && [searchString characterAtIndex:beginning - 1] == ':') {
                        [scanner setScanLocation:beginning + 1];
                        continue; // To avoid http:// ftp:// file:// etc.
                    }
                } else if ([firstSingleLineComment isEqualToString:@"#"]) {
                    if (searchStringLength > 1) {
                        rangeOfLine = [searchString lineRangeForRange:NSMakeRange(beginning, 0)];
                        if ([searchString rangeOfString:@"#!" options:NSLiteralSearch range:rangeOfLine].location != NSNotFound) {
                            [scanner setScanLocation:NSMaxRange(rangeOfLine)];
                            continue; // Don't treat the line as a comment if it begins with #!
                        } else if ([searchString characterAtIndex:beginning - 1] == '$') {
                            [scanner setScanLocation:beginning + 1];
                            continue; // To avoid $#
                        } else if ([searchString characterAtIndex:beginning - 1] == '&') {
                            [scanner setScanLocation:beginning + 1];
                            continue; // To avoid &#
                        }
                    }
                } else if ([firstSingleLineComment isEqualToString:@"%"]) {
                    if (searchStringLength > 1) {
                        if ([searchString characterAtIndex:beginning - 1] == '\\') {
                            [scanner setScanLocation:beginning + 1];
                            continue; // To avoid \% in LaTex
                        }
                    }
                }
                if (beginning + rangeLocation + searchSyntaxLength < completeStringLength) {
                    if ([[firstLayoutManager temporaryAttributesAtCharacterIndex:beginning + rangeLocation effectiveRange:NULL] isEqualToDictionary:stringsColour]) {
                        [scanner setScanLocation:beginning + 1];
                        continue; // If the comment is within a string disregard it
                    }
                }
                endOfLine = NSMaxRange([searchString lineRangeForRange:NSMakeRange(beginning, 0)]);
                [scanner setScanLocation:endOfLine];
                
                [self setColour:commentsColour range:NSMakeRange(beginning + rangeLocation, [scanner scanLocation] - beginning)];
            }
        }
        
        
        // Second single-line comment
        if (![secondSingleLineComment isEqualToString:@""] && [[FRADefaults valueForKey:@"ColourComments"] boolValue] == YES) {
            [scanner setScanLocation:0];
            searchSyntaxLength = [secondSingleLineComment length];
            while (![scanner isAtEnd]) {
                [scanner scanUpToString:secondSingleLineComment intoString:nil];
                beginning = [scanner scanLocation];
                
                if ([secondSingleLineComment isEqualToString:@"//"]) {
                    if (beginning > 0 && [searchString characterAtIndex:beginning - 1] == ':') {
                        [scanner setScanLocation:beginning + 1];
                        continue; // To avoid http:// ftp:// file:// etc.
                    }
                } else if ([secondSingleLineComment isEqualToString:@"#"]) {
                    if (searchStringLength > 1) {
                        rangeOfLine = [searchString lineRangeForRange:NSMakeRange(beginning, 0)];
                        if ([searchString rangeOfString:@"#!" options:NSLiteralSearch range:rangeOfLine].location != NSNotFound) {
                            [scanner setScanLocation:NSMaxRange(rangeOfLine)];
                            continue; // Don't treat the line as a comment if it begins with #!
                        } else if ([searchString characterAtIndex:beginning - 1] == '$') {
                            [scanner setScanLocation:beginning + 1];
                            continue; // To avoid $#
                        } else if ([searchString characterAtIndex:beginning - 1] == '&') {
                            [scanner setScanLocation:beginning + 1];
                            continue; // To avoid &#
                        }
                    }
                }
                if (beginning + rangeLocation + searchSyntaxLength < completeStringLength) {
                    if ([[firstLayoutManager temporaryAttributesAtCharacterIndex:beginning + rangeLocation effectiveRange:NULL] isEqualToDictionary:stringsColour]) {
                        [scanner setScanLocation:beginning + 1];
                        continue; // If the comment is within a string disregard it
                    }
                }
                endOfLine = NSMaxRange([searchString lineRangeForRange:NSMakeRange(beginning, 0)]);
                [scanner setScanLocation:endOfLine];
                
                [self setColour:commentsColour range:NSMakeRange(beginning + rangeLocation, [scanner scanLocation] - beginning)];
            }
        }
        
        
        // First multi-line comment
        if (![beginFirstMultiLineComment isEqualToString:@""] && [[FRADefaults valueForKey:@"ColourComments"] boolValue] == YES) {
            
            beginLocationInMultiLine = [completeString rangeOfString:beginFirstMultiLineComment options:NSBackwardsSearch range:NSMakeRange(0, rangeLocation)].location;
            endLocationInMultiLine = [completeString rangeOfString:endFirstMultiLineComment options:NSBackwardsSearch range:NSMakeRange(0, rangeLocation)].location;
            if (beginLocationInMultiLine == NSNotFound || (endLocationInMultiLine != NSNotFound && beginLocationInMultiLine < endLocationInMultiLine)) {
                beginLocationInMultiLine = rangeLocation;
            }
            [completeDocumentScanner setScanLocation:beginLocationInMultiLine];
            searchSyntaxLength = [endFirstMultiLineComment length];
            
            while (![completeDocumentScanner isAtEnd]) {
                searchRange = NSMakeRange(beginLocationInMultiLine, range.length);
                if (NSMaxRange(searchRange) > completeStringLength) {
                    searchRange = NSMakeRange(beginLocationInMultiLine, completeStringLength - beginLocationInMultiLine);
                }
                beginning = [completeString rangeOfString:beginFirstMultiLineComment options:NSLiteralSearch range:searchRange].location;
                if (beginning == NSNotFound) {
                    break;
                }
                [completeDocumentScanner setScanLocation:beginning];
                if (beginning + 1 < completeStringLength) {
                    if ([[firstLayoutManager temporaryAttributesAtCharacterIndex:beginning effectiveRange:NULL] isEqualToDictionary:stringsColour]) {
                        [completeDocumentScanner setScanLocation:beginning + 1];
                        beginLocationInMultiLine++;
                        continue; // If the comment is within a string disregard it
                    }
                }
                if (![completeDocumentScanner scanUpToString:endFirstMultiLineComment intoString:nil] || [completeDocumentScanner scanLocation] >= completeStringLength) {
                    if (shouldOnlyColourTillTheEndOfLine) {
                        [completeDocumentScanner setScanLocation:NSMaxRange([completeString lineRangeForRange:NSMakeRange(beginning, 0)])];
                    } else {
                        [completeDocumentScanner setScanLocation:completeStringLength];
                    }
                    length = [completeDocumentScanner scanLocation] - beginning;
                } else {
                    if ([completeDocumentScanner scanLocation] < completeStringLength)
                        [completeDocumentScanner setScanLocation:[completeDocumentScanner scanLocation] + searchSyntaxLength];
                    length = [completeDocumentScanner scanLocation] - beginning;
                    if ([endFirstMultiLineComment isEqualToString:@"-->"]) {
                        [completeDocumentScanner scanUpToCharactersFromSet:letterCharacterSet intoString:nil]; // Search for the first letter after -->
                        if ([completeDocumentScanner scanLocation] + 6 < completeStringLength) {// Check if there's actually room for a </script>
                            if ([completeString rangeOfString:@"</script>" options:NSCaseInsensitiveSearch range:NSMakeRange([completeDocumentScanner scanLocation] - 2, 9)].location != NSNotFound || [completeString rangeOfString:@"</style>" options:NSCaseInsensitiveSearch range:NSMakeRange([completeDocumentScanner scanLocation] - 2, 8)].location != NSNotFound) {
                                beginLocationInMultiLine = [completeDocumentScanner scanLocation];
                                continue; // If the comment --> is followed by </script> or </style> it is probably not a real comment
                            }
                        }
                        [completeDocumentScanner setScanLocation:beginning + length]; // Reset the scanner position
                    }
                }
                
                [self setColour:commentsColour range:NSMakeRange(beginning, length)];
                
                if ([completeDocumentScanner scanLocation] > maxRange) {
                    break;
                }
                beginLocationInMultiLine = [completeDocumentScanner scanLocation];
            }
        }
        
        
        // Second multi-line comment
        if (![beginSecondMultiLineComment isEqualToString:@""] && [[FRADefaults valueForKey:@"ColourComments"] boolValue] == YES) {
            
            beginLocationInMultiLine = rangeLocation;
            [completeDocumentScanner setScanLocation:beginLocationInMultiLine];
            searchSyntaxLength = [endSecondMultiLineComment length];
            
            while (![completeDocumentScanner isAtEnd]) {
                searchRange = NSMakeRange(beginLocationInMultiLine, range.length);
                if (NSMaxRange(searchRange) > completeStringLength) {
                    searchRange = NSMakeRange(beginLocationInMultiLine, completeStringLength - beginLocationInMultiLine);
                }
                beginning = [completeString rangeOfString:beginSecondMultiLineComment options:NSLiteralSearch range:searchRange].location;
                if (beginning == NSNotFound) {
                    break;
                }
                [completeDocumentScanner setScanLocation:beginning];
                if (beginning + 1 < completeStringLength) {
                    if ([[firstLayoutManager temporaryAttributesAtCharacterIndex:beginning effectiveRange:NULL] isEqualToDictionary:stringsColour]) {
                        [completeDocumentScanner setScanLocation:beginning + 1];
                        beginLocationInMultiLine++;
                        continue; // If the comment is within a string disregard it
                    }
                }
                
                if (![completeDocumentScanner scanUpToString:endSecondMultiLineComment intoString:nil] || [completeDocumentScanner scanLocation] >= completeStringLength) {
                    if (shouldOnlyColourTillTheEndOfLine) {
                        [completeDocumentScanner setScanLocation:NSMaxRange([completeString lineRangeForRange:NSMakeRange(beginning, 0)])];
                    } else {
                        [completeDocumentScanner setScanLocation:completeStringLength];
                    }
                    length = [completeDocumentScanner scanLocation] - beginning;
                } else {
                    if ([completeDocumentScanner scanLocation] < completeStringLength)
                        [completeDocumentScanner setScanLocation:[completeDocumentScanner scanLocation] + searchSyntaxLength];
                    length = [completeDocumentScanner scanLocation] - beginning;
                    if ([endSecondMultiLineComment isEqualToString:@"-->"]) {
                        [completeDocumentScanner scanUpToCharactersFromSet:letterCharacterSet intoString:nil]; // Search for the first letter after -->
                        if ([completeDocumentScanner scanLocation] + 6 < completeStringLength) { // Check if there's actually room for a </script>
                            if ([completeString rangeOfString:@"</script>" options:NSCaseInsensitiveSearch range:NSMakeRange([completeDocumentScanner scanLocation] - 2, 9)].location != NSNotFound || [completeString rangeOfString:@"</style>" options:NSCaseInsensitiveSearch range:NSMakeRange([completeDocumentScanner scanLocation] - 2, 8)].location != NSNotFound) {
                                beginLocationInMultiLine = [completeDocumentScanner scanLocation];
                                continue; // If the comment --> is followed by </script> or </style> it is probably not a real comment
                            }
                        }
                        [completeDocumentScanner setScanLocation:beginning + length]; // Reset the scanner position
                    }
                }
                [self setColour:commentsColour range:NSMakeRange(beginning, length)];
                
                if ([completeDocumentScanner scanLocation] > maxRange) {
                    break;
                }
                beginLocationInMultiLine = [completeDocumentScanner scanLocation];
            }
        }
        
        
        // Second string, second pass
        if (![secondString isEqualToString:@""] && [[FRADefaults valueForKey:@"ColourStrings"] boolValue] == YES) {
            @try {
                [secondStringMatcher reset];
            }
            @catch (NSException *exception) {
                return;
            }
            
            while ([secondStringMatcher findNext]) {
                foundRange = [secondStringMatcher rangeOfMatch];
                if ([[firstLayoutManager temporaryAttributesAtCharacterIndex:foundRange.location + rangeLocation effectiveRange:NULL] isEqualToDictionary:stringsColour] || [[firstLayoutManager temporaryAttributesAtCharacterIndex:foundRange.location + rangeLocation effectiveRange:NULL] isEqualToDictionary:commentsColour]) {
                    continue;
                }
                [self setColour:stringsColour range:NSMakeRange(foundRange.location + rangeLocation + 1, foundRange.length - 1)];
            }
        }
        
	}
	@catch (NSException *exception) {
		//Log(exception);
	}
	
}


- (void)setColour:(NSDictionary *)colourDictionary range:(NSRange)range
{
	[firstLayoutManager setTemporaryAttributes:colourDictionary forCharacterRange:range];
    
    [_secondLayoutManager setTemporaryAttributes:colourDictionary forCharacterRange:range];
    [_thirdLayoutManager setTemporaryAttributes:colourDictionary forCharacterRange:range];
    [_fourthLayoutManager setTemporaryAttributes:colourDictionary forCharacterRange:range];
}


- (void)highlightLineRange:(NSRange)lineRange
{
	if (lineRange.location == lastLineHighlightRange.location && lineRange.length == lastLineHighlightRange.length) {
		return;
	}
	
	[firstLayoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:lastLineHighlightRange];
    
    [_secondLayoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:lastLineHighlightRange];
    
    [_thirdLayoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:lastLineHighlightRange];
    [_fourthLayoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:lastLineHighlightRange];
	
	[self pageRecolour];
	
	[firstLayoutManager addTemporaryAttributes:lineHighlightColour forCharacterRange:lineRange];

    [_secondLayoutManager addTemporaryAttributes:lineHighlightColour forCharacterRange:lineRange];

    [_thirdLayoutManager addTemporaryAttributes:lineHighlightColour forCharacterRange:lineRange];
    [_fourthLayoutManager addTemporaryAttributes:lineHighlightColour forCharacterRange:lineRange];
	
	lastLineHighlightRange = lineRange;
}


#pragma mark -
#pragma mark Delegates

- (void)textDidChange:(NSNotification *)notification
{
	if (_reactToChanges == NO)
    {
		return;
	}
	
	if ([completeString length] < 2) {
		[FRAInterface updateStatusBar]; // One needs to call this from here as well because otherwise it won't update the status bar if one writes one character and deletes it in an empty document, because the textViewDidChangeSelection delegate method won't be called.
	}
	
	FRATextView *textView = (FRATextView *)[notification object];
	
	if ([document isEdited] == NO) {
		[FRAVarious hasChangedDocument:document];
	}
	
	if ([[FRADefaults valueForKey:@"HighlightCurrentLine"] boolValue] == YES) {
		[self highlightLineRange:[completeString lineRangeForRange:[textView selectedRange]]];
	} else if ([document isSyntaxColoured])
    {
		[self pageRecolourTextView:textView];
	}
	
	if (autocompleteWordsTimer != nil) {
		[autocompleteWordsTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:[[FRADefaults valueForKey:@"AutocompleteAfterDelay"] doubleValue]]];
	} else if ([[FRADefaults valueForKey:@"AutocompleteSuggestAutomatically"] boolValue] == YES) {
		autocompleteWordsTimer = [NSTimer scheduledTimerWithTimeInterval:[[FRADefaults valueForKey:@"AutocompleteAfterDelay"] doubleValue] target:self selector:@selector(autocompleteWordsTimerSelector:) userInfo:textView repeats:NO];
	}
	
	if (liveUpdatePreviewTimer != nil) {
		[liveUpdatePreviewTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:[[FRADefaults valueForKey:@"LiveUpdatePreviewDelay"] doubleValue]]];
	} else if ([[FRADefaults valueForKey:@"LiveUpdatePreview"] boolValue] == YES) {
		liveUpdatePreviewTimer = [NSTimer scheduledTimerWithTimeInterval:[[FRADefaults valueForKey:@"LiveUpdatePreviewDelay"] doubleValue] target:self selector:@selector(liveUpdatePreviewTimerSelector:) userInfo:textView repeats:NO];
	}
	
	[[document lineNumbers] updateLineNumbersCheckWidth: NO];
}


- (void)textViewDidChangeSelection:(NSNotification *)aNotification
{
	if (_reactToChanges == NO)
    {
		return;
	}
	
	completeStringLength = [completeString length];
	if (completeStringLength == 0) {
		return;
	}
	
	FRATextView *textView = [aNotification object];
	[FRACurrentProject setLastTextViewInFocus:textView];
	
	[FRAInterface updateStatusBar];
	
	editedRange = [textView selectedRange];
	
	if ([[FRADefaults valueForKey:@"HighlightCurrentLine"] boolValue] == YES) {
		[self highlightLineRange:[completeString lineRangeForRange:editedRange]];
	}
	
	if ([[FRADefaults valueForKey:@"ShowMatchingBraces"] boolValue] == NO) {
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


- (NSArray *)textView:theTextView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
{
	if ([keywordsAndAutocompleteWords count] == 0) {
		if ([[FRADefaults valueForKey:@"AutocompleteIncludeStandardWords"] boolValue] == NO) {
			return @[];
		} else {
			return words;
		}
	}
	
	NSString *matchString = [[theTextView string] substringWithRange:charRange];
	NSMutableArray *finalWordsArray = [NSMutableArray arrayWithArray:keywordsAndAutocompleteWords];
	if ([[FRADefaults valueForKey:@"AutocompleteIncludeStandardWords"] boolValue]) {
		[finalWordsArray addObjectsFromArray:words];
	}
	
	NSMutableArray *matchArray = [NSMutableArray array];
	NSString *item;
	for (item in finalWordsArray) {
		if ([item rangeOfString:matchString options:NSCaseInsensitiveSearch range:NSMakeRange(0, [item length])].location == 0) {
			[matchArray addObject:item];
		}
	}
	
	if ([[FRADefaults valueForKey:@"AutocompleteIncludeStandardWords"] boolValue]) { // If no standard words are added there's no need to sort it again as it has already been sorted
		return [matchArray sortedArrayUsingSelector:@selector(compare:)];
	} else {
		return matchArray;
	}
}


#pragma mark -
#pragma mark Other
- (NSString *)guessSyntaxDefinitionFromFirstLine:(NSString *)firstLine
{
	NSString *returnString;
	NSRange firstLineRange = NSMakeRange(0, [firstLine length]);
	if ([firstLine rangeOfString:@"perl" options:NSCaseInsensitiveSearch range:firstLineRange].location != NSNotFound) {
		returnString = @"pl";
	} else if ([firstLine rangeOfString:@"wish" options:NSCaseInsensitiveSearch range:firstLineRange].location != NSNotFound) {
		returnString = @"tcl";
	} else if ([firstLine rangeOfString:@"sh" options:NSCaseInsensitiveSearch range:firstLineRange].location != NSNotFound) {
		returnString = @"sh";
	} else if ([firstLine rangeOfString:@"php" options:NSCaseInsensitiveSearch range:firstLineRange].location != NSNotFound) {
		returnString = @"php";
	} else if ([firstLine rangeOfString:@"python" options:NSCaseInsensitiveSearch range:firstLineRange].location != NSNotFound) {
		returnString = @"py";
	} else if ([firstLine rangeOfString:@"awk" options:NSCaseInsensitiveSearch range:firstLineRange].location != NSNotFound) {
		returnString = @"awk";
	} else if ([firstLine rangeOfString:@"xml" options:NSCaseInsensitiveSearch range:firstLineRange].location != NSNotFound) {
		returnString = @"xml";
	} else if ([firstLine rangeOfString:@"ruby" options:NSCaseInsensitiveSearch range:firstLineRange].location != NSNotFound) {
		returnString = @"rb";
	} else if ([firstLine rangeOfString:@"%!ps" options:NSCaseInsensitiveSearch range:firstLineRange].location != NSNotFound) {
		returnString = @"ps";
	} else if ([firstLine rangeOfString:@"%pdf" options:NSCaseInsensitiveSearch range:firstLineRange].location != NSNotFound) {
		returnString = @"pdf";
	} else {
		returnString = @"";
	}
	
	return returnString;
}


- (void)checkIfCanUndo
{
	if (![undoManager canUndo])
    {
		[FRACurrentDocument setEdited: NO];
		[FRACurrentProject updateEditedBlobStatus];
		[FRACurrentProject reloadData];
	}
}


- (void)autocompleteWordsTimerSelector:(NSTimer *)theTimer
{
	FRATextView *textView = [theTimer userInfo];
	selectedRange = [textView selectedRange];
	stringLength = [completeString length];
	if (selectedRange.location <= stringLength && selectedRange.length == 0 && stringLength != 0) {
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
	if ([[FRADefaults valueForKey:@"LiveUpdatePreview"] boolValue] == YES) {
		[[FRAPreviewController sharedInstance] liveUpdate];
	}
	
	if (liveUpdatePreviewTimer) {
		[liveUpdatePreviewTimer invalidate];
		liveUpdatePreviewTimer = nil;
	}
}


@end