//
//  VAFoundationTests.m
//  VAFoundationTests
//
//  Created by Mac003 on 14-6-5.
//  Copyright (c) 2014年 Mac003. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <VAFoundation/VAFoundation.h>

@interface VAFoundationTests : XCTestCase

@end

@implementation VAFoundationTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    NSString *bundlePath = [[NSBundle bundleForClass: [self class]] pathForResource: @"lua"
                                                                             ofType: @"tmbundle"];
    
    VATMBundle *bundle = [[VATMBundle alloc] initWithPath: bundlePath];
    
    XCTAssertNotNil(bundlePath, @"should read path");
}

@end
