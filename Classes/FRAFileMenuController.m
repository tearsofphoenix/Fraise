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

#import "FRAFileMenuController.h"
#import "FRAProjectsController.h"
#import "FRAExtraInterfaceController.h"
#import "FRABasicPerformer.h"
#import "FRAOpenSavePerformer.h"
#import "FRAInterfacePerformer.h"
#import "FRAVariousPerformer.h"
#import "FRAPrintTextView.h"
#import "FRASyntaxColouring.h"
#import "FRAProject.h"

#import "VADocument.h"
#import "FRATextView.h"
#import "VAEncoding.h"

#import <VADevUIKit/VADevUIKit.h>

@implementation FRAFileMenuController

VASingletonIMPDefault(FRAFileMenuController)

- (IBAction)newAction:(id)sender
{
	if (FRACurrentProject == nil)
    {
		[[FRAProjectsController sharedDocumentController] newDocument:nil];
	}
	id document = [FRACurrentProject createNewDocumentWithContents:@""];

	[FRACurrentProject selectionDidChange];
}


- (IBAction)newProjectAction:(id)sender
{
	[[[FRAExtraInterfaceController sharedInstance] newProjectWindow] makeKeyAndOrderFront:nil];
}


- (IBAction)openAction:(id)sender
{
	[FRABasic removeAllItemsFromMenu:[[[FRAExtraInterfaceController sharedInstance] openPanelEncodingsPopUp] menu]];
    
	NSArray *allEncodings = [VAEncoding allEncodings];

	NSMenuItem *menuItem;
	for (VAEncoding *item in allEncodings)
    {
		if ([item active])
        {
			NSUInteger encoding = [item encoding];
			menuItem = [[NSMenuItem alloc] initWithTitle:[NSString localizedNameOfStringEncoding:encoding] action:nil keyEquivalent:@""];
			[menuItem setTag:encoding];
			[[[[FRAExtraInterfaceController sharedInstance] openPanelEncodingsPopUp] menu] insertItem:menuItem atIndex:0];
		}
	}
    
	menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Use settings from Preferences", @"Use settings from Preferences in openAction") action:nil keyEquivalent:@""];
	[menuItem setTag:0];
	[[[[FRAExtraInterfaceController sharedInstance] openPanelEncodingsPopUp] menu] insertItem:menuItem atIndex:0];
    
	[[[FRAExtraInterfaceController sharedInstance] openPanelEncodingsPopUp] selectItemAtIndex:0]; // Reset it to: Use settings from Preferences
	
	if ([sender tag] == 7) { // Needs to be set before it is created
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"AppleShowAllFiles"];
	}
	
	openPanel = [[NSOpenPanel alloc] init];
    
	[openPanel setResolvesAliases:YES];
	[openPanel setAllowsMultipleSelection:YES];
	[openPanel setAccessoryView:[[FRAExtraInterfaceController sharedInstance] openPanelAccessoryView]];
	
	if ([[FRADefaults valueForKey:@"OpenAllFilesWithinAFolder"] boolValue] == YES) {
		[openPanel setCanChooseDirectories:YES];
	}
	
	if ([sender tag] == 7) {
		[openPanel setTreatsFilePackagesAsDirectories:YES];
	}
	
    [openPanel setDirectoryURL: [NSURL fileURLWithPath: [FRAInterface whichDirectoryForOpen]]];
    
    [openPanel beginSheetModalForWindow: FRACurrentWindow
                      completionHandler: (^(NSInteger returnCode)
                                          {
                                              [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"AppleShowAllFiles"];
                                              
                                              if (returnCode == NSOKButton)
                                              {
                                                  [FRADefaults setValue: [[[openPanel URL] path] stringByDeletingLastPathComponent]
                                                                 forKey: @"LastOpenDirectory"];
                                                  NSArray *array = [openPanel URLs];
                                                  for (NSURL *item in array)
                                                  {
                                                      [FRAOpenSave shouldOpen: [item path]
                                                                 withEncoding: [[[FRAExtraInterfaceController sharedInstance] openPanelEncodingsPopUp] selectedTag]];
                                                  }
                                              }
                                          })];
}

- (IBAction)saveAction:(id)sender
{
	if ([[FRAProjectsController currentDocument] isNewDocument] == YES) {
		[[FRAProjectsController sharedDocumentController] selectDocument:[FRAProjectsController currentDocument]]; // If one has saved from a single document window it should select the proper document in the project
		[self saveAsAction:sender];
	} else {
		[FRAOpenSave performSaveOfDocument:[FRAProjectsController currentDocument] fromSaveAs:NO];
	}
}


