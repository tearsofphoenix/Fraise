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

@class FRAFullScreenWindow;

@interface FRAInterfacePerformer : NSObject {
	
	NSString *statusBarBetweenString;
	NSString *statusBarLastSavedString;
	NSString *statusBarDocumentLengthString;
	NSString *statusBarSelectionLengthString;
	NSString *statusBarPositionString;
	NSString *statusBarSyntaxDefinitionString;
	NSString *statusBarEncodingString;
	
	FRAFullScreenWindow *fullScreenWindow;
	id __unsafe_unretained fullScreenDocument;
	NSMenu *savedMainMenu;
	NSRect fullScreenRect;
	
	NSImage *defaultIcon;
	NSImage *defaultUnsavedIcon;
}

@property (readonly) FRAFullScreenWindow *fullScreenWindow;
@property (unsafe_unretained, readonly) id fullScreenDocument;

@property (strong) NSImage *defaultIcon;
@property (strong) NSImage *defaultUnsavedIcon;


+ (FRAInterfacePerformer *)sharedInstance;

- (void)goToFunctionOnLine:(id)sender;
- (void)createFirstViewForDocument:(id)document;
- (void)insertDocumentIntoSecondContentView:(id)document;
- (void)insertDocumentIntoThirdContentView:(id)document orderFront:(BOOL)orderFront;
- (void)insertDocumentIntoFourthContentView:(id)document;

- (void)updateStatusBar;
- (void)clearStatusBar;

- (NSString *)whichDirectoryForOpen;
- (NSString *)whichDirectoryForSave;

- (void)removeAllSubviewsFromView:(NSView *)view;
- (void)enterFullScreenForDocument:(id)document;
- (void)insertDocumentIntoFullScreenWindow;
- (void)returnFromFullScreen;

- (void)insertAllFunctionsIntoMenu:(NSMenu *)menu;
- (NSArray *)allFunctions;
- (NSInteger)currentLineNumber;
- (NSInteger)currentFunctionIndexForFunctions:(NSArray *)functions;

- (void)removeAllTabBarObjectsForTabView:(NSTabView *)tabView;

- (void)changeViewWithAnimationForWindow:(NSWindow *)window oldView:(NSView *)oldView newView:(NSView *)newView newRect:(NSRect)newRect;

- (void) updateGutterViewForDocument:(id)document;

@end
