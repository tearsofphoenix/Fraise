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

#import "FRACommandsController.h"
#import "FRADocumentsListCell.h"
#import "FRAApplicationDelegate.h"
#import "FRABasicPerformer.h"
#import "FRADragAndDropController.h"
#import "FRAToolsMenuController.h"
#import "FRAInterfacePerformer.h"
#import "FRAProjectsController.h"
#import "FRAVariousPerformer.h"
#import "FRAOpenSavePerformer.h"
#import "FRATextView.h"

#import "VACommand.h"
#import "VACommandCollection.h"
#import "VADocument.h"

#import <VADevUIKit/VADevUIKit.h>

@interface FRACommandsController ()<NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (nonatomic, strong) NSArray *draggedNodes;
@property (nonatomic, strong) NSArray *draggedCommandNodes;

@end

@implementation FRACommandsController

VASingletonIMPDefault(FRACommandsController)

- (instancetype)init
{
    if ((self = [super init]))
    {
		temporaryFilesArray = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void)openCommandsWindow
{
	if (_commandsWindow == nil)
    {
		[NSBundle loadNibNamed:@"FRACommands.nib" owner:self];
		
		[_commandCollectionsTableView setDataSource: self];
        [_commandCollectionsTableView setDelegate: self];
		[_commandsTableView setDataSource: self];
        [_commandsTableView setDelegate: self];
		
		[_commandCollectionsTableView registerForDraggedTypes:@[NSFilenamesPboardType, @"FRAMovedCommandType"]];
		[_commandCollectionsTableView setDraggingSourceOperationMask:(NSDragOperationCopy) forLocal:NO];
		
		[_commandsTableView registerForDraggedTypes:@[NSStringPboardType]];
		[_commandsTableView setDraggingSourceOperationMask:(NSDragOperationCopy) forLocal:NO];
				
		FRADocumentsListCell *cell = [[FRADocumentsListCell alloc] init];
		[cell setWraps:NO];
		[cell setLineBreakMode:NSLineBreakByTruncatingMiddle];
		[[_commandCollectionsTableView tableColumnWithIdentifier:@"collection"] setDataCell:cell];
		
		
		NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"CommandsToolbarIdentifier"];
		[toolbar setShowsBaselineSeparator:YES];
		[toolbar setAllowsUserCustomization:YES];
		[toolbar setAutosavesConfiguration:YES];
		[toolbar setDisplayMode:NSToolbarDisplayModeDefault];
		[toolbar setSizeMode:NSToolbarSizeModeSmall];
		[toolbar setDelegate:self];
		[_commandsWindow setToolbar:toolbar];
		
		//[_commandCollectionsTableView setBackgroundColor:[[NSColor controlAlternatingRowBackgroundColors] objectAtIndex:1]];
        
	}
	
	[_commandsWindow makeKeyAndOrderFront:self];
	[[FRAToolsMenuController sharedInstance] buildRunCommandMenu];
}


- (IBAction)newCollectionAction:(id)sender
{
	VACommandCollection *collection = [[VACommandCollection alloc] init];
	
    [self setSelectedCollection: collection];
	
	[_commandsWindow makeFirstResponder: _commandCollectionsTableView];
	[_commandCollectionsTableView editColumn:0 row:[_commandCollectionsTableView selectedRow] withEvent:nil select:NO];
}


- (IBAction)newCommandAction:(id)sender
{
	VACommandCollection *collection;
	NSArray *commandCollections = [VACommandCollection allCommandCollections];

	if ([commandCollections count] == 0)
    {
		collection = [[VACommandCollection alloc] init];

		[collection setName: COLLECTION_STRING];
	}
    
	[self performInsertNewCommand];
	
	[_commandsWindow makeFirstResponder:_commandsTableView];
	[_commandsTableView editColumn:0 row:[_commandsTableView selectedRow] withEvent:nil select:NO];
}


- (id)performInsertNewCommand
{
	VACommandCollection *collection;
	NSArray *commandCollections = [VACommandCollection allCommandCollections];

	if ([commandCollections count] == 0)
    {
		collection = [[VACommandCollection alloc] init];
		[collection setName: COLLECTION_STRING];
	} else
    {
        
		if (_commandsWindow != nil && _selectedCollection)
        {
			collection = _selectedCollection;
		} else { // If no collection is selected choose the last one in the array
			collection = [commandCollections lastObject];
		}
	}
	
	id item = [[VACommand alloc] init];
	[[collection commands] addObject: item];

    [self setSelectedCommand: item];
	
	return item;
}


