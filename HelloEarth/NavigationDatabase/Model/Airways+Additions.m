//
//  Airways+Additions.m
//  RocketRoute
//
//  Created by Dmytro Yaropovetsky on 7/26/16.
//  Copyright © 2016 Rocket Route. All rights reserved.
//

#import "Airways+Additions.h"
#import "RRWaypointsDatabase.h"
#import "RRAirwaysDatabase.h"

@implementation Airways (Additions)

- (Waypoints *)srcWaypoint {
	return [[RRWaypointsDatabase sharedInstance] waypointWithURN:self.srcurn];
}

- (Waypoints *)destWaypoint {
	return [[RRWaypointsDatabase sharedInstance] waypointWithURN:self.desturn];
}

- (NSArray<Waypoints *> *)orderedWaypoints {
	NSArray<Airways *> *airways = [[RRAirwaysDatabase sharedInstance] airwaysWithIdent:self.ident];
	
	NSMutableOrderedSet<NSString *> *urns = [NSMutableOrderedSet new];
	for (Airways *airway in airways) {
		[urns addObject:airway.srcurn];
		[urns addObject:airway.desturn];
	}
	
	NSMutableArray<Waypoints *> *waypoints = [NSMutableArray new];
	for (NSString *urn in urns) {
		[waypoints addObject:[[RRWaypointsDatabase sharedInstance] waypointWithURN:urn] ?: (Waypoints *)[NSNull null]];
	}
	
	[waypoints removeObject:(Waypoints *)[NSNull null]];
	
	return waypoints.copy;
}

- (NSArray<Waypoints *> *)segmentFromWaypoint:(NSString *)startWaypoint upToWaypoint:(NSString *)endWaypoint {
	NSArray<Waypoints *> *orderedWaypoints = self.orderedWaypoints;
	
	NSMutableOrderedSet<NSString *> *identifiers = [NSMutableOrderedSet new];
	for (Waypoints *waypoint in orderedWaypoints) {
		[identifiers addObject:waypoint.ident];
	}
	
	NSInteger index1 = [identifiers indexOfObject:startWaypoint];
	NSInteger index2 = [identifiers indexOfObject:endWaypoint];
	
	NSArray<Waypoints *> *segment = nil;
	if (index1 != NSNotFound && index2 != NSNotFound) {
		NSInteger location = MIN(index1, index2);
		segment = [orderedWaypoints subarrayWithRange:NSMakeRange(location, MAX(index1, index2) + 1 - location)];
		if (index1 > index2) {
			segment = segment.reverseObjectEnumerator.allObjects;
		}
	}
	return segment;
}

@end
