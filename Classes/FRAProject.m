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

#import "FRAProject.h"
#import "FRABasicPerformer.h"
#import "FRAProjectsController.h"
#import "FRADocumentsListCell.h"
#import "FRAViewMenuController.h"
#import "FRADragAndDropController.h"
#import "FRAApplicationDelegate.h"
#import "FRAInterfacePerformer.h"
#import "FRAViewMenuController.h"
#import "FRAVariousPerformer.h"
#import "FRASyntaxColouring.h"
#import "FRAFileMenuController.h"
#import "FRAAdvancedFindController.h"
#import "FRAProject+DocumentViewsController.h"


#import "FRAPrintViewController.h"
#import "FRAPrintTextView.h"
#import "VADocument.h"
#import "FRATextView.h"
#import "VAProject.h"

#import <VADevUIKit/VADevUIKit.h>

@implementation FRAProject

- (id)init
{
    self = [super init];
    if (self)
    {
		_project = [[VAProject alloc] init];
		[[FRAProjectsController sharedDocumentController] setCurrentProject:self];
    }
    return self;
}


#pragma mark -
#pragma mark Overrides


- (NSString *)windowNibName
{
    return @"FRAProject";
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
	[super windowControllerDidLoadNib:aController];
	
	[[self windowControllers][0] setWindowFrameAutosaveName:@"FraiseProjectWindow"];
	[[self window] setFrameAutosaveName:@"FraiseProjectWindow"];
	//[[[self windowControllers] objectAtIndex:0] setShouldCascadeWindows:NO];
	
	[self setDefaultAppearanceAtStartup];
	
	[self setDefaultViews];
	
	[_documentsTableView setDelegate:self];
	[_mainSplitView setDelegate:self];
	//[mainSplitView setAutosaveName:@"MainSplitView"];
	[_contentSplitView setDelegate:self];	
	
	[[FRAViewMenuController sharedInstance] performCollapse];
	[self performSelector:@selector(performSetupAfterItIsCurrentProject) withObject:nil afterDelay:0.0];
	
	[[self window] setDelegate:self];
	
	[_documentsTableView setDataSource:[FRADragAndDropController sharedInstance]];
	[_documentsTableView registerForDraggedTypes:@[NSFilenamesPboardType, NSStringPboardType, @"FRAMovedDocumentType"]];
	[_documentsTableView setDraggingSourceOperationMask:(NSDragOperationCopy | NSDragOperationMove) forLocal:NO];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES];
	[_documentsArrayController setSortDescriptors:@[sortDescriptor]];

	if ([[FRAApplicationDelegate sharedInstance] shouldCreateEmptyDocument] == YES) {
		id document = [self createNewDocumentWithContents:@""];
		[self insertDefaultIconsInDocument:document];
		[self selectionDidChange];
	}
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{	
	return [NSArchiver archivedDataWithRootObject:[self dictionaryOfDocumentsInProject]];
}


- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel
{
    [savePanel setDirectoryURL: [NSURL fileURLWithPath: [FRAInterface whichDirectoryForSave]]];
	
	return YES;
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	return NO;
}

/**
 * This method creates a NSPrintOperation object to allow the user to print its document or to export it. It also
 * shows the Printing panel so the user can modify settings concerning the document printing. The printing operation
 * is executed in a new thread so the user can still interact with the application.
 */
- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError
{
	NSPrintInfo *printInfo = [self printInfo]; 
	FRAPrintTextView *printTextView = [[FRAPrintTextView alloc] initWithFrame:NSMakeRect([printInfo leftMargin], [printInfo bottomMargin], [printInfo paperSize].width - [printInfo leftMargin] - [printInfo rightMargin], [printInfo paperSize].height - [printInfo topMargin] - [printInfo bottomMargin])];
	
	NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:printTextView printInfo:printInfo];
    [printOperation setShowsPrintPanel:YES];
	[printOperation setCanSpawnSeparateThread:YES]; // Allow the printing process to be executed in a new thread.
    
    NSPrintPanel *printPanel = [printOperation printPanel];
	FRAPrintViewController *printViewController = [[FRAPrintViewController alloc] init];    
	[printPanel addAccessoryController:printViewController];
	
    return printOperation;
}


