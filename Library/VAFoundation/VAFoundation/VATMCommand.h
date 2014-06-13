//
//  VATMCommand.h
//  VAFoundation
//
//  Created by Lei on 14-6-13.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import <VAFoundation/VATMObject.h>

@interface VATMCommand : VATMObject

@property (strong) NSString *beforeRunningCommand;
@property (strong) NSString *command;

@property (strong) NSString *input;
@property (strong) NSString *inputFormat;
@property (strong) NSString *output;
@property (strong) NSString *outputFormat;
@property (strong) NSString *outputLocation;

@property (strong) NSString *keyEquivalent;

@property (strong) NSArray *requiredCommands;

@property (strong) NSString *semanticClass;

@end

extern NSString * const VATMNopCommandName;