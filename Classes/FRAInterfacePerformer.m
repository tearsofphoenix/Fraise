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

#import "FRAInterfacePerformer.h"
#import "FRATextView.h"
#import "FRATextMenuController.h"
#import "FRAProjectsController.h"

#import "FRASingleDocumentWindowDelegate.h"
#import "FRAAdvancedFindController.h"
#import "FRABasicPerformer.h"
#import "FRAMainController.h"
#import "FRAProject.h"
#import "FRASyntaxColouring.h"
#import "FRAFullScreenWindow.h"

#import "VADocument.h"

#import <VAFoundation/VAFoundation.h>
#import <VADevUIKit/VADevUIKit.h>

@implementation FRAInterfacePerformer

@synthesize fullScreenWindow, fullScreenDocument, defaultIcon, defaultUnsavedIcon;

VASingletonIMPDefault(FRAInterfacePerformer)

- (id)init 
{
    if ((self = [super init]))
    {
        [VIGutterTextView setDefaultFont: [NSUnarchiver unarchiveObjectWithData: [FRADefaults valueForKey: @"TextFont"]]];
        
		statusBarBetweenString = [[NSString alloc] initWithFormat:@"  %C  ", 0x00B7];
		statusBarLastSavedString = NSLocalizedString(@"Saved", @"Saved, in the status bar");
		statusBarDocumentLengthString = NSLocalizedString(@"Length", @"Length, in the status bar");
		statusBarSelectionLengthString = NSLocalizedString(@"Selection", @"Selection, in the status bar");
		statusBarPositionString = NSLocalizedString(@"Position", @"Position, in the status bar");
		statusBarSyntaxDefinitionString = NSLocalizedString(@"Syntax", @"Syntax, in the status bar");
		statusBarEncodingString = NSLocalizedString(@"Encoding", @"Encoding, in the status bar");		
    }
    return self;
}


- (void)goToFunctionOnLine:(id)sender
{
	NSInteger lineToGoTo = [sender tag];
	[[FRATextMenuController sharedInstance] performGoToLine:lineToGoTo];
}





