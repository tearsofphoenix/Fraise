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
	
	[FRAInterface removeAllSubviewsFromView:firstContentView];
	[firstContentView addSubview:[document firstTextScrollView]];
	if ([document showLineNumberGutter] == YES) {
		[firstContentView addSubview:[document firstGutterScrollView]];
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

@end
