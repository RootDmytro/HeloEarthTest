//
//  RRWaypointsDatabase.h
//  RocketRoute
//
//  Created by Yuriy Levytskyy on 18.01.14.
//  Copyright (c) 2014 Rocket Route. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "RRDatabaseBase.h"
#import "Waypoints+Additions.h"

@interface RRWaypointsDatabase : RRDatabaseBase
+ (instancetype)sharedInstance;

- (Waypoints *)waypointWithURN:(NSString *)urn;
- (NSArray<Waypoints *> *)waypointsWithIdent:(NSString *)ident;

- (Waypoints *)anyWaypointAtLocation:(CLLocationCoordinate2D)location;
- (Waypoints *)waypointWithCoordinate:(CLLocationCoordinate2D)coordinate snapRadius:(CLLocationDegrees)radius;
- (NSArray<Waypoints *> *)waypointsWithCoordinate:(CLLocationCoordinate2D)coordinate limit:(NSUInteger)limit;

@end
