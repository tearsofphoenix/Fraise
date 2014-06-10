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

#import "FRASnippetsController.h"
#import "FRADragAndDropController.h"
#import "FRATextView.h"
#import "FRAMainController.h"
#import "FRAInterfacePerformer.h"
#import "FRABasicPerformer.h"
#import "FRAOpenSavePerformer.h"
#import "FRADocumentsListCell.h"
#import "FRAApplicationDelegate.h"
#import "FRAToolsMenuController.h"
#import "FRAProjectsController.h"
#import "VASnippet.h"
#import "VASnippetCollection.h"

#import <VADevUIKit/VADevUIKit.h>
#import <PXSourceList/PXSourceList.h>

@interface FRASnippetsController ()<PXSourceListDataSource, PXSourceListDelegate>

@end

@implementation FRASnippetsController

@synthesize snippetsTextView, snippetsWindow;

VASingletonIMPDefault(FRASnippetsController)

- (void)openSnippetsWindow
{
	if (snippetsWindow == nil)
    {
		[NSBundle loadNibNamed:@"FRASnippets.nib" owner:self];
		
		[_snippetCollectionsTableView setDataSource: self];
        [_snippetCollectionsTableView setDelegate: self];
        
		[_snippetsTableView setDataSource: self];
		[_snippetsTableView setDelegate: self];
        
		[_snippetCollectionsTableView registerForDraggedTypes: @[NSFilenamesPboardType, @"FRAMovedSnippetType"]];
		[_snippetCollectionsTableView setDraggingSourceOperationMask:(NSDragOperationCopy) forLocal:NO];
		
		[_snippetsTableView registerForDraggedTypes:@[NSStringPboardType]];
		[_snippetsTableView setDraggingSourceOperationMask:(NSDragOperationCopy) forLocal:NO];
        
		FRADocumentsListCell *cell = [[FRADocumentsListCell alloc] init];
		[cell setWraps:NO];
		[cell setLineBreakMode:NSLineBreakByTruncatingMiddle];
		[[_snippetCollectionsTableView tableColumnWithIdentifier:@"collection"] setDataCell:cell];
		
		NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"SnippetsToolbarIdentifier"];
		[toolbar setShowsBaselineSeparator:YES];
		[toolbar setAllowsUserCustomization:YES];
		[toolbar setAutosavesConfiguration:YES];
		[toolbar setDisplayMode:NSToolbarDisplayModeDefault];
		[toolbar setSizeMode:NSToolbarSizeModeSmall];
		[toolbar setDelegate:self];
		[snippetsWindow setToolbar:toolbar];
	}
	
	[snippetsWindow makeKeyAndOrderFront:self];
	[[FRAToolsMenuController sharedInstance] buildInsertSnippetMenu];
	
}


- (IBAction)newCollectionAction:(id)sender
{
	VASnippetCollection *collection = [[VASnippetCollection alloc] init];
	
	_selectedCollection = collection;
	
	[snippetsWindow makeFirstResponder:_snippetCollectionsTableView];
    //	[_snippetCollectionsTableView editColumn:0 row:[_snippetCollectionsTableView selectedRow] withEvent:nil select:NO];
    [_snippetCollectionsTableView reloadData];
}


- (IBAction)newSnippetAction:(id)sender
{
	NSArray *snippetCollections = [VASnippetCollection allSnippetCollections];
	if ([snippetCollections count] == 0)
    {
		VASnippetCollection *collection = [[VASnippetCollection alloc] init];
        
		[collection setName: COLLECTION_STRING];
	}
    
	[self performInsertNewSnippet];
	
	[snippetsWindow makeFirstResponder:_snippetsTableView];
	[_snippetsTableView editColumn:0 row:[_snippetsTableView selectedRow] withEvent:nil select:NO];
}


- (VASnippet *)performInsertNewSnippet
{
	VASnippetCollection *collection;
	NSArray *snippetCollections = [VASnippetCollection allSnippetCollections];
    
	if ([snippetCollections count] == 0)
    {
		collection = [[VASnippetCollection alloc] init];
		[collection setName: COLLECTION_STRING];
	} else
    {
		if (snippetsWindow != nil && _selectedCollection)
        {
			collection = _selectedCollection;
            
		} else
        { // If no collection is selected choose the last one in the array
			collection = [snippetCollections lastObject];
		}
	}
	
	VASnippet *item = [[VASnippet alloc] init];
    
	[[collection snippets] addObject: item];
    
    _selectedSnippet = item;
	
	return item;
}


