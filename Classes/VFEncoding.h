//
//  VAEncoding.h
//  Fraise
//
//  Created by Lei on 14-6-7.
//
//

#import <Foundation/Foundation.h>

@interface VFEncoding : NSObject

@property BOOL active;
@property (nonatomic) NSInteger encoding;

@property (NS_NONATOMIC_IOSONLY, copy) NSString *name;

+ (NSArray *)allEncodings;

@end
