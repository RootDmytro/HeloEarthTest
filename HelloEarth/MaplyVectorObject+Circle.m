//
//  MaplyVectorObject+Circle.m
//  RocketEarth
//
//  Created by Dmytro Yaropovetsky on 11/3/17.
//  Copyright © 2017 yar. All rights reserved.
//

#import "MaplyVectorObject+Circle.h"
#import "RRUtils.h"

@implementation MaplyVectorObject (Circle)

+ (instancetype)circleVectorWithRadius:(double)radius centerCoordinate:(CLLocationCoordinate2D)centerCoordinate {
	return [self circleVectorWithRadius:radius centerCoordinate:centerCoordinate attributes:nil];
}

+ (instancetype)circleVectorWithRadius:(double)radius centerCoordinate:(CLLocationCoordinate2D)centerCoordinate attributes:(NSDictionary *)attr {
	int num = 100;
	
	MaplyCoordinate coords[num];
	
	for (int i = 0; i < num; i++) {
		CLLocationDirection bearing = 360.0 * i / (num - 1);
		CLLocationCoordinate2D intermediateCoordinate = RRTranslateCoordinate(centerCoordinate, radius, bearing);
		coords[i] = MaplyCoordinateMakeWithDegrees(intermediateCoordinate.longitude, intermediateCoordinate.latitude);
	}
	
	MaplyVectorObject *vec = [[self alloc] initWithLineString:coords numCoords:num attributes:attr];
	return vec;
}

@end
