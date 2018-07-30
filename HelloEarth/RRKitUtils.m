//
//  RRKitUtils.m
//  RRKit
//
//  Created by Altukhov Anton on 10.02.16.
//  Copyright © 2016 RocketRoute. All rights reserved.
//

#import "RRKitUtils.h"

const CLLocationDistance RREarthRadiusMeters = 6371032.0;

@implementation RRKitUtils

+ (double)radiansFromDegrees:(double)degrees {
	return degrees * (M_PI / 180.0);
}

+ (double)degreesFromRadians:(double)radians {
	return radians * (180.0 / M_PI);
}

+ (CLLocationBounds)boundsWithCenter:(CLLocationCoordinate2D)centerCoordinate radius:(CLLocationDistance)radius {
	CLLocationBounds result;
	
	// angular distance in radians on a great circle
	double radDist = radius / RREarthRadiusMeters;
	double radLat = [self radiansFromDegrees:centerCoordinate.latitude];
	double radLon = [self radiansFromDegrees:centerCoordinate.longitude];
	
	double minLat = radLat - radDist;
	double maxLat = radLat + radDist;
	
	double minLon, maxLon;
	if (minLat > -M_PI / 2 && maxLat < M_PI / 2) {
		double deltaLon = asin(sin(radDist) / cos(radLat));
		minLon = radLon - deltaLon;
		if (minLon < -M_PI)
			minLon += 2 * M_PI;
		maxLon = radLon + deltaLon;
		if (maxLon > M_PI)
			maxLon -= 2 * M_PI;
	} else {
		// a pole is within the distance
		minLat = fmax(minLat, -M_PI / 2);
		maxLat = fmin(maxLat, M_PI / 2);
		minLon = -M_PI;
		maxLon = M_PI;
	}
	
	result.topLeft.longitude = [self degreesFromRadians:minLon];
	result.topLeft.latitude = [self degreesFromRadians:minLat];
	result.bottomRight.latitude = [self degreesFromRadians:maxLat];
	result.bottomRight.longitude = [self degreesFromRadians:maxLon];
	
	return result;
}

+ (CLLocationDegrees)bearingBetweenLocation:(CLLocation *)firstLocation andLocation:(CLLocation *)secondLocation {
	NSParameterAssert(firstLocation);
	NSParameterAssert(secondLocation);
	double lat1 = [self radiansFromDegrees:firstLocation.coordinate.latitude];
	double lon1 = [self radiansFromDegrees:firstLocation.coordinate.longitude];
	
	double lat2 = [self radiansFromDegrees:secondLocation.coordinate.latitude];
	double lon2 = [self radiansFromDegrees:secondLocation.coordinate.longitude];
	
	double dLon = lon2 - lon1;
	
	double y = sin(dLon) * cos(lat2);
	double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
	double radiansBearing = atan2(y, x);
	double degreesBearing = [self degreesFromRadians:radiansBearing];
	if (degreesBearing < 0) {
		degreesBearing = 360 - ABS(degreesBearing);
	}
	return degreesBearing;
}

@end

BOOL PathToResourceNamed(NSString *name, void(^completion)(NSString *path)) {
	NSArray<NSString *> *files = [[NSBundle mainBundle] pathsForResourcesOfType:name.pathExtension inDirectory:nil];
	for (NSString *path in files) {
		if ([path.lastPathComponent isEqualToString:name]) {
			completion(path);
			return YES;
		}
	}
	return NO;
}

RRFeetDistance RRFeetFromMeters(CLLocationDistance meters) {
	return meters * 3.2808399;
}

RRNauticalMilesDistance RRNauticalMilesFromMeters(CLLocationDistance meters) {
	return meters / 1852.0;
}

RRNauticalMilesDistance RRMilesFromMeters(CLLocationDistance meters) {
	return meters / 1609.344;
}


CLLocationDistance RRMetersFromFeet(RRFeetDistance feet) {
	return feet / 3.2808399;
}

CLLocationDistance RRMetersFromNauticalMiles(RRNauticalMilesDistance nauticalMiles) {
	return nauticalMiles * 1852.0;
}

CLLocationDistance RRMetersFromMiles(RRNauticalMilesDistance miles) {
	return miles * 1609.344;
}


RRKnotsSpeed RRKnotsFromMpS(CLLocationSpeed metersPerSecond) {
	return metersPerSecond * 1.94384449;
}

CLLocationSpeed RRMpSFromKnots(RRKnotsSpeed knots) {
	return knots / 1.94384449;
}


NSTimeInterval RRSecondsFromHours(RRHoursTimeInterval hours) {
	return hours * 3600.0;
}

RRHoursTimeInterval RRHoursFromSeconds(NSTimeInterval seconds) {
	return seconds / 3600.0;
}


RRLitersVolume RRLitersFromGallons(RRGallonsVolume gallons) {
	return gallons * 3.785411784;
}

RRGallonsVolume RRGallonsFromLiters(RRLitersVolume liters) {
	return liters / 3.785411784;
}
