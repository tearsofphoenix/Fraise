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

@class VILineNumbers;
@class VITextView;

@protocol VITextViewDelegate <NSObject>

- (void)textViewTryToSaveContent: (VITextView *)textView;
- (void)textViewTryToShiftContentToRightDirection: (VITextView *)textView;

@end

@interface VITextView : NSTextView

@property (unsafe_unretained) NSCursor *colouredIBeamCursor;
@property (assign) BOOL inCompleteMethod;
@property (nonatomic, strong) VILineNumbers *lineNumbers;

@property (nonatomic) BOOL indentNewLinesAutomatically;
@property (nonatomic) BOOL automaticallyIndentBraces;
@property (nonatomic) BOOL useTabStops;
@property (nonatomic) NSInteger tabWidth;
@property (nonatomic) BOOL showPageGuide;
@property BOOL autoInsertAClosingParenthesis;
@property BOOL autoInsertAClosingBrace;
@property BOOL indentWithSpaces;
@property NSInteger showPageGuideAtColumn;

@property (assign) id menuTarget;
@property (nonatomic, assign) id<VITextViewDelegate> delegate;

- (void)setDefaults;

- (void)setTabWidth;

- (void)setPageGuideValues;

- (void)updateIBeamCursor;

@end
