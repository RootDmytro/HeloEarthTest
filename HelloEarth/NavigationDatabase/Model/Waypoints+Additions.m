//
//  Waypoints+Additions.m
//  RocketRoute 4
//
//  Created by Altukhov Anton on 9/23/15.
//  Copyright © 2015 Rocket Route. All rights reserved.
//

#import "Waypoints+Additions.h"
#import "RRAirwaysDatabase.h"

@implementation Waypoints (Additions)

+ (BOOL)isDPNWaypointType:(NSString *)waypointType {
	return (NSOrderedSame == [waypointType caseInsensitiveCompare:@"DPN"]) || (NSOrderedSame == [waypointType caseInsensitiveCompare:@"TERMINAL"]);
}

- (BOOL)isDPNWaypoint {
	return [self.class isDPNWaypointType:self.type];
}

- (CLLocationCoordinate2D)coordinate {
	return CLLocationCoordinate2DMake(self.latitude.doubleValue, self.lon.doubleValue);
}

- (NSArray<Airways *> *)airways {
	return [[RRAirwaysDatabase sharedInstance] airwaysWithWaypoint:self.ident];
}

@end
