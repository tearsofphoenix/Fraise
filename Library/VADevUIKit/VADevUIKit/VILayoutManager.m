/*
Fraise version 3.7 - Based on Smultron by Peter Borg
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Fraise

Copyright 2010 Jean-François Moy
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "VILayoutManager.h"
#import "VADevUIKitNotifications.h"

@interface VILayoutManager ()
{
	
	NSString *completeString;
	NSInteger lengthToRedraw;
	NSInteger index;
	unichar characterToCheck;
	NSPoint pointToDrawAt;
	NSRect glyphFragment;
}
@end

static 	NSString *tabCharacter = nil;
static NSString *newLineCharacter = nil;

@implementation VILayoutManager

+ (void)initialize
{
    unichar tabUnichar = 0x00AC;
    tabCharacter = [[NSString alloc] initWithCharacters:&tabUnichar length:1];
    unichar newLineUnichar = 0x00B6;
    newLineCharacter = [[NSString alloc] initWithCharacters:&newLineUnichar length:1];
}

- (instancetype)init
{
	if (self = [super init])
    {
		[self setAllowsNonContiguousLayout:YES]; // Setting this to YES sometimes causes "an extra toolbar" and other graphical glitches to sometimes appear in the text view when one sets a temporary attribute, reported as ID #5832329 to Apple
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(_notificationForTextFontChanged:)
                                                     name: VATextFontChangedNotification
                                                   object: nil];

	}
	return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)_notificationForTextFontChanged: (NSNotification *)notification
{
    if (_attributes)
    {
        NSFont *font = [notification userInfo][VAFontKey];

        NSDictionary *newAttributes = (@{
                                         NSFontAttributeName : font,
                                         NSForegroundColorAttributeName : _attributes[NSForegroundColorAttributeName]
                                         });
        [self setAttributes: newAttributes];
    }
}


- (void)setAttributes: (NSDictionary *)attributes
{
    if (_attributes != attributes)
    {
        _attributes = attributes;
        [[self firstTextView] setNeedsDisplay: YES];
    }
}


- (void)drawGlyphsForGlyphRange:(NSRange)glyphRange atPoint:(NSPoint)containerOrigin
{
    if (_showInvisibleCharacters)
    {
		completeString = [[self textStorage] string];
		lengthToRedraw = NSMaxRange(glyphRange);	
		
		for (index = glyphRange.location; index < lengthToRedraw; index++)
        {
			characterToCheck = [completeString characterAtIndex:index];
			if (characterToCheck == '\t')
            {
				pointToDrawAt = [self locationForGlyphAtIndex:index];
				glyphFragment = [self lineFragmentRectForGlyphAtIndex:index effectiveRange:NULL];
				pointToDrawAt.x += glyphFragment.origin.x;
				pointToDrawAt.y = glyphFragment.origin.y;
				[tabCharacter drawAtPoint:pointToDrawAt
                           withAttributes: _attributes];
				
			} else if (characterToCheck == '\n' || characterToCheck == '\r')
            {
				pointToDrawAt = [self locationForGlyphAtIndex:index];
				glyphFragment = [self lineFragmentRectForGlyphAtIndex:index effectiveRange:NULL];
				pointToDrawAt.x += glyphFragment.origin.x;
				pointToDrawAt.y = glyphFragment.origin.y;
				[newLineCharacter drawAtPoint: pointToDrawAt
                               withAttributes: _attributes];
			}
		}
    } 
	
    [super drawGlyphsForGlyphRange: glyphRange
                           atPoint: containerOrigin];
}


- (void)setShowInvisibleCharacters:(BOOL)flag
{
	_showInvisibleCharacters = flag;
	[self setShowsInvisibleCharacters: flag];
}


@end
