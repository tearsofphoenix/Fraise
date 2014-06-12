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
@class FRAProject;

@interface FRAProjectsController : NSDocumentController
{
	FRAProject *__unsafe_unretained currentProject;
}

@property (unsafe_unretained) FRAProject *currentProject;

@property (NS_NONATOMIC_IOSONLY, readonly, strong) id currentFRADocument;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) FRATextView *currentTextView;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *currentText;
- (void)selectDocumentFromTheDock:(id)sender;

- (void)putInRecentWithPath:(NSString *)path;

- (IBAction)openProjectAction:(id)sender;
- (void)performOpenProjectWithPath:(NSString *)path;
- (void)insertDocumentsFromProjectArray:(NSArray *)array;

- (void)selectDocument:(id)document;
@end