- (void)insertDocumentIntoSecondContentView:(VADocument *)document
{
	[FRACurrentProject setSecondDocument:document];
	NSView *secondContentView = [FRACurrentProject secondContentView];
	[self removeAllSubviewsFromView:secondContentView];
	
	NSTextStorage *textStorage = [[[document firstTextScrollView] documentView] textStorage];
    
    NSDictionary *attributes = (@{
                                  NSFontAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextFont"]],
                                  NSForegroundColorAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"InvisibleCharactersColourWell"]]
                                  });
    BOOL showInvisibleCharacters = [[FRADefaults valueForKey:@"ShowInvisibleCharacters"] boolValue];
    
	VILayoutManager *layoutManager = [[VILayoutManager alloc] init];
    [layoutManager setAttributes: attributes];
    [layoutManager setShowInvisibleCharacters: showInvisibleCharacters];
    
	[textStorage addLayoutManager: layoutManager];
	[[document syntaxColouring] setSecondLayoutManager:layoutManager];
	
	u_int16_t gutterWidth = [[document firstGutterScrollView] bounds].size.width;
	
	NSView *secondContentViewNavigationBar = [FRACurrentProject secondContentViewNavigationBar];
	CGFloat secondContentViewNavigationBarHeight = [secondContentViewNavigationBar bounds].size.height;
	
	VIScrollView *textScrollView = [[VIScrollView alloc] initWithFrame:NSMakeRect(gutterWidth, secondContentViewNavigationBarHeight, [secondContentView bounds].size.width - gutterWidth, [secondContentView bounds].size.height - secondContentViewNavigationBarHeight - secondContentViewNavigationBarHeight)];
	NSSize contentSize = [textScrollView contentSize];
	
	NSTextContainer *container = [[NSTextContainer alloc] initWithContainerSize:contentSize];
	[layoutManager addTextContainer:container];
		
	[[NSNotificationCenter defaultCenter] addObserver:[document lineNumbers] selector:@selector(viewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[textScrollView contentView]];
	
	FRATextView *textView;
	if ([document isLineWrapped] == YES) {
		textView = [[FRATextView alloc] initWithFrame:NSMakeRect(gutterWidth, 0, contentSize.width - 2, contentSize.height) textContainer:container]; // - 2 to remove slight movement left and right
		[textView setMinSize:contentSize];
		[textScrollView setHasHorizontalScroller:NO];
		[textView setHorizontallyResizable:NO];
		[[textView textContainer] setWidthTracksTextView:YES];
		[[textView textContainer] setContainerSize:NSMakeSize(contentSize.width, CGFLOAT_MAX)];		 
	} else {
		textView = [[FRATextView alloc] initWithFrame:NSMakeRect(gutterWidth, 0, contentSize.width, contentSize.height) textContainer:container];
		[textView setMinSize:contentSize];
		[textScrollView setHasHorizontalScroller:YES];
		[textView setHorizontallyResizable:YES];
		[[textView textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
		[[textView textContainer] setWidthTracksTextView:NO];
	}
	[textView setDefaults];
	
	[textScrollView setDocumentView:textView];
	
	NSScrollView *gutterScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, secondContentViewNavigationBarHeight, gutterWidth, contentSize.height)];
	[gutterScrollView setBorderType:NSNoBorder];
	[gutterScrollView setHasVerticalScroller:NO];
	[gutterScrollView setHasHorizontalScroller:NO];
	[gutterScrollView setAutoresizingMask:NSViewHeightSizable];
	[[gutterScrollView contentView] setAutoresizesSubviews:YES];
	
	VIGutterTextView *gutterTextView = [[VIGutterTextView alloc] initWithFrame:NSMakeRect(0, secondContentViewNavigationBarHeight, gutterWidth, contentSize.height)];
	[gutterScrollView setDocumentView:gutterTextView];
	
	[secondContentView addSubview:textScrollView];
	
	[textView setDelegate:[document syntaxColouring]];
    
    [textScrollView setGutterScrollView: gutterScrollView];
    
    [[document lineNumbers] addScrollView: textScrollView];

	[document setSecondTextView: textView];
	[document setSecondTextScrollView: textScrollView];
	[document setSecondGutterScrollView: gutterScrollView];
	
	[secondContentViewNavigationBar setFrame:NSMakeRect(0, 0, [secondContentView bounds].size.width, secondContentViewNavigationBarHeight)];
	[secondContentViewNavigationBar setAutoresizingMask:NSViewWidthSizable];
	[secondContentView addSubview:secondContentViewNavigationBar];
	
	NSRect visibleRect = [[[[document firstTextView] enclosingScrollView] contentView] documentVisibleRect];
	NSRange visibleRange = [[[document firstTextView] layoutManager] glyphRangeForBoundingRect:visibleRect inTextContainer:[[document firstTextView] textContainer]];
	[textView scrollRangeToVisible:visibleRange];
	
	[FRACurrentProject resizeViewsForDocument:document]; // To properly set the width of the line number gutter and to recolour the document
}


