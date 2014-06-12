/*
Fraise version 3.7 - Based on Smultron by Peter Borg
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Fraise

Copyright 2010 Jean-François Moy
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/


#import <Cocoa/Cocoa.h>

@class FRATextView;
@class FRAProjectManagedObject;
@class FRADocumentManagedObject;
@class FRATableViewDelegate;
@class FRASplitViewDelegate;
@class PSMTabBarControl;

@interface FRAProject : NSDocument <NSTableViewDelegate,NSSplitViewDelegate,NSWindowDelegate,NSMenuDelegate>
{
	NSManagedObject *__unsafe_unretained project;
	
	IBOutlet NSTextField *__unsafe_unretained statusBarTextField;
	
	IBOutlet NSView *__unsafe_unretained firstContentView;
	IBOutlet NSView *__unsafe_unretained secondContentView;

	IBOutlet NSView *__unsafe_unretained secondContentViewNavigationBar;
	IBOutlet NSPopUpButton *__unsafe_unretained secondContentViewPopUpButton;
	
	IBOutlet NSSplitView *__unsafe_unretained mainSplitView;
	IBOutlet NSSplitView *__unsafe_unretained contentSplitView;
	
	IBOutlet NSView *__unsafe_unretained leftDocumentsView;
	
	IBOutlet PSMTabBarControl *__unsafe_unretained tabBarControl;
	IBOutlet NSTabView *__unsafe_unretained tabBarTabView;
	
	FRATextView *__unsafe_unretained lastTextViewInFocus;
	
	FRADocumentManagedObject *__unsafe_unretained firstDocument;
	FRADocumentManagedObject *__unsafe_unretained secondDocument;
	
	BOOL shouldWindowClose;
		
	IBOutlet NSButton *functionButton;
	IBOutlet NSPopUpButton *functionPopUpButton;
	
	NSTimer *liveFindSessionTimer;
	NSInteger originalPosition;
	
	NSMenuItem *menuFormRepresentation;
		
	// FRADocumentViewsControllerCategory
	IBOutlet NSView *viewSelectionView;
	IBOutlet NSSlider *viewSelectionSizeSlider;
	
	IBOutlet NSView *__unsafe_unretained leftDocumentsTableView;
	IBOutlet NSTableView *__unsafe_unretained documentsTableView;
	IBOutlet NSArrayController *__unsafe_unretained documentsArrayController;
	
}

@property (nonatomic, unsafe_unretained) FRATextView *lastTextViewInFocus;

@property (unsafe_unretained) FRADocumentManagedObject *firstDocument;
@property (unsafe_unretained) FRADocumentManagedObject *secondDocument;

@property (unsafe_unretained, readonly) IBOutlet NSManagedObject *project;
@property (unsafe_unretained, readonly) IBOutlet NSArrayController *documentsArrayController;
@property (unsafe_unretained, readonly) IBOutlet NSTableView *documentsTableView;
@property (unsafe_unretained, readonly) IBOutlet NSView *firstContentView;
@property (unsafe_unretained, readonly) IBOutlet NSView *secondContentView;
@property (unsafe_unretained, readonly) IBOutlet NSTextField *statusBarTextField;

@property (unsafe_unretained, readonly) IBOutlet NSSplitView *mainSplitView;
@property (unsafe_unretained, readonly) IBOutlet NSSplitView *contentSplitView;

@property (unsafe_unretained, readonly) IBOutlet NSView *secondContentViewNavigationBar;
@property (unsafe_unretained, readonly) IBOutlet NSPopUpButton *secondContentViewPopUpButton;

@property (unsafe_unretained, readonly) IBOutlet NSView *leftDocumentsView;
@property (unsafe_unretained, readonly) IBOutlet NSView *leftDocumentsTableView;

@property (unsafe_unretained, readonly) IBOutlet PSMTabBarControl *tabBarControl;
@property (unsafe_unretained, readonly) IBOutlet NSTabView *tabBarTabView;


- (void)setDefaultAppearanceAtStartup;

- (void)selectDocument:(id)document;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL areThereAnyDocuments;
- (void)resizeViewsForDocument:(id)document;
- (void)setLastTextViewInFocus:(FRATextView *)newLastTextViewInFocus;
- (id)createNewDocumentWithContents:(NSString *)textString;
- (id)createNewDocumentWithPath:(NSString *)path andContents:(NSString *)textString;

- (void)updateEditedBlobStatus;
- (void)updateWindowTitleBarForDocument:(id)document;
- (void)checkIfDocumentIsUnsaved:(id)document keepOpen:(BOOL)keepOpen;
- (void)performCloseDocument:(id)document;
- (void)cleanUpDocument:(id)document;


@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSMutableSet *documents;

@property (NS_NONATOMIC_IOSONLY, readonly, strong) NSManagedObjectContext *managedObjectContext;

- (NSDictionary *)dictionaryOfDocumentsInProject;

- (void)autosave;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *name;

- (void)selectionDidChange;

@property (NS_NONATOMIC_IOSONLY, readonly, strong) NSWindow *window;

@property (NS_NONATOMIC_IOSONLY, readonly, strong) NSToolbar *projectWindowToolbar;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL areAllDocumentsSaved;

- (void)documentsListHasUpdated;
- (void)buildSecondContentViewNavigationBarMenu;

@property (NS_NONATOMIC_IOSONLY, readonly) CGFloat mainSplitViewFraction;
- (void)resizeMainSplitView;
- (void)saveMainSplitViewFraction;

- (void)insertDefaultIconsInDocument:(id)document;


@end


