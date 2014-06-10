//
//  NSString+VAExtensions.h
//  VAFoundation
//
//  Created by Mac003 on 14-6-5.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import <Foundation/Foundation.h>

enum
{
	VADefaultsLineEndings = 0,
	VAUnixLineEndings = 1,
	VAMacLineEndings = 2,
	VADarkSideLineEndings = 3,
	VALeaveLineEndingsUnchanged = 6
};

typedef NSUInteger VALineEndingType;

@interface NSString (VAExtensions)

+ (NSString *)UUIDString;

- (NSArray *)divideCommandIntoArray;


- (NSString *)stringByConvertToLineEndings: (VALineEndingType)type;

- (NSString *)stringByReplaceAllNewLineCharactersWithSymbol;

- (NSString *)stringByRemoveAllLineEndings;

+ (NSString *)darkSideLineEnding;
+ (NSString *)macLineEnding;
+ (NSString *)unixLineEnding;
+ (NSString *)newLineSymbolString;

@end
