//
//  VACommandCollection.h
//  Fraise
//
//  Created by Lei on 14-6-7.
//
//

#import <Foundation/Foundation.h>

@interface VASnippetCollection : NSObject

@property (strong) NSString *name;
@property NSInteger sortOrder;
@property (strong) NSString *uuid;
@property NSInteger version;
@property (strong) NSMutableArray *snippets;

+ (NSArray *)allSnippetCollections;

@end