- (void)insertDocumentIntoThirdContentView:(id)document orderFront:(BOOL)orderFront
{
	if ([document singleDocumentWindow] != nil) {
		[[document singleDocumentWindow] makeKeyAndOrderFront:nil];
		return;
	}
	
	NSWindowController *windowController = [[NSWindowController alloc] initWithWindowNibName:@"FRASingleDocument"];
	
	NSWindow *window = [windowController window];
	
	if ([FRADefaults valueForKey:@"SingleDocumentWindow"] != nil) {
		[window setFrame:NSRectFromString([FRADefaults valueForKey:@"SingleDocumentWindow"]) display:NO animate:NO];
	}
	
	if (orderFront == YES) {
		[window makeKeyAndOrderFront:nil];
	}
	
	NSView *thirdContentView = [window contentView];
	
	NSTextStorage *textStorage = [[[document firstTextScrollView] documentView] textStorage];
    
    NSDictionary *attributes = (@{
                                  NSFontAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextFont"]],
                                  NSForegroundColorAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"InvisibleCharactersColourWell"]]
                                  });
    BOOL showInvisibleCharacters = [[FRADefaults valueForKey:@"ShowInvisibleCharacters"] boolValue];
    
	VILayoutManager *layoutManager = [[VILayoutManager alloc] init];
    [layoutManager setAttributes: attributes];
    [layoutManager setShowInvisibleCharacters: showInvisibleCharacters];
    
	[textStorage addLayoutManager:layoutManager];
	[[document syntaxColouring] setThirdLayoutManager:layoutManager];
	
	u_int16_t gutterWidth = [[document firstGutterScrollView] bounds].size.width;	
	
	VIScrollView *textScrollView = [[VIScrollView alloc] initWithFrame:NSMakeRect(gutterWidth, -1, [thirdContentView bounds].size.width - gutterWidth, [thirdContentView bounds].size.height + 2)]; // +2 and -1 to remove extra line at the top and bottom
	NSSize contentSize = [textScrollView contentSize];
	NSTextContainer *container = [[NSTextContainer alloc] initWithContainerSize:contentSize];
	[layoutManager addTextContainer:container];

	[[NSNotificationCenter defaultCenter] addObserver:[document lineNumbers] selector:@selector(viewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[textScrollView contentView]];
	
	FRATextView *textView;
	if ([document isLineWrapped] == YES) {
		textView = [[FRATextView alloc] initWithFrame:NSMakeRect(gutterWidth, 0, contentSize.width, contentSize.height) textContainer:container];
		[textView setMinSize:contentSize];
		[textScrollView setHasHorizontalScroller:NO];
		[textView setHorizontallyResizable:NO];
		[[textView textContainer] setWidthTracksTextView:YES];
		[[textView textContainer] setContainerSize:NSMakeSize(contentSize.width, CGFLOAT_MAX)];		 
	} else {
		textView = [[FRATextView alloc] initWithFrame:NSMakeRect(gutterWidth, 0, contentSize.width, contentSize.height) textContainer:container];
		[textView setMinSize:contentSize];
		[textScrollView setHasHorizontalScroller:YES];
		[textView setHorizontallyResizable:YES];
		[[textView textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
		[[textView textContainer] setWidthTracksTextView:NO];
	}
	[textView setDefaults];
	
	[textScrollView setDocumentView:textView];
	
	NSScrollView *gutterScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, -1, gutterWidth, contentSize.height)];
	[gutterScrollView setBorderType:NSNoBorder];
	[gutterScrollView setHasVerticalScroller:NO];
	[gutterScrollView setHasHorizontalScroller:NO];
	[gutterScrollView setAutoresizingMask:NSViewHeightSizable];
	[[gutterScrollView contentView] setAutoresizesSubviews:YES];
	
	VIGutterTextView *gutterTextView = [[VIGutterTextView alloc] initWithFrame:NSMakeRect(0, 0, gutterWidth, contentSize.height)];
	[gutterScrollView setDocumentView:gutterTextView];
	
	[thirdContentView addSubview:textScrollView];
	
    [textScrollView setGutterScrollView: gutterScrollView];
    [[document lineNumbers] addScrollView: textScrollView];

	[textView setDelegate:[document syntaxColouring]];
	[document setThirdTextView: textView];
	[document setThirdTextScrollView: textScrollView];
	[document setThirdGutterScrollView: gutterScrollView];
    
	[document setSingleDocumentWindow: window];
	[document setSingleDocumentWindowController: windowController];
	
	[FRACurrentProject resizeViewsForDocument:document]; // To properly set the width of the line number gutter and to recolour the document
	
	[window setDelegate:[FRASingleDocumentWindowDelegate sharedInstance]];
	[window makeFirstResponder:textView];
}


