//
//  AnimatedVectorCircle.h
//  QuadEarth
//
//  Created by Dmytro Yaropovetsky on 10/20/17.
//  Copyright © 2017 HW Corporation. All rights reserved.
//

#import <MaplyBaseViewController.h>
#import <CoreLocation/CLLocation.h>

@class MaplyScreenMarker;
@class MaplyScreenLabel;

@interface AnimatedVectorCircle : MaplyActiveObject

@property (nonatomic, assign) BOOL needsUpdate;
@property (nonatomic, strong) MaplyVectorObject *vector;
@property (nonatomic, strong) NSDictionary *vectorDisplayOptions;
@property (nonatomic, strong, readonly) MaplyComponentObject *vectorComponentObject;

@property (nonatomic, assign) UIColor *color;
- (void)setColor:(UIColor *)color withDuration:(NSTimeInterval)duration;

@property (nonatomic, assign) CLLocationCoordinate2D coordinate2D;
- (void)setCoordinate2D:(CLLocationCoordinate2D)coordinate2D withDuration:(NSTimeInterval)duration;

@property (nonatomic, assign) MaplyCoordinate coordinate;
- (void)setCoordinate:(MaplyCoordinate)coordinate withDuration:(NSTimeInterval)duration;

@property (nonatomic, assign) CLLocationDistance radius;
- (void)setRadius:(CLLocationDistance)radius withDuration:(NSTimeInterval)duration;

+ (instancetype)animatedVectorCircleWithRadius:(CLLocationDistance)radius
							centerCoordinate2D:(CLLocationCoordinate2D)centerCoordinate2D
								displayOptions:(NSDictionary *)displayOptions
							  inViewController:(MaplyBaseViewController *)inViewController;

@end