- (void)performDeleteCollection
{
    [VACommandCollection removeCollection: _selectedCollection];
    [_commandCollectionsTableView reloadData];
	[[FRAToolsMenuController sharedInstance] buildRunCommandMenu];
}


- (void)importCommands
{
	[self openCommandsWindow];
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setResolvesAliases:YES];
    [openPanel setDirectoryURL: [NSURL fileURLWithPath: [FRAInterface whichDirectoryForOpen]]];
    [openPanel setAllowedFileTypes: @[@"fraiseCommands"]];
    [openPanel beginSheetModalForWindow: _commandsWindow
                      completionHandler: (^(NSInteger returnCode)
                                          {
                                              if (returnCode == NSOKButton)
                                              {
                                                  [self performCommandsImportWithPath: [[openPanel URL] path]];
                                              }
                                              [_commandsWindow makeKeyAndOrderFront:nil];
                                          })];
}


- (void)performCommandsImportWithPath:(NSString *)path
{
	NSData *data = [NSData dataWithContentsOfFile:path];
	NSArray *commands = (NSArray *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	if ([commands count] == 0)
    {
		return;
	}
	
	VACommandCollection *collection = [[VACommandCollection alloc] init];
	[collection setName: commands[0][@"collectionName"]];
	
	for (NSDictionary *item in commands)
    {
		VACommand *command = [[VACommand alloc] init];
		[command setName:item[@"name"]];
		[command setText:item[@"text"]];
		[command setCollectionName: item[@"collectionName"]];
		[command setShortcutDisplayString: item[@"shortcutDisplayString"]];
		[command setShortcutMenuItemKeyString: item[@"shortcutMenuItemKeyString"]];
		[command setShortcutModifier: [item[@"shortcutModifier"] integerValue]];
		[command setSortOrder: [item[@"sortOrder"] integerValue]];
		
        [command setIsInline: [item[@"inline"] boolValue]];

        [command setInterpreter: item[@"interpreter"]];

        [[collection commands] addObject: command];
	}
		
    _selectedCollection = collection;
}


- (void)exportCommands
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes: @[@"fraiseCommands"]];
    [savePanel setDirectoryURL: [NSURL fileURLWithPath: [FRAInterface whichDirectoryForSave]]];
    [savePanel setNameFieldStringValue: [_selectedCollection name]];
    [savePanel beginSheetModalForWindow: _commandsWindow
                      completionHandler: (^(NSInteger returnCode)
                                          {
                                              if (returnCode == NSOKButton)
                                              {
                                                  VACommandCollection *collection = _selectedCollection;
                                                  
                                                  NSMutableArray *exportArray = [NSMutableArray array];
                                                  NSEnumerator *enumerator = [[collection commands] objectEnumerator];
                                                  for (VACommand *item in enumerator)
                                                  {
                                                      NSMutableDictionary *command = [[NSMutableDictionary alloc] init];
                                                      command[@"name"] = [item name];
                                                      command[@"text"] = [item text];
                                                      command[@"collectionName"] = [collection name];
                                                      command[@"shortcutDisplayString"] = [item shortcutDisplayString];
                                                      command[@"shortcutMenuItemKeyString"] = [item shortcutMenuItemKeyString];
                                                      command[@"shortcutModifier"] = @([item shortcutModifier]);
                                                      command[@"sortOrder"] = @([item sortOrder]);
                                                      command[@"version"] = @3;
                                                      command[@"inline"] = @([item isInline]);
                                                      command[@"interpreter"] = [item interpreter];
                                                      [exportArray addObject: command];
                                                  }
                                                  
                                                  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:exportArray];
                                                  [FRAOpenSave performDataSaveWith: data
                                                                              path: [[savePanel URL] path]];
                                              }
                                              
                                              [_commandsWindow makeKeyAndOrderFront:nil];

                                          })];
}

- (void)windowWillClose:(NSNotification *)aNotification
{

}

- (IBAction)runAction:(id)sender
{
	[self runCommand: _selectedCommand];
}


- (IBAction)insertPathAction:(id)sender
{
	id document = FRACurrentDocument;
	if (document == nil || [document path] == nil) {
		NSBeep();
		return;
	}
	
	[_commandsTextView insertText:[document path]];
}


