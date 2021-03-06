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


@interface FRAInfoController : NSObject
{
    IBOutlet NSTextField *createdTextField;
    IBOutlet NSTextField *creatorTextField;
    IBOutlet NSTextField *encodingTextField;
	IBOutlet NSTextField *functionTextField;
    IBOutlet NSTextField *groupTextField;
    IBOutlet NSImageView *iconImageView;
    IBOutlet NSWindow *__unsafe_unretained infoWindow;
	IBOutlet NSTextField *lengthTextField;
    IBOutlet NSTextField *linesTextField;
	IBOutlet NSTextField *modifiedTextField;
    IBOutlet NSTextField *ownerTextField;
    IBOutlet NSTextField *permissionsTextField;
    IBOutlet NSTextField *positionTextField;
    IBOutlet NSTextField *selectionTextField;
    IBOutlet NSTextField *fileSizeTextField;
    IBOutlet NSTextField *spotlightTextField;
    IBOutlet NSTextField *syntaxTextField;
    IBOutlet NSTextField *titleTextField;
    IBOutlet NSTextField *typeTextField;
    IBOutlet NSTextField *whereTextField;
    IBOutlet NSTextField *wordsTextField;
}

@property (unsafe_unretained, readonly) IBOutlet NSWindow *infoWindow;

+ (FRAInfoController *)sharedInstance;

- (void)openInfoWindow;
- (void)refreshInfo;

- (NSString *)stringFromPermissions:(NSUInteger)permissions;
@end
