//
//  VATMCommand.h
//  VAFoundation
//
//  Created by Lei on 14-6-13.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import "VATMObject.h"

@interface VATMCommand : VATMObject

@property (nonatomic, strong) NSString *beforeRunningCommand;
@property (nonatomic, strong) NSString *command;

@property (nonatomic, strong) NSString *input;
@property (nonatomic, strong) NSString *inputFormat;
@property (nonatomic, strong) NSString *output;
@property (nonatomic, strong) NSString *outputFormat;
@property (nonatomic, strong) NSString *outputLocation;

@property (nonatomic, strong) NSString *keyEquivalent;
@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) NSArray *requiredCommands;

@property (nonatomic, strong) NSString *scope;
@property (nonatomic, strong) NSString *semanticClass;

@end
