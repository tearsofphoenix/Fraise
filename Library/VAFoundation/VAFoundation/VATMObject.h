//
//  VATMObject.h
//  VAFoundation
//
//  Created by Lei on 14-6-13.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VATMObject <NSObject>

@property (nonatomic, strong) NSString *uuid;

@property (nonatomic) NSInteger version;

- (id)initWithDictionary: (NSDictionary *)dict;

- (NSDictionary *)dictionaryRepresent;

@end

@interface VATMObject : NSObject<VATMObject>


@end
