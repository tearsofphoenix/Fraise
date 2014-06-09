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

#import "FRAProject+TableViewDelegate.h"
#import "FRAApplicationDelegate.h"
#import "FRADocumentsListCell.h"
#import "FRAInterfacePerformer.h"
#import "FRAVariousPerformer.h"
#import "FRASyntaxColouring.h"
#import "VADocument.h"

#import "FRAProject+DocumentViewsController.h"

#import <PXSourceList/PXSourceList.h>

@implementation FRAProject (TableViewDelegate)


- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSTableView *tableView = [aNotification object];
	if (tableView == [self documentsTableView] || aNotification == nil) {
		if ([[FRAApplicationDelegate sharedInstance] isTerminatingApplication] == YES) {
			return;
		}
		if ([[[self documentsArrayController] arrangedObjects] count] < 1 || [[[self documentsArrayController] selectedObjects] count] < 1) {
			[self updateWindowTitleBarForDocument:nil];
			return;
		}
		
		id document = [[self documentsArrayController] selectedObjects][0];
		
		[self performInsertFirstDocument:document];
	}
	
}


- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ([[FRADefaults valueForKey:@"SizeOfDocumentsListTextPopUp"] integerValue] == 0) {
		[aCell setFont:[NSFont systemFontOfSize:11.0]];
	} else {
		[aCell setFont:[NSFont systemFontOfSize:13.0]];
	}
	
	if (aTableView == [self documentsTableView]) {
		id document = [[self documentsArrayController] arrangedObjects][rowIndex];
		
		if ([document isNewDocument] == YES) {
			[aTableView addToolTipRect:[aTableView rectOfRow:rowIndex] owner:UNSAVED_STRING userData:nil];
		} else {
			if ([document fromExternal]) {
				[aTableView addToolTipRect:[aTableView rectOfRow:rowIndex] owner:[document externalPath] userData:nil];
			} else {
				[aTableView addToolTipRect:[aTableView rectOfRow:rowIndex] owner:[document path] userData:nil];
			}
		}
		
		if ([[aTableColumn identifier] isEqualToString:@"name"]) {
			NSImage *image;
			if ([document isEdited] == YES) {
				image = [document unsavedIcon];
			} else {
				image = [document icon];
			}

			[(FRADocumentsListCell *)aCell setHeightAndWidth:[[[self valueForKey:@"project"] valueForKey:@"viewSize"] doubleValue]];
			[(FRADocumentsListCell *)aCell setImage:image];
			
			if ([[FRADefaults valueForKey:@"ShowFullPathInDocumentsList"] boolValue] == YES) {
				[(FRADocumentsListCell *)aCell setStringValue:[document nameWithPath]];
			} else {
				[(FRADocumentsListCell *)aCell setStringValue:[document name]];
			}
		}
		
	}
}


- (void)performInsertFirstDocument:(id)document
{	
	[self setFirstDocument:document];
	
	[FRAInterface removeAllSubviewsFromView: [self firstContentView]];
	[[self firstContentView] addSubview:[document firstTextScrollView]];
	if ([document showLineNumberGutter] == YES) {
		[[self firstContentView] addSubview: [document firstGutterScrollView]];
	}
	
	[self updateWindowTitleBarForDocument:document];
	[self resizeViewsForDocument:document]; // If the window has changed since the view was last visible
	[[self documentsTableView] scrollRowToVisible:[[self documentsTableView] selectedRow]];
	
	[[self window] makeFirstResponder:[document firstTextView]];
    NSClipView *clipView = [[document firstTextScrollView] contentView];
	[[document lineNumbers] updateLineNumbersForClipView: clipView
                                                             checkWidth: NO]; // If the window has changed since the view was last visible
    [[document syntaxColouring] pageRecolourTextView: [clipView documentView]];

	[FRAInterface updateStatusBar];
	
	[self selectSameDocumentInTabBarAsInDocumentsList];
}


#pragma mark - PXSourceList Data Source

- (NSUInteger)sourceList:(PXSourceList*)sourceList numberOfChildrenOfItem:(id)item
{
    if (!item)
    {
        return [[self documents] count];
    }
    
    return [[item children] count];
}

