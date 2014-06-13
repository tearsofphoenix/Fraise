//
//  VATMSyntax.h
//  VAFoundation
//
//  Created by Mac003 on 14-6-13.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import <VAFoundation/VATMObject.h>

@interface VATMSyntax : VATMObject

@property (strong) NSString *comment;
@property (strong) NSArray *fileTypes;
@property (strong) NSString *firstLineMatch;
@property (strong) NSString *keyEquivalent;
@property (strong) NSArray *patterns;

//for compatibility
@property (strong) NSString *scopeName;

@end