- (IBAction)insertDirectoryAction:(id)sender
{
	id document = FRACurrentDocument;
	if (document == nil || [document path] == nil) {
		NSBeep();
		return;
	}
	
	[_commandsTextView insertText:[[document path] stringByDeletingLastPathComponent]];
}


- (NSString *)commandToRunFromString:(NSString *)string
{
	NSMutableString *returnString = [NSMutableString stringWithString:string];
	id document = FRACurrentDocument;
	if (document == nil || [document isNewDocument] || [document path] == nil) {
		[returnString replaceOccurrencesOfString:@"%%p" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
		[returnString replaceOccurrencesOfString:@"%%d" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
	} else {
		NSString *path = [NSString stringWithFormat:@"\"%@\"", [document path]]; // If there's a space in the path
		NSString *directory;
		if ([[FRADefaults valueForKey:@"PutQuotesAroundDirectory"] boolValue] == YES) {
			directory = [NSString stringWithFormat:@"\"%@\"", [[document path] stringByDeletingLastPathComponent]];
		} else {
			directory = [NSString stringWithFormat:@"%@", [[document path] stringByDeletingLastPathComponent]];
		}
		[returnString replaceOccurrencesOfString:@"%%p" withString:path options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
		[returnString replaceOccurrencesOfString:@"%%d" withString:directory options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
	}
	
	if ([FRACurrentTextView selectedRange].length > 0) {
		[returnString replaceOccurrencesOfString:@"%%s" withString:[FRACurrentText substringWithRange:[FRACurrentTextView selectedRange]] options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
	}
	
	[returnString replaceOccurrencesOfString:@" ~" withString:[NSString stringWithFormat:@" %@", NSHomeDirectory()] options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
    
	return returnString;
}


- (void)runCommand: (VACommand *)command
{
	isCommandRunning = YES;
	
	if ([command valueForKey:@"inline"] != nil && [command isInline])
    {
		currentCommandShouldBeInsertedInline = YES;
	} else
    {
		currentCommandShouldBeInsertedInline = NO;
	}
	
	NSString *commandString = [command text];
	
    if (commandString == nil || [commandString length] < 1)
    {
		NSBeep();
		return;
	}
	
	if ([commandString length] > 2 && [commandString rangeOfString:@"#!" options:NSLiteralSearch range:NSMakeRange(0, 2)].location != NSNotFound)
    { // The command starts with a shebang so run it specially
		NSString *selectionStringPath;
		NSMutableString *commandToWrite = [NSMutableString stringWithString:commandString];
		
		if ([FRACurrentTextView selectedRange].length > 0 && [commandString rangeOfString:@"%%s"].location != NSNotFound)
        {
			selectionStringPath = [FRABasic genererateTemporaryPath];
			NSString *selectionString = [FRACurrentText substringWithRange:[FRACurrentTextView selectedRange]];
			[selectionString writeToFile:selectionStringPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
			[temporaryFilesArray addObject:selectionStringPath];
			[commandToWrite replaceOccurrencesOfString:@"%%s" withString:selectionStringPath options:NSLiteralSearch range:NSMakeRange(0, [commandToWrite length])];
		}
		
		id document = FRACurrentDocument;
		NSString *path = [NSString stringWithFormat:@"\"%@\"", [document path]]; // If there's a space in the path
		NSString *directory = [NSString stringWithFormat:@"\"%@\"", [[document path] stringByDeletingLastPathComponent]];
		[commandToWrite replaceOccurrencesOfString:@"%%p" withString:path options:NSLiteralSearch range:NSMakeRange(0, [commandToWrite length])];
		[commandToWrite replaceOccurrencesOfString:@"%%d" withString:directory options:NSLiteralSearch range:NSMakeRange(0, [commandToWrite length])];
		
		NSString *commandPath = [FRABasic genererateTemporaryPath];
		[commandToWrite writeToFile:commandPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
		[temporaryFilesArray addObject:commandPath];
		
		if ([command interpreter] != nil && ![[command interpreter] isEqualToString:@""])
        {
			[FRAVarious performCommandAsynchronously:[NSString stringWithFormat:@"%@ %@", [command interpreter], commandPath]];
		} else {
			[FRAVarious performCommandAsynchronously:[NSString stringWithFormat:@"%@ %@", [FRADefaults valueForKey: @"RunText"], commandPath]];
		}
		
		if (checkIfTemporaryFilesCanBeDeletedTimer != nil) {
			[checkIfTemporaryFilesCanBeDeletedTimer invalidate];
		}
		checkIfTemporaryFilesCanBeDeletedTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(checkIfTemporaryFilesCanBeDeleted) userInfo:nil repeats:YES];
		
	} else
    {
		[FRAVarious performCommandAsynchronously: [self commandToRunFromString:commandString]];
	}
}


- (BOOL)currentCommandShouldBeInsertedInline
{
    return currentCommandShouldBeInsertedInline;
}


- (void)setCommandRunning:(BOOL)flag
{
    isCommandRunning = flag;
}


- (void)checkIfTemporaryFilesCanBeDeleted
{
	if (isCommandRunning == YES) {
		return;
	}
	
	if (checkIfTemporaryFilesCanBeDeletedTimer != nil) {
		[checkIfTemporaryFilesCanBeDeletedTimer invalidate];
		checkIfTemporaryFilesCanBeDeletedTimer = nil;
	}
	
	[self clearAnyTemporaryFiles];
}


- (void)clearAnyTemporaryFiles
{
	NSArray *enumeratorArray = [NSArray arrayWithArray:temporaryFilesArray];
	id item;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	for (item in enumeratorArray) {
		if ([fileManager fileExistsAtPath:item]) {
			[fileManager removeItemAtPath:item error:nil];
		}
		[temporaryFilesArray removeObject:item];
	}
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
    return @[@"NewCommandCollectionToolbarItem",
             @"NewCommandToolbarItem",
             @"FilterCommandsToolbarItem",
             @"RunCommandToolbarItem",
             NSToolbarFlexibleSpaceItemIdentifier];
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return @[@"NewCommandCollectionToolbarItem",
             NSToolbarFlexibleSpaceItemIdentifier,
             @"RunCommandToolbarItem",
             NSToolbarFlexibleSpaceItemIdentifier,
             @"FilterCommandsToolbarItem",
             @"NewCommandToolbarItem"];
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)willBeInserted
{
    if ([itemIdentifier isEqualToString:@"NewCommandCollectionToolbarItem"]) {
        
		NSImage *newCommandCollectionImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRANewCollectionIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
		[[newCommandCollectionImage representations][0] setAlpha:YES];
		
		return [NSToolbarItem createToolbarItemWithIdentifier:itemIdentifier name:NEW_COLLECTION_STRING image:newCommandCollectionImage action:@selector(newCollectionAction:) tag:0 target:self];
		
		
	} else if ([itemIdentifier isEqualToString:@"NewCommandToolbarItem"]) {
        
		NSImage *newCommandImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRANewIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
		[[newCommandImage representations][0] setAlpha:YES];
		
		return [NSToolbarItem createToolbarItemWithIdentifier:itemIdentifier name:NSLocalizedStringFromTable(@"New Command", @"Localizable3", @"New Command") image:newCommandImage action:@selector(newCommandAction:) tag:0 target:self];
        
		
	} else if ([itemIdentifier isEqualToString:@"RunCommandToolbarItem"]) {
        
		NSImage *runCommandImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRARunIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
		[[runCommandImage representations][0] setAlpha:YES];
		
		return [NSToolbarItem createToolbarItemWithIdentifier:itemIdentifier name:NSLocalizedStringFromTable(@"Run", @"Localizable3", @"Run") image:runCommandImage action:@selector(runAction:) tag:0 target:self];
        
		
		
	} else if ([itemIdentifier isEqualToString:@"FilterCommandsToolbarItem"]) {
		
		return [NSToolbarItem createSeachFieldToolbarItemWithIdentifier:itemIdentifier name:FILTER_STRING view:commandsFilterView];		
        
	}
	
	return nil;
}




#pragma mark - NSOutlineView data source methods. (The required ones)

// Required methods.
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (outlineView == _commandCollectionsTableView)
    {
        if (!item)
        {
            return [VACommandCollection allCommandCollections][index];
        }
    }else if (outlineView == _commandsTableView)
    {
        if (!item)
        {
            return [_selectedCollection commands][index];
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
    if (outlineView == _commandCollectionsTableView)
    {
        if (!item)
        {
            return [[VACommandCollection allCommandCollections] count];
        }
    }else if (outlineView == _commandsTableView)
    {
        if (!item)
        {
            return [[_selectedCollection commands] count];
        }
    }
    
    return 0;
}

- (id)        outlineView: (NSOutlineView *)outlineView
objectValueForTableColumn: (NSTableColumn *)tableColumn
                   byItem: (id)item
{
    id objectValue = nil;
    
    if (outlineView == _commandCollectionsTableView)
    {
        VACommandCollection *collection = item;
        
        // The return value from this method is used to configure the state of the items cell via setObjectValue:
        if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString: @"collection"])
        {
            objectValue = [collection name];
        }
    }else if (outlineView == _commandsTableView)
    {
        VACommand *snippet = item;
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
    if (ov == _commandCollectionsTableView)
    {
        VACommandCollection *collection = item;
        [collection setName: object];
        
    }else if (ov == _commandsTableView)
    {
        VACommand *snippet = item;
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
    
    if (outlineView == _commandCollectionsTableView)
    {
        VACommandCollection *collection = item;
        
        if ((tableColumn == nil) || [tabColumnID isEqualToString: @"collection"])
        {
            [cell setStringValue: [collection name]];
        }
        
    }else if (outlineView == _commandsTableView)
    {
        VACommand *command = item;
        if ([tabColumnID isEqualToString: @"name"])
        {
            [cell setStringValue: [command name]];
        }else if ([tabColumnID isEqualToString: @"shortcut"])
        {
            [cell setStringValue: [command shortcutDisplayString] ?: @""];
        }else if([tabColumnID isEqualToString: @"inline"])
        {
            [cell setObjectValue: @([command isInline])];
            
        }else if ([tabColumnID isEqualToString: @"intepreter"])
        {
            [cell setStringValue: [command interpreter]];
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
        NSRect cellFrame = [_commandCollectionsTableView frameOfCellAtColumn: [[_commandCollectionsTableView tableColumns] indexOfObject: tableColumn]
                                                                         row: [_commandCollectionsTableView rowForItem: item]];
        NSUInteger hitTestResult = [cell hitTestForEvent: [NSApp currentEvent]
                                                  inRect: cellFrame
                                                  ofView: _commandCollectionsTableView];
        
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
        return [_commandCollectionsTableView isRowSelected:[_commandCollectionsTableView rowForItem: item]];
    }
}

/* In 10.7 multiple drag images are supported by using this delegate method. */
- (id <NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView pasteboardWriterForItem:(id)item
{
    if (outlineView == _commandCollectionsTableView)
    {
        VACommandCollection *collection = item;
        return [collection  name];
    }else if (outlineView == _commandsTableView)
    {
        VACommand *snippet = item;
        return [snippet name];
    }
    
    return nil;
}

- (void)outlineViewSelectionDidChange: (NSNotification *)notification
{
    NSOutlineView *outlineView = [notification object];
    if (outlineView == _commandCollectionsTableView)
    {
        VACommandCollection *collection = [outlineView itemAtRow: [outlineView selectedRow]];
        [self setSelectedCollection: collection];
        
        [_commandsTableView reloadData];
        
    }else if (outlineView == _commandsTableView)
    {
        VACommand *snippet = [outlineView itemAtRow: [outlineView selectedRow]];
        [_commandsTextView setString: [snippet text] ?: @""];
    }
}

#pragma mark - drag

- (void)outlineView: (NSOutlineView *)outlineView
    draggingSession: (NSDraggingSession *)session
   willBeginAtPoint: (NSPoint)screenPoint
           forItems: (NSArray *)draggedItems
{
    if (outlineView == _commandCollectionsTableView)
    {
        _draggedNodes = draggedItems;
        [session.draggingPasteboard setData: [NSData data]
                                    forType: @"com.veritas.fraise.pasteboard.data"];
    }else
    {
        _draggedCommandNodes = draggedItems;
    }
}

- (void)outlineView: (NSOutlineView *)outlineView
    draggingSession: (NSDraggingSession *)session
       endedAtPoint: (NSPoint)screenPoint
          operation: (NSDragOperation)operation
{
    // If the session ended in the trash, then delete all the items
    if (outlineView == _commandCollectionsTableView)
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
    }else if (outlineView == _commandsTableView)
    {
        if (operation == NSDragOperationDelete)
        {
            [outlineView beginUpdates];
            
            [_draggedCommandNodes enumerateObjectsWithOptions: NSEnumerationReverse
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
        _draggedCommandNodes = nil;
    }
}


@end