- (id)sourceList:(PXSourceList*)aSourceList child:(NSUInteger)index ofItem:(id)item
{
    if (!item)
    {
        return [self documents][index];
    }
    
    return [[item children] objectAtIndex:index];
}

- (BOOL)sourceList:(PXSourceList*)aSourceList isItemExpandable:(id)item
{
    return [item hasChildren];
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
    
    PXSourceListItem *sourceListItem = item;
    VADocument *document =  [sourceListItem representedObject];
    
    // Only allow us to edit the user created photo collection titles.
    BOOL isTitleEditable = YES;

    cellView.textField.editable = isTitleEditable;
    cellView.textField.selectable = isTitleEditable;
    
    cellView.textField.stringValue = sourceListItem.title ? sourceListItem.title : [sourceListItem.representedObject title];
    cellView.imageView.image = [item icon];
    cellView.badgeView.hidden = YES;
    cellView.badgeView.badgeValue = 0;
    
    return cellView;
}

- (void)sourceListSelectionDidChange:(NSNotification *)notification
{
    PXSourceListItem *selectedItem = [[self documentsTableView] itemAtRow: [[self documentsTableView] selectedRow]];

    NSString *newLabel = @"";
    if (selectedItem)
    {
        // We can use the underlying model object to do something based on the selection.
//        VADocument *document = [selectedItem representedObject];
        
        newLabel = @"User-created collection selected.";
    }
}

#pragma mark - Drag and Drop

- (BOOL)sourceList:(PXSourceList*)aSourceList writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
//    // For simplicity in this example, put the dragged indexes on the pasteboard. Since we use the representedObject
//    // on SourceListItem, we cannot reliably archive it directly.
//    NSMutableIndexSet *draggedChildIndexes = [NSMutableIndexSet indexSet];
//    for (PXSourceListItem *item in items)
//    {
//        [draggedChildIndexes addIndex:[[parentItem children] indexOfObject:item]];
//    }
//    
//    [pboard declareTypes:@[draggingType] owner:self];
//    [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:draggedChildIndexes] forType:draggingType];
    
    return YES;
}

- (NSDragOperation)sourceList:(PXSourceList*)sourceList validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
//    PXSourceListItem *albumsItem = self.albumsItem;
//    
//    // Only allow the items in the 'albums' group to be moved around. It can either be dropped on the group header, or inserted between other child items.
//    // It can't be made the child of another item in this group, so the only valid case is when the proposedItem is the 'Albums' group item.
//    if (![item isEqual:albumsItem])
//        return NSDragOperationNone;
    
    return NSDragOperationMove;
}

- (BOOL)sourceList:(PXSourceList*)aSourceList acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index
{
//    NSPasteboard *draggingPasteboard = info.draggingPasteboard;
//    NSMutableIndexSet *draggedChildIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:[draggingPasteboard dataForType:draggingType]];
//    
//    PXSourceListItem *parentItem = self.albumsItem;
//    NSMutableArray *draggedItems = [NSMutableArray array];
//    [draggedChildIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
//        [draggedItems addObject:[[parentItem children] objectAtIndex:idx]];
//    }];
//    
//    // An index of -1 means it's been dropped on the group header itself, so insert at the end of the group.
//    if (index == -1)
//        index = parentItem.children.count;
//    
//    // Perform the Source List and model updates.
//    [aSourceList beginUpdates];
//    [aSourceList removeItemsAtIndexes:draggedChildIndexes
//                             inParent:parentItem
//                        withAnimation:NSTableViewAnimationEffectNone];
//    [parentItem removeChildItems:draggedItems];
//    
//    // We have to calculate the new child index which we have to perform the drop at, since we've just removed items from the parent item which
//    // may have come before the drop index.
//    NSUInteger adjustedDropIndex = index - [draggedChildIndexes countOfIndexesInRange:NSMakeRange(0, index)];
//    
//    // The insertion indexes are now simply from the adjusted drop index.
//    NSIndexSet *insertionIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(adjustedDropIndex, draggedChildIndexes.count)];
//    [parentItem insertChildItems:draggedItems atIndexes:insertionIndexes];
//    
//    [aSourceList insertItemsAtIndexes:insertionIndexes
//                             inParent:parentItem
//                        withAnimation:NSTableViewAnimationEffectNone];
//    [aSourceList endUpdates];
    
    return YES;
}

@end
