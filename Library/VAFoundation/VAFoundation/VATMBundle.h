//
//  VATMBundle.h
//  VAFoundation
//
//  Created by Lei on 14-6-13.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VATMBundle : NSObject

@property (nonatomic, strong) NSArray *commands;
@property (nonatomic, strong) NSDictionary *info;
@property (nonatomic, strong) NSArray *preferences;
@property (nonatomic, strong) NSArray *snippets;
@property (nonatomic, strong) NSArray *syntaxes;

- (id)initWithPath: (NSString *)path;

- (NSString *)path;

@end
