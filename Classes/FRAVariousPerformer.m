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

#import "FRAVariousPerformer.h"
#import "NSString+Fraise.h"
#import "FRABasicPerformer.h"
#import "FRAProjectsController.h"
#import "FRAMainController.h"
#import "FRACommandsController.h"
#import "FRAFileMenuController.h"
#import "FRAExtraInterfaceController.h"
#import "FRAProject.h"
#import "FRAProject+DocumentViewsController.h"

#import "ODBEditorSuite.h"
#import "FRATextView.h"
#import "FRACommandManagedObject.h"
#import "VADocument.h"
#import "VAEncoding.h"
#import "VASyntaxDefinition.h"
#import "VASnippet.h"
#import "VASnippetCollection.h"
#import "VACommandCollection.h"
#import "VACommand.h"

#import <VAFoundation/VAFoundation.h>
#import <VADevUIKit/VADevUIKit.h>



@implementation FRAVariousPerformer

VASingletonIMPDefault(FRAVariousPerformer)

- (id)init 
{
    if ((self = [super init]))
    {
		untitledNumber = 1;
		
		isChangingSyntaxDefinitionsProgrammatically = NO; // So that FRAManagedObject does not need to care about changes when resetting the preferences
    }
    
    return self;
}



- (void)updateCheckIfAnotherApplicationHasChangedDocumentsTimer
{
	if ([[FRADefaults valueForKey:@"CheckIfDocumentHasBeenUpdated"] boolValue] == YES) {
		
		NSInteger interval = [[FRADefaults valueForKey:@"TimeBetweenDocumentUpdateChecks"] integerValue];
		if (interval < 1) {
			interval = 1;
		}
		checkIfAnotherApplicationHasChangedDocumentsTimer = 
			[NSTimer scheduledTimerWithTimeInterval:interval target:FRAVarious selector:@selector(checkIfDocumentsHaveBeenUpdatedByAnotherApplication)	userInfo:nil repeats:YES];
	} else {
		if (checkIfAnotherApplicationHasChangedDocumentsTimer) {
			[checkIfAnotherApplicationHasChangedDocumentsTimer invalidate];
			checkIfAnotherApplicationHasChangedDocumentsTimer = nil;
		}
	}
}


- (void)insertTextEncodings
{
	const NSStringEncoding *availableEncodings = [NSString availableStringEncodings];
	NSStringEncoding encoding;
	NSArray *activeEncodings = [FRADefaults valueForKey:@"ActiveEncodings"];
	while ((encoding = *availableEncodings++))
    {
		VAEncoding *item = [[VAEncoding alloc] init];
		NSNumber *encodingObject =  @(encoding);
		if ([activeEncodings containsObject:encodingObject])
        {
			[item setActive: YES];
		}
		[item setEncoding: encoding];
		[item setName: [NSString localizedNameOfStringEncoding:encoding]];
	}
}


