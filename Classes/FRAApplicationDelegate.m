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

#import "FRAApplicationDelegate.h"
#import "FRAOpenSavePerformer.h"
#import "FRAProjectsController.h"
#import "FRACommandsController.h"
#import "FRABasicPerformer.h"
#import "FRAServicesController.h"
#import "FRAToolsMenuController.h"
#import "FRAProject.h"
#import "FRAVariousPerformer.h"
#import "VACommandCollection.h"
#import "VACommand.h"

#import "ODBEditorSuite.h"
#import "VADocument.h"

@implementation FRAApplicationDelegate
	
@synthesize filesToOpenArray, appleEventDescriptor;

VASingletonIMPDefault(FRAApplicationDelegate)

- (id)init 
{
    if ((self = [super init]))
    {
		_shouldCreateEmptyDocument = YES;
		_hasFinishedLaunching = NO;
		_isTerminatingApplication = NO;
		appleEventDescriptor = nil;
    }
	
    return self;
}


- (NSString *)applicationSupportFolder
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? paths[0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"Fraise"];
}
 
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    //TODO
    return nil;
//	return [[self managedObjectContext] undoManager];
}

 
- (IBAction)saveAction:(id)sender
{
    //TODO
//    NSError *error = nil;
//    if (![[self managedObjectContext] save:&error])
//    {
//        [[NSApplication sharedApplication] presentError:error];
//    }
}

 
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	id item;
	NSArray *array = [[FRAProjectsController sharedDocumentController] documents];
	for (item in array) {
		[item autosave];
		if ([item areAllDocumentsSaved] == NO) {
			return NSTerminateCancel;
		}
	}

	_isTerminatingApplication = YES; // This is to avoid changing the document when quiting the application because otherwise it "flashes" when removing the documents
	
	[[FRACommandsController sharedInstance] clearAnyTemporaryFiles];
	
	if ([[FRADefaults valueForKey:@"OpenAllDocumentsIHadOpen"] boolValue] == YES) {

		NSMutableArray *documentsArray = [NSMutableArray array];
		NSArray *projects = [[FRAProjectsController sharedDocumentController] documents];
		for (id project in projects) {
			if ([project fileURL] == nil) {
				NSArray *documents = [[project documentsArrayController] arrangedObjects];
				for (id document in documents) {
					if ([document path] != nil && [document fromExternal] != YES) {
						[documentsArray addObject:[document path]];
					}
				}
			}
		}
		
		[FRADefaults setValue:documentsArray forKey:@"OpenDocuments"];
	}
	
	if ([[FRADefaults valueForKey:@"OpenAllProjectsIHadOpen"] boolValue] == YES) {
		NSMutableArray *projectsArray = [NSMutableArray array];
		NSArray *array = [[FRAProjectsController sharedDocumentController] documents];
		for (id project in array) {
			if ([project fileURL] != nil) {
				[projectsArray addObject:[[project fileURL] path]];
			}
		}
		
		[FRADefaults setValue:projectsArray forKey:@"OpenProjects"];
	}
	
	array = [VADocument allDocuments]; // Mark any external documents as closed
	for (VADocument *item in array)
    {
		if ([item  fromExternal])
        {
			[FRAVarious sendClosedEventToExternalDocument:item];
		}
	}
	
//	NSError *error;
    NSInteger reply = NSTerminateNow;

    //TODO
//    if ([managedObjectContext commitEditing])
//    {
//        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
//        {
//            
//            BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
//            
//            if (errorResult == YES)
//            {
//                reply = NSTerminateCancel;
//            } else
//            {
//                NSInteger alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
//                if (alertReturn == NSAlertAlternateReturn)
//                {
//                    reply = NSTerminateCancel;
//                }
//            }
//        }
//    } else
//    {
//        reply = NSTerminateCancel;
//    }
    
	if (reply == NSTerminateCancel) {
		_isTerminatingApplication = NO;
	}
	
    return reply;
}


- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	filesToOpenArray = [[NSMutableArray alloc] initWithArray:filenames];
	[filesToOpenArray sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	_shouldCreateEmptyDocument = NO;
	
	if (_hasFinishedLaunching) {
		[FRAOpenSave openAllTheseFiles:filesToOpenArray];
		filesToOpenArray = nil;
	} else if ([[[NSAppleEventManager sharedAppleEventManager] currentAppleEvent] paramDescriptorForKeyword:keyFileSender] != nil || [[[NSAppleEventManager sharedAppleEventManager] currentAppleEvent] paramDescriptorForKeyword:keyAEPropData] != nil) {
		if (appleEventDescriptor == nil) {
			appleEventDescriptor = [[NSAppleEventDescriptor alloc] initWithDescriptorType:[[[NSAppleEventManager sharedAppleEventManager] currentAppleEvent] descriptorType] data:[[[NSAppleEventManager sharedAppleEventManager] currentAppleEvent] data]];
			_shouldCreateEmptyDocument = NO;
		}
	}
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[NSApp setServicesProvider:[FRAServicesController sharedInstance]];
	
	[self performSelector:@selector(markItAsTrulyFinishedWithLaunching) withObject:nil afterDelay:0.0]; // Do it this way because otherwise this is called before the values are inserted by Core Data
}