- (NSPrintInfo *)printInfo
{
    NSPrintInfo *printInfo = [super printInfo];
	
	CGFloat marginsMin = [[FRADefaults valueForKey:@"MarginsMin"] doubleValue];
	if ([[FRADefaults valueForKey:@"PrintHeader"] boolValue] == YES) {
		[printInfo setTopMargin:(marginsMin + 22)];
	} else {
		[printInfo setTopMargin:marginsMin];
	}
	[printInfo setLeftMargin:marginsMin];	
	[printInfo setRightMargin:marginsMin];
	[printInfo setBottomMargin:marginsMin];
	
	[printInfo setHorizontallyCentered:NO];    
	[printInfo setVerticallyCentered:NO];
	
	[printInfo setHorizontalPagination:NSAutoPagination];
	[printInfo setVerticalPagination:NSAutoPagination];
	
    return printInfo;
}


#pragma mark -
#pragma mark Others

- (void)performSetupAfterItIsCurrentProject
{
	[[FRAProjectsController sharedDocumentController] setCurrentProject:nil];
	
	[_documentsTableView setTarget:self];
	[_documentsTableView setDoubleAction:@selector(doubleClick:)];
	
	if ([[_documentsArrayController arrangedObjects] count] > 0)
    {
		[self updateWindowTitleBarForDocument: [_documentsArrayController selectedObjects][0]];
	} else {
		[self updateWindowTitleBarForDocument:nil];
	}
	
//	[self extraToolbarValidation];
}


- (void)setDefaultAppearanceAtStartup
{
	[[_statusBarTextField cell] setBackgroundStyle:NSBackgroundStyleRaised];
	
	FRADocumentsListCell *cell = [[FRADocumentsListCell alloc] init];
	[cell setWraps:NO];
	[cell setLineBreakMode:NSLineBreakByTruncatingMiddle];
	[[_documentsTableView tableColumnWithIdentifier:@"name"] setDataCell:cell];

	if ([[FRADefaults valueForKey:@"ShowStatusBar"] boolValue] == NO)
    {
		[[FRAViewMenuController sharedInstance] performHideStatusBar];
	}

	if ([[FRADefaults valueForKey:@"ShowTabBar"] boolValue] == NO) {
		CGFloat tabBarHeight = [_tabBarControl bounds].size.height;
		NSRect mainSplitViewRect = [_mainSplitView frame];
		[_tabBarControl setHidden:YES];
		[_mainSplitView setFrame:NSMakeRect(mainSplitViewRect.origin.x, mainSplitViewRect.origin.y, mainSplitViewRect.size.width, mainSplitViewRect.size.height + tabBarHeight)];
	} else {
		[self updateTabBar];
	}

	if ([_project valueForKey:@"dividerPosition"] == nil) {
		[_project setValue:[FRADefaults valueForKey:@"DividerPosition"] forKey:@"dividerPosition"];
	}
	[self resizeMainSplitView];
}


- (void)selectDocument:(id)document
{
	[_documentsArrayController setSelectedObjects:@[document]];
}


- (BOOL)areThereAnyDocuments
{
	if ([[_documentsArrayController arrangedObjects] count] > 0)
    {
		return YES;
	} else {
		return NO;
	}
}


