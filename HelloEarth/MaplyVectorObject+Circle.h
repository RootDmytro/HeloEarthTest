//
//  MaplyVectorObject+Circle.h
//  RocketEarth
//
//  Created by Dmytro Yaropovetsky on 11/3/17.
//  Copyright © 2017 yar. All rights reserved.
//

#import <WhirlyGlobeComponent.h>
#import <CoreLocation/CoreLocation.h>

@interface MaplyVectorObject (Circle)

+ (instancetype)circleVectorWithRadius:(double)radius centerCoordinate:(CLLocationCoordinate2D)centerCoordinate;
+ (instancetype)circleVectorWithRadius:(double)radius centerCoordinate:(CLLocationCoordinate2D)centerCoordinate attributes:(NSDictionary *)attr;

@end
