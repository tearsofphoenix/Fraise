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

#import "FRATableView.h"
#import "FRASnippetsController.h"
#import "FRACommandsController.h"
#import "FRAToolsMenuController.h"
#import "FRAProjectsController.h"
#import "FRAProject.h"
#import "VASnippetCollection.h"

@implementation FRATableView

- (void)keyDown:(NSEvent *)event
{
	if (self == [FRACurrentProject documentsTableView])
    {
        
		unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
		NSInteger keyCode = [event keyCode];
		NSUInteger flags = ([event modifierFlags] & 0x00FF);
		
		if ((key == NSDeleteCharacter || keyCode == 0x75) && flags == 0) { // 0x75 is forward delete
			if ([self selectedRow] == -1) {
				NSBeep();
			} else
            {
                 if (self == [FRACurrentProject documentsTableView])
                 {
					id document = [[FRACurrentProject documentsArrayController] selectedObjects][0];
					[FRACurrentProject checkIfDocumentIsUnsaved:document keepOpen:NO];
				}
			}
		}
		
	} else {
		[super keyDown:event];
	}
}


- (void)snippetSheetDidDismiss:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
	[sheet close];
	
	if (returnCode == NSAlertDefaultReturn) {
		[[FRASnippetsController sharedInstance] performDeleteCollection];
		
	}
}


- (void)commandSheetDidDismiss:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
	[sheet close];
	
	if (returnCode == NSAlertDefaultReturn) {
		[[FRACommandsController sharedInstance] performDeleteCollection];
	}
}


- (void)textDidEndEditing:(NSNotification *)aNotification
{
	if ([[aNotification userInfo][@"NSTextMovement"] integerValue] == NSReturnTextMovement) {
		[[self window] endEditingFor:self];
		[self reloadData];
		[[self window] makeFirstResponder:self];
	} else {
		[super textDidEndEditing:aNotification];
	}
}

@end
