//
//  KSBeaconManager.m
//  KCSIBeacon
//
//  Copyright 2014 Kinvey, Inc
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

#import "KCSBeaconManager.h"

#import "KCSBeaconInfo.h"

@import UIKit;

NSString* const KCSIBeaconErrorDomain = @"KCSIBeaconErrorDomain";

@interface KCSBeaconManager () <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, strong) CLBeacon* lastBeacon;
@property (nonatomic, strong) NSDate* lastRanging;
@property (nonatomic, strong) NSDate* lastBoundary;
@property (nonatomic, strong) NSMutableSet* insideRegions;
@property (nonatomic, strong) NSMutableSet* knownRegions;
@end


@implementation KCSBeaconManager

- (id)init
{
    self = [super init];
    if (self) {
        _lastBeacon = nil;
        _lastRanging = nil;
        _lastBoundary = nil;
        _monitoringInterval = 0;
        _insideRegions = [NSMutableSet set];
        _knownRegions = [NSMutableSet set];
    }
    return self;
}

/*
 
 The Core Location framework provides two ways to detect a user’s entry and exit into specific regions: geographical region monitoring (iOS 4.0 and later and OS X 10.8 and later) and beacon region monitoring (iOS 7.0 and later and OS X 10.9 and later). A geographical region is an area defined by a circle of a specified radius around a known point on the Earth’s surface. In contrast, a beacon region is an area defined by the device’s proximity to Bluetooth low energy beacons. Beacons themselves are simply devices that advertise a particular Bluetooth low energy payload—you can even turn your iOS device and Mac into a beacon with some assistance from the Core Bluetooth framework.
 
 Apps can use region monitoring to be notified when the user crosses geographic boundaries or when the user enters or exits the vicinity of a beacon. While a beacon is in range of the user’s device, apps can also monitor for the relative distance to the beacon. You can use these capabilities to develop many types of innovative location-based apps. That said, because a geographical region and a beacon region are conceptually different from one another, the type of region monitoring you decide to use in your app will likely depend on the use case your app is designed to fulfill.
 
 In iOS, regions associated with your app are tracked at all times, including when your app is not running. If a region boundary is crossed while an app is not running, that app is relaunched into the background to handle the event. Similarly, if the app is suspended when the event occurs, it is woken up and given a short amount of time (around 10 seconds) to handle the event. When necessary, an app can request more background execution time using the beginBackgroundTaskWithExpirationHandler: method of the UIApplication class. Be sure to end the background task appropriately by calling the endBackgroundTask: method. The process for requesting more background execution time is described in “Executing a Finite-Length Task in the Background” in iOS App Programming Guide.
 
 In OS X, region monitoring works only while the app is running (either in the foreground or background) and the user’s system is awake. As a result, the system does not launch apps to deliver region-related notifications.
 
 Determining the Availability of Region Monitoring
 
 Before attempting to monitor any regions, your app should check to see if region monitoring is supported on the current device. There are several reasons why region monitoring might not be available:
 
 The device may not have the hardware needed to support region monitoring.
 The user might have denied the app the authorization to use region monitoring.
 The user may have disabled location services in the Settings app.
 The user may have disabled Background App Refresh in the Settings app, either for the device or for your app.
 The device might be in Airplane mode and unable to power up the necessary hardware.
 In iOS 7.0 and later, you should always call the isMonitoringAvailableForClass: and authorizationStatus class methods of CLLocationManager before attempting to monitor regions. (In OS X 10.8 and later and in previous versions of iOS, use the regionMonitoringAvailable class instead.) The isMonitoringAvailableForClass: method lets you know whether the underlying hardware supports region monitoring for the specified class at all. If that method returns NO, your app can’t use region monitoring on the device. If it returns YES, call the authorizationStatus method to determine whether the app is currently authorized to use location services. If the authorization status is kCLAuthorizationStatusAuthorized, your app will begin to receive boundary crossing notifications for any regions it registered. If the authorization status is set to any other value, your app does not receive those notifications.
 
 Note: Even if your app is not authorized to use region monitoring, it can still register regions for use later. If the user subsequently grants authorization to your app, monitoring for those regions will begin and will generate subsequent boundary crossing notifications. If you do not want regions to remain installed while your app is not authorized, you can use the locationManager:didChangeAuthorizationStatus: delegate method to detect changes in your app’s status and remove regions as appropriate.
 Finally, if your app needs to process location updates in the background, be sure to check the backgroundRefreshStatus property of the UIApplication class. You can use the value of this property to determine if doing so is possible and to warn the user if it is not.
 
 
 */

- (CLLocationManager *)locationManager
{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
    }
    return _locationManager;
}

