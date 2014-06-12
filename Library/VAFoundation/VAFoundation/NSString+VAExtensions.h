//
//  NSString+VAExtensions.h
//  VAFoundation
//
//  Created by Mac003 on 14-6-5.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, VALineEndingType)
{
	VADefaultsLineEndings = 0,
	VAUnixLineEndings = 1,
	VAMacLineEndings = 2,
	VADarkSideLineEndings = 3,
	VALeaveLineEndingsUnchanged = 6
};

@interface NSString (VAExtensions)

+ (NSString *)UUIDString;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *divideCommandIntoArray;


- (NSString *)stringByConvertToLineEndings: (VALineEndingType)type;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *stringByReplaceAllNewLineCharactersWithSymbol;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *stringByRemoveAllLineEndings;

+ (NSString *)darkSideLineEnding;
+ (NSString *)macLineEnding;
+ (NSString *)unixLineEnding;
+ (NSString *)newLineSymbolString;

@end
