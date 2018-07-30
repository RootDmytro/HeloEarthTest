//
//  ActiveMarker.m
//  QuadEarth
//
//  Created by Dmytro Yaropovetsky on 10/20/17.
//  Copyright © 2017 HW Corporation. All rights reserved.
//

#import "ActiveMarker.h"
#import <MaplyScreenLabel.h>
#import "ActiveObjectAnimator.h"
#import "RRUtils.h"
//#import <WhirlyGlobe/SceneRendererES.h>
#import "NSMutableArray+Synchronized.h"


@class WhirlyKitRendererFrameInfo;

@interface ActiveMarker () <ActiveObjectAnimatorDelegate>

@property (nonatomic, strong, readwrite) MaplyComponentObject *markerComponentObject;
@property (nonatomic, strong, readwrite) MaplyComponentObject *labelComponentObject;
@property (nonatomic, strong) NSMutableArray<ActiveObjectAnimator *> *animators;

@end

@implementation ActiveMarker

+ (instancetype)activeMarkerForMarker:(MaplyScreenMarker *)marker
						displayOptions:(NSDictionary *)displayOptions
							   inViewC:(MaplyBaseViewController *)inViewC {
	
	ActiveMarker *activeObject = [[self alloc] initWithViewController:inViewC];
	activeObject.marker = marker;
	activeObject.needsUpdate = YES; //so it gets added to the next frame
	marker.layoutImportance = MAXFLOAT; //so it doesn't flash
	
	if(displayOptions) {
		activeObject.markerDisplayOptions = displayOptions;
	} else { //default display options
		activeObject.markerDisplayOptions = @{kMaplyMinVis: @(0.0),
											  kMaplyMaxVis: @(6.0),
											  kMaplyFade: @(0.0)};
	}
	
	return activeObject;
}

- (instancetype)initWithViewController:(MaplyBaseViewController *)viewC {
	self = [super initWithViewController:viewC];
	if (self != nil) {
		self.animators = [NSMutableArray new];
	}
	return self;
}

- (void)addAnimatorWithDuration:(NSTimeInterval)duration
			  modificationBlock:(void (^)(ActiveMarker *this, double fraction))modificationBlock
					animatedKey:(NSString *)animatedKey {
	
	__weak typeof(self) wself = self;
	ActiveObjectAnimator *newAnimator = [[ActiveObjectAnimator alloc] initWithDelegate:self
																			  duration:duration
																	 modificationBlock:^(double fraction) {
																		 modificationBlock(wself, fraction);
																	 }
																		   animatedKey:animatedKey];
	
	@synchronized (self.animators) {
		if (animatedKey != nil) {
			for (ActiveObjectAnimator *animator in self.animators.copy) {
				if ([animator.animatedKey isEqualToString:animatedKey]) {
					[animator complete];
				}
			}
		}
		
		[self.animators addObject:newAnimator];
	}
}

#pragma mark - Coordinate2D

- (CLLocationCoordinate2D)coordinate2D {
	MaplyCoordinate coordinate = self.coordinate;
	return CLLocationCoordinate2DMake(RRDegreesFromRadians(coordinate.y), RRDegreesFromRadians(coordinate.x));
}

- (void)setCoordinate2D:(CLLocationCoordinate2D)coordinate2D {
	self.coordinate = MaplyCoordinateMakeWithDegrees(coordinate2D.longitude, coordinate2D.latitude);
}

- (void)setCoordinate2D:(CLLocationCoordinate2D)coordinate2D withDuration:(NSTimeInterval)duration {
	CLLocationCoordinate2D initialCoordinate = self.coordinate2D;
	
	CLLocationDistance distance;
	CLLocationDirection bearing;
	RRComputeParameters(initialCoordinate, coordinate2D, &distance, &bearing, NULL);
	
	[self addAnimatorWithDuration:duration
				modificationBlock:^(ActiveMarker *this, double fraction) {
					CLLocationCoordinate2D intermediateCoordinate = RRTranslateCoordinate(initialCoordinate, distance * fraction, bearing);
					this.coordinate_ = MaplyCoordinateMakeWithDegrees(intermediateCoordinate.longitude, intermediateCoordinate.latitude);
					this.needsUpdate = YES;
				}
					  animatedKey:@"coordinate"];
}

#pragma mark - MaplyCoordinate

- (MaplyCoordinate)coordinate {
	return self.marker.loc;
}

- (void)setCoordinate:(MaplyCoordinate)coordinate {
	self.coordinate_ = coordinate;
	self.needsUpdate = YES;
}

- (void)setCoordinate_:(MaplyCoordinate)coordinate {
	self.marker.loc = coordinate;
	self.label.loc = coordinate;
}

- (void)setCoordinate:(MaplyCoordinate)coordinate withDuration:(NSTimeInterval)duration {
	[self setCoordinate2D:CLLocationCoordinate2DMake(RRDegreesFromRadians(coordinate.y),
													 RRDegreesFromRadians(coordinate.x))
			 withDuration:duration];
}

#pragma mark - Rotation

- (double)rotation {
	return self.marker.rotation;
}

- (void)setRotation:(double)radians {
	self.rotation_ = radians;
	self.needsUpdate = YES;
}

- (void)setRotation_:(double)radians {
	self.marker.rotation = radians;
}

- (void)setRotation:(double)radians withDuration:(NSTimeInterval)duration {
	double initialRotation = self.marker.rotation;
	
	[self addAnimatorWithDuration:duration
				modificationBlock:^(ActiveMarker *this, double fraction) {
					this.rotation_ = initialRotation * (1 - fraction) + radians * fraction;
					this.needsUpdate = YES;
				}
					  animatedKey:@"rotation"];
}

#pragma mark - ActiveObjectAnimatorDelegate

- (void)activeObjectAnimatorDidFinishAnimation:(ActiveObjectAnimator *)animator {
	[self.animators removeObjectSync:animator];
}

#pragma mark -

- (void)updateForFrame:(WhirlyKitRendererFrameInfo *)frameInfo {
	NSMutableArray<ActiveObjectAnimator *> *animators = nil;
	animators = self.animators.copySync;
	
	for (ActiveObjectAnimator *animator in animators) {
		[animator animateFrame];
	}
	
	if (self.needsUpdate && self.marker) {
		self.needsUpdate = NO;
		
		MaplyComponentObject *oldMarkerObject = self.markerComponentObject;
		MaplyComponentObject *oldLabelObject = self.labelComponentObject;
		
		if (self.marker) {
			self.markerComponentObject = [self.viewC addScreenMarkers:@[self.marker] desc:self.markerDisplayOptions mode:MaplyThreadCurrent];
		}
		
		if (self.label) {
			self.labelComponentObject = [self.viewC addScreenLabels:@[self.label] desc:self.labelDisplayOptions mode:MaplyThreadCurrent];
		}
		
		if (oldMarkerObject) {
			[self.viewC removeObjects:@[oldMarkerObject] mode:MaplyThreadCurrent];
		}
		
		if (oldLabelObject) {
			[self.viewC removeObjects:@[oldLabelObject] mode:MaplyThreadCurrent];
		}
	}
}

- (void)shutdown {
	if (self.markerComponentObject) {
		[self.viewC removeObjects:@[self.markerComponentObject]
							 mode:MaplyThreadCurrent];
		self.markerComponentObject = nil;
	}
	
	if (self.labelComponentObject) {
		[self.viewC removeObjects:@[self.labelComponentObject]
							 mode:MaplyThreadCurrent];
		self.labelComponentObject = nil;
	}
}

- (bool)hasUpdate {
	return self.needsUpdate || self.animators.countSync;
}

@end
