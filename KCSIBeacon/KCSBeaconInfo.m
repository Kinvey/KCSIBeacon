//
//  KCSBeaconInfo.m
//  KCSIBeacon
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
#import "KCSBeaconInfo.h"

@implementation CLBeaconRegion (KCSBeaconInfo)

- (KCSBeaconInfo *)kcsBeaconInfo
{
    KCSBeaconInfo* beaconInfo = [[KCSBeaconInfo alloc] init];
    beaconInfo.uuid = [self.proximityUUID UUIDString];
    beaconInfo.major = [self.major unsignedIntValue];
    beaconInfo.minor = [self.minor unsignedIntValue];
    beaconInfo.identifier = self.identifier;
    return beaconInfo;
}

@end

@implementation CLBeacon (KCSBeaconInfo)

- (KCSBeaconInfo *)kcsBeaconInfo
{
    KCSBeaconInfo* beaconInfo = [[KCSBeaconInfo alloc] init];
    beaconInfo.uuid = [self.proximityUUID UUIDString];
    beaconInfo.major = [self.major unsignedIntValue];
    beaconInfo.minor = [self.minor unsignedIntValue];
    beaconInfo.accuracy = self.accuracy;
    beaconInfo.proximity = self.proximity;
    beaconInfo.rssi = self.rssi;
    return beaconInfo;
}

- (NSComparisonResult)compareByDistance:(CLBeacon *)beacon
{
    NSComparisonResult result = NSOrderedSame;
    if (beacon.proximity == CLProximityUnknown) {
        if (self.proximity != CLProximityUnknown) {
            result = NSOrderedAscending;
        }
    } else if (self.proximity > beacon.proximity) {
        result = NSOrderedDescending;
    } else if (self.proximity == beacon.proximity) {
        //handle they're both the same but or the other is -1 (can't find the beacon); then the one with a value is the "closest" 
        if (self.accuracy < 0 && beacon.accuracy > 0) {
            result = NSOrderedDescending;
        } else if (self.accuracy > 0 && beacon.accuracy < 0) {
            result = NSOrderedAscending;
        } else {
            result = [@(self.accuracy) compare:@(beacon.accuracy)];
        }
    } else { //self.proximity < beacon.proximity
        if (self.proximity != CLProximityUnknown) {
            result = NSOrderedAscending;
        }
    }
    return result;
}

@end

@implementation KCSBeaconInfo

- (NSDictionary *)plistObject
{
    NSMutableDictionary* object = [NSMutableDictionary dictionary];
    if (self.uuid) object[@"uuid"] = self.uuid;
    if (self.identifier) object[@"identifier"] = self.identifier;
    if (self.major) object[@"major"] = @(self.major);
    if (self.minor) object[@"minor"] = @(self.minor);
    if (self.accuracy) object[@"accuracy"] = @(self.accuracy);
    if (self.proximity) object[@"proximity"] = @(self.proximity);
    if (self.rssi) object[@"rssi"] = @(self.rssi);
    return object;
}

- (instancetype)initWithPlistObject:(NSDictionary *)plistObject
{
    self = [super init];
    if (self) {
        [plistObject enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [self setValue:obj forKey:key];
        }];
    }
    return self;
}

- (void) mergeWithNewInfo:(KCSBeaconInfo*)newInfo
{
    if (newInfo.identifier && newInfo.identifier.length > 1) self.identifier = newInfo.identifier;
    if (newInfo.major) self.major = newInfo.major;
    if (newInfo.minor) self.minor = newInfo.minor;
    if (newInfo.accuracy) self.accuracy = newInfo.accuracy;
    if (newInfo.proximity) self.proximity = newInfo.proximity;
    if (newInfo.rssi) self.rssi = newInfo.rssi;
}


- (BOOL)isEqual:(KCSBeaconInfo*)object
{
    return [object isKindOfClass:[KCSBeaconInfo class]] &&
           [object.uuid isEqualToString:self.uuid] &&
           object.major == self.major &&
           object.minor == self.minor;
}

- (NSUInteger)hash
{
    return [self.uuid hash] + self.minor + self.major;
}

- (id)copyWithZone:(NSZone *)zone
{
    KCSBeaconInfo* newInfo = [[KCSBeaconInfo allocWithZone:zone] initWithPlistObject:[self plistObject]];
    return newInfo;
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"%@ %@", [super debugDescription], [self plistObject]];
}

@end