- (void)insertDocumentIntoFourthContentView:(id)document
{	
	NSTextStorage *textStorage = [[[document firstTextScrollView] documentView] textStorage];
    
    NSDictionary *attributes = (@{
                                  NSFontAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextFont"]],
                                  NSForegroundColorAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"InvisibleCharactersColourWell"]]
                                  });
    BOOL showInvisibleCharacters = [[FRADefaults valueForKey:@"ShowInvisibleCharacters"] boolValue];
    
	VILayoutManager *layoutManager = [[VILayoutManager alloc] init];
    [layoutManager setAttributes: attributes];
    [layoutManager setShowInvisibleCharacters: showInvisibleCharacters];
    
	[textStorage addLayoutManager:layoutManager];
	[[document syntaxColouring] setFourthLayoutManager:layoutManager];
	
	u_int16_t gutterWidth = [[document firstGutterScrollView] bounds].size.width;
	
	NSView *fourthContentView = [[FRAAdvancedFindController sharedInstance] resultDocumentContentView];
	
	VIScrollView *textScrollView = [[VIScrollView alloc] initWithFrame:NSMakeRect(gutterWidth, 0, [fourthContentView bounds].size.width - gutterWidth, [fourthContentView bounds].size.height)];
	NSSize contentSize = [textScrollView contentSize];
	
	NSTextContainer *container = [[NSTextContainer alloc] initWithContainerSize:contentSize];
	[layoutManager addTextContainer:container];
		
	[[NSNotificationCenter defaultCenter] addObserver:[document lineNumbers] selector:@selector(viewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[textScrollView contentView]];
	
	FRATextView *textView;
	if ([document isLineWrapped] == YES) {
		textView = [[FRATextView alloc] initWithFrame:NSMakeRect(gutterWidth, 0, contentSize.width, contentSize.height) textContainer:container];
		[textView setMinSize:contentSize];
		[textScrollView setHasHorizontalScroller:NO];
		[textView setHorizontallyResizable:NO];
		[[textView textContainer] setWidthTracksTextView:YES];
		[[textView textContainer] setContainerSize:NSMakeSize(contentSize.width, CGFLOAT_MAX)];		 
	} else {
		textView = [[FRATextView alloc] initWithFrame:NSMakeRect(gutterWidth, 0, contentSize.width, contentSize.height) textContainer:container];
		[textView setMinSize:contentSize];
		[textScrollView setHasHorizontalScroller:YES];
		[textView setHorizontallyResizable:YES];
		[[textView textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
		[[textView textContainer] setWidthTracksTextView:NO];
	}
	[textView setDefaults];
	
	[textScrollView setDocumentView:textView];
    [[document lineNumbers] addScrollView: textScrollView];

	NSScrollView *gutterScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, gutterWidth, contentSize.height)];
	[gutterScrollView setBorderType:NSNoBorder];
	[gutterScrollView setHasVerticalScroller:NO];
	[gutterScrollView setHasHorizontalScroller:NO];
	[gutterScrollView setAutoresizingMask:NSViewHeightSizable];
	[[gutterScrollView contentView] setAutoresizesSubviews:YES];
	
	VIGutterTextView *gutterTextView = [[VIGutterTextView alloc] initWithFrame:NSMakeRect(0, 0, gutterWidth, contentSize.height)];
	[gutterScrollView setDocumentView:gutterTextView];
	
	[fourthContentView addSubview:textScrollView];
    
	[textScrollView setGutterScrollView: gutterScrollView];
	
    [textView setDelegate:[document syntaxColouring]];
	[document setFourthTextView: textView];
	[document setFourthTextScrollView: textScrollView];
	[document setFourthGutterScrollView: gutterScrollView];
}

/**
 * Update gutter views to adjust its size to newly defined width for the specified
 * document. It refreshes every views used to display the document afterwards.
 **/
- (void) updateGutterViewForDocument:(id)document {
	NSArray *viewNumbers = @[@"first",@"second", @"third"];
	NSView *contentView = nil;
	u_int16_t gutterWidth = [[FRADefaults valueForKey:@"GutterWidth"] integerValue];
	NSRect frame;
	
	// Update document value first.
	[document setGutterWidth: gutterWidth];
	
	for (NSString* viewNumber in viewNumbers) {
		NSScrollView *gutterScrollView = (NSScrollView *) [document valueForKey:[NSString stringWithFormat:@"%@GutterScrollView", viewNumber]];
		NSTextView *textView = (NSTextView *)[document valueForKey:[NSString stringWithFormat:@"%@TextView", viewNumber]];
		NSScrollView *textScrollView = (NSScrollView *)[document valueForKey:[NSString stringWithFormat:@"%@TextScrollView", viewNumber]];
		
		if ([viewNumber isEqualToString:@"first"]) {
			contentView = [FRACurrentProject firstContentView];
		}
		else if ([viewNumber isEqualToString:@"second"]) {
			contentView = [FRACurrentProject secondContentView];
		}
		else if ([viewNumber isEqualToString:@"third"]) {
			if ([document singleDocumentWindow] == nil) {
				continue;
			}
			contentView = [[document singleDocumentWindow] contentView];
		}
				   
		// Text Scroll View
		if (textScrollView != nil) {
			frame = [textScrollView frame];
			[textScrollView setFrame:NSMakeRect(gutterWidth, frame.origin.y, [contentView bounds].size.width - gutterWidth, frame.size.height)];
			[textScrollView setNeedsDisplay:YES];
		}
		
		// Text View
		if (textView != nil) {
			frame = [textView frame];
			[textView setFrame:NSMakeRect(gutterWidth, frame.origin.y, [contentView bounds].size.width - gutterWidth, frame.size.height)];
			[textView setNeedsDisplay:YES];
		}
		
		// Gutter Scroll View
		if (gutterScrollView != nil) {
			frame = [gutterScrollView frame];
			[gutterScrollView setFrame:NSMakeRect(frame.origin.x, frame.origin.y, gutterWidth, frame.size.height)];
			[gutterScrollView setNeedsDisplay:YES];
		}
	}
}


