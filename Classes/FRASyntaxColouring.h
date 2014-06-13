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
@class VILayoutManager;

@interface FRASyntaxColouring : NSObject <NSTextStorageDelegate>


@property BOOL reactToChanges;

@property (copy) NSString *functionDefinition;
@property (copy) NSString *removeFromFunction;

@property (unsafe_unretained) VILayoutManager *secondLayoutManager;
@property (unsafe_unretained) VILayoutManager *thirdLayoutManager;
@property (unsafe_unretained) VILayoutManager *fourthLayoutManager;

@property (readonly) NSUndoManager *undoManager;


- (instancetype)initWithDocument:(id)document ;

- (void)setColours;
- (void)setSyntaxDefinition;
- (void)prepareRegularExpressions;
- (void)recolourRange:(NSRange)range;

- (void)removeAllColours;
- (void)removeColoursFromRange:(NSRange)range;

- (NSString *)guessSyntaxDefinitionFromFirstLine:(NSString *)firstLine;

- (void)pageRecolour;
- (void)pageRecolourTextView:(FRATextView *)textView;

- (void)setColour:(NSDictionary *)colour range:(NSRange)range;
- (void)highlightLineRange:(NSRange)lineRange;


@end
