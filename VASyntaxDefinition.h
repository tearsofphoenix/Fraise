//
//  VASyntaxDefinition.h
//  Fraise
//
//  Created by Lei on 14-6-8.
//
//

#import <Foundation/Foundation.h>

@interface VASyntaxDefinition : NSObject

@property (strong) NSString *extensions;
@property (strong) NSString *file;
@property (strong) NSString *name;
@property NSInteger sortOrder;

+ (NSArray *)allDefinitions;

@end
