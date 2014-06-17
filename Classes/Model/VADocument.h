//
//  VADocument.h
//  Fraise
//
//  Created by Lei on 14-6-7.
//
//

#import <Cocoa/Cocoa.h>

@class VIScrollView;
@class FRATextView;
@interface VADocument : NSObject

@property (strong) NSImage *icon;
@property (strong) NSImage *unsavedIcon;

@property (strong) NSString *encodingName;
@property (strong) NSString *lastSaved;
@property (strong) NSDictionary *fileAttributes;
@property  BOOL isSyntaxColoured;
@property (strong) NSWindowController *singleDocumentWindowController;
@property NSInteger sortOrder;

@property (strong) FRATextView * firstTextView;
@property (strong) FRATextView * secondTextView;
@property (strong) FRATextView * thirdTextView;
@property (strong) FRATextView *fourthTextView;
@property  BOOL showInvisibleCharacters;

@property (strong) NSScrollView *firstGutterScrollView;
@property (strong) NSScrollView *secondGutterScrollView;
@property (strong) NSScrollView *thirdGutterScrollView;
@property (strong) NSScrollView *fourthGutterScrollView;

@property (strong) VIScrollView *firstTextScrollView;
@property (strong) VIScrollView *secondTextScrollView;
@property (strong) VIScrollView *thirdTextScrollView;
@property (strong) VIScrollView *fourthTextScrollView;

@property (strong) NSWindow *singleDocumentWindow;

@property (nonatomic) NSInteger encoding;
@property (strong) id syntaxColouring;
@property (strong) id lineNumbers;
@property (strong) id externalToken;

@property BOOL fromExternal;
@property (assign) id project;

@property (strong) id externalSender;
@property (strong) NSString *nameWithPath;
@property NSInteger gutterWidth;

@property BOOL ignoreAnotherApplicationHasUpdatedDocument;
@property (strong) id syntaxDefinition;
@property (getter = isLineWrapped) BOOL lineWrapped;
@property BOOL lineEndings;
@property (getter = isNewDocument) BOOL newDocument;
@property (strong) NSString *externalPath;

@property BOOL hasManuallyChangedSyntaxDefinition;
@property BOOL showLineNumberGutter;
@property (getter = isEdited) BOOL edited;

@property (strong) NSString *path;
@property (strong) NSString *name;

@property NSRange selectedRange;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasChildren;

+ (NSArray *)allDocuments;

- (instancetype)initWithPath: (NSString *)path
           content: (NSString *)content
      contentFrame: (NSRect)frame NS_DESIGNATED_INITIALIZER;

@end

