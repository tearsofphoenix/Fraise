//
//  VATMBundle.m
//  VAFoundation
//
//  Created by Lei on 14-6-13.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import "VATMBundle.h"

#import "VATMCommand.h"
#import "VATMPreference.h"
#import "VATMSnippet.h"
#import "VATMSyntax.h"

@interface VATMBundle ()

@property (nonatomic, strong) NSString *path;

@end

@implementation VATMBundle

- (instancetype)initWithPath: (NSString *)path
{
    if (path)
    {
        
        NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile: [path stringByAppendingPathComponent: @"info.plist"]];
        
        NSAssert(dict, @"in file: %s func: %s line: %d nil info plist for bundle path: %@", __FILE__, __func__, __LINE__, path);
        
        if ((self = [super init]))
        {
            _path = path;
            _info = dict;
            _commands = [self __loadObjectInFolder: @"Commands"
                                         withClass: [VATMCommand class]];
            _preferences = [self __loadObjectInFolder: @"Preferences"
                                            withClass: [VATMPreference class]];
            _snippets = [self __loadObjectInFolder: @"Snippets"
                                         withClass: [VATMSnippet class]];
            _syntaxes = [self __loadObjectInFolder: @"Syntaxes"
                                         withClass: [VATMSyntax class]];
        }
        
        return self;
    }
    
    return nil;
}

- (NSArray *)__loadObjectInFolder: (NSString *)folderName
                        withClass: (Class)theClass
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *commandPath = [_path stringByAppendingPathComponent: folderName];
    NSError *error = nil;
    NSArray *commandFiles = [manager contentsOfDirectoryAtPath: commandPath
                                                         error: &error];
    if (error)
    {
        NSLog(@"in file: %s func: %s line: %d error: %@", __FILE__, __func__, __LINE__, [error localizedDescription]);
    }else
    {
        NSMutableArray *results = [NSMutableArray arrayWithCapacity: [commandFiles count]];
        
        for (NSString *cLooper in commandFiles)
        {
            NSString *pathLooper = [commandPath stringByAppendingPathComponent: cLooper];
            id commandLooper = [[theClass alloc] initWithDictionary: [NSDictionary dictionaryWithContentsOfFile: pathLooper]];
            
            [results addObject: commandLooper];
        }
        
        return results;
    }
    
    return nil;
}


@end

NSString * const VATMBundleContactEmailRot13 = @"contactEmailRot13";

NSString * const VATMBundleContactName = @"contactName";

NSString * const VATMBundleDescription = @"description";

NSString * const VATMBundleMainMenu = @"mainMenu";

NSString * const VATMBundleOrdering = @"ordering";