- (void)resizeViewsForDocument:(id)document
{	
	if ([self areThereAnyDocuments] == YES) {		
		NSInteger gutterWidth;
		CGFloat subtractFromY; // To remove extra "ugly" pixel row in singleDocumentWindow
		CGFloat subtractFromHeight = 0;
		NSInteger extraHeight;
		NSInteger viewNumber = 0;
		NSView *view = _firstContentView;
		NSScrollView *textScrollView = [document firstTextScrollView];
		NSScrollView *gutterScrollView = [document firstGutterScrollView];
		
		while (viewNumber++ < 3) {
			subtractFromY = 0;
			extraHeight = 0;
			if (viewNumber == 2) {
				if ([document secondTextView] != nil) {
					view = _secondContentView;
					textScrollView = [document secondTextScrollView];
					gutterScrollView = [document secondGutterScrollView];
					subtractFromY = [_secondContentViewNavigationBar bounds].size.height * -1;
					subtractFromHeight = [_secondContentViewNavigationBar bounds].size.height;
				} else {
					continue;
				}
			}
			if (viewNumber == 3) {
				if ([document singleDocumentWindow] != nil) {
					view = [[document singleDocumentWindow] contentView];
					textScrollView = [document thirdTextScrollView];
					gutterScrollView = [document thirdGutterScrollView];
					subtractFromY = 1;
					extraHeight = 2;
				} else {
					continue;
				}
			}
			if ([document showLineNumberGutter] == YES) {
				if (![[view subviews] containsObject:gutterScrollView]) {
					[view addSubview:gutterScrollView];
				}
				gutterWidth = [document gutterWidth];
				[gutterScrollView setFrame:NSMakeRect(0, 0 - subtractFromY, gutterWidth, [view bounds].size.height + extraHeight - subtractFromHeight)];
			} else {
				gutterWidth = 0;
				[gutterScrollView removeFromSuperviewWithoutNeedingDisplay];
			}

			[textScrollView setFrame:NSMakeRect(gutterWidth, 0 - subtractFromY, [view bounds].size.width - gutterWidth, [view bounds].size.height + extraHeight - subtractFromHeight)];
		}
		
		[[document lineNumbers] updateLineNumbersCheckWidth: YES];
        [[document syntaxColouring] pageRecolour];
	}
}


- (void)doubleClick:(id)sender
{
	[[FRAViewMenuController sharedInstance] viewDocumentInSeparateWindowAction:nil];
}


- (id)createNewDocumentWithContents:(NSString *)textString
{
	VADocument *document = [self createNewDocumentWithPath:nil andContents:textString];
	
	[document setNewDocument: YES];
	[FRAVarious setUnsavedAsLastSavedDateForDocument:document];
	[FRAInterface updateStatusBar];
	
	return document;
}


- (id)createNewDocumentWithPath:(NSString *)path andContents:(NSString *)textString
{
	VADocument *document = [[VADocument alloc] init];
	
	[[self documents] addObject:document];
	
	[FRAVarious setNameAndPathForDocument:document path:path];
	[FRAInterface createFirstViewForDocument:document];

	[[document firstTextView] setString:textString];
	
	FRASyntaxColouring *syntaxColouring = [[FRASyntaxColouring alloc] initWithDocument:document];
	[document setSyntaxColouring: syntaxColouring];
	
    NSClipView *clipView = [[document firstTextScrollView] contentView];
	[[document lineNumbers] updateLineNumbersForClipView: clipView
                                                             checkWidth: NO];
    [[document syntaxColouring] pageRecolourTextView: [clipView documentView]];

	[document setSortOrder: [[_documentsArrayController arrangedObjects] count]];
	[self documentsListHasUpdated];
	
	[_documentsArrayController setSelectedObjects:@[document]];
	
	[document setEncodingName: [NSString localizedNameOfStringEncoding: [document encoding]]];
	
	return document;
}


- (void)updateEditedBlobStatus
{
	id currentDocument = [FRAProjectsController currentDocument];
	if ([currentDocument isEdited] == YES) {
		[[self window] setDocumentEdited:YES];
		if ([currentDocument singleDocumentWindow] != nil)
        {
			[[currentDocument singleDocumentWindow] setDocumentEdited:YES];
		}
	} else {
		[[self window] setDocumentEdited:NO];
		if ([currentDocument singleDocumentWindow] != nil)
        {
			[[currentDocument singleDocumentWindow] setDocumentEdited:NO];
		}
	}
}