- (IBAction)saveAsAction:(id)sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	NSMutableString *name = [NSMutableString stringWithString:[[FRAProjectsController currentDocument] name]];
	if ([[FRADefaults valueForKey:@"AppendNameInSaveAs"] boolValue] == YES)
    {
		[name appendString:[FRADefaults valueForKey:@"AppendNameInSaveAsWith"]];
	}
    
    [savePanel setDirectoryURL: [NSURL fileURLWithPath: [FRAInterface whichDirectoryForSave]]];
    [savePanel setNameFieldStringValue: name];
    [savePanel beginSheetModalForWindow: FRACurrentWindow
                      completionHandler: (^(NSInteger returnCode)
                                          {
                                              [savePanel close];
                                              [FRAVarious stopModalLoop];
                                              
                                              if (returnCode == NSOKButton)
                                              {
                                                  if ([[FRAProjectsController currentDocument]  fromExternal])
                                                  {
                                                      [FRAVarious sendClosedEventToExternalDocument:[FRAProjectsController currentDocument]];
                                                      [[FRAProjectsController currentDocument] setValue:@NO forKey:@"fromExternal"]; // If it is "fromExternal" it shouldn't be that after it has gone through a Save As, but rather, it should be a normal document
                                                  }
                                                  
                                                  NSString *path = [[savePanel URL] path];
                                                  
                                                  [FRAOpenSave performSaveOfDocument: [FRAProjectsController currentDocument]
                                                                                path: path
                                                                          fromSaveAs: YES
                                                                               aCopy: NO];
                                                  if ([[NSFileManager defaultManager] fileExistsAtPath: path])
                                                  {// Check that it has actually been saved
                                                      [[FRAProjectsController sharedDocumentController] putInRecentWithPath: path];
                                                  }
                                                  [FRADefaults setValue: [path stringByDeletingLastPathComponent]
                                                                 forKey: @"LastSaveAsDirectory"];
                                                  
                                                  [[[FRAProjectsController currentDocument] syntaxColouring] setSyntaxDefinition];
                                                  
                                                  [[[FRAProjectsController currentDocument] syntaxColouring] pageRecolour];
                                                  
                                                  [FRAInterface updateStatusBar];
                                              }
                                          })];
	
	[NSApp runModalForWindow:savePanel]; // Run as modal to handle if there are more than one document that needs saving
}

- (IBAction)saveACopyAsAction:(id)sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	
	NSString *copyName = [NSString stringWithFormat:@"%@ %@", [[FRAProjectsController currentDocument] name], NSLocalizedString(@"copy", @"The word to indicate that the filename is a copy in Save-A-Copy-As save-panel")];
	
    [savePanel setDirectoryURL: [NSURL fileURLWithPath: [FRAInterface whichDirectoryForSave]]];
    [savePanel setNameFieldStringValue: copyName];
    [savePanel beginSheetModalForWindow: FRACurrentWindow
                      completionHandler: (^(NSInteger returnCode)
                                          {
                                              if (returnCode == NSOKButton)
                                              {
                                                  NSString *path = [[savePanel URL] path];
                                                  [FRAOpenSave performSaveOfDocument: [FRAProjectsController currentDocument]
                                                                                path: path
                                                                          fromSaveAs: YES
                                                                               aCopy: YES];
                                                  [FRADefaults setValue: [path stringByDeletingLastPathComponent]
                                                                 forKey: @"LastSaveAsDirectory"];
                                              }
                                          })];
}

- (IBAction)revertAction:(id)sender
{
	id document = [FRAProjectsController currentDocument];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:[document path]]) { // Check if original file exists
		NSString *title = [NSString stringWithFormat:NSLocalizedString(@"You cannot revert this document because the file %@ doesn't exist anymore", @"Indicate that you cannot revert this document because the file %@ doesn't exist anymore Revert-file-doesn't-exist sheet"), [document path]];
		[FRAVarious standardAlertSheetWithTitle:title message:NSLocalizedString(@"Please check if you've moved or deleted the original file", @"Indicate that they should please check if you've moved or deleted the original file in Revert-file-doesn't-exist sheet") window:FRACurrentWindow];
		return;
	}
	
	if ([document isEdited] == NO) {
		[self performRevertOfDocument:document]; // I.e an update of the document
	} else {
		if ([FRACurrentWindow attachedSheet]) {
			[[FRACurrentWindow attachedSheet] close];
		}
		
		NSBeginAlertSheet(NSLocalizedString(@"Are you sure you want to revert this document?", @"Ask if you are sure you want to revert this document in Revert-sheet"),
						  NSLocalizedString(@"Revert", @"Revert-button in Revert-sheet"),
						  nil,
						  CANCEL_BUTTON,
						  FRACurrentWindow,
						  self,
						  @selector(revertSheetDidEnd:returnCode:contextInfo:),
						  nil,
						  nil,
						  NSLocalizedString(@"Your changes will be lost if you revert the document", @"Warn that changes will be lost if you revert in Revert-sheet"));
	}
}


- (void)revertSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertDefaultReturn) {
		[self performRevertOfDocument:[FRAProjectsController currentDocument]];
	}
}