- (void) updateStatusBar
{
	if ([[FRADefaults valueForKey:@"ShowStatusBar"] boolValue] == NO) {
		return;
	}
	
	NSMutableString *statusBarString = [NSMutableString string];
	id document = [FRAProjectsController currentDocument];
	FRATextView *textView = FRACurrentTextView;
	NSString *text = FRACurrentText;
	
	if ([[FRADefaults valueForKey:@"StatusBarShowWhenLastSaved"] boolValue] == YES)
		[statusBarString appendFormat:@"%@: %@", statusBarLastSavedString, [document lastSaved]];
	
	if ([[FRADefaults valueForKey:@"StatusBarShowLength"] boolValue] == YES) {
		if ([[FRADefaults valueForKey:@"StatusBarShowWhenLastSaved"] boolValue] == YES) {
			[statusBarString appendString:statusBarBetweenString];
		}
		
		[statusBarString appendFormat:@"%@: %@", statusBarDocumentLengthString, [FRABasic thousandFormatedStringFromNumber:@([text length])]];
	}
	
	NSArray *array = [textView selectedRanges];
	NSInteger selection = 0;
	for (id item in array) {
		selection = selection + [item rangeValue].length;
	}
	if ([[FRADefaults valueForKey:@"StatusBarShowSelection"] boolValue] == YES && selection > 1) {
		if ([[FRADefaults valueForKey:@"StatusBarShowWhenLastSaved"] boolValue] == YES || [[FRADefaults valueForKey:@"StatusBarShowLength"] boolValue] == YES) {
			[statusBarString appendString:statusBarBetweenString];
		}
		[statusBarString appendFormat:@"%@: %@", statusBarSelectionLengthString, [FRABasic thousandFormatedStringFromNumber:@(selection)]];
	}
	
	if ([[FRADefaults valueForKey:@"StatusBarShowPosition"] boolValue] == YES) {
		if ([[FRADefaults valueForKey:@"StatusBarShowWhenLastSaved"] boolValue] == YES || [[FRADefaults valueForKey:@"StatusBarShowLength"] boolValue] == YES || ([[FRADefaults valueForKey:@"StatusBarShowSelection"] boolValue] == YES && selection > 1)) {
			[statusBarString appendString:statusBarBetweenString];
		}
		NSRange selectionRange;
		if (textView == nil) {
			selectionRange = NSMakeRange(0,0);
		} else {
			selectionRange = [textView selectedRange];
		}
		[statusBarString appendFormat:@"%@: %@\\%@", statusBarPositionString, [FRABasic thousandFormatedStringFromNumber: @((selectionRange.location - [text lineRangeForRange:selectionRange].location))], [FRABasic thousandFormatedStringFromNumber: @(selectionRange.location)]];
	}
	
	if ([[FRADefaults valueForKey:@"StatusBarShowEncoding"] boolValue] == YES) {
		if ([[FRADefaults valueForKey:@"StatusBarShowWhenLastSaved"] boolValue] == YES || [[FRADefaults valueForKey:@"StatusBarShowLength"] boolValue] == YES || ([[FRADefaults valueForKey:@"StatusBarShowSelection"] boolValue] == YES && selection > 1) || [[FRADefaults valueForKey:@"StatusBarShowPosition"] boolValue] == YES) {
			[statusBarString appendString:statusBarBetweenString];
		}
		[statusBarString appendFormat:@"%@: %@", statusBarEncodingString, [document encodingName]];
	}
	
	if ([[FRADefaults valueForKey:@"StatusBarShowSyntax"] boolValue] == YES && [document isSyntaxColoured]) {
		if ([[FRADefaults valueForKey:@"StatusBarShowWhenLastSaved"] boolValue] == YES || ([[FRADefaults valueForKey:@"StatusBarShowSelection"] boolValue] == YES && selection > 1) || [[FRADefaults valueForKey:@"StatusBarShowPosition"] boolValue] == YES || [[FRADefaults valueForKey:@"StatusBarShowEncoding"] boolValue] == YES) {
			[statusBarString appendString:statusBarBetweenString];
		}
		[statusBarString appendFormat:@"%@: %@", statusBarSyntaxDefinitionString, [document syntaxDefinition]];
	}
	
	[[FRACurrentProject statusBarTextField] setStringValue:statusBarString];
}


