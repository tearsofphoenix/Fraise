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

#import <VADevUIKit/VADevUIKit.h>

@interface FRACommandsController ()<NSOutlineViewDataSource, NSOutlineViewDelegate>

@end

@implementation FRACommandsController

@synthesize commandsTextView;

VASingletonIMPDefault(FRACommandsController)

- (id)init
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
		[_commandsTableView setDataSource: self];
		
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
	id collection = _selectedCollection;

	//TODO
//	[FRAManagedObjectContext deleteObject:collection];
	
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
                                              if (returnCode == NSOKButton) {
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
	
	id collection = [[VACommandCollection alloc] init];
	[collection setValue:[commands[0] valueForKey:@"collectionName"] forKey:@"name"];
	
	id item;
	for (item in commands)
    {
		id command = [[VACommand alloc] init];
		[command setValue:[item valueForKey:@"name"] forKey:@"name"];
		[command setValue:[item valueForKey:@"text"] forKey:@"text"];
		[command setValue:[item valueForKey:@"collectionName"] forKey:@"collectionName"];
		[command setValue:[item valueForKey:@"shortcutDisplayString"] forKey:@"shortcutDisplayString"];
		[command setValue:[item valueForKey:@"shortcutMenuItemKeyString"] forKey:@"shortcutMenuItemKeyString"];
		[command setValue:[item valueForKey:@"shortcutModifier"] forKey:@"shortcutModifier"];
		[command setValue:[item valueForKey:@"sortOrder"] forKey:@"sortOrder"];
		if ([item valueForKey:@"inline"] != nil) {
			[command setValue:[item valueForKey:@"inline"] forKey:@"inline"];
		}
		if ([item valueForKey:@"interpreter"] != nil) {
			[command setValue:[item valueForKey:@"interpreter"] forKey:@"interpreter"];
		}
		[[collection mutableSetValueForKey:@"commands"] addObject:command];
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
	if (document == nil || [document valueForKey:@"path"] == nil) {
		NSBeep();
		return;
	}
	
	[commandsTextView insertText:[document valueForKey:@"path"]];
}


- (IBAction)insertDirectoryAction:(id)sender
{
	id document = FRACurrentDocument;
	if (document == nil || [document valueForKey:@"path"] == nil) {
		NSBeep();
		return;
	}
	
	[commandsTextView insertText:[[document valueForKey:@"path"] stringByDeletingLastPathComponent]];
}


- (NSString *)commandToRunFromString:(NSString *)string
{
	NSMutableString *returnString = [NSMutableString stringWithString:string];
	id document = FRACurrentDocument;
	if (document == nil || [[document valueForKey:@"isNewDocument"] boolValue] == YES || [document valueForKey:@"path"] == nil) {
		[returnString replaceOccurrencesOfString:@"%%p" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
		[returnString replaceOccurrencesOfString:@"%%d" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
	} else {
		NSString *path = [NSString stringWithFormat:@"\"%@\"", [document valueForKey:@"path"]]; // If there's a space in the path
		NSString *directory;
		if ([[FRADefaults valueForKey:@"PutQuotesAroundDirectory"] boolValue] == YES) {
			directory = [NSString stringWithFormat:@"\"%@\"", [[document valueForKey:@"path"] stringByDeletingLastPathComponent]];
		} else {
			directory = [NSString stringWithFormat:@"%@", [[document valueForKey:@"path"] stringByDeletingLastPathComponent]];
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
		NSString *path = [NSString stringWithFormat:@"\"%@\"", [document valueForKey:@"path"]]; // If there's a space in the path
		NSString *directory = [NSString stringWithFormat:@"\"%@\"", [[document valueForKey:@"path"] stringByDeletingLastPathComponent]];
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




@end
