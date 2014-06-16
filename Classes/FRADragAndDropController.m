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

#import "FRADragAndDropController.h"
#import "FRAOpenSavePerformer.h"
#import "FRAProjectsController.h"
#import "FRATableView.h"

#import "FRACommandsController.h"
#import "FRABasicPerformer.h"
#import "FRASnippetsController.h"
#import "FRAVariousPerformer.h"
#import "FRAProject.h"
#import "FRATextView.h"
#import "VASnippetCollection.h"
#import "VACommand.h"
#import "VACommandCollection.h"

@implementation FRADragAndDropController

VASingletonIMPDefault(FRADragAndDropController)

- (instancetype)init 
{
    if ((self = [super init]))
    {
		movedDocumentType = @"FRAMovedDocumentType";
		movedSnippetType = @"FRAMovedSnippetType";
		movedCommandType = @"FRAMovedCommandType";
    }
    return self;
}


- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
	NSArray *typesArray;
	if (aTableView == [FRACurrentProject documentsTableView]) {		
		typesArray = @[movedDocumentType];
		
		NSMutableArray *uriArray = [NSMutableArray array];
		NSArray *arrangedObjects = [FRACurrentProject documents];
		NSInteger currentIndex = [rowIndexes firstIndex];
		while (currentIndex != NSNotFound) {
			[uriArray addObject:[FRABasic uriFromObject:arrangedObjects[currentIndex]]];
			currentIndex = [rowIndexes indexGreaterThanIndex:currentIndex];
		}
		
		[pboard declareTypes:typesArray owner:self];
		[pboard setData:[NSArchiver archivedDataWithRootObject:@[rowIndexes, uriArray]] forType:movedDocumentType];
		
		return YES;
		
	} else if (aTableView == [[FRACommandsController sharedInstance] commandsTableView]) {
		typesArray = @[NSStringPboardType, movedCommandType];
		
		NSMutableString *string = [NSMutableString stringWithString:@""];
		NSMutableArray *uriArray = [NSMutableArray array];
		NSArray *arrangedObjects = [VACommand allCommands];

		NSInteger currentIndex = [rowIndexes firstIndex];
		while (currentIndex != NSNotFound) {
			NSRange selectedRange = [FRACurrentTextView selectedRange];
			NSString *selectedText = [[FRACurrentTextView string] substringWithRange:selectedRange];
			if (selectedText == nil) {
				selectedText = @"";
			}
			NSMutableString *insertString = [NSMutableString stringWithString:[arrangedObjects[currentIndex] valueForKey:@"text"]];
			[insertString replaceOccurrencesOfString:@"%%s" withString:selectedText options:NSLiteralSearch range:NSMakeRange(0, [insertString length])];
			
			[string appendString:insertString];
			[uriArray addObject:[FRABasic uriFromObject:arrangedObjects[currentIndex]]];
			currentIndex = [rowIndexes indexGreaterThanIndex:currentIndex];
		}
		
		[pboard declareTypes:typesArray owner:self];
		[pboard setString:string forType:NSStringPboardType];
		[pboard setData:[NSArchiver archivedDataWithRootObject:@[rowIndexes, uriArray]] forType:movedCommandType];
		
		return YES;
		
	} else {
		return NO;
	}
}


- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	if (aTableView == [FRACurrentProject documentsTableView]) {
		if ([info draggingSource] == [FRACurrentProject documentsTableView]) {
			[aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
			return NSDragOperationMove;
		} else {
			[aTableView setDropRow:[[FRACurrentProject documents] count] dropOperation:NSTableViewDropAbove];
			return NSDragOperationCopy;
		}
		
	} else if (aTableView == [[FRACommandsController sharedInstance] commandsTableView]) {
		[aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
	 	return NSDragOperationCopy;
		
	} else if (aTableView == [[FRACommandsController sharedInstance] commandCollectionsTableView]) {
		if ([info draggingSource] == [[FRACommandsController sharedInstance] commandsTableView]) {
			[aTableView setDropRow:row dropOperation:NSTableViewDropOn];
			return NSDragOperationMove;
		} else
        {
			[aTableView setDropRow: [VACommandCollection allCommandCollections]
                     dropOperation: NSTableViewDropAbove];
			return NSDragOperationCopy;
		}
		return NSDragOperationCopy;
		
	} else if ([aTableView isKindOfClass:[FRATableView class]]) {		
		[aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
		return NSDragOperationMove;
	}
	
	return NSDragOperationNone;
}


- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
	if (row < 0) {
		row = 0;
	}

    // Documents list
	if (aTableView == [FRACurrentProject documentsTableView])
    {
		if ([info draggingSource] == [FRACurrentProject documentsTableView])
        {
			if (![[[info draggingPasteboard] types] containsObject:movedDocumentType])
            {
				return NO;
			}
            
			NSArray *pasteboardData = [NSUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:movedDocumentType]];
			NSIndexSet *rowIndexes = pasteboardData[0];
			NSArray *uriArray = pasteboardData[1];
			 [self moveObjects: uriArray
             inArrayController: [FRACurrentProject documents]
                   fromIndexes: rowIndexes toIndex:row];
			
			[FRACurrentProject documentsListHasUpdated];
			
			return YES;
			
		}

		NSArray *filesToImport = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
		if (filesToImport != nil && aTableView == [FRACurrentProject documentsTableView]) {
			[FRAOpenSave openAllTheseFiles:filesToImport];
			return YES;
		}
		
		NSString *textToImport = (NSString *)[[info draggingPasteboard] stringForType:NSStringPboardType];
		if (textToImport != nil && aTableView == [FRACurrentProject documentsTableView]) {
			[FRACurrentProject createNewDocumentWithContents:textToImport];
			return YES;
		}
			
	// Commands
	} else if (aTableView == [[FRACommandsController sharedInstance] commandsTableView]) {
		
		NSString *textToImport = (NSString *)[[info draggingPasteboard] stringForType:NSStringPboardType];
		if (textToImport != nil) {
			
			id item = [[FRACommandsController sharedInstance] performInsertNewCommand];
			
			[item setValue:textToImport forKey:@"text"];
			if ([textToImport length] > SNIPPET_NAME_LENGTH)
            {
				[item setValue: [[textToImport substringWithRange:NSMakeRange(0, SNIPPET_NAME_LENGTH)] stringByReplaceAllNewLineCharactersWithSymbol]
                        forKey: @"name"];
			} else
            {
				[item setValue:textToImport forKey:@"name"];
			}
			
			return YES;
		} else {
			return NO;
		}		
		
	// Command collections
	} else if (aTableView == [[FRACommandsController sharedInstance] commandCollectionsTableView]) {

		NSArray *filesToImport = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
		
		if (filesToImport != nil) {
			[FRAOpenSave openAllTheseFiles:filesToImport];
			return YES;
		}
		
		if ([info draggingSource] == [[FRACommandsController sharedInstance] commandsTableView]) {
			if (![[[info draggingPasteboard] types] containsObject:movedCommandType]) {
				return NO;
			}
			
			NSArray *pasteboardData = [NSUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:movedCommandType]];
			NSArray *uriArray = pasteboardData[1];
			
			VACommandCollection *collection = [VACommandCollection allCommandCollections][row];
			
			id item;
			for (item in uriArray)
            {
				[[collection commands] addObject: [FRABasic objectFromURI:item]];
			}
			
//			[[[FRACommandsController sharedInstance] commandsArrayController] rearrangeObjects];
			
			return YES;
		}
		
	// From another project
	} else if ([[info draggingSource] isKindOfClass:[FRATableView class]]) {
		if (![[[info draggingPasteboard] types] containsObject:movedDocumentType]) {
			return NO;
		}
		
		NSArray *array = [[FRAProjectsController sharedDocumentController] documents];
		id destinationProject;
		for (destinationProject in array) {
			if (aTableView == [destinationProject documentsTableView]) {
				break;
			}
		}
		
		if (destinationProject == nil) {
			return NO;
		}
		
		NSArray *pasteboardData = [NSUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:movedDocumentType]];
		NSArray *uriArray = pasteboardData[1];
		id document = [FRABasic objectFromURI:uriArray[0]];
		[(NSMutableSet *)[destinationProject documents] addObject:document];
		[document setValue:@(row) forKey:@"sortOrder"];
		[FRAVarious fixSortOrderNumbersForArrayController: [FRACurrentProject documents]
                                                overIndex: row];

        [destinationProject selectDocument:document];
		[destinationProject documentsListHasUpdated];
		[FRACurrentProject documentsListHasUpdated];
		
		return YES;	
		
	
	// To a table view which is not active
	} else if ([aTableView isKindOfClass:[FRATableView class]]) {
		
		NSArray *filesToImport = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
		
		if (filesToImport != nil) {
			[[aTableView window] makeMainWindow];
			NSArray *array = [[FRAProjectsController sharedDocumentController] documents];
			for (id item in array) {
				if (aTableView == [item documentsTableView]) {
					[[FRAProjectsController sharedDocumentController] setCurrentProject:item];
					break;
				}
			}
			
			if (FRACurrentProject != nil) {
				[FRAOpenSave openAllTheseFiles:filesToImport];
				[[FRAProjectsController sharedDocumentController] setCurrentProject:nil];
				return YES;
			}
		}
		
		return NO;
	}
	
	
    return NO;
}


- (NSArray *)moveObjects: (NSArray *)objects
       inArrayController: (NSArray *)data
             fromIndexes: (NSIndexSet *)rowIndexes
                 toIndex: (NSInteger)insertIndex
{
	NSMutableArray *arrangedObjects = [NSMutableArray arrayWithArray: data];
	
	if (arrangedObjects == nil || objects == nil) {
		return nil;
	} 
	
	NSUInteger currentIndex = [rowIndexes firstIndex];
	while (currentIndex != NSNotFound) {
		arrangedObjects[currentIndex] = [NSNull null]; 
		currentIndex = [rowIndexes indexGreaterThanIndex:currentIndex];
	}
	
	NSEnumerator *enumerator = [objects reverseObjectEnumerator]; 
	id item;
	for (item in enumerator) {
		[arrangedObjects insertObject:[FRABasic objectFromURI:item] atIndex:insertIndex];
	}

	[arrangedObjects removeObject:[NSNull null]];
	
	NSInteger index = 0;
	for (item in arrangedObjects) {
		[item setValue:@(index) forKey:@"sortOrder"];
		index++;
	}
	
    return arrangedObjects;
}

@end
