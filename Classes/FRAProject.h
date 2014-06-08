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
@class VADocument;
@class FRATableViewDelegate;
@class FRASplitViewDelegate;
@class PSMTabBarControl;
@class VAProject;

@interface FRAProject : NSDocument <NSTableViewDelegate,NSSplitViewDelegate,NSWindowDelegate,NSMenuDelegate>
{    
	BOOL shouldWindowClose;
	
	NSTimer *liveFindSessionTimer;
	NSInteger originalPosition;
	
	NSMenuItem *menuFormRepresentation;
		
	// FRADocumentViewsControllerCategory
	IBOutlet NSView *viewSelectionView;
	IBOutlet NSSlider *viewSelectionSizeSlider;
}

@property (nonatomic, unsafe_unretained) FRATextView *lastTextViewInFocus;

@property (strong) VADocument *firstDocument;
@property (strong) VADocument *secondDocument;

@property (strong) VAProject *project;
@property (strong) IBOutlet NSArrayController *documentsArrayController;
@property (strong) IBOutlet NSTableView *documentsTableView;
@property (strong) IBOutlet NSView *firstContentView;
@property (strong) IBOutlet NSView *secondContentView;
@property (strong) IBOutlet NSTextField *statusBarTextField;

@property (strong) IBOutlet NSSplitView *mainSplitView;
@property (strong) IBOutlet NSSplitView *contentSplitView;

@property (strong) IBOutlet NSView *secondContentViewNavigationBar;
@property (strong) IBOutlet NSPopUpButton *secondContentViewPopUpButton;

@property (strong) IBOutlet NSView *leftDocumentsView;
@property (strong) IBOutlet NSView *leftDocumentsTableView;

@property (strong) IBOutlet PSMTabBarControl *tabBarControl;
@property (strong) IBOutlet NSTabView *tabBarTabView;


- (void)setDefaultAppearanceAtStartup;

- (void)selectDocument:(id)document;
- (BOOL)areThereAnyDocuments;
- (void)resizeViewsForDocument:(id)document;
- (void)setLastTextViewInFocus:(FRATextView *)newLastTextViewInFocus;
- (id)createNewDocumentWithContents:(NSString *)textString;
- (id)createNewDocumentWithPath:(NSString *)path andContents:(NSString *)textString;

- (void)updateEditedBlobStatus;
- (void)updateWindowTitleBarForDocument:(id)document;
- (void)checkIfDocumentIsUnsaved:(id)document keepOpen:(BOOL)keepOpen;
- (void)performCloseDocument:(id)document;
- (void)cleanUpDocument:(id)document;


- (NSMutableSet *)documents;

- (NSDictionary *)dictionaryOfDocumentsInProject;

- (void)autosave;

- (NSString *)name;

- (void)selectionDidChange;

- (NSWindow *)window;

- (NSToolbar *)projectWindowToolbar;

- (BOOL)areAllDocumentsSaved;

- (void)documentsListHasUpdated;
- (void)buildSecondContentViewNavigationBarMenu;

- (CGFloat)mainSplitViewFraction;
- (void)resizeMainSplitView;
- (void)saveMainSplitViewFraction;

- (void)insertDefaultIconsInDocument:(id)document;


@end