- (void)insertSyntaxDefinitions
{
	isChangingSyntaxDefinitionsProgrammatically = YES;
	NSMutableArray *syntaxDefinitionsArray = [[NSMutableArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SyntaxDefinitions" ofType:@"plist"]];
	NSString *path = [[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Fraise"] stringByAppendingPathComponent:@"SyntaxDefinitions.plist"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:path] == YES) {
		NSArray *syntaxDefinitionsUserArray = [[NSArray alloc] initWithContentsOfFile:path];
		[syntaxDefinitionsArray addObjectsFromArray:syntaxDefinitionsUserArray];
	}
	
	NSArray *keys = @[@"name", @"file", @"extensions"];
	NSDictionary *standard = [NSDictionary dictionaryWithObjects:@[@"Standard", @"standard", @""] forKeys:keys];
	NSDictionary *none = [NSDictionary dictionaryWithObjects:@[@"None", @"none", @""] forKeys:keys];
	[syntaxDefinitionsArray insertObject:none atIndex:0];
	[syntaxDefinitionsArray insertObject:standard atIndex:0];
	
	NSMutableArray *changedSyntaxDefinitionsArray = nil;
	if ([FRADefaults valueForKey:@"ChangedSyntaxDefinitions"]) {
		changedSyntaxDefinitionsArray = [NSMutableArray arrayWithArray:[FRADefaults valueForKey:@"ChangedSyntaxDefinitions"]];
	}
	
	id item;
	NSInteger index = 0;
	for (item in syntaxDefinitionsArray) {
		if ([[item valueForKey:@"extensions"] isKindOfClass:[NSArray class]]) { // If extensions is an array instead of a string, i.e. an older version
			continue;
		}
        
		VASyntaxDefinition *syntaxDefinition = [[VASyntaxDefinition alloc] init];
		NSString *name = [item valueForKey:@"name"];
		[syntaxDefinition setName: name];
		[syntaxDefinition setFile: [item valueForKey:@"file"]];
		[syntaxDefinition setSortOrder: index];
		index++;
		
		BOOL hasInsertedAChangedValue = NO;
		if (changedSyntaxDefinitionsArray != nil) {
			for (id changedObject in changedSyntaxDefinitionsArray) {
				if ([[changedObject valueForKey:@"name"] isEqualToString:name]) {
					[syntaxDefinition setValue:[changedObject valueForKey:@"extensions"] forKey:@"extensions"];
					hasInsertedAChangedValue = YES;
					break;
				}					
			}
		} 
		
		if (hasInsertedAChangedValue == NO) {
			[syntaxDefinition setValue:[item valueForKey:@"extensions"] forKey:@"extensions"];
		}		
	}

	isChangingSyntaxDefinitionsProgrammatically = NO;
}


- (void)insertDefaultSnippets
{
    NSArray *snippets = [VASnippet all];
    
	if ([snippets count] == 0 && [[FRADefaults valueForKey:@"HasInsertedDefaultSnippets"] boolValue] == NO)
    {
		NSDictionary *defaultSnippets = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultSnippets" ofType:@"plist"]];
		
		NSEnumerator *collectionEnumerator = [defaultSnippets keyEnumerator];
		for (id collection in collectionEnumerator)
        {
			VASnippetCollection *newCollection = [[VASnippetCollection alloc] init];
			[newCollection setName: collection];
            
			NSArray *array = [defaultSnippets valueForKey:collection];
			for (NSDictionary *snippet in array)
            {
				VASnippet *newSnippet = [[VASnippet alloc] init];
				[newSnippet setName: snippet[@"name"]];
				[newSnippet setText: snippet[@"text"]];
				[[newCollection snippets] addObject: newSnippet];
			}
		}
		
		[FRADefaults setValue:@YES forKey:@"HasInsertedDefaultSnippets"];
	}
}


- (void)insertDefaultCommands
{
	if ([[FRADefaults valueForKey:@"HasInsertedDefaultCommands3"] boolValue] == NO) {
		
		NSDictionary *defaultCommands = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultCommands" ofType:@"plist"]];
		
		NSEnumerator *collectionEnumerator = [defaultCommands keyEnumerator];
		for (id collection in collectionEnumerator)
        {
			VACommandCollection *newCollection = [[VACommandCollection alloc] init];
			[newCollection setName: collection];
			
            NSEnumerator *snippetEnumerator = [defaultCommands[collection] objectEnumerator];
			for (id command in snippetEnumerator)
            {
				VACommand *newCommand = [[VACommand alloc] init];
				[newCommand setName: command[@"name"]];
				[newCommand setText: command[@"text"]];
				
                if (command[@"inline"] != nil)
                {
					[newCommand setIsInline: [command[@"inline"] boolValue]];
				}
                
				if (command[@"interpreter"] != nil)
                {
					[newCommand setInterpreter: command[@"interpreter"]];
				}
                
				[[newCollection commands] addObject: newCommand];
			}
		}
		
		[FRADefaults setValue: @YES
                       forKey: @"HasInsertedDefaultCommands3"];
	}
}


- (void)standardAlertSheetWithTitle:(NSString *)title message:(NSString *)message window:(NSWindow *)window
{
	if ([window attachedSheet]) {
		[[window attachedSheet] close];
	}
	
	NSBeginAlertSheet(title,
					  OK_BUTTON,
					  nil,
					  nil,
					  window,
					  self,
					  nil,
					  @selector(sheetDidDismiss:returnCode:contextInfo:),
					  nil,
					  @"%@", message);
	
	[NSApp runModalForWindow:[window attachedSheet]]; // Modal to catch if there are sheets for many files to be displayed
}


- (void)sheetDidDismiss:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
	[sheet close];
	[self stopModalLoop];
}


- (void)stopModalLoop
{
	[NSApp stopModal];
	[[FRACurrentWindow standardWindowButton:NSWindowCloseButton] setEnabled:YES];
	[[FRACurrentWindow standardWindowButton:NSWindowMiniaturizeButton] setEnabled:YES];
	[[FRACurrentWindow standardWindowButton:NSWindowZoomButton] setEnabled:YES];
}


- (void)sendModifiedEventToExternalDocument:(VADocument *)document path:(NSString *)path
{
	BOOL fromSaveAs = NO;
	NSString *currentPath = [document path];
	if ([path isEqualToString:currentPath] == NO) {
		fromSaveAs = YES;
	}
	
	NSURL *url = [NSURL fileURLWithPath:currentPath];
	NSData *data = [[url absoluteString] dataUsingEncoding:NSUTF8StringEncoding];
	
	OSType signature = [[document externalSender] typeCodeValue];
	NSAppleEventDescriptor *descriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature bytes:&signature length:sizeof(OSType)];
	NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:kODBEditorSuite eventID:kAEModifiedFile targetDescriptor:descriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithDescriptorType:typeFileURL data:data] forKeyword:keyDirectObject];
	
	if ([document externalToken]) {
		[event setParamDescriptor:[document externalToken] forKeyword:keySenderToken];
	}
	if (fromSaveAs) {
		[descriptor setParamDescriptor:[NSAppleEventDescriptor descriptorWithDescriptorType:typeFileURL data:data] forKeyword:keyNewLocation];
		[document setFromExternal: NO]; // If it's a Save As it no longer belongs to the external program
	}
	
	AppleEvent *eventPointer = (AEDesc *)[event aeDesc];
	
	if (eventPointer) {
		AESendMessage(eventPointer, NULL, kAENoReply, kAEDefaultTimeout);
	}
}