- (void)insertSnippet:(id)snippet
{
	FRATextView *textView = FRACurrentTextView;
	if ([FRAMain isInFullScreenMode])
    {
		textView = [[FRAInterface fullScreenDocument] valueForKey:@"thirdTextView"];
	}
	if (textView == nil)
    {
		NSBeep();
		return;
	}
	
	NSRange selectedRange = [FRACurrentTextView selectedRange];
	NSString *selectedText = [[FRACurrentTextView string] substringWithRange:selectedRange];
	if (selectedText == nil) {
		selectedText = @"";
	}
	
	NSMutableString *insertString = [NSMutableString stringWithString:[snippet valueForKey:@"text"]];
	[insertString replaceOccurrencesOfString:@"%%s" withString:selectedText options:NSLiteralSearch range:NSMakeRange(0, [insertString length])];
	NSInteger locationOfSelectionInString = [insertString rangeOfString:@"%%c"].location;
	[insertString replaceOccurrencesOfString:@"%%c" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [insertString length])];
	[textView insertText:insertString];
	if (locationOfSelectionInString != NSNotFound) {
		[textView setSelectedRange:NSMakeRange(selectedRange.location + locationOfSelectionInString, 0)];
	}
}


- (void)performDeleteCollection
{
    [VASnippetCollection removeCollection: _selectedCollection];
	
	[[FRAToolsMenuController sharedInstance] buildInsertSnippetMenu];
}


- (void)importSnippets
{
	[self openSnippetsWindow];
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setResolvesAliases:YES];
	[openPanel setDirectoryURL: [NSURL fileURLWithPath: [FRAInterface whichDirectoryForOpen]]];
    [openPanel setAllowedFileTypes: @[@"frac", @"smlc", @"fraiseSnippets"]];
    [openPanel beginSheetModalForWindow: snippetsWindow
                      completionHandler: (^(NSInteger result)
                                          {
                                              
                                              if (result == NSOKButton)
                                              {
                                                  [self performSnippetsImportWithPath: [[openPanel URL] path]];
                                              }
                                              [snippetsWindow makeKeyAndOrderFront:nil];
                                          })];
}


- (void)performSnippetsImportWithPath:(NSString *)path
{
	NSData *data = [NSData dataWithContentsOfFile:path];
	NSArray *snippets = (NSArray *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	if ([snippets count] == 0)
    {
		NSBeep();
		return;
	}
	
    NSInteger version = [snippets[0][@"version"] integerValue];
	if (version == 2 || version == 3)
    {
		
		VASnippetCollection *collection = [[VASnippetCollection alloc] init];
        
		[collection setName: snippets[0][@"collectionName"]];
		
		for (NSDictionary *item in snippets)
        {
			VASnippet *snippet = [[VASnippet alloc] init];
            
			[snippet setName: [item objectForKey: @"name"]];
			[snippet setText: [item objectForKey: @"text"]];
			[snippet setCollectionName: [item objectForKey:@"collectionName"]];
			[snippet setShortcutDisplayString: [item objectForKey:@"shortcutDisplayString"]];
			[snippet setShortcutMenuItemKeyString: [item objectForKey:@"shortcutMenuItemKeyString"]];
			[snippet setShortcutModifier: [[item objectForKey:@"shortcutModifier"] integerValue]];
			[snippet setSortOrder: [[item objectForKey:@"sortOrder"] integerValue]];
            
			[[collection snippets] addObject: snippet];
		}
        
        _selectedCollection = collection;
	} else
    {
		NSBeep();
	}
}


- (void)exportSnippets
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes: @[@"fraiseSnippets"]];
    [savePanel setDirectoryURL: [NSURL fileURLWithPath: [FRAInterface whichDirectoryForSave]]];
    [savePanel setNameFieldStringValue: [_selectedCollection name]];
    [savePanel beginSheetModalForWindow: snippetsWindow
                      completionHandler: (^(NSInteger result)
                                          {
                                              if (result == NSOKButton)
                                              {
                                                  VASnippetCollection *collection = _selectedCollection;
                                                  
                                                  NSMutableArray *exportArray = [NSMutableArray array];
                                                  NSArray *array = [collection snippets];
                                                  for (VASnippet *item in array)
                                                  {
                                                      NSMutableDictionary *snippet = [NSMutableDictionary dictionary];
                                                      snippet[@"name"] = [item name];
                                                      snippet[@"text"] = [item text];
                                                      snippet[@"collectionName"] = [collection name];
                                                      snippet[@"shortcutDisplayString"] = [item shortcutDisplayString];
                                                      snippet[@"shortcutMenuItemKeyString"] = [item shortcutMenuItemKeyString];
                                                      snippet[@"shortcutModifier"] = @([item shortcutModifier]);
                                                      snippet[@"sortOrder"] = @([item sortOrder]);
                                                      snippet[@"version"] = @3;
                                                      
                                                      [exportArray addObject:snippet];
                                                  }
                                                  
                                                  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:exportArray];
                                                  [FRAOpenSave performDataSaveWith: data
                                                                              path: [[savePanel URL] path]];
                                              }
                                              
                                              [snippetsWindow makeKeyAndOrderFront:nil];
                                          })];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ([[FRADefaults valueForKey:@"SizeOfDocumentsListTextPopUp"] integerValue] == 0) {
		[aCell setFont:[NSFont systemFontOfSize:11.0]];
	} else {
		[aCell setFont:[NSFont systemFontOfSize:13.0]];
	}
}


- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return @[@"NewSnippetCollectionToolbarItem",
             @"NewSnippetToolbarItem",
             @"FilterSnippetsToolbarItem",
             NSToolbarFlexibleSpaceItemIdentifier];
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return @[@"NewSnippetCollectionToolbarItem",
             NSToolbarFlexibleSpaceItemIdentifier,
             @"FilterSnippetsToolbarItem",
             @"NewSnippetToolbarItem"];
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)willBeInserted
{
    if ([itemIdentifier isEqualToString:@"NewSnippetCollectionToolbarItem"]) {
        
		NSImage *newSnippetCollectionImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRANewCollectionIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
		[[newSnippetCollectionImage representations][0] setAlpha:YES];
		
		return [NSToolbarItem createToolbarItemWithIdentifier:itemIdentifier name:NEW_COLLECTION_STRING image:newSnippetCollectionImage action:@selector(newCollectionAction:) tag:0 target:self];
		
		
	} else if ([itemIdentifier isEqualToString:@"NewSnippetToolbarItem"]) {
        
		NSImage *newSnippetImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRANewIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
		[[newSnippetImage representations][0] setAlpha:YES];
		
		return [NSToolbarItem createToolbarItemWithIdentifier:itemIdentifier name:NSLocalizedStringFromTable(@"New Snippet", @"Localizable3", @"New Snippet") image:newSnippetImage action:@selector(newSnippetAction:) tag:0 target:self];
		
		
	} else if ([itemIdentifier isEqualToString:@"FilterSnippetsToolbarItem"]) {
		
		return [NSToolbarItem createSeachFieldToolbarItemWithIdentifier:itemIdentifier name:FILTER_STRING view:snippetsFilterView];
		
	}
	
	return nil;
}


#pragma mark - PXSourceList Data Source

- (NSUInteger)sourceList: (PXSourceList*)sourceList numberOfChildrenOfItem:(id)item
{
    if (sourceList == _snippetCollectionsTableView)
    {
        if (!item)
        {
            return [[VASnippetCollection allSnippetCollections] count];
        }
    }else
    {
        
    }
    
    return 0;
}

- (id)sourceList: (PXSourceList*)sourceList
           child: (NSUInteger)index
          ofItem: (id)item
{
    if (sourceList == _snippetCollectionsTableView)
    {
        
        if (!item)
        {
            return [VASnippetCollection allSnippetCollections][index];
        }
        
    }else
    {
        
    }
    return nil;
}

- (BOOL)sourceList:(PXSourceList*)sourceList isItemExpandable:(id)item
{
    return NO;
}

#pragma mark - PXSourceList Delegate

- (BOOL)sourceList:(PXSourceList *)sourceList isGroupAlwaysExpanded:(id)group
{
    return YES;
}

