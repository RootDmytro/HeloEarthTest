//
//  Waypoints.m
//  RocketRoute
//
//  Created by Yuriy Levytskyy on 19.01.14.
//  Copyright (c) 2014 Rocket Route. All rights reserved.
//

#import "Waypoints.h"
#import <CoreLocation/CoreLocation.h>
#import "RRKitUtils.h"
#import <objc/runtime.h>

@implementation Waypoints

- (NSString *)description {
	return [NSString stringWithFormat:@"%@ %@ (%@)", super.description, self.name, self.ident];
}

- (CLLocation *)location {
	CLLocation * location = [[CLLocation alloc] initWithLatitude:self.latitude.doubleValue longitude:self.lon.doubleValue];
	return location;
}

- (NSString *)absoluteRepresentation {
	return self.isVRP ? self.name : [NSString stringWithFormat:@"\"%@\"", self.name];
}

- (NSString *)bearingDistanceFromLocation:(CLLocation *)location {
	NSParameterAssert(location);
	CLLocationDistance distance = [location distanceFromLocation:self.location];
	NSInteger miles = ABS(RRNauticalMilesFromMeters(distance));
	CLLocationDegrees bearing = [RRKitUtils bearingBetweenLocation:location andLocation:self.location];
	
	NSAssert(miles < 999, @"unexpected distance in miles");
	
	return [NSString stringWithFormat:@"%@%03d%03ld", self.name, (unsigned int)bearing, (long)miles];
}

- (BOOL)isVRP {
	return [objc_getAssociatedObject(self, @selector(isVRP)) boolValue];
}

- (void)setVRP:(BOOL)isVRP {
	return objc_setAssociatedObject(self, @selector(isVRP), @(isVRP), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