- (void)updateWindowTitleBarForDocument:(id)document
{
	NSWindow *currentWindow = [self window];
	NSString *projectName = nil;
	if ([self name] != nil) {
		projectName = [self name];
	}

	if ([self areThereAnyDocuments] == YES && document != nil) {
		NSWindow *singleDocumentWindow = [document singleDocumentWindow];
		[self updateEditedBlobStatus];
		if ([document path] != nil && [[FRADefaults valueForKey:@"ShowFullPathInWindowTitle"] boolValue] == YES) {
			
			if ([document fromExternal] == YES) {
				
				if (document == [self firstDocument] || document == [self secondDocument]) {
					[currentWindow setTitleWithRepresentedFilename:[document path]];
					if (projectName != nil) {
						[currentWindow setTitle:[NSString stringWithFormat:@"%@ - %@ (%@)", [document name], [[document externalPath] stringByDeletingLastPathComponent], projectName]];
					} else {
						[currentWindow setTitle:[NSString stringWithFormat:@"%@ - %@", [document name], [[document externalPath] stringByDeletingLastPathComponent]]];
					}
				}
				if (singleDocumentWindow != nil) {
					[singleDocumentWindow setTitleWithRepresentedFilename:[document path]];
					[singleDocumentWindow setTitle:[NSString stringWithFormat:@"%@ - %@", [document name], [[document externalPath] stringByDeletingLastPathComponent]]];
				}
				
			} else {
				if (document == [self firstDocument] || document == [self secondDocument]) {
					[currentWindow setTitleWithRepresentedFilename:[document path]];
					if (projectName != nil) {
						[currentWindow setTitle:[NSString stringWithFormat:@"%@ (%@)", [document nameWithPath], projectName]];
					} else {
						[currentWindow setTitle:[document nameWithPath]];
					}
				}
				if (singleDocumentWindow != nil) {
					[singleDocumentWindow setTitleWithRepresentedFilename:[document path]];
					[singleDocumentWindow setTitle:[document nameWithPath]];
				}
			}
			
		} else {
			if ([document path] != nil) {
				if (document == [self firstDocument] || document == [self secondDocument]) {
					[currentWindow setTitleWithRepresentedFilename:[document path]];
					if (projectName != nil) {
						[currentWindow setTitle:[NSString stringWithFormat:@"%@ (%@)", [document name], projectName]];
					}
				}
				if (singleDocumentWindow != nil) {
					[singleDocumentWindow setTitleWithRepresentedFilename:[document path]];
				}
				
			} else {
				if (document == [self firstDocument] || document == [self secondDocument]) {
					[currentWindow setRepresentedFilename:[[NSBundle mainBundle] bundlePath]];
					if (projectName != nil) {
						[currentWindow setTitle:[NSString stringWithFormat:@"%@ (%@)", [document name], projectName]];
					} else {
						[currentWindow setTitle:[document name]];
					}
				}
				if (singleDocumentWindow != nil) {
					[singleDocumentWindow setRepresentedFilename:[[NSBundle mainBundle] bundlePath]];
				}
			}
			
			if (document == [self firstDocument] || document == [self secondDocument]) {
				if (projectName != nil) {
					[currentWindow setTitle:[NSString stringWithFormat:@"%@ (%@)", [document name], projectName]];
				} else {
					[currentWindow setTitle:[document name]];
				}
			}
			if (singleDocumentWindow != nil) {
				[singleDocumentWindow setTitle:[document name]];
			}
		}
	} else {
		[currentWindow setDocumentEdited:NO];
		[currentWindow setRepresentedFilename:[[NSBundle mainBundle] bundlePath]];
		[currentWindow setTitle:@"Fraise"];
	}
}


- (void)checkIfDocumentIsUnsaved:(id)document keepOpen:(BOOL)keepOpen
{	
	if ([document isEdited] == YES) {
		[self selectDocument:document];
		NSString *title = [NSString stringWithFormat:NSLocalizedString(@"The document %@ has not been saved", @"Indicate in Close-sheet that the document %@ has not been saved."), [document name]];
		NSBeginAlertSheet(title,
						  SAVE_STRING,
						  NSLocalizedString(@"Don't Save", @"Don't Save-button in Close-sheet"),
						  CANCEL_BUTTON,
						  [self window],
						  self,
						  @selector(closeSheetDidEnd:returnCode:contextInfo:),
						  nil,
						  (__bridge void *)@[document, @(keepOpen)],
						  NSLocalizedString(@"Your changes will be lost if you close the document without saving.", @"Your changes will be lost if you close the document without saving in Close-sheet"));
		[NSApp runModalForWindow:[[self window] attachedSheet]]; // Modal to make sure that nothing happens while the sheet is displaying
	} else {
		if (keepOpen == NO) {
			[self performCloseDocument:document];
		}
	}
}


