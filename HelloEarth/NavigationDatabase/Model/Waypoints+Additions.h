//
//  Waypoints+Additions.h
//  RocketRoute 4
//
//  Created by Altukhov Anton on 9/23/15.
//  Copyright © 2015 Rocket Route. All rights reserved.
//

#import "Waypoints.h"

@class Airways;

@interface Waypoints (Additions)

- (BOOL)isDPNWaypoint;
+ (BOOL)isDPNWaypointType:(NSString *)waypointType;

- (CLLocationCoordinate2D)coordinate;

- (NSArray<Airways *> *)airways;

@end
