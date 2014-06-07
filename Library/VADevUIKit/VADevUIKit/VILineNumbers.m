/*
Fraise version 3.7 - Based on Smultron by Peter Borg
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Fraise

Copyright 2010 Jean-François Moy
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "VILineNumbers.h"
#import "VADevUIKitNotifications.h"
#import "VIScrollView.h"
#import "NSTextView+VAExtensions.h"

@interface VILineNumbers ()

@property (nonatomic, strong) NSMutableArray *scrollViews;
@end

@implementation VILineNumbers

- (id)init
{
	if (self = [super init])
    {
        _showLineNumberGutter = YES;
		_scrollViews = [[NSMutableArray alloc] init];
        
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
    NSFont *font = [notification userInfo][VAFontKey];
    _attributes = @{NSFontAttributeName: font};
}

- (void)addScrollView: (NSScrollView *)scrollView
{
    [_scrollViews addObject: scrollView];
}

- (void)removeScrollView: (NSScrollView *)scrollView
{
    [_scrollViews removeObject: scrollView];
}


- (void)viewBoundsDidChange:(NSNotification *)notification
{
	if ([[notification object] isKindOfClass: [NSClipView class]])
    {
		[self updateLineNumbersForClipView: [notification object]
                                checkWidth: YES];
	}
}


- (void)updateLineNumbersCheckWidth: (BOOL)checkWidth
{
    for (NSScrollView *sLooper in _scrollViews)
    {
        [self updateLineNumbersForClipView: [sLooper contentView]
                                checkWidth: checkWidth];
    }
}


- (void)updateLineNumbersForClipView: (NSClipView *)clipView
                          checkWidth: (BOOL)checkWidth
{
    NSTextView *textView = [clipView documentView];
	
	if (_showLineNumberGutter == NO || textView == nil)
    {
		return;
	}
	
	VIScrollView *scrollView = (VIScrollView *)[clipView superview];
    NSScrollView *gutterScrollView = [scrollView gutterScrollView];
    
	CGFloat addToScrollPoint = 0;

//    if (scrollView == [document valueForKey:@"secondTextScrollView"])
    {
//		addToScrollPoint = [[FRACurrentProject secondContentViewNavigationBar] bounds].size.height;
	}
    
    if (!gutterScrollView)
    {
		return;
	}
	
    NSPoint zeroPoint = NSZeroPoint;
	
	NSInteger index;
	NSInteger lineNumber = 0;
	
	unichar lastGlyph;
    
	NSRange range;

	NSLayoutManager *layoutManager = [textView layoutManager];
	NSRect visibleRect = [[scrollView contentView] documentVisibleRect];
	NSRange visibleRange = [layoutManager glyphRangeForBoundingRect:visibleRect inTextContainer:[textView textContainer]];
	NSString *textString = [textView string];
	NSString *searchString = [textString substringWithRange:NSMakeRange(0,visibleRange.location)];
	
	for (index = 0; index < visibleRange.location; lineNumber++)
    {
		index = NSMaxRange([searchString lineRangeForRange:NSMakeRange(index, 0)]);
	}
	
	NSInteger indexNonWrap = [searchString lineRangeForRange:NSMakeRange(index, 0)].location;
	NSInteger maxRangeVisibleRange = NSMaxRange([textString lineRangeForRange:NSMakeRange(NSMaxRange(visibleRange), 0)]); // Set it to just after the last glyph on the last visible line
	NSInteger numberOfGlyphsInTextString = [layoutManager numberOfGlyphs];
	BOOL oneMoreTime = NO;
    
	if (numberOfGlyphsInTextString != 0)
    {
		lastGlyph = [textString characterAtIndex:numberOfGlyphsInTextString - 1];
		if (lastGlyph == '\n' || lastGlyph == '\r') {
			oneMoreTime = YES; // Continue one more time through the loop if the last glyph isn't newline
		}
	}
	
    NSMutableString *lineNumbersString = [[NSMutableString alloc] init];
	
	while (indexNonWrap <= maxRangeVisibleRange)
    {
		if (index == indexNonWrap)
        {
			lineNumber++;
			[lineNumbersString appendFormat:@"%ld\n", lineNumber];
		} else
        {
			[lineNumbersString appendFormat:@"%C\n", 0x00B7];
			indexNonWrap = index;
		}
		
		if (index < maxRangeVisibleRange) {
			[layoutManager lineFragmentRectForGlyphAtIndex:index effectiveRange:&range];
			index = NSMaxRange(range);
			indexNonWrap = NSMaxRange([textString lineRangeForRange:NSMakeRange(indexNonWrap, 0)]);
		} else {
			index++;
			indexNonWrap ++;
		}
		
		if (index == numberOfGlyphsInTextString && !oneMoreTime)
        {
			break;
		}
	}
	
	if (checkWidth == YES)
    {
		NSInteger widthOfStringInGutter = [lineNumbersString sizeWithAttributes: _attributes].width;
		
		if (widthOfStringInGutter > (_gutterWidth - 14))
        { // Check if the gutterTextView has to be resized
            
            _gutterWidth = widthOfStringInGutter + 20; // Make it bigger than need be so it doesn't have to resized soon again
			if (!_showLineNumberGutter)
            {
				_gutterWidth = 0;
			}
			NSRect currentViewBounds = [[gutterScrollView superview] bounds];
			[scrollView setFrame:NSMakeRect(_gutterWidth, 0, currentViewBounds.size.width - _gutterWidth, currentViewBounds.size.height)];
			
			[gutterScrollView setFrame:NSMakeRect(0, 0, _gutterWidth, currentViewBounds.size.height)];
		}
	}
	
	[[gutterScrollView documentView] setString:lineNumbersString];
	
    //NSLog(@"%s %@ %@", __FUNCTION__, [clipView superview], NSStringFromRect([[clipView superview] frame]));
    
	[[gutterScrollView contentView] setBoundsOrigin:zeroPoint]; // To avert an occasional bug which makes the line numbers disappear
	NSInteger currentLineHeight = [textView lineHeight];
    
	if ((NSInteger)visibleRect.origin.y != 0 && currentLineHeight != 0)
    {
		[[gutterScrollView contentView] scrollToPoint:NSMakePoint(0, ((NSInteger)visibleRect.origin.y % currentLineHeight) + addToScrollPoint)]; // Move currentGutterScrollView so it aligns with the rows in currentTextView
	}
}
@end
