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


@interface FRASnippetsController ()<NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (nonatomic, strong) NSArray *draggedNodes;
@property (nonatomic, strong) NSArray *draggedSnippetNodes;

@end

@implementation FRASnippetsController

VASingletonIMPDefault(FRASnippetsController)

- (void)openSnippetsWindow
{
	if (_snippetsWindow == nil)
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
		[_snippetsWindow setToolbar:toolbar];
	}
	
	[_snippetsWindow makeKeyAndOrderFront:self];
	[[FRAToolsMenuController sharedInstance] buildInsertSnippetMenu];
	
}


- (IBAction)newCollectionAction:(id)sender
{
	VASnippetCollection *collection = [[VASnippetCollection alloc] init];
	
	_selectedCollection = collection;
	
	[_snippetsWindow makeFirstResponder:_snippetCollectionsTableView];
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
	
	[_snippetsWindow makeFirstResponder:_snippetsTableView];
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
		if (_snippetsWindow != nil && _selectedCollection)
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
    [openPanel beginSheetModalForWindow: _snippetsWindow
                      completionHandler: (^(NSInteger result)
                                          {
                                              
                                              if (result == NSOKButton)
                                              {
                                                  [self performSnippetsImportWithPath: [[openPanel URL] path]];
                                              }
                                              [_snippetsWindow makeKeyAndOrderFront:nil];
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
            
			[snippet setName: item[@"name"]];
			[snippet setText: item[@"text"]];
			[snippet setCollectionName: item[@"collectionName"]];
			[snippet setShortcutDisplayString: item[@"shortcutDisplayString"]];
			[snippet setShortcutMenuItemKeyString: item[@"shortcutMenuItemKeyString"]];
			[snippet setShortcutModifier: [item[@"shortcutModifier"] integerValue]];
			[snippet setSortOrder: [item[@"sortOrder"] integerValue]];
            
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
    [savePanel beginSheetModalForWindow: _snippetsWindow
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
                                              
                                              [_snippetsWindow makeKeyAndOrderFront:nil];
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


#pragma mark - NSOutlineView data source methods. (The required ones)

// Required methods.
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (outlineView == _snippetCollectionsTableView)
    {
        if (!item)
        {
            return [VASnippetCollection allSnippetCollections][index];
        }
    }else if (outlineView == _snippetsTableView)
    {
        if (!item)
        {
            return [_selectedCollection snippets][index];
        }
    }
    
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    // 'item' may potentially be nil for the root item.
    if (outlineView == _snippetCollectionsTableView)
    {
        if (!item)
        {
            return [[VASnippetCollection allSnippetCollections] count];
        }
    }else if (outlineView == _snippetsTableView)
    {
        if (!item)
        {
            return [[_selectedCollection snippets] count];
        }
    }
    
    return 0;
}

- (id)        outlineView: (NSOutlineView *)outlineView
objectValueForTableColumn: (NSTableColumn *)tableColumn
                   byItem: (id)item
{
    id objectValue = nil;
    
    if (outlineView == _snippetCollectionsTableView)
    {
        VASnippetCollection *collection = item;
        
        // The return value from this method is used to configure the state of the items cell via setObjectValue:
        if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString: @"collection"])
        {
            objectValue = [collection name];
        }
    }else if (outlineView == _snippetsTableView)
    {
        VASnippet *snippet = item;
        objectValue = [snippet name];
    }
    
    return objectValue;
}

// Optional method: needed to allow editing.
- (void)outlineView: (NSOutlineView *)ov
     setObjectValue: (id)object
     forTableColumn: (NSTableColumn *)tableColumn
             byItem: (id)item
{
    if (ov == _snippetCollectionsTableView)
    {
        VASnippetCollection *collection = item;
        [collection setName: object];
        
    }else if (ov == _snippetsTableView)
    {
        VASnippet *snippet = item;
        [snippet setName: object];
    }
}

// We can return a different cell for each row, if we want
- (NSCell *)outlineView: (NSOutlineView *)ov
 dataCellForTableColumn: (NSTableColumn *)tableColumn
                   item: (id)item
{
    // If we return a cell for the 'nil' tableColumn, it will be used as a "full width" cell and span all the columns
    {
        // We want to use the cell for the name column, but we could construct a new cell if we wanted to, or return a different cell for each row.
        //return [[_outlineView tableColumnWithIdentifier:COLUMNID_NAME] dataCell];
    }
    return [tableColumn dataCell];
}

// To get the "group row" look, we implement this method.
- (BOOL)outlineView: (NSOutlineView *)outlineView
        isGroupItem: (id)item
{
    return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item
{
    return YES;
}

- (void)outlineView: (NSOutlineView *)outlineView
    willDisplayCell: (NSCell *)cell
     forTableColumn: (NSTableColumn *)tableColumn
               item: (id)item
{
    NSString *tabColumnID = [tableColumn identifier];
    
    if (outlineView == _snippetCollectionsTableView)
    {
        VASnippetCollection *collection = item;
        
        if ((tableColumn == nil) || [tabColumnID isEqualToString: @"collection"])
        {
            [cell setStringValue: [collection name]];
        }
        
    }else if (outlineView == _snippetsTableView)
    {
        VASnippet *snippet = item;
        if ([tabColumnID isEqualToString: @"name"])
        {
            [cell setStringValue: [snippet name]];
        }else if ([tabColumnID isEqualToString: @"shortcut"])
        {
            [cell setStringValue: [snippet shortcutDisplayString] ?: @""];
        }
    }
}

- (BOOL)outlineView: (NSOutlineView *)ov
   shouldSelectItem: (id)item
{
    return YES;
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    // We want to allow tracking for all the button cells, even if we don't allow selecting that particular row.
    if ([cell isKindOfClass:[NSButtonCell class]])
    {
        // We can also take a peek and make sure that the part of the cell clicked is an area that is normally tracked. Otherwise, clicking outside of the checkbox may make it check the checkbox
        NSRect cellFrame = [_snippetCollectionsTableView frameOfCellAtColumn: [[_snippetCollectionsTableView tableColumns] indexOfObject: tableColumn]
                                                                         row: [_snippetCollectionsTableView rowForItem: item]];
        NSUInteger hitTestResult = [cell hitTestForEvent: [NSApp currentEvent]
                                                  inRect: cellFrame
                                                  ofView: _snippetCollectionsTableView];
        
        if ((hitTestResult & NSCellHitTrackableArea) != 0)
        {
            return YES;
        } else
        {
            return NO;
        }
    } else
    {
        // Only allow tracking on selected rows. This is what NSTableView does by default.
        return [_snippetCollectionsTableView isRowSelected:[_snippetCollectionsTableView rowForItem: item]];
    }
}

/* In 10.7 multiple drag images are supported by using this delegate method. */
- (id <NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView pasteboardWriterForItem:(id)item
{
    if (outlineView == _snippetCollectionsTableView)
    {
        VASnippetCollection *collection = item;
        return [collection  name];
    }else if (outlineView == _snippetsTableView)
    {
        VASnippet *snippet = item;
        return [snippet name];
    }
    
    return nil;
}

- (void)outlineViewSelectionDidChange: (NSNotification *)notification
{
    NSOutlineView *outlineView = [notification object];
    if (outlineView == _snippetCollectionsTableView)
    {
        VASnippetCollection *collection = [outlineView itemAtRow: [outlineView selectedRow]];
        [self setSelectedCollection: collection];
        
        [_snippetsTableView reloadData];
        
    }else if (outlineView == _snippetsTableView)
    {
        VASnippet *snippet = [outlineView itemAtRow: [outlineView selectedRow]];
        [_snippetsTextView setString: [snippet text]];
    }
}

#pragma mark - drag

- (void)outlineView: (NSOutlineView *)outlineView
    draggingSession: (NSDraggingSession *)session
   willBeginAtPoint: (NSPoint)screenPoint
           forItems: (NSArray *)draggedItems
{
    if (outlineView == _snippetCollectionsTableView)
    {
        _draggedNodes = draggedItems;
        [session.draggingPasteboard setData: [NSData data]
                                    forType: @"com.veritas.fraise.pasteboard.data"];
    }else
    {
        _draggedSnippetNodes = draggedItems;
    }
}

- (void)outlineView: (NSOutlineView *)outlineView
    draggingSession: (NSDraggingSession *)session
       endedAtPoint: (NSPoint)screenPoint
          operation: (NSDragOperation)operation
{
    // If the session ended in the trash, then delete all the items
    if (outlineView == _snippetCollectionsTableView)
    {
        if (operation == NSDragOperationDelete)
        {
            [outlineView beginUpdates];
            
            [_draggedNodes enumerateObjectsWithOptions: NSEnumerationReverse
                                            usingBlock: (^(id node, NSUInteger index, BOOL *stop)
                                                         {
                                                             id parent = [node parentNode];
                                                             NSMutableArray *children = [parent mutableChildNodes];
                                                             NSInteger childIndex = [children indexOfObject:node];
                                                             [children removeObjectAtIndex:childIndex];
                                                             [outlineView removeItemsAtIndexes: [NSIndexSet indexSetWithIndex:childIndex]
                                                                                      inParent: nil
                                                                                 withAnimation: NSTableViewAnimationEffectFade];
                                                         })];
            
            [outlineView endUpdates];
        }
        _draggedNodes = nil;
    }else if (outlineView == _snippetsTableView)
    {
        if (operation == NSDragOperationDelete)
        {
            [outlineView beginUpdates];
            
            [_draggedSnippetNodes enumerateObjectsWithOptions: NSEnumerationReverse
                                                   usingBlock: (^(id node, NSUInteger index, BOOL *stop)
                                                                {
                                                                    id parent = [node parentNode];
                                                                    NSMutableArray *children = [parent mutableChildNodes];
                                                                    NSInteger childIndex = [children indexOfObject:node];
                                                                    [children removeObjectAtIndex:childIndex];
                                                                    [outlineView removeItemsAtIndexes: [NSIndexSet indexSetWithIndex:childIndex]
                                                                                             inParent: nil
                                                                                        withAnimation: NSTableViewAnimationEffectFade];
                                                                })];
            
            [outlineView endUpdates];
        }
        _draggedSnippetNodes = nil;
    }
}

@end