- (void)clearStatusBar
{
	[[FRACurrentProject statusBarTextField] setObjectValue:@""];
}


- (NSString *)whichDirectoryForOpen
{
	NSString *directory;
	
    if ([[FRADefaults valueForKey:@"OpenMatrix"] integerValue] == FRAOpenSaveRemember)
    {
		directory = [FRADefaults valueForKey:@"LastOpenDirectory"];
	} else if ([[FRADefaults valueForKey:@"OpenMatrix"] integerValue] == FRAOpenSaveCurrent)
    {
		if ([FRACurrentProject areThereAnyDocuments] == YES)
        {
			directory = [[[FRAProjectsController currentDocument] path] stringByDeletingLastPathComponent]; 
		} else
        {
			directory = NSHomeDirectory();
		}
	} else
    {
		directory = [FRADefaults valueForKey:@"OpenAlwaysUseTextField"];
	}
	
    if (!directory)
    {
        directory = NSHomeDirectory();
    }
    
	return [directory stringByExpandingTildeInPath];
}


- (NSString *)whichDirectoryForSave
{
	NSString *directory;
	if ([[FRADefaults valueForKey:@"SaveMatrix"] integerValue] == FRAOpenSaveRemember) {
		directory = [FRADefaults valueForKey:@"LastSaveAsDirectory"];
	} else if ([[FRADefaults valueForKey:@"SaveMatrix"] integerValue] == FRAOpenSaveCurrent) {
		if ([[FRAProjectsController currentDocument] isNewDocument] == NO) {
			directory = [[[FRAProjectsController currentDocument] path] stringByDeletingLastPathComponent];
		} else { 
			directory = NSHomeDirectory();
		}
	} else {
		directory = [FRADefaults valueForKey:@"SaveAsAlwaysUseTextField"];
	}

	return [directory stringByExpandingTildeInPath];
}


- (void)removeAllSubviewsFromView:(NSView *)view
{
	[view setSubviews:@[]];
	//NSArray *array = [NSArray arrayWithArray:[view subviews]];
//	id item;
//	for (item in array) {
//		[item removeFromSuperview];
//		item = nil;
//	}
}


- (void)enterFullScreenForDocument:(VADocument *)document
{
	savedMainMenu = [NSApp mainMenu];
	
	fullScreenRect = [[NSScreen mainScreen] frame];	
	CGFloat width;
	if ([FRAMain singleDocumentWindowWasOpenBeforeEnteringFullScreen] == YES) {
		width = [[document thirdTextView] bounds].size.width * [[NSScreen mainScreen] userSpaceScaleFactor];
	} else {
		width = [[document firstTextView] bounds].size.width * [[NSScreen mainScreen] userSpaceScaleFactor];
	}
	fullScreenRect = NSMakeRect(fullScreenRect.origin.x - ((width - fullScreenRect.size.width + [document gutterWidth]) / 2), fullScreenRect.origin.y, width + [document gutterWidth], fullScreenRect.size.height);

	fullScreenWindow = [[FRAFullScreenWindow alloc] initWithContentRect:[[NSScreen mainScreen] frame] styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:[NSScreen mainScreen]];
	
	if ([FRAMain singleDocumentWindowWasOpenBeforeEnteringFullScreen] == NO) {
		NSRange sell = [[document firstTextView] selectedRange];
		[[document thirdTextView] scrollRangeToVisible:sell];
		[[document thirdTextView] setSelectedRange:sell];
	}
	
	fullScreenDocument = document;
	[fullScreenWindow orderFront:nil];
	[fullScreenWindow enterFullScreen];
}