- (void)closeSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [FRAVarious stopModalLoop];
	
	id document = ((__bridge NSArray *)contextInfo)[0];
	BOOL keepOpen = [((__bridge NSArray *)contextInfo)[1] boolValue];
	
	if (returnCode == NSAlertDefaultReturn) {
		[sheet close];
		[[FRAFileMenuController sharedInstance] saveAction:nil];
		if ([document isEdited] == NO) { // Save didn't fail
			if (keepOpen == NO) {
				[self performCloseDocument:document];
			}
		} else {
			shouldWindowClose = NO;
		}
	} else if (returnCode == NSAlertAlternateReturn) {
		if (keepOpen == NO) {
			[self performCloseDocument:document];
		}
	} else { // The user wants to review the document
		shouldWindowClose = NO;
	}
}


- (void)performCloseDocument:(id)document
{
	if (document == nil) {
		return;
	}
	
	NSInteger documentIndex = [[[self documentsArrayController] arrangedObjects] indexOfObject:document];

	[self cleanUpDocument:document];
	
	if ([self areThereAnyDocuments]) {
		if (documentIndex > 0) {
			documentIndex--;
			[[self documentsArrayController] setSelectionIndex:documentIndex];
		} else {
			[[self documentsArrayController] setSelectionIndex:0];
			[self selectionDidChange]; // Doesn't seem to send this notification otherwise
		}
		[self updateWindowTitleBarForDocument:[FRAProjectsController currentDocument]];
	
		[self documentsListHasUpdated];
	} else {
		if ([[FRAApplicationDelegate sharedInstance] filesToOpenArray] == nil) { // A hack to make it only close the window when there no documents to open, from e.g. a FTP-program
			if ([[self window] attachedSheet]) {
				[self performSelector:@selector(performCloseWindow) withObject:nil afterDelay:0.0]; // Do it this way to allow a possible attached sheet to close, otherwise it won't work
			} else {
				if ([[FRADefaults valueForKey:@"KeepEmptyWindowOpen"] boolValue] == NO) {
					[[self window] performClose:nil];
				}
			}
		}
	}
	
	[FRAVarious resetSortOrderNumbersForArrayController: _documentsArrayController];
}


- (void)performCloseWindow
{
	[[self window] performClose:nil];
}


- (void)cleanUpDocument:(id)document
{
	[[NSNotificationCenter defaultCenter] removeObserver:[document lineNumbers]];
	
	if ([self secondDocument] == document && [[document secondTextScrollView] contentView] != nil) {
		[[FRAViewMenuController sharedInstance] performCollapse];
	}
	
	if ([document singleDocumentWindow] != nil) {
		[[document singleDocumentWindow] performClose:nil];
	}	
	
	if ([[FRAAdvancedFindController sharedInstance] currentlyDisplayedDocumentInAdvancedFind] == document) {
		[[FRAAdvancedFindController sharedInstance] removeCurrentlyDisplayedDocumentInAdvancedFind];
	}
	
	if ([document fromExternal] == YES) {
		[FRAVarious sendClosedEventToExternalDocument:document];
	}
	
	if ([self firstDocument] == document) {
		[FRAInterface removeAllSubviewsFromView:[self firstContentView]];
		[self setFirstDocument:nil];
	}
	
    [_documentsArrayController removeObject:document];
	[[FRAApplicationDelegate sharedInstance] saveAction:nil]; // To remove it from memory
}


