//
//  KCSBeaconInfo.h
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
#import <Foundation/Foundation.h>

@import CoreLocation;

@class KCSBeaconInfo;

/** Category to provide info object.
 @since 1.0.0
 */
@interface CLBeaconRegion (KCSBeaconInfo)

/** Translate the region into an representation useful for comparisons.
 @return the info object
 @since 1.0.0
 */
- (KCSBeaconInfo*) kcsBeaconInfo;
@end

/** Category to provide info object.
 @since 1.0.0
 */
@interface CLBeacon (KCSBeaconInfo)

/** Translate the region into an representation useful for comparisons.
 @return the info object
 @since 1.0.0
 */
- (KCSBeaconInfo*) kcsBeaconInfo;

/** Compares two beacons by measured distance.
 
 __NOTE:__ This may not reflect actual real-world distance comparison. There a lot of factors that go into estimating distance, and this can be affected by transmission power, number of other signals, room layout etc. The closer the proximity value, the more likely this is to be a correct comparison. 
 
 @param beacon a beacon to compare to
 @result NSOrderedAscending if this object is closer than the supplied beacon
 @since 1.0.0
 */
- (NSComparisonResult) compareByDistance:(CLBeacon*)beacon;
@end


/**
 A handy wrapper for comparing and using `CLBeacon`s and `CLBeaconRegion`s between delegate calls and for linking beacons and beaconRegions. 

 This is particuarlly useful since the CL objects can change between delegate calls.
 
 __NOTE:__ Uniqueness of is determined solely by the combination of uuid, major, and minor values. 
 @since 1.0.0
 */
@interface KCSBeaconInfo : NSObject <NSCopying>

/** The proximityUUID string.
 @since 1.0.0
 */
@property (nonatomic, copy) NSString* uuid;

/** The region identifier. Only set on CLBeaconRegion.
 @since 1.0.0
 */
@property (nonatomic, copy) NSString* identifier;

/** The major value.
 @since 1.0.0
 */
@property (nonatomic) CLBeaconMajorValue major;

/** The minor value.
 @since 1.0.0
 */
@property (nonatomic) CLBeaconMinorValue minor;

/** The accuracy of a beacon. Only set on CLBeacon.
 @since 1.0.0
 */
@property (nonatomic) CLLocationAccuracy accuracy;

/** The proximity of a beacon. Only set on CLBeacon.
 @since 1.0.0
 */
@property (nonatomic) CLProximity proximity;

/** The rssi of a beacon. Only set on CLBeacon.
 @since 1.0.0
 */
@property (nonatomic) NSInteger rssi;

/** Creates a value that can be used for serialization. This is handy for saving state or posting in a notification.
 @return a NSDictionary suitable for serialization
 @since 1.0.0
 */
- (NSDictionary*) plistObject;

/** Instantiates a KCSBeaconInfo from a dictionary representation
 @param plistObject the dictionary representation of a KCSBeaconInfo
 @return an updated object with the appropriate values set
 @since 1.0.0
 */
- (instancetype) initWithPlistObject:(NSDictionary*)plistObject;

/** Adds the properties of another beacon info. 
 
 This can be used to update an existing object after a ranging event with the latest values or combining beaconRegion and beacon info.
 
 @param newInfo another info object
 @since 1.0.0
 */
- (void) mergeWithNewInfo:(KCSBeaconInfo*)newInfo;

@end
