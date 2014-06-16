//
//  VATMBundleManager.m
//  Fraise
//
//  Created by Lei on 14-6-14.
//
//

#import "VATMBundleManager.h"
#import "VASnippetCollection.h"
#import <VAFoundation/VAFoundation.h>

@interface VATMBundleManager ()<NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (weak) IBOutlet NSOutlineView *sourceListView;
@property (weak) IBOutlet NSView *contentView;

@property (strong) NSArray *draggedNodes;
@property (strong) NSArray *draggedSnippetNodes;
@property (weak) IBOutlet NSWindow *window;

@end

@implementation VATMBundleManager

VASingletonIMP(VATMBundleManager, manager)

- (id)init
{
    if ((self = [super init]))
    {
    }
    
    return self;
}

- (void)showWindow
{
    if (!_window)
    {
        [NSBundle loadNibNamed:@"VATMBundleManager" owner:self];
        
    }
    
    [_window makeKeyAndOrderFront:self];
}


#pragma mark - NSOutlineView data source methods. (The required ones)

// Required methods.
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (!item)
    {
        return [VASnippetCollection allSnippetCollections][index];
    }
    
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if ([item isKindOfClass: [VASnippetCollection class]])
    {
        return YES;
    }
    
    return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    // 'item' may potentially be nil for the root item.
    if (!item)
    {
        return [[VASnippetCollection allSnippetCollections] count];
    }
    
    return 0;
}

- (id)        outlineView: (NSOutlineView *)outlineView
objectValueForTableColumn: (NSTableColumn *)tableColumn
                   byItem: (id)item
{
    id objectValue = nil;
    
    VASnippetCollection *collection = item;
    
    // The return value from this method is used to configure the state of the items cell via setObjectValue:
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString: @"collection"])
    {
        objectValue = [collection name];
    }
    
    NSLog(@"in func:%s value: %@", __func__, [tableColumn identifier]);
    
    return objectValue;
}

// Optional method: needed to allow editing.
- (void)outlineView: (NSOutlineView *)ov
     setObjectValue: (id)object
     forTableColumn: (NSTableColumn *)tableColumn
             byItem: (id)item
{
    VASnippetCollection *collection = item;
    [collection setName: object];
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

- (NSView *)outlineView: (NSOutlineView *)outlineView
     viewForTableColumn: (NSTableColumn *)tableColumn
                   item: (id)item
{
    NSTableCellView *cellView = nil;
    
    if ([item isKindOfClass: [VASnippetCollection class]])
    {
        VASnippetCollection *collection = item;
        cellView = [outlineView makeViewWithIdentifier: @"groupcell"
                                             owner: nil];
        [[cellView textField] setStringValue: [collection name]];
    }else
    {
        cellView = [outlineView makeViewWithIdentifier: @"DataCell"
                                                 owner: nil];
    }
    
    return cellView;
}

- (void)outlineView: (NSOutlineView *)outlineView
    willDisplayCell: (NSCell *)cell
     forTableColumn: (NSTableColumn *)tableColumn
               item: (id)item
{
    //    NSString *tabColumnID = [tableColumn identifier];
    
    VASnippetCollection *collection = item;
    
    if ([[cell identifier] isEqualToString: @"groupcell"])
    {
        [cell setStringValue: [collection name]];
    }
    
    NSLog(@"in func:%s value: %@ %@", __func__, [tableColumn identifier], [cell identifier]);

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
        NSRect cellFrame = [ov frameOfCellAtColumn: [[ov tableColumns] indexOfObject: tableColumn]
                                               row: [ov rowForItem: item]];
        NSUInteger hitTestResult = [cell hitTestForEvent: [NSApp currentEvent]
                                                  inRect: cellFrame
                                                  ofView: ov];
        
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
        return [ov isRowSelected:[ov rowForItem: item]];
    }
}

/* In 10.7 multiple drag images are supported by using this delegate method. */
- (id <NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView pasteboardWriterForItem:(id)item
{
    VASnippetCollection *collection = item;
    return [collection  name];
}

- (void)outlineViewSelectionDidChange: (NSNotification *)notification
{
    //    NSOutlineView *outlineView = [notification object];
    //
    //    VASnippetCollection *collection = [outlineView itemAtRow: [outlineView selectedRow]];
}

#pragma mark - drag

- (void)outlineView: (NSOutlineView *)outlineView
    draggingSession: (NSDraggingSession *)session
   willBeginAtPoint: (NSPoint)screenPoint
           forItems: (NSArray *)draggedItems
{
    _draggedNodes = draggedItems;
    [session.draggingPasteboard setData: [NSData data]
                                forType: @"com.veritas.fraise.pasteboard.data"];
}

- (void)outlineView: (NSOutlineView *)outlineView
    draggingSession: (NSDraggingSession *)session
       endedAtPoint: (NSPoint)screenPoint
          operation: (NSDragOperation)operation
{
    // If the session ended in the trash, then delete all the items
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
}

@end
