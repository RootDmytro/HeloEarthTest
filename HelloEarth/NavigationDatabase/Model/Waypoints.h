//
//  Waypoints.h
//  RocketRoute
//
//  Created by Yuriy Levytskyy on 19.01.14.
//  Copyright (c) 2014 Rocket Route. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface Waypoints : NSObject

@property (nonatomic, retain) NSString * freq;
@property (nonatomic, retain) NSString * ident;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * lon;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * rowid;
@property (nonatomic, retain) NSString * state;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * urn;

//vrp specific
@property (nonatomic, retain) NSString * icao_coords;
@property (nonatomic, retain) NSString * long_name;
@property (nonatomic, retain) NSString * icao;
@property (nonatomic, retain) NSString * elevation;
@property (nonatomic, retain) NSNumber * grid;

- (CLLocation *)location;
- (NSString *)absoluteRepresentation;
- (NSString *)bearingDistanceFromLocation:(CLLocation *)location;

- (BOOL)isVRP; // surrogate property, should not be listed as real @property
- (void)setVRP:(BOOL)isVRP;

@end