- (void)sendClosedEventToExternalDocument:(id)document
{
	NSURL *url = [NSURL fileURLWithPath:[document path]];
	NSData *data = [[url absoluteString] dataUsingEncoding:NSUTF8StringEncoding];
	
	OSType signature = [[document externalSender] typeCodeValue];
	NSAppleEventDescriptor *descriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature bytes:&signature length:sizeof(OSType)];
	
	NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:kODBEditorSuite eventID:kAEClosedFile targetDescriptor:descriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithDescriptorType:typeFileURL data:data] forKeyword:keyDirectObject];

	if ([document externalToken]) {
		[event setParamDescriptor:[document externalToken] forKeyword:keySenderToken];
	}
	
	AppleEvent *eventPointer = (AEDesc *)[event aeDesc];
	
	if (eventPointer) {
		AESendMessage(eventPointer, NULL, kAENoReply, kAEDefaultTimeout);
	}
}


- (NSInteger)alertWithMessage:(NSString *)message informativeText:(NSString *)informativeText defaultButton:(NSString *)defaultButton alternateButton:(NSString *)alternateButton otherButton:(NSString *)otherButton
{	
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:message];
	[alert setInformativeText:informativeText];
	if (defaultButton != nil) {
		[alert addButtonWithTitle:defaultButton];
	}
	if (alternateButton != nil) {
		[alert addButtonWithTitle:alternateButton];
	}
	if (otherButton != nil) {
		[alert addButtonWithTitle:otherButton];
	}
	
	return [alert runModal];
	// NSAlertFirstButtonReturn
	// NSAlertSecondButtonReturn
	// NSAlertThirdButtonReturn
}