- (NSView *)sourceList:(PXSourceList *)aSourceList viewForItem:(id)item
{
    NSTableCellView *cellView = nil;
    
    if (aSourceList == _snippetCollectionsTableView)
    {
        if ([aSourceList levelForItem:item] == 0)
            cellView = [aSourceList makeViewWithIdentifier:@"HeaderCell" owner:nil];
        else
            cellView = [aSourceList makeViewWithIdentifier:@"MainCell" owner:nil];
        
        VASnippetCollection *collection = item;
        
        // Only allow us to edit the user created photo collection titles.
        BOOL isTitleEditable = YES;
        cellView.textField.editable = isTitleEditable;
        cellView.textField.selectable = isTitleEditable;
        
        cellView.textField.stringValue = [collection name];
    }else
    {
        
    }
    
    return cellView;
}

- (void)sourceListSelectionDidChange: (NSNotification *)notification
{
    VASnippetCollection *selectedItem = [_snippetCollectionsTableView itemAtRow: [_snippetCollectionsTableView selectedRow]];
    
    NSLog(@"%@", [selectedItem name]);
}

#pragma mark - Drag and Drop

- (BOOL)sourceList:(PXSourceList*)aSourceList writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
    
    NSArray *typesArray;
    if (aSourceList == _snippetsTableView)
    {
        typesArray = @[NSStringPboardType, @"FRAMovedSnippetType"];
		
        NSMutableString *string = [NSMutableString stringWithString: @""];
        NSMutableArray *uuidArray = [NSMutableArray arrayWithCapacity: [items count]];
        for (VASnippet *sLooper in items)
        {
            [uuidArray addObject: [sLooper uuid]];
        }
        
		[pboard declareTypes: typesArray
                       owner: self];
		[pboard setString: string
                  forType: NSStringPboardType];
		[pboard setData: [NSArchiver archivedDataWithRootObject: uuidArray]
                forType: @"FRAMovedSnippetType"];
		
		return YES;
	}else
    {
		return NO;
	}
}

- (NSDragOperation)sourceList:(PXSourceList*)sourceList validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
    if (sourceList == _snippetsTableView)
    {
		[sourceList setDropRow: index
                 dropOperation: NSTableViewDropAbove];
	 	return NSDragOperationCopy;
		
	} else if (sourceList == _snippetCollectionsTableView)
    {
		if ([info draggingSource] == _snippetsTableView)
        {
			[sourceList setDropRow: index
                     dropOperation: NSTableViewDropOn];
			return NSDragOperationMove;
		} else
        {
			[sourceList setDropRow: [[VASnippetCollection allSnippetCollections] count]
                     dropOperation: NSTableViewDropAbove];
			return NSDragOperationCopy;
		}
        
		return NSDragOperationCopy;
	}
	
	return NSDragOperationNone;
}

- (BOOL)sourceList:(PXSourceList*)aSourceList acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index
{
	
	// Snippets
    if (aSourceList == _snippetsTableView)
    {
        
        NSString *textToImport = (NSString *)[[info draggingPasteboard] stringForType:NSStringPboardType];
        if (textToImport != nil) {
            
            VASnippet *item = [[FRASnippetsController sharedInstance] performInsertNewSnippet];
            
            [item setText: textToImport];
            
            if ([textToImport length] > SNIPPET_NAME_LENGTH)
            {
                [item setName: [[textToImport substringWithRange:NSMakeRange(0, SNIPPET_NAME_LENGTH)] stringByReplaceAllNewLineCharactersWithSymbol]];
            } else
            {
                [item setName: textToImport];
            }
            
            return YES;
        } else {
            return NO;
        }
        
        // Snippet collections
    } else if (aSourceList == _snippetCollectionsTableView)
    {
        NSArray *filesToImport = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
        
        if (filesToImport != nil)
        {
            [FRAOpenSave openAllTheseFiles:filesToImport];
            return YES;
        }
        
        if ([info draggingSource] == [[FRASnippetsController sharedInstance] snippetsTableView])
        {
//            if (![[[info draggingPasteboard] types] containsObject: movedSnippetType])
//            {
//                return NO;
//            }
//TODO
//            NSArray *pasteboardData = [NSUnarchiver unarchiveObjectWithData: [[info draggingPasteboard] dataForType: movedSnippetType]];
//            NSArray *uriArray = pasteboardData[1];
//            
//            VASnippetCollection *collection = item;
//            
//            id item;
//            for (item in uriArray)
//            {
//                [[collection snippets] addObject: [FRABasic objectFromURI: item]];
//            }
            
            return YES;
        }
    }
    
    return YES;
}

@end
