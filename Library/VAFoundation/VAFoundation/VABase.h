//
//  VABase.h
//  VAFoundation
//
//  Created by Lei on 14-6-5.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#ifndef VAFoundation_VABase_h
#define VAFoundation_VABase_h

#import <Foundation/Foundation.h>

#define VASingletonIMP(ClassName, methodName) + (ClassName *)methodName \
{ \
static id sharedInstance = nil; \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, \
(^{ sharedInstance = [[self alloc] init]; })); \
return sharedInstance; \
}

#define VASingletonIMPDefault(ClassName)  VASingletonIMP(ClassName, sharedInstance)


#endif
