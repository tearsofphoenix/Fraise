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

#import "FRASingleDocumentWindowDelegate.h"
#import "FRABasicPerformer.h"
#import "FRASyntaxColouring.h"
#import <VADevUIKit/VADevUIKit.h>

@implementation FRASingleDocumentWindowDelegate

VASingletonIMPDefault(FRASingleDocumentWindowDelegate)

- (void)windowDidResize:(NSNotification *)aNotification
{
	NSWindow *window = [aNotification object];
	NSArray *array = [FRABasic fetchAll:@"Document"];
	id document;
	for (document in array) {
		if ([document valueForKey:@"singleDocumentWindow"] == window) {
			break;
		}
	}
	
	if (document == nil) {
		return;
	}
	
	array = [[window contentView] subviews];
	for (id view in array)
    {
		if (view == [document valueForKey:@"thirdTextScrollView"])
        {
			[[document valueForKey:@"lineNumbers"] updateLineNumbersForClipView: [view contentView] checkWidth: NO];
            
            [[document valueForKey: @"syntaxColouring"] pageRecolourTextView: [[view contentView] documentView]];

		}
	}
	
	[FRADefaults setValue:NSStringFromRect([window frame]) forKey:@"SingleDocumentWindow"];
}


- (BOOL)windowShouldClose:(id)sender
{
	NSArray *array = [FRABasic fetchAll:@"Document"];
	for (id item in array) {
		if ([item valueForKey:@"singleDocumentWindow"] == sender) {
			[item setValue:nil forKey:@"singleDocumentWindow"];
			[item setValue:nil forKey:@"singleDocumentWindow"];
			[item setValue:nil forKey:@"thirdTextView"];
			[[item valueForKey:@"syntaxColouring"] setThirdLayoutManager:nil];
			break;
		}
	}
	
	[FRADefaults setValue:NSStringFromRect([sender frame]) forKey:@"SingleDocumentWindow"];
	
	return YES;
}

@end
