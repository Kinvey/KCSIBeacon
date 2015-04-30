//
//  KCSIBeaconTests.m
//  KCSIBeaconTests
//
//  Copyright 2015 Kinvey, Inc
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
#import <XCTest/XCTest.h>

#import "KCSBeaconManager.h"

@interface KCSIBeaconTests : XCTestCase <KCSBeaconManagerDelegate>
@property (nonatomic, strong) NSError* rangingError;
@end

@implementation KCSIBeaconTests

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
    KCSBeaconManager* manager = [[KCSBeaconManager alloc] init];
    manager.delegate = self;
    [manager startMonitoringForRegion:[[NSUUID UUID] UUIDString] identifier:@"com.kinvey.foo"];
    while (1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
    }
}

- (void) rangingFailedForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    self.rangingError = error;
}

@end