- (void)insertDocumentIntoFullScreenWindow
{
	CGDisplayCapture(kCGDirectMainDisplay);
	[fullScreenWindow setLevel:CGShieldingWindowLevel()];
	[fullScreenWindow setContentView:[[fullScreenDocument valueForKey:@"singleDocumentWindow"] contentView]];
	[fullScreenWindow makeKeyAndOrderFront:nil];
	[fullScreenWindow setFrame:fullScreenRect display:YES animate:YES];
	
    NSClipView *clipView = [[fullScreenDocument valueForKey:@"thirdTextScrollView"] contentView];
	[[fullScreenDocument lineNumbers] updateLineNumbersForClipView: clipView
                                                                       checkWidth: YES];
    [[fullScreenDocument syntaxColouring] pageRecolourTextView: [clipView documentView]];

	[[fullScreenDocument valueForKey:@"singleDocumentWindow"] orderOut:nil];
	[fullScreenWindow makeFirstResponder:[fullScreenDocument thirdTextView]];
}


- (void)returnFromFullScreen
{	
	SetSystemUIMode(kUIModeNormal, 0);
	[NSApp setMainMenu:savedMainMenu];
	
	[[fullScreenDocument valueForKey:@"singleDocumentWindow"] setContentView:[fullScreenWindow contentView]];
	
	[fullScreenWindow orderOut:self];
	fullScreenWindow = nil;
	
	CGDisplayRelease(kCGDirectMainDisplay);
	
	if ([FRAMain singleDocumentWindowWasOpenBeforeEnteringFullScreen] == NO) {
		[[fullScreenDocument valueForKey:@"singleDocumentWindow"] performClose:nil];
	} else
    {
		[[fullScreenDocument valueForKey:@"singleDocumentWindow"] makeKeyAndOrderFront:nil];
        
        NSClipView *clipView = [[fullScreenDocument valueForKey:@"thirdTextScrollView"] contentView];
		[[fullScreenDocument lineNumbers] updateLineNumbersForClipView: clipView
                                                                           checkWidth: YES];
        [[fullScreenDocument syntaxColouring] pageRecolourTextView: [clipView documentView]];

	}
	
	fullScreenDocument = nil;
	[FRAMain setIsInFullScreenMode:NO];
}


- (void)insertAllFunctionsIntoMenu:(NSMenu *)menu
{
	NSArray *allFunctions = [self allFunctions];

	if ([allFunctions count] == 0) {
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Not applicable", @"Not applicable in insertAllFunctionsIntoMenu") action:nil keyEquivalent:@""];
		[menuItem setState:NSOffState];
		[menu insertItem:menuItem atIndex:0];
		return;
	}		
	
	NSEnumerator *enumerator = [allFunctions reverseObjectEnumerator];
	NSInteger index = [allFunctions count] - 1;
	NSInteger currentFunctionIndex = [self currentFunctionIndexForFunctions:allFunctions];
	NSString *spaceBetween;
	if ([allFunctions count] != 0) {
		if ([[[allFunctions lastObject] valueForKey:@"lineNumber"] integerValue] > 999) {
			spaceBetween = @"\t\t ";
		} else {
			spaceBetween = @"\t ";
		}
	} else {
		spaceBetween = @"";
	}
	for (id item in enumerator) {
		NSMenuItem *menuItem = [[NSMenuItem alloc] init];
		NSInteger lineNumber = [[item valueForKey:@"lineNumber"] integerValue];
		NSString *title = [NSString stringWithFormat:@"%ld%@%@", lineNumber, spaceBetween, [item valueForKey:@"name"]];
		[menuItem setTitle:title];
		[menuItem setTarget:FRAInterface];
		[menuItem setAction:@selector(goToFunctionOnLine:)];
		[menuItem setTag:lineNumber];
		if (index == currentFunctionIndex) {
			[menuItem setState:NSOnState];
		}
		index--;
		[menu insertItem:menuItem atIndex:0];
	}
}