- (void)markItAsTrulyFinishedWithLaunching
{
	if (filesToOpenArray != nil && [filesToOpenArray count] > 0) {
		NSArray *openDocument = [VADocument allDocuments];
		if ([openDocument count] != 0) {
			if (FRACurrentProject != nil) {
				[FRACurrentProject performCloseDocument:openDocument[0]];
			}
		}

		[FRAOpenSave openAllTheseFiles:filesToOpenArray];
		[FRACurrentProject selectionDidChange];
		filesToOpenArray = nil;
	} else { // Open previously opened documents/projects only if Fraise wasn't opened by e.g. dragging a document onto the icon
		
		if ([[FRADefaults valueForKey:@"OpenAllDocumentsIHadOpen"] boolValue] == YES && [[FRADefaults valueForKey:@"OpenDocuments"] count] > 0) {
			_shouldCreateEmptyDocument = NO;
			NSArray *openDocument = [VADocument allDocuments];
			if ([openDocument count] != 0) {
				if (FRACurrentProject != nil) {
					filesToOpenArray = [[NSMutableArray alloc] init]; // A hack so that -[FRAProject performCloseDocument:] won't close the window
					[FRACurrentProject performCloseDocument:openDocument[0]];
					filesToOpenArray = nil;
				}
			}

			[FRAOpenSave openAllTheseFiles:[FRADefaults valueForKey:@"OpenDocuments"]];
			[FRACurrentProject selectionDidChange];
		}
		
		if ([[FRADefaults valueForKey:@"OpenAllProjectsIHadOpen"] boolValue] == YES && [[FRADefaults valueForKey:@"OpenProjects"] count] > 0) {
			_shouldCreateEmptyDocument = NO;
			[FRAOpenSave openAllTheseFiles:[FRADefaults valueForKey:@"OpenProjects"]];
		}
	}

	_hasFinishedLaunching = YES;
	_shouldCreateEmptyDocument = NO;

	// Do this here so that it won't slow down the perceived start-up time
	[[FRAToolsMenuController sharedInstance] buildInsertSnippetMenu];
	[[FRAToolsMenuController sharedInstance] buildRunCommandMenu];
}


- (void)changeFont:(id)sender // When you change the font in the print panel
{
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	NSFont *panelFont = [fontManager convertFont:[fontManager selectedFont]];
	[FRADefaults setValue:[NSArchiver archivedDataWithRootObject:panelFont] forKey:@"PrintFont"];
}


- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	if (([[FRADefaults valueForKey:@"OpenAllProjectsIHadOpen"] boolValue] == YES
        && [[FRADefaults valueForKey:@"OpenProjects"] count] > 0)
        || [[[FRAProjectsController sharedDocumentController] documents] count] > 0)
    {
		return NO;
	} else
    {
		return [[FRADefaults valueForKey:@"NewDocumentAtStartup"] boolValue];
	}
}


- (NSMenu *)applicationDockMenu:(NSApplication *)sender
{
	NSMenu *returnMenu = [[NSMenu alloc] init];
	NSMenuItem *menuItem;
	id document;
	
	NSEnumerator *currentProjectEnumerator = [[[FRACurrentProject documentsArrayController] arrangedObjects] reverseObjectEnumerator];
	for (document in currentProjectEnumerator) {
		menuItem = [[NSMenuItem alloc] initWithTitle:[document name] action:@selector(selectDocumentFromTheDock:) keyEquivalent:@""];
		[menuItem setTarget:[FRAProjectsController sharedDocumentController]];
		[menuItem setRepresentedObject:document];
		[returnMenu insertItem:menuItem atIndex:0];
	}
	
	NSArray *projects = [[FRAProjectsController sharedDocumentController] documents];
	for (id project in projects) {
		if (project == FRACurrentProject) {
			continue;
		}
		NSMenu *menu;
		if ([project valueForKey:@"name"] == nil) {
			menu = [[NSMenu alloc] initWithTitle:UNTITLED_PROJECT_NAME];
		} else {
			menu = [[NSMenu alloc] initWithTitle:[project valueForKey:@"name"]];
		}
		
		NSEnumerator *documentsEnumerator = [[(FRAProject *)project documents] reverseObjectEnumerator];
		for (document in documentsEnumerator) {
			menuItem = [[NSMenuItem alloc] initWithTitle:[document name] action:@selector(selectDocumentFromTheDock:) keyEquivalent:@""];
			[menuItem setTarget:[FRAProjectsController sharedDocumentController]];
			[menuItem setRepresentedObject:document];
			[menu insertItem:menuItem atIndex:0];
		}
		
		NSMenuItem *subMenuItem = [[NSMenuItem alloc] initWithTitle:[menu title] action:nil keyEquivalent:@""];
		[subMenuItem setSubmenu:menu];
		[returnMenu addItem:subMenuItem];
	}

	return returnMenu;
}


- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
	if ([[FRADefaults valueForKey:@"CheckIfDocumentHasBeenUpdated"] boolValue] == YES) { // Check for updates directly when Fraise gets focus
		[FRAVarious checkIfDocumentsHaveBeenUpdatedByAnotherApplication];
	}
}

@end
