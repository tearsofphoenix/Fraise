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

- (NSString *)name;

+ (NSArray *)allEncodings;

@end