- (NSDictionary *)dictionaryOfDocumentsInProject
{	
	[FRAVarious resetSortOrderNumbersForArrayController: _documentsArrayController];
	
	NSArray *array = [[self documents] allObjects];
	NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionary];
	NSMutableArray *documentsArray = [NSMutableArray array];
	
    for (VADocument *item in array)
    {
		if ([item path] != nil)
        {
			NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
			[dictionary setObject:[item path] forKey:@"path"];
			[dictionary setObject: @([item encoding]) forKey:@"encoding"];
			[dictionary setObject: @([item sortOrder]) forKey:@"sortOrder"];
			NSRange selectedRange = [[item firstTextView] selectedRange];
			if (selectedRange.location == NSNotFound)
            {
				[dictionary setObject:NSStringFromRange(NSMakeRange(0, 0)) forKey:@"selectedRange"];
			} else
            {
				[dictionary setObject:NSStringFromRange(selectedRange) forKey:@"selectedRange"];
			}
			[documentsArray addObject:dictionary];
		}
	}
	
	[returnDictionary setObject:documentsArray forKey:@"documentsArray"];
	NSString *name;
	
	if ([self areThereAnyDocuments] == NO || [[_documentsArrayController selectedObjects][0] valueForKey:@"name"] == nil) {
		name = @"";
	} else {
		name = [[_documentsArrayController selectedObjects][0] valueForKey:@"name"];
	}
	[returnDictionary setObject:name forKey:@"selectedDocumentName"];
	[returnDictionary setObject: NSStringFromRect([[self window] frame]) forKey:@"windowFrame"];
	[returnDictionary setObject: [_project valueForKey:@"view"] forKey:@"view"];
	[returnDictionary setObject: [_project valueForKey:@"viewSize"] forKey:@"viewSize"];
	[self saveMainSplitViewFraction];
	[returnDictionary setObject: [_project valueForKey:@"dividerPosition"]  forKey:@"dividerPosition"];
	[returnDictionary setObject:@3 forKey:@"version"];
	
	return returnDictionary;
}


- (void)autosave
{
	if ([self fileURL] != nil) {
		[self saveDocument:nil];
	}
}


- (NSString *)name
{
	if ([self fileURL] == nil) {
		return nil;
	}
	
	NSString *urlString = (NSString*)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (CFStringRef)[[self fileURL] absoluteString], CFSTR(""), kCFStringEncodingUTF8));
//	NSMakeCollectable(urlString);
	return [[urlString lastPathComponent] stringByDeletingPathExtension];
}


- (void)selectionDidChange
{
	[self tableViewSelectionDidChange: [NSNotification notificationWithName: NSTableViewSelectionDidChangeNotification
                                                                     object: _documentsTableView]];
}


- (BOOL)isDocumentEdited
{
	return NO;
}


- (BOOL)areAllDocumentsSaved
{	
	[self saveMainSplitViewFraction];
	
	shouldWindowClose = YES;
	
	NSArray *array = [[self documents] allObjects];
	for (id item in array) {
		if ([item isEdited] == YES) {	
			[self checkIfDocumentIsUnsaved:item keepOpen:YES];
		}
		if (shouldWindowClose == NO) { // If one has chosen Cancel to review document one should not be asked about other unsaved documents
			return NO;
		}
	}
	
	// If the user has chosen to review the document instead of closing it the application should not be closed
	if (shouldWindowClose == NO) {
		return NO;
	} else {
		return YES;
	}
}


- (void)documentsListHasUpdated
{
	[self updateTabBar];
	[self buildSecondContentViewNavigationBarMenu];
		
	[self reloadData];
	
	if ([[FRAApplicationDelegate sharedInstance] hasFinishedLaunching] == YES)
    { // Do this toolbar validation here so it doesn't need to be updated all the time as it would have been in validateToolbarItem
//		[self extraToolbarValidation];
	}
}


- (void)buildSecondContentViewNavigationBarMenu
{
	if (_secondDocument == nil)
    {
		return;
	}
	
	NSMenu *menu = [_secondContentViewPopUpButton menu];
	[FRABasic removeAllItemsFromMenu:menu];
	
	id menuItemToSelect = nil;
	NSEnumerator *enumerator = [[_documentsArrayController arrangedObjects] reverseObjectEnumerator];
	for (id item in enumerator) {
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[item valueForKey:@"name"] action:@selector(secondContentViewDocumentChanged:) keyEquivalent:@""];
		[menuItem setRepresentedObject:item];
		[menuItem setTarget:self];
		[menu insertItem:menuItem atIndex:0];
		if (item == _secondDocument)
        {
			menuItemToSelect = menuItem;
		}
	}
	
	[_secondContentViewPopUpButton selectItem:menuItemToSelect];
}


