//
//  VAEncoding.h
//  Fraise
//
//  Created by Lei on 14-6-7.
//
//

#import <Foundation/Foundation.h>

@interface VAEncoding : NSObject

@property BOOL active;
@property NSInteger encoding;
@property (strong) NSString *name;

+ (NSArray *)allEncodings;

@end
