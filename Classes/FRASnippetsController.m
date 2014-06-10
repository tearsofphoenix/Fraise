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

@synthesize snippetsTextView, snippetsWindow, snippetCollectionsArrayController, snippetsTableView, snippetsArrayController;

VASingletonIMPDefault(FRASnippetsController)

- (void)openSnippetsWindow
{
	if (snippetsWindow == nil)
    {
		[NSBundle loadNibNamed:@"FRASnippets.nib" owner:self];
		
		[_snippetCollectionsTableView setDataSource: self];
		[snippetsTableView setDataSource:[FRADragAndDropController sharedInstance]];
		
		[_snippetCollectionsTableView registerForDraggedTypes: @[NSFilenamesPboardType, @"FRAMovedSnippetType"]];
		[_snippetCollectionsTableView setDraggingSourceOperationMask:(NSDragOperationCopy) forLocal:NO];
		
		[snippetsTableView registerForDraggedTypes:@[NSStringPboardType]];
		[snippetsTableView setDraggingSourceOperationMask:(NSDragOperationCopy) forLocal:NO];
		
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
		[snippetCollectionsArrayController setSortDescriptors:@[sortDescriptor]];
		[snippetsArrayController setSortDescriptors:@[sortDescriptor]];
		
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
	[snippetCollectionsArrayController commitEditing];
	VASnippetCollection *collection = [[VASnippetCollection alloc] init];
	
	[snippetCollectionsArrayController setSelectedObjects:@[collection]];
	
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
	[snippetsArrayController commitEditing];
	[self performInsertNewSnippet];
	
	[snippetsWindow makeFirstResponder:snippetsTableView];
	[snippetsTableView editColumn:0 row:[snippetsTableView selectedRow] withEvent:nil select:NO];
}


- (id)performInsertNewSnippet
{
	VASnippetCollection *collection;
	NSArray *snippetCollections = [VASnippetCollection allSnippetCollections];

	if ([snippetCollections count] == 0)
    {
		collection = [[VASnippetCollection alloc] init];
		[collection setName: COLLECTION_STRING];
	} else
    {
		if (snippetsWindow != nil && [[snippetCollectionsArrayController selectedObjects] count] != 0)
        {
			collection = [snippetCollectionsArrayController selectedObjects][0];
		} else { // If no collection is selected choose the last one in the array
			collection = [snippetCollections lastObject];
		}
	}
	
	VASnippet *item = [[VASnippet alloc] init];
    
	[[collection snippets] addObject: item];
	[FRAManagedObjectContext processPendingChanges];
	[snippetsArrayController setSelectedObjects:@[item]];
	
	return item;
}


- (void)insertSnippet:(id)snippet
{
	FRATextView *textView = FRACurrentTextView;
	if ([FRAMain isInFullScreenMode]) {
		textView = [[FRAInterface fullScreenDocument] valueForKey:@"thirdTextView"];
	}
	if (textView == nil) {
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
	id collection = [snippetCollectionsArrayController selectedObjects][0];
    
	[FRAManagedObjectContext deleteObject:collection];
	
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
		
		[FRAManagedObjectContext processPendingChanges];
		
		[snippetCollectionsArrayController setSelectedObjects:@[collection]];
	} else {
		NSBeep();
	}
}


- (void)exportSnippets
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes: @[@"fraiseSnippets"]];
    [savePanel setDirectoryURL: [NSURL fileURLWithPath: [FRAInterface whichDirectoryForSave]]];
    [savePanel setNameFieldStringValue: [[snippetCollectionsArrayController selectedObjects][0] valueForKey:@"name"]];
    [savePanel beginSheetModalForWindow: snippetsWindow
                      completionHandler: (^(NSInteger result)
                                          {
                                              if (result == NSOKButton)
                                              {
                                                  VASnippetCollection *collection = [snippetCollectionsArrayController selectedObjects][0];
                                                  
                                                  NSMutableArray *exportArray = [NSMutableArray array];
                                                  NSArray *array = [collection snippets];
                                                  for (id item in array)
                                                  {
                                                      NSMutableDictionary *snippet = [NSMutableDictionary dictionary];
                                                      snippet[@"name"] = [item valueForKey:@"name"];
                                                      snippet[@"text"] = [item valueForKey:@"text"];
                                                      snippet[@"collectionName"] = [collection name];
                                                      snippet[@"shortcutDisplayString"] = [item valueForKey:@"shortcutDisplayString"];
                                                      snippet[@"shortcutMenuItemKeyString"] = [item valueForKey:@"shortcutMenuItemKeyString"];
                                                      snippet[@"shortcutModifier"] = [item valueForKey:@"shortcutModifier"];
                                                      snippet[@"sortOrder"] = [item valueForKey:@"sortOrder"];
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
	[snippetCollectionsArrayController commitEditing];
	[snippetsArrayController commitEditing];
}


- (NSManagedObjectContext *)managedObjectContext
{
	return FRAManagedObjectContext;
}


- (NSTextView *)snippetsTextView
{
	return snippetsTextView;
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

- (NSUInteger)sourceList:(PXSourceList*)sourceList numberOfChildrenOfItem:(id)item
{
    if (!item)
    {
        return [[VASnippetCollection allSnippetCollections] count];
    }

    return 0;
}

- (id)sourceList: (PXSourceList*)aSourceList
           child: (NSUInteger)index
          ofItem: (id)item
{
    if (!item)
    {
        return [VASnippetCollection allSnippetCollections][index];
    }
    
    return nil;
}

- (BOOL)sourceList:(PXSourceList*)aSourceList isItemExpandable:(id)item
{
    return NO;
}

#pragma mark - PXSourceList Delegate

- (BOOL)sourceList:(PXSourceList *)aSourceList isGroupAlwaysExpanded:(id)group
{
    return YES;
}

- (NSView *)sourceList:(PXSourceList *)aSourceList viewForItem:(id)item
{
    PXSourceListTableCellView *cellView = nil;
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

//    cellView.imageView.image = [item icon];
    cellView.badgeView.hidden = YES;
    
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
    
    // For simplicity in this example, put the dragged indexes on the pasteboard. Since we use the representedObject
    // on SourceListItem, we cannot reliably archive it directly.
//    NSMutableIndexSet *draggedChildIndexes = [NSMutableIndexSet indexSet];
//    for (PXSourceListItem *item in items)
//        [draggedChildIndexes addIndex:[[parentItem children] indexOfObject:item]];
//    
//    [pboard declareTypes:@[draggingType] owner:self];
//    [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:draggedChildIndexes] forType:draggingType];
    
    return YES;
}

- (NSDragOperation)sourceList:(PXSourceList*)sourceList validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
//    PXSourceListItem *albumsItem = self.albumsItem;
    
    // Only allow the items in the 'albums' group to be moved around. It can either be dropped on the group header, or inserted between other child items.
    // It can't be made the child of another item in this group, so the only valid case is when the proposedItem is the 'Albums' group item.
//    if (![item isEqual:albumsItem])
//        return NSDragOperationNone;
    
    return NSDragOperationMove;
}

- (BOOL)sourceList:(PXSourceList*)aSourceList acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index
{
    /*
    NSPasteboard *draggingPasteboard = info.draggingPasteboard;
    NSMutableIndexSet *draggedChildIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:[draggingPasteboard dataForType:draggingType]];
    
    PXSourceListItem *parentItem = self.albumsItem;
    NSMutableArray *draggedItems = [NSMutableArray array];
    [draggedChildIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [draggedItems addObject:[[parentItem children] objectAtIndex:idx]];
    }];
    
    // An index of -1 means it's been dropped on the group header itself, so insert at the end of the group.
    if (index == -1)
        index = parentItem.children.count;
    
    // Perform the Source List and model updates.
    [aSourceList beginUpdates];
    [aSourceList removeItemsAtIndexes:draggedChildIndexes
                             inParent:parentItem
                        withAnimation:NSTableViewAnimationEffectNone];
    [parentItem removeChildItems:draggedItems];
    
    // We have to calculate the new child index which we have to perform the drop at, since we've just removed items from the parent item which
    // may have come before the drop index.
    NSUInteger adjustedDropIndex = index - [draggedChildIndexes countOfIndexesInRange:NSMakeRange(0, index)];
    
    // The insertion indexes are now simply from the adjusted drop index.
    NSIndexSet *insertionIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(adjustedDropIndex, draggedChildIndexes.count)];
    [parentItem insertChildItems:draggedItems atIndexes:insertionIndexes];
    
    [aSourceList insertItemsAtIndexes:insertionIndexes
                             inParent:parentItem
                        withAnimation:NSTableViewAnimationEffectNone];
    [aSourceList endUpdates];
    */
    return YES;
}

@end
