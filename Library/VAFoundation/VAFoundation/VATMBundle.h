//
//  VATMBundle.h
//  VAFoundation
//
//  Created by Lei on 14-6-13.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import <VAFoundation/VATMObject.h>

@interface VATMBundle : VATMObject

@property (strong) NSDictionary *info;

@property (strong) NSArray *commands;
@property (strong) NSArray *preferences;
@property (strong) NSArray *snippets;
@property (strong) NSArray *syntaxes;

- (instancetype)initWithPath: (NSString *)path ;

- (NSString *)path;

@end

extern NSString * const VATMBundleContactEmailRot13;

extern NSString * const VATMBundleContactName;

extern NSString * const VATMBundleDescription;

extern NSString * const VATMBundleMainMenu;

extern NSString * const VATMBundleOrdering;