- (void)checkIfDocumentsHaveBeenUpdatedByAnotherApplication
{
	if ([FRACurrentProject areThereAnyDocuments] == NO || [FRAMain isInFullScreenMode] == YES || [[FRADefaults valueForKey:@"CheckIfDocumentHasBeenUpdated"] boolValue] == NO || [FRACurrentWindow attachedSheet] != nil)
    {
		return;
	}
	
	NSArray *array = [VADocument allDocuments];
	for (id item in array)
    {
		if ([item isNewDocument] == YES || [item ignoreAnotherApplicationHasUpdatedDocument] == YES)
        {
			continue;
		}
		NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: [item path]
                                                                                    error: nil];
		if ([attributes fileModificationDate] == nil)
        {
			continue; // If fileModificationDate is nil the file has been removed or renamed there's no need to check the dates then
		}
		if (![[[item fileAttributes] fileModificationDate] isEqualToDate:[attributes fileModificationDate]])
        {
			if ([[FRADefaults valueForKey:@"UpdateDocumentAutomaticallyWithoutWarning"] boolValue] == YES)
            {
				[[FRAFileMenuController sharedInstance] performRevertOfDocument:item];
				[item setFileAttributes: [[NSFileManager defaultManager] attributesOfItemAtPath:[item path] error:nil]];
			} else {
				if ([NSApp isHidden]) { // To display the sheet properly if the application is hidden
					[NSApp activateIgnoringOtherApps:YES]; 
					[FRACurrentWindow makeKeyAndOrderFront:self];
				}
				
				NSString *title = [NSString stringWithFormat:NSLocalizedString(@"The document %@ has been updated by another application", @"Indicate that the document %@ has been updated by another application in Document-has-been-updated-alert sheet"), [item valueForKey:@"path"]];
				NSString *message;
				if ([item isEdited] == YES) {
					message = NSLocalizedString(@"Do you want to ignore the updates the other application has made or reload the document and destroy any changes you have made to this document?", @"Ask whether they want to ignore the updates the other application has made or reload the document and destroy any changes you have made to this document Document-has-been-updated-alert sheet");
				} else {
					message = NSLocalizedString(@"Do you want to ignore the updates the other application has made or reload the document?", @"Ask whether they want to ignore the updates the other application has made or reload the document Document-has-been-updated-alert sheet");
				}
				NSBeginAlertSheet(title,
								  NSLocalizedString(@"Ignore", @"Ignore-button in Document-has-been-updated-alert sheet"),
								  nil,
								  NSLocalizedString(@"Reload", @"Reload-button in Document-has-been-updated-alert sheet"),
								  FRACurrentWindow,
								  self,
								  @selector(sheetDidFinish:returnCode:contextInfo:),
								  nil,
								  (__bridge void *)@[item],
								  @"%@", message);
				[NSApp runModalForWindow:[FRACurrentWindow attachedSheet]];
			}
		}
	}
}


- (void)sheetDidFinish:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
	[sheet close];
	[FRAVarious stopModalLoop];
	
	VADocument *document = ((__bridge NSArray *)contextInfo)[0];
	if (returnCode == NSAlertDefaultReturn)
    {
		[document setIgnoreAnotherApplicationHasUpdatedDocument: YES];
        
	} else if (returnCode == NSAlertOtherReturn)
    {
		[[FRAFileMenuController sharedInstance] performRevertOfDocument:document];
		[document setFileAttributes: [[NSFileManager defaultManager] attributesOfItemAtPath:[document path] error:nil]];
	}
}


