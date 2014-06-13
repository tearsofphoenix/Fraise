//
//  VATMObject.h
//  VAFoundation
//
//  Created by Lei on 14-6-13.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VATMObject <NSObject>

@property (strong) NSString *uuid;
@property (strong) NSString *name;
@property (strong) NSString *scope;

@property NSInteger version;

- (instancetype)initWithDictionary: (NSDictionary *)dict;

- (NSDictionary *)dictionaryRepresent;

@end

@interface VATMObject : NSObject<VATMObject>


@end

extern NSString * const VATMNameKey;

extern NSString * const VATMUUIDKey;
