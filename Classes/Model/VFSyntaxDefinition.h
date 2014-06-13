//
//  VASyntaxDefinition.h
//  Fraise
//
//  Created by Lei on 14-6-8.
//
//

#import <Foundation/Foundation.h>

@interface VFSyntaxDefinition : NSObject

@property (strong) NSString *extensions;
@property (strong) NSString *file;
@property (nonatomic, strong) NSString *name;
@property NSInteger sortOrder;

+ (NSArray *)allDefinitions;
+ (VFSyntaxDefinition *)definitionForName: (NSString *)name;

@end
