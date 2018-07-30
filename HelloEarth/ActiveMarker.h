//
//  ActiveMarker.h
//  QuadEarth
//
//  Created by Dmytro Yaropovetsky on 10/20/17.
//  Copyright © 2017 HW Corporation. All rights reserved.
//

#import <MaplyBaseViewController.h>
#import <CoreLocation/CLLocation.h>

@class MaplyScreenMarker;
@class MaplyScreenLabel;

@interface ActiveMarker : MaplyActiveObject

@property (nonatomic, assign) BOOL needsUpdate;
@property (nonatomic, strong) MaplyScreenMarker *marker;
@property (nonatomic, strong) MaplyScreenLabel *label;
@property (nonatomic, strong) NSDictionary *markerDisplayOptions;
@property (nonatomic, strong) NSDictionary *labelDisplayOptions;
@property (nonatomic, strong, readonly) MaplyComponentObject *markerComponentObject;
@property (nonatomic, strong, readonly) MaplyComponentObject *labelComponentObject;

@property (nonatomic, assign) CLLocationCoordinate2D coordinate2D;
- (void)setCoordinate2D:(CLLocationCoordinate2D)coordinate2D withDuration:(NSTimeInterval)duration;

@property (nonatomic, assign) MaplyCoordinate coordinate;
- (void)setCoordinate:(MaplyCoordinate)coordinate withDuration:(NSTimeInterval)duration;

@property (nonatomic, assign) double rotation;
- (void)setRotation:(double)radians withDuration:(NSTimeInterval)duration;

+ (instancetype)activeMarkerForMarker:(MaplyScreenMarker *)marker
					   displayOptions:(NSDictionary *)displayOptions
							  inViewC:(MaplyBaseViewController *)inViewC;

@end