- (void)performRevertOfDocument:(VADocument *)document
{
	NSData *textData = [[NSData alloc] initWithContentsOfFile: [document path]];
	
	// UTF-8 e.g. encoding returns nil if the file is not properly formed so check for that and try others if it's nil
	NSString *string = [[NSString alloc] initWithData:textData encoding:[document encoding]];
	
	if (string == nil) { // Test if encoding worked, else try NSISOLatin1StringEncoding
		string = [[NSString alloc] initWithData:textData encoding:NSISOLatin1StringEncoding];
		if (string == nil) { // Test if encoding worked, else try defaultCStringEncoding
			string = [[NSString alloc] initWithData:textData encoding:[NSString defaultCStringEncoding]];
			if (string == nil) { // If it still is nil set it to empty string
				string = @"";
			}
		}
	}
	[[[document firstTextView] undoManager] removeAllActions];
	[[document firstTextView] setString:string];
	[[document syntaxColouring] pageRecolour];
	[[document lineNumbers] updateLineNumbersCheckWidth: NO];
	[[document firstTextView] setSelectedRange:NSMakeRange(0,0)];
	[document setEdited: NO];
    
	[FRACurrentProject updateEditedBlobStatus];
	[FRACurrentProject reloadData];
	[FRAInterface updateStatusBar];
}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	BOOL enableMenuItem = YES;
	NSInteger tag = [anItem tag];
	if (FRACurrentProject != nil && [FRACurrentProject areThereAnyDocuments]) {
		if (tag == 2) { // Save All
			NSArray *array = [FRACurrentProject documents];
			for (id item in array) {
				if ([item isEdited] == YES) {
					enableMenuItem = YES;
					break;
				}
				enableMenuItem = NO;
			}
            
		} else if (tag == 4 || tag == 8 ) { // Revert & Reveal In Finder
			enableMenuItem = ![[FRAProjectsController currentDocument] isNewDocument];
		} else if (tag == 5) { // Save Documents As Project
			if ([FRACurrentProject fileURL] != nil) {
				enableMenuItem = NO;
			}
		} else if (tag == 6) { // Close
			if ([NSApp mainWindow] == nil && [NSApp keyWindow] == nil) {
				enableMenuItem = NO;
			}
		} else if (tag == 9) { // Close Project
			if ([NSApp mainWindow] == nil) {
				enableMenuItem = NO;
			}
		}
        
	} else {
		if (tag == 1 || tag == 7) { // All items that should be active all the time and Open Hidden...
			enableMenuItem = YES;
		} else if (tag == 6) { // Close
			if ([NSApp mainWindow] == nil && [NSApp keyWindow] == nil) {
				enableMenuItem = NO;
			}
		} else {
			enableMenuItem = NO;
		}
	}
	
	return enableMenuItem;
}


- (IBAction)closeAction:(id)sender
{
	NSWindow *window = [NSApp keyWindow];
	if (window == FRACurrentWindow && [[FRACurrentProject documents] count] > 0) {
		[FRACurrentProject checkIfDocumentIsUnsaved:[FRAProjectsController currentDocument] keepOpen:NO];
	} else {
		[window performClose:nil];
	}
}


- (IBAction)saveAllAction:(id)sender
{
	NSArray *array = [FRACurrentProject documents];
	for (id item in array) {
		if ([item isEdited] == YES) {
			if ([item isNewDocument] == YES) {
				[[FRAProjectsController sharedDocumentController] selectDocument:item];
				[self saveAsInSaveAllForDocument:item];
			} else {
				[FRAOpenSave performSaveOfDocument:item fromSaveAs:NO];
			}
		}
	}
	[FRAInterface updateStatusBar]; // Might be needed if the current document has saved with a new name
}


- (void)saveAsInSaveAllForDocument:(id)document
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setDirectoryURL: [NSURL fileURLWithPath: [FRAInterface whichDirectoryForSave]]];
    [savePanel setAllowedFileTypes: @[ [document name] ]];
    
	[savePanel beginSheetModalForWindow: FRACurrentWindow
                      completionHandler: (^(NSInteger returnCode)
                                          {
                                              [savePanel close];
                                              [FRAVarious stopModalLoop];
                                              
                                              if (returnCode == NSOKButton)
                                              {                                                  
                                                  NSString *path = [[savePanel URL] path];
                                                  [FRAOpenSave performSaveOfDocument:document path:path fromSaveAs:NO aCopy:NO];
                                                  if ([[NSFileManager defaultManager] fileExistsAtPath:path]) { // Check that it has actually been saved
                                                      [[FRAProjectsController sharedDocumentController] putInRecentWithPath:path];
                                                  }
                                                  [FRADefaults setValue:[path stringByDeletingLastPathComponent] forKey:@"LastSaveAsDirectory"];
                                                  [[document syntaxColouring] setSyntaxDefinition];
                                                  [[document syntaxColouring] pageRecolour];
                                              }
                                          })];
    
	[NSApp runModalForWindow:savePanel]; // Run as modal to handle if there are more than one document that needs saving
}

- (void)printAction:(id)sender 
{
	[FRACurrentProject printDocument:sender];
}




- (IBAction)revealInFinderAction:(id)sender
{
	[[NSWorkspace sharedWorkspace] selectFile:[[FRAProjectsController currentDocument] path] inFileViewerRootedAtPath:@""];
}


- (IBAction)saveDocumentsAsProjectAction:(id)sender
{
	[FRACurrentProject saveDocumentAs:nil];
}

@end