- (BOOL) startMonitoringForRegion:(NSString*)UUIDString identifier:(NSString*)identifier error:(NSError**)error
{
    return [self startMonitoringForRegion:UUIDString identifier:identifier major:nil minor:nil error:error];
}

- (BOOL) startMonitoringForRegion:(NSString*)UUIDString identifier:(NSString*)identifier major:(NSNumber*)major minor:(NSNumber*)minor error:(NSError**)error
{
    BOOL locationEnabled = [CLLocationManager locationServicesEnabled];
    if (!locationEnabled) {
        NSDictionary* info = @{NSLocalizedDescriptionKey : @"Location Services Not Enabled"};
        *error = [NSError errorWithDomain:KCSIBeaconErrorDomain code:KCSIBeaconLocationServicesNotEnabled userInfo:info];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            if ([CLLocationManager locationServicesEnabled]) {
                //now have location management
                [self startMonitoringForRegion:UUIDString identifier:identifier major:major minor:minor error:NULL];
            }
        }];
        return NO;
    }
    
    CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
    if (authStatus == kCLAuthorizationStatusDenied) {
        if (error) {
            NSDictionary* info = @{NSLocalizedDescriptionKey : @"User has denied access to Location Services"};
            *error = [NSError errorWithDomain:KCSIBeaconErrorDomain code:KCSIBeaconLocationServicesDenied userInfo:info];
        }
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            if ([CLLocationManager locationServicesEnabled]) {
                //now have location management
                [self startMonitoringForRegion:UUIDString identifier:identifier major:major minor:minor error:NULL];
            }
        }];
        return NO;
    } else if (authStatus == kCLAuthorizationStatusRestricted) {
        if (error) {
            NSDictionary* info = @{NSLocalizedDescriptionKey : @"App is prevented from accessing Location Services"};
            *error = [NSError errorWithDomain:KCSIBeaconErrorDomain code:KCSIBeaconLocationServicesRestricted userInfo:info];
        }
        return NO;
    }
    
    BOOL beaconsAvailable = [CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]];
    if (!beaconsAvailable) {
        if (error) {
            NSDictionary* info = @{NSLocalizedDescriptionKey : @"iBeacon region monitoring is not available."};
            *error = [NSError errorWithDomain:KCSIBeaconErrorDomain code:KCSIBeaconCannotMonitorCLBeaconRegion userInfo:info];
        }
        return NO;
    }
    
    BOOL rangeStatus = [CLLocationManager isRangingAvailable];
    if (!rangeStatus) {
        if (error) {
            NSDictionary* info = @{NSLocalizedDescriptionKey : @"iBeacon ranging is not available"};
            *error = [NSError errorWithDomain:KCSIBeaconErrorDomain code:KCSIBeaconCannotRangeIBeacons userInfo:info];
        }
        return NO;
    }
    

    // Create the beacon region to be monitored.
    NSUUID* uuid = [[NSUUID alloc] initWithUUIDString:UUIDString];
    if (!uuid) {
        if (error) {
            NSDictionary* info = @{NSLocalizedDescriptionKey : @"Supplied UUID string is not a UUID", @"uuidString":UUIDString};
            *error = [NSError errorWithDomain:KCSIBeaconErrorDomain code:KCSIBeaconInvalidUUID userInfo:info];
        }
        return NO;
    }
    
    CLBeaconRegion *beaconRegion = nil;
    if (minor) {
        beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid major:[major unsignedIntValue] minor:[minor unsignedIntValue] identifier:identifier];
    } else if (major) {
        beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid major:[major unsignedIntValue] identifier:identifier];
    } else {
        beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:identifier];
    }
    
    if (!beaconRegion) {
        NSDictionary* info = @{NSLocalizedDescriptionKey : @"Beacon region could not be created"};
        *error = [NSError errorWithDomain:KCSIBeaconErrorDomain code:KCSIBeaconInvalidBeaconRegion userInfo:info];
        return NO;
    }
    
    beaconRegion.notifyEntryStateOnDisplay = YES;
    
    // Register the beacon region with the location manager.
    self.locationManager.delegate = self;
    for (CLBeaconRegion* region in self.locationManager.monitoredRegions) {
        if ([[region kcsBeaconInfo] isEqual:[beaconRegion kcsBeaconInfo]]) {
            [self.locationManager stopMonitoringForRegion:region];
        }
    }
    [self.locationManager startMonitoringForRegion:beaconRegion];
    [self checkForEntryAfterDelay:beaconRegion]; //some beacon types don't trigger entry events if inside

    _lastRanging = [NSDate date];

    return YES;
}


- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLBeaconRegion *)region
{
    [self.knownRegions addObject:[region kcsBeaconInfo]];
    if (state == CLRegionStateInside) {
        
        if (![self.insideRegions containsObject:[region kcsBeaconInfo]]) {
            [self locationManager:manager didEnterRegion:region];
        }
        [self.locationManager startRangingBeaconsInRegion:region];
    } else if (state == CLRegionStateOutside) {
        [self.locationManager stopRangingBeaconsInRegion:region];
    } else {
        //unknown?
    }
    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(rangingFailedForRegion:withError:)]) {
        [self.delegate rangingFailedForRegion:nil withError:error];
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLBeaconRegion *)region
{
    if ([[NSDate date] timeIntervalSinceDate:self.lastBoundary] < self.monitoringInterval) {
        return;
    }
    
    self.lastBoundary = [NSDate date];
    if ([self.insideRegions containsObject:[region kcsBeaconInfo]]) {
        //being inside this region has already been determined, so no need to repost this message
        return;
    }
    [self.insideRegions addObject:[region kcsBeaconInfo]];
    
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(enteredRegion:)]) {
        [self.delegate enteredRegion:(CLBeaconRegion*)region];
    }
    
    if (self.postsLocalNotification) {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"You're inside the region '%@'", @"region enter notification"), region.identifier];
        notification.userInfo = @{@"region":[[region kcsBeaconInfo] plistObject], @"event":@"enter"};

        /*
         If the application is in the foreground, it will get a callback to application:didReceiveLocalNotification:.
         If it's not, iOS will display the notification to the user.
         */
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
    
    if (![[manager rangedRegions] containsObject:region]) {
        [manager startRangingBeaconsInRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLBeaconRegion *)region
{
    if ([[NSDate date] timeIntervalSinceDate:self.lastBoundary] < self.monitoringInterval) {
        return;
    }
    self.lastBoundary = [NSDate date];
    [self.insideRegions removeObject:[region kcsBeaconInfo]];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(exitedRegion:)]) {
        [self.delegate exitedRegion:(CLBeaconRegion*)region];
    }
    
    if (self.postsLocalNotification) {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"You're outside the region '%@'", @"region exit notification"), region.identifier];
        notification.userInfo = @{@"region":[[region kcsBeaconInfo] plistObject], @"event":@"exit"};
        
        /*
         If the application is in the foreground, it will get a callback to application:didReceiveLocalNotification:.
         If it's not, iOS will display the notification to the user.
         */
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
}

- (void) checkForEntryAfterDelay:(CLBeaconRegion*)r
{
    [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(checkForEntry:) userInfo:@{@"region":r} repeats:NO];
}

- (void) checkForEntry:(NSTimer*)timer
{
    CLBeaconRegion* region = timer.userInfo[@"region"];
    if (region && ![self.knownRegions containsObject:[region kcsBeaconInfo]]) {
        [self.locationManager startRangingBeaconsInRegion:region];
    }
}

#pragma mark - ranging

- (void) locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(rangingFailedForRegion:withError:)]) {
        [self.delegate rangingFailedForRegion:region withError:error];
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    CLBeacon* closestBeacon = nil;
    
    if (![self.knownRegions containsObject:[region kcsBeaconInfo]]) {
        if (beacons.count == 0) {
            [manager stopRangingBeaconsInRegion:region];
        }
        [self.knownRegions addObject:[region kcsBeaconInfo]];
    }
    
    for (CLBeacon* beacon in beacons) {
        if (![self.insideRegions containsObject:[region kcsBeaconInfo]]) {
            [self locationManager:manager didEnterRegion:region];
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(rangedBeacon:)]) {
            [self.delegate rangedBeacon:beacon];
        }

        if (!closestBeacon) {
            closestBeacon = beacon;
        } else {
            if ([closestBeacon compareByDistance:beacon] == NSOrderedDescending) {
                closestBeacon = beacon;
            }
        }
    }
    
    //Note that this can different CLBeacon instances, even for the same beacon
    BOOL different = closestBeacon && ![[self.lastBeacon kcsBeaconInfo] isEqual:[closestBeacon kcsBeaconInfo]] && (self.lastBeacon == nil || [closestBeacon compareByDistance:self.lastBeacon] == NSOrderedAscending);
    
    if (different && [[NSDate date] timeIntervalSinceDate:self.lastRanging] >= self.monitoringInterval) {
        self.lastBeacon = closestBeacon;
        self.lastRanging = [NSDate date];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(newNearestBeacon:)]) {
            [self.delegate newNearestBeacon:self.lastBeacon];
        }
    } else if ([[self.lastBeacon kcsBeaconInfo] isEqual:[closestBeacon kcsBeaconInfo]]) {
        //need to update even though the same to capture most current info (including accuracy and proximity)
        self.lastBeacon = closestBeacon;
    }
    
    
}

@end
