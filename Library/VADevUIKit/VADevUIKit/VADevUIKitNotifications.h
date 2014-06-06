//
//  VADevUIKitNotifications.h
//  VADevUIKit
//
//  Created by Mac003 on 14-6-5.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import <Foundation/Foundation.h>

#define VAPrefix @"com.veritas.ios.fraise"
#define VANotificationPrefix VAPrefix ".notification"

#pragma mark - User Defaults notifications

#define VATextFontChangedNotification VANotificationPrefix ".text-font-changed"

#define VATextColorChangedNotification VANotificationPrefix ".text-color-changed"

extern NSString * const VAFontNameKey;

extern NSString * const VAFontKey;