//
//  Airways+Additions.h
//  RocketRoute
//
//  Created by Dmytro Yaropovetsky on 7/26/16.
//  Copyright © 2016 Rocket Route. All rights reserved.
//

#import "Airways.h"

@class Waypoints;

@interface Airways (Additions)

- (Waypoints *)srcWaypoint;
- (Waypoints *)destWaypoint;

- (NSArray<Waypoints *> *)segmentFromWaypoint:(NSString *)startWaypoint upToWaypoint:(NSString *)endWaypoint;

@end
