//
//  RRKitUtils.h
//  RRKit
//
//  Created by Altukhov Anton on 10.02.16.
//  Copyright © 2016 RocketRoute. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef struct CLLocationBounds {
	CLLocationCoordinate2D topLeft;
	CLLocationCoordinate2D bottomRight;
} CLLocationBounds;

extern const CLLocationDistance RREarthRadiusMeters;

@interface RRKitUtils : NSObject

+ (double)radiansFromDegrees:(double)degrees;
+ (double)degreesFromRadians:(double)radians;

+ (CLLocationBounds)boundsWithCenter:(CLLocationCoordinate2D)centerCoordinate radius:(CLLocationDistance)radius;

+ (CLLocationDegrees)bearingBetweenLocation:(CLLocation *)firstLocation andLocation:(CLLocation *)secondLocation;

@end

BOOL PathToResourceNamed(NSString *name, void(^completion)(NSString *path));

typedef double RRKnotsSpeed;
typedef double RRFeetDistance;
typedef double RRNauticalMilesDistance;
typedef double RRMilesDistance;
typedef double RRLitersVolume;
typedef double RRGallonsVolume;
typedef double RRHoursTimeInterval;

static const double kRRMetersToFeet = 3.2808399;
static const double kRRMSTOKnots = 1.943844;
static const double kRRMetersInNauticalMiles = 1852;

RRFeetDistance RRFeetFromMeters(CLLocationDistance meters);
RRNauticalMilesDistance RRNauticalMilesFromMeters(CLLocationDistance meters);
RRNauticalMilesDistance RRMilesFromMeters(CLLocationDistance meters);

CLLocationDistance RRMetersFromFeet(RRFeetDistance feet);
CLLocationDistance RRMetersFromNauticalMiles(RRNauticalMilesDistance nauticalMiles);
CLLocationDistance RRMetersFromMiles(RRNauticalMilesDistance miles);

RRKnotsSpeed RRKnotsFromMpS(CLLocationSpeed metersPerSecond);
CLLocationSpeed RRMpSFromKnots(RRKnotsSpeed knots);

NSTimeInterval RRSecondsFromHours(RRHoursTimeInterval hours);
RRHoursTimeInterval RRHoursFromSeconds(NSTimeInterval seconds);

RRLitersVolume RRLitersFromGallons(RRGallonsVolume gallons);
RRGallonsVolume RRGallonsFromLiters(RRLitersVolume liters);