- (void)secondContentViewDocumentChanged:(id)sender
{
	[FRAInterface insertDocumentIntoSecondContentView:[sender representedObject]];
}


- (CGFloat)mainSplitViewFraction
{
	CGFloat fraction;
	if ([_contentSplitView bounds].size.width + [_leftDocumentsView bounds].size.width + [_mainSplitView dividerThickness] != 0)
    {
		fraction = [_leftDocumentsView bounds].size.width / ([_contentSplitView bounds].size.width + [_leftDocumentsView bounds].size.width + [_mainSplitView dividerThickness]);
	} else {
		fraction = 0.0;
	}
	
	return fraction;
}


- (void)resizeMainSplitView
{	
	NSRect leftDocumentsViewFrame = [[_mainSplitView subviews][0] frame];
    NSRect contentViewFrame = [[_mainSplitView subviews][1] frame];
	CGFloat totalWidth = leftDocumentsViewFrame.size.width + contentViewFrame.size.width + [_mainSplitView dividerThickness];
    leftDocumentsViewFrame.size.width = [_project dividerPosition] * totalWidth;
    contentViewFrame.size.width = totalWidth - leftDocumentsViewFrame.size.width - [_mainSplitView dividerThickness];
	
    [[_mainSplitView subviews][0] setFrame:leftDocumentsViewFrame];
    [[_mainSplitView subviews][1] setFrame:contentViewFrame];
	
    [_mainSplitView adjustSubviews];
}


- (void)saveMainSplitViewFraction
{
	NSNumber *fraction = @([self mainSplitViewFraction]);
	[_project setDividerPosition: [fraction doubleValue]];
	[FRADefaults setValue:fraction forKey:@"DividerPosition"];
}


- (void)insertDefaultIconsInDocument:(id)document
{
	NSImage *defaultIcon = [FRAInterface defaultIcon];
	[defaultIcon setScalesWhenResized:YES];
		
	NSImage *defaultUnsavedIcon = [FRAInterface defaultUnsavedIcon];
	[defaultUnsavedIcon setScalesWhenResized:YES];
	
	[document setIcon: defaultIcon];
	[document setUnsavedIcon: defaultUnsavedIcon];
}


#pragma mark -
#pragma mark Accessors

- (void)setLastTextViewInFocus: (FRATextView *)newLastTextViewInFocus
{
	if (_lastTextViewInFocus != newLastTextViewInFocus)
    {
		_lastTextViewInFocus = newLastTextViewInFocus;
	}
	
	[self updateWindowTitleBarForDocument:[FRAProjectsController currentDocument]];
}


- (NSMutableSet *)documents
{
	return [_project documents];
}


- (NSWindow *)window
{
	return [[self windowControllers][0] window];
}

- (NSToolbar *)projectWindowToolbar
{
    return [[self window] toolbar];
}


#pragma mark -
#pragma mark Window delegates

- (BOOL)windowShouldClose:(id)sender
{	
	if ([self areAllDocumentsSaved] == YES) { // Has the closing been stopped, by e.g. the user wanting to review a document
		return YES;
	} else {
		return NO;
	}
}


- (void)windowWillClose:(NSNotification *)aNotification
{
	if ([[FRAApplicationDelegate sharedInstance] isTerminatingApplication] == YES) {		
		return; // No need to clean up if we are quitting
	}
	
	[self autosave];
	
	NSArray *array = [[self documents] allObjects];
	for (id item in array) {
		[self cleanUpDocument:item];
	}

	[[FRAApplicationDelegate sharedInstance] saveAction:nil]; // Make sure the documents objects really are deleted, before deleting the project

	if (_project != nil)
    { // Remove the managed object project
//		[FRAManagedObjectContext deleteObject:project];
	}

	[[FRAApplicationDelegate sharedInstance] saveAction:nil];
//	[[FRAManagedObjectContext undoManager] removeAllActions];
}





@end
