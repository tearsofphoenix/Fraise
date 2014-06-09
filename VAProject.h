//
//  VAProject.h
//  Fraise
//
//  Created by Lei on 14-6-8.
//
//

#import <Foundation/Foundation.h>

@interface VAProject : NSObject

@property CGFloat dividerPosition;
@property (strong) NSString *name;
@property (strong) NSString *path;
@property  NSInteger view;
@property  NSInteger viewSize;
@property NSRect windowFrame;

@property (strong) NSMutableArray *documents;

@end
