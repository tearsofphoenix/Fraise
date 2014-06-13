//
//  VACommand.h
//  Fraise
//
//  Created by Lei on 14-6-7.
//
//

#import <Foundation/Foundation.h>

@interface VACommand : NSObject

@property (strong) NSString *collectionName;
@property (strong) NSString *command;
@property BOOL isInline;
@property (strong) NSString *interpreter;
@property (strong) NSString *name;
@property (strong) NSString *shortcutDisplayString;
@property (strong) NSString *shortcutMenuItemKeyString;
@property NSInteger shortcutModifier;
@property NSInteger sortOrder;
@property (strong) NSString *text;
@property (strong) NSString *uuid;
@property NSInteger version;

+ (NSArray *)allCommands;

@end