- (NSArray *)allFunctions
{
	NSString *functionDefinition = [[[FRAProjectsController currentDocument] syntaxColouring] functionDefinition];
	if (functionDefinition == nil || [functionDefinition isEqualToString:@""]) {
		return @[];
	}
	NSString *removeFromFunction = [[[FRAProjectsController currentDocument] syntaxColouring] removeFromFunction];
	NSString *text = FRACurrentText;
	if (text == nil || [text isEqualToString:@""]) {
		return @[];
	}
	
	ICUPattern *pattern = [[ICUPattern alloc] initWithString:functionDefinition flags:(ICUCaseInsensitiveMatching | ICUMultiline)];
	ICUMatcher *matcher = [[ICUMatcher alloc] initWithPattern:pattern overString:text];

	NSInteger index = 0;
	NSInteger lineNumber = 0;
	NSMutableArray *returnArray = [NSMutableArray array];
	NSArray *keys = @[@"lineNumber", @"name"];
	while ([matcher findNext]) {
		NSRange matchRange = [matcher rangeOfMatch];
		while (index <= matchRange.location + 1) {
			index = NSMaxRange([text lineRangeForRange:NSMakeRange(index, 0)]);
			lineNumber++;
		}
		
		NSMutableString *name = [NSMutableString stringWithString:[text substringWithRange:matchRange]];
		NSInteger nameIndex = -1;
		NSInteger nameLength = [name length];
		while (++nameIndex < nameLength && ([name characterAtIndex:nameIndex] == ' ' || [name characterAtIndex:nameIndex] == '\t' || [name characterAtIndex:nameIndex] == '\n' || [name characterAtIndex:nameIndex] == '\r')) {
			[name replaceCharactersInRange:NSMakeRange(nameIndex, 1) withString:@""];
			nameLength--;
			nameIndex--; // Move it backwards as it, so to speak, has moved forwards by deleting one
		}
		
		while (nameLength-- && ([name characterAtIndex:nameLength] == ' ' || [name characterAtIndex:nameLength] == '\t' || [name characterAtIndex:nameLength] == '{' || [name characterAtIndex:nameIndex] == '\n' || [name characterAtIndex:nameIndex] == '\r')) {
			[name replaceCharactersInRange:NSMakeRange(nameLength, 1) withString:@""];
		}
		
		[name replaceOccurrencesOfString:removeFromFunction withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [name length])];
		
		NSDictionary *dictionary = [[NSDictionary alloc] initWithObjects:@[@(lineNumber), name] forKeys:keys];
		
		[returnArray addObject:dictionary];
	}
	
	return (NSArray *)returnArray;	
}


- (NSInteger)currentLineNumber
{
	NSTextView *textView = FRACurrentTextView;
	NSString *text = [textView string];
	NSInteger textLength = [text length];
	if (textView == nil || [text isEqualToString:@""]) {
		return 0;
	}
	
	NSRange selectedRange = [textView selectedRange];
	
	NSInteger index = 0;
	NSInteger	lineNumber = 0;
	while (index <= selectedRange.location && index < textLength) {
		index = NSMaxRange([text lineRangeForRange:NSMakeRange(index, 0)]);
		lineNumber++;
	}
	
	return lineNumber;	
}


- (NSInteger)currentFunctionIndexForFunctions:(NSArray *)functions
{
	NSInteger lineNumber = [FRAInterface currentLineNumber];
	
	id item;
	NSInteger index = 0;
	for (item in functions) {
		NSInteger functionLineNumber = [[item valueForKey:@"lineNumber"] integerValue];
		if (functionLineNumber == lineNumber) {
			return index;
		} else if (functionLineNumber > lineNumber) {
			return index - 1;
		}
		index++;
	}
	
	return -1;	
}


- (void)removeAllTabBarObjectsForTabView:(NSTabView *)tabView
{
	NSArray *array = [tabView tabViewItems];
	for (id item in array) {
		[tabView removeTabViewItem:item];
	}
}


- (void)changeViewWithAnimationForWindow:(NSWindow *)window oldView:(NSView *)oldView newView:(NSView *)newView newRect:(NSRect)newRect
{	
    NSDictionary *windowResize = @{NSViewAnimationTargetKey: window, NSViewAnimationEndFrameKey: [NSValue valueWithRect:newRect]};
	
    NSDictionary *oldFadeOut = @{NSViewAnimationTargetKey: oldView, NSViewAnimationEffectKey: NSViewAnimationFadeOutEffect};
	
    NSDictionary *newFadeIn = @{NSViewAnimationTargetKey: newView, NSViewAnimationEffectKey: NSViewAnimationFadeInEffect};
	
    NSArray *animations = @[windowResize, newFadeIn, oldFadeOut];
	
    NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:animations];
    [animation setAnimationBlockingMode:NSAnimationNonblocking];
    [animation setDuration:0.32];
    [animation startAnimation];
}


@end
