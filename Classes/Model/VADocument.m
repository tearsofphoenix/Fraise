//
//  VADocument.m
//  Fraise
//
//  Created by Lei on 14-6-7.
//
//
#import "FRAStandardHeader.h"
#import "VADocument.h"
#import "FRAProject.h"
#import "FRASyntaxColouring.h"
#import "FRATextView.h"

#import <VADevUIKit/VADevUIKit.h>

@implementation VADocument

static NSMutableArray *gsAllDocuments = nil;
static NSInteger untitledNumber = 0;
static NSImage *defaultIcon = nil;
static NSImage *defaultUnsavedIcon = nil;

+ (void)initialize
{
    gsAllDocuments = [[NSMutableArray alloc] initWithCapacity: 16];
    untitledNumber = 1;
    defaultIcon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRADefaultIcon" ofType:@"png"]];
    defaultUnsavedIcon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRADefaultUnsavedIcon" ofType:@"png"]];
}

- (instancetype)initWithPath: (NSString *)path
           content: (NSString *)content
      contentFrame: (NSRect)frame
{
    if ((self = [super init]))
    {
        id defaults = FRADefaults;
        
        _isSyntaxColoured = [[defaults valueForKey:@"SyntaxColourNewDocuments"] boolValue];
        _lineWrapped = [[defaults valueForKey:@"LineWrapNewDocuments"] boolValue];
        _showInvisibleCharacters = [[defaults valueForKey:@"ShowInvisibleCharacters"] boolValue];
        _showLineNumberGutter = [[defaults valueForKey:@"ShowLineNumberGutter"] boolValue];
        _gutterWidth = [[defaults valueForKey:@"GutterWidth"] integerValue];
        _encoding = [[defaults valueForKey:@"EncodingsPopUp"] integerValue];
        _newDocument = YES;
        _lastSaved = UNSAVED_STRING;
        
        [self _initNameWithPath: path];
        [self _createFirstViewWithFrame: frame];
        
        [self setIcon: defaultIcon];
        [self setUnsavedIcon: defaultUnsavedIcon];
        
        [[self firstTextView] setString: content];
        
        FRASyntaxColouring *syntaxColouring = [[FRASyntaxColouring alloc] initWithDocument: self];
        [self setSyntaxColouring: syntaxColouring];
        
        NSClipView *clipView = [[self firstTextScrollView] contentView];
        [[self lineNumbers] updateLineNumbersForClipView: clipView
                                                  checkWidth: NO];
        [[self syntaxColouring] pageRecolourTextView: [clipView documentView]];        
        
        [self setEncodingName: [NSString localizedNameOfStringEncoding: [self encoding]]];
        
        [gsAllDocuments addObject: self];
    }
    
    return self;
}

- (void)_initNameWithPath: (NSString *)path
{
    
    NSString *name;
    
    if (path == nil)
    {
        NSString *untitledName = NSLocalizedString(@"untitled", @"Name for untitled document");
        if (untitledNumber == 1)
        {
            name = [NSString stringWithString: untitledName];
        } else
        {
            name = [NSString stringWithFormat: @"%@ %ld", untitledName, untitledNumber];
        }
        
        untitledNumber++;
        
        [self setNameWithPath: name];
        
    } else
    {
        name = [path lastPathComponent];
        [self setNameWithPath: [NSString stringWithFormat:@"%@ - %@", name, [path stringByDeletingLastPathComponent]]];
    }
    
    [self setName: name];
    [self setPath: path];
}

- (void)_createFirstViewWithFrame: (NSRect)frame
{
    NSInteger gutterWidth = [[FRADefaults valueForKey:@"GutterWidth"] integerValue];
	VIScrollView *textScrollView = [[VIScrollView alloc] initWithFrame:NSMakeRect(gutterWidth, 0, frame.size.width - gutterWidth, frame.size.height)];
	NSSize contentSize = [textScrollView contentSize];
	
	VILineNumbers *lineNumbers = [[VILineNumbers alloc] init];
    
    NSDictionary *attributes = (@{ NSFontAttributeName : [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextFont"]]});
    [lineNumbers setAttributes: attributes];
    
	[[NSNotificationCenter defaultCenter] addObserver: lineNumbers
                                             selector: @selector(viewBoundsDidChange:)
                                                 name: NSViewBoundsDidChangeNotification
                                               object: [textScrollView contentView]];
	[self setLineNumbers: lineNumbers];
	
	FRATextView *textView;
	if ([[FRADefaults valueForKey:@"LineWrapNewDocuments"] boolValue] == YES)
    {
		textView = [[FRATextView alloc] initWithFrame:NSMakeRect(gutterWidth, 0, contentSize.width, contentSize.height)];
		[textView setMinSize:contentSize];
		[textScrollView setHasHorizontalScroller:NO];
		[textView setHorizontallyResizable:YES];
		[[textView textContainer] setWidthTracksTextView:YES];
		[[textView textContainer] setContainerSize:NSMakeSize(contentSize.width, CGFLOAT_MAX)];
	} else
    {
		textView = [[FRATextView alloc] initWithFrame:NSMakeRect(gutterWidth, 0, contentSize.width, contentSize.height)];
		[textView setMinSize:contentSize];
		[textScrollView setHasHorizontalScroller:YES];
		[textView setHorizontallyResizable:YES];
		[[textView textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
		[[textView textContainer] setWidthTracksTextView:NO];
	}
	
	[textScrollView setDocumentView:textView];
    
	NSScrollView *gutterScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, gutterWidth, contentSize.height)];
	[gutterScrollView setBorderType:NSNoBorder];
	[gutterScrollView setHasVerticalScroller:NO];
	[gutterScrollView setHasHorizontalScroller:NO];
	[gutterScrollView setAutoresizingMask:NSViewHeightSizable];
	[[gutterScrollView contentView] setAutoresizesSubviews:YES];
	
	VIGutterTextView *gutterTextView = [[VIGutterTextView alloc] initWithFrame:NSMakeRect(0, 0, gutterWidth, contentSize.height - 50)];
	[gutterScrollView setDocumentView: gutterTextView];
	
    [textScrollView setGutterScrollView: gutterScrollView];
    
    [lineNumbers addScrollView: textScrollView];
    
	[self setFirstTextView: textView];
	[self setFirstTextScrollView: textScrollView];
	[self setFirstGutterScrollView: gutterScrollView];
}

+ (NSArray *)allDocuments
{
    return gsAllDocuments;
}

- (BOOL)hasChildren
{
    return NO;
}

@end