- (NSString *)performCommand:(NSString *)command
{
	NSMutableString *returnString = [NSMutableString string];
	
	@try {
		NSTask *task = [[NSTask alloc] init];
		NSPipe *pipe = [[NSPipe alloc] init];
		NSPipe *errorPipe = [[NSPipe alloc] init];
		
		NSMutableArray *splitArray = [NSMutableArray arrayWithArray: [command divideCommandIntoArray]];
		[task setLaunchPath:splitArray[0]];
		[splitArray removeObjectAtIndex:0];
		
		[task setArguments:splitArray];
		[task setStandardOutput:pipe];
		[task setStandardError:errorPipe];
		
		[task launch];
		
		[task waitUntilExit];
		
		NSString *errorString = [[NSString alloc] initWithData:[[errorPipe fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding];
		NSString *outputString = [[NSString alloc] initWithData:[[pipe fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding];
		[returnString appendString:errorString];
		[returnString appendString:outputString];
	}
	@catch (NSException *exception) {
		[returnString appendString:NSLocalizedString(@"Unknown error when running the command", @"Unknown error when running the command in performCommand")];
	}
	@finally {
		return returnString;
	}
}


- (void)performCommandAsynchronously:(NSString *)command
{
	asynchronousTaskResult = [[NSMutableString alloc] initWithString:@""];
	
	asynchronousTask = [[NSTask alloc] init];
	
	if ([FRAProjectsController currentDocument] != nil && [[FRAProjectsController currentDocument] path] != nil) {
		NSMutableDictionary *defaultEnvironment = [NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo] environment]];
		NSString *envPath = @(getenv("PATH"));
		NSString *directory = [[[FRAProjectsController currentDocument] path] stringByDeletingLastPathComponent];
		defaultEnvironment[@"PATH"] = [NSString stringWithFormat:@"%@:%@", envPath, directory];
		defaultEnvironment[@"PWD"] = directory;
		[asynchronousTask setEnvironment:defaultEnvironment];
	}
	
	NSMutableArray *splitArray = [NSMutableArray arrayWithArray:[command divideCommandIntoArray]];
	//NSLog([splitArray description]);
	[asynchronousTask setLaunchPath:splitArray[0]];
	[splitArray removeObjectAtIndex:0];
	[asynchronousTask setArguments:splitArray];
	
	[asynchronousTask setStandardOutput:[NSPipe pipe]];
	[asynchronousTask setStandardError:[asynchronousTask standardOutput]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(asynchronousDataReceived:) name:NSFileHandleReadCompletionNotification object:[[asynchronousTask standardOutput] fileHandleForReading]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(asynchronousTaskCompleted:) name:NSTaskDidTerminateNotification object:nil];
	
	[[[asynchronousTask standardOutput] fileHandleForReading] readInBackgroundAndNotify];
	
	[asynchronousTask launch];
}


- (void)asynchronousDataReceived:(NSNotification *)aNotification
{
    NSData *data = [[aNotification userInfo] valueForKey:@"NSFileHandleNotificationDataItem"];
	
	if ([data length]) {
		NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		if (string != nil) {
			[asynchronousTaskResult appendString:string];
		}
		
		[[[asynchronousTask standardOutput] fileHandleForReading] readInBackgroundAndNotify];
	} else {
		//[self asynchronousTaskCompleted];
	}
	
}

- (void)asynchronousTaskCompleted:(NSNotification *)aNotification
{
	[asynchronousTask waitUntilExit];
	[self asynchronousTaskCompleted];
}


- (void)asynchronousTaskCompleted
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[asynchronousTask terminate];
	
	NSData *data;
	while ((data = [[[asynchronousTask standardOutput] fileHandleForReading] availableData]) && [data length]) {
		NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		if (string != nil) {
			[asynchronousTaskResult appendString:string];
		}
	}

	[[FRACommandsController sharedInstance] setCommandRunning:NO];

	if ([asynchronousTask terminationStatus] == 0) {
		if ([[FRACommandsController sharedInstance] currentCommandShouldBeInsertedInline]) {
			[FRACurrentTextView insertText:asynchronousTaskResult];
			[[[FRAExtraInterfaceController sharedInstance] commandResultTextView] setString:@""];
		} else {
			[[[FRAExtraInterfaceController sharedInstance] commandResultTextView] setString:asynchronousTaskResult];
			[[[FRAExtraInterfaceController sharedInstance] commandResultWindow] makeKeyAndOrderFront:nil];
		}
	} else {
		NSBeep();
		[[[FRAExtraInterfaceController sharedInstance] commandResultWindow] makeKeyAndOrderFront:nil];
		[[[FRAExtraInterfaceController sharedInstance] commandResultTextView] setString:asynchronousTaskResult];
	}

	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setLastSavedDateForDocument:(id)document date:(NSDate *)lastSavedDate
{
	[document setLastSaved: [NSString dateStringForDate: (NSCalendarDate *)lastSavedDate
                                            formatIndex: [[FRADefaults valueForKey:@"StatusBarLastSavedFormatPopUp"] integerValue]]];
}


- (void)hasChangedDocument:(id)document
{
	[document setEdited: YES];
	[FRACurrentProject reloadData];
	if (document == [FRAProjectsController currentDocument]) {
		[FRACurrentWindow setDocumentEdited:YES];
	}
	if ([document singleDocumentWindow] != nil) {
		[[document singleDocumentWindow] setDocumentEdited:YES];
	}
	
	[FRACurrentProject updateTabBar];
}


- (BOOL)isChangingSyntaxDefinitionsProgrammatically
{
    return isChangingSyntaxDefinitionsProgrammatically;
}


- (void)setNameAndPathForDocument: (VADocument *)document
                             path: (NSString *)path
{
	NSString *name;
	
    if (path == nil)
    {
		NSString *untitledName = NSLocalizedString(@"untitled", @"Name for untitled document");
		if (untitledNumber == 1)
        {
			name = [NSString stringWithString: untitledName];
		} else
        {
			name = [NSString stringWithFormat: @"%@ %ld", untitledName, untitledNumber];
		}
        
		untitledNumber++;
		
        [document setNameWithPath: name];
		
	} else
    {
		name = [path lastPathComponent];
		[document setNameWithPath: [NSString stringWithFormat:@"%@ - %@", name, [path stringByDeletingLastPathComponent]]];
	}
	
	[document setName: name];
	[document setPath: path];
}





- (void)fixSortOrderNumbersForArrayController:(NSArrayController *)arrayController overIndex:(NSInteger)index
{
	NSArray *array = [arrayController arrangedObjects];
	for (id item in array) {
		if ([[item valueForKey:@"sortOrder"] integerValue] >= index) {
			[item setValue:@([[item valueForKey:@"sortOrder"] integerValue] + 1) forKey:@"sortOrder"];
		}
	}
}


- (void)resetSortOrderNumbersForArrayController:(NSArrayController *)arrayController
{
	NSInteger index = 0;
	NSArray *array = [arrayController arrangedObjects];
	for (id item in array) {
		[item setValue:@(index) forKey:@"sortOrder"];
		index++;
	}
}


- (void)insertIconsInBackground:(id)array
{
	NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(performInsertIcons:) object:array];
	
    [[FRAMain operationQueue] addOperation:operation];
}


- (void)performInsertIcons:(id)array
{
	NSArray *icons = [NSImage iconsForPath: array[1]
                          useQuickLookIcon: [[FRADefaults valueForKey:@"UseQuickLookIcon"] boolValue]];
	
	NSArray *resultArray = @[array[0], icons];
	
	[self performSelectorOnMainThread:@selector(performInsertIconsOnMainThread:) withObject:resultArray waitUntilDone:NO];
}
	

- (void)performInsertIconsOnMainThread:(id)array
{
	VADocument *document = array[0];
	
	NSArray *icons = array[1];
	
	if (document != nil) { // Check that the document hasn't been closed etc.
		[document setIcon: icons[0]];
		[document setUnsavedIcon: icons[1]];
		
		[FRACurrentProject reloadData];
	}
}

@end
