KCSIBeacon [![MIT License](http://b.repl.ca/v1/License-Apache2.0-blue.png)](LICENSE)
==========

Generic iBeacon Management and Utilities

## Installation 

![Version](https://cocoapod-badges.herokuapp.com/v/KCSIBeacon/badge.png)
![Platform](https://cocoapod-badges.herokuapp.com/p/KCSIBeacon/badge.png)


KCSIBeacon is available as a [CocoaPods](http://cocoapods.org) to install add to your podfile:

    pod "KCSIBeacon"
    
## Usage

### Setup
1. Add to project with CocoaPods
2. Import 

         #import "KCSIBeacon.h"
         
3. Set up your class to conform to `KCSBeaconManagerDelegate`
4. Create an instance of `KCSBeaconManager`

        self.beaconManager = [[KCSBeaconManager alloc] init];
        self.beaconManager.delegate = self;
        

5. Start Monitoring Beacon Regions, e.g.

        [self.beaconManager startMonitoringForRegion:@"41AF5763-174C-4C2C-9E4A-C99EAB4AE668" identifier:@"ipad" major:@(10) minor:@(1)];
        [self.beaconManager startMonitoringForRegion:@"F7826DA6-4FA2-4E98-8024-BC5B71E0893E" identifier:@"kontakt"]; //monitors all major & minor
    
6. Implement protocol methods to receive interesting events:
     * Ranging events, region enter/exit, and if there is a new nearest beacon.
     * e.g:
     
       - (void)newNearestBeacon2:(CLBeacon *)beacon
       {
           //show a modal for new beacon
           if ([beacon.proximityUUID isEqual:kUUID] && [beacon.major intValue] == 1) {
                NearbyBeaconViewController* nearby = [[NearbyBeaconViewController alloc] initWithNibName:@"NearbyBeaconViewController" bundle:nil];
                [self presentViewController:nearby animated:YES completion:nil];
           }
       }

### Documentation
* [Cocoadocs](http://cocoadocs.org/docsets/KCSIBeacon)

### Example project
* [iBeacon-Demo](https://github.com/mikekatz/iBeacon-Demo)

## System Requirements
* iOS 7 or later (uses iBeacons)

## License

Copyright (c) 2014 Kinvey, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

